import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inflammation_analysis.dart';
import '../services/api_client.dart';

/// Provider for InflammationRepository
final inflammationRepositoryProvider = Provider<InflammationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return InflammationRepository(client);
});

/// Repository for inflammation analysis API calls
class InflammationRepository {
  final ApiClient _client;

  InflammationRepository(this._client);

  /// Analyze ingredients for inflammation
  ///
  /// Takes ingredients text from barcode scan and returns inflammation analysis.
  /// Results are cached by barcode on the server for 90 days.
  Future<InflammationAnalysis> analyzeIngredients({
    required String userId,
    required String barcode,
    required String ingredientsText,
    String? productName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 [Inflammation] Analyzing barcode: $barcode');
      }

      final response = await _client.post(
        '/inflammation/analyze',
        data: {
          'user_id': userId,
          'barcode': barcode,
          'ingredients_text': ingredientsText,
          if (productName != null) 'product_name': productName,
        },
      );

      final analysis = InflammationAnalysis.fromJson(response.data);

      if (kDebugMode) {
        debugPrint('✅ [Inflammation] Analysis complete: score=${analysis.overallScore}, '
            'inflammatory=${analysis.inflammatoryCount}, '
            'anti-inflammatory=${analysis.antiInflammatoryCount}');
      }

      return analysis;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Inflammation] Analysis failed: $e');
      }
      rethrow;
    }
  }

  /// Get user's inflammation scan history
  Future<List<InflammationAnalysis>> getHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
    bool favoritedOnly = false,
  }) async {
    try {
      final response = await _client.get(
        '/inflammation/history/$userId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          'favorited_only': favoritedOnly,
        },
      );

      final items = (response.data['items'] as List<dynamic>? ?? [])
          .map((item) => InflammationAnalysis.fromJson(item as Map<String, dynamic>))
          .toList();

      return items;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Inflammation] Failed to get history: $e');
      }
      rethrow;
    }
  }

  /// Get user's aggregated inflammation statistics
  Future<InflammationStats> getStats({required String userId}) async {
    try {
      final response = await _client.get('/inflammation/stats/$userId');
      return InflammationStats.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Inflammation] Failed to get stats: $e');
      }
      rethrow;
    }
  }

  /// Update notes on a scan
  Future<bool> updateScanNotes({
    required String userId,
    required String scanId,
    String? notes,
  }) async {
    try {
      await _client.put(
        '/inflammation/scans/$scanId/notes',
        queryParameters: {'user_id': userId},
        data: {'notes': notes},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Inflammation] Failed to update notes: $e');
      }
      return false;
    }
  }

  /// Toggle favorite status on a scan
  Future<bool> toggleFavorite({
    required String userId,
    required String scanId,
    required bool isFavorited,
  }) async {
    try {
      await _client.put(
        '/inflammation/scans/$scanId/favorite',
        queryParameters: {'user_id': userId},
        data: {'is_favorited': isFavorited},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Inflammation] Failed to toggle favorite: $e');
      }
      return false;
    }
  }
}

/// Aggregated inflammation statistics for a user
class InflammationStats {
  final String userId;
  final int totalScans;
  final double? avgInflammationScore;
  final int inflammatoryProductsScanned;
  final int antiInflammatoryProductsScanned;
  final DateTime? lastScanAt;

  const InflammationStats({
    required this.userId,
    this.totalScans = 0,
    this.avgInflammationScore,
    this.inflammatoryProductsScanned = 0,
    this.antiInflammatoryProductsScanned = 0,
    this.lastScanAt,
  });

  factory InflammationStats.fromJson(Map<String, dynamic> json) {
    return InflammationStats(
      userId: json['user_id'] as String,
      totalScans: json['total_scans'] as int? ?? 0,
      avgInflammationScore: (json['avg_inflammation_score'] as num?)?.toDouble(),
      inflammatoryProductsScanned: json['inflammatory_products_scanned'] as int? ?? 0,
      antiInflammatoryProductsScanned: json['anti_inflammatory_products_scanned'] as int? ?? 0,
      lastScanAt: json['last_scan_at'] != null
          ? DateTime.parse(json['last_scan_at'] as String)
          : null,
    );
  }
}
