import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Repository for the training-load endpoints (Banister TRIMP + ACWR).
///
/// Backed by `backend/api/v1/training_load_endpoints.py`. Self-contained —
/// no caching, no fallback data. Errors bubble up to the caller, per
/// `feedback_no_silent_fallbacks.md`.
class TrainingLoadRepository {
  final ApiClient _apiClient;

  TrainingLoadRepository(this._apiClient);

  /// Per-day timeline of {daily_trimp, acute_load, chronic_load, acwr}.
  ///
  /// [days] is the visible window (chart x-axis length). The backend still
  /// pulls 27 extra prior days of cardio so chronic_load on the leftmost
  /// visible day is honest (28-day right-aligned rolling sum).
  Future<List<TrainingLoadDayPoint>> fetchHistory({int days = 120}) async {
    debugPrint('🏃 [TrainingLoad] fetchHistory days=$days');
    final response = await _apiClient.get(
      '/training-load/history',
      queryParameters: {'days': days},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load training-load history (${response.statusCode})',
      );
    }
    final list = response.data as List<dynamic>;
    return list
        .map((row) =>
            TrainingLoadDayPoint.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Today's intraday Daily Cardio Load accumulation + target band + ACWR.
  Future<TrainingLoadToday> fetchToday() async {
    debugPrint('🏃 [TrainingLoad] fetchToday');
    final response = await _apiClient.get('/training-load/today');
    if (response.statusCode != 200) {
      throw Exception('Failed to load today\'s cardio load (${response.statusCode})');
    }
    return TrainingLoadToday.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  /// Latest day's TRIMP / acute / chronic / ACWR + classification state.
  Future<TrainingLoadState> fetchCurrent() async {
    debugPrint('🏃 [TrainingLoad] fetchCurrent');
    final response = await _apiClient.get('/training-load/current');
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load training-load state (${response.statusCode})',
      );
    }
    return TrainingLoadState.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

/// Riverpod provider for [TrainingLoadRepository].
final trainingLoadRepositoryProvider =
    Provider<TrainingLoadRepository>((ref) {
  return TrainingLoadRepository(ref.watch(apiClientProvider));
});

/// 120-day training-load history (default). Use `.family` if a different
/// window length is needed by the caller.
final trainingLoadHistoryProvider =
    FutureProvider.autoDispose<List<TrainingLoadDayPoint>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(trainingLoadRepositoryProvider);
  return repo.fetchHistory(days: 120);
});

/// Latest training-load state — drives the hero number + classification.
final trainingLoadCurrentProvider =
    FutureProvider.autoDispose<TrainingLoadState>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(trainingLoadRepositoryProvider);
  return repo.fetchCurrent();
});

/// Today's intraday Daily Cardio Load — drives the "Today's progress" chart.
final trainingLoadTodayProvider =
    FutureProvider.autoDispose<TrainingLoadToday>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(trainingLoadRepositoryProvider);
  return repo.fetchToday();
});

// ---------------------------------------------------------------------------
// Models — mirror backend pydantic models
// ---------------------------------------------------------------------------

/// One day in the training-load timeline.
@immutable
class TrainingLoadDayPoint {
  final DateTime date;
  final double dailyTrimp;
  final double acuteLoad;
  final double chronicLoad;
  final double? acwr;

  const TrainingLoadDayPoint({
    required this.date,
    required this.dailyTrimp,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
  });

  factory TrainingLoadDayPoint.fromJson(Map<String, dynamic> json) {
    return TrainingLoadDayPoint(
      date: DateTime.parse(json['date'] as String),
      dailyTrimp: (json['daily_trimp'] as num).toDouble(),
      acuteLoad: (json['acute_load'] as num).toDouble(),
      chronicLoad: (json['chronic_load'] as num).toDouble(),
      acwr: (json['acwr'] as num?)?.toDouble(),
    );
  }
}

/// Latest training-load snapshot + classification.
@immutable
class TrainingLoadState {
  final DateTime asOf;
  final double dailyTrimp;
  final double acuteLoad;
  final double chronicLoad;
  final double? acwr;

  /// One of: `detraining`, `balanced`, `loading`, `overreaching`,
  /// `calibration`.
  final String state;
  final String interpretation;
  final int daysOfHistory;

  const TrainingLoadState({
    required this.asOf,
    required this.dailyTrimp,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
    required this.state,
    required this.interpretation,
    required this.daysOfHistory,
  });

  bool get isCalibration => state == 'calibration';

  factory TrainingLoadState.fromJson(Map<String, dynamic> json) {
    return TrainingLoadState(
      asOf: DateTime.parse(json['as_of'] as String),
      dailyTrimp: (json['daily_trimp'] as num).toDouble(),
      acuteLoad: (json['acute_load'] as num).toDouble(),
      chronicLoad: (json['chronic_load'] as num).toDouble(),
      acwr: (json['acwr'] as num?)?.toDouble(),
      state: json['state'] as String,
      interpretation: json['interpretation'] as String,
      daysOfHistory: json['days_of_history'] as int? ?? 0,
    );
  }
}

/// One point on today's cumulative cardio-load curve.
@immutable
class TrainingLoadIntradayPoint {
  final int minute; // minute of the user-local day (0-1440)
  final double cumulative;
  const TrainingLoadIntradayPoint({required this.minute, required this.cumulative});

  factory TrainingLoadIntradayPoint.fromJson(Map<String, dynamic> json) =>
      TrainingLoadIntradayPoint(
        minute: json['minute'] as int,
        cumulative: (json['cumulative'] as num).toDouble(),
      );
}

/// Today's intraday Daily Cardio Load accumulation + target band + ACWR state.
@immutable
class TrainingLoadToday {
  final DateTime asOf;
  final int workoutCount;
  final double dailyLoad;
  final List<TrainingLoadIntradayPoint> points;
  final double? targetMin;
  final double? targetMax;
  final double? acwr;
  final String state;
  final String interpretation;

  const TrainingLoadToday({
    required this.asOf,
    required this.workoutCount,
    required this.dailyLoad,
    required this.points,
    required this.targetMin,
    required this.targetMax,
    required this.acwr,
    required this.state,
    required this.interpretation,
  });

  bool get hasTarget => targetMin != null && targetMax != null;

  factory TrainingLoadToday.fromJson(Map<String, dynamic> json) {
    return TrainingLoadToday(
      asOf: DateTime.parse(json['as_of'] as String),
      workoutCount: json['workout_count'] as int? ?? 0,
      dailyLoad: (json['daily_load'] as num?)?.toDouble() ?? 0,
      points: ((json['points'] as List<dynamic>?) ?? [])
          .map((e) => TrainingLoadIntradayPoint.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      targetMin: (json['target_min'] as num?)?.toDouble(),
      targetMax: (json['target_max'] as num?)?.toDouble(),
      acwr: (json['acwr'] as num?)?.toDouble(),
      state: json['state'] as String? ?? 'calibration',
      interpretation: json['interpretation'] as String? ?? '',
    );
  }
}
