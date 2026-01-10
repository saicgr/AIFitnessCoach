import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feature_request.dart';
import '../services/api_client.dart';

/// Feature repository provider
final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FeatureRepository(apiClient);
});

/// Feature repository for API calls (Robinhood-style voting system)
class FeatureRepository {
  final ApiClient _apiClient;

  FeatureRepository(this._apiClient);

  /// Get all feature requests with optional status filter
  Future<List<FeatureRequest>> getFeatures({
    String? status,
    String? userId,
  }) async {
    try {
      debugPrint('🔍 [Features] Fetching features (status=$status, userId=$userId)');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _apiClient.get(
        '/features/list',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final features = data
            .map((json) => FeatureRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Features] Fetched ${features.length} features');
        return features;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Features] Error fetching features: $e');
      rethrow;
    }
  }

  /// Get a specific feature by ID
  Future<FeatureRequest?> getFeature(String featureId, String? userId) async {
    try {
      debugPrint('🔍 [Features] Fetching feature $featureId');

      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _apiClient.get(
        '/features/$featureId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return FeatureRequest.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Features] Error fetching feature: $e');
      rethrow;
    }
  }

  /// Create a new feature request
  Future<FeatureRequest> createFeature({
    required String title,
    required String description,
    required String category,
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [Features] Creating feature: $title');

      final response = await _apiClient.post(
        '/features/create',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'user_id': userId,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('✅ [Features] Feature created successfully');
        return FeatureRequest.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to create feature request');
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // User hit the 2-suggestion limit
        throw Exception('You have reached the maximum of 2 feature suggestions');
      }
      debugPrint('❌ [Features] Error creating feature: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ [Features] Error creating feature: $e');
      rethrow;
    }
  }

  /// Toggle vote for a feature (vote if not voted, unvote if already voted)
  Future<Map<String, dynamic>> toggleVote({
    required String featureId,
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [Features] Toggling vote for feature $featureId');

      final response = await _apiClient.post(
        '/features/vote',
        data: {
          'feature_id': featureId,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        debugPrint('✅ [Features] Vote toggled: ${result['action']}');
        return result;
      }

      throw Exception('Failed to toggle vote');
    } catch (e) {
      debugPrint('❌ [Features] Error toggling vote: $e');
      rethrow;
    }
  }

  /// Get remaining submissions count for a user
  Future<Map<String, dynamic>> getRemainingSubmissions(String userId) async {
    try {
      debugPrint('🔍 [Features] Checking remaining submissions for user $userId');

      final response = await _apiClient.get(
        '/features/user/$userId/remaining',
      );

      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        debugPrint(
          '✅ [Features] Remaining submissions: ${result['remaining']}/${result['total_limit']}',
        );
        return result;
      }

      throw Exception('Failed to get remaining submissions');
    } catch (e) {
      debugPrint('❌ [Features] Error getting remaining submissions: $e');
      rethrow;
    }
  }
}
