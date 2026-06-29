// Easy tier — guided warm-up runner (full Easy-mode treatment).
//
// Shown BEFORE the working sets when the workout has warm-up moves. Each move
// now runs through the SAME Easy components the working sets use —
// [EasyExerciseHeader] (demo media + Instructions / Plan) and
// [EasyFocalColumn] (the hold timer) — so a warm-up move looks and behaves
// like a real Easy exercise: there's a video/illustration, an Instructions
// sheet, and a countdown. ("Where is the video and more?" — here.)
//
// Warm-up moves are still kept SEPARATE from the logged working sets (they
// never touch the session/sets, so they can't drift working-set indices or
// inflate volume / PR stats). Completion IS persisted to the backend
// `/warmup-logs` table so the work is saved, not ephemeral.
//
// Flow: an intro card (N moves · ~M min · Start / Skip) → each move with the
// full Easy header + a countdown → `onDone` fires when finished OR skipped.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/services/api_client.dart';
import '../../../../widgets/exercise_image.dart';
import '../../../../widgets/glass_sheet.dart';
import '../easy_active_workout_state_models.dart';
import '../easy_sheet_helpers.dart';
import 'easy_exercise_header.dart';
import 'easy_focal_column.dart';

class EasyWarmupRunner extends ConsumerStatefulWidget {
  /// Raw warm-up item maps (name / duration_seconds / exercise_id …) as
  /// returned by `WorkoutRepository.fetchWarmupAndStretches`.
  final List<Map<String, dynamic>> warmup;

  /// Called once the warm-up is finished OR skipped — proceed to working sets.
  final VoidCallback onDone;

  /// Workout id — used to persist warm-up completion to `/warmup-logs`.
  final String? workoutId;

  final bool useKg;

  const EasyWarmupRunner({
    super.key,
    required this.warmup,
    required this.onDone,
    this.workoutId,
    this.useKg = true,
  });

  @override
  ConsumerState<EasyWarmupRunner> createState() => _EasyWarmupRunnerState();
}

class _EasyWarmupRunnerState extends ConsumerState<EasyWarmupRunner> {
  bool _started = false;
  int _index = 0;
  final Map<int, EasyExerciseState> _moveStates = {};
  // Completed moves accumulated for the single /warmup-logs persist at the end.
  final Map<String, List<Map<String, dynamic>>> _completed = {};

  int _durationOf(Map<String, dynamic> m) {
    final v = m['duration_seconds'] ??
        m['durationSeconds'] ??
        m['hold_seconds'] ??
        m['holdSeconds'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 30;
    return 30;
  }

  String _nameOf(Map<String, dynamic> m) => m['name']?.toString() ?? 'Warm-up';

  /// Build a WorkoutExercise for a warm-up move so the Easy components (header
  /// media + focal timer) can render it exactly like a working exercise.
  WorkoutExercise _exerciseFor(Map<String, dynamic> m) {
    final dur = _durationOf(m);
    return WorkoutExercise(
      nameValue: _nameOf(m),
      exerciseId: m['exercise_id']?.toString() ?? m['exerciseId']?.toString(),
      holdSeconds: dur,
      isTimed: true,
      section: 'warmup',
      gifUrl: m['gif_url']?.toString() ?? m['gifUrl']?.toString(),
      imageS3Path:
          m['image_s3_path']?.toString() ?? m['imageS3Path']?.toString(),
      videoUrl: m['video_url']?.toString() ?? m['videoUrl']?.toString(),
      instructions: m['instructions']?.toString(),
      equipment: m['equipment']?.toString(),
      bodyPart: m['body_part']?.toString() ?? m['bodyPart']?.toString(),
    );
  }

  EasyExerciseState _stateFor(int i) => _moveStates.putIfAbsent(
        i,
        () => EasyExerciseState(
          displayWeight: 0,
          reps: 0,
          targetReps: 0,
          targetWeightKg: 0,
          totalSets: 1,
          isTimed: true,
          durationSeconds: _durationOf(widget.warmup[i]),
        ),
      );

  void _completeCurrentMove() {
    final m = widget.warmup[_index];
    final name = _nameOf(m);
    (_completed[name] ??= []).add({
      'type': 'warmup_complete',
      'hold_seconds': _stateFor(_index).durationSeconds,
    });
    HapticService.instance.success();
    _next();
  }

  void _next() {
    if (_index + 1 >= widget.warmup.length) {
      _persistAndFinish();
      return;
    }
    setState(() => _index++);
  }

  /// Fire-and-forget persistence of completed warm-up moves, then hand control
  /// back to the working sets. Failure is non-blocking (the warm-up is done
  /// regardless) — matches the existing warmup-interval persistence contract.
  void _persistAndFinish() {
    final id = widget.workoutId;
    if (id != null && id.isNotEmpty && _completed.isNotEmpty) {
      () async {
        try {
          await ref.read(apiClientProvider).post(
            '${ApiConstants.workouts}/$id/warmup-logs',
            data: {'intervals': _completed},
          );
        } catch (_) {
          // Non-blocking — warm-up still proceeds.
        }
      }();
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    final totalSecs =
        widget.warmup.fold<int>(0, (s, m) => s + _durationOf(m));
    final mins = (totalSecs / 60).ceil();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: !_started ? _intro(tc, mins) : _runMove(context, tc),
      ),
    );
  }

  // ── Intro card: N moves · ~M min · Start / Skip ──────────────────────────
  Widget _intro(ThemeColors tc, int mins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('WARM-UP',
                style: ZType.lbl(12, color: tc.accent, letterSpacing: 2.5)),
          ),
          const SizedBox(height: 4),
          Text('${widget.warmup.length} moves · ~$mins min',
              style: ZType.disp(26, color: tc.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: widget.warmup.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _moveRow(tc, widget.warmup[i]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticService.instance.tap();
                setState(() => _started = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.accent,
                foregroundColor: tc.accentContrast,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text('START WARM-UP',
                  style: ZType.lbl(16,
                      color: tc.accentContrast,
                      weight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                HapticService.instance.tap();
                widget.onDone();
              },
              child: Text('SKIP WARM-UP →',
                  style: ZType.lbl(13, color: tc.textMuted, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveRow(ThemeColors tc, Map<String, dynamic> m) => Row(
        children: [
          ExerciseImage(
            exerciseName: _nameOf(m),
            exerciseId: m['exercise_id']?.toString(),
            width: 40,
            height: 40,
            borderRadius: 9,
            fit: BoxFit.cover,
            iconColor: tc.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_nameOf(m),
                style: ZType.sans(15,
                    color: tc.textPrimary, weight: FontWeight.w600)),
          ),
          Text('${_durationOf(m)}s',
              style: ZType.data(13, color: tc.textMuted)),
        ],
      );

  // ── Running a single move — full Easy treatment ──────────────────────────
  Widget _runMove(BuildContext context, ThemeColors tc) {
    final ex = _exerciseFor(widget.warmup[_index]);
    final state = _stateFor(_index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final compact =
        MediaQuery.of(context).size.height < kEasyCompactSafeAreaHeight;
    final nextName = _index + 1 < widget.warmup.length
        ? _nameOf(widget.warmup[_index + 1])
        : null;

    return Column(
      children: [
        // Phase ribbon — keeps the warm-up framing while the rest reads as a
        // normal Easy exercise.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Text('WARM-UP · ${_index + 1} OF ${widget.warmup.length}',
                  style: ZType.lbl(12, color: tc.accent, letterSpacing: 2)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.instance.tap();
                  _persistAndFinish();
                },
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text('SKIP →',
                    style:
                        ZType.lbl(12, color: tc.textMuted, letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
        EasyExerciseHeader(
          exercise: ex,
          currentSet: 1,
          totalSets: 1,
          compact: compact,
          onShowVideo: () => openEasyVideo(context, ex, ref: ref),
          onShowInfo: () => openEasyInfoSheet(context, ex),
          onOpenPlan: () => _showSequenceSheet(context, tc),
          // No form-check / note / set-stepper / more on a warm-up move.
        ),
        Expanded(
          child: EasyFocalColumn(
            state: state,
            exerciseName: ex.name,
            useKg: widget.useKg,
            weightStep: 2.5,
            accent: accent,
            compact: compact,
            onWeightChanged: (_) {},
            onRepsChanged: (_) {},
            onDurationChanged: (v) =>
                setState(() => state.durationSeconds = v.round()),
            onDistanceChanged: (_) {},
            onLogSet: () async => _completeCurrentMove(),
            nextExerciseName: nextName,
            nextDetail: nextName == null ? 'Start workout' : null,
          ),
        ),
      ],
    );
  }

  /// The "Plan" affordance on a warm-up move → the full warm-up sequence.
  void _showSequenceSheet(BuildContext context, ThemeColors tc) {
    HapticService.instance.tap();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WARM-UP SEQUENCE',
                  style:
                      ZType.lbl(13, color: tc.textMuted, letterSpacing: 1.8)),
              const SizedBox(height: 12),
              for (int i = 0; i < widget.warmup.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Opacity(
                    opacity: i == _index ? 1 : 0.6,
                    child: _moveRow(tc, widget.warmup[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
