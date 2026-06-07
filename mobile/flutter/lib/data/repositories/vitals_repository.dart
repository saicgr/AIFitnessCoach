import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Repository for the Vitals endpoint (overnight bio-signals vs baseline).
///
/// Backed by `backend/api/v1/health_metrics_endpoints.py` → GET /health/vitals.
/// Self-contained, no fallback data — errors bubble up
/// (feedback_no_silent_fallbacks). A signal with `state == 'no_data'` is a
/// genuine "no wearable reading", rendered as a per-signal empty state.
class VitalsRepository {
  final ApiClient _apiClient;

  VitalsRepository(this._apiClient);

  Future<VitalsData> fetch() async {
    debugPrint('❤️ [Vitals] fetch');
    final response = await _apiClient.get('/health/vitals');
    if (response.statusCode != 200) {
      throw Exception('Failed to load vitals (${response.statusCode})');
    }
    return VitalsData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(ref.watch(apiClientProvider));
});

/// Today's Vitals — drives the home card + Vitals pillar detail.
final vitalsProvider = FutureProvider.autoDispose<VitalsData>((ref) async {
  ref.keepAlive();
  return ref.watch(vitalsRepositoryProvider).fetch();
});

// ---------------------------------------------------------------------------
// Models — mirror backend pydantic (services/vitals_service.py)
// ---------------------------------------------------------------------------

@immutable
class VitalSignal {
  final String key;
  final String label;
  final String unit;
  final double? value;
  final double? baseline;
  final double? z;

  /// `high_bad` | `low_bad` | `either` — which direction is the concern.
  final String direction;

  /// `in_range` | `out_of_range` | `no_data`.
  final String state;

  const VitalSignal({
    required this.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.baseline,
    required this.z,
    required this.direction,
    required this.state,
  });

  bool get isOutOfRange => state == 'out_of_range';
  bool get hasReading => value != null && state != 'no_data';

  factory VitalSignal.fromJson(Map<String, dynamic> json) {
    return VitalSignal(
      key: json['key'] as String,
      label: json['label'] as String,
      unit: json['unit'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble(),
      baseline: (json['baseline'] as num?)?.toDouble(),
      z: (json['z'] as num?)?.toDouble(),
      direction: json['direction'] as String? ?? 'either',
      state: json['state'] as String? ?? 'no_data',
    );
  }
}

@immutable
class VitalsData {
  final String localDate;
  final List<VitalSignal> signals;
  final int outOfRangeCount;
  final int measuredCount;
  final String headline;
  final String body;

  /// `gemini` | `deterministic_fallback`.
  final String delivery;

  const VitalsData({
    required this.localDate,
    required this.signals,
    required this.outOfRangeCount,
    required this.measuredCount,
    required this.headline,
    required this.body,
    required this.delivery,
  });

  bool get hasAnyReading => measuredCount > 0;

  factory VitalsData.fromJson(Map<String, dynamic> json) {
    return VitalsData(
      localDate: json['local_date'] as String? ?? '',
      signals: ((json['signals'] as List<dynamic>?) ?? [])
          .map((e) => VitalSignal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      outOfRangeCount: json['out_of_range_count'] as int? ?? 0,
      measuredCount: json['measured_count'] as int? ?? 0,
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'deterministic_fallback',
    );
  }
}
