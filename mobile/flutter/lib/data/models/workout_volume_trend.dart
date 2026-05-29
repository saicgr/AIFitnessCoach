/// Weekly training volume trend — feeds the Stats-tab "Weekly Volume Trend"
/// bar chart. Backed by `GET /api/v1/scores/volume-trend`.
///
/// Volume is in KILOGRAMS as returned by the backend (weight is stored in kg;
/// the UI converts to lbs per the user's workout-weight unit preference — see
/// feedback_weight_units.md). Models are hand-written (no codegen / .g.dart)
/// because build_runner crashes the analyzer in this repo.
library;

import 'package:flutter/foundation.dart';

/// One ISO-week bucket. Empty weeks arrive zero-filled (the backend guarantees
/// exactly `weeks` buckets, oldest to newest), so the chart can render evenly
/// spaced bars without client-side gap-filling.
@immutable
class WorkoutVolumeWeek {
  /// Monday of the ISO week, user-local. Parsed from the "YYYY-MM-DD" string.
  final DateTime weekStart;

  /// Sum of weight_kg * reps_completed over completed sets that week (kg).
  final double volumeKg;

  /// Count of completed sets logged that week.
  final int sets;

  /// Distinct completed workout sessions that week.
  final int workouts;

  const WorkoutVolumeWeek({
    required this.weekStart,
    required this.volumeKg,
    required this.sets,
    required this.workouts,
  });

  /// True when no training was logged this week (zero-filled bucket).
  bool get isEmpty => sets == 0 && workouts == 0;

  factory WorkoutVolumeWeek.fromJson(Map<String, dynamic> json) {
    final raw = (json['week_start'] as String?) ?? '';
    final parsed = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return WorkoutVolumeWeek(
      weekStart: parsed,
      volumeKg: (json['volume_kg'] as num?)?.toDouble() ?? 0.0,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      workouts: (json['workouts'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The full ordered series, oldest to newest.
@immutable
class WorkoutVolumeTrend {
  final List<WorkoutVolumeWeek> weeks;

  const WorkoutVolumeTrend({required this.weeks});

  /// True when every bucket is empty (user has no logged training in range).
  bool get hasNoData => weeks.every((w) => w.isEmpty);

  /// Total external load (kg) across the visible window.
  double get totalVolumeKg =>
      weeks.fold(0.0, (sum, w) => sum + w.volumeKg);

  factory WorkoutVolumeTrend.fromJson(Map<String, dynamic> json) {
    final list = (json['weeks'] as List?) ?? const [];
    return WorkoutVolumeTrend(
      weeks: list
          .whereType<Map<String, dynamic>>()
          .map(WorkoutVolumeWeek.fromJson)
          .toList(growable: false),
    );
  }
}
