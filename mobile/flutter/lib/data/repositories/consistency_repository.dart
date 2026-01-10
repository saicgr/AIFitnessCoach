import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consistency.dart';
import '../models/workout_day_detail.dart';
import '../services/api_client.dart';

/// Consistency repository provider
final consistencyRepositoryProvider = Provider<ConsistencyRepository>((ref) {
  return ConsistencyRepository(ref.watch(apiClientProvider));
});

/// Repository for consistency insights, streaks, and workout patterns
class ConsistencyRepository {
  final ApiClient _client;

  ConsistencyRepository(this._client);

  // ============================================
  // Insights Endpoints
  // ============================================

  /// Get comprehensive consistency insights
  Future<ConsistencyInsights> getInsights({
    required String userId,
    int daysBack = 90,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Getting insights for $userId');
      final response = await _client.get(
        '/consistency/insights',
        queryParameters: {
          'user_id': userId,
          'days_back': daysBack,
        },
      );
      debugPrint('✅ [Consistency] Got insights successfully');
      return ConsistencyInsights.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error getting insights: $e');
      rethrow;
    }
  }

  /// Get detailed consistency patterns
  Future<ConsistencyPatterns> getPatterns({
    required String userId,
    int daysBack = 180,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Getting patterns for $userId');
      final response = await _client.get(
        '/consistency/patterns',
        queryParameters: {
          'user_id': userId,
          'days_back': daysBack,
        },
      );
      debugPrint('✅ [Consistency] Got patterns successfully');
      return ConsistencyPatterns.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error getting patterns: $e');
      rethrow;
    }
  }

  /// Get calendar heatmap data
  Future<CalendarHeatmapResponse> getCalendarHeatmap({
    required String userId,
    int weeks = 4,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Getting calendar heatmap for $userId');
      final response = await _client.get(
        '/consistency/calendar',
        queryParameters: {
          'user_id': userId,
          'weeks': weeks,
        },
      );
      debugPrint('✅ [Consistency] Got calendar heatmap successfully');
      return CalendarHeatmapResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error getting calendar heatmap: $e');
      rethrow;
    }
  }

  // ============================================
  // Streak Recovery Endpoints
  // ============================================

  /// Initiate streak recovery
  Future<StreakRecoveryResponse> initiateRecovery({
    required String userId,
    String recoveryType = 'standard',
  }) async {
    try {
      debugPrint('🔍 [Consistency] Initiating streak recovery for $userId');
      final response = await _client.post(
        '/consistency/streak-recovery',
        data: {
          'user_id': userId,
          'recovery_type': recoveryType,
        },
      );
      debugPrint('✅ [Consistency] Streak recovery initiated');
      return StreakRecoveryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error initiating recovery: $e');
      rethrow;
    }
  }

  /// Complete streak recovery attempt
  Future<Map<String, dynamic>> completeRecovery({
    required String attemptId,
    required String userId,
    String? workoutId,
    bool wasSuccessful = true,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Completing recovery attempt $attemptId');
      final response = await _client.post(
        '/consistency/streak-recovery/$attemptId/complete',
        queryParameters: {
          'user_id': userId,
          'was_successful': wasSuccessful,
          if (workoutId != null) 'workout_id': workoutId,
        },
      );
      debugPrint('✅ [Consistency] Recovery completed');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error completing recovery: $e');
      rethrow;
    }
  }

  // ============================================
  // Day Detail & Exercise Search Endpoints
  // ============================================

  /// Get detailed workout data for a specific day
  Future<WorkoutDayDetail> getDayDetail({
    required String userId,
    required String date,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Getting day detail for $userId on $date');
      final response = await _client.get(
        '/consistency/day-detail',
        queryParameters: {
          'user_id': userId,
          'date': date,
        },
      );
      debugPrint('✅ [Consistency] Got day detail successfully');
      return WorkoutDayDetail.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error getting day detail: $e');
      rethrow;
    }
  }

  /// Search exercise history across all workouts
  Future<ExerciseSearchResponse> searchExercise({
    required String userId,
    required String exerciseName,
    int weeks = 52,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Searching exercise "$exerciseName" for $userId');
      final response = await _client.get(
        '/consistency/search-exercise',
        queryParameters: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'weeks': weeks,
        },
      );
      debugPrint('✅ [Consistency] Found exercise history');
      return ExerciseSearchResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Consistency] Error searching exercise: $e');
      rethrow;
    }
  }

  /// Get exercise name suggestions for autocomplete
  Future<List<ExerciseSuggestion>> getExerciseSuggestions({
    required String userId,
    String query = '',
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 [Consistency] Getting exercise suggestions for "$query"');
      final response = await _client.get(
        '/consistency/exercise-suggestions',
        queryParameters: {
          'user_id': userId,
          'query': query,
          'limit': limit,
        },
      );
      debugPrint('✅ [Consistency] Got ${(response.data as List).length} suggestions');
      return (response.data as List)
          .map((e) => ExerciseSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [Consistency] Error getting suggestions: $e');
      rethrow;
    }
  }
}
