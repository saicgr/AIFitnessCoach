import 'package:flutter/foundation.dart';
import '../models/user_xp.dart';
import '../models/trophy.dart';
import '../models/xp_event.dart';
import '../services/api_client.dart';

/// Repository for XP and trophy operations
class XPRepository {
  final ApiClient _client;

  XPRepository(this._client);

  // =========================================================================
  // User XP
  // =========================================================================

  /// Get user's XP data
  Future<UserXP> getUserXP(String userId) async {
    try {
      final response = await _client.get('/progress/xp/$userId');
      return UserXP.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      // Return empty XP on error
      return UserXP.empty(userId);
    }
  }

  /// Get XP summary with rank
  Future<XPSummary> getXPSummary(String userId) async {
    try {
      final response = await _client.get('/progress/xp/$userId/summary');
      return XPSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting XP summary: $e');
      rethrow;
    }
  }

  /// Get XP transactions history
  Future<List<XPTransaction>> getXPTransactions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        '/progress/xp/$userId/transactions',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as List;
      return data.map((json) => XPTransaction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting XP transactions: $e');
      return [];
    }
  }

  /// Get XP leaderboard
  Future<List<XPLeaderboardEntry>> getXPLeaderboard({int limit = 100}) async {
    try {
      final response = await _client.get(
        '/progress/xp/leaderboard',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => XPLeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting XP leaderboard: $e');
      return [];
    }
  }

  // =========================================================================
  // Trophies
  // =========================================================================

  /// Get all trophies with progress for user
  Future<List<TrophyProgress>> getTrophyProgress(
    String userId, {
    TrophyCategory? category,
    String? filter, // 'all', 'earned', 'locked', 'in_progress'
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category.name;
      }
      if (filter != null) {
        queryParams['filter'] = filter;
      }

      final response = await _client.get(
        '/progress/trophies/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => TrophyProgress.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting trophy progress: $e');
      return [];
    }
  }

  /// Get trophy room summary
  Future<TrophyRoomSummary> getTrophyRoomSummary(String userId) async {
    try {
      final response = await _client.get('/progress/trophies/$userId/summary');
      return TrophyRoomSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting trophy summary: $e');
      return const TrophyRoomSummary();
    }
  }

  /// Get earned trophies
  Future<List<UserTrophy>> getEarnedTrophies(String userId) async {
    try {
      final response = await _client.get('/progress/trophies/$userId/earned');
      final data = response.data as List;
      return data.map((json) => UserTrophy.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting earned trophies: $e');
      return [];
    }
  }

  /// Get recently earned trophies (for celebration)
  Future<List<UserTrophy>> getRecentTrophies(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final response = await _client.get(
        '/progress/trophies/$userId/recent',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => UserTrophy.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recent trophies: $e');
      return [];
    }
  }

  // =========================================================================
  // World Records
  // =========================================================================

  /// Get all world records
  Future<List<WorldRecord>> getWorldRecords({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _client.get(
        '/progress/world-records',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => WorldRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting world records: $e');
      return [];
    }
  }

  /// Get user's world records (if any)
  Future<List<WorldRecord>> getUserWorldRecords(String userId) async {
    try {
      final response = await _client.get('/progress/world-records/user/$userId');
      final data = response.data as List;
      return data.map((json) => WorldRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user world records: $e');
      return [];
    }
  }

  /// Get former champion badges
  Future<List<FormerChampion>> getFormerChampions(String userId) async {
    try {
      final response =
          await _client.get('/progress/world-records/former-champion/$userId');
      final data = response.data as List;
      return data.map((json) => FormerChampion.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting former champions: $e');
      return [];
    }
  }

  /// Attempt to set a world record
  Future<Map<String, dynamic>?> attemptWorldRecord(
    String userId,
    String recordType,
    double value, {
    String? exerciseId,
    String? workoutId,
  }) async {
    try {
      final response = await _client.post(
        '/progress/world-records/attempt',
        data: {
          'user_id': userId,
          'record_type': recordType,
          'value': value,
          if (exerciseId != null) 'exercise_id': exerciseId,
          if (workoutId != null) 'workout_id': workoutId,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Error attempting world record: $e');
      return null;
    }
  }

  // =========================================================================
  // Rewards
  // =========================================================================

  /// Get available rewards for user
  Future<List<Map<String, dynamic>>> getAvailableRewards(String userId) async {
    try {
      final response = await _client.get('/progress/rewards/$userId/available');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('Error getting available rewards: $e');
      return [];
    }
  }

  /// Claim a reward
  Future<bool> claimReward(String userId, String rewardId, {String? email}) async {
    try {
      await _client.post(
        '/progress/rewards/$userId/claim',
        data: {
          'reward_id': rewardId,
          if (email != null) 'delivery_email': email,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      return false;
    }
  }

  /// Get claimed rewards history
  Future<List<Map<String, dynamic>>> getClaimedRewards(String userId) async {
    try {
      final response = await _client.get('/progress/rewards/$userId/claimed');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('Error getting claimed rewards: $e');
      return [];
    }
  }

  // =========================================================================
  // Daily Login & XP Events
  // =========================================================================

  /// Process daily login and get XP bonuses
  Future<DailyLoginResult?> processDailyLogin() async {
    try {
      final response = await _client.post('/xp/daily-login');
      return DailyLoginResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error processing daily login: $e');
      return null;
    }
  }

  /// Get user's login streak info
  Future<LoginStreakInfo> getLoginStreak() async {
    try {
      final response = await _client.get('/xp/login-streak');
      return LoginStreakInfo.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting login streak: $e');
      return LoginStreakInfo.empty();
    }
  }

  /// Get all currently active XP events (Double XP, etc.)
  Future<List<XPEvent>> getActiveXPEvents() async {
    try {
      final response = await _client.get('/xp/active-events');
      final data = response.data as List;
      return data.map((json) => XPEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting active XP events: $e');
      return [];
    }
  }

  /// Award XP for completing a daily goal
  /// Returns the XP awarded (0 if already claimed today)
  Future<int> awardGoalXP(String goalType, {String? sourceId}) async {
    try {
      final response = await _client.post('/xp/award-goal-xp', data: {
        'goal_type': goalType,
        if (sourceId != null) 'source_id': sourceId,
      });
      final data = response.data as Map<String, dynamic>;
      final xpAwarded = data['xp_awarded'] as int? ?? 0;
      final alreadyClaimed = data['already_claimed'] as bool? ?? false;
      if (alreadyClaimed) {
        debugPrint('[XP] Goal $goalType already claimed today');
      } else if (xpAwarded > 0) {
        debugPrint('[XP] Awarded $xpAwarded XP for $goalType');
      }
      return xpAwarded;
    } catch (e) {
      debugPrint('Error awarding goal XP: $e');
      return 0;
    }
  }

  /// Get all XP bonus templates
  Future<List<XPBonusTemplate>> getBonusTemplates() async {
    try {
      final response = await _client.get('/xp/bonus-templates');
      final data = response.data as List;
      return data.map((json) => XPBonusTemplate.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting bonus templates: $e');
      return [];
    }
  }

  /// Get weekly or monthly checkpoint progress
  Future<CheckpointProgress> getCheckpointProgress(String type) async {
    try {
      final response = await _client.get(
        '/xp/checkpoint-progress',
        queryParameters: {'checkpoint_type': type},
      );
      return CheckpointProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting checkpoint progress: $e');
      return CheckpointProgress.empty(type);
    }
  }
}
