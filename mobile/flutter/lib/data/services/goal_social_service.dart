import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'personal_goals_service.dart';

/// Service for goal social features - friends, invites, joining goals
class GoalSocialService {
  final ApiClient _apiClient;

  GoalSocialService(this._apiClient);

  // ============================================================
  // GET GOAL FRIENDS (Leaderboard)
  // ============================================================

  /// Get friends who have the same goal this week (leaderboard)
  Future<GoalFriendsResponse> getGoalFriends({
    required String userId,
    required String goalId,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] Getting friends on goal: $goalId');

      final response = await _apiClient.get(
        '/goal-social/goals/$goalId/friends',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [GoalSocial] Found ${data['total_friends_count']} friends');
        return GoalFriendsResponse.fromJson(data);
      } else {
        throw Exception('Failed to get goal friends: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error getting goal friends: $e');
      rethrow;
    }
  }

  // ============================================================
  // JOIN GOAL
  // ============================================================

  /// Join a friend's goal by creating your own copy
  Future<Map<String, dynamic>> joinGoal({
    required String userId,
    required String goalId,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] Joining goal: $goalId');

      final response = await _apiClient.post(
        '/goal-social/goals/$goalId/join',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [GoalSocial] Successfully joined goal');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to join goal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error joining goal: $e');
      rethrow;
    }
  }

  // ============================================================
  // INVITE TO GOAL
  // ============================================================

  /// Invite a friend to join your goal
  Future<GoalInvite> inviteToGoal({
    required String userId,
    required String goalId,
    required String inviteeId,
    String? message,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] Inviting $inviteeId to goal: $goalId');

      final response = await _apiClient.post(
        '/goal-social/goals/$goalId/invite',
        queryParameters: {'user_id': userId},
        data: {
          'goal_id': goalId,
          'invitee_id': inviteeId,
          if (message != null) 'message': message,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [GoalSocial] Invite sent successfully');
        return GoalInvite.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to send invite: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error sending invite: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET INVITES
  // ============================================================

  /// Get pending goal invites for the user
  Future<List<GoalInviteWithDetails>> getGoalInvites({
    required String userId,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] Getting goal invites for: $userId');

      final response = await _apiClient.get(
        '/goal-social/goals/invites',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        debugPrint('✅ [GoalSocial] Found ${data.length} invites');
        return data
            .map((e) => GoalInviteWithDetails.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get invites: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error getting invites: $e');
      rethrow;
    }
  }

  // ============================================================
  // RESPOND TO INVITE
  // ============================================================

  /// Accept or decline a goal invite
  Future<GoalInviteResponse> respondToInvite({
    required String userId,
    required String inviteId,
    required bool accept,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] ${accept ? "Accepting" : "Declining"} invite: $inviteId');

      final response = await _apiClient.post(
        '/goal-social/goals/invites/$inviteId/respond',
        queryParameters: {'user_id': userId},
        data: {'accept': accept},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [GoalSocial] Invite response sent');
        return GoalInviteResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to respond to invite: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error responding to invite: $e');
      rethrow;
    }
  }

  // ============================================================
  // CANCEL INVITE
  // ============================================================

  /// Cancel a sent invite (as inviter)
  Future<void> cancelInvite({
    required String userId,
    required String inviteId,
  }) async {
    try {
      debugPrint('🎯 [GoalSocial] Cancelling invite: $inviteId');

      final response = await _apiClient.delete(
        '/goal-social/goals/invites/$inviteId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [GoalSocial] Invite cancelled');
      } else {
        throw Exception('Failed to cancel invite: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error cancelling invite: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET PENDING COUNT
  // ============================================================

  /// Get count of pending invites (for badge)
  Future<int> getPendingInvitesCount({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/goal-social/goals/invites/pending-count',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['pending_count'] as int;
      } else {
        throw Exception('Failed to get pending count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GoalSocial] Error getting pending count: $e');
      rethrow;
    }
  }
}

// ============================================================
// GOAL SOCIAL MODELS
// ============================================================

/// Invite status enum
enum InviteStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired');

  final String value;
  const InviteStatus(this.value);

  static InviteStatus fromString(String value) {
    return InviteStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InviteStatus.pending,
    );
  }
}

/// Friend's progress on a goal
class FriendGoalProgress {
  final String oderId;
  final String name;
  final String? avatarUrl;
  final int currentValue;
  final int targetValue;
  final double progressPercentage;
  final bool isPrBeaten;
  final int rank;

  FriendGoalProgress({
    required this.oderId,
    required this.name,
    this.avatarUrl,
    required this.currentValue,
    required this.targetValue,
    required this.progressPercentage,
    this.isPrBeaten = false,
    this.rank = 0,
  });

  factory FriendGoalProgress.fromJson(Map<String, dynamic> json) {
    return FriendGoalProgress(
      oderId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      currentValue: json['current_value'] as int,
      targetValue: json['target_value'] as int,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      isPrBeaten: json['is_pr_beaten'] as bool? ?? false,
      rank: json['rank'] as int? ?? 0,
    );
  }
}

/// Response with friends on a goal
class GoalFriendsResponse {
  final String goalId;
  final String exerciseName;
  final PersonalGoalType goalType;
  final DateTime weekStart;
  final List<FriendGoalProgress> friendEntries;
  final int totalFriendsCount;
  final int userRank;
  final double userProgressPercentage;

  GoalFriendsResponse({
    required this.goalId,
    required this.exerciseName,
    required this.goalType,
    required this.weekStart,
    required this.friendEntries,
    required this.totalFriendsCount,
    this.userRank = 0,
    this.userProgressPercentage = 0,
  });

  factory GoalFriendsResponse.fromJson(Map<String, dynamic> json) {
    return GoalFriendsResponse(
      goalId: json['goal_id'] as String,
      exerciseName: json['exercise_name'] as String,
      goalType: PersonalGoalType.fromString(json['goal_type'] as String),
      weekStart: DateTime.parse(json['week_start'] as String),
      friendEntries: (json['friend_entries'] as List<dynamic>)
          .map((e) => FriendGoalProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalFriendsCount: json['total_friends_count'] as int,
      userRank: json['user_rank'] as int? ?? 0,
      userProgressPercentage: (json['user_progress_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get hasFriends => totalFriendsCount > 0;
}

/// Basic goal invite
class GoalInvite {
  final String id;
  final String goalId;
  final String inviterId;
  final String inviteeId;
  final InviteStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;

  GoalInvite({
    required this.id,
    required this.goalId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
  });

  factory GoalInvite.fromJson(Map<String, dynamic> json) {
    return GoalInvite(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: InviteStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  bool get isPending => status == InviteStatus.pending;
  bool get isExpiringSoon {
    final hoursLeft = expiresAt.difference(DateTime.now()).inHours;
    return hoursLeft <= 24 && hoursLeft > 0;
  }
}

/// Goal invite with expanded details
class GoalInviteWithDetails extends GoalInvite {
  final String goalExerciseName;
  final PersonalGoalType goalGoalType;
  final int goalTargetValue;
  final String inviterName;
  final String? inviterAvatarUrl;
  final int inviterCurrentValue;
  final double inviterProgressPercentage;

  GoalInviteWithDetails({
    required super.id,
    required super.goalId,
    required super.inviterId,
    required super.inviteeId,
    required super.status,
    super.message,
    required super.createdAt,
    super.respondedAt,
    required super.expiresAt,
    required this.goalExerciseName,
    required this.goalGoalType,
    required this.goalTargetValue,
    required this.inviterName,
    this.inviterAvatarUrl,
    this.inviterCurrentValue = 0,
    this.inviterProgressPercentage = 0,
  });

  factory GoalInviteWithDetails.fromJson(Map<String, dynamic> json) {
    return GoalInviteWithDetails(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: InviteStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      goalExerciseName: json['goal_exercise_name'] as String,
      goalGoalType: PersonalGoalType.fromString(json['goal_type'] as String),
      goalTargetValue: json['goal_target_value'] as int,
      inviterName: json['inviter_name'] as String,
      inviterAvatarUrl: json['inviter_avatar_url'] as String?,
      inviterCurrentValue: json['inviter_current_value'] as int? ?? 0,
      inviterProgressPercentage:
          (json['inviter_progress_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Response after responding to invite
class GoalInviteResponse {
  final GoalInvite invite;
  final String? createdGoalId;

  GoalInviteResponse({
    required this.invite,
    this.createdGoalId,
  });

  factory GoalInviteResponse.fromJson(Map<String, dynamic> json) {
    return GoalInviteResponse(
      invite: GoalInvite.fromJson(json['invite'] as Map<String, dynamic>),
      createdGoalId: json['created_goal_id'] as String?,
    );
  }

  bool get wasAccepted => invite.status == InviteStatus.accepted;
}
