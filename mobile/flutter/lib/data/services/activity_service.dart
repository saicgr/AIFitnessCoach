import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'health_service.dart';

/// Activity service provider
final activityServiceProvider = Provider<ActivityService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityService(apiClient);
});

/// Service for syncing daily activity data to Supabase
class ActivityService {
  final ApiClient _apiClient;

  ActivityService(this._apiClient);

  /// Sync daily activity to backend
  Future<Map<String, dynamic>?> syncActivity({
    required String userId,
    required DailyActivity activity,
  }) async {
    try {
      debugPrint('🏃 [Activity] Syncing activity for ${activity.date}...');

      final response = await _apiClient.post(
        '/activity/sync',
        data: {
          'user_id': userId,
          'activity_date': _formatDate(activity.date),
          'steps': activity.steps,
          'calories_burned': activity.caloriesBurned,
          'active_calories': activity.caloriesBurned, // Use same value if no separate active calories
          'distance_meters': activity.distanceMeters,
          'resting_heart_rate': activity.restingHeartRate,
          'source': Platform.isAndroid ? 'health_connect' : 'apple_health',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Activity] Synced activity successfully');
        return response.data as Map<String, dynamic>?;
      } else {
        debugPrint('❌ [Activity] Sync failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [Activity] Error syncing activity: $e');
      return null;
    }
  }

  /// Get today's activity from backend
  Future<DailyActivity?> getTodayActivity(String userId) async {
    try {
      final response = await _apiClient.get(
        '/activity/today/$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseActivity(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error getting today activity: $e');
      return null;
    }
  }

  /// Get activity history from backend
  Future<List<DailyActivity>> getActivityHistory(
    String userId, {
    int limit = 30,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) {
        queryParams['from_date'] = _formatDate(fromDate);
      }
      if (toDate != null) {
        queryParams['to_date'] = _formatDate(toDate);
      }

      final response = await _apiClient.get(
        '/activity/history/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List<dynamic>;
        return list.map((item) => _parseActivity(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Activity] Error getting activity history: $e');
      return [];
    }
  }

  /// Get activity summary from backend
  Future<Map<String, dynamic>?> getActivitySummary(
    String userId, {
    int days = 7,
  }) async {
    try {
      final response = await _apiClient.get(
        '/activity/summary/$userId',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error getting activity summary: $e');
      return null;
    }
  }

  /// Batch sync multiple days of activity
  Future<Map<String, dynamic>?> batchSyncActivities({
    required String userId,
    required List<DailyActivity> activities,
  }) async {
    try {
      debugPrint('🏃 [Activity] Batch syncing ${activities.length} days...');

      final data = activities.map((a) => {
        'user_id': userId,
        'activity_date': _formatDate(a.date),
        'steps': a.steps,
        'calories_burned': a.caloriesBurned,
        'active_calories': a.caloriesBurned,
        'distance_meters': a.distanceMeters,
        'resting_heart_rate': a.restingHeartRate,
        'source': Platform.isAndroid ? 'health_connect' : 'apple_health',
      }).toList();

      final response = await _apiClient.post(
        '/activity/sync-batch',
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Activity] Batch sync completed');
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error batch syncing: $e');
      return null;
    }
  }

  /// Parse activity from JSON response
  DailyActivity _parseActivity(Map<String, dynamic> json) {
    return DailyActivity(
      steps: json['steps'] as int? ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      restingHeartRate: json['resting_heart_rate'] as int?,
      date: DateTime.parse(json['activity_date'] as String),
      isFromHealthConnect: true,
    );
  }

  /// Format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
