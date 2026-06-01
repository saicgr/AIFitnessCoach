/// `workoutSleepCorrelationProvider` — late-workout vs REM correlation.
///
/// Backed by `GET /api/v1/insights/workout-sleep-correlation`. Returns
/// `remDropPct` only when the backend sees a >=10% relative REM drop on
/// nights following late (>=8 PM local) sessions over the past 4 weeks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

class WorkoutSleepCorrelationApi {
  final int lateWorkoutThresholdHour;
  final double? remDropPct; // 0.0..1.0, relative drop; null when no signal
  final int sampleSize;
  final int weeks;

  const WorkoutSleepCorrelationApi({
    required this.lateWorkoutThresholdHour,
    required this.remDropPct,
    required this.sampleSize,
    required this.weeks,
  });

  factory WorkoutSleepCorrelationApi.fromJson(Map<String, dynamic> json) {
    final drop = json['rem_drop_pct'];
    return WorkoutSleepCorrelationApi(
      lateWorkoutThresholdHour:
          (json['late_workout_threshold_hour'] as num?)?.toInt() ?? 20,
      remDropPct: drop is num ? drop.toDouble() : null,
      sampleSize: (json['sample_size'] as num?)?.toInt() ?? 0,
      weeks: (json['weeks'] as num?)?.toInt() ?? 4,
    );
  }

  /// True when there's a meaningful late-night → REM-drop signal worth
  /// surfacing on the home card.
  bool get hasFinding =>
      remDropPct != null && remDropPct! > 0 && sampleSize >= 3;
}

final workoutSleepCorrelationApiProvider =
    FutureProvider.autoDispose<WorkoutSleepCorrelationApi>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>(
    '/insights/workout-sleep-correlation',
  );
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const WorkoutSleepCorrelationApi(
      lateWorkoutThresholdHour: 20,
      remDropPct: null,
      sampleSize: 0,
      weeks: 4,
    );
  }
  return WorkoutSleepCorrelationApi.fromJson(data);
});
