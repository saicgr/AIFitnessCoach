import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../../core/constants/api_constants.dart';

/// Activity type enum for social posts
enum SocialActivityType {
  workoutCompleted('workout_completed'),
  achievementEarned('achievement_earned'),
  personalRecord('personal_record'),
  weightMilestone('weight_milestone'),
  streakMilestone('streak_milestone');

  final String value;
  const SocialActivityType(this.value);
}

/// Visibility level for posts
enum PostVisibility {
  public('public'),
  friends('friends'),
  family('family'),
  private('private');

  final String value;
  const PostVisibility(this.value);
}

/// Social service for activity feed, reactions, comments, challenges
class SocialService {
  final ApiClient _apiClient;

  SocialService(this._apiClient);

  // ============================================================
  // ACTIVITY FEED
  // ============================================================

  /// Create a new activity post
  Future<Map<String, dynamic>> createActivity({
    required String userId,
    required SocialActivityType activityType,
    required Map<String, dynamic> activityData,
    PostVisibility visibility = PostVisibility.friends,
    String? workoutLogId,
    String? achievementId,
    String? prId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/social/feed',
        queryParameters: {'user_id': userId},
        data: {
          'activity_type': activityType.value,
          'activity_data': activityData,
          'visibility': visibility.value,
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
          if (achievementId != null) 'achievement_id': achievementId,
          if (prId != null) 'pr_id': prId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Activity created: ${activityType.value}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error creating activity: $e');
      rethrow;
    }
  }

  /// Get activity feed for user
  Future<Map<String, dynamic>> getActivityFeed({
    required String userId,
    int page = 1,
    int pageSize = 20,
    SocialActivityType? activityType,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (activityType != null) 'activity_type': activityType.value,
      };

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/social/feed/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting feed: $e');
      rethrow;
    }
  }

  /// Delete an activity post
  Future<void> deleteActivity({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.baseUrl}/social/feed/$activityId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Activity deleted: $activityId');
      } else {
        throw Exception('Failed to delete activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error deleting activity: $e');
      rethrow;
    }
  }

  // ============================================================
  // REACTIONS
  // ============================================================

  /// Add or update reaction to an activity
  Future<void> addReaction({
    required String userId,
    required String activityId,
    required String reactionType, // 'cheer', 'fire', 'strong', 'clap', 'heart'
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/social/reactions',
        queryParameters: {'user_id': userId},
        data: {
          'activity_id': activityId,
          'reaction_type': reactionType,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Reaction added: $reactionType');
      } else {
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove reaction from an activity
  Future<void> removeReaction({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.baseUrl}/social/reactions/$activityId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Reaction removed');
      } else {
        throw Exception('Failed to remove reaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error removing reaction: $e');
      rethrow;
    }
  }

  /// Get reactions summary for an activity
  Future<Map<String, dynamic>> getReactions({
    required String activityId,
    String? userId,
  }) async {
    try {
      final queryParams = {
        if (userId != null) 'user_id': userId,
      };

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/social/reactions/$activityId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get reactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting reactions: $e');
      rethrow;
    }
  }

  // ============================================================
  // PRIVACY SETTINGS
  // ============================================================

  /// Get user's privacy settings
  Future<Map<String, dynamic>> getPrivacySettings(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/social/privacy/$userId',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get privacy settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting privacy settings: $e');
      // Return default settings on error
      return {
        'show_workouts': true,
        'show_achievements': true,
        'show_weight_progress': false,
        'show_personal_records': true,
      };
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    required String userId,
    bool? showWorkouts,
    bool? showAchievements,
    bool? showWeightProgress,
    bool? showPersonalRecords,
    PostVisibility? profileVisibility,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (showWorkouts != null) data['show_workouts'] = showWorkouts;
      if (showAchievements != null) data['show_achievements'] = showAchievements;
      if (showWeightProgress != null) data['show_weight_progress'] = showWeightProgress;
      if (showPersonalRecords != null) data['show_personal_records'] = showPersonalRecords;
      if (profileVisibility != null) data['profile_visibility'] = profileVisibility.value;

      final response = await _apiClient.put(
        '${ApiConstants.baseUrl}/social/privacy/$userId',
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Privacy settings updated');
      } else {
        throw Exception('Failed to update privacy: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error updating privacy: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Check if user has enabled sharing for a specific activity type
  Future<bool> canShareActivity({
    required String userId,
    required SocialActivityType activityType,
  }) async {
    try {
      final settings = await getPrivacySettings(userId);

      switch (activityType) {
        case SocialActivityType.workoutCompleted:
          return settings['show_workouts'] ?? true;
        case SocialActivityType.achievementEarned:
          return settings['show_achievements'] ?? true;
        case SocialActivityType.personalRecord:
          return settings['show_personal_records'] ?? true;
        case SocialActivityType.weightMilestone:
          return settings['show_weight_progress'] ?? false;
        case SocialActivityType.streakMilestone:
          return settings['show_achievements'] ?? true; // Grouped with achievements
      }
    } catch (e) {
      debugPrint('⚠️ [Social] Error checking privacy, defaulting to allow: $e');
      // Default to sharing if we can't check (except weight)
      return activityType != SocialActivityType.weightMilestone;
    }
  }

  /// Auto-post workout completion (called after workout is saved)
  Future<void> autoPostWorkoutCompletion({
    required String userId,
    required String workoutLogId,
    required String workoutName,
    required int durationMinutes,
    required int exercisesCount,
    double? totalVolume,
    PostVisibility visibility = PostVisibility.friends,
  }) async {
    // Check privacy settings
    final canShare = await canShareActivity(
      userId: userId,
      activityType: SocialActivityType.workoutCompleted,
    );

    if (!canShare) {
      debugPrint('🔒 [Social] Workout sharing disabled by user');
      return;
    }

    try {
      await createActivity(
        userId: userId,
        activityType: SocialActivityType.workoutCompleted,
        activityData: {
          'workout_name': workoutName,
          'duration_minutes': durationMinutes,
          'exercises_count': exercisesCount,
          if (totalVolume != null) 'total_volume': totalVolume,
        },
        visibility: visibility,
        workoutLogId: workoutLogId,
      );

      debugPrint('🎉 [Social] Auto-posted workout completion');
    } catch (e) {
      debugPrint('⚠️ [Social] Failed to auto-post workout: $e');
      // Don't throw - this is a non-critical feature
    }
  }

  /// Auto-post achievement earned
  Future<void> autoPostAchievement({
    required String userId,
    required String achievementId,
    required String achievementName,
    required String achievementIcon,
    String? achievementCategory,
    PostVisibility visibility = PostVisibility.friends,
  }) async {
    final canShare = await canShareActivity(
      userId: userId,
      activityType: SocialActivityType.achievementEarned,
    );

    if (!canShare) {
      debugPrint('🔒 [Social] Achievement sharing disabled by user');
      return;
    }

    try {
      await createActivity(
        userId: userId,
        activityType: SocialActivityType.achievementEarned,
        activityData: {
          'achievement_name': achievementName,
          'achievement_icon': achievementIcon,
          if (achievementCategory != null) 'achievement_category': achievementCategory,
        },
        visibility: visibility,
        achievementId: achievementId,
      );

      debugPrint('🏆 [Social] Auto-posted achievement');
    } catch (e) {
      debugPrint('⚠️ [Social] Failed to auto-post achievement: $e');
    }
  }

  /// Auto-post personal record
  Future<void> autoPostPersonalRecord({
    required String userId,
    required String prId,
    required String exerciseName,
    required double recordValue,
    required String recordUnit,
    PostVisibility visibility = PostVisibility.friends,
  }) async {
    final canShare = await canShareActivity(
      userId: userId,
      activityType: SocialActivityType.personalRecord,
    );

    if (!canShare) {
      debugPrint('🔒 [Social] PR sharing disabled by user');
      return;
    }

    try {
      await createActivity(
        userId: userId,
        activityType: SocialActivityType.personalRecord,
        activityData: {
          'exercise_name': exerciseName,
          'record_value': recordValue,
          'record_unit': recordUnit,
        },
        visibility: visibility,
        prId: prId,
      );

      debugPrint('💪 [Social] Auto-posted personal record');
    } catch (e) {
      debugPrint('⚠️ [Social] Failed to auto-post PR: $e');
    }
  }

  /// Auto-post streak milestone
  Future<void> autoPostStreakMilestone({
    required String userId,
    required int streakDays,
    PostVisibility visibility = PostVisibility.friends,
  }) async {
    // Only post on significant milestones
    final milestones = [7, 14, 30, 60, 90, 100, 180, 365];
    if (!milestones.contains(streakDays)) {
      return; // Not a milestone worth posting
    }

    final canShare = await canShareActivity(
      userId: userId,
      activityType: SocialActivityType.streakMilestone,
    );

    if (!canShare) {
      debugPrint('🔒 [Social] Streak sharing disabled by user');
      return;
    }

    try {
      await createActivity(
        userId: userId,
        activityType: SocialActivityType.streakMilestone,
        activityData: {
          'streak_days': streakDays,
        },
        visibility: visibility,
      );

      debugPrint('🔥 [Social] Auto-posted streak milestone: $streakDays days');
    } catch (e) {
      debugPrint('⚠️ [Social] Failed to auto-post streak: $e');
    }
  }

  /// Auto-post weight milestone
  Future<void> autoPostWeightMilestone({
    required String userId,
    required double weightChange,
    PostVisibility visibility = PostVisibility.friends,
  }) async {
    final canShare = await canShareActivity(
      userId: userId,
      activityType: SocialActivityType.weightMilestone,
    );

    if (!canShare) {
      debugPrint('🔒 [Social] Weight sharing disabled by user');
      return;
    }

    // Only post on significant milestones (every 5 lbs)
    final absChange = weightChange.abs();
    if (absChange < 5 || absChange % 5 != 0) {
      return;
    }

    try {
      await createActivity(
        userId: userId,
        activityType: SocialActivityType.weightMilestone,
        activityData: {
          'weight_change': weightChange,
        },
        visibility: visibility,
      );

      debugPrint('⚖️ [Social] Auto-posted weight milestone: ${weightChange}lbs');
    } catch (e) {
      debugPrint('⚠️ [Social] Failed to auto-post weight: $e');
    }
  }
}

// Import for debug print
import 'package:flutter/foundation.dart';
