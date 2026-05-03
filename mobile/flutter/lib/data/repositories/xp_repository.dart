import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_xp.dart';
import '../models/trophy.dart';
import '../models/xp_event.dart';
import '../../core/services/sentry_service.dart';
import '../../utils/tz.dart';
import '../services/api_client.dart';

part 'xp_repository_part_daily_goals_status.dart';


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

  /// Get available rewards for user.
  ///
  /// Previously swallowed all errors (including 404s for the endpoint not
  /// existing) and returned `[]`, which is exactly what hid the missing
  /// backend route for months. Now rethrows and surfaces to Sentry so we
  /// see regressions immediately — per feedback_no_silent_fallbacks.md.
  Future<List<Map<String, dynamic>>> getAvailableRewards(String userId) async {
    try {
      final response = await _client.get('/progress/rewards/$userId/available');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stack) {
      debugPrint('Error getting available rewards: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'GET /progress/rewards/$userId/available failed',
        tags: {'subsystem': 'rewards', 'stage': 'fetch_available'},
      ));
      rethrow;
    }
  }

  /// Claim a reward. Response varies by reward kind:
  ///   - daily_crate: `{success, reward_type, crate_type, reward: {type, amount}}`
  ///   - consumable:  `{success, reward_type, message, level_reached, items}`
  ///   - merch:       `{success, reward_type: "merch", redirect: "merch_address", claim_id}`
  /// The screen branches on `response['reward_type']` / `response['redirect']`.
  Future<Map<String, dynamic>?> claimReward(String userId, String rewardId, {String? email}) async {
    try {
      final response = await _client.post(
        '/progress/rewards/$userId/claim',
        data: {
          'reward_id': rewardId,
          if (email != null) 'delivery_email': email,
        },
      );
      final data = response.data;
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e, stack) {
      debugPrint('Error claiming reward: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'POST /progress/rewards/$userId/claim failed',
        tags: {'subsystem': 'rewards', 'stage': 'claim', 'reward_id': rewardId},
      ));
      return null;
    }
  }

  /// Get claimed rewards history. Same silent-swallow → rethrow treatment
  /// as getAvailableRewards.
  Future<List<Map<String, dynamic>>> getClaimedRewards(String userId) async {
    try {
      final response = await _client.get('/progress/rewards/$userId/claimed');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stack) {
      debugPrint('Error getting claimed rewards: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'GET /progress/rewards/$userId/claimed failed',
        tags: {'subsystem': 'rewards', 'stage': 'fetch_claimed'},
      ));
      rethrow;
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

  /// Award XP for logging body measurements (20 XP, once per day)
  Future<int> awardBodyMeasurementsXP() async {
    return awardGoalXP('body_measurements');
  }

  // =========================================================================
  // First-Time Bonuses
  // =========================================================================

  /// Award XP for a first-time action
  /// Returns the XP awarded (0 if already claimed)
  Future<FirstTimeBonusResult> awardFirstTimeBonus(String bonusType) async {
    try {
      final response = await _client.post('/xp/award-first-time-bonus', data: {
        'bonus_type': bonusType,
      });
      final data = response.data as Map<String, dynamic>;
      return FirstTimeBonusResult(
        awarded: data['awarded'] as bool? ?? false,
        xp: data['xp'] as int? ?? 0,
        bonusType: data['bonus_type'] as String? ?? bonusType,
        message: data['message'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Error awarding first-time bonus: $e');
      return FirstTimeBonusResult(
        awarded: false,
        xp: 0,
        bonusType: bonusType,
        message: 'Error awarding bonus',
      );
    }
  }

  /// Get all first-time bonuses that have been awarded to the user
  Future<List<FirstTimeBonusInfo>> getAwardedFirstTimeBonuses() async {
    try {
      final response = await _client.get('/xp/first-time-bonuses');
      final data = response.data as List;
      return data.map((json) => FirstTimeBonusInfo.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting first-time bonuses: $e');
      return [];
    }
  }

  /// Get all available first-time bonuses with their status
  Future<List<AvailableBonus>> getAvailableFirstTimeBonuses() async {
    try {
      final response = await _client.get('/xp/available-first-time-bonuses');
      final bonuses = response.data['bonuses'] as List;
      return bonuses.map((json) => AvailableBonus.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting available first-time bonuses: $e');
      return [];
    }
  }

  // =========================================================================
  // Consumables System
  // =========================================================================

  /// Get user's consumable inventory
  Future<UserConsumables> getConsumables() async {
    try {
      final response = await _client.get('/xp/consumables');
      return UserConsumables.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting consumables: $e');
      return const UserConsumables();
    }
  }

  /// Use a consumable item
  Future<UseConsumableResult> useConsumable(String itemType) async {
    try {
      final response = await _client.post('/xp/use-consumable', data: {
        'item_type': itemType,
      });
      return UseConsumableResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error using consumable: $e');
      return UseConsumableResult(
        success: false,
        itemType: itemType,
        message: 'Error using consumable',
      );
    }
  }

  /// Activate 2x XP token (24 hour boost)
  Future<UseConsumableResult> activate2xXPToken() async {
    return useConsumable('xp_token_2x');
  }

  /// Open a crate and get reward
  Future<CrateRewardResult> openCrate(String crateType) async {
    try {
      final response = await _client.post('/xp/open-crate', data: {
        'crate_type': crateType,
      });
      return CrateRewardResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error opening crate: $e');
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Error opening crate',
      );
    }
  }

  // =========================================================================
  // Daily Crate System
  // =========================================================================

  /// Get today's daily crate availability and status
  Future<DailyCratesState> getDailyCrates() async {
    try {
      final response = await _client.get('/xp/daily-crates',
        queryParameters: {'date': Tz.localDate()},
      );
      return DailyCratesState.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily crates: $e');
      return DailyCratesState.empty();
    }
  }

  /// Claim a daily crate (pick 1 of 3 available).
  /// [crateDate] is optional — pass an ISO date string (e.g. '2026-04-05')
  /// to claim a past unclaimed crate.
  Future<CrateRewardResult> claimDailyCrate(String crateType, {String? crateDate}) async {
    final data = <String, dynamic>{'crate_type': crateType};
    if (crateDate != null) data['crate_date'] = crateDate;
    debugPrint('🔍 [Crate] POST /xp/claim-daily-crate body=$data');
    try {
      final response = await _client.post('/xp/claim-daily-crate', data: data);
      debugPrint('✅ [Crate] Claim response: ${response.statusCode} body=${response.data}');
      return CrateRewardResult.fromJson(response.data);
    } on DioException catch (e, stack) {
      // Dio error — preserve the HTTP status + server message so the UI can
      // display the actual reason (NOT a generic "Failed to claim crate").
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final serverDetail = (body is Map ? body['detail'] ?? body['message'] : null)?.toString();
      final detailMsg = serverDetail ?? e.message ?? e.type.toString();
      final userMsg = status != null
          ? 'Claim failed (HTTP $status): $detailMsg'
          : 'Claim failed: $detailMsg';

      debugPrint('❌ [Crate] DioException claiming daily crate '
          '(status=$status, type=${e.type}): $detailMsg');
      debugPrint('❌ [Crate] Response body: $body');
      debugPrint('❌ [Crate] Request: ${e.requestOptions.method} ${e.requestOptions.uri} '
          'data=${e.requestOptions.data}');
      debugPrint('❌ [Crate] Stack:\n$stack');

      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Claim daily crate failed',
        tags: {
          'feature': 'daily_crate',
          'op': 'claim',
          if (status != null) 'http_status': status.toString(),
          'dio_type': e.type.toString(),
        },
        extra: {
          'crate_type': crateType,
          'crate_date': crateDate ?? 'default(today)',
          'response_body': body?.toString() ?? '',
          'request_path': e.requestOptions.path,
        },
      ));

      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: userMsg,
      );
    } catch (e, stack) {
      debugPrint('❌ [Crate] Non-Dio error claiming daily crate: $e');
      debugPrint('❌ [Crate] Stack:\n$stack');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Claim daily crate failed (non-Dio)',
        tags: {'feature': 'daily_crate', 'op': 'claim'},
        extra: {
          'crate_type': crateType,
          'crate_date': crateDate ?? 'default(today)',
        },
      ));
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Claim failed: $e',
      );
    }
  }

  /// Get all unclaimed daily crates (up to 9 most recent).
  Future<List<UnclaimedCrate>> getUnclaimedCrates() async {
    try {
      final response = await _client.get('/xp/unclaimed-crates');
      final list = response.data['unclaimed'] as List<dynamic>? ?? [];
      return list
          .map((e) => UnclaimedCrate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting unclaimed crates: $e');
      return [];
    }
  }

  /// Unlock the activity crate (call when all daily goals are complete)
  Future<bool> unlockActivityCrate() async {
    try {
      final response = await _client.post('/xp/unlock-activity-crate');
      return response.data['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error unlocking activity crate: $e');
      return false;
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

  /// Get both weekly and monthly checkpoint progress
  Future<Map<String, CheckpointProgress>> getAllCheckpointProgress() async {
    try {
      final response = await _client.get('/xp/all-checkpoint-progress');
      final data = response.data as Map<String, dynamic>;
      return {
        'weekly': data['weekly'] != null
            ? CheckpointProgress.fromJson({...data['weekly'] as Map<String, dynamic>, 'checkpoint_type': 'weekly'})
            : CheckpointProgress.empty('weekly'),
        'monthly': data['monthly'] != null
            ? CheckpointProgress.fromJson({...data['monthly'] as Map<String, dynamic>, 'checkpoint_type': 'monthly'})
            : CheckpointProgress.empty('monthly'),
      };
    } catch (e) {
      debugPrint('Error getting all checkpoint progress: $e');
      return {
        'weekly': CheckpointProgress.empty('weekly'),
        'monthly': CheckpointProgress.empty('monthly'),
      };
    }
  }

  /// Increment workout count for checkpoints (call when workout completes)
  Future<CheckpointIncrementResult> incrementCheckpointWorkout() async {
    try {
      final response = await _client.post('/xp/increment-checkpoint-workout');
      return CheckpointIncrementResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error incrementing checkpoint workout: $e');
      return const CheckpointIncrementResult();
    }
  }

  /// Get today's daily goal completion status from backend
  /// Returns which goals have been completed today
  Future<DailyGoalsStatus> getDailyGoalsStatus() async {
    try {
      final response = await _client.get('/xp/daily-goals-status',
        queryParameters: {'date': Tz.localDate()},
      );
      return DailyGoalsStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily goals status: $e');
      return const DailyGoalsStatus();
    }
  }

  // =========================================================================
  // Extended Weekly Checkpoints (10 types)
  // =========================================================================

  /// Get all 10 weekly checkpoint progress items
  Future<ExtendedWeeklyProgress> getExtendedWeeklyProgress() async {
    try {
      final response = await _client.get('/xp/weekly-checkpoints');
      return ExtendedWeeklyProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting extended weekly progress: $e');
      return ExtendedWeeklyProgress.empty();
    }
  }

  /// Increment a specific weekly checkpoint (protein, calories, hydration, etc.)
  Future<Map<String, dynamic>> incrementWeeklyCheckpoint(String checkpointType) async {
    try {
      final response = await _client.post(
        '/xp/increment-weekly-checkpoint',
        queryParameters: {'checkpoint_type': checkpointType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error incrementing weekly checkpoint: $e');
      return {'success': false};
    }
  }

  /// Update weekly habits completion percentage
  Future<Map<String, dynamic>> updateWeeklyHabits(double completionPercent) async {
    try {
      final response = await _client.post(
        '/xp/update-weekly-habits',
        queryParameters: {'completion_percent': completionPercent},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating weekly habits: $e');
      return {'success': false};
    }
  }

  // =========================================================================
  // Monthly Achievements (12 types)
  // =========================================================================

  /// Get all 12 monthly achievement progress items
  Future<MonthlyAchievementsProgress> getMonthlyAchievements() async {
    try {
      final response = await _client.get('/xp/monthly-achievements');
      return MonthlyAchievementsProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting monthly achievements: $e');
      return MonthlyAchievementsProgress.empty();
    }
  }

  /// Increment a specific monthly achievement
  Future<Map<String, dynamic>> incrementMonthlyAchievement(
    String achievementType, {
    String interactionType = 'reaction',
  }) async {
    try {
      final response = await _client.post(
        '/xp/increment-monthly-achievement',
        queryParameters: {
          'achievement_type': achievementType,
          'interaction_type': interactionType,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error incrementing monthly achievement: $e');
      return {'success': false};
    }
  }

  /// Update monthly goal progress percentage
  Future<Map<String, dynamic>> updateMonthlyGoalProgress(double progress) async {
    try {
      final response = await _client.post(
        '/xp/update-monthly-goal-progress',
        queryParameters: {'progress': progress},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating monthly goal progress: $e');
      return {'success': false};
    }
  }

  // =========================================================================
  // Daily Social XP (4 actions, 270 XP cap)
  // =========================================================================

  /// Get today's social XP status
  Future<DailySocialXPStatus> getDailySocialXP() async {
    try {
      final response = await _client.get('/xp/daily-social-xp');
      return DailySocialXPStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily social XP: $e');
      return DailySocialXPStatus.empty();
    }
  }

  /// Award XP for a social action (share, react, comment, friend)
  Future<SocialXPResult> awardSocialXP(String actionType) async {
    try {
      final response = await _client.post(
        '/xp/award-social-xp',
        queryParameters: {'action_type': actionType},
      );
      return SocialXPResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error awarding social XP: $e');
      return SocialXPResult.empty();
    }
  }

  /// Get all 250 levels with names, titles, XP requirements, and milestones
  Future<List<Map<String, dynamic>>> getAllLevels() async {
    final response = await _client.get('/xp/all-levels');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
