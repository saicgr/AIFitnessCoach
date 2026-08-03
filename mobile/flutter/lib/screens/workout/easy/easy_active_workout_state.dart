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
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/utils/exercise_tracking_metric.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/exercise_metrics_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/pr_detection_service.dart';
import '../../../data/services/workout_completion_prewarmer.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../widgets/change_equipment_helper.dart';
import '../widgets/enhanced_notes_sheet.dart';
import '../widgets/exercise_add_sheet.dart';
import '../widgets/exercise_swap_sheet.dart';
import '../widgets/form_analysis_sheet.dart';
import '../widgets/how_did_i_do_pill.dart';
import '../widgets/metric_picker_sheet.dart';
import '../widgets/report_pain_sheet.dart';
import '../widgets/stale_checkpoint_dialog.dart';
import 'easy_active_workout_screen.dart';
import '../providers/active_workout_session_provider.dart';
import '../providers/active_workout_live_provider.dart';
import 'easy_active_workout_state_models.dart';
import 'easy_active_workout_view.dart';
import 'easy_insight_helpers.dart';
import 'easy_persistence_helpers.dart';
import 'easy_rest_controller.dart';
import 'easy_sheet_helpers.dart';
import 'score_target_service.dart';
import 'widgets/easy_exercise_actions_sheet.dart';
import 'widgets/easy_exercise_header.dart' show showEasyExerciseHistorySheet;
import 'widgets/warmup_rest_overlay.dart';
import '../../../core/providers/workout_ui_mode_provider.dart';
import '../../../core/services/workout_tour_steps.dart';
import '../../../widgets/app_tour/app_tour_controller.dart' show AppTourState;
import '../../../core/constants/api_constants.dart';

import '../../../l10n/generated/app_localizations.dart';

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

  /// B6 — per-exercise Strength-Score TARGET (weight×reps to level up that
  /// exercise's primary muscle). Populated in parallel on init; renders via
  /// `EasyScoreTargetPill`. Keyed by exercise index. A null entry means
  /// "no target" (already elite / excluded / fetch failed) → pill hides.
  final Map<int, ScoreTarget?> _scoreTargetByEx = {};
  // Muscles already fetched (avoid re-querying the same muscle once cached;
  // multiple exercises can share a primary muscle).
  final Map<String, ScoreTarget?> _scoreTargetByMuscle = {};

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
  // Backed by a holder (not a bare field) so every set-persist call — the
  // natural per-set path in `_logCurrentSet` AND the padding loop in
  // `_completeWorkoutNow` — serializes against the SAME mutable id through
  // `persistEasySetSerialized` (E2E #175). See `_persistEasySetTracked`.
  final EasyWorkoutLogIdHolder _workoutLogIdHolder = EasyWorkoutLogIdHolder();
  // `holder.value` is only ever written by `persistEasySetSerialized` — no
  // setter here, that's the single point of truth for the id.
  String? get _workoutLogId => _workoutLogIdHolder.value;
  // Re-entry guard so the finalize-and-navigate flow can't fire twice
  // (e.g. last-set persistence + rest-complete both call into it).
  bool _isFinishing = false;
  // Stable per-workout timestamp — drives deterministic copy selection in
  // the pre-set insight engine so banner text doesn't flicker between
  // variants on every rebuild.
  final int _workoutStartEpochMs = DateTime.now().millisecondsSinceEpoch;

  // Warm-up phase. There is NO separate warm-up screen any more: a warm-up
  // move renders through the SAME `EasyActiveWorkoutView` a working exercise
  // does (top bar + stats strip + header + set ledger + focal column + Ask
  // coach), so the user never sees a second, differently-shaped UI mid-flow.
  //
  // Warm-up moves are still kept OUT of `_exercises` / `_perExercise` / the
  // shared session. That is deliberate: prepending them would shift every
  // working-set index (the session mirror, the checkpoint restore, the
  // Advanced tier's parallel index space, the per-index preload caches) and
  // would fold warm-up holds into volume / calories / PR math. Warm-up gets
  // its own tiny parallel index space instead, rendered by the same widget.
  List<WorkoutExercise> _warmupExercises = const [];
  final Map<int, EasyExerciseState> _warmupStates = {};
  int _warmupIndex = 0;
  bool _warmupPhase = false;

  /// E2E #134 — the rest overlay is a transparent-barrier ROUTE pushed on
  /// top of this screen (see `_startRest`/`startEasyRest`), so nothing
  /// below it reserves height and the bottom-docked rest strip overlapped
  /// the set ledger / "Ask coach" pill underneath. True for the duration
  /// the overlay is up; `EasyActiveWorkoutView` uses it to add matching
  /// bottom clearance so the content lifts clear of the strip.
  bool _isResting = false;

  /// Completed warm-up moves accumulated for the single `/warmup-logs` POST
  /// fired when the warm-up ends (finished OR skipped).
  final Map<String, List<Map<String, dynamic>>> _warmupCompleted = {};

  // True from initState until `_resolveWarmupPhase` decides whether a guided
  // warm-up runs. While true the build shows a neutral warm-up placeholder
  // (NOT the working-set screen) so the active screen never flashes in before
  // the warm-up data arrives. Set only when a warm-up is actually eligible.
  bool _warmupResolving = false;

  /// Mirrors the spotlight tour's dismiss → `tour_seen_easy` so the first-run
  /// Easy walkthrough fires exactly once. Closed in [dispose].
  ProviderSubscription<AppTourState>? _tourSeenSub;

  @override
  void initState() {
    super.initState();
    _tourSeenSub = WorkoutTourSeenListener.attach(ref);
    _exercises = List<WorkoutExercise>.from(widget.workout.exercises);
    if (_exercises.isEmpty) {
      _timer = WorkoutTimerController();
      _prService = ref.read(prDetectionServiceProvider);
      _perExercise = const {};
      return;
    }
    final useKg = ref.read(useKgForWorkoutProvider);
    _perExercise = seedEasyExerciseStates(_exercises, useKg: useKg);

    // Restore any sets logged earlier this session — covers the
    // tier-swap case (user logs 2 sets in Easy, flips to Advanced, flips
    // back, expects their 2 sets still there). The shared session
    // provider is keyed by workout.id; `start` is a no-op if the same
    // workout is already in play.
    //
    // `start()` mutates the session provider; calling it synchronously in
    // initState throws "Tried to modify a provider while the widget tree
    // was building". Defer to a post-frame callback (the Riverpod-blessed
    // fix) — the restore then re-seeds via setState.
    final session = ref.read(activeWorkoutSessionProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      session.start(widget.workout.id);
      final userId = await ref.read(apiClientProvider).getUserId();
      if (!mounted) return;

      // E2E #136 — a checkpoint with real progress older than the prompt
      // threshold must NOT rehydrate silently (that's how a freshly-started
      // workout opened already 23m37s / 161 kcal / 666 kg into a session the
      // user never started this time). Ask before adopting it.
      final age = await session.peekStaleCheckpoint(
        workoutId: widget.workout.id,
        userId: userId,
      );
      if (age != null &&
          age > kCheckpointStalePromptThreshold &&
          mounted) {
        final resume = await showStaleCheckpointDialog(context, age: age);
        if (resume != true) {
          await session.discardOnDiskCheckpoint();
          return; // start fresh — nothing to rehydrate
        }
      }
      if (!mounted) return;

      // WF4 — rehydrate the crash-safe checkpoint from SharedPreferences. If
      // the app was killed mid-workout, this restores the logged sets +
      // current exercise + elapsed timer for THIS workout. restoreCheckpoint
      // also adopts the restored state as the live in-memory session.
      await session.restoreCheckpoint(
        workoutId: widget.workout.id,
        userId: userId,
      );
      if (!mounted) return;
      final stored = ref.read(activeWorkoutSessionProvider);
      if (stored.workoutId == widget.workout.id &&
          stored.completedSets.isNotEmpty) {
        setState(() {
          stored.completedSets.forEach((idx, logs) {
            final s = _perExercise[idx];
            // Only fill empty buckets so a tier-swap restore isn't doubled.
            if (s != null && s.completed.isEmpty) s.completed.addAll(logs);
          });
          _currentIndex = stored.currentExerciseIndex.clamp(
            0,
            _exercises.length - 1,
          );
        });
      }
      // Restore the workout clock if the checkpoint had one.
      if (stored.elapsedSeconds > _timer.workoutSeconds) {
        _timer.startWorkoutTimer(initialSeconds: stored.elapsedSeconds);
      }
    });

    _timer = WorkoutTimerController()
      ..onWorkoutTick = (seconds) {
        if (mounted) setState(() {});
        // WF4 — feed the elapsed clock into the shared session so the
        // checkpoint persists an accurate timer (self-throttled to ~5s).
        if (mounted) {
          ref
              .read(activeWorkoutSessionProvider.notifier)
              .updateElapsedSeconds(seconds);
        }
      }
      ..onRestTick = (remaining) {
        _restBroadcaster?.push(remaining);
        if (mounted) setState(() {});
      }
      ..onRestComplete = _handleRestComplete
      // Tier-swap continuity: the sister tier (Advanced) pushes `elapsed
      // Seconds` into the shared session every tick, so on an Advanced→Easy
      // flip the live value is exact. Seed the clock from it instead of
      // restarting at 0 (the disk-checkpoint restore above can't cover this —
      // it returns null when no blob has been written yet). Falls back to 0
      // for a genuinely fresh session.
      ..startWorkoutTimer(initialSeconds: _liveSessionElapsedSeconds());

    _prService = ref.read(prDetectionServiceProvider)..startNewWorkout();
    unawaited(
      _prService.preloadExerciseHistory(ref: ref, exercises: _exercises),
    );
    unawaited(_preloadLastSetPerExercise());
    unawaited(_preloadSmartWeightPerExercise());
    unawaited(_preloadScoreTargetsPerExercise());

    _currentSetStartTime = DateTime.now();

    // Easy now STARTS WITH WARM-UP (present but skippable) instead of skipping
    // it. Decide ELIGIBILITY synchronously here so the FIRST build can show a
    // warm-up placeholder instead of the working-set screen — otherwise the
    // active screen paints first and the warm-up appears on top of it (flash).
    // The actual warm-up data is still fetched async in _resolveWarmupPhase.
    final warmupAlreadyDone = ref.read(activeWorkoutWarmupDoneProvider);
    final warmupHasLoggedSets =
        _perExercise.values.any((s) => s.completed.isNotEmpty);
    _warmupResolving = !(warmupAlreadyDone ||
        warmupHasLoggedSets ||
        widget.workout.id == null);

    // Resolve the warm-up phase after the first frame (so the checkpoint
    // restore above has had a chance to run).
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveWarmupPhase());
  }

  /// Elapsed workout seconds already accumulated for THIS workout by whichever
  /// tier was on screen before us (the shared session is fed on every timer
  /// tick). Returns 0 for a fresh session or a different workout — never a
  /// fabricated value.
  int _liveSessionElapsedSeconds() {
    final live = ref.read(activeWorkoutSessionProvider);
    if (live.workoutId != widget.workout.id) return 0;
    return live.elapsedSeconds > 0 ? live.elapsedSeconds : 0;
  }

  /// Decide whether to show the guided warm-up before the working sets.
  /// Shows ONLY on a fresh start (no restored sets), when warm-up data exists,
  /// and when warm-up hasn't already been done/skipped this session (so a
  /// tier-swap back to Easy doesn't re-show it). Otherwise proceeds straight to
  /// the working sets, mirroring the prior behaviour. Never blocks the workout:
  /// any fetch failure falls through to "no warm-up".
  Future<void> _resolveWarmupPhase() async {
    if (!mounted) return;
    final alreadyDone = ref.read(activeWorkoutWarmupDoneProvider);
    final hasLoggedSets =
        _perExercise.values.any((s) => s.completed.isNotEmpty);
    if (alreadyDone || hasLoggedSets || widget.workout.id == null) {
      _finishWarmupPhase();
      return;
    }
    final workoutId = widget.workout.id!;
    try {
      final repo = ref.read(workoutRepositoryProvider);
      // E2E #125 ask #3 — prefer the user's SAVED warm-up template (their
      // past add/remove/swap/duration/rest edits) over a fresh AI-generated
      // one. `applyWarmupTemplate` seeds THIS workout's own `warmups` row
      // from it server-side, so the per-workout persist in
      // `_persistWarmupList` above keeps working normally on top of it. A
      // miss (nothing saved yet) or any failure falls straight through to
      // the normal per-workout read below — never a fabricated warm-up.
      List<Map<String, dynamic>>? warm;
      try {
        warm = await repo.applyWarmupTemplate(workoutId);
      } catch (e) {
        debugPrint('⚠️ [EasyWorkout] warm-up template apply failed: $e');
      }
      warm ??= (await repo.fetchWarmupAndStretches(workoutId)).warmup;
      if (!mounted) return;
      if (warm != null && warm.isNotEmpty) {
        final built = [for (final m in warm) _warmupExerciseFrom(m)];
        setState(() {
          _warmupExercises = built;
          _warmupStates
            ..clear()
            ..addEntries([
              for (int i = 0; i < built.length; i++)
                MapEntry(
                  i,
                  EasyExerciseState(
                    displayWeight: 0,
                    reps: 0,
                    targetReps: 0,
                    targetWeightKg: 0,
                    totalSets: 1,
                    isTimed: true,
                    isBodyweight: true,
                    durationSeconds: built[i].holdSeconds ?? 30,
                  ),
                ),
            ]);
          _warmupIndex = 0;
          _warmupPhase = true;
          _warmupResolving = false;
        });
        return;
      }
    } catch (_) {
      // No warm-up / offline → proceed without one (never a hardcoded fallback).
    }
    _finishWarmupPhase();
  }

  /// Adapt a raw warm-up item map (`name` / `duration_seconds` / `exercise_id`
  /// …, as returned by `WorkoutRepository.fetchWarmupAndStretches`) into a
  /// `WorkoutExercise` so the shared Easy view can render it exactly like a
  /// working exercise — same media resolution, Instructions sheet, focal timer.
  WorkoutExercise _warmupExerciseFrom(Map<String, dynamic> m) {
    int durationOf() {
      final v = m['duration_seconds'] ??
          m['durationSeconds'] ??
          m['hold_seconds'] ??
          m['holdSeconds'];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 30;
      return 30;
    }

    int restOf() {
      final v = m['rest_seconds'] ?? m['restSeconds'];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 10;
      return 10; // matches the backend WarmupExercise schema's default
    }

    return WorkoutExercise(
      nameValue: m['name']?.toString() ?? 'Warm-up',
      exerciseId: m['exercise_id']?.toString() ?? m['exerciseId']?.toString(),
      holdSeconds: durationOf(),
      // E2E #125: carried through so a customized rest/duration round-trips
      // to `_warmupItemToJson` on the next persist — without this, an edit
      // followed immediately by ANOTHER edit (or a reorder) would silently
      // revert the first edit's rest value back to the server default.
      restSeconds: restOf(),
      isTimed: true,
      section: 'warmup',
      gifUrl: m['gif_url']?.toString() ?? m['gifUrl']?.toString(),
      imageS3Path:
          m['image_s3_path']?.toString() ?? m['imageS3Path']?.toString(),
      videoUrl: m['video_url']?.toString() ?? m['videoUrl']?.toString(),
      instructions: m['instructions']?.toString(),
      equipment: m['equipment']?.toString(),
      bodyPart: m['body_part']?.toString() ?? m['bodyPart']?.toString(),
      muscleGroup: m['muscle_group']?.toString() ?? m['muscleGroup']?.toString(),
    );
  }

  /// Serialize one warm-up move back to the raw shape the backend's
  /// `WarmupExercise` schema expects for `PUT /{id}/warmup/exercises`
  /// (`WorkoutRepository.saveWarmupStretchOrder`). `duration_seconds` is read
  /// from the LIVE per-move state (the user's ±5s nudges) when available, so
  /// an in-memory-only edit (E2E #125's core complaint) actually persists.
  Map<String, dynamic> _warmupItemToJson(int idx, WorkoutExercise ex) {
    final liveDuration = _warmupStates[idx]?.durationSeconds;
    return {
      'name': ex.name,
      'sets': 1,
      'duration_seconds': liveDuration ?? ex.holdSeconds ?? 30,
      'rest_seconds': ex.restSeconds ?? 10,
      'equipment': (ex.equipment == null || ex.equipment!.isEmpty)
          ? 'none'
          : ex.equipment,
      // Required, non-nullable server-side — 'general' is the same fallback
      // the backend itself uses when a resolved exercise carries none.
      'muscle_group': (ex.muscleGroup == null || ex.muscleGroup!.isEmpty)
          ? 'general'
          : ex.muscleGroup,
      if (ex.instructions != null) 'notes': ex.instructions,
    };
  }

  /// Persist the CURRENT `_warmupExercises` order/durations/rest to the
  /// server so a customized warm-up survives to the next run. Two writes:
  ///   1. THIS workout's `warmups` row (`saveWarmupStretchOrder`) — covers
  ///      re-entering the SAME workout (tier-swap, app restart mid-workout).
  ///   2. The user's SAVED warm-up template (`saveWarmupTemplate`,
  ///      `backend/api/v1/workouts/warmup_templates.py`, scoped by
  ///      `workout.type`) — the actual E2E #125 ask #3: carrying the edit
  ///      into the NEXT workout, which (1) alone does not do (a fresh
  ///      workout's `warmups` row is unrelated to a past one's). Read back
  ///      by `_resolveWarmupPhase` via `applyWarmupTemplate`.
  /// Both are best-effort — a failed persist doesn't block the workout; the
  /// next successful edit (or app session) retries with the latest state.
  Future<void> _persistWarmupList() async {
    final id = widget.workout.id;
    if (id == null || id.isEmpty || _warmupExercises.isEmpty) return;
    final list = [
      for (int i = 0; i < _warmupExercises.length; i++)
        _warmupItemToJson(i, _warmupExercises[i]),
    ];
    final repo = ref.read(workoutRepositoryProvider);
    try {
      await repo.saveWarmupStretchOrder(id, 'warmup', list);
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] warm-up persist failed: $e');
    }
    try {
      await repo.saveWarmupTemplate(
        workoutType: widget.workout.type,
        exercises: list,
      );
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] warm-up template save failed: $e');
    }
  }

  /// Re-seed `_warmupExercises`/`_warmupStates` from a freshly-fetched (or
  /// locally-composed) raw item list, preserving each move's session
  /// progress where the name still matches so an add/swap/remove mid-warm-up
  /// doesn't reset moves the user already completed.
  void _rebuildWarmupFrom(List<Map<String, dynamic>> raw, {int? focusIndex}) {
    final built = [for (final m in raw) _warmupExerciseFrom(m)];
    final newStates = <int, EasyExerciseState>{};
    for (int i = 0; i < built.length; i++) {
      newStates[i] = EasyExerciseState(
        displayWeight: 0,
        reps: 0,
        targetReps: 0,
        targetWeightKg: 0,
        totalSets: 1,
        isTimed: true,
        isBodyweight: true,
        durationSeconds: built[i].holdSeconds ?? 30,
      );
    }
    setState(() {
      _warmupExercises = built;
      _warmupStates
        ..clear()
        ..addAll(newStates);
      _warmupIndex = (focusIndex ?? _warmupIndex)
          .clamp(0, built.isEmpty ? 0 : built.length - 1);
    });
  }

  /// E2E #125 ask #1 — "+ Add a move". Reuses the SAME injury-screened,
  /// library-resolved add sheet the working-set list already uses
  /// (`section: 'warmup'` routes the backend write to the `warmups` table
  /// instead of `exercises_json` — see `add_exercise_to_workout` in
  /// `api/v1/workouts/workout_operations.py`). Appends, then re-fetches so
  /// the new move carries its server-resolved media/equipment.
  Future<void> _addWarmupMove() async {
    final id = widget.workout.id;
    if (id == null) return;
    final repo = ref.read(workoutRepositoryProvider);
    final result = await showExerciseAddSheet(
      context,
      ref,
      workoutId: id,
      workoutType: widget.workout.type ?? 'strength',
      section: 'warmup',
    );
    if (result == null || !mounted) return;
    HapticService.instance.success();
    final res = await repo.fetchWarmupAndStretches(id, forceRefresh: true);
    if (!mounted || res.warmup == null) return;
    _rebuildWarmupFrom(res.warmup!, focusIndex: res.warmup!.length - 1);
  }

  /// E2E #125 ask #1 — "Swap this move". There is no injury-screened
  /// warmup-swap endpoint (`POST /swap-exercise`'s `section` field is
  /// accepted but never actually branched on server-side — see report),
  /// so this composes swap from two EXISTING, already-safe primitives: the
  /// injury-screened `section: 'warmup'` ADD (appends the replacement),
  /// then a local splice + `saveWarmupStretchOrder` puts it where the old
  /// move was and drops the old move — one extra round-trip, zero new
  /// backend surface, and the replacement is screened exactly like a fresh
  /// add would be.
  Future<void> _swapWarmupMove(int idx) async {
    final id = widget.workout.id;
    if (id == null || idx < 0 || idx >= _warmupExercises.length) return;
    final repo = ref.read(workoutRepositoryProvider);
    final oldName = _warmupExercises[idx].name;
    final result = await showExerciseAddSheet(
      context,
      ref,
      workoutId: id,
      workoutType: widget.workout.type ?? 'strength',
      section: 'warmup',
    );
    if (result == null || !mounted) return;
    final res = await repo.fetchWarmupAndStretches(id, forceRefresh: true);
    if (!mounted || res.warmup == null || res.warmup!.isEmpty) return;
    // The add just appended — the new move is the last entry not matching
    // the pre-swap name at this position (append-only semantics of the
    // warmup add endpoint make "last item" the reliable signal).
    final withAppend = List<Map<String, dynamic>>.from(res.warmup!);
    final added = withAppend.removeLast();
    if (idx < withAppend.length) {
      withAppend[idx] = added; // replace the old move in place
    } else {
      withAppend.add(added);
    }
    HapticService.instance.success();
    _rebuildWarmupFrom(withAppend, focusIndex: idx);
    unawaited(_persistWarmupList());
    debugPrint('🔍 [EasyWorkout] swapped warm-up move "$oldName" → "${added['name']}"');
  }

  /// E2E #125 ask #1 — "Remove this move". Uses the general-purpose
  /// `PUT /{id}/warmup/exercises` (already backend-supported; no new
  /// endpoint needed) with the item spliced out.
  Future<void> _removeWarmupMove(int idx) async {
    if (idx < 0 || idx >= _warmupExercises.length) return;
    if (_warmupExercises.length == 1) {
      // Nothing left to warm up with — same as skipping the whole thing.
      _finishWarmupPhase();
      return;
    }
    HapticService.instance.tap();
    final list = [
      for (int i = 0; i < _warmupExercises.length; i++)
        if (i != idx) _warmupItemToJson(i, _warmupExercises[i]),
    ];
    final newFocus = idx >= list.length ? list.length - 1 : idx;
    _rebuildWarmupFrom(list, focusIndex: newFocus);
    unawaited(_persistWarmupList());
  }

  /// E2E #125 ask #2 — per-move rest, editable via the actions sheet.
  /// Cycles a common-preset ladder (the sheet closes on every tap, so a
  /// stepper the user nudges repeatedly would mean reopening it each time
  /// anyway — a cycle reaches every useful value in at most 5 taps).
  static const List<int> _kWarmupRestPresets = [0, 10, 20, 30, 45, 60];
  void _cycleWarmupRest(int idx) {
    if (idx < 0 || idx >= _warmupExercises.length) return;
    final ex = _warmupExercises[idx];
    final current = ex.restSeconds ?? 10;
    final i = _kWarmupRestPresets.indexOf(current);
    final next = _kWarmupRestPresets[
        i == -1 ? 0 : (i + 1) % _kWarmupRestPresets.length];
    setState(() {
      _warmupExercises[idx] = ex.copyWith(restSeconds: next);
    });
    HapticService.instance.tick();
    unawaited(_persistWarmupList());
  }

  /// "Log set" on a warm-up move → record the hold and advance. Warm-up holds
  /// never touch `_perExercise` / the session / PR detection, so they can't
  /// inflate volume, calories or personal records.
  Future<void> _logWarmupMove() async {
    final ex = _warmupExercises[_warmupIndex];
    final st = _warmupStates[_warmupIndex];
    (_warmupCompleted[ex.name] ??= []).add({
      'type': 'warmup_complete',
      'hold_seconds': st?.durationSeconds ?? ex.holdSeconds ?? 30,
    });
    await HapticService.instance.success();
    _advanceWarmup();
  }

  /// Move to the next warm-up move (via a rest interval when the finishing
  /// move has one configured — E2E #125 ask #2), or hand off to the working
  /// sets. Also persists the just-edited duration/rest/order (E2E #125 ask
  /// #3) — this is the point every warm-up flow (log/skip/skip-whole) passes
  /// through before leaving a move, so it's the natural save point.
  void _advanceWarmup() {
    unawaited(_persistWarmupList());
    final isLastMove = _warmupIndex + 1 >= _warmupExercises.length;
    final restSecs = _warmupExercises[_warmupIndex].restSeconds ?? 0;
    if (!isLastMove && restSecs > 0) {
      _startWarmupRest(restSecs);
      return;
    }
    _advanceWarmupIndexNow();
  }

  void _advanceWarmupIndexNow() {
    if (_warmupIndex + 1 >= _warmupExercises.length) {
      _finishWarmupPhase();
      return;
    }
    setState(() => _warmupIndex++);
  }

  /// E2E #125 ask #2 — an actual rest pause between warm-up moves (there was
  /// previously NO rest concept at all; every move ran back-to-back). A
  /// lightweight local countdown — not the shared working-set rest overlay,
  /// which is built around a weight×reps target the warm-up doesn't have.
  bool _warmupResting = false;
  int _warmupRestRemaining = 0;
  // The duration this countdown STARTED at — `WarmupRestOverlay`'s draining
  // progress bar needs it alongside the ticking `_warmupRestRemaining`, so the
  // remaining number has a scale rather than being a bare "8s".
  int _warmupRestTotal = 0;
  Timer? _warmupRestTimer;

  void _startWarmupRest(int seconds) {
    _warmupRestTimer?.cancel();
    setState(() {
      _warmupResting = true;
      _warmupRestRemaining = seconds;
      _warmupRestTotal = seconds;
    });
    _warmupRestTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_warmupRestRemaining <= 1) {
        t.cancel();
        setState(() => _warmupResting = false);
        _advanceWarmupIndexNow();
      } else {
        setState(() => _warmupRestRemaining--);
      }
    });
  }

  void _skipWarmupRest() {
    HapticService.instance.tap();
    _warmupRestTimer?.cancel();
    setState(() => _warmupResting = false);
    _advanceWarmupIndexNow();
  }

  void _skipWarmupMove() {
    HapticService.instance.tap();
    _advanceWarmup();
  }

  /// Abandon the remaining warm-up moves and start the working sets. Whatever
  /// the user already completed is still persisted by [_finishWarmupPhase].
  void _skipWholeWarmup() {
    HapticService.instance.tap();
    _finishWarmupPhase();
  }

  /// Jump the focal card to another warm-up move (the Plan sheet's row tap).
  void _jumpWarmupTo(int idx) {
    if (_warmupExercises.isEmpty) return;
    setState(
      () => _warmupIndex = idx.clamp(0, _warmupExercises.length - 1),
    );
  }

  /// Fire-and-forget persistence of the completed warm-up moves. Failure is
  /// non-blocking (the warm-up is done regardless) — matches the existing
  /// warm-up-interval persistence contract.
  void _persistWarmupLogs() {
    final id = widget.workout.id;
    if (id == null || id.isEmpty || _warmupCompleted.isEmpty) return;
    final payload = {
      for (final e in _warmupCompleted.entries)
        e.key: List<Map<String, dynamic>>.from(e.value),
    };
    _warmupCompleted.clear();
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).post(
          '${ApiConstants.workouts}/$id/warmup-logs',
          data: {'intervals': payload},
        );
      } catch (_) {
        // Non-blocking — the workout still proceeds.
      }
    }());
  }

  /// The ⋯ actions available on a warm-up move.
  ///
  /// E2E #125 — the warm-up used to be completely non-editable: every
  /// callback into `EasyActiveWorkoutView` was nulled out (see the file's
  /// class doc), so this sheet was the ONLY affordance — skip/quit/video/
  /// water. Add/Swap/Remove + a Rest stepper now live here too.
  void _showWarmupActions() {
    if (_warmupExercises.isEmpty) return;
    final idx = _warmupIndex;
    final ex = _warmupExercises[idx];
    final isLast = idx >= _warmupExercises.length - 1;
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        showHandle: true,
        child: EasyExerciseActionsSheet(
          exerciseName: ex.name,
          // "What's this?" — warm-up moves are the ones users are least
          // likely to recognise by name (E2E: "I do not understand what is
          // inchworm").
          onShowInfo: () => openEasyInfoSheet(context, ex),
          actions: [
            EasyExerciseAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Swap this move',
              onTap: () => unawaited(_swapWarmupMove(idx)),
            ),
            EasyExerciseAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add a move',
              onTap: () => unawaited(_addWarmupMove()),
            ),
            if (_warmupExercises.length > 1)
              EasyExerciseAction(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Remove this move',
                onTap: () => unawaited(_removeWarmupMove(idx)),
                destructive: true,
              ),
            EasyExerciseAction(
              icon: Icons.timer_outlined,
              label: 'Rest after this move: ${ex.restSeconds ?? 10}s',
              subtitle: 'Tap to cycle 0 / 10 / 20 / 30 / 45 / 60s',
              onTap: () => _cycleWarmupRest(idx),
            ),
            EasyExerciseAction(
              icon: Icons.skip_next_rounded,
              label: isLast ? 'Start working sets' : 'Skip this move',
              onTap: _advanceWarmup,
            ),
            EasyExerciseAction(
              icon: Icons.fast_forward_rounded,
              label: 'Skip the whole warm-up',
              subtitle: '${_warmupExercises.length - idx} moves left',
              onTap: _finishWarmupPhase,
            ),
            EasyExerciseAction(
              icon: Icons.play_circle_outline_rounded,
              label: 'Show video',
              onTap: () => openEasyVideo(
                context,
                ex,
                ref: ref,
                playlist: _warmupExercises,
                playlistIndex: idx,
              ),
            ),
            EasyExerciseAction(
              icon: Icons.local_drink_outlined,
              label: 'Log a cup of water',
              onTap: _logWaterCup,
            ),
            EasyExerciseAction(
              icon: Icons.close_rounded,
              label: AppLocalizations.of(context).easyActiveWorkoutQuitWorkout,
              onTap: _quitWorkout,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Leave the warm-up phase → working sets. Marks warm-up done (so Advanced
  /// won't re-warmup on a tier swap) and shows the first-run help. Called from
  /// the runner's onDone (finished OR skipped) and the no-warmup path.
  void _finishWarmupPhase() {
    if (!mounted) return;
    // Save whatever warm-up work was actually done before leaving the phase.
    _persistWarmupLogs();
    // Clear both the active phase and the resolving placeholder so the build
    // falls through to the working sets (covers the no-warm-up / error paths).
    if (_warmupPhase || _warmupResolving) {
      setState(() {
        _warmupPhase = false;
        _warmupResolving = false;
      });
    }
    ref.read(activeWorkoutWarmupDoneProvider.notifier).state = true;
    // First-run Easy walkthrough — the shared spotlight tour (same
    // `tour_seen_easy` flag the old bottom-card used, so existing users who
    // saw onboarding aren't re-shown). Fired post-frame so the AppTourKeys
    // anchors on the exercise header + focal column are mounted and the
    // spotlight can find them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WorkoutTourService.maybeShowForTier(ref, WorkoutUiMode.easy);
      }
    });
  }

  @override
  void dispose() {
    _tourSeenSub?.close();
    _timer.dispose();
    _restBroadcaster?.dispose();
    // E2E register row 125: the warm-up rest countdown is a Timer.periodic. It
    // guards on `mounted` inside the tick, but an uncancelled timer still keeps
    // firing (and holding this State alive) after the screen is gone — cancel
    // it here rather than relying on the guard.
    _warmupRestTimer?.cancel();
    super.dispose();
  }

  void _setWeight(double v) {
    setState(() {
      final st = _perExercise[_currentIndex]!;
      st.displayWeight = v;
      st.userEditedWeight = true;
      // Keep canonical kg in sync so a kg↔lb toggle re-derives from kg and
      // never drifts on coarse-step equipment. Only when adjusting the LIVE
      // set target — not while editing a previously-logged set.
      if (_editingSetIndex == null) {
        final useKg = ref.read(useKgForWorkoutProvider);
        st.targetWeightKg = useKg ? v : v / 2.20462;
      }
    });
    HapticService.instance.tick();
  }

  void _setReps(double v) {
    setState(() => _perExercise[_currentIndex]!.reps = v.round());
    HapticService.instance.tick();
  }

  void _setDuration(double v) {
    setState(() => _perExercise[_currentIndex]!.durationSeconds = v.round());
    HapticService.instance.tick();
  }

  /// Edit a dynamic EXTRA metric (box_height, calories, custom…) for the
  /// current set. Keyed by metric KEY; snapshotted to the SetLog on log.
  void _setExtraMetric(String key, double value) {
    setState(() {
      _perExercise[_currentIndex]!.extraMetrics[key] = value;
    });
    HapticService.instance.tick();
  }

  /// "+ metric" — open the picker, persist the chosen column to this exercise's
  /// prefs, and optimistically surface it so the new stepper appears at once.
  Future<void> _addMetric() async {
    final exercise = _exercises[_currentIndex];
    final exId = exercise.exerciseId ?? exercise.libraryId ?? exercise.name;
    final st = _perExercise[_currentIndex]!;
    // Hide every column already on the exercise (the four standard ones live in
    // the profile; the extras are what we render) from the add list.
    final currentKeys = <String>{
      ...exercise.trackingProfile.metricKeys,
      ...st.extraMetricKeys,
    }.toList();
    final chosen =
        await MetricPickerSheet.show(context, currentKeys: currentKeys);
    if (chosen == null || !mounted) return;
    // Persist as the user's per-exercise EXTRA prefs (defaults stay implicit).
    final prefs =
        ref.read(exerciseMetricPrefsProvider(exId)).valueOrNull ?? const [];
    final nextPrefs = <String>[...prefs, if (!prefs.contains(chosen)) chosen];
    await ref
        .read(exerciseMetricsServiceProvider)
        .saveExerciseMetricKeys(exId, nextPrefs);
    if (!mounted) return;
    setState(() {
      if (!st.extraMetricKeys.contains(chosen)) st.extraMetricKeys.add(chosen);
    });
  }

  void _setDistance(double v) {
    setState(() =>
        _perExercise[_currentIndex]!.distanceMeters = v.clamp(0, 100000));
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
    final ex = _exercises[_currentIndex];
    final displayWeight = useKg
        ? log.weight
        : kgToDisplayLbs(log.weight, ex.equipment, exerciseName: ex.name);
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
        state.completed.add(
          SetLog(
            reps: 0,
            weight: 0,
            targetReps: state.targetReps,
            startedAt: null,
            durationSeconds: 0,
            loggingMode: 'easy',
          ),
        );
      }
      // Load target values into the focal stepper for the new current set.
      final targetWeightKg = state.targetWeightKg;
      final ex = _exercises[_currentIndex];
      state.displayWeight = useKg
          ? targetWeightKg
          : kgToDisplayLbs(targetWeightKg, ex.equipment, exerciseName: ex.name);
      state.reps = state.targetReps;
      _editingSetIndex = null;
    });
    // WF4 — _skipToSet appends placeholder SetLogs straight onto
    // `state.completed` without going through recordSet, so mirror the full
    // map into the session or those placeholders are lost on a restore.
    _syncEasySessionSets();
  }

  /// WF4 — push the full per-exercise completed-sets map into the shared
  /// session so the on-disk checkpoint exactly mirrors what the user has
  /// logged. Used by paths that mutate `state.completed` outside the normal
  /// recordSet/replaceSet append-or-replace flow.
  void _syncEasySessionSets() {
    final snapshot = <int, List<SetLog>>{};
    _perExercise.forEach((idx, st) {
      snapshot[idx] = List<SetLog>.from(st.completed);
    });
    ref.read(activeWorkoutSessionProvider.notifier).syncSets(snapshot);
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

      await Future.wait(
        List.generate(_exercises.length, (i) async {
          final ex = _exercises[i];
          try {
            final data = await repo.getExerciseLastPerformance(
              userId: userId,
              exerciseName: ex.name,
            );
            if (data == null) return;
            final sets = data['sets'];
            if (sets is! List || sets.isEmpty) return;
            final first = sets.first;
            if (first is! Map) return;
            final wKg = (first['weight'] as num?)?.toDouble();
            final reps = (first['reps'] as num?)?.toInt();
            final completedAtRaw =
                data['completed_at'] ?? first['completed_at'];
            DateTime? when;
            if (completedAtRaw is String) {
              when = DateTime.tryParse(completedAtRaw)?.toLocal();
            }
            if (wKg == null || reps == null || wKg <= 0 || when == null) return;
            _lastSetByEx[i] = (weightKg: wKg, reps: reps, when: when);
          } catch (_) {
            /* swallow per-exercise failure */
          }
        }),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] last-set preload failed: $e');
    }
  }

  /// Pre-fill each exercise's focal weight using the same smart-weight
  /// pipeline that Advanced mode uses (`/workouts/smart-weight/...`). Easy
  /// previously seeded straight from the plan's `targetWeightKg`, which
  /// diverged from Advanced's intelligent suggestion and produced confusing
  /// numbers when the plan had no per-set target. This brings the two modes
  /// to parity — same backend formula, same equipment-aware rounding.
  /// Failures are swallowed; the seeded value remains.
  Future<void> _preloadSmartWeightPerExercise() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null || _exercises.isEmpty) return;
      final useKg = ref.read(useKgForWorkoutProvider);

      await Future.wait(
        List.generate(_exercises.length, (i) async {
          final ex = _exercises[i];
          final state = _perExercise[i];
          if (state == null) return;
          // Skip bodyweight exercises — they have no external weight.
          final equipment = (ex.equipment ?? 'dumbbell').toLowerCase();
          if (equipment.contains('bodyweight') || equipment == 'none') return;
          final firstTarget = ex.getTargetForSet(1);
          final targetReps = firstTarget?.targetReps ?? ex.reps ?? 10;
          try {
            final suggestion = await WeightSuggestionService.getSmartWeight(
              dio: apiClient.dio,
              userId: userId,
              exerciseId: ex.exerciseId ?? ex.libraryId ?? '',
              exerciseName: ex.name,
              targetReps: targetReps,
              equipment: equipment,
            );
            if (suggestion == null || suggestion.suggestedWeight <= 0) return;
            if (!mounted) return;
            // Don't clobber a value the user has already logged OR manually
            // edited (the edit can land before the first set is logged, so the
            // logged-set guard alone isn't enough — also check userEditedWeight).
            if (state.completed.isNotEmpty || state.userEditedWeight) return;
            final kg = suggestion.suggestedWeight;
            setState(() {
              state.targetWeightKg = kg;
              // Equipment-aware snap (same pipeline as Advanced), not raw ×2.20462.
              state.displayWeight = useKg
                  ? kg
                  : kgToDisplayLbs(kg, ex.equipment, exerciseName: ex.name);
            });
          } catch (_) {
            /* swallow per-exercise failure */
          }
        }),
      );
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] smart-weight preload failed: $e');
    }
  }

  /// B6 — preload each exercise's Strength-Score target (the weight×reps that
  /// would level up its primary muscle's score). Deduped by muscle so a
  /// chest day with 3 chest moves issues ONE request. Each target's
  /// `target_reps` is anchored to the exercise's first planned set so the pill
  /// number matches what the user is about to do. Failures are swallowed; the
  /// pill simply doesn't render for that exercise.
  Future<void> _preloadScoreTargetsPerExercise() async {
    try {
      if (_exercises.isEmpty) return;
      await Future.wait(
        List.generate(_exercises.length, (i) async {
          final ex = _exercises[i];
          final muscle =
              (ex.primaryMuscle ?? ex.muscleGroup ?? ex.bodyPart ?? '')
                  .trim()
                  .toLowerCase();
          if (muscle.isEmpty) return;
          final targetReps = ex.getTargetForSet(1)?.targetReps ?? ex.reps ?? 8;
          final exName = (ex.name).trim();
          final equip = (ex.equipment ?? '').trim();
          try {
            // Cache by (muscle, reps, exercise, equipment): the target is now
            // exercise-aware (different exercises on the same muscle can differ,
            // and bodyweight moves return a rep goal), so the key must include
            // exercise identity — keying by muscle alone made every exercise on
            // a muscle show the identical (often nonsensical) target.
            final cacheKey = '$muscle|$targetReps|$exName|$equip';
            ScoreTarget? target;
            if (_scoreTargetByMuscle.containsKey(cacheKey)) {
              target = _scoreTargetByMuscle[cacheKey];
            } else {
              target = await ScoreTargetService.fetch(
                ref: ref,
                muscleGroup: muscle,
                targetReps: targetReps,
                exerciseName: exName,
                equipment: equip,
              );
              _scoreTargetByMuscle[cacheKey] = target;
            }
            _scoreTargetByEx[i] = target;
          } catch (_) {
            /* swallow per-exercise failure */
          }
        }),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ [EasyWorkout] score-target preload failed: $e');
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
    final editing = idx != null && idx >= 0 && idx < state.completed.length;

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

    final weightKg = useKg
        ? state.displayWeight
        : state.displayWeight * 0.453592;

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
          // Preserve the metric-bag + distance captured when the set was first
          // logged — a weight/reps correction must not drop them.
          distanceMeters: original.distanceMeters,
          extraMetrics: original.extraMetrics,
          loggingMode: 'easy',
        );
        state.completed[idx] = updated;
        ref
            .read(activeWorkoutSessionProvider.notifier)
            .replaceSet(_currentIndex, idx, updated);

        // PERSIST the correction.
        //
        // This used to return here with "Backend re-syncs via plan save" — it
        // does not. Easy POSTs each set to /performance/logs as it happens, and
        // the finish path only PATCHes workout_logs.sets_json; it never
        // revisits the performance_logs rows it already wrote. So an edit
        // updated the pill and the session volume while the database kept the
        // ORIGINAL set forever — verified in production: the UI read "1 5x12"
        // and recalculated volume 1,968 -> 1,536 kg while performance_logs
        // still held reps_completed 10 / weight_kg 0.
        //
        // performance_logs is what History, PRs and volume analytics read, so
        // the divergence is silent and permanent. Addressed by natural key
        // (workout_log_id, exercise_name, set_number) because Easy only keeps
        // the parent log id, never the per-set row id.
        //
        // Fire-and-forget with a logged failure: a correction must not block
        // the user's next set, but it must not fail silently either.
        final logId = _workoutLogId;
        if (logId != null) {
          unawaited(
            ref
                .read(workoutRepositoryProvider)
                .updateLoggedSet(
                  workoutLogId: logId,
                  exerciseName: exercise.name,
                  setNumber: idx + 1,
                  repsCompleted: updated.reps,
                  weightKg: updated.weight,
                )
                .catchError((Object e) {
              debugPrint('❌ [EasySet] set-correction persist failed: $e');
            }),
          );
        } else {
          debugPrint(
            '⚠️ [EasySet] no workout_log id yet — correction is local only',
          );
        }
      }
      await HapticService.instance.success();
      _returnToCurrentSet();
      // No rest timer and no PR detection: editing a past set is a correction,
      // not a new rep.
      return;
    }

    // E2E #76 (Easy mirror of set_logging_mixin): the elapsed time since this
    // set became active is IDLE time, not set time — `_currentSetStartTime` is
    // stamped on screen open / rest-complete, not when the lifter starts
    // working. A rep set has no client-observable start, so no duration is
    // invented for one. Timed sets below still write `state.durationSeconds`,
    // which IS the measured hold.
    const int? setDuration = null;

    // Timed exercises (planks, wall sits): the user-entered hold seconds
    // ARE the metric — write them into durationSeconds and zero out
    // weight/reps so volume/PR math stays correct. Distance moves (SkiErg,
    // sled, carries) write the meters into distanceMeters, zero weight/reps.
    final isTimed = state.isTimed;
    final isDistance = state.isDistance;
    // Loaded carries (sled push, prowler, yoke, farmer's carry, weighted hold)
    // track a LOAD alongside their distance/time metric. Persist the weight
    // instead of zeroing it so the set logs e.g. 60 kg over 20 m. Pure
    // distance/time moves (SkiErg, plank) still zero out the load.
    final isLoadedCarry = (isTimed || isDistance) && weightKg > 0;
    // Snapshot the dynamic EXTRA metrics (box_height, calories, custom…) into
    // the canonical metric bag, keyed by bagKey (KEY→bagKey). Mirrors Advanced
    // `SetLog.extraMetrics`. Zero/absent values are dropped.
    final extraBag = <String, num>{
      for (final e in state.extraMetrics.entries)
        if (e.value != 0)
          (kMetricCatalog[e.key]?.bagKey ?? e.key): e.value,
    };
    final setLog = SetLog(
      reps: (isTimed || isDistance) ? 0 : state.reps,
      weight: ((isTimed || isDistance) && !isLoadedCarry) ? 0 : weightKg,
      targetReps: state.targetReps,
      startedAt: _currentSetStartTime,
      durationSeconds: isTimed ? state.durationSeconds : setDuration,
      distanceMeters: isDistance ? state.distanceMeters : null,
      extraMetrics: extraBag,
      loggingMode: 'easy',
      notes: _pendingNoteText.trim().isNotEmpty
          ? [_pendingNoteText.trim()]
          : const [],
      notesAudioPath: _pendingNoteAudioPath,
      notesPhotoPaths: List.unmodifiable(_pendingNotePhotoPaths),
    );
    state.completed.add(setLog);
    // Mirror into the shared session so a tier swap (Easy → Advanced)
    // sees the same logged sets.
    ref
        .read(activeWorkoutSessionProvider.notifier)
        .recordSet(_currentIndex, setLog);
    // Clear pending note staging so the next set starts clean.
    _pendingNoteText = '';
    _pendingNoteAudioPath = null;
    _pendingNotePhotoPaths = const [];
    await HapticService.instance.success();

    detectEasyPRs(
      service: _prService,
      log: setLog,
      exercise: exercise,
      state: state,
    );

    if (widget.workout.id != null) {
      await _persistEasySetTracked(exercise: exercise, log: setLog, state: state);
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

  /// Chokepoint for every Easy-tier set-persist call (natural per-set
  /// logging in `_logCurrentSet` AND the "Complete workout now" padding
  /// loop) — delegates to [persistEasySetSerialized] against the shared
  /// [_workoutLogIdHolder] so a tight loop of persists can't race
  /// `createWorkoutLog` (E2E #175 — see the helper's doc comment for the
  /// full mechanism: 27 identical `POST /performance/workout-logs` for one
  /// completion because every padded set read the same stale, still-null
  /// id before the previous call's `.then()` had a chance to run).
  Future<void> _persistEasySetTracked({
    required WorkoutExercise exercise,
    required SetLog log,
    required EasyExerciseState state,
  }) async {
    if (widget.workout.id == null) return;
    await persistEasySetSerialized(
      ref: ref,
      exercise: exercise,
      log: log,
      state: state,
      workoutId: widget.workout.id!,
      totalTimeSeconds: _timer.workoutSeconds,
      holder: _workoutLogIdHolder,
    );
  }

  void _startRest(int seconds, {required bool finishedExercise}) {
    _restBroadcaster?.dispose();
    final target = resolveEasyNextTarget(
      finishedExercise: finishedExercise,
      currentIndex: _currentIndex,
      exercises: _exercises,
      perExercise: _perExercise,
    );
    if (mounted) setState(() => _isResting = true);
    _restBroadcaster = startEasyRest(
      context: context,
      timer: _timer,
      seconds: seconds,
      target: target,
      useKg: ref.read(useKgForWorkoutProvider),
      onLogWater: _logWaterCup,
    );
  }

  void _handleRestComplete() {
    if (mounted) setState(() => _isResting = false);
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
      ref.read(activeWorkoutSessionProvider.notifier).setCurrentIndex(next);
      return;
    }
    // Re-seed working values for the NEXT set from target table / last log.
    final st = _perExercise[_currentIndex]!;
    final nextSetNumber = st.completed.length + 1;
    final target = _exercises[_currentIndex].getTargetForSet(nextSetNumber);
    if (target != null) {
      final useKg = ref.read(useKgForWorkoutProvider);
      final ex = _exercises[_currentIndex];
      final targetKg = (target.targetWeightKg ?? st.targetWeightKg).toDouble();
      setState(() {
        st.targetReps = target.targetReps;
        st.targetWeightKg = targetKg;
        st.reps = target.targetReps;
        // Per-set target carries its own (possibly pyramid) weight; snap it the
        // same equipment-aware way as the initial seed so steppers stay clean.
        st.displayWeight = useKg
            ? targetKg
            : kgToDisplayLbs(targetKg, ex.equipment, exerciseName: ex.name);
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
    ref.read(activeWorkoutSessionProvider.notifier).setCurrentIndex(next);
    _currentSetStartTime = DateTime.now();
  }

  /// Open the per-exercise actions sheet (Swap / Report pain / Change
  /// equipment / Skip / Video). Reachable from the "•••" header chip and
  /// from a long-press on the focal column body. Easy mode previously had
  /// NO swap path mid-workout; this wiring is the fix.
  /// Quick per-equipment weight-increment picker (the +/− step). Persists via
  /// weightIncrementsProvider, so the focal stepper immediately uses the new
  /// step. Answers "where do I set the increment per exercise/equipment".
  void _showIncrementPicker(String? equipment) {
    final incState = ref.read(weightIncrementsProvider);
    final unit = incState.unitSuffix; // 'kg' | 'lbs'
    final opts = unit == 'lbs'
        ? const <double>[2.5, 5, 10, 25]
        : const <double>[1, 2.5, 5, 10, 20];
    final current = incState.getIncrement(equipment);
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Weight increment · ${equipment ?? 'default'}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ...opts.map((o) {
              final sel = (o - current).abs() < 0.001;
              return ListTile(
                title: Text('${fmt(o)} $unit'),
                trailing: sel ? const Icon(Icons.check_rounded) : null,
                onTap: () async {
                  await ref
                      .read(weightIncrementsProvider.notifier)
                      .setIncrement(equipment ?? '', o);
                  await HapticService.instance.success();
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showExerciseActions() {
    if (_currentIndex >= _exercises.length) return;
    final exercise = _exercises[_currentIndex];
    final workoutId = widget.workout.id;
    final incNow = ref.read(weightIncrementsProvider);
    final incVal = incNow.getIncrement(exercise.equipment);
    final incLabel =
        '${incVal == incVal.roundToDouble() ? incVal.toStringAsFixed(0) : incVal} ${incNow.unitSuffix} · ${exercise.equipment ?? 'default'}';
    EasyExerciseActionsSheet.show(
      context,
      exerciseName: exercise.name,
      // "What's this?" in the sheet header — an unfamiliar move name is now
      // one tap from an explanation instead of a guess.
      onShowInfo: () => openEasyInfoSheet(context, exercise),
      onSwap: () async {
        if (workoutId == null) return;
        final updated = await showExerciseSwapSheet(
          context,
          ref,
          workoutId: workoutId,
          exercise: exercise,
        );
        if (updated == null || !mounted) return;
        // Replace the swapped exercise in our local list and reseed its
        // per-exercise state so the focal column rerenders against the new
        // movement (sets/reps/weight/duration). Other exercises retain
        // their completed-set state. We rebuild the full seed map and keep
        // each surviving exercise's prior `completed` list — index alignment
        // holds because swapExercise replaces in-place at the same index.
        setState(() {
          final oldPerExercise = Map<int, EasyExerciseState>.from(_perExercise);
          _exercises
            ..clear()
            ..addAll(updated.exercises);
          // LIFTED-weight unit, not BODY-weight unit. This site read
          // `useKgProvider` (body measurements) while initState — and every
          // label on this screen — reads `useKgForWorkoutProvider`. For a user
          // who weighs in kg but lifts in lb (the settings are deliberately
          // separate) an exercise swap re-seeded EVERY exercise's target in kg
          // while the stepper label still said LB.
          final useKg = ref.read(useKgForWorkoutProvider);
          final reseeded = seedEasyExerciseStates(_exercises, useKg: useKg);
          for (final entry in reseeded.entries) {
            final old = oldPerExercise[entry.key];
            if (old != null && entry.key != _currentIndex) {
              // Preserve in-progress state for non-swapped exercises.
              _perExercise[entry.key] = entry.value
                ..completed.clear()
                ..completed.addAll(old.completed)
                ..displayWeight = old.displayWeight
                ..reps = old.reps
                ..durationSeconds = old.durationSeconds
                ..distanceMeters = old.distanceMeters
                ..extraMetrics.addAll(old.extraMetrics);
            } else {
              _perExercise[entry.key] = entry.value;
            }
          }
        });
        // WF4 — the swap reseeds the swapped exercise with an empty
        // completed list; mirror the full map so the checkpoint doesn't keep
        // the pre-swap sets for that index.
        _syncEasySessionSets();
        // Publish the mutated workout so the swap survives an Easy<->Advanced
        // tier switch (the other tier remounts from this shared override).
        ref.read(activeWorkoutLiveProvider.notifier).state = updated;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).easyActiveWorkoutExerciseSwapped,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReportPain: () async {
        await ReportPainSheet.show(
          context,
          exerciseName: exercise.name,
          exerciseId: exercise.id ?? exercise.libraryId,
          bodyPart: exercise.muscleGroup ?? exercise.bodyPart,
          // Active workout id → swap the aggravators at the ≥4/10 threshold (#3).
          workoutId: widget.workout.id,
          // #179: base for the sheet's own live-provider re-sync if the
          // engine reshapes today's session. The sheet prefers whatever's
          // already in activeWorkoutLiveProvider (e.g. an earlier swap this
          // session) over this snapshot when the ids match.
          activeWorkout: widget.workout,
        );
        // The avoided-list provider already invalidates today/all-workouts
        // caches; for the *current* session we leave the exercise in place
        // unless the user also taps Skip / Swap. (User explicitly preferred
        // not to disrupt the active set on a soft pain flag.)
      },
      onChangeEquipment: () {
        showChangeEquipmentForActiveWorkout(
          context,
          ref,
          activeWorkout: widget.workout,
        );
      },
      onSkipToNext: _skipToNextExercise,
      onShowVideo: () => openEasyVideo(context, exercise,
          ref: ref, playlist: _exercises, playlistIndex: _currentIndex),
      onSetIncrement: () => _showIncrementPicker(exercise.equipment),
      incrementLabel: incLabel,
      onCompleteWorkout: _completeWorkoutNow,
      onQuitWorkout: _quitWorkout,
      onLogWater: _logWaterCup,
    );
  }

  /// Logs one cup (250 ml) of water via the shared hydration path. Reused by
  /// the ⋯ actions sheet AND the 💧 control on the inline rest strip.
  Future<void> _logWaterCup() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;
    final ok = await ref
        .read(hydrationProvider.notifier)
        .quickLog(userId: userId, amountMl: 250);
    if (!mounted) return;
    if (ok) {
      await HapticService.instance.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged a cup of water'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _jumpTo(int idx) {
    setState(() => _currentIndex = idx.clamp(0, _exercises.length - 1));
    ref
        .read(activeWorkoutSessionProvider.notifier)
        .setCurrentIndex(_currentIndex);
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

    // "Complete workout now" can fire straight from a warm-up move, which
    // never reaches _finishWarmupPhase — flush the warm-up logs here too so
    // completed warm-up work is never silently dropped.
    _persistWarmupLogs();

    _timer.stopWorkoutTimer();
    _restBroadcaster?.dispose();
    _restBroadcaster = null;

    // WF8 — compute the completion-screen aggregates locally (pure-Dart, no
    // I/O) so we can navigate to `/workout-complete` on this frame instead
    // of awaiting `/complete`. The backend save runs fire-and-forget below.
    final aggregates = computeEasyAggregates(
      workout: widget.workout,
      exercises: _exercises,
      perExercise: _perExercise,
    );

    // WF7 — make sure the completion-screen prewarmer has run so the screen
    // renders with stats populated, no spinner wave. Idempotent.
    unawaited(WorkoutCompletionPrewarmer.warm(ref));

    // WF8/WF9 — backend save off the navigation path. Failures (offline /
    // 5xx) are enqueued + replayed on reconnect inside runEasyBackgroundSave.
    unawaited(
      runEasyBackgroundSave(
        ref: ref,
        workout: widget.workout,
        aggregates: aggregates,
        totalTimeSeconds: _timer.workoutSeconds,
        workoutLogId: _workoutLogId,
      ),
    );

    // Tell any background "mini player" the workout is over and clear
    // the active-workout phase flag so re-entry restarts cleanly.
    ref.read(workoutMiniPlayerProvider.notifier).close();
    ref.read(activeWorkoutWarmupDoneProvider.notifier).state = false;
    // Wipe the shared session (also deletes the WF4 on-disk checkpoint) so
    // the next workout starts clean and a finished workout can't be resumed.
    ref.read(activeWorkoutSessionProvider.notifier).clear();

    if (!mounted) return;
    context.go(
      '/workout-complete',
      extra: <String, dynamic>{
        'workout': widget.workout,
        'duration': _timer.workoutSeconds,
        'calories': aggregates.calories,
        'workoutLogId': _workoutLogId,
        'exercisesPerformance': aggregates.exercisesPerformance,
        'exerciseSets': aggregates.exerciseSets,
        'totalSets': aggregates.totalSets,
        'totalReps': aggregates.totalReps,
        'totalVolumeKg': aggregates.totalVolumeKg,
        // PRs / performance comparison resolve in the background save; the
        // completion screen renders its calm "Saved" state and upgrades
        // silently when they arrive. Null here is expected, not an error.
        'personalRecords': null,
        'performanceComparison': null,
        'isFirstWorkout': false,
      },
    );
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
        title: Text(
          AppLocalizations.of(context).workoutFlowMixinCompleteWorkoutNow,
        ),
        content: const Text(
          'Any sets you haven’t logged will be saved as zero (0 weight, '
          '0 reps). You’ll go straight to the workout summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).workoutFlowMixinKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context).workoutFlowMixinComplete),
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
          // Routed through `_persistEasySetTracked` (E2E #175), NOT a bare
          // unawaited `persistEasySet` — this loop has no natural pause
          // between iterations, so a bare fire-and-forget call here raced
          // every padded set against the same stale `_workoutLogId` and
          // fired one `createWorkoutLog` per set. `_persistEasySetTracked`
          // awaits only while the log id is still unknown (i.e. at most the
          // very first padded set); once it's cached, later iterations stay
          // fire-and-forget exactly as before — the UI still isn't blocked
          // on each individual set's round trip.
          await _persistEasySetTracked(
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
          );
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
        title: Text(AppLocalizations.of(context).easyActiveWorkoutQuitWorkout),
        content: const Text(
          'Your logged sets will still be saved. You can resume this '
          'workout from Today any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).workoutFlowMixinKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent), // accent-allowlist: destructive Quit-workout confirmation action — must stay red regardless of accent
            child: Text(AppLocalizations.of(context).easyActiveWorkoutQuit),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      // Warm-up moves the user actually completed before quitting are still
      // real work — save them before tearing the session down.
      _persistWarmupLogs();
      // Clear the shared session — user explicitly walked away. Re-entry
      // should rehydrate from persisted server data, not stale memory.
      ref.read(activeWorkoutSessionProvider.notifier).clear();
      // Use pop() (NOT maybePop) — the screen's PopScope(canPop: false)
      // intercepts maybePop()/system-back to show THIS confirm; a direct
      // pop bypasses the guard so the confirmed Quit actually leaves.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Warm-up is eligible but its data hasn't resolved yet — show a neutral
    // placeholder on the Easy screen's OWN background so neither the working
    // sets nor the warm-up move flashes in with a colour change behind it.
    if (_warmupResolving && _warmupExercises.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = AccentColorScope.of(context).getColor(isDark);
      return Scaffold(
        backgroundColor: isDark ? AppColors.background : Colors.white,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
          ),
        ),
      );
    }

    // Warm-up phase — rendered by the SAME view as a working exercise, so the
    // user never crosses into a second, differently-shaped screen mid-workout.
    if (_warmupPhase && _warmupExercises.isNotEmpty) {
      return _buildWarmupView(context);
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
          // Re-derive the display value from the CANONICAL kg, not from the
          // old display value. Converting the display each flip drifts on
          // coarse-step equipment (62.5kg → 140lb → 65kg); going kg→display
          // every time is lossless. While editing a previously-logged set on
          // the current exercise, the focal stepper is showing that log's
          // value — convert it directly so the in-progress edit is preserved.
          if (_editingSetIndex != null && i == _currentIndex) {
            final raw = next
                ? s.displayWeight * 0.453592
                : s.displayWeight * 2.20462;
            s.displayWeight = snapToRealIncrement(
              raw,
              ex.equipment,
              exerciseName: ex.name,
              useKg: next,
            );
          } else {
            s.displayWeight = next
                ? s.targetWeightKg
                : kgToDisplayLbs(
                    s.targetWeightKg,
                    ex.equipment,
                    exerciseName: ex.name,
                  );
          }
        }
      });
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final useKg = ref.watch(useKgForWorkoutProvider);

    final exercise = _exercises[_currentIndex];
    final state = _perExercise[_currentIndex]!;
    final currentSetNumber = state.completedCount + 1;

    // EXTRA metric columns = the exercise's effective metrics (classifier
    // profile ∪ the user's saved per-exercise prefs ∪ any optimistic add)
    // MINUS the four standard ones the poster + load/reps steppers already own.
    // WATCH the prefs family so a freshly added column appears immediately.
    final exId = exercise.exerciseId ?? exercise.libraryId ?? exercise.name;
    final savedMetricPrefs =
        ref.watch(exerciseMetricPrefsProvider(exId)).valueOrNull ??
            const <String>[];
    const standardMetricKeys = {'weight', 'reps', 'distance', 'time'};
    final effectiveExtras = <String>[];
    for (final k in [
      ...exercise.trackingProfile.metricKeys,
      ...savedMetricPrefs,
      ...state.extraMetricKeys,
    ]) {
      if (!standardMetricKeys.contains(k) && !effectiveExtras.contains(k)) {
        effectiveExtras.add(k);
      }
    }
    state.extraMetricKeys = effectiveExtras;

    // Use the user's configured per-equipment increment (same source as
    // Advanced), expressed in the workout's DISPLAY unit. The increment is a
    // separate setting with its own unit (feedback_weight_unit_separation), so
    // convert when it differs from the display unit; keep the lb step clean.
    final inc = ref.watch(weightIncrementsProvider);
    final double weightStep = useKg
        ? inc.getIncrementKg(exercise.equipment)
        : (inc.unit == 'lbs'
              ? inc.getIncrement(exercise.equipment)
              : (() {
                  final lbs = inc.getIncrementKg(exercise.equipment) * 2.20462;
                  return (lbs * 2).round() / 2; // nearest 0.5 lb
                })());

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

    return PopScope(
      // Intercept the system back gesture / hardware back so leaving the
      // workout confirms first (parity with Advanced). `_quitWorkout` shows
      // the "logged sets saved" dialog and pops on confirm.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quitWorkout();
      },
      child: EasyActiveWorkoutView(
      exercise: exercise,
      state: state,
      nextExerciseName: nextExerciseName,
      nextExerciseImageUrl: nextExerciseImageUrl,
      currentSetNumber: currentSetNumber,
      workoutSeconds: _timer.workoutSeconds,
      useKg: useKg,
      compact: compact,
      weightStep: weightStep > 0 ? weightStep : (useKg ? 2.5 : 5.0),
      accent: accent,
      isDark: isDark,
      preSetInsight: computeEasyPreSetInsight(
        exercise: exercise,
        state: state,
        useKg: useKg,
        workoutStartEpochMs: _workoutStartEpochMs,
      ),
      // Leaving the workout confirms first (parity with Advanced) — logged
      // sets are saved, but a stray back tap shouldn't silently exit.
      onBack: _quitWorkout,
      // Video = full-screen looping video player (pure playback).
      // Instructions = text-only glass sheet with muscle / body /
      // equipment / how-to. Separate surfaces, distinct content.
      onShowVideo: () => openEasyVideo(context, exercise,
          ref: ref, playlist: _exercises, playlistIndex: _currentIndex),
      onShowInfo: () => openEasyInfoSheet(context, exercise),
      // Form Check — pre-filled with this exercise (editable in the sheet);
      // the sheet captures the active gym so analyses persist per gym/exercise.
      onFormCheck: () => showFormAnalysisSheet(
        context,
        exerciseName: exercise.name,
        exerciseId: exercise.exerciseId ?? exercise.libraryId,
      ),
      // "How did I do?" — honest critique of the sets just logged. Weights in
      // `state.completed` are already kg (see _logCurrentSet).
      onHowDidIDo: () => showHowDidIDoSheet(
        context,
        exerciseName: exercise.name,
        exerciseId: exercise.exerciseId ?? exercise.libraryId,
        sets: [
          for (final s in state.completed)
            {
              'weight_kg': s.weight,
              'reps': s.reps,
              'rir': s.rir,
              'duration_seconds': s.durationSeconds,
              'set_type': s.setType,
            },
        ],
        target: {
          'weight_kg': state.targetWeightKg,
          'reps': state.completed.isNotEmpty
              ? state.completed.first.targetReps
              : state.reps,
        },
        useKg: useKg,
      ),
      onOpenPlan: () => openEasyPlanSheet(
        context: context,
        exercises: _exercises,
        perExercise: _perExercise,
        currentIndex: _currentIndex,
        onJumpTo: _jumpTo,
      ),
      onMinimize: () {
        ref
            .read(workoutMiniPlayerProvider.notifier)
            .minimize(
              workout: widget.workout,
              workoutSeconds: _timer.workoutSeconds,
              currentExerciseIndex: _currentIndex,
              currentExerciseName: exercise.name,
              totalExercises: _exercises.length,
              isPaused: false,
              isResting: false,
              restSecondsRemaining: 0,
            );
        // Direct pop() — bypasses the screen's PopScope(canPop: false) guard
        // (minimize is a deliberate dismiss, not a stray back gesture).
        Navigator.of(context).pop();
      },
      onWeightChanged: _setWeight,
      onRepsChanged: _setReps,
      onDurationChanged: _setDuration,
      onDistanceChanged: _setDistance,
      onMetricChanged: _setExtraMetric,
      onAddMetric: _addMetric,
      onLogSet: _logCurrentSet,
      editingSetIndex: _editingSetIndex,
      onEditSet: _editSet,
      onReturnToCurrent: _returnToCurrentSet,
      onSkipToSet: _skipToSet,
      onAddSet: state.totalSets < _kMaxSetsPerExercise ? _addSet : null,
      onRemoveSet: state.totalSets > state.completed.length + 1
          ? _removeSet
          : null,
      lastSet: _lastSetByEx[_currentIndex],
      scoreTarget: _scoreTargetByEx[_currentIndex],
      onEditNote: _openNoteSheet,
      hasNote: _focalSetHasNote,
      onSkipToNext: _currentIndex < _exercises.length - 1
          ? _skipToNextExercise
          : null,
      onShowHistory: () =>
          showEasyExerciseHistorySheet(context, ref, exercise.name),
      onShowExerciseActions: _showExerciseActions,
      onQuitWorkout: _quitWorkout,
      onCompleteWorkoutNow: _completeWorkoutNow,
      allCompletedSets: [for (final s in _perExercise.values) ...s.completed],
      isResting: _isResting,
      ),
    );
  }

  /// A warm-up move on the ORDINARY Easy screen. Same widget, same chrome,
  /// same focal timer as a working exercise — only the wiring differs:
  /// no set ledger to edit, no PR/volume side effects, and "Log set" records
  /// the hold into `/warmup-logs` instead of `performance_logs`.
  Widget _buildWarmupView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final hasMoreWarmup = _warmupIndex + 1 < _warmupExercises.length;
    // "Next:" points at the following warm-up move, or — on the last one — at
    // the first working exercise, so the hand-off is never a surprise.
    final nextName = hasMoreWarmup
        ? _warmupExercises[_warmupIndex + 1].name
        : (_exercises.isNotEmpty ? _exercises.first.name : null);

    // E2E #125 ask #2 — the render surface for `_startWarmupRest`'s
    // countdown. Replaces the whole warm-up screen (rather than a slot
    // inside `EasyActiveWorkoutView`, which has no rest concept) while
    // `_warmupResting` is true; `_skipWarmupRest` is now a REAL control
    // instead of dead code.
    if (_warmupResting) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _quitWorkout();
        },
        child: WarmupRestOverlay(
          secondsRemaining: _warmupRestRemaining,
          totalSeconds: _warmupRestTotal,
          nextMoveName: nextName,
          onSkip: _skipWarmupRest,
          isDark: isDark,
          accent: accent,
        ),
      );
    }

    final useKg = ref.watch(useKgForWorkoutProvider);
    final mq = MediaQuery.of(context);
    final safeAreaH = mq.size.height - mq.padding.top - mq.padding.bottom;
    final compact = safeAreaH < kEasyCompactSafeAreaHeight;

    final exercise = _warmupExercises[_warmupIndex];
    final state = _warmupStates[_warmupIndex]!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quitWorkout();
      },
      child: EasyActiveWorkoutView(
        exercise: exercise,
        state: state,
        nextExerciseName: nextName,
        nextExerciseImageUrl: hasMoreWarmup
            ? (_warmupExercises[_warmupIndex + 1].imageS3Path ??
                _warmupExercises[_warmupIndex + 1].gifUrl ??
                _warmupExercises[_warmupIndex + 1].videoUrl)
            : null,
        currentSetNumber: 1,
        workoutSeconds: _timer.workoutSeconds,
        useKg: useKg,
        compact: compact,
        weightStep: useKg ? 2.5 : 5.0,
        accent: accent,
        isDark: isDark,
        // The insight engine reads logged working sets; a warm-up move has
        // none, so there is nothing honest to say yet.
        preSetInsight: null,
        onBack: _quitWorkout,
        onShowVideo: () => openEasyVideo(context, exercise,
            ref: ref,
            playlist: _warmupExercises,
            playlistIndex: _warmupIndex),
        onShowInfo: () => openEasyInfoSheet(context, exercise),
        // "Plan" during warm-up = the warm-up sequence, in the same sheet the
        // working sets use. Tapping a row moves the focal card to that move.
        onOpenPlan: () => openEasyPlanSheet(
          context: context,
          exercises: _warmupExercises,
          perExercise: _warmupStates,
          currentIndex: _warmupIndex,
          onJumpTo: _jumpWarmupTo,
        ),
        onMinimize: () {
          ref.read(workoutMiniPlayerProvider.notifier).minimize(
                workout: widget.workout,
                workoutSeconds: _timer.workoutSeconds,
                currentExerciseIndex: 0,
                currentExerciseName: exercise.name,
                totalExercises: _exercises.length,
                isPaused: false,
                isResting: false,
                restSecondsRemaining: 0,
              );
          Navigator.of(context).pop();
        },
        // A warm-up hold is measured in seconds only — the weight / reps /
        // distance steppers never render for it (isTimed), so those callbacks
        // are inert by construction.
        onWeightChanged: (_) {},
        onRepsChanged: (_) {},
        onDistanceChanged: (_) {},
        onDurationChanged: (v) =>
            setState(() => state.durationSeconds = v.round()),
        onLogSet: _logWarmupMove,
        // One hold per move: no ledger editing, no set stepper.
        onAddSet: null,
        onRemoveSet: null,
        onEditSet: null,
        onSkipToSet: null,
        onEditNote: null,
        onFormCheck: null,
        onHowDidIDo: null,
        lastSet: null,
        scoreTarget: null,
        // Rest is handled by the WarmupRestOverlay early-return above, so this
        // branch only ever runs while NOT resting.
        onSkipToNext: hasMoreWarmup ? _skipWarmupMove : _skipWholeWarmup,
        onShowHistory: () =>
            showEasyExerciseHistorySheet(context, ref, exercise.name),
        onShowExerciseActions: _showWarmupActions,
        onQuitWorkout: _quitWorkout,
        onCompleteWorkoutNow: _completeWorkoutNow,
        // Warm-up holds are NOT working volume — the stats strip must not
        // count them.
        allCompletedSets: const [],
        phaseLabel:
            'WARM-UP · ${_warmupIndex + 1} OF ${_warmupExercises.length}',
      ),
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
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
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
                AppLocalizations.of(context).workoutUiBuildersSavingWorkout,
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
                child: CircularProgressIndicator(strokeWidth: 3, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
