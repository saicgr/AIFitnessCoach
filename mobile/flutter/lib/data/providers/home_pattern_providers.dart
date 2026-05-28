/// Home-pattern providers — small read-only aggregates the sub-cards on
/// the home screen consume directly:
///
/// * [workoutMilestoneProvider] → `GET /api/v1/workouts/milestones`
/// * [dayOfWeekSkipProvider]    → `GET /api/v1/insights/day-of-week-skip`
/// * [macroPatternProvider]     → `GET /api/v1/insights/macro-pattern`
/// * [recoveryHoursProvider]    → `GET /api/v1/health/recovery-hours-remaining`
///
/// Each provider is `FutureProvider.autoDispose` so it doesn't pin memory
/// when the home screen scrolls past the card. Errors propagate as-is —
/// the consuming card decides whether to render the failure inline or
/// self-collapse (most do the latter).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

// ============================================================================
// Models
// ============================================================================

/// Response for `GET /workouts/milestones`.
class WorkoutMilestonesData {
  final int totalWorkouts;
  final int nextMilestone;
  final int remaining;

  /// Threshold crossed in the last 7 days (null if none).
  final int? justCrossed;

  const WorkoutMilestonesData({
    required this.totalWorkouts,
    required this.nextMilestone,
    required this.remaining,
    this.justCrossed,
  });

  factory WorkoutMilestonesData.fromJson(Map<String, dynamic> json) {
    return WorkoutMilestonesData(
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      nextMilestone: (json['next_milestone'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      justCrossed: (json['just_crossed'] as num?)?.toInt(),
    );
  }
}

/// Response for `GET /insights/day-of-week-skip`.
class DayOfWeekSkipData {
  /// 0=Sun..6=Sat (matches Postgres EXTRACT(DOW)).
  final int? weekday;
  final String? weekdayName;
  final double? missRate;
  final int weeksObserved;

  const DayOfWeekSkipData({
    this.weekday,
    this.weekdayName,
    this.missRate,
    this.weeksObserved = 0,
  });

  bool get hasPattern => weekday != null && weekdayName != null;

  factory DayOfWeekSkipData.fromJson(Map<String, dynamic> json) {
    return DayOfWeekSkipData(
      weekday: (json['weekday'] as num?)?.toInt(),
      weekdayName: json['weekday_name'] as String?,
      missRate: (json['miss_rate'] as num?)?.toDouble(),
      weeksObserved: (json['weeks_observed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response for `GET /insights/macro-pattern`.
class MacroPatternData {
  /// Weekdays where protein is consistently low (0=Sun..6=Sat).
  final List<int> lowWeekdays;
  final List<String> weekdayNames;
  final double? avgProteinG;
  final double targetProteinG;

  const MacroPatternData({
    this.lowWeekdays = const [],
    this.weekdayNames = const [],
    this.avgProteinG,
    this.targetProteinG = 0,
  });

  bool get hasPattern => lowWeekdays.isNotEmpty && targetProteinG > 0;

  factory MacroPatternData.fromJson(Map<String, dynamic> json) {
    final wd = json['low_weekdays'];
    final names = json['weekday_names'];
    return MacroPatternData(
      lowWeekdays: wd is List
          ? wd.map((e) => (e as num).toInt()).toList(growable: false)
          : const [],
      weekdayNames: names is List
          ? names.map((e) => e.toString()).toList(growable: false)
          : const [],
      avgProteinG: (json['avg_protein_g'] as num?)?.toDouble(),
      targetProteinG: (json['target_protein_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Response for `GET /health/recovery-hours-remaining`.
class RecoveryHoursData {
  final DateTime? lastWorkoutAt;
  final int estimatedTotalRecoveryHours;
  final int hoursRemaining;
  final DateTime? nextReadyAt;

  const RecoveryHoursData({
    this.lastWorkoutAt,
    this.estimatedTotalRecoveryHours = 0,
    this.hoursRemaining = 0,
    this.nextReadyAt,
  });

  bool get hasData => lastWorkoutAt != null;

  factory RecoveryHoursData.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return RecoveryHoursData(
      lastWorkoutAt: parse(json['last_workout_at']),
      estimatedTotalRecoveryHours:
          (json['estimated_total_recovery_hours'] as num?)?.toInt() ?? 0,
      hoursRemaining: (json['hours_remaining'] as num?)?.toInt() ?? 0,
      nextReadyAt: parse(json['next_ready_at']),
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

final workoutMilestoneProvider =
    FutureProvider.autoDispose<WorkoutMilestonesData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.get<Map<String, dynamic>>('/workouts/milestones');
  final data = resp.data;
  if (data == null) {
    throw StateError('workouts/milestones returned empty body');
  }
  return WorkoutMilestonesData.fromJson(data);
});

final dayOfWeekSkipProvider =
    FutureProvider.autoDispose<DayOfWeekSkipData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp =
      await api.get<Map<String, dynamic>>('/insights/day-of-week-skip');
  final data = resp.data;
  if (data == null) {
    throw StateError('insights/day-of-week-skip returned empty body');
  }
  return DayOfWeekSkipData.fromJson(data);
});

final macroPatternProvider =
    FutureProvider.autoDispose<MacroPatternData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.get<Map<String, dynamic>>('/insights/macro-pattern');
  final data = resp.data;
  if (data == null) {
    throw StateError('insights/macro-pattern returned empty body');
  }
  return MacroPatternData.fromJson(data);
});

final recoveryHoursProvider =
    FutureProvider.autoDispose<RecoveryHoursData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp =
      await api.get<Map<String, dynamic>>('/health/recovery-hours-remaining');
  final data = resp.data;
  if (data == null) {
    throw StateError('health/recovery-hours-remaining returned empty body');
  }
  return RecoveryHoursData.fromJson(data);
});
