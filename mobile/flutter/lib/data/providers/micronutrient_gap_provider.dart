/// `micronutrientGapProvider` — biggest micronutrient gap today.
///
/// Backed by `GET /api/v1/nutrition/micros/today-gap`. Returns null fields
/// when fewer than ~2 meals are logged today (the chip self-collapses on
/// that). No mock data, no silent fallback — network errors bubble to
/// `AsyncError` and the chip stays collapsed.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Shape of the gap payload returned by the backend.
class MicronutrientGap {
  final String? nutrient;
  final double? coveragePct; // 0..100 (or null)
  final double rda;
  final double current;
  final List<String> exampleFoods;

  const MicronutrientGap({
    required this.nutrient,
    required this.coveragePct,
    required this.rda,
    required this.current,
    required this.exampleFoods,
  });

  factory MicronutrientGap.fromJson(Map<String, dynamic> json) {
    final foods = (json['example_foods'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final pctRaw = json['coverage_pct'];
    return MicronutrientGap(
      nutrient: json['micro'] as String?,
      coveragePct: pctRaw is num ? pctRaw.toDouble() : null,
      rda: (json['rda'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      exampleFoods: foods,
    );
  }

  /// Convenience: true when the backend has a confident pick to show.
  bool get hasGap =>
      (nutrient ?? '').isNotEmpty && coveragePct != null;
}

final micronutrientGapProvider =
    FutureProvider.autoDispose<MicronutrientGap>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>(
    '/nutrition/micros/today-gap',
  );
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const MicronutrientGap(
      nutrient: null,
      coveragePct: null,
      rda: 0,
      current: 0,
      exampleFoods: <String>[],
    );
  }
  return MicronutrientGap.fromJson(data);
});
