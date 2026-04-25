// Easy-tier active-workout state.
//
// Owns business logic for `EasyActiveWorkoutScreen`. Kept separate from
// the screen widget so every file stays under the 300-line budget.
//
// Easy intentionally does NOT mix in SetLoggingMixin / TimerRestMixin /
// PRManagerMixin — those mixins expose ~40 getters/setters that would
// blow the file-budget without adding Easy-relevant behavior (no RIR,
// no progression patterns, no superset rounds, no bar type). Instead we
// reuse:
//   • WorkoutTimerController   (rest timer)
//   • PRDetectionService       (PR detection + haptics)
//   • WorkoutRepository        (same POST /performance/logs endpoint)
// …and stamp `loggingMode: 'easy'` on every SetLog.
//
// Pure data + helpers live in sibling files:
//   • easy_active_workout_state_models.dart — EasyExerciseState + broadcaster
//   • easy_persistence_helpers.dart         — seedState / persistSet / PR
//   • easy_rest_controller.dart             — rest-overlay lifecycle
//   • easy_sheet_helpers.dart               — plan / video sheet launchers
//   • easy_active_workout_view.dart         — presentational widget
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/active_workout_phase_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/pr_detection_service.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../widgets/enhanced_notes_sheet.dart';
import 'easy_active_workout_screen.dart';
import 'easy_active_workout_state_models.dart';
import 'easy_active_workout_view.dart';
import 'easy_insight_helpers.dart';
import 'easy_persistence_helpers.dart';
import 'easy_rest_controller.dart';
import 'easy_sheet_helpers.dart';
import 'widgets/easy_help_sheet.dart';

class EasyActiveWorkoutScreenState
    extends ConsumerState<EasyActiveWorkoutScreen> {
  late List<WorkoutExercise> _exercises;
  int _currentIndex = 0;
  late Map<int, EasyExerciseState> _perExercise;

  /// Non-null ⇒ the focal card is editing a past set for the current
  /// exercise (0-indexed). Tap another dot to switch, tap "return" to
  /// go back to the upcoming set.
  int? _editingSetIndex;

  /// Cached "Last time" data per exercise index. Populated on init for all
  /// exercises in parallel; renders via `EasyLastTimeChip` and collapses
  /// to zero height when the server has no prior session.
  final Map<int, ({double weightKg, int reps, DateTime when})> _lastSetByEx =
      {};

  /// Note content the user is attaching to the next set they log (live
  /// mode). When editing a past set, notes are written straight into
  /// `state.completed[idx]` via `copyWith` and these stay empty.
  String _pendingNoteText = '';
  String? _pendingNoteAudioPath;
  List<String> _pendingNotePhotoPaths = const [];
  /// Preserves the user's values when they enter edit mode so we can
  /// restore them when they "return to current set" without losing
  /// the in-progress weight/rep picks.
  double? _liveWeightSnapshot;
  int? _liveRepsSnapshot;

  late WorkoutTimerController _timer;
  late PRDetectionService _prService;
  RestStreamBroadcaster? _restBroadcaster;

  DateTime? _currentSetStartTime;
  String? _workoutLogId;
  // Re-entry guard so the finalize-and-navigate flow can't fire twice
  // (e.g. last-set persistence + rest-complete both call into it).
  bool _isFinishing = false;
  // Stable per-workout timestamp — drives deterministic copy selection in
  // the pre-set insight engine so banner text doesn't flicker between
  // variants on every rebuild.
  final int _workoutStartEpochMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _exercises = List<WorkoutExercise>.from(widget.workout.exercises);
    if (_exercises.isEmpty) {
      _timer = WorkoutTimerController();
      _prService = ref.read(prDetectionServiceProvider);
      _perExercise = const {};
      return;
    }
    final useKg = ref.read(useKgForWorkoutProvider);
    _perExercise = seedEasyExerciseStates(_exercises, useKg: useKg);

    _timer = WorkoutTimerController()
      ..onWorkoutTick = (_) {
        if (mounted) setState(() {});
      }
      ..onRestTick = (remaining) {
        _restBroadcaster?.push(remaining);
        if (mounted) setState(() {});
      }
      ..onRestComplete = _handleRestComplete
      ..startWorkoutTimer();

    _prService = ref.read(prDetectionServiceProvider)..startNewWorkout();
    unawaited(
        _prService.preloadExerciseHistory(ref: ref, exercises: _exercises));
    unawaited(_preloadLastSetPerExercise());

    _currentSetStartTime = DateTime.now();

    // Easy skips warmup by design. Mark the phase as done so tier-switching
    // to Advanced mid-session doesn't drop the user back into warmup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeWorkoutWarmupDoneProvider.notifier).state = true;
      EasyHelpSheet.showIfNeverSeen(context,
          onSkipToNext: _skipToNextExercise);
    });
  }

  @override
  void dispose() {
    _timer.dispose();
    _restBroadcaster?.dispose();
    super.dispose();
  }

  void _setWeight(double v) {
    setState(() => _perExercise[_currentIndex]!.displayWeight = v);
    HapticService.instance.tick();
  }

  void _setReps(double v) {
    setState(() => _perExercise[_currentIndex]!.reps = v.round());
    HapticService.instance.tick();
  }

  // ── Edit past sets ─────────────────────────────────────────────────
  void _editSet(int setIndex) {
    final state = _perExercise[_currentIndex]!;
    if (setIndex < 0 || setIndex >= state.completed.length) return;
    if (_editingSetIndex == null) {
      // Snapshot the live set values so we can restore them on return.
      _liveWeightSnapshot = state.displayWeight;
      _liveRepsSnapshot = state.reps;
    }
    final log = state.completed[setIndex];
    final useKg = ref.read(useKgForWorkoutProvider);
    final displayWeight = useKg ? log.weight : log.weight * 2.20462;
    setState(() {
      _editingSetIndex = setIndex;
      state.displayWeight = displayWeight;
      state.reps = log.reps;
    });
  }

  void _returnToCurrentSet() {
    if (_editingSetIndex == null) return;
    final state = _perExercise[_currentIndex]!;
    setState(() {
      if (_liveWeightSnapshot != null) {
        state.displayWeight = _liveWeightSnapshot!;
      }
      if (_liveRepsSnapshot != null) {
        state.reps = _liveRepsSnapshot!;
      }
      _editingSetIndex = null;
      _liveWeightSnapshot = null;
      _liveRepsSnapshot = null;
    });
  }

  /// Jump the focal card forward to a future set. Intermediate sets
  /// between the current position and the target index are filled with
  /// placeholder SetLogs (reps=0, weight=0) so the counter advances; the
  /// user can tap any of those placeholder dots later to go back and
  /// edit them with real values.
  void _skipToSet(int targetIndex) {
    final state = _perExercise[_currentIndex]!;
    if (targetIndex <= state.completed.length) return;
    if (targetIndex >= state.totalSets) return;
    final useKg = ref.read(useKgForWorkoutProvider);
    setState(() {
      while (state.completed.length < targetIndex) {
        state.completed.add(SetLog(
          reps: 0,
          weight: 0,
          targetReps: state.targetReps,
          startedAt: null,
          durationSeconds: 0,
          loggingMode: 'easy',
        ));
      }
      // Load target values into the focal stepper for the new current set.
      final targetWeightKg = state.targetWeightKg;
      state.displayWeight = useKg ? targetWeightKg : targetWeightKg * 2.20462;
      state.reps = state.targetReps;
      _editingSetIndex = null;
    });
  }

  /// Soft-cap so nobody accidentally creates a workout with 20 sets per
  /// exercise. The user can always remove back down.
  static const int _kMaxSetsPerExercise = 10;

  /// Fetch the most-recent logged set for every exercise in this workout so
  /// the `EasyLastTimeChip` can render "Last time: 25 lb × 12 · 3 days ago".
  /// Runs in parallel; any per-exercise failure is swallowed and the chip
  /// for that exercise simply collapses to zero height.
  Future<void> _preloadLastSetPerExercise() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null || _exercises.isEmpty) return;
      final repo = ref.read(workoutRepositoryProvider);

      await Future.wait(List.generate(_exercises.length, (i) async {
        final ex = _exercises[i];
        try {
          final data = await repo.getExerciseLastPerformance(
              userId: userId, exerciseName: ex.name);
          if (data == null) return;
          final sets = data['sets'];
          if (sets is! List || sets.isEmpty) return;
          final first = sets.first;
          if (first is! Map) return;
          final wKg = (first['weight'] as num?)?.toDouble();
          final reps = (first['reps'] as num?)?.toInt();
          final completedAtRaw = data['completed_at'] ?? first['completed_at'];
          DateTime? when;
          if (completedAtRaw is String) {
            when = DateTime.tryParse(completedAtRaw)?.toLocal();
          }
          if (wKg == null || reps == null || wKg <= 0 || when == null) return;
          _lastSetByEx[i] =
              (weightKg: wKg, reps: reps, when: when);
        } catch (_) {/* swallow per-exercise failure */}
      }));

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] last-set preload failed: $e');
    }
  }

  /// Add an upcoming set to the current exercise. Bumps `totalSets` by 1.
  /// The new slot is empty until the user logs it.
  void _addSet() {
    final state = _perExercise[_currentIndex]!;
    if (state.totalSets >= _kMaxSetsPerExercise) return;
    setState(() => state.totalSets += 1);
  }

  /// Drop the last upcoming set. Disabled when the only remaining slot is
  /// the current live set (can't remove a set the user is on or has
  /// already completed).
  void _removeSet() {
    final state = _perExercise[_currentIndex]!;
    if (state.totalSets <= state.completed.length + 1) return;
    setState(() => state.totalSets -= 1);
  }

  /// Open the shared `EnhancedNotesSheet` (text + audio + photo) for the
  /// current focal set. When editing a past set, writes the result
  /// directly to `state.completed[idx]`; otherwise stashes to the
  /// `_pending*` fields and they flow into the next SetLog on log.
  void _openNoteSheet() {
    final state = _perExercise[_currentIndex]!;
    final idx = _editingSetIndex;
    final editing = idx != null &&
        idx >= 0 &&
        idx < state.completed.length;

    // The EnhancedNotesSheet edits a single text blob; flatten the per-set
    // notes list with newlines so existing notes are presented as one block,
    // then re-split on save (the save handler replaces the list wholesale).
    final initialNotes = editing
        ? state.completed[idx].notes.join('\n')
        : _pendingNoteText;
    final initialAudio = editing
        ? state.completed[idx].notesAudioPath
        : _pendingNoteAudioPath;
    final initialPhotos = editing
        ? state.completed[idx].notesPhotoPaths
        : _pendingNotePhotoPaths;

    showEnhancedNotesSheet(
      context,
      initialNotes: initialNotes,
      initialAudioPath: initialAudio,
      initialPhotoPaths: initialPhotos.toList(),
      onSave: (notes, audioPath, photoPaths) {
        if (!mounted) return;
        setState(() {
          if (editing) {
            // Sheet returns a single string (flattened above); split back into
            // the list shape SetLog expects. Empty lines are dropped.
            final lines = notes
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            state.completed[idx] = state.completed[idx].copyWith(
              notes: lines,
              notesAudioPath: audioPath,
              notesPhotoPaths: photoPaths,
            );
          } else {
            _pendingNoteText = notes;
            _pendingNoteAudioPath = audioPath;
            _pendingNotePhotoPaths = List.unmodifiable(photoPaths);
          }
        });
      },
    );
  }

  /// True when the currently-displayed focal set has any attached note
  /// (text, audio, or photo). Drives the pencil-chip dot indicator.
  bool get _focalSetHasNote {
    final state = _perExercise[_currentIndex]!;
    final idx = _editingSetIndex;
    if (idx != null && idx >= 0 && idx < state.completed.length) {
      final s = state.completed[idx];
      return s.notes.isNotEmpty ||
          (s.notesAudioPath?.isNotEmpty ?? false) ||
          s.notesPhotoPaths.isNotEmpty;
    }
    return _pendingNoteText.isNotEmpty ||
        (_pendingNoteAudioPath?.isNotEmpty ?? false) ||
        _pendingNotePhotoPaths.isNotEmpty;
  }

  // ── Log set ─────────────────────────────────────────────────────────
  Future<void> _logCurrentSet() async {
    final state = _perExercise[_currentIndex]!;
    final exercise = _exercises[_currentIndex];
    final useKg = ref.read(useKgForWorkoutProvider);

    final weightKg =
        useKg ? state.displayWeight : state.displayWeight * 0.453592;

    // Edit mode: overwrite the past log in-place and return to live set.
    if (_editingSetIndex != null) {
      final idx = _editingSetIndex!;
      if (idx >= 0 && idx < state.completed.length) {
        final original = state.completed[idx];
        final updated = SetLog(
          reps: state.reps,
          weight: weightKg,
          targetReps: original.targetReps,
          startedAt: original.startedAt,
          durationSeconds: original.durationSeconds,
          loggingMode: 'easy',
        );
        state.completed[idx] = updated;
      }
      await HapticService.instance.success();
      _returnToCurrentSet();
      // We deliberately do NOT start a rest timer or persist here —
      // editing a past set is a correction, not a new rep, so skip
      // PR detection and rest. (Backend re-syncs via plan save.)
      return;
    }

    int? setDuration;
    if (_currentSetStartTime != null) {
      setDuration = DateTime.now()
          .difference(_currentSetStartTime!)
          .inSeconds
          .clamp(0, 600);
    }

    final setLog = SetLog(
      reps: state.reps,
      weight: weightKg,
      targetReps: state.targetReps,
      startedAt: _currentSetStartTime,
      durationSeconds: setDuration,
      loggingMode: 'easy',
      notes: _pendingNoteText.trim().isNotEmpty
          ? [_pendingNoteText.trim()]
          : const [],
      notesAudioPath: _pendingNoteAudioPath,
      notesPhotoPaths: List.unmodifiable(_pendingNotePhotoPaths),
    );
    state.completed.add(setLog);
    // Clear pending note staging so the next set starts clean.
    _pendingNoteText = '';
    _pendingNoteAudioPath = null;
    _pendingNotePhotoPaths = const [];
    await HapticService.instance.success();

    detectEasyPRs(
        service: _prService, log: setLog, exercise: exercise, state: state);

    if (widget.workout.id != null) {
      unawaited(persistEasySet(
        ref: ref,
        exercise: exercise,
        log: setLog,
        state: state,
        workoutId: widget.workout.id!,
        totalTimeSeconds: _timer.workoutSeconds,
        cachedWorkoutLogId: _workoutLogId,
      ).then((id) {
        if (id != null) _workoutLogId = id;
      }));
    }

    final finished = state.completed.length >= state.totalSets;
    final isLast = _currentIndex >= _exercises.length - 1;
    if (finished && isLast) {
      // Last set of last exercise — run the finalize-and-celebrate flow
      // (Advanced parity) instead of dropping the user back on Home.
      unawaited(_finishWorkout());
      return;
    }

    final restSeconds = exercise.restSeconds ?? (finished ? 120 : 90);
    _startRest(restSeconds, finishedExercise: finished);
  }

  void _startRest(int seconds, {required bool finishedExercise}) {
    _restBroadcaster?.dispose();
    final target = resolveEasyNextTarget(
      finishedExercise: finishedExercise,
      currentIndex: _currentIndex,
      exercises: _exercises,
      perExercise: _perExercise,
    );
    _restBroadcaster = startEasyRest(
      context: context,
      timer: _timer,
      seconds: seconds,
      target: target,
      useKg: ref.read(useKgForWorkoutProvider),
    );
  }

  void _handleRestComplete() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _currentSetStartTime = DateTime.now();
    _advanceAfterRest();
  }

  void _advanceAfterRest() {
    final currentState = _perExercise[_currentIndex]!;
    if (currentState.completed.length >= currentState.totalSets) {
      final next = _currentIndex + 1;
      if (next >= _exercises.length) {
        // Rest after the final set finished — finalize + navigate to
        // /workout-complete.
        unawaited(_finishWorkout());
        return;
      }
      setState(() => _currentIndex = next);
      return;
    }
    // Re-seed working values for the NEXT set from target table / last log.
    final st = _perExercise[_currentIndex]!;
    final nextSetNumber = st.completed.length + 1;
    final target = _exercises[_currentIndex].getTargetForSet(nextSetNumber);
    if (target != null) {
      final useKg = ref.read(useKgForWorkoutProvider);
      final targetKg =
          (target.targetWeightKg ?? st.targetWeightKg).toDouble();
      setState(() {
        st.targetReps = target.targetReps;
        st.targetWeightKg = targetKg;
        st.reps = target.targetReps;
        st.displayWeight = useKg ? targetKg : targetKg * 2.20462;
      });
    }
  }

  void _skipToNextExercise() {
    HapticService.instance.tap();
    final next = _currentIndex + 1;
    if (next >= _exercises.length) {
      // User skipped on the last exercise — treat as natural completion
      // for whatever sets they've already logged so they still get the
      // summary screen + any PRs / XP they earned.
      unawaited(_finishWorkout());
      return;
    }
    setState(() => _currentIndex = next);
    _currentSetStartTime = DateTime.now();
  }

  void _jumpTo(int idx) {
    setState(() => _currentIndex = idx.clamp(0, _exercises.length - 1));
    _currentSetStartTime = DateTime.now();
  }

  /// Natural completion path: every exercise's last set has been logged.
  /// Mirrors what `WorkoutFlowMixin.finalizeWorkoutCompletion()` does for
  /// Advanced — patches the workout_log row with the full sets_json +
  /// metadata, calls /complete to detect PRs / build the performance
  /// summary / award server-side XP, invalidates the history providers,
  /// then routes to `/workout-complete` so the user gets the summary
  /// screen + celebrations instead of being dropped on Home.
  Future<void> _finishWorkout() async {
    if (_isFinishing || !mounted) return;
    _isFinishing = true;

    _timer.stopWorkoutTimer();
    _restBroadcaster?.dispose();
    _restBroadcaster = null;

    final result = await finalizeEasyWorkout(
      ref: ref,
      workout: widget.workout,
      exercises: _exercises,
      perExercise: _perExercise,
      totalTimeSeconds: _timer.workoutSeconds,
      workoutLogId: _workoutLogId,
    );

    if (!mounted) return;

    // Tell any background "mini player" the workout is over and clear
    // the active-workout phase flag so re-entry restarts cleanly.
    ref.read(workoutMiniPlayerProvider.notifier).close();
    ref.read(activeWorkoutWarmupDoneProvider.notifier).state = false;

    context.go('/workout-complete', extra: <String, dynamic>{
      'workout': widget.workout,
      'duration': _timer.workoutSeconds,
      'calories': result.calories,
      'workoutLogId': _workoutLogId,
      'exercisesPerformance': result.exercisesPerformance,
      'totalSets': result.totalSets,
      'totalReps': result.totalReps,
      'totalVolumeKg': result.totalVolumeKg,
      'personalRecords': result.personalRecords,
      'performanceComparison': result.performanceComparison,
      'isFirstWorkout': result.completionResponse?.isFirstWorkout ?? false,
    });
  }

  /// User-initiated "Complete workout" overflow action. Confirms, then
  /// pads every unlogged set across every exercise with a zero-stamped
  /// SetLog (weight 0, reps 0, is_completed:false), persists each one
  /// through the same `persistEasySet` path so the audit trail matches
  /// what's in memory, and finally runs the same finalize pipeline that
  /// the natural-completion path uses. This guarantees the workout
  /// reaches the `/workout-complete` screen, hits the backend `/complete`
  /// endpoint (PR detection + summary aggregation + XP), and shows up
  /// in history identically to a fully-logged session — just with the
  /// untouched sets clearly marked as not completed.
  Future<void> _completeWorkoutNow() async {
    if (_isFinishing) return;
    HapticService.instance.tap();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete workout now?'),
        content: const Text(
          'Any sets you haven’t logged will be saved as zero (0 weight, '
          '0 reps). You’ll go straight to the workout summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // Pad every unlogged set with a zero entry. Each entry persists via
    // the same per-set path so performance_logs has a row per planned
    // set — the summary aggregator counts is_completed=false rows
    // separately from real working sets.
    for (int i = 0; i < _exercises.length; i++) {
      final st = _perExercise[i];
      if (st == null) continue;
      while (st.completed.length < st.totalSets) {
        final placeholder = SetLog(
          reps: 0,
          weight: 0,
          setType: 'working',
          targetReps: st.targetReps,
          loggingMode: 'easy',
        );
        st.completed.add(placeholder);

        if (widget.workout.id != null) {
          // Fire-and-forget persist; we don't block the UI on each. The
          // finalize step below awaits the workout-log PATCH which is
          // the load-bearing call for summary aggregation.
          unawaited(persistEasySet(
            ref: ref,
            exercise: _exercises[i],
            log: placeholder.copyWith(),
            // Spoof a state so persistEasySet uses the right set_number
            // (it reads `state.completed.length` for setNumber).
            state: EasyExerciseState(
              displayWeight: 0,
              reps: 0,
              targetReps: st.targetReps,
              targetWeightKg: st.targetWeightKg,
              totalSets: st.totalSets,
              completed: List<SetLog>.from(st.completed),
            ),
            workoutId: widget.workout.id!,
            totalTimeSeconds: _timer.workoutSeconds,
            cachedWorkoutLogId: _workoutLogId,
          ).then((id) {
            if (id != null) _workoutLogId = id;
          }));
        }
      }
    }

    await _finishWorkout();
  }

  /// Confirm + bail out of the workout entirely. Completed sets remain
  /// logged upstream; this just closes the active-workout screen.
  Future<void> _quitWorkout() async {
    HapticService.instance.tap();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit workout?'),
        content: const Text(
            'Your logged sets will still be saved. You can resume this '
            'workout from Today any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).maybePop();
  }


  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Saving / completing pipeline is running — show the same trophy +
    // spinner overlay Advanced shows during finalize. Without this the
    // user sits on a frozen "Log set" screen for a few seconds while
    // the PATCH workout_log + /complete + provider invalidations run.
    if (_isFinishing) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = AccentColorScope.of(context).getColor(isDark);
      return _EasySavingOverlay(isDark: isDark, accent: accent);
    }

    // Convert every in-memory displayWeight when the user flips kg↔lb on
    // the unit chip. Without this, `state.displayWeight` keeps its numeric
    // value — so "10 kg" reads as "10 lb" instead of "22 lb". Conversion
    // is snapped to real gym plate/dumbbell increments per equipment type
    // (same logic Advanced uses via `snapToRealIncrement`) so 10 kg on a
    // cable stack becomes 25 lb — not the literal 22.046 lb mathematical
    // conversion which doesn't exist as a weight option.
    ref.listen<bool>(useKgForWorkoutProvider, (prev, next) {
      if (prev == null || prev == next) return;
      setState(() {
        for (int i = 0; i < _exercises.length; i++) {
          final s = _perExercise[i];
          if (s == null) continue;
          final ex = _exercises[i];
          final raw = next
              ? s.displayWeight * 0.453592
              : s.displayWeight * 2.20462;
          s.displayWeight = snapToRealIncrement(
            raw,
            ex.equipment,
            exerciseName: ex.name,
            useKg: next,
          );
        }
      });
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final useKg = ref.watch(useKgForWorkoutProvider);

    final exercise = _exercises[_currentIndex];
    final state = _perExercise[_currentIndex]!;
    final currentSetNumber = state.completedCount + 1;

    final mq = MediaQuery.of(context);
    final safeAreaH = mq.size.height - mq.padding.top - mq.padding.bottom;
    final compact = safeAreaH < kEasyCompactSafeAreaHeight;

    final nextIdx = _currentIndex + 1;
    final hasNext = nextIdx < _exercises.length;
    final nextExerciseName = hasNext ? _exercises[nextIdx].name : null;
    final nextExerciseImageUrl = hasNext
        ? (_exercises[nextIdx].imageS3Path ??
            _exercises[nextIdx].gifUrl ??
            _exercises[nextIdx].videoUrl)
        : null;

    return EasyActiveWorkoutView(
      exercise: exercise,
      state: state,
      nextExerciseName: nextExerciseName,
      nextExerciseImageUrl: nextExerciseImageUrl,
      currentSetNumber: currentSetNumber,
      workoutSeconds: _timer.workoutSeconds,
      useKg: useKg,
      compact: compact,
      weightStep: useKg ? 2.5 : 5.0,
      accent: accent,
      isDark: isDark,
      preSetInsight: computeEasyPreSetInsight(
        exercise: exercise,
        state: state,
        useKg: useKg,
        workoutStartEpochMs: _workoutStartEpochMs,
      ),
      onBack: () => Navigator.of(context).maybePop(),
      // Video = full-screen looping video player (pure playback).
      // Instructions = text-only glass sheet with muscle / body /
      // equipment / how-to. Separate surfaces, distinct content.
      onShowVideo: () => openEasyVideo(context, exercise, ref: ref),
      onShowInfo: () => openEasyInfoSheet(context, exercise),
      onOpenPlan: () => openEasyPlanSheet(
        context: context,
        exercises: _exercises,
        perExercise: _perExercise,
        currentIndex: _currentIndex,
        onJumpTo: _jumpTo,
      ),
      onMinimize: () {
        ref.read(workoutMiniPlayerProvider.notifier).minimize(
              workout: widget.workout,
              workoutSeconds: _timer.workoutSeconds,
              currentExerciseIndex: _currentIndex,
              currentExerciseName: exercise.name,
              totalExercises: _exercises.length,
              isPaused: false,
              isResting: false,
              restSecondsRemaining: 0,
            );
        Navigator.of(context).maybePop();
      },
      onWeightChanged: _setWeight,
      onRepsChanged: _setReps,
      onLogSet: _logCurrentSet,
      editingSetIndex: _editingSetIndex,
      onEditSet: _editSet,
      onReturnToCurrent: _returnToCurrentSet,
      onSkipToSet: _skipToSet,
      onAddSet: state.totalSets < _kMaxSetsPerExercise ? _addSet : null,
      onRemoveSet:
          state.totalSets > state.completed.length + 1 ? _removeSet : null,
      lastSet: _lastSetByEx[_currentIndex],
      onEditNote: _openNoteSheet,
      hasNote: _focalSetHasNote,
      onSkipToNext:
          _currentIndex < _exercises.length - 1 ? _skipToNextExercise : null,
      onQuitWorkout: _quitWorkout,
      onCompleteWorkoutNow: _completeWorkoutNow,
      allCompletedSets: [
        for (final s in _perExercise.values) ...s.completed,
      ],
    );
  }
}

/// Brief saving / completing screen shown while the Easy-tier finalize
/// pipeline (PATCH workout_log → /complete → invalidate providers) runs.
/// Mirrors the Advanced `buildCompletionScreen` so both tiers feel
/// identical at the end of a workout.
class _EasySavingOverlay extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _EasySavingOverlay({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.background : Colors.white;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: accent)
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms)
                  .then()
                  .shake(duration: 300.ms),
              const SizedBox(height: 24),
              Text(
                'Saving workout...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
