import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout.dart';
import '../../data/services/image_url_cache.dart';
import '../shareable_data.dart';

/// Builds a `Shareable` for a completed workout — the source data the
/// "Share Your Workout" sheet renders. Recomputes volume from the actual
/// per-set log data so we never display `0 kg` when the user has logged
/// real sets (Bug #10 from the plan).
class WorkoutAdapter {
  /// Build a `Shareable` from the completion-screen payload.
  ///
  /// Returns `null` when the workout has no exercises at all (a legitimate
  /// "no data" state). When exercises exist but per-set logs aren't
  /// available, we fall back to planned values from `WorkoutExercise`
  /// — the WorkoutDetails template will be greyed by the catalog because
  /// `sets[]` will be empty in that case.
  static Shareable? fromCompletion({
    required WidgetRef ref,
    required String workoutName,
    required int durationSeconds,
    required List<WorkoutExercise> plannedExercises,
    List<SetLogInfo>? loggedSets,
    int? calories,
    double? totalVolumeKgFromCaller,
    int? totalSets,
    int? totalReps,
    List<Map<String, dynamic>>? newPRs,
    int? currentStreak,
    int? totalWorkouts,
    Map<String, int>? musclesWorked,
    String? userDisplayName,
    String? userAvatarUrl,
  }) {
    if (plannedExercises.isEmpty) return null;

    final accent = AppColors.accent;
    // Picking the user's preferred unit at adapter time so the captured
    // image matches what they see in the rest of the app (lbs by default
    // per the workout-unit preference, not body-weight unit).
    final useKg = ref.read(useKgForWorkoutProvider);
    final unit = useKg ? 'kg' : 'lbs';

    // Volume: prefer real per-set logs, then caller-supplied total, then
    // sum planned exercises (lower fidelity but better than `0`).
    final volumeKg = _resolveVolumeKg(
      loggedSets: loggedSets,
      callerTotalKg: totalVolumeKgFromCaller,
      planned: plannedExercises,
    );
    final volumeDisplay = volumeKg == null
        ? null
        : useKg
            ? '${volumeKg.round()} kg'
            : '${(volumeKg * 2.20462).round()} lbs';

    // Sets / reps: prefer logged, fall back to caller, then planned.
    final setCount = loggedSets?.length ??
        totalSets ??
        plannedExercises.fold<int>(0, (s, e) => s + (e.sets ?? 0));
    final repCount = loggedSets?.fold<int>(0, (s, log) => s + log.repsCompleted) ??
        totalReps ??
        plannedExercises.fold<int>(
            0, (s, e) => s + ((e.sets ?? 0) * (e.reps ?? 0)));

    // Build per-exercise ShareableExercise with per-set logged values
    // (when available). This is what the Hevy-style WorkoutDetails
    // template renders.
    final exercises = _buildExerciseList(
      planned: plannedExercises,
      logs: loggedSets,
      useKg: useKg,
      unitLabel: unit,
    );

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'DURATION',
        value: _fmtDuration(durationSeconds),
        icon: Icons.timer_outlined,
      ),
      if (volumeDisplay != null)
        ShareableMetric(
          label: 'VOLUME',
          value: volumeDisplay,
          icon: Icons.fitness_center_rounded,
        ),
      ShareableMetric(
        label: 'SETS',
        value: setCount.toString(),
        icon: Icons.repeat_rounded,
      ),
      if (repCount > 0)
        ShareableMetric(
          label: 'REPS',
          value: repCount.toString(),
          icon: Icons.bolt_rounded,
        ),
      ShareableMetric(
        label: 'EXERCISES',
        value: plannedExercises.length.toString(),
        icon: Icons.list_alt_rounded,
      ),
      if (calories != null && calories > 0)
        ShareableMetric(
          label: 'CALORIES',
          value: '$calories kcal',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.orange,
        ),
      if (currentStreak != null && currentStreak > 0)
        ShareableMetric(
          label: 'STREAK',
          value: '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.orange,
        ),
      if (newPRs != null && newPRs.isNotEmpty)
        ShareableMetric(
          label: 'NEW PRS',
          value: newPRs.length.toString(),
          icon: Icons.emoji_events_rounded,
          accent: const Color(0xFFFCD34D),
        ),
    ];

    // Hero image — first exercise's illustration. Polaroid, Magazine
    // Cover, Trading Card, Now Playing, and Exercise Showcase use this.
    final heroImage = exercises.isNotEmpty
        ? exercises.firstWhere(
            (e) => e.imageUrl != null,
            orElse: () => exercises.first,
          ).imageUrl
        : null;

    return Shareable(
      kind: ShareableKind.workoutComplete,
      title: workoutName,
      periodLabel: _fmtDateShort(DateTime.now()),
      heroValue: volumeKg ?? plannedExercises.length.toDouble(),
      heroUnitSingular: volumeKg != null ? unit : 'exercise',
      highlights: highlights,
      subMetrics: const [],
      exercises: exercises,
      musclesWorked: musclesWorked,
      userDisplayName: userDisplayName,
      userAvatarUrl: userAvatarUrl,
      heroImageUrl: heroImage,
      accentColor: accent,
    );
  }

  static double? _resolveVolumeKg({
    required List<SetLogInfo>? loggedSets,
    required double? callerTotalKg,
    required List<WorkoutExercise> planned,
  }) {
    if (loggedSets != null && loggedSets.isNotEmpty) {
      final v = loggedSets.fold<double>(
          0, (s, log) => s + log.weightKg * log.repsCompleted);
      if (v > 0) return v;
    }
    if (callerTotalKg != null && callerTotalKg > 0) return callerTotalKg;
    final fromPlanned = planned.fold<double>(0, (s, e) {
      final w = e.weight ?? 0;
      final reps = e.reps ?? 0;
      final sets = e.sets ?? 0;
      return s + w * reps * sets;
    });
    return fromPlanned > 0 ? fromPlanned : null;
  }

  static List<ShareableExercise> _buildExerciseList({
    required List<WorkoutExercise> planned,
    required List<SetLogInfo>? logs,
    required bool useKg,
    required String unitLabel,
  }) {
    final byExercise = <String, List<SetLogInfo>>{};
    if (logs != null) {
      for (final log in logs) {
        byExercise.putIfAbsent(log.exerciseName, () => []).add(log);
      }
    }

    return planned.map((ex) {
      final logsForEx = byExercise[ex.name] ?? const <SetLogInfo>[];
      // Prefer logged sets when present — that's what the user actually did.
      final sets = logsForEx.isNotEmpty
          ? logsForEx
              .map((s) => ShareableSet(
                    weight: useKg ? s.weightKg : s.weightKg * 2.20462,
                    unit: unitLabel,
                    reps: s.repsCompleted,
                    rpe: s.rpe,
                  ))
              .toList()
          // Fall back to planned (replicated for the planned set count).
          : List.generate(
              ex.sets ?? 0,
              (i) => ShareableSet(
                weight: ex.weight == null
                    ? null
                    : useKg
                        ? ex.weight!
                        : ex.weight! * 2.20462,
                unit: unitLabel,
                reps: ex.reps ?? 0,
              ),
            );
      return ShareableExercise(
        name: ex.name,
        imageUrl: _resolveExerciseImageUrl(ex),
        sets: sets,
      );
    }).toList();
  }

  /// Resolves an HTTP image URL for an exercise so templates can render
  /// the actual illustration instead of a generic dumbbell icon. Sources
  /// in priority order:
  ///   1. Direct gifUrl on the WorkoutExercise (already a full URL).
  ///   2. ImageUrlCache lookup by exercise name (populated by every
  ///      ExerciseImage widget the user has rendered elsewhere in the
  ///      app — this is the hot cache that makes share-sheet renders
  ///      instant for already-seen exercises).
  ///   3. videoUrl as last-ditch fallback (Image.network will fail and
  ///      the template's errorBuilder will show the icon — better than
  ///      pre-decided null which gives the icon every time).
  /// Returns null if no source is available; templates fall back to
  /// Icons.fitness_center_rounded in that case.
  static String? _resolveExerciseImageUrl(WorkoutExercise ex) {
    final gif = ex.gifUrl;
    if (gif != null && gif.startsWith('http')) return gif;
    final cached = ImageUrlCache.get(ex.name);
    if (cached != null && cached.isNotEmpty) return cached;
    final video = ex.videoUrl;
    if (video != null && video.startsWith('http')) return video;
    return null;
  }

  static String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  static String _fmtDateShort(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[d.month - 1]} ${d.day} \'${d.year % 100}';
  }
}
