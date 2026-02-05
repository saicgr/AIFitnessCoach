import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood.dart';
import '../services/api_client.dart';

/// Provider for mood history repository
final moodHistoryRepositoryProvider = Provider<MoodHistoryRepository>((ref) {
  return MoodHistoryRepository(ref.watch(apiClientProvider));
});

/// Repository for mood history and analytics
class MoodHistoryRepository {
  final ApiClient _apiClient;

  MoodHistoryRepository(this._apiClient);

  /// Fetch mood check-in history for a user.
  Future<MoodHistoryResponse> getMoodHistory({
    required String userId,
    int limit = 30,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _apiClient.get(
        '/workouts/$userId/mood-history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return MoodHistoryResponse.fromJson(response.data);
      }

      return const MoodHistoryResponse(
        checkins: [],
        totalCount: 0,
        hasMore: false,
      );
    } catch (e) {
      debugPrint('Error fetching mood history: $e');
      return const MoodHistoryResponse(
        checkins: [],
        totalCount: 0,
        hasMore: false,
      );
    }
  }

  /// Fetch mood analytics for a user.
  Future<MoodAnalyticsResponse?> getMoodAnalytics({
    required String userId,
    int days = 30,
  }) async {
    try {
      final response = await _apiClient.get(
        '/workouts/$userId/mood-analytics',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data != null) {
        return MoodAnalyticsResponse.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching mood analytics: $e');
      return null;
    }
  }

  /// Get today's mood check-in for a user.
  Future<MoodHistoryItem?> getTodayMood({required String userId}) async {
    try {
      final response = await _apiClient.get('/workouts/$userId/mood-today');

      if (response.statusCode == 200 && response.data != null) {
        final hasCheckin = response.data['has_checkin'] as bool? ?? false;
        if (hasCheckin && response.data['checkin'] != null) {
          return MoodHistoryItem.fromJson(
            response.data['checkin'] as Map<String, dynamic>,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching today mood: $e');
      return null;
    }
  }

  /// Mark a mood check-in's workout as completed.
  Future<bool> markWorkoutCompleted({
    required String userId,
    required String checkinId,
  }) async {
    try {
      final response = await _apiClient.put(
        '/workouts/$userId/mood-checkins/$checkinId/complete',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking mood workout completed: $e');
      return false;
    }
  }

  /// Fetch weekly mood data for a user (last 7 days).
  Future<MoodWeeklyResponse?> getMoodWeekly({required String userId}) async {
    try {
      final response = await _apiClient.get('/workouts/$userId/mood-weekly');

      if (response.statusCode == 200 && response.data != null) {
        return MoodWeeklyResponse.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching weekly mood data: $e');
      return null;
    }
  }

  /// Fetch monthly mood calendar data for a user.
  Future<MoodCalendarResponse?> getMoodCalendar({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiClient.get(
        '/workouts/$userId/mood-calendar',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return MoodCalendarResponse.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching mood calendar data: $e');
      return null;
    }
  }
}
