import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
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
    /// Raw `metadata['sets_json']` from the workout summary response. Used as
    /// the primary per-set source when present — it carries the actual reps
    /// + weight the user logged on every set, including for bodyweight
    /// sessions where `setLogs` may be empty server-side.
    dynamic setsJsonRaw,
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

    // Use the user's selected in-app accent so the share card actually
    // reads as colored. AppColors.accent resolves to white in dark mode,
    // which made every selected pill, the iMessage sent bubble, and the
    // watermark switch render as a white-on-dark blob.
    final accent = ref.read(accentColorProvider).getColor(true);
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
    // Coerce sets_json (List<dynamic> or JSON string) into per-exercise
    // bucketed maps so _buildExerciseList can prefer them over loggedSets.
    final Map<String, List<Map<String, dynamic>>> setsJsonByExercise =
        _parseSetsJson(setsJsonRaw);

    final exercises = _buildExerciseList(
      planned: plannedExercises,
      logs: loggedSets,
      setsJsonByExercise: setsJsonByExercise,
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
    Map<String, List<Map<String, dynamic>>> setsJsonByExercise =
        const <String, List<Map<String, dynamic>>>{},
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
      // Priority: sets_json (richest, has per-set reps/weight even for
      // bodyweight) > setLogs (server-side aggregate) > planned fallback.
      final jsonSets = setsJsonByExercise[ex.name.toLowerCase()] ??
          const <Map<String, dynamic>>[];
      final logsForEx = byExercise[ex.name] ?? const <SetLogInfo>[];

      List<ShareableSet> sets;
      if (jsonSets.isNotEmpty) {
        sets = jsonSets.where((s) => s['is_completed'] != false).map((s) {
          final weightKg = (s['weight_kg'] as num?)?.toDouble() ??
              (s['weight'] as num?)?.toDouble() ??
              0;
          final reps = (s['reps'] as num?)?.toInt() ?? 0;
          final rpe = (s['rpe'] as num?)?.toDouble();
          return ShareableSet(
            // Pass 0 for bodyweight so the template can render "BW"
            // explicitly; null only when truly unknown.
            weight: useKg ? weightKg : weightKg * 2.20462,
            unit: unitLabel,
            reps: reps,
            rpe: rpe,
          );
        }).toList();
      } else if (logsForEx.isNotEmpty) {
        sets = logsForEx
            .map((s) => ShareableSet(
                  weight: useKg ? s.weightKg : s.weightKg * 2.20462,
                  unit: unitLabel,
                  reps: s.repsCompleted,
                  rpe: s.rpe,
                ))
            .toList();
      } else {
        // Fall back to planned (replicated for the planned set count).
        sets = List.generate(
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
      }

      return ShareableExercise(
        name: ex.name,
        imageUrl: _resolveExerciseImageUrl(ex),
        sets: sets,
      );
    }).toList();
  }

  /// Parse the raw `metadata['sets_json']` blob (List<dynamic> or JSON
  /// string) into per-exercise buckets keyed by lowercased exercise name.
  /// Returns an empty map on any parse failure or null input.
  static Map<String, List<Map<String, dynamic>>> _parseSetsJson(dynamic raw) {
    if (raw == null) return const {};
    List? list;
    if (raw is List) {
      list = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
      } catch (_) {
        return const {};
      }
    }
    if (list == null) return const {};
    final out = <String, List<Map<String, dynamic>>>{};
    for (final s in list) {
      if (s is! Map) continue;
      final m = Map<String, dynamic>.from(s);
      final name = (m['exercise_name'] as String?)?.trim().toLowerCase();
      if (name == null || name.isEmpty) continue;
      out.putIfAbsent(name, () => []).add(m);
    }
    return out;
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
