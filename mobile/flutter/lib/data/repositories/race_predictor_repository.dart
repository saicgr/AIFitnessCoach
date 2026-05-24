import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Predicted race time for a single distance (5K/10K/half/marathon).
///
/// Mirrors the backend `RacePrediction` Pydantic model in
/// `backend/services/race_predictor_service.py`. Inline here (no codegen)
/// per the repo's no-build_runner invariant.
@immutable
class RacePrediction {
  final int predictedSeconds;
  final int distanceM;
  final BaseRunRef baseRun;
  final double confidence; // 0.0 - 1.0
  final String formula; // 'riegel' | 'cameron'
  final int ageDaysOfBase;

  const RacePrediction({
    required this.predictedSeconds,
    required this.distanceM,
    required this.baseRun,
    required this.confidence,
    required this.formula,
    required this.ageDaysOfBase,
  });

  factory RacePrediction.fromJson(Map<String, dynamic> json) {
    return RacePrediction(
      predictedSeconds: (json['predicted_seconds'] as num).toInt(),
      distanceM: (json['distance_m'] as num).toInt(),
      baseRun: BaseRunRef.fromJson(
        Map<String, dynamic>.from(json['base_run'] as Map),
      ),
      confidence: (json['confidence'] as num).toDouble(),
      formula: json['formula'] as String,
      ageDaysOfBase: (json['age_days_of_base'] as num).toInt(),
    );
  }

  /// 95% confidence band (± seconds) derived from the confidence value.
  /// At conf=1.0 → ±2% of predicted time. At conf=0.7 → ±5%. At conf=0.5 → ±8%.
  /// Linear interpolation keeps it simple and intuitive for the UI band.
  int get confidenceBandSeconds {
    final pctBand = 0.02 + (1.0 - confidence) * 0.10; // 2%..12%
    return (predictedSeconds * pctBand).round();
  }
}

@immutable
class BaseRunRef {
  final String? cardioLogId;
  final double distanceM;
  final int timeSeconds;
  final DateTime performedAt;

  const BaseRunRef({
    required this.cardioLogId,
    required this.distanceM,
    required this.timeSeconds,
    required this.performedAt,
  });

  factory BaseRunRef.fromJson(Map<String, dynamic> json) {
    return BaseRunRef(
      cardioLogId: json['cardio_log_id'] as String?,
      distanceM: (json['distance_m'] as num).toDouble(),
      timeSeconds: (json['time_seconds'] as num).toInt(),
      performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cardio_log_id': cardioLogId,
        'distance_m': distanceM,
        'time_seconds': timeSeconds,
        'performed_at': performedAt.toUtc().toIso8601String(),
      };
}

/// Repository wrapper for `GET /api/v1/cardio-prediction/races`.
///
/// Returns an ordered map keyed by `five_k | ten_k | half_marathon | marathon`.
/// Values are nullable — null means insufficient data (UI shows empty state).
class RacePredictorRepository {
  final ApiClient _apiClient;

  RacePredictorRepository(this._apiClient);

  Future<Map<String, RacePrediction?>> fetch() async {
    debugPrint('🏃 [RacePredictor] fetching predictions');
    final response = await _apiClient.get('/cardio-prediction/races');
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load race predictions (${response.statusCode})',
      );
    }
    final raw = Map<String, dynamic>.from(response.data as Map);
    final out = <String, RacePrediction?>{};
    for (final key in const ['five_k', 'ten_k', 'half_marathon', 'marathon']) {
      final value = raw[key];
      if (value == null) {
        out[key] = null;
      } else {
        out[key] = RacePrediction.fromJson(Map<String, dynamic>.from(value as Map));
      }
    }
    return out;
  }
}

final racePredictorRepositoryProvider = Provider<RacePredictorRepository>((ref) {
  return RacePredictorRepository(ref.watch(apiClientProvider));
});

/// Auto-refreshing predictions; UI watches this.
final racePredictionsProvider =
    FutureProvider.autoDispose<Map<String, RacePrediction?>>((ref) async {
  final repo = ref.watch(racePredictorRepositoryProvider);
  return repo.fetch();
});
