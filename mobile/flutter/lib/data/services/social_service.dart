import 'package:flutter/foundation.dart';
import 'api_client.dart';

part 'social_service_part_social_activity_type.dart';

// Methods from social_service_ui_1.dart and social_service_ui_2.dart
// have been inlined into SocialService class below.


/// Social service for activity feed, reactions, comments, challenges
class SocialService {
  final ApiClient _apiClient;

  SocialService(this._apiClient);

  /// Delete an activity post
  Future<void> deleteActivity({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/feed/$activityId',
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

  /// Remove reaction from an activity
  Future<void> removeReaction({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/reactions/$activityId',
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
        '/social/reactions/$activityId',
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

  /// Delete a comment
  Future<void> deleteComment({
    required String userId,
    required String commentId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/comments/$commentId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Comment deleted: $commentId');
      } else {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error deleting comment: $e');
      rethrow;
    }
  }

  /// Join a challenge
  Future<Map<String, dynamic>> joinChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/challenges/participate',
        queryParameters: {'user_id': userId},
        data: {
          'challenge_id': challengeId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Joined challenge: $challengeId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to join challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error joining challenge: $e');
      rethrow;
    }
  }

  /// Update challenge progress
  Future<Map<String, dynamic>> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required double currentValue,
  }) async {
    try {
      final response = await _apiClient.put(
        '/social/challenges/participate/$challengeId',
        queryParameters: {'user_id': userId},
        data: {
          'current_value': currentValue,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Updated challenge progress');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update challenge progress: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error updating challenge progress: $e');
      rethrow;
    }
  }

  /// Get challenge leaderboard
  Future<Map<String, dynamic>> getChallengeLeaderboard({
    required String challengeId,
    String? userId,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _apiClient.get(
        '/social/challenges/$challengeId/leaderboard',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get challenge leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting challenge leaderboard: $e');
      rethrow;
    }
  }

  // ============================================================
  // CONNECTIONS (Friends, Followers, Following)
  // ============================================================

  /// Get friends (mutual connections)
  Future<List<Map<String, dynamic>>> getFriends({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/connections/friends/$userId',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Got friends for user: $userId');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get friends: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting friends: $e');
      rethrow;
    }
  }

  /// Follow a user
  Future<Map<String, dynamic>> followUser({
    required String userId,
    required String followingId,
    String connectionType = 'follow',
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/connections',
        queryParameters: {'user_id': userId},
        data: {
          'following_id': followingId,
          'connection_type': connectionType,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Followed user: $followingId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to follow user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String userId,
    required String followingId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/connections/$followingId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Unfollowed user: $followingId');
      } else {
        throw Exception('Failed to unfollow user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>> getUserProfile({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/users/$targetUserId/profile',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting user profile: $e');
      rethrow;
    }
  }

  /// Get pending friend request count
  Future<int> getPendingFriendRequestCount({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/friend-requests/pending-count',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return (response.data['count'] as num).toInt();
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [Social] Error getting pending count: $e');
      return 0;
    }
  }

  /// Accept a friend request
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String userId,
    required String requestId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/friend-requests/$requestId/accept',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Friend request accepted');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to accept friend request: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest({
    required String userId,
    required String requestId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/friend-requests/$requestId/decline',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Friend request declined');
      } else {
        throw Exception('Failed to decline friend request: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error declining friend request: $e');
      rethrow;
    }
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest({
    required String userId,
    required String requestId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/friend-requests/$requestId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Friend request cancelled');
      } else {
        throw Exception('Failed to cancel friend request: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error cancelling friend request: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/notifications/unread-count',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return (response.data['count'] as num).toInt();
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [Social] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _apiClient.put(
        '/social/notifications/$notificationId/read',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Social] Notification marked as read');
    } catch (e) {
      debugPrint('❌ [Social] Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead({
    required String userId,
  }) async {
    try {
      await _apiClient.put(
        '/social/notifications/read-all',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Social] All notifications marked as read');
    } catch (e) {
      debugPrint('❌ [Social] Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _apiClient.delete(
        '/social/notifications/$notificationId',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Social] Notification deleted');
    } catch (e) {
      debugPrint('❌ [Social] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications({
    required String userId,
  }) async {
    try {
      await _apiClient.delete(
        '/social/notifications/clear-all',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Social] All notifications cleared');
    } catch (e) {
      debugPrint('❌ [Social] Error clearing notifications: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST PINNING (Admin Only)
  // ============================================================

  /// Pin a post to the top of the feed (admin only)
  Future<void> pinPost({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/feed/$activityId/pin',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Post pinned: $activityId');
      } else {
        throw Exception('Failed to pin post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error pinning post: $e');
      rethrow;
    }
  }

  /// Unpin a post from the top of the feed (admin only)
  Future<void> unpinPost({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/feed/$activityId/pin',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Post unpinned: $activityId');
      } else {
        throw Exception('Failed to unpin post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error unpinning post: $e');
      rethrow;
    }
  }

  /// Get social summary for a user (workout stats, mutual friends, etc.)
  Future<Map<String, dynamic>> getSocialSummary({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/social/users/$targetUserId/summary',
        queryParameters: {'user_id': userId},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('❌ [Social] Error getting social summary: $e');
      return {};
    }
  }

  // ============================================================
  // BLOCKING & REPORTING (F9)
  // ============================================================

  /// Block a user
  Future<void> blockUser(String userId, {String? reason}) async {
    try {
      await _apiClient.post(
        '/social/blocks',
        data: {
          'blocked_id': userId,
          if (reason != null) 'reason': reason,
        },
      );
      debugPrint('✅ [Social] User blocked: $userId');
    } catch (e) {
      debugPrint('❌ [Social] Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      await _apiClient.delete('/social/blocks/$userId');
      debugPrint('✅ [Social] User unblocked: $userId');
    } catch (e) {
      debugPrint('❌ [Social] Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final response = await _apiClient.get('/social/blocks');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Social] Error getting blocked users: $e');
      rethrow;
    }
  }

  /// Report content (post, comment, user, message)
  Future<void> reportContent({
    required String contentType,
    required String contentId,
    String? reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiClient.post(
        '/social/reports',
        data: {
          'content_type': contentType,
          'content_id': contentId,
          if (reportedUserId != null) 'reported_user_id': reportedUserId,
          'reason': reason,
          if (description != null) 'description': description,
        },
      );
      debugPrint('✅ [Social] Content reported: $contentType/$contentId');
    } catch (e) {
      debugPrint('❌ [Social] Error reporting content: $e');
      rethrow;
    }
  }

  // ============================================================
  // HASHTAGS (F10)
  // ============================================================

  /// Get trending hashtags
  Future<List<Map<String, dynamic>>> getTrendingHashtags({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/social/hashtags/trending',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Social] Error getting trending hashtags: $e');
      rethrow;
    }
  }

  /// Get posts by hashtag
  Future<Map<String, dynamic>> getPostsByHashtag(
    String name, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/hashtags/$name/posts',
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'posts': [], 'total_count': 0};
    } catch (e) {
      debugPrint('❌ [Social] Error getting posts by hashtag: $e');
      rethrow;
    }
  }

  /// Search hashtags
  Future<List<Map<String, dynamic>>> searchHashtags(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/hashtags/search',
        queryParameters: {
          'q': query,
          'limit': limit.toString(),
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Social] Error searching hashtags: $e');
      rethrow;
    }
  }

  // ============================================================
  // STORIES (F11)
  // ============================================================

  /// Get pre-signed URL for story media upload
  Future<Map<String, dynamic>> getStoryPresignedUrl(
    String fileName,
    String contentType,
  ) async {
    try {
      final response = await _apiClient.post(
        '/social/stories/presign',
        data: {
          'file_name': fileName,
          'content_type': contentType,
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to get story presigned URL: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Social] Error getting story presigned URL: $e');
      rethrow;
    }
  }

  /// Create a new story
  Future<Map<String, dynamic>> createStory({
    required String mediaUrl,
    String mediaType = 'image',
    String? storageKey,
    String? caption,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/stories',
        data: {
          'media_url': mediaUrl,
          'media_type': mediaType,
          if (storageKey != null) 'storage_key': storageKey,
          if (caption != null) 'caption': caption,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Story created');
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to create story: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Social] Error creating story: $e');
      rethrow;
    }
  }

  /// Get stories feed (stories from friends)
  Future<List<Map<String, dynamic>>> getStoriesFeed() async {
    try {
      final response = await _apiClient.get('/social/stories/feed');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Social] Error getting stories feed: $e');
      rethrow;
    }
  }

  /// Get views for a story
  Future<List<Map<String, dynamic>>> getStoryViews(String storyId) async {
    try {
      final response = await _apiClient.get('/social/stories/$storyId/views');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Social] Error getting story views: $e');
      rethrow;
    }
  }

  /// Mark a story as viewed
  Future<void> markStoryViewed(String storyId) async {
    try {
      await _apiClient.post('/social/stories/$storyId/view');
      debugPrint('✅ [Social] Story marked as viewed: $storyId');
    } catch (e) {
      debugPrint('❌ [Social] Error marking story viewed: $e');
      rethrow;
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      await _apiClient.delete('/social/stories/$storyId');
      debugPrint('✅ [Social] Story deleted: $storyId');
    } catch (e) {
      debugPrint('❌ [Social] Error deleting story: $e');
      rethrow;
    }
  }

  // ============================================================
  // GROUP CHATS (F12)
  // ============================================================

  /// Create a group conversation
  Future<Map<String, dynamic>> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/messages/conversations/group',
        data: {
          'name': name,
          'member_ids': memberIds,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Group conversation created: $name');
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to create group conversation: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Social] Error creating group conversation: $e');
      rethrow;
    }
  }

  /// Update group members (add or remove)
  Future<void> updateGroupMembers(
    String conversationId, {
    List<String>? addIds,
    List<String>? removeIds,
  }) async {
    try {
      await _apiClient.put(
        '/social/messages/conversations/$conversationId/members',
        data: {
          if (addIds != null) 'add_ids': addIds,
          if (removeIds != null) 'remove_ids': removeIds,
        },
      );
      debugPrint('✅ [Social] Group members updated: $conversationId');
    } catch (e) {
      debugPrint('❌ [Social] Error updating group members: $e');
      rethrow;
    }
  }

  /// Update group settings (name, avatar)
  Future<void> updateGroupSettings(
    String conversationId, {
    String? name,
    String? avatarUrl,
  }) async {
    try {
      await _apiClient.put(
        '/social/messages/conversations/$conversationId/settings',
        data: {
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );
      debugPrint('✅ [Social] Group settings updated: $conversationId');
    } catch (e) {
      debugPrint('❌ [Social] Error updating group settings: $e');
      rethrow;
    }
  }

  /// Leave a group conversation
  Future<void> leaveGroup(String conversationId) async {
    try {
      await _apiClient.post(
        '/social/messages/conversations/$conversationId/leave',
      );
      debugPrint('✅ [Social] Left group: $conversationId');
    } catch (e) {
      debugPrint('❌ [Social] Error leaving group: $e');
      rethrow;
    }
  }

  // ============================================================
  // SOCIAL STATS (F7)
  // ============================================================

  /// Get social stats for the current user (friends count, followers, following)
  Future<Map<String, dynamic>> getSocialStats({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/users/$userId/stats',
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'friends_count': 0, 'followers_count': 0, 'following_count': 0};
    } catch (e) {
      debugPrint('❌ [Social] Error getting social stats: $e');
      return {'friends_count': 0, 'followers_count': 0, 'following_count': 0};
    }
  }

  /// Get or create a direct message conversation with another user
  Future<Map<String, dynamic>> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/social/conversations',
        data: {
          'user_id': userId,
          'other_user_id': otherUserId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get/create conversation: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Social] Error getting/creating conversation: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACTIVITY FEED (from social_service_ui_1.dart)
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
    required String reactionType,
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
          return settings['show_achievements'] ?? true;
        case SocialActivityType.manualPost:
          return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Social] Error checking privacy, defaulting to allow: $e');
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
    final milestones = [7, 14, 30, 60, 90, 100, 180, 365];
    if (!milestones.contains(streakDays)) {
      return;
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

  // ============================================================
  // DIRECT MESSAGES (from social_service_ui_2.dart)
  // ============================================================

  /// Get list of conversations for user
  Future<List<Map<String, dynamic>>> getConversations({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/messages/conversations',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> conversations = [];

        if (data is Map && data['conversations'] != null) {
          conversations = data['conversations'] as List<dynamic>;
        } else if (data is List) {
          conversations = data;
        }

        return conversations.map<Map<String, dynamic>>((conv) {
          final participants = conv['participants'] as List<dynamic>? ?? [];
          Map<String, dynamic>? otherUser;
          for (final p in participants) {
            if (p['user_id'] != userId) {
              otherUser = p as Map<String, dynamic>;
              break;
            }
          }

          final lastMessage = conv['last_message'] as Map<String, dynamic>?;

          return {
            'id': conv['id'],
            'other_user_id': otherUser?['user_id'],
            'other_user_name': otherUser?['user_name'] ?? 'User',
            'other_user_avatar': otherUser?['user_avatar'],
            'is_support_user': otherUser?['is_support_user'] ?? false,
            'last_message': (lastMessage?['encryption_version'] ?? 0) > 0
                ? 'Encrypted message'
                : (lastMessage?['content'] ?? ''),
            'last_message_encryption_version': lastMessage?['encryption_version'] ?? 0,
            'last_message_time': conv['last_message_at'] ?? lastMessage?['created_at'],
            'unread_count': conv['unread_count'] ?? 0,
          };
        }).toList();
      } else {
        throw Exception('Failed to get conversations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting conversations: $e');
      rethrow;
    }
  }

  /// Get messages in a conversation
  Future<List<Map<String, dynamic>>> getMessages({
    required String userId,
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/messages/conversations/$conversationId',
        queryParameters: {
          'user_id': userId,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting messages: $e');
      rethrow;
    }
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String recipientId,
    String? content,
    String? conversationId,
    String? encryptedContent,
    String? encryptionNonce,
    int? encryptionVersion,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/messages/send',
        queryParameters: {'user_id': userId},
        data: {
          'recipient_id': recipientId,
          if (content != null) 'content': content,
          if (conversationId != null) 'conversation_id': conversationId,
          if (encryptedContent != null) 'encrypted_content': encryptedContent,
          if (encryptionNonce != null) 'encryption_nonce': encryptionNonce,
          if (encryptionVersion != null) 'encryption_version': encryptionVersion,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Message sent');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error sending message: $e');
      rethrow;
    }
  }
}
