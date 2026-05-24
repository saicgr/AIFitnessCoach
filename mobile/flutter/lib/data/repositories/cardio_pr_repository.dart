import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cardio_pr.dart';
import '../services/api_client.dart';

/// Repository for cardio PRs (`backend/api/v1/cardio_pr_endpoints.py`).
///
/// Reads the `personal_records` table filtered to rows where `sport IS NOT
/// NULL` — added in migration 2094. Writes are owned by the cardio-log
/// insert path (server-side), not by this repository.
class CardioPrRepository {
  final ApiClient _api;
  CardioPrRepository(this._api);

  /// All-time cardio PRs grouped by sport. Each item already carries its
  /// own 10-point sparkline, so a list render needs no follow-up call.
  Future<List<CardioPrGroup>> listAll() async {
    debugPrint('🏃 [CardioPR] listAll');
    final resp = await _api.get('/cardio-prs');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load cardio PRs (${resp.statusCode})');
    }
    final data = Map<String, dynamic>.from(resp.data as Map);
    final groups = (data['groups'] as List<dynamic>? ?? const [])
        .map((g) => CardioPrGroup.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList(growable: false);
    return groups;
  }

  /// Flat convenience — flatten groups into a single list of records.
  Future<List<CardioPersonalRecord>> listFlat() async {
    final groups = await listAll();
    return [for (final g in groups) ...g.items];
  }

  /// Time-series of attempts for a single `kind` (optionally sport-scoped).
  /// Powers the inline sparkline shown when a PR row is tapped.
  Future<List<CardioPrSparklinePoint>> history(
    String kind, {
    String? sport,
    int limit = 30,
  }) async {
    debugPrint('🏃 [CardioPR] history kind=$kind sport=$sport limit=$limit');
    final resp = await _api.get(
      '/cardio-prs/$kind/history',
      queryParameters: {
        'limit': limit,
        if (sport != null) 'sport': sport,
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to load PR history (${resp.statusCode})');
    }
    final data = Map<String, dynamic>.from(resp.data as Map);
    final points = (data['points'] as List<dynamic>? ?? const [])
        .map((p) =>
            CardioPrSparklinePoint.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(growable: false);
    return points;
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final cardioPrRepositoryProvider = Provider<CardioPrRepository>((ref) {
  return CardioPrRepository(ref.watch(apiClientProvider));
});

/// All-time cardio PRs grouped by sport. `.autoDispose` so the cache
/// resets after the user closes the sheet — keeps memory tight.
final cardioPrsProvider =
    FutureProvider.autoDispose<List<CardioPrGroup>>((ref) async {
  final repo = ref.watch(cardioPrRepositoryProvider);
  return repo.listAll();
});

/// History for a specific (kind, sport) — used by the inline sparkline.
/// `.family` parameter is a tuple-equivalent so two identical taps share
/// the cached result.
class CardioPrHistoryParams {
  final String kind;
  final String? sport;
  final int limit;
  const CardioPrHistoryParams({
    required this.kind,
    this.sport,
    this.limit = 30,
  });

  @override
  bool operator ==(Object other) =>
      other is CardioPrHistoryParams &&
      other.kind == kind &&
      other.sport == sport &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(kind, sport, limit);
}

final cardioPrHistoryProvider = FutureProvider.autoDispose
    .family<List<CardioPrSparklinePoint>, CardioPrHistoryParams>(
        (ref, params) async {
  final repo = ref.watch(cardioPrRepositoryProvider);
  return repo.history(params.kind, sport: params.sport, limit: params.limit);
});
