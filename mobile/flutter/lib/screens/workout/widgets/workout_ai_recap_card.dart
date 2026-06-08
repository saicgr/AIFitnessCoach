import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/api_client.dart';
import '../../library/providers/muscle_group_images_provider.dart';
import 'score_level_up_celebration.dart';

/// Persisted post-workout AI recap card (Task B8 — deeper than Gravl's summary).
///
/// Renders a structured, AI-generated recap of the just-finished workout:
///   - total volume vs the last comparable session
///   - PRs hit this session
///   - "what stood out" (weak point progressed, consistency, strong lift)
///   - ONE concrete coaching cue for next time
///   - an optional reference to logged notes (multi-modal-ready)
///
/// Lifecycle (instant-feel, never a blank spinner — see
/// feedback_instant_feel_ai_generation):
///   1. Mount → optimistic SKELETON paints immediately.
///   2. GET `/feedback/recap/{workout_id}` — if a persisted recap exists, show it.
///   3. Otherwise POST `/feedback/recap` to generate + persist (idempotent),
///      keeping the skeleton up with a "crafting your recap" shimmer until it
///      resolves, then cross-fade into the rendered recap.
///
/// Fully self-contained: it owns its own fetch/generate/render state. The host
/// screen only needs to construct it with the completed-workout payload.
class WorkoutAiRecapCard extends ConsumerStatefulWidget {
  /// The plan/session id the recap is keyed by (matches `workout_id` server-side).
  final String workoutId;

  /// The specific completion this recap is generated from (optional but preferred).
  final String? workoutLogId;

  final String workoutName;
  final String workoutType;

  /// Completed exercises. Each map: {name, sets, reps, weight_kg, time_seconds}.
  final List<Map<String, dynamic>> exercises;

  /// Originally-planned exercises (for skip/completion context). Same shape.
  final List<Map<String, dynamic>> plannedExercises;

  final int totalTimeSeconds;
  final int totalRestSeconds;
  final double avgRestSeconds;
  final int caloriesBurned;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;

  /// PRs hit this session: [{exercise_name, detail}].
  final List<Map<String, dynamic>> earnedPRs;

  /// Free-text set/workout notes logged this session (multi-modal-ready signal).
  final List<String> loggedNotes;

  final int? totalWorkoutsCompleted;

  /// When true, weights are shown in kg; otherwise converted to lb for display.
  final bool useKg;

  /// Completed exercises as domain models — used for the always-visible
  /// "Muscles Worked" strip (merged in from the old AiCoachReportCard).
  final List<WorkoutExercise> workoutExercises;

  /// Volume-vs-last-session comparison, drives the always-visible vs-last pill.
  final PerformanceComparisonInfo? performanceComparison;

  /// Muscles trained this session — fed to the embedded strength level-up
  /// celebration (merged in so it's one card, not a separate stacked card).
  final Set<String> trainedMuscles;

  const WorkoutAiRecapCard({
    super.key,
    required this.workoutId,
    this.workoutLogId,
    required this.workoutName,
    this.workoutType = 'strength',
    this.exercises = const [],
    this.plannedExercises = const [],
    this.totalTimeSeconds = 0,
    this.totalRestSeconds = 0,
    this.avgRestSeconds = 0,
    this.caloriesBurned = 0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.totalVolumeKg = 0,
    this.earnedPRs = const [],
    this.loggedNotes = const [],
    this.totalWorkoutsCompleted,
    this.useKg = true,
    this.workoutExercises = const [],
    this.performanceComparison,
    this.trainedMuscles = const {},
  });

  @override
  ConsumerState<WorkoutAiRecapCard> createState() => _WorkoutAiRecapCardState();
}

enum _RecapStatus { loading, generating, ready, error }

class _WorkoutAiRecapCardState extends ConsumerState<WorkoutAiRecapCard> {
  _RecapStatus _status = _RecapStatus.loading;
  Map<String, dynamic>? _recap;
  bool _expanded = false; // Collapsed by default (2.2) — tap chevron to open.
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kick off the fetch-then-generate flow after first frame so the skeleton
    // paints instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    // 1) Try the persisted recap first (instant, no LLM).
    try {
      final res = await api.get('/feedback/recap/${widget.workoutId}');
      if (!mounted) return;
      final data = res.data;
      if (res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['exists'] == true &&
          data['recap'] is Map) {
        setState(() {
          _recap = Map<String, dynamic>.from(data['recap'] as Map);
          _status = _RecapStatus.ready;
        });
        return;
      }
    } catch (_) {
      // Fall through to generation — a missing recap is the normal first-run path.
    }

    // 2) Generate + persist (idempotent server-side).
    if (!mounted) return;
    setState(() => _status = _RecapStatus.generating);
    await _generate();
  }

  Future<void> _generate({bool force = false}) async {
    final api = ref.read(apiClientProvider);
    try {
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _status = _RecapStatus.error;
            _error = 'Not signed in';
          });
        }
        return;
      }

      final body = <String, dynamic>{
        'user_id': userId,
        'workout_id': widget.workoutId,
        'workout_log_id': widget.workoutLogId,
        'workout_name': widget.workoutName,
        'workout_type': widget.workoutType,
        'exercises': widget.exercises,
        'planned_exercises': widget.plannedExercises,
        'total_time_seconds': widget.totalTimeSeconds,
        'total_rest_seconds': widget.totalRestSeconds,
        'avg_rest_seconds': widget.avgRestSeconds,
        'calories_burned': widget.caloriesBurned,
        'total_sets': widget.totalSets,
        'total_reps': widget.totalReps,
        'total_volume_kg': widget.totalVolumeKg,
        if (widget.earnedPRs.isNotEmpty) 'earned_prs': widget.earnedPRs,
        if (widget.loggedNotes.isNotEmpty) 'logged_notes': widget.loggedNotes,
        if (widget.totalWorkoutsCompleted != null)
          'total_workouts_completed': widget.totalWorkoutsCompleted,
        'force': force,
      };

      final res = await api.post(
        '/feedback/recap',
        data: body,
        options: Options(
          // AI generation can take a few seconds; give it room.
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      if (!mounted) return;
      final data = res.data;
      if (res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['recap'] is Map) {
        setState(() {
          _recap = Map<String, dynamic>.from(data['recap'] as Map);
          _status = _RecapStatus.ready;
          _error = null;
        });
      } else {
        setState(() {
          _status = _RecapStatus.error;
          _error = 'Could not build your recap';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _RecapStatus.error;
        _error = 'Could not build your recap';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final muscles = _extractMuscles(widget.workoutExercises);
    final recap = _recap ?? const <String, dynamic>{};
    final headline = (recap['headline'] as String?)?.trim() ?? '';

    return _GlassShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — chevron expands the full recap detail.
          _RecapHeader(
            isDark: isDark,
            trailing: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 22,
                  color: textSecondary,
                ),
              ),
            ),
          ),

          // Always-visible AI headline (clamped to 2 lines when collapsed).
          if (_status == _RecapStatus.ready && headline.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              headline,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ],

          // Always-visible "Muscles Worked" — horizontally scrollable (2.1).
          if (muscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MergedMusclesStrip(muscles: muscles),
          ],

          // Always-visible quick pills (Volume / vs-last / PRs).
          const SizedBox(height: 12),
          _MergedQuickPills(
            totalSets: widget.totalSets,
            totalVolumeKg: widget.totalVolumeKg,
            durationSeconds: widget.totalTimeSeconds,
            prCount: widget.earnedPRs.length,
            performanceComparison: widget.performanceComparison,
            useKg: widget.useKg,
          ),

          // Expandable: the full recap detail (collapsed by default — 2.2).
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _buildExpandedBody(isDark),
                  )
                : const SizedBox(width: double.infinity),
          ),

          // Strength level-up celebration, merged in (2.3). Self-hides to
          // zero height when no tier was crossed, so normally invisible.
          ScoreLevelUpCelebration(trainedMuscles: widget.trainedMuscles),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(bool isDark) {
    switch (_status) {
      case _RecapStatus.loading:
      case _RecapStatus.generating:
        return _RecapSkeleton(
          isDark: isDark,
          generating: _status == _RecapStatus.generating,
        );
      case _RecapStatus.error:
        return _RecapError(
          isDark: isDark,
          message: _error ?? 'Could not build your recap',
          onRetry: () {
            setState(() => _status = _RecapStatus.generating);
            _generate(force: true);
          },
        );
      case _RecapStatus.ready:
        return _RecapDetail(
          recap: _recap ?? const {},
          isDark: isDark,
          useKg: widget.useKg,
        ).animate().fadeIn(duration: 220.ms);
    }
  }
}

// ─── Glass shell ────────────────────────────────────────────────

class _GlassShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassShell({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.purple.withValues(alpha: 0.10),
                      AppColors.orange.withValues(alpha: 0.06),
                    ]
                  : [
                      AppColors.purple.withValues(alpha: 0.06),
                      AppColors.orange.withValues(alpha: 0.04),
                    ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: isDark ? 0.28 : 0.22),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Header (shared) ────────────────────────────────────────────

class _RecapHeader extends StatelessWidget {
  final bool isDark;
  final Widget? trailing;
  const _RecapHeader({required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple, AppColors.orange],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.insights_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Coach Recap',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Loading / generating skeleton (never a blank spinner) ──────

class _RecapSkeleton extends StatelessWidget {
  final bool isDark;
  final bool generating;
  const _RecapSkeleton({required this.isDark, required this.generating});

  @override
  Widget build(BuildContext context) {
    final base = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    final shimmer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // MUST be min: this card lives inside the completion screen's vertical
      // SingleChildScrollView (unbounded height). A default mainAxisSize.max
      // Column forces infinite height there ("BoxConstraints forces an infinite
      // height"), which fails layout for the WHOLE screen → blank screen on
      // workout finish. The outer skeleton Column is min; this inner one was not.
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(0.85, 16),
        const SizedBox(height: 12),
        bar(1.0, 11),
        const SizedBox(height: 7),
        bar(0.92, 11),
        const SizedBox(height: 7),
        bar(0.7, 11),
        const SizedBox(height: 16),
        bar(0.5, 38),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1100.ms,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        );

    // Header lives in the always-visible area now — this only fills the
    // expanded region with shimmer lines.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        shimmer,
        if (generating) ...[
          const SizedBox(height: 12),
          Text(
            'Crafting your recap…',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Error state ────────────────────────────────────────────────

class _RecapError extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;
  const _RecapError({
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rendered recap ─────────────────────────────────────────────

/// The expanded recap detail — volume-vs-last chip, PRs, what stood out, a
/// notes reference, and the single coaching cue. Header/headline/muscles/pills
/// live in the always-visible area of [WorkoutAiRecapCard]; this is only built
/// when the card is expanded.
class _RecapDetail extends StatelessWidget {
  final Map<String, dynamic> recap;
  final bool isDark;
  final bool useKg;

  const _RecapDetail({
    required this.recap,
    required this.isDark,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final stoodOut = (recap['what_stood_out'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final prs = (recap['prs'] as List?)
            ?.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        const <Map<String, dynamic>>[];
    final cue = (recap['coaching_cue'] as String?)?.trim() ?? '';
    final notes = (recap['notes_reference'] as String?)?.trim();
    final volume = recap['volume_comparison'] is Map
        ? Map<String, dynamic>.from(recap['volume_comparison'] as Map)
        : const <String, dynamic>{};

    final children = <Widget>[];
    if (volume.isNotEmpty) {
      children.add(_VolumeChip(volume: volume, isDark: isDark, useKg: useKg));
    }
    if (prs.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.addAll(prs.map((pr) => _PrRow(
            exercise: (pr['exercise_name'] as String?) ?? 'Exercise',
            detail: (pr['detail'] as String?) ?? '',
            isDark: isDark,
          )));
    }
    if (stoodOut.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_SectionLabel('What stood out', isDark: isDark));
      children.add(const SizedBox(height: 6));
      children.addAll(stoodOut.map((s) => _BulletRow(text: s, isDark: isDark)));
    }
    if (notes != null && notes.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_NoteRow(text: notes, isDark: isDark));
    }
    if (cue.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_CoachingCue(text: cue, isDark: isDark));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// ─── Merged-in "Muscles Worked" strip (horizontal scroll) + quick pills ──
// Ported from the old standalone AiCoachReportCard so the completion screen
// shows ONE coach card instead of three stacked cards.

class _MuscleData {
  final String name;
  final String? imagePath;
  final int sets;
  final bool isPrimary;
  const _MuscleData({
    required this.name,
    this.imagePath,
    required this.sets,
    required this.isPrimary,
  });
}

List<_MuscleData> _extractMuscles(List<WorkoutExercise> exercises) {
  final Map<String, _MuscleData> map = {};
  for (final exercise in exercises) {
    final muscleName = exercise.primaryMuscle ?? exercise.muscleGroup;
    if (muscleName != null && muscleName.isNotEmpty) {
      final normalized = _normalizeMuscle(muscleName);
      final existing = map[normalized];
      map[normalized] = _MuscleData(
        name: normalized,
        imagePath: _findMuscleImage(normalized),
        sets: (existing?.sets ?? 0) + (exercise.sets ?? 0),
        isPrimary: true,
      );
    }
    for (final sec in _parseSecondaryMuscles(exercise.secondaryMuscles)) {
      final normalized = _normalizeMuscle(sec);
      if (!map.containsKey(normalized)) {
        map[normalized] = _MuscleData(
          name: normalized,
          imagePath: _findMuscleImage(normalized),
          sets: 0,
          isPrimary: false,
        );
      }
    }
  }
  final result = map.values.toList()
    ..sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return b.sets.compareTo(a.sets);
    });
  return result;
}

String _normalizeMuscle(String name) {
  final stripped = name.trim().replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
  final lower = stripped.toLowerCase();
  const aliases = {
    'upper back': 'Back',
    'lats': 'Back',
    'latissimus dorsi': 'Back',
    'rear delts': 'Shoulders',
    'front delts': 'Shoulders',
    'side delts': 'Shoulders',
    'deltoids': 'Shoulders',
    'pecs': 'Chest',
    'pectorals': 'Chest',
    'abs': 'Core',
    'abdominals': 'Core',
    'obliques': 'Core',
    'quads': 'Quadriceps',
    'glutes': 'Glutes',
    'gluteus': 'Glutes',
    'calves': 'Calves',
    'forearms': 'Forearms',
    'lower back': 'Lower Back',
    'hip flexors': 'Hips',
  };
  return aliases[lower] ?? _titleCase(stripped);
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

String? _findMuscleImage(String normalized) {
  if (muscleGroupAssets.containsKey(normalized)) {
    return muscleGroupAssets[normalized];
  }
  for (final entry in muscleGroupAssets.entries) {
    if (entry.key.toLowerCase() == normalized.toLowerCase()) return entry.value;
  }
  return null;
}

List<String> _parseSecondaryMuscles(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return [];
}

class _MergedMusclesStrip extends StatelessWidget {
  final List<_MuscleData> muscles;
  const _MergedMusclesStrip({required this.muscles});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MUSCLES WORKED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal scroll (2.1) — never wraps/overflows regardless of count.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final m in muscles) ...[
                _MuscleChip(muscle: m),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final _MuscleData muscle;
  const _MuscleChip({required this.muscle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final borderColor = muscle.isPrimary
        ? AppColors.orange.withValues(alpha: 0.6)
        : AppColors.purple.withValues(alpha: 0.3);
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            child: ClipOval(
              child: muscle.imagePath != null
                  ? Image.asset(
                      muscle.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.fitness_center, size: 18, color: textMuted),
                    )
                  : Icon(Icons.fitness_center, size: 18, color: textMuted),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            muscle.name,
            style: TextStyle(fontSize: 9, color: textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (muscle.sets > 0)
            Text(
              '${muscle.sets}s',
              style: TextStyle(
                fontSize: 8,
                color: muscle.isPrimary ? AppColors.orange : textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _MergedQuickPills extends StatelessWidget {
  final int totalSets;
  final double totalVolumeKg;
  final int durationSeconds;
  final int prCount;
  final PerformanceComparisonInfo? performanceComparison;
  final bool useKg;

  const _MergedQuickPills({
    required this.totalSets,
    required this.totalVolumeKg,
    required this.durationSeconds,
    required this.prCount,
    required this.performanceComparison,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final volumePercent =
        performanceComparison?.workoutComparison.volumeDiffPercent;
    final minutes = durationSeconds > 0 ? durationSeconds / 60.0 : 1.0;
    final workRateKg = totalVolumeKg / minutes;
    // Volume + work-rate are aggregates → linear conversion (not gym-snapped).
    final displayVolume =
        useKg ? totalVolumeKg : WeightUtils.kgToLbs(totalVolumeKg);
    final displayWorkRate =
        useKg ? workRateKg : WeightUtils.kgToLbs(workRateKg);
    final unit = WeightUtils.workoutUnitLabel(useKg);

    return Row(
      children: [
        Expanded(
          child: _Pill(
            icon: Icons.trending_up,
            value: volumePercent != null
                ? '${volumePercent >= 0 ? '+' : ''}${volumePercent.toStringAsFixed(0)}%'
                : '${displayVolume.toStringAsFixed(0)}$unit',
            label: volumePercent != null ? 'vs last' : 'Volume',
            color: volumePercent != null
                ? (volumePercent >= 0 ? AppColors.green : Colors.redAccent)
                : AppColors.green,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            icon: Icons.speed,
            value: displayWorkRate.toStringAsFixed(0),
            label: '$unit/min',
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            icon: Icons.emoji_events,
            value: '$prCount',
            label: prCount == 1 ? 'PR' : 'PRs',
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Pill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, style: TextStyle(fontSize: 8, color: textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Volume comparison chip ─────────────────────────────────────

class _VolumeChip extends StatelessWidget {
  final Map<String, dynamic> volume;
  final bool isDark;
  final bool useKg;
  const _VolumeChip({
    required this.volume,
    required this.isDark,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final delta = (volume['delta_pct'] as num?)?.toDouble();
    final summary = (volume['summary'] as String?)?.trim() ?? '';
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final bool up = (delta ?? 0) >= 1;
    final bool down = (delta ?? 0) <= -1;
    final Color accent = up
        ? AppColors.green
        : (down ? AppColors.orange : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary));
    final IconData icon = up
        ? Icons.trending_up_rounded
        : (down ? Icons.trending_down_rounded : Icons.trending_flat_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary.isNotEmpty
                  ? summary
                  : 'Total volume logged for this session.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Text(
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PR row ─────────────────────────────────────────────────────

class _PrRow extends StatelessWidget {
  final String exercise;
  final String detail;
  final bool isDark;
  const _PrRow({
    required this.exercise,
    required this.detail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$exercise PR — ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
    );
  }
}

// ─── Bullet row ─────────────────────────────────────────────────

class _BulletRow extends StatelessWidget {
  final String text;
  final bool isDark;
  const _BulletRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Note reference row (multi-modal) ───────────────────────────

class _NoteRow extends StatelessWidget {
  final String text;
  final bool isDark;
  const _NoteRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_outlined, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Coaching cue (the single concrete next step) ───────────────

class _CoachingCue extends StatelessWidget {
  final String text;
  final bool isDark;
  const _CoachingCue({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: AppColors.orange),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT TIME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
