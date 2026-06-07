import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Repository for the Fitness Index endpoint (5-axis radar + peer percentile).
///
/// Backed by `backend/api/v1/fitness_index_endpoints.py` → GET /fitness-index.
/// Axis `value == null` means no data for that axis (greyed spoke); a null
/// `percentile` means the peer cohort is below the k-anonymity threshold.
class FitnessIndexRepository {
  final ApiClient _apiClient;

  FitnessIndexRepository(this._apiClient);

  Future<FitnessIndexData> fetch() async {
    debugPrint('📊 [FitnessIndex] fetch');
    final response = await _apiClient.get('/fitness-index');
    if (response.statusCode != 200) {
      throw Exception('Failed to load fitness index (${response.statusCode})');
    }
    return FitnessIndexData.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}

final fitnessIndexRepositoryProvider =
    Provider<FitnessIndexRepository>((ref) {
  return FitnessIndexRepository(ref.watch(apiClientProvider));
});

final fitnessIndexProvider =
    FutureProvider.autoDispose<FitnessIndexData>((ref) async {
  ref.keepAlive();
  return ref.watch(fitnessIndexRepositoryProvider).fetch();
});

// ---------------------------------------------------------------------------
// Models — mirror services/fitness_index_service.py
// ---------------------------------------------------------------------------

@immutable
class FitnessAxis {
  final String key;
  final String label;
  final int? value; // 0-100, null = no data
  final int? percentile; // vs peers, null under k-anon
  final int? cohortSize;

  const FitnessAxis({
    required this.key,
    required this.label,
    required this.value,
    required this.percentile,
    required this.cohortSize,
  });

  bool get hasData => value != null;

  /// 0-1 for the radar painter (greyed spoke draws at 0 with a no-data flag).
  double get fraction => (value ?? 0) / 100.0;

  factory FitnessAxis.fromJson(Map<String, dynamic> json) {
    return FitnessAxis(
      key: json['key'] as String,
      label: json['label'] as String? ?? '',
      value: json['value'] as int?,
      percentile: json['percentile'] as int?,
      cohortSize: json['cohort_size'] as int?,
    );
  }
}

@immutable
class FitnessIndexData {
  final String localDate;
  final int? overall;
  final String focus;
  final List<FitnessAxis> axes;
  final String headline;
  final String body;
  final String delivery;

  const FitnessIndexData({
    required this.localDate,
    required this.overall,
    required this.focus,
    required this.axes,
    required this.headline,
    required this.body,
    required this.delivery,
  });

  factory FitnessIndexData.fromJson(Map<String, dynamic> json) {
    return FitnessIndexData(
      localDate: json['local_date'] as String? ?? '',
      overall: json['overall'] as int?,
      focus: json['focus'] as String? ?? 'Overall',
      axes: ((json['axes'] as List<dynamic>?) ?? [])
          .map((e) => FitnessAxis.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'deterministic_fallback',
    );
  }
}
