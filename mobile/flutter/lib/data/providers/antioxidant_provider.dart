import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Antioxidant rollup from logged food — a food-truth answer to Samsung's
/// wrist-optical Antioxidant Index. Backed by
/// `backend/api/v1/nutrition/micronutrients.py` →
/// GET /nutrition/antioxidant-score/{user_id}. No fallback data.
class AntioxidantRepository {
  final ApiClient _apiClient;

  AntioxidantRepository(this._apiClient);

  Future<AntioxidantData> fetch() async {
    final userId = await _apiClient.getUserId();
    if (userId == null) {
      throw Exception('Not signed in');
    }
    debugPrint('🥗 [Antioxidant] fetch');
    final response =
        await _apiClient.get('/nutrition/antioxidant-score/$userId');
    if (response.statusCode != 200) {
      throw Exception('Failed to load antioxidant score (${response.statusCode})');
    }
    return AntioxidantData.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}

final antioxidantRepositoryProvider = Provider<AntioxidantRepository>((ref) {
  return AntioxidantRepository(ref.watch(apiClientProvider));
});

final antioxidantProvider =
    FutureProvider.autoDispose<AntioxidantData>((ref) async {
  ref.keepAlive();
  return ref.watch(antioxidantRepositoryProvider).fetch();
});

// ---------------------------------------------------------------------------
// Models — mirror micronutrients.py AntioxidantScoreResponse
// ---------------------------------------------------------------------------

@immutable
class AntioxidantTrendPoint {
  final String date;
  final int score;
  const AntioxidantTrendPoint({required this.date, required this.score});

  factory AntioxidantTrendPoint.fromJson(Map<String, dynamic> json) =>
      AntioxidantTrendPoint(
        date: json['date'] as String? ?? '',
        score: json['score'] as int? ?? 0,
      );
}

@immutable
class AntioxidantContributor {
  final String name;
  final int contributionPct;
  const AntioxidantContributor(
      {required this.name, required this.contributionPct});

  factory AntioxidantContributor.fromJson(Map<String, dynamic> json) =>
      AntioxidantContributor(
        name: json['name'] as String? ?? 'Food',
        contributionPct: json['contribution_pct'] as int? ?? 0,
      );
}

@immutable
class AntioxidantData {
  final String date;
  final int score; // 0-100
  final int nutrientsCounted;
  final int foodsWithMicroData;
  final int totalFoods;
  final List<AntioxidantTrendPoint> trend;
  final List<AntioxidantContributor> topContributors;

  const AntioxidantData({
    required this.date,
    required this.score,
    required this.nutrientsCounted,
    required this.foodsWithMicroData,
    required this.totalFoods,
    required this.trend,
    required this.topContributors,
  });

  factory AntioxidantData.fromJson(Map<String, dynamic> json) {
    final coverage =
        Map<String, dynamic>.from((json['coverage'] as Map?) ?? const {});
    return AntioxidantData(
      date: json['date'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      nutrientsCounted: json['nutrients_counted'] as int? ?? 0,
      foodsWithMicroData: coverage['foods_with_micro_data'] as int? ?? 0,
      totalFoods: coverage['total_foods'] as int? ?? 0,
      trend: ((json['trend'] as List<dynamic>?) ?? [])
          .map((e) =>
              AntioxidantTrendPoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      topContributors: ((json['top_contributors'] as List<dynamic>?) ?? [])
          .map((e) => AntioxidantContributor.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
