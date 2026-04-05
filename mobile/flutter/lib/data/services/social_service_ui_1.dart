part of 'social_service.dart';

/// Methods extracted from SocialService
extension _SocialServiceExt1 on SocialService {

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
        '/social/feed',
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
    String sortBy = 'recent',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'sort_by': sortBy,
        if (activityType != null) 'activity_type': activityType.value,
      };

      final response = await _apiClient.get(
        '/social/feed/$userId',
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
        '/social/reactions',
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


  // ============================================================
  // COMMENTS
  // ============================================================

  /// Get comments for an activity
  Future<Map<String, dynamic>> getComments({
    required String activityId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/comments/$activityId',
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get comments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting comments: $e');
      rethrow;
    }
  }


  /// Add a comment to an activity
  Future<Map<String, dynamic>> addComment({
    required String userId,
    required String activityId,
    required String text,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/comments',
        queryParameters: {'user_id': userId},
        data: {
          'activity_id': activityId,
          'comment_text': text,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Comment added');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error adding comment: $e');
      rethrow;
    }
  }


  // ============================================================
  // EDIT ACTIVITY
  // ============================================================

  /// Edit an activity's data (caption, flairs)
  Future<Map<String, dynamic>> editActivity({
    required String userId,
    required String activityId,
    required Map<String, dynamic> activityData,
  }) async {
    try {
      final response = await _apiClient.put(
        '/social/feed/$activityId',
        queryParameters: {'user_id': userId},
        data: activityData,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Activity edited: $activityId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to edit activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error editing activity: $e');
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
        '/social/privacy/$userId',
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
        '/social/privacy/$userId',
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
        case SocialActivityType.workoutShared:
          return settings['show_workouts'] ?? true;
        case SocialActivityType.achievementEarned:
          return settings['show_achievements'] ?? true;
        case SocialActivityType.personalRecord:
          return settings['show_personal_records'] ?? true;
        case SocialActivityType.weightMilestone:
          return settings['show_weight_progress'] ?? false;
        case SocialActivityType.streakMilestone:
          return settings['show_achievements'] ?? true; // Grouped with achievements
        case SocialActivityType.manualPost:
          return true; // Manual posts are always allowed (user explicitly creates them)
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
    List<Map<String, dynamic>>? exercisesPerformance,
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
          if (exercisesPerformance != null && exercisesPerformance.isNotEmpty)
            'exercises_performance': exercisesPerformance,
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


  // ============================================================
  // CHALLENGES
  // ============================================================

  /// Get challenges (public and user's challenges)
  Future<List<Map<String, dynamic>>> getChallenges({
    String? userId,
    String? challengeType,
    bool? isPublic,
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'active_only': activeOnly.toString(),
      };
      if (userId != null) queryParams['user_id'] = userId;
      if (challengeType != null) queryParams['challenge_type'] = challengeType;
      if (isPublic != null) queryParams['is_public'] = isPublic.toString();

      final response = await _apiClient.get(
        '/social/challenges',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Got challenges');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get challenges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting challenges: $e');
      rethrow;
    }
  }


  /// Create a new challenge
  Future<Map<String, dynamic>> createChallenge({
    required String userId,
    required String title,
    required String description,
    required String challengeType,
    required double goalValue,
    required String goalUnit,
    required DateTime startDate,
    required DateTime endDate,
    bool isPublic = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/challenges',
        queryParameters: {'user_id': userId},
        data: {
          'title': title,
          'description': description,
          'challenge_type': challengeType,
          'goal_value': goalValue,
          'goal_unit': goalUnit,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_public': isPublic,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Created challenge: $title');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error creating challenge: $e');
      rethrow;
    }
  }


  /// Get followers with cursor-based pagination
  Future<Map<String, dynamic>> getFollowers({
    required String userId,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _apiClient.get(
        '/social/connections/followers/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Got followers for user: $userId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get followers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting followers: $e');
      rethrow;
    }
  }


  /// Get following with cursor-based pagination
  Future<Map<String, dynamic>> getFollowing({
    required String userId,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _apiClient.get(
        '/social/connections/following/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Got following for user: $userId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get following: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting following: $e');
      rethrow;
    }
  }


  // ============================================================
  // USER SEARCH
  // ============================================================

  /// Search users by name (with pagination support)
  Future<Map<String, dynamic>> searchUsers({
    required String userId,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return {'results': <Map<String, dynamic>>[], 'total_count': 0, 'has_more': false};
    }

    debugPrint('🔍 [Social] Searching users: query="$query", userId=$userId, limit=$limit, offset=$offset');

    try {
      final response = await _apiClient.get(
        '/social/users/search',
        queryParameters: {
          'user_id': userId,
          'query': query,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      debugPrint('🔍 [Social] Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        // Support both old (List) and new (Map with results/total_count/has_more) response formats
        if (data is List) {
          final results = List<Map<String, dynamic>>.from(data);
          debugPrint('✅ [Social] Found ${results.length} users for query "$query"');
          return {
            'results': results,
            'total_count': results.length,
            'has_more': false,
          };
        } else if (data is Map) {
          debugPrint('✅ [Social] Found ${data['total_count'] ?? 0} users for query "$query"');
          return Map<String, dynamic>.from(data);
        }
        return {'results': <Map<String, dynamic>>[], 'total_count': 0, 'has_more': false};
      } else {
        debugPrint('❌ [Social] Search failed with status: ${response.statusCode}');
        debugPrint('❌ [Social] Response body: ${response.data}');
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error searching users: $e');
      rethrow;
    }
  }


  /// Get friend suggestions
  Future<List<Map<String, dynamic>>> getFriendSuggestions({
    required String userId,
    int limit = 10,
  }) async {
    debugPrint('🔍 [Social] Getting friend suggestions for user: $userId (limit: $limit)');
    try {
      final response = await _apiClient.get(
        '/social/users/suggestions',
        queryParameters: {
          'user_id': userId,
          'limit': limit.toString(),
        },
      );

      debugPrint('🔍 [Social] Suggestions response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final suggestions = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ [Social] Got ${suggestions.length} friend suggestions');
        return suggestions;
      } else {
        debugPrint('❌ [Social] Suggestions failed with status: ${response.statusCode}');
        throw Exception('Failed to get suggestions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting suggestions: $e');
      rethrow;
    }
  }


  // ============================================================
  // FRIEND REQUESTS
  // ============================================================

  /// Send a friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String userId,
    required String toUserId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/friend-requests',
        queryParameters: {'user_id': userId},
        data: {
          'to_user_id': toUserId,
          if (message != null) 'message': message,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Friend request sent to $toUserId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send friend request: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error sending friend request: $e');
      rethrow;
    }
  }


  /// Get received friend requests
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests({
    required String userId,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId,
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        '/social/friend-requests/received',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get friend requests: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting friend requests: $e');
      rethrow;
    }
  }


  /// Get sent friend requests
  Future<List<Map<String, dynamic>>> getSentFriendRequests({
    required String userId,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId,
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        '/social/friend-requests/sent',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get sent requests: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting sent requests: $e');
      rethrow;
    }
  }


  // ============================================================
  // SOCIAL NOTIFICATIONS
  // ============================================================

  /// Get social notifications
  Future<Map<String, dynamic>> getSocialNotifications({
    required String userId,
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/notifications',
        queryParameters: {
          'user_id': userId,
          'unread_only': unreadOnly.toString(),
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting notifications: $e');
      rethrow;
    }
  }


  // ============================================================
  // SOCIAL PRIVACY SETTINGS
  // ============================================================

  /// Get social privacy settings
  Future<Map<String, dynamic>> getSocialPrivacySettings({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/notifications/settings',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get social settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting social settings: $e');
      // Return defaults on error
      return {
        'notify_friend_requests': true,
        'notify_reactions': true,
        'notify_comments': true,
        'notify_challenge_invites': true,
        'notify_friend_activity': true,
        'require_follow_approval': false,
      };
    }
  }


  /// Update social privacy settings
  Future<Map<String, dynamic>> updateSocialPrivacySettings({
    required String userId,
    bool? notifyFriendRequests,
    bool? notifyReactions,
    bool? notifyComments,
    bool? notifyChallengeInvites,
    bool? notifyFriendActivity,
    bool? requireFollowApproval,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notifyFriendRequests != null) {
        data['notify_friend_requests'] = notifyFriendRequests;
      }
      if (notifyReactions != null) {
        data['notify_reactions'] = notifyReactions;
      }
      if (notifyComments != null) {
        data['notify_comments'] = notifyComments;
      }
      if (notifyChallengeInvites != null) {
        data['notify_challenge_invites'] = notifyChallengeInvites;
      }
      if (notifyFriendActivity != null) {
        data['notify_friend_activity'] = notifyFriendActivity;
      }
      if (requireFollowApproval != null) {
        data['require_follow_approval'] = requireFollowApproval;
      }

      final response = await _apiClient.put(
        '/social/notifications/settings',
        queryParameters: {'user_id': userId},
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Social settings updated');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update social settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error updating social settings: $e');
      rethrow;
    }
  }

}
