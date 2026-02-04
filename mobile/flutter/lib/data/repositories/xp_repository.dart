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
      final response = await _client.get('/xp/daily-crates');
      return DailyCratesState.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily crates: $e');
      return DailyCratesState.empty();
    }
  }

  /// Claim a daily crate (pick 1 of 3 available)
  Future<CrateRewardResult> claimDailyCrate(String crateType) async {
    try {
      final response = await _client.post('/xp/claim-daily-crate', data: {
        'crate_type': crateType,
      });
      return CrateRewardResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error claiming daily crate: $e');
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Error claiming crate',
      );
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
      final response = await _client.get('/xp/daily-goals-status');
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
}

/// Status of daily goals from backend
class DailyGoalsStatus {
  final bool weightLog;
  final bool mealLog;
  final bool workoutComplete;
  final bool proteinGoal;
  final bool bodyMeasurements;

  const DailyGoalsStatus({
    this.weightLog = false,
    this.mealLog = false,
    this.workoutComplete = false,
    this.proteinGoal = false,
    this.bodyMeasurements = false,
  });

  factory DailyGoalsStatus.fromJson(Map<String, dynamic> json) {
    return DailyGoalsStatus(
      weightLog: json['weight_log'] as bool? ?? false,
      mealLog: json['meal_log'] as bool? ?? false,
      workoutComplete: json['workout_complete'] as bool? ?? false,
      proteinGoal: json['protein_goal'] as bool? ?? false,
      bodyMeasurements: json['body_measurements'] as bool? ?? false,
    );
  }
}

/// Result of awarding a first-time bonus
class FirstTimeBonusResult {
  final bool awarded;
  final int xp;
  final String bonusType;
  final String message;

  const FirstTimeBonusResult({
    required this.awarded,
    required this.xp,
    required this.bonusType,
    required this.message,
  });
}

/// Info about an awarded first-time bonus
class FirstTimeBonusInfo {
  final String bonusType;
  final int xpAwarded;
  final DateTime awardedAt;

  const FirstTimeBonusInfo({
    required this.bonusType,
    required this.xpAwarded,
    required this.awardedAt,
  });

  factory FirstTimeBonusInfo.fromJson(Map<String, dynamic> json) {
    return FirstTimeBonusInfo(
      bonusType: json['bonus_type'] as String,
      xpAwarded: json['xp_awarded'] as int,
      awardedAt: DateTime.parse(json['awarded_at'] as String),
    );
  }

  /// Human-readable name for the bonus type
  String get displayName {
    return bonusType
        .replaceAll('_', ' ')
        .replaceFirst('first ', '')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Available bonus with claimed status
class AvailableBonus {
  final String bonusType;
  final int xpAmount;
  final bool awarded;

  const AvailableBonus({
    required this.bonusType,
    required this.xpAmount,
    required this.awarded,
  });

  factory AvailableBonus.fromJson(Map<String, dynamic> json) {
    return AvailableBonus(
      bonusType: json['bonus_type'] as String,
      xpAmount: json['xp_amount'] as int,
      awarded: json['awarded'] as bool,
    );
  }

  /// Human-readable name for the bonus type
  String get displayName {
    return bonusType
        .replaceAll('_', ' ')
        .replaceFirst('first ', '')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Result of incrementing checkpoint workout count
class CheckpointIncrementResult {
  final bool success;
  final int weeklyXpAwarded;
  final int monthlyXpAwarded;
  final int weeklyWorkouts;
  final int monthlyWorkouts;
  final bool weeklyComplete;
  final bool monthlyComplete;
  final int totalXpAwarded;

  const CheckpointIncrementResult({
    this.success = false,
    this.weeklyXpAwarded = 0,
    this.monthlyXpAwarded = 0,
    this.weeklyWorkouts = 0,
    this.monthlyWorkouts = 0,
    this.weeklyComplete = false,
    this.monthlyComplete = false,
    this.totalXpAwarded = 0,
  });

  factory CheckpointIncrementResult.fromJson(Map<String, dynamic> json) {
    return CheckpointIncrementResult(
      success: json['success'] as bool? ?? false,
      weeklyXpAwarded: json['weekly_xp_awarded'] as int? ?? 0,
      monthlyXpAwarded: json['monthly_xp_awarded'] as int? ?? 0,
      weeklyWorkouts: json['weekly_workouts'] as int? ?? 0,
      monthlyWorkouts: json['monthly_workouts'] as int? ?? 0,
      weeklyComplete: json['weekly_complete'] as bool? ?? false,
      monthlyComplete: json['monthly_complete'] as bool? ?? false,
      totalXpAwarded: json['total_xp_awarded'] as int? ?? 0,
    );
  }
}

/// User's consumable inventory
class UserConsumables {
  final int streakShield;
  final int xpToken2x;
  final int fitnessCrate;
  final int premiumCrate;
  final DateTime? active2xUntil;

  const UserConsumables({
    this.streakShield = 0,
    this.xpToken2x = 0,
    this.fitnessCrate = 0,
    this.premiumCrate = 0,
    this.active2xUntil,
  });

  factory UserConsumables.fromJson(Map<String, dynamic> json) {
    DateTime? activeUntil;
    if (json['active_2x_until'] != null) {
      try {
        activeUntil = DateTime.parse(json['active_2x_until'] as String);
      } catch (_) {}
    }
    return UserConsumables(
      streakShield: json['streak_shield'] as int? ?? 0,
      xpToken2x: json['xp_token_2x'] as int? ?? 0,
      fitnessCrate: json['fitness_crate'] as int? ?? 0,
      premiumCrate: json['premium_crate'] as int? ?? 0,
      active2xUntil: activeUntil,
    );
  }

  /// Whether 2x XP is currently active
  bool get is2xActive {
    if (active2xUntil == null) return false;
    return DateTime.now().isBefore(active2xUntil!);
  }

  /// Time remaining for 2x XP boost
  Duration? get remaining2xTime {
    if (!is2xActive) return null;
    return active2xUntil!.difference(DateTime.now());
  }

  /// Total crates available
  int get totalCrates => fitnessCrate + premiumCrate;

  /// Copy with updated values
  UserConsumables copyWith({
    int? streakShield,
    int? xpToken2x,
    int? fitnessCrate,
    int? premiumCrate,
    DateTime? active2xUntil,
  }) {
    return UserConsumables(
      streakShield: streakShield ?? this.streakShield,
      xpToken2x: xpToken2x ?? this.xpToken2x,
      fitnessCrate: fitnessCrate ?? this.fitnessCrate,
      premiumCrate: premiumCrate ?? this.premiumCrate,
      active2xUntil: active2xUntil ?? this.active2xUntil,
    );
  }
}

/// Result of using a consumable
class UseConsumableResult {
  final bool success;
  final String itemType;
  final String message;
  final String? activeUntil;

  const UseConsumableResult({
    required this.success,
    required this.itemType,
    required this.message,
    this.activeUntil,
  });

  factory UseConsumableResult.fromJson(Map<String, dynamic> json) {
    return UseConsumableResult(
      success: json['success'] as bool? ?? false,
      itemType: json['item_type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      activeUntil: json['active_until'] as String?,
    );
  }
}

/// Result of opening a crate
class CrateRewardResult {
  final bool success;
  final String crateType;
  final CrateReward? reward;
  final String? message;

  const CrateRewardResult({
    required this.success,
    required this.crateType,
    this.reward,
    this.message,
  });

  factory CrateRewardResult.fromJson(Map<String, dynamic> json) {
    CrateReward? reward;
    if (json['reward'] != null) {
      reward = CrateReward.fromJson(json['reward'] as Map<String, dynamic>);
    }
    return CrateRewardResult(
      success: json['success'] as bool? ?? false,
      crateType: json['crate_type'] as String? ?? '',
      reward: reward,
      message: json['message'] as String?,
    );
  }
}

/// A reward from opening a crate
class CrateReward {
  final String type;
  final int amount;
  final String displayName;

  const CrateReward({
    required this.type,
    required this.amount,
    required this.displayName,
  });

  factory CrateReward.fromJson(Map<String, dynamic> json) {
    return CrateReward(
      type: json['type'] as String,
      amount: json['amount'] as int,
      displayName: json['display_name'] as String,
    );
  }

  /// Whether this is an XP reward
  bool get isXP => type == 'xp';

  /// Whether this is a consumable reward
  bool get isConsumable => !isXP;
}

/// State of daily crates (pick 1 of 3 each day)
class DailyCratesState {
  final bool dailyCrateAvailable;
  final bool streakCrateAvailable;
  final bool activityCrateAvailable;
  final String? selectedCrate;
  final CrateReward? reward;
  final bool claimed;
  final DateTime? claimedAt;
  final DateTime crateDate;

  const DailyCratesState({
    this.dailyCrateAvailable = true,
    this.streakCrateAvailable = false,
    this.activityCrateAvailable = false,
    this.selectedCrate,
    this.reward,
    this.claimed = false,
    this.claimedAt,
    required this.crateDate,
  });

  factory DailyCratesState.fromJson(Map<String, dynamic> json) {
    CrateReward? reward;
    if (json['reward'] != null) {
      final rewardData = json['reward'] as Map<String, dynamic>;
      reward = CrateReward(
        type: rewardData['type'] as String? ?? 'xp',
        amount: rewardData['amount'] as int? ?? 0,
        displayName: rewardData['type'] == 'xp'
            ? '+${rewardData['amount']} XP'
            : '${rewardData['amount']} ${(rewardData['type'] as String).replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')}',
      );
    }

    DateTime? claimedAt;
    if (json['claimed_at'] != null) {
      try {
        claimedAt = DateTime.parse(json['claimed_at'] as String);
      } catch (_) {}
    }

    return DailyCratesState(
      dailyCrateAvailable: json['daily_crate_available'] as bool? ?? true,
      streakCrateAvailable: json['streak_crate_available'] as bool? ?? false,
      activityCrateAvailable: json['activity_crate_available'] as bool? ?? false,
      selectedCrate: json['selected_crate'] as String?,
      reward: reward,
      claimed: json['claimed'] as bool? ?? false,
      claimedAt: claimedAt,
      crateDate: DateTime.tryParse(json['crate_date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory DailyCratesState.empty() {
    return DailyCratesState(crateDate: DateTime.now());
  }

  /// Number of crates available to choose from
  int get availableCount {
    int count = 0;
    if (dailyCrateAvailable) count++;
    if (streakCrateAvailable) count++;
    if (activityCrateAvailable) count++;
    return count;
  }

  /// Whether any crate is available and not claimed
  bool get hasAvailableCrate => !claimed && availableCount > 0;

  /// Copy with updated values
  DailyCratesState copyWith({
    bool? dailyCrateAvailable,
    bool? streakCrateAvailable,
    bool? activityCrateAvailable,
    String? selectedCrate,
    CrateReward? reward,
    bool? claimed,
    DateTime? claimedAt,
    DateTime? crateDate,
  }) {
    return DailyCratesState(
      dailyCrateAvailable: dailyCrateAvailable ?? this.dailyCrateAvailable,
      streakCrateAvailable: streakCrateAvailable ?? this.streakCrateAvailable,
      activityCrateAvailable: activityCrateAvailable ?? this.activityCrateAvailable,
      selectedCrate: selectedCrate ?? this.selectedCrate,
      reward: reward ?? this.reward,
      claimed: claimed ?? this.claimed,
      claimedAt: claimedAt ?? this.claimedAt,
      crateDate: crateDate ?? this.crateDate,
    );
  }
}

// =========================================================================
// Extended Weekly Progress (10 checkpoints)
// =========================================================================

/// A single weekly checkpoint item
class WeeklyCheckpointItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int current;
  final int target;
  final int xpReward;
  final bool completed;
  final bool xpAwarded;

  const WeeklyCheckpointItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.current,
    required this.target,
    required this.xpReward,
    required this.completed,
    required this.xpAwarded,
  });

  factory WeeklyCheckpointItem.fromJson(Map<String, dynamic> json) {
    return WeeklyCheckpointItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      current: json['current'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
      xpReward: json['xp_reward'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      xpAwarded: json['xp_awarded'] as bool? ?? false,
    );
  }

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progress * 100).round();
}

/// Extended weekly progress with all 10 checkpoint types
class ExtendedWeeklyProgress {
  final String weekStart;
  final int totalXpPossible;
  final int totalXpEarned;
  final List<WeeklyCheckpointItem> checkpoints;

  const ExtendedWeeklyProgress({
    required this.weekStart,
    required this.totalXpPossible,
    required this.totalXpEarned,
    required this.checkpoints,
  });

  factory ExtendedWeeklyProgress.fromJson(Map<String, dynamic> json) {
    final checkpointsData = json['checkpoints'] as List? ?? [];
    return ExtendedWeeklyProgress(
      weekStart: json['week_start'] as String? ?? '',
      totalXpPossible: json['total_xp_possible'] as int? ?? 1575,
      totalXpEarned: json['total_xp_earned'] as int? ?? 0,
      checkpoints: checkpointsData
          .map((e) => WeeklyCheckpointItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ExtendedWeeklyProgress.empty() {
    return const ExtendedWeeklyProgress(
      weekStart: '',
      totalXpPossible: 1575,
      totalXpEarned: 0,
      checkpoints: [],
    );
  }

  int get completedCount => checkpoints.where((c) => c.completed).length;
  double get overallProgress =>
      totalXpPossible > 0 ? totalXpEarned / totalXpPossible : 0.0;
}

// =========================================================================
// Monthly Achievements Progress (12 achievements)
// =========================================================================

/// A single monthly achievement item
class MonthlyAchievementItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final dynamic current;  // Can be int or double for percentages
  final int target;
  final String? unit;
  final int xpReward;
  final bool completed;
  final bool xpAwarded;

  const MonthlyAchievementItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.current,
    required this.target,
    this.unit,
    required this.xpReward,
    required this.completed,
    required this.xpAwarded,
  });

  factory MonthlyAchievementItem.fromJson(Map<String, dynamic> json) {
    return MonthlyAchievementItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      current: json['current'] ?? 0,
      target: json['target'] as int? ?? 1,
      unit: json['unit'] as String?,
      xpReward: json['xp_reward'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      xpAwarded: json['xp_awarded'] as bool? ?? false,
    );
  }

  int get currentInt => current is int ? current : (current as double).round();
  double get progress {
    final curr = current is int ? current.toDouble() : current as double;
    return target > 0 ? (curr / target).clamp(0.0, 1.0) : 0.0;
  }
  int get progressPercent => (progress * 100).round();
}

/// Monthly achievements progress with all 12 achievement types
class MonthlyAchievementsProgress {
  final String month;
  final String monthName;
  final int daysInMonth;
  final int daysRemaining;
  final int totalXpPossible;
  final int totalXpEarned;
  final List<MonthlyAchievementItem> achievements;

  const MonthlyAchievementsProgress({
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.daysRemaining,
    required this.totalXpPossible,
    required this.totalXpEarned,
    required this.achievements,
  });

  factory MonthlyAchievementsProgress.fromJson(Map<String, dynamic> json) {
    final achievementsData = json['achievements'] as List? ?? [];
    return MonthlyAchievementsProgress(
      month: json['month'] as String? ?? '',
      monthName: json['month_name'] as String? ?? '',
      daysInMonth: json['days_in_month'] as int? ?? 30,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      totalXpPossible: json['total_xp_possible'] as int? ?? 5250,
      totalXpEarned: json['total_xp_earned'] as int? ?? 0,
      achievements: achievementsData
          .map((e) => MonthlyAchievementItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory MonthlyAchievementsProgress.empty() {
    return const MonthlyAchievementsProgress(
      month: '',
      monthName: '',
      daysInMonth: 30,
      daysRemaining: 0,
      totalXpPossible: 5250,
      totalXpEarned: 0,
      achievements: [],
    );
  }

  int get completedCount => achievements.where((a) => a.completed).length;
  double get overallProgress =>
      totalXpPossible > 0 ? totalXpEarned / totalXpPossible : 0.0;
}

// =========================================================================
// Daily Social XP (4 actions, 270 XP cap)
// =========================================================================

/// A single social action type
class SocialAction {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpPerAction;
  final int countToday;
  final int maxPerDay;
  final int xpAwardedToday;
  final bool canEarnMore;

  const SocialAction({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpPerAction,
    required this.countToday,
    required this.maxPerDay,
    required this.xpAwardedToday,
    required this.canEarnMore,
  });

  factory SocialAction.fromJson(Map<String, dynamic> json) {
    return SocialAction(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      xpPerAction: json['xp_per_action'] as int? ?? 0,
      countToday: json['count_today'] as int? ?? 0,
      maxPerDay: json['max_per_day'] as int? ?? 1,
      xpAwardedToday: json['xp_awarded_today'] as int? ?? 0,
      canEarnMore: json['can_earn_more'] as bool? ?? true,
    );
  }

  int get remainingCount => maxPerDay - countToday;
  int get potentialXp => remainingCount * xpPerAction;
}

/// Daily social XP status
class DailySocialXPStatus {
  final DateTime date;
  final int totalSocialXpToday;
  final int dailyCap;
  final int remainingCap;
  final bool atCap;
  final List<SocialAction> actions;

  const DailySocialXPStatus({
    required this.date,
    required this.totalSocialXpToday,
    required this.dailyCap,
    required this.remainingCap,
    required this.atCap,
    required this.actions,
  });

  factory DailySocialXPStatus.fromJson(Map<String, dynamic> json) {
    final actionsData = json['actions'] as List? ?? [];
    return DailySocialXPStatus(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalSocialXpToday: json['total_social_xp_today'] as int? ?? 0,
      dailyCap: json['daily_cap'] as int? ?? 270,
      remainingCap: json['remaining_cap'] as int? ?? 270,
      atCap: json['at_cap'] as bool? ?? false,
      actions: actionsData
          .map((e) => SocialAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory DailySocialXPStatus.empty() {
    return DailySocialXPStatus(
      date: DateTime.now(),
      totalSocialXpToday: 0,
      dailyCap: 270,
      remainingCap: 270,
      atCap: false,
      actions: [],
    );
  }

  double get progress => dailyCap > 0 ? totalSocialXpToday / dailyCap : 0.0;
}

/// Result of awarding social XP
class SocialXPResult {
  final bool success;
  final String action;
  final int xpAwarded;
  final int totalSocialXpToday;
  final int dailyCap;
  final bool atCap;

  const SocialXPResult({
    required this.success,
    required this.action,
    required this.xpAwarded,
    required this.totalSocialXpToday,
    required this.dailyCap,
    required this.atCap,
  });

  factory SocialXPResult.fromJson(Map<String, dynamic> json) {
    return SocialXPResult(
      success: json['success'] as bool? ?? false,
      action: json['action'] as String? ?? '',
      xpAwarded: json['xp_awarded'] as int? ?? 0,
      totalSocialXpToday: json['total_social_xp_today'] as int? ?? 0,
      dailyCap: json['daily_cap'] as int? ?? 270,
      atCap: json['at_cap'] as bool? ?? false,
    );
  }

  factory SocialXPResult.empty() {
    return const SocialXPResult(
      success: false,
      action: '',
      xpAwarded: 0,
      totalSocialXpToday: 0,
      dailyCap: 270,
      atCap: false,
    );
  }
}
