/// ONE resolver for "what did this session actually total?".
///
/// E2E #78: the completed-workout Summary screen rendered real numbers in its
/// hero ledger (duration / volume / sets · reps / records) but its SHARE button
/// handed the shareable adapter only `workout.durationMinutes` and
/// `summary.setLogs` — both routinely empty on a summary row — so the share
/// card came out with nothing on it but the title, the date and the watermark.
/// Two different resolutions of the same session in the same screen.
///
/// This file is that single resolution. `SummaryHeroStats` renders it and the
/// share button passes it to `WorkoutAdapter.fromCompletion`, so the image the
/// user posts can never disagree with the screen they are looking at.
///
/// Every field is nullable-by-absence: a stat that was not captured resolves to
/// 0 / null and the caller HIDES it. Nothing here fabricates a value.
library;

import 'dart:convert';

import '../../../data/models/workout.dart';

class SummarySessionTotals {
  /// Tracked wall-clock seconds for the session. 0 = never tracked.
  final int durationSeconds;

  /// Total lifted volume in KILOGRAMS (storage unit). 0 = nothing loaded.
  final double volumeKg;

  /// Completed working sets / reps. 0 = nothing logged.
  final int sets;
  final int reps;

  /// Total logged distance (meters) across completed sets — SkiErg, sled,
  /// a tracked run. 0 = nothing distance-based. See [reps]: a distance set
  /// legitimately logs 0 reps (`easy_active_workout_state.dart` deliberately
  /// zeroes reps for a timed/distance set), so [reps] alone cannot tell a
  /// caller whether "0" means "nothing happened" or "19,950 meters
  /// happened, just not measured in reps".
  final double distanceMeters;

  /// Total set-duration seconds across completed sets that carried NEITHER
  /// reps NOR distance — i.e. genuinely time-primary sets (a timed plank
  /// hold), not the optional "time under tension" info a rep set can also
  /// carry. 0 = nothing purely time-based.
  final int timedOnlySeconds;

  /// Distinct exercises the session touched.
  final int exercises;

  /// Calories, and whether they are a planned estimate rather than tracked.
  final int? caloriesKcal;
  final bool caloriesEstimated;

  /// Personal records set in this session.
  final int records;

  const SummarySessionTotals({
    required this.durationSeconds,
    required this.volumeKg,
    required this.sets,
    required this.reps,
    this.distanceMeters = 0,
    this.timedOnlySeconds = 0,
    required this.exercises,
    required this.caloriesKcal,
    required this.caloriesEstimated,
    required this.records,
  });

  /// True when the session captured at least one shareable number. Callers use
  /// this to decide whether a share card would be empty.
  bool get hasAnyStat =>
      durationSeconds > 0 || volumeKg > 0 || sets > 0 || exercises > 0;

  /// Resolve from the summary payload.
  ///
  /// Resolution order per stat, highest fidelity first:
  ///   1. the backend's `workout_performance_summary` aggregates
  ///      (`performanceComparison.workoutComparison`),
  ///   2. `metadata['sets_json']` — the per-set blob the active-workout client
  ///      wrote, which survives even when `performance_logs` rows did not,
  ///   3. `summary.setLogs` — the server's per-set rows.
  static SummarySessionTotals resolve({
    required WorkoutSummaryResponse summary,
    Map<String, dynamic>? metadata,
    int exerciseCount = 0,
  }) {
    final wc = summary.performanceComparison?.workoutComparison;
    final fallback = _aggregateSetsJson(metadata) ??
        (summary.setLogs.isNotEmpty ? _aggregateSetLogs(summary) : null);

    final volumeKg = (wc?.currentTotalVolumeKg ?? 0) > 0
        ? wc!.currentTotalVolumeKg
        : (fallback?.volumeKg ?? 0);
    final sets =
        (wc?.currentTotalSets ?? 0) > 0 ? wc!.currentTotalSets : (fallback?.sets ?? 0);
    final reps =
        (wc?.currentTotalReps ?? 0) > 0 ? wc!.currentTotalReps : (fallback?.reps ?? 0);

    final durationSeconds = summary.durationSeconds > 0
        ? summary.durationSeconds
        : ((wc?.currentDurationSeconds ?? 0) > 0
            ? wc!.currentDurationSeconds
            : ((metadata?['total_time_seconds'] as num?)?.toInt() ?? 0));

    final caloriesKcal = summary.caloriesKcal ??
        ((wc?.currentCalories ?? 0) > 0 ? wc!.currentCalories : null);

    return SummarySessionTotals(
      durationSeconds: durationSeconds,
      volumeKg: volumeKg,
      sets: sets,
      reps: reps,
      // No backend `wc` equivalent for these two yet — always the local
      // aggregation. Presentation-only additions (defect: the "Sets · Reps"
      // headline summarised a distance/timed session as "N · 0", the same
      // fabrication class as a set's own Reps cell reading a bare "0" —
      // see summary_exercise_table.dart's SummarySetData.hasAlternateMetric).
      distanceMeters: fallback?.distanceMeters ?? 0,
      timedOnlySeconds: fallback?.timedOnlySeconds ?? 0,
      exercises:
          (wc?.currentExercises ?? 0) > 0 ? wc!.currentExercises : exerciseCount,
      caloriesKcal: caloriesKcal,
      caloriesEstimated: summary.caloriesSource == 'planned_estimate',
      records: summary.personalRecords.length,
    );
  }

  /// A set is completed either because it says so explicitly, or — for
  /// legacy rows with no `is_completed` flag — because it recorded SOME
  /// real output. Reps alone used to be that inference, which silently
  /// undercounted a legacy distance/timed set (reps is legitimately 0 for
  /// those) as "not completed". Any of reps, distance, a timed duration, or
  /// a custom metric now counts as evidence the set actually happened.
  static bool _inferCompleted({
    required bool? explicit,
    required int repsCompleted,
    required double? distanceMeters,
    required int? durationSeconds,
    required bool hasCustomMetrics,
  }) =>
      explicit ??
      (repsCompleted > 0 ||
          (distanceMeters ?? 0) > 0 ||
          (durationSeconds ?? 0) > 0 ||
          hasCustomMetrics);

  static ({
    double volumeKg,
    int sets,
    int reps,
    double distanceMeters,
    int timedOnlySeconds,
  }) _aggregateSetLogs(WorkoutSummaryResponse summary) {
    double volume = 0;
    int sets = 0;
    int reps = 0;
    double distance = 0;
    int timedOnly = 0;
    for (final log in summary.setLogs) {
      final isCompleted = _inferCompleted(
        explicit: log.isCompleted,
        repsCompleted: log.repsCompleted,
        distanceMeters: log.distanceMeters,
        durationSeconds: log.setDurationSeconds,
        hasCustomMetrics: log.metrics?.isNotEmpty ?? false,
      );
      if (!isCompleted) continue;
      sets += 1;
      reps += log.repsCompleted;
      volume += log.weightKg * log.repsCompleted;
      distance += log.distanceMeters ?? 0;
      // Time-under-tension on an ordinary rep set is secondary info, not
      // this set's primary output — only count duration here when reps AND
      // distance are both absent, i.e. a genuinely timed-hold set.
      if (log.repsCompleted <= 0 && (log.distanceMeters ?? 0) <= 0) {
        timedOnly += log.setDurationSeconds ?? 0;
      }
    }
    return (
      volumeKg: volume,
      sets: sets,
      reps: reps,
      distanceMeters: distance,
      timedOnlySeconds: timedOnly,
    );
  }

  static ({
    double volumeKg,
    int sets,
    int reps,
    double distanceMeters,
    int timedOnlySeconds,
  })? _aggregateSetsJson(Map<String, dynamic>? metadata) {
    final raw = metadata?['sets_json'];
    if (raw == null) return null;
    List<dynamic>? list;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
      } catch (_) {}
    } else if (raw is List) {
      list = raw;
    }
    if (list == null || list.isEmpty) return null;
    double volume = 0;
    int sets = 0;
    int reps = 0;
    double distance = 0;
    int timedOnly = 0;
    for (final item in list) {
      if (item is! Map) continue;
      final completedRaw = item['is_completed'];
      final repsCompleted = (item['reps_completed'] as num?)?.toInt() ?? 0;
      final distanceMeters = (item['distance_meters'] as num?)?.toDouble();
      final durationSeconds = (item['set_duration_seconds'] as int?) ??
          (item['duration_seconds'] as int?);
      final metricsRaw = item['metrics'];
      final isCompleted = _inferCompleted(
        explicit: completedRaw is bool ? completedRaw : null,
        repsCompleted: repsCompleted,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        hasCustomMetrics: metricsRaw is Map && metricsRaw.isNotEmpty,
      );
      if (!isCompleted) continue;
      final weightKg = (item['weight_kg'] as num?)?.toDouble() ?? 0;
      sets += 1;
      reps += repsCompleted;
      volume += weightKg * repsCompleted;
      distance += distanceMeters ?? 0;
      if (repsCompleted <= 0 && (distanceMeters ?? 0) <= 0) {
        timedOnly += durationSeconds ?? 0;
      }
    }
    return (
      volumeKg: volume,
      sets: sets,
      reps: reps,
      distanceMeters: distance,
      timedOnlySeconds: timedOnly,
    );
  }
}
