import 'package:flutter/foundation.dart';
import 'api_client.dart';

part 'social_service_part_social_activity_type.dart';

part 'social_service_ui_1.dart';
part 'social_service_ui_2.dart';


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
}
