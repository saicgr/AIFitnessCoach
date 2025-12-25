import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

/// Challenge status enum
enum ChallengeStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  completed('completed'),
  expired('expired');

  final String value;
  const ChallengeStatus(this.value);
}

/// Service for workout challenges (friend-to-friend)
class ChallengesService {
  final ApiClient _apiClient;

  ChallengesService(this._apiClient);

  // ============================================================
  // SEND CHALLENGES
  // ============================================================

  /// Send workout challenge to specific friends
  Future<Map<String, dynamic>> sendChallenges({
    required String userId,
    required List<String> toUserIds,
    required String workoutName,
    required Map<String, dynamic> workoutData,
    String? workoutLogId,
    String? activityId,
    String? challengeMessage,
    bool isRetry = false,
    String? retriedFromChallengeId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/challenges/send',
        queryParameters: {'user_id': userId},
        data: {
          'to_user_ids': toUserIds,
          'workout_name': workoutName,
          'workout_data': workoutData,
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
          if (activityId != null) 'activity_id': activityId,
          if (challengeMessage != null) 'challenge_message': challengeMessage,
          'is_retry': isRetry,
          if (retriedFromChallengeId != null) 'retried_from_challenge_id': retriedFromChallengeId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Challenges] Sent ${toUserIds.length} challenges');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send challenges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error sending challenges: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET CHALLENGES
  // ============================================================

  /// Get challenges received by user
  Future<Map<String, dynamic>> getReceivedChallenges({
    required String userId,
    ChallengeStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (status != null) 'status': status.value,
      };

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/challenges/received',
        queryParameters: {'user_id': userId, ...queryParams},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get received challenges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error getting received challenges: $e');
      rethrow;
    }
  }

  /// Get challenges sent by user
  Future<Map<String, dynamic>> getSentChallenges({
    required String userId,
    ChallengeStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (status != null) 'status': status.value,
      };

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/challenges/sent',
        queryParameters: {'user_id': userId, ...queryParams},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get sent challenges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error getting sent challenges: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACCEPT / DECLINE CHALLENGES
  // ============================================================

  /// Accept a challenge
  Future<Map<String, dynamic>> acceptChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/challenges/accept/$challengeId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Challenges] Accepted challenge $challengeId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to accept challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error accepting challenge: $e');
      rethrow;
    }
  }

  /// Decline a challenge
  Future<void> declineChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/challenges/decline/$challengeId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Challenges] Declined challenge $challengeId');
      } else {
        throw Exception('Failed to decline challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error declining challenge: $e');
      rethrow;
    }
  }

  /// Complete a challenge with results
  Future<Map<String, dynamic>> completeChallenge({
    required String userId,
    required String challengeId,
    required String workoutLogId,
    required Map<String, dynamic> challengedStats,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/challenges/complete/$challengeId',
        queryParameters: {'user_id': userId},
        data: {
          'challenge_id': challengeId,
          'workout_log_id': workoutLogId,
          'challenged_stats': challengedStats,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Challenges] Completed challenge $challengeId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to complete challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error completing challenge: $e');
      rethrow;
    }
  }

  /// Abandon/quit a challenge midway through workout
  Future<Map<String, dynamic>> abandonChallenge({
    required String userId,
    required String challengeId,
    required String quitReason,
    Map<String, dynamic>? partialStats,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/challenges/abandon/$challengeId',
        queryParameters: {'user_id': userId},
        data: {
          'challenge_id': challengeId,
          'quit_reason': quitReason,
          if (partialStats != null) 'partial_stats': partialStats,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('🐔 [Challenges] Abandoned challenge $challengeId: $quitReason');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to abandon challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error abandoning challenge: $e');
      rethrow;
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  /// Get challenge notifications
  Future<Map<String, dynamic>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/challenges/notifications',
        queryParameters: {
          'user_id': userId,
          'unread_only': unreadOnly.toString(),
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error getting notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.baseUrl}/challenges/notifications/$notificationId/read',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Challenges] Marked notification as read');
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error marking notification as read: $e');
      rethrow;
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get challenge statistics for user
  Future<Map<String, dynamic>> getChallengeStats({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/challenges/stats/$userId',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get challenge stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Challenges] Error getting challenge stats: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get pending challenges count
  Future<int> getPendingChallengesCount({
    required String userId,
  }) async {
    try {
      final result = await getReceivedChallenges(
        userId: userId,
        status: ChallengeStatus.pending,
        pageSize: 1,
      );
      return result['total'] as int;
    } catch (e) {
      debugPrint('❌ [Challenges] Error getting pending count: $e');
      return 0;
    }
  }

  /// Quick challenge a single friend
  Future<void> quickChallengeFriend({
    required String userId,
    required String friendId,
    required String workoutName,
    required Map<String, dynamic> workoutData,
    String? workoutLogId,
    String? challengeMessage,
  }) async {
    await sendChallenges(
      userId: userId,
      toUserIds: [friendId],
      workoutName: workoutName,
      workoutData: workoutData,
      workoutLogId: workoutLogId,
      challengeMessage: challengeMessage,
    );
  }
}
