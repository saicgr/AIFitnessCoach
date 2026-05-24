import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Single VO2max measurement on the trend chart.
///
/// Mirrors `Vo2MaxHistoryPoint` in
/// `backend/api/v1/vo2max_endpoints.py`. Inline (no codegen) per the
/// no-build_runner invariant. `source` is one of `calculated | measured |
/// health_kit | fitness_test | manual` or null.
@immutable
class Vo2MaxPoint {
  final DateTime recordedAt;
  final double mlPerKgPerMin;
  final String? source;

  const Vo2MaxPoint({
    required this.recordedAt,
    required this.mlPerKgPerMin,
    this.source,
  });

  factory Vo2MaxPoint.fromJson(Map<String, dynamic> json) {
    return Vo2MaxPoint(
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      mlPerKgPerMin: (json['ml_per_kg_per_min'] as num).toDouble(),
      source: json['source'] as String?,
    );
  }

  /// Pretty source label for the hero block. Returns null when source is
  /// unknown so callers can decide whether to render the chip at all.
  String? get sourceLabel {
    switch (source) {
      case 'health_kit':
        return 'Apple Watch';
      case 'manual':
        return 'Manual';
      case 'measured':
        return 'Measured';
      case 'fitness_test':
        return 'Fitness test';
      case 'calculated':
        return 'Calculated';
      default:
        return null;
    }
  }
}

/// Latest VO2max snapshot. All-null fields when the user has no
/// measurements — UI uses this to render the empty state.
@immutable
class Vo2MaxLatest {
  final DateTime? recordedAt;
  final double? mlPerKgPerMin;
  final String? source;
  final int? fitnessAge;

  const Vo2MaxLatest({
    this.recordedAt,
    this.mlPerKgPerMin,
    this.source,
    this.fitnessAge,
  });

  factory Vo2MaxLatest.fromJson(Map<String, dynamic> json) {
    final ra = json['recorded_at'];
    final v = json['ml_per_kg_per_min'];
    return Vo2MaxLatest(
      recordedAt: ra == null ? null : DateTime.parse(ra as String).toLocal(),
      mlPerKgPerMin: v == null ? null : (v as num).toDouble(),
      source: json['source'] as String?,
      fitnessAge: json['fitness_age'] as int?,
    );
  }

  bool get hasData => mlPerKgPerMin != null;

  String? get sourceLabel {
    switch (source) {
      case 'health_kit':
        return 'Apple Watch';
      case 'manual':
        return 'Manual';
      case 'measured':
        return 'Measured';
      case 'fitness_test':
        return 'Fitness test';
      case 'calculated':
        return 'Calculated';
      default:
        return null;
    }
  }
}

/// Repository wrapper for `/vo2max/*`.
class Vo2MaxRepository {
  final ApiClient _apiClient;

  Vo2MaxRepository(this._apiClient);

  /// `GET /vo2max/history?days=...` — ascending by `recorded_at`.
  Future<List<Vo2MaxPoint>> history({int days = 180}) async {
    debugPrint('💪 [VO2max] history days=$days');
    final resp = await _apiClient.get(
      '/vo2max/history',
      queryParameters: {'days': days},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to load VO2max history (${resp.statusCode})');
    }
    final raw = resp.data;
    if (raw is! List) {
      throw Exception('Unexpected VO2max history payload shape');
    }
    return raw
        .map((e) => Vo2MaxPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  /// `GET /vo2max/latest` — view-backed, returns `Vo2MaxLatest` whose
  /// `hasData` is false when the user has no qualifying measurement.
  Future<Vo2MaxLatest> latest() async {
    debugPrint('💪 [VO2max] latest');
    final resp = await _apiClient.get('/vo2max/latest');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load latest VO2max (${resp.statusCode})');
    }
    final raw = resp.data;
    if (raw is! Map) {
      throw Exception('Unexpected VO2max latest payload shape');
    }
    return Vo2MaxLatest.fromJson(Map<String, dynamic>.from(raw));
  }
}

final vo2MaxRepositoryProvider = Provider<Vo2MaxRepository>((ref) {
  return Vo2MaxRepository(ref.watch(apiClientProvider));
});

/// 180-day trend for the detail screen. autoDispose so navigating away
/// frees the cache.
final vo2MaxHistoryProvider =
    FutureProvider.autoDispose<List<Vo2MaxPoint>>((ref) async {
  final repo = ref.watch(vo2MaxRepositoryProvider);
  return repo.history(days: 180);
});

/// Latest VO2max snapshot — drives the hero block.
final vo2MaxLatestProvider =
    FutureProvider.autoDispose<Vo2MaxLatest>((ref) async {
  final repo = ref.watch(vo2MaxRepositoryProvider);
  return repo.latest();
});
