import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/neat.dart';
import '../services/api_client.dart';

/// NEAT repository provider
final neatRepositoryProvider = Provider<NeatRepository>((ref) {
  return NeatRepository(ref.watch(apiClientProvider));
});

/// Repository for NEAT (Non-Exercise Activity Thermogenesis) tracking
/// Handles step goals, activity tracking, scores, streaks, and achievements
class NeatRepository {
  final ApiClient _client;

  NeatRepository(this._client);

  // =========================================================================
  // Goal Management
  // =========================================================================

  /// Get current NEAT goals for a user
  Future<NeatGoal> getNeatGoals(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting goals for user $userId');
      final response = await _client.get(
        '/neat/goals',
        queryParameters: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Got goals successfully');
      return NeatGoal.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting goals: $e');
      rethrow;
    }
  }

  /// Update step goal for a user
  Future<NeatGoal> updateStepGoal(String userId, int goal) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Updating step goal to $goal for user $userId');
      final response = await _client.put(
        '/neat/goals/steps',
        data: {
          'user_id': userId,
          'target_value': goal,
        },
      );
      debugPrint('\u2705 [NEAT] Step goal updated successfully');
      return NeatGoal.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error updating step goal: $e');
      rethrow;
    }
  }

  /// Calculate progressive goal based on user history
  Future<NeatGoal> calculateProgressiveGoal(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Calculating progressive goal for user $userId');
      final response = await _client.post(
        '/neat/goals/progressive',
        data: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Progressive goal calculated');
      return NeatGoal.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error calculating progressive goal: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Activity Syncing
  // =========================================================================

  /// Sync hourly activity data from health sources
  Future<void> syncHourlyActivity(
    String userId,
    List<HourlyActivity> activities,
  ) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Syncing ${activities.length} hourly activities');
      await _client.post(
        '/neat/activity/sync',
        data: {
          'user_id': userId,
          'activities': activities.map((a) => a.toJson()).toList(),
        },
      );
      debugPrint('\u2705 [NEAT] Activity sync completed');
    } catch (e) {
      debugPrint('\u274C [NEAT] Error syncing activity: $e');
      rethrow;
    }
  }

  /// Get hourly breakdown for a specific date
  Future<NeatHourlyBreakdown> getHourlyBreakdown(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      debugPrint('\u{1F6B6} [NEAT] Getting hourly breakdown for $dateStr');
      final response = await _client.get(
        '/neat/activity/hourly',
        queryParameters: {
          'user_id': userId,
          'date': dateStr,
        },
      );
      debugPrint('\u2705 [NEAT] Got hourly breakdown');
      return NeatHourlyBreakdown.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting hourly breakdown: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Scores
  // =========================================================================

  /// Get today's NEAT score
  Future<NeatDailyScore> getTodayScore(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting today score for user $userId');
      final response = await _client.get(
        '/neat/scores/today',
        queryParameters: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Got today score');
      return NeatDailyScore.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting today score: $e');
      rethrow;
    }
  }

  /// Get score history for a date range
  Future<List<NeatDailyScore>> getScoreHistory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = startDate.toIso8601String().split('T').first;
      final endStr = endDate.toIso8601String().split('T').first;
      debugPrint('\u{1F6B6} [NEAT] Getting score history from $startStr to $endStr');
      final response = await _client.get(
        '/neat/scores/history',
        queryParameters: {
          'user_id': userId,
          'start_date': startStr,
          'end_date': endStr,
        },
      );
      debugPrint('\u2705 [NEAT] Got score history');
      final data = response.data as List;
      return data.map((json) => NeatDailyScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting score history: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Streaks
  // =========================================================================

  /// Get all NEAT streaks for a user
  Future<List<NeatStreak>> getStreaks(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting streaks for user $userId');
      final response = await _client.get(
        '/neat/streaks',
        queryParameters: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Got streaks');
      final data = response.data as List;
      return data.map((json) => NeatStreak.fromJson(json)).toList();
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting streaks: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Achievements
  // =========================================================================

  /// Get earned NEAT achievements for a user
  Future<List<UserNeatAchievement>> getAchievements(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting achievements for user $userId');
      final response = await _client.get(
        '/neat/achievements',
        queryParameters: {
          'user_id': userId,
          'earned_only': true,
        },
      );
      debugPrint('\u2705 [NEAT] Got achievements');
      final data = response.data as List;
      return data.map((json) => UserNeatAchievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting achievements: $e');
      rethrow;
    }
  }

  /// Get all available NEAT achievements (with progress)
  Future<List<UserNeatAchievement>> getAvailableAchievements(
    String userId,
  ) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting available achievements for user $userId');
      final response = await _client.get(
        '/neat/achievements',
        queryParameters: {
          'user_id': userId,
          'earned_only': false,
        },
      );
      debugPrint('\u2705 [NEAT] Got available achievements');
      final data = response.data as List;
      return data.map((json) => UserNeatAchievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting available achievements: $e');
      rethrow;
    }
  }

  /// Mark achievements as celebrated
  Future<bool> markAchievementsCelebrated(
    String userId,
    List<String> achievementIds,
  ) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Marking ${achievementIds.length} achievements as celebrated');
      await _client.post(
        '/neat/achievements/celebrate',
        data: {
          'user_id': userId,
          'achievement_ids': achievementIds,
        },
      );
      debugPrint('\u2705 [NEAT] Achievements marked as celebrated');
      return true;
    } catch (e) {
      debugPrint('\u274C [NEAT] Error marking achievements celebrated: $e');
      return false;
    }
  }

  // =========================================================================
  // Reminder Preferences
  // =========================================================================

  /// Get reminder preferences for a user
  Future<NeatReminderPreferences> getReminderPreferences(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting reminder preferences for user $userId');
      final response = await _client.get(
        '/neat/reminders/preferences',
        queryParameters: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Got reminder preferences');
      return NeatReminderPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting reminder preferences: $e');
      rethrow;
    }
  }

  /// Update reminder preferences
  Future<NeatReminderPreferences> updateReminderPreferences(
    String userId,
    NeatReminderPreferences prefs,
  ) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Updating reminder preferences for user $userId');
      final response = await _client.put(
        '/neat/reminders/preferences',
        data: {
          'user_id': userId,
          ...prefs.toJson(),
        },
      );
      debugPrint('\u2705 [NEAT] Reminder preferences updated');
      return NeatReminderPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error updating reminder preferences: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Dashboard
  // =========================================================================

  /// Get complete NEAT dashboard data
  Future<NeatDashboard> getNeatDashboard(String userId) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting dashboard for user $userId');
      final response = await _client.get(
        '/neat/dashboard',
        queryParameters: {'user_id': userId},
      );
      debugPrint('\u2705 [NEAT] Got dashboard data');
      return NeatDashboard.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting dashboard: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Weekly Summary
  // =========================================================================

  /// Get weekly summary for the current or specified week
  Future<NeatWeeklySummary> getWeeklySummary(
    String userId, {
    DateTime? weekStart,
  }) async {
    try {
      debugPrint('\u{1F6B6} [NEAT] Getting weekly summary');
      final Map<String, dynamic> params = {'user_id': userId};
      if (weekStart != null) {
        params['week_start'] = weekStart.toIso8601String().split('T').first;
      }

      final response = await _client.get(
        '/neat/summary/weekly',
        queryParameters: params,
      );
      debugPrint('\u2705 [NEAT] Got weekly summary');
      return NeatWeeklySummary.fromJson(response.data);
    } catch (e) {
      debugPrint('\u274C [NEAT] Error getting weekly summary: $e');
      rethrow;
    }
  }
}
