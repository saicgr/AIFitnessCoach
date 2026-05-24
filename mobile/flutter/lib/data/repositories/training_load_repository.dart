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
  final repo = ref.watch(trainingLoadRepositoryProvider);
  return repo.fetchHistory(days: 120);
});

/// Latest training-load state — drives the hero number + classification.
final trainingLoadCurrentProvider =
    FutureProvider.autoDispose<TrainingLoadState>((ref) async {
  final repo = ref.watch(trainingLoadRepositoryProvider);
  return repo.fetchCurrent();
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
