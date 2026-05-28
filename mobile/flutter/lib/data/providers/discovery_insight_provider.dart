/// `discoveryInsightProvider` — single rotating pattern insight.
///
/// Backed by `GET /api/v1/insights/discovery`. Surfaces the strongest of a
/// few candidate patterns (sleep delta on workout days, weekend vs weekday
/// calorie spread, big-meal day sleep delta). All fields null when no
/// candidate has enough signal — the tile collapses in that case.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

class DiscoveryInsightApi {
  final String? insightId;
  final String? title;
  final String? body;
  final String? magnitudeLabel;
  final int evidenceDays;

  const DiscoveryInsightApi({
    required this.insightId,
    required this.title,
    required this.body,
    required this.magnitudeLabel,
    required this.evidenceDays,
  });

  factory DiscoveryInsightApi.fromJson(Map<String, dynamic> json) {
    return DiscoveryInsightApi(
      insightId: json['insight_id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      magnitudeLabel: json['magnitude_label'] as String?,
      evidenceDays: (json['evidence_days'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasInsight =>
      (insightId ?? '').isNotEmpty &&
      (title ?? '').isNotEmpty &&
      (body ?? '').isNotEmpty;
}

final discoveryInsightProvider =
    FutureProvider.autoDispose<DiscoveryInsightApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>('/insights/discovery');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const DiscoveryInsightApi(
      insightId: null,
      title: null,
      body: null,
      magnitudeLabel: null,
      evidenceDays: 0,
    );
  }
  return DiscoveryInsightApi.fromJson(data);
});
