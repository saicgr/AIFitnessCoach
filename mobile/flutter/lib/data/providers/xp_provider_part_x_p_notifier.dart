part of 'xp_provider.dart';


class XPNotifier extends StateNotifier<XPState> {
  final XPRepository _repository;
  final PosthogService _posthog;
  String? _currentUserId;

  XPNotifier(this._repository, this._posthog)
      : super(_xpInMemoryCache ?? const XPState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _xpInMemoryCache = null;
    debugPrint('🧹 [XPProvider] In-memory cache cleared');
  }

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load cached XP data for instant display
  Future<void> _loadFromCache() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.xpDataKey,
      );
      if (cached != null) {
        final userXp = UserXP.fromJson(cached);
        state = state.copyWith(userXp: userXp, isLoading: false);
        // Update in-memory cache for instant access on provider recreation
        _xpInMemoryCache = state;
        debugPrint('⚡ [XPProvider] Loaded from cache: Level ${userXp.currentLevel}, ${userXp.totalXp} XP');
      }
    } catch (e) {
      debugPrint('⚠️ [XPProvider] Cache parse error: $e');
    }
  }

  /// Save XP data to cache (both in-memory and persistent)
  Future<void> _saveToCache(UserXP userXp) async {
    // Update in-memory cache FIRST for instant access on provider recreation
    _xpInMemoryCache = state.copyWith(userXp: userXp);

    try {
      await DataCacheService.instance.cache(
        DataCacheService.xpDataKey,
        userXp.toJson(),
      );
    } catch (e) {
      debugPrint('⚠️ [XPProvider] Cache save error: $e');
    }
  }

  /// Load user XP data with cache-first pattern
  Future<void> loadUserXP({String? userId, bool showLoading = true}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[XPProvider] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      // Capture old level/title before fetching to detect level-ups
      final oldLevel = state.userXp?.currentLevel;
      final oldTitle = state.userXp?.title;

      final userXp = await _repository.getUserXP(uid);

      // Detect level-up by comparing old vs new level
      LevelUpEvent? levelUp;
      if (oldLevel != null && userXp.currentLevel > oldLevel) {
        levelUp = LevelUpEvent(
          oldLevel: oldLevel,
          newLevel: userXp.currentLevel,
          oldTitle: oldTitle,
          newTitle: userXp.title != oldTitle ? userXp.title : null,
          totalXp: userXp.totalXp,
        );
        debugPrint(
            '🎯 [XPProvider] Level-up detected! $oldLevel → ${userXp.currentLevel}');
      }

      state = state.copyWith(
        userXp: userXp,
        isLoading: false,
        lastLevelUp: levelUp,
      );

      // Save to cache for next app open
      await _saveToCache(userXp);

      debugPrint(
          '[XPProvider] Loaded XP: Level ${userXp.currentLevel}, ${userXp.totalXp} XP');
    } catch (e) {
      debugPrint('[XPProvider] Error loading XP: $e');
      // Only set error if no cached data
      if (state.userXp == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load XP: $e',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Load all trophies with progress
  Future<void> loadTrophies({String? userId, TrophyCategory? category}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoadingTrophies: true);

    try {
      final trophies = await _repository.getTrophyProgress(uid, category: category);
      final earned = trophies.where((t) => t.isEarned).toList();

      state = state.copyWith(
        allTrophies: trophies,
        earnedTrophies: earned,
        isLoadingTrophies: false,
      );
      debugPrint(
          '[XPProvider] Loaded ${trophies.length} trophies (${earned.length} earned)');
    } catch (e) {
      debugPrint('[XPProvider] Error loading trophies: $e');
      state = state.copyWith(isLoadingTrophies: false);
    }
  }

  /// Load trophy room summary
  Future<void> loadTrophySummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final summary = await _repository.getTrophyRoomSummary(uid);
      state = state.copyWith(trophySummary: summary);
      debugPrint(
          '[XPProvider] Trophy summary: ${summary.earnedTrophies}/${summary.totalTrophies}');
    } catch (e) {
      debugPrint('[XPProvider] Error loading trophy summary: $e');
    }
  }

  /// Load recent XP transactions
  Future<void> loadRecentTransactions({String? userId, int limit = 20}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final transactions = await _repository.getXPTransactions(uid, limit: limit);
      state = state.copyWith(recentTransactions: transactions);
      debugPrint('[XPProvider] Loaded ${transactions.length} XP transactions');
    } catch (e) {
      debugPrint('[XPProvider] Error loading transactions: $e');
    }
  }

  /// Load XP leaderboard
  Future<void> loadLeaderboard({int limit = 100}) async {
    try {
      final leaderboard = await _repository.getXPLeaderboard(limit: limit);
      state = state.copyWith(leaderboard: leaderboard);
      debugPrint('[XPProvider] Loaded ${leaderboard.length} leaderboard entries');
    } catch (e) {
      debugPrint('[XPProvider] Error loading leaderboard: $e');
    }
  }

  /// Load world records
  Future<void> loadWorldRecords({String? category}) async {
    try {
      final records = await _repository.getWorldRecords(category: category);
      state = state.copyWith(worldRecords: records);
      debugPrint('[XPProvider] Loaded ${records.length} world records');
    } catch (e) {
      debugPrint('[XPProvider] Error loading world records: $e');
    }
  }

  /// Load former champion badges for user
  Future<void> loadFormerChampions({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final champions = await _repository.getFormerChampions(uid);
      state = state.copyWith(formerChampions: champions);
      debugPrint('[XPProvider] Loaded ${champions.length} former champion badges');
    } catch (e) {
      debugPrint('[XPProvider] Error loading former champions: $e');
    }
  }

  /// Load all XP data with cache-first pattern
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    // Step 1: Load from cache first (no loading state)
    await _loadFromCache();

    // Step 2: Fetch fresh data in background
    final hasCachedData = state.userXp != null;

    if (!hasCachedData) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      await Future.wait([
        loadUserXP(userId: uid, showLoading: !hasCachedData),
        loadTrophySummary(userId: uid),
        syncDailyGoalsFromBackend(),  // Sync which goals were already completed today
        loadAwardedBonuses(),  // Load first-time bonuses that have been awarded
        loadConsumables(),  // Load consumables inventory
        loadDailyCrates(),  // Load daily crates state
      ]);
      state = state.copyWith(isLoading: false);
      debugPrint('[XPProvider] Loaded all XP data');
    } catch (e) {
      debugPrint('[XPProvider] Error loading all data: $e');
      // Only show error if no cached data
      if (!hasCachedData) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load XP data: $e',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }

  /// Clear level up event (after showing celebration)
  void clearLevelUp() {
    state = state.copyWith(clearLevelUp: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Handle XP awarded event (from workout completion, etc.)
  void handleXPAwarded(int xpAmount, String source, {LevelUpEvent? levelUp}) {
    if (state.userXp != null) {
      // Update local XP optimistically
      final newXp = UserXP(
        id: state.userXp!.id,
        userId: state.userXp!.userId,
        totalXp: state.userXp!.totalXp + xpAmount,
        currentLevel: levelUp?.newLevel ?? state.userXp!.currentLevel,
        xpToNextLevel: state.userXp!.xpToNextLevel,
        xpInCurrentLevel: levelUp != null
            ? 0
            : state.userXp!.xpInCurrentLevel + xpAmount,
        prestigeLevel: state.userXp!.prestigeLevel,
        title: levelUp?.newTitle ?? state.userXp!.title,
        trustLevel: state.userXp!.trustLevel,
      );

      state = state.copyWith(
        userXp: newXp,
        lastLevelUp: levelUp,
      );
    }
  }

  /// Load login streak info
  Future<void> loadLoginStreak() async {
    try {
      final streak = await _repository.getLoginStreak();
      state = state.copyWith(loginStreak: streak);
      debugPrint(
          '[XPProvider] Login streak: ${streak.currentStreak} days, longest: ${streak.longestStreak}');
    } catch (e) {
      debugPrint('[XPProvider] Error loading login streak: $e');
    }
  }

  /// Load active XP events (Double XP, etc.)
  Future<void> loadActiveEvents() async {
    try {
      final events = await _repository.getActiveXPEvents();
      state = state.copyWith(activeEvents: events);
      if (events.isNotEmpty) {
        debugPrint(
            '[XPProvider] Active events: ${events.map((e) => '${e.eventName} (${e.multiplierDisplay})').join(', ')}');
      }
    } catch (e) {
      debugPrint('[XPProvider] Error loading active events: $e');
    }
  }

  /// Load XP bonus templates
  Future<void> loadBonusTemplates() async {
    try {
      final templates = await _repository.getBonusTemplates();
      state = state.copyWith(bonusTemplates: templates);
      debugPrint('[XPProvider] Loaded ${templates.length} bonus templates');
    } catch (e) {
      debugPrint('[XPProvider] Error loading bonus templates: $e');
    }
  }

  /// Load checkpoint progress (weekly or monthly)
  Future<void> loadCheckpointProgress(String type) async {
    try {
      final progress = await _repository.getCheckpointProgress(type);
      if (type == 'weekly') {
        state = state.copyWith(weeklyCheckpoints: progress);
      } else if (type == 'monthly') {
        state = state.copyWith(monthlyCheckpoints: progress);
      }
      debugPrint(
          '[XPProvider] $type checkpoint progress: ${progress.earnedCount}/${progress.totalCheckpoints}');
    } catch (e) {
      debugPrint('[XPProvider] Error loading $type checkpoint progress: $e');
    }
  }

  /// Load all checkpoint progress
  Future<void> loadAllCheckpoints() async {
    await Future.wait([
      loadCheckpointProgress('weekly'),
      loadCheckpointProgress('monthly'),
    ]);
  }

  /// Clear daily login result (after showing celebration)
  void clearDailyLoginResult() {
    state = state.copyWith(clearDailyLoginResult: true);
  }

  /// Load all XP events data
  Future<void> loadAllEventsData() async {
    await Future.wait([
      loadLoginStreak(),
      loadActiveEvents(),
      loadAllCheckpoints(),
    ]);
  }

  // =========================================================================
  // Daily Goals Tracking
  // =========================================================================

  /// Get or create today's daily goals
  DailyGoals _getOrCreateDailyGoals() {
    final now = DateTime.now();
    final existing = state.dailyGoals;

    // If no goals exist or they're stale (from a previous day), create fresh ones
    if (existing == null || existing.isStale(now)) {
      return DailyGoals.today().copyWith(
        loggedIn: state.loginStreak?.hasLoggedInToday ?? false,
      );
    }
    return existing;
  }

  /// Initialize daily goals for today
  void initializeDailyGoals() {
    final goals = _getOrCreateDailyGoals();
    state = state.copyWith(dailyGoals: goals);
    debugPrint('[XPProvider] Initialized daily goals: ${goals.completedCount}/${goals.totalCount}');
  }

  /// Sync daily goals status from backend
  /// This ensures UI reflects which goals were already completed today
  Future<void> syncDailyGoalsFromBackend() async {
    try {
      debugPrint('[XPProvider] Syncing daily goals status from backend...');
      final status = await _repository.getDailyGoalsStatus();

      final goals = DailyGoals.today().copyWith(
        loggedIn: state.loginStreak?.hasLoggedInToday ?? false,
        completedWorkout: status.workoutComplete,
        loggedMeal: status.mealLog,
        loggedWeight: status.weightLog,
        hitProteinGoal: status.proteinGoal,
        loggedBodyMeasurements: status.bodyMeasurements,
        hitStepsGoal: status.stepsGoal,
        hitHydrationGoal: status.hydrationGoal,
        hitCalorieGoal: status.calorieGoal,
      );

      state = state.copyWith(dailyGoals: goals);
      debugPrint('[XPProvider] Synced daily goals: ${goals.completedCount}/${goals.totalCount} (weight=${status.weightLog}, meal=${status.mealLog}, workout=${status.workoutComplete}, protein=${status.proteinGoal}, bodyMeasurements=${status.bodyMeasurements}, steps=${status.stepsGoal}, hydration=${status.hydrationGoal}, calorie=${status.calorieGoal})');
    } catch (e) {
      debugPrint('[XPProvider] Error syncing daily goals: $e');
    }
  }

  /// Mark workout completed for today and award XP
  Future<void> markWorkoutCompleted({String? workoutId}) async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.completedWorkout) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(completedWorkout: true),
      );
      debugPrint('[XPProvider] Daily goal: workout completed');

      // Award XP via backend
      final xpAwarded = await _repository.awardGoalXP('workout_complete', sourceId: workoutId);
      if (xpAwarded > 0) {
        // Trigger animation event
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.workoutComplete,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'workout_complete',
          },
        );
      }

      // Increment checkpoint workout count (for weekly/monthly goals)
      final checkpointResult = await _repository.incrementCheckpointWorkout();
      if (checkpointResult.totalXpAwarded > 0) {
        debugPrint('[XPProvider] Checkpoint XP awarded: ${checkpointResult.totalXpAwarded}');
        // Reload checkpoint progress to reflect updated counts
        await loadAllCheckpoints();
      }

      // Check for first-time workout bonus (+150 XP)
      await checkFirstWorkoutBonus();

      // Always refresh XP data to keep progress bar in sync
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark meal logged for today and award XP
  /// [mealType] should be one of: 'breakfast', 'lunch', 'dinner', 'snack'
  Future<void> markMealLogged({String? mealId, String? mealType}) async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.loggedMeal) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(loggedMeal: true),
      );
      debugPrint('[XPProvider] Daily goal: meal logged');

      // Award XP via backend
      final xpAwarded = await _repository.awardGoalXP('meal_log', sourceId: mealId);
      if (xpAwarded > 0) {
        // Trigger animation event
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.mealLog,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'meal_log',
          },
        );
      }

      // Check for first-time meal bonus (+50 XP for first of each meal type)
      if (mealType != null) {
        await checkFirstMealBonus(mealType);
      }

      // Always refresh XP data to keep progress bar in sync
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark weight logged for today and award XP
  Future<void> markWeightLogged({String? weightLogId}) async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.loggedWeight) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(loggedWeight: true),
      );
      debugPrint('[XPProvider] Daily goal: weight logged');

      // Award XP via backend
      final xpAwarded = await _repository.awardGoalXP('weight_log', sourceId: weightLogId);
      if (xpAwarded > 0) {
        // Trigger animation event
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.weightLog,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'weight_log',
          },
        );
      }

      // Check for first-time weight log bonus (+50 XP)
      await checkFirstWeightLogBonus();

      // Always refresh XP data to keep progress bar in sync
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark protein goal hit for today and award XP
  Future<void> markProteinGoalHit() async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.hitProteinGoal) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(hitProteinGoal: true),
      );
      debugPrint('[XPProvider] Daily goal: protein goal hit');

      // Award XP via backend
      final xpAwarded = await _repository.awardGoalXP('protein_goal');
      if (xpAwarded > 0) {
        // Trigger animation event
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.proteinGoal,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'protein_goal',
          },
        );
      }

      // Check for first-time protein goal bonus (+100 XP)
      await checkFirstProteinGoalBonus();

      // Always refresh XP data to keep progress bar in sync
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark body measurements logged for today and award XP (20 XP)
  Future<void> markBodyMeasurementsLogged({String? measurementId}) async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.loggedBodyMeasurements) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(loggedBodyMeasurements: true),
      );
      debugPrint('[XPProvider] Daily goal: body measurements logged');

      // Award XP via backend
      final xpAwarded = await _repository.awardGoalXP('body_measurements', sourceId: measurementId);
      if (xpAwarded > 0) {
        // Trigger animation event
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.bodyMeasurements,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'body_measurements',
          },
        );
      }

      // Check for first-time body measurements bonus (+50 XP)
      await checkFirstBodyMeasurementsBonus();

      // Check if all daily goals are complete for activity crate unlock
      await checkAndUnlockActivityCrate();

      // Always refresh XP data to keep progress bar in sync
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark the daily-steps goal hit (e.g. 10,000 steps reached) and award XP.
  /// Idempotent per day: repeat calls after the flag is set are no-ops.
  /// Also emits a [CoachBannerEvent] so the home screen can surface a
  /// persona-voiced congratulation banner.
  Future<void> markStepsGoalHit(int steps) async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.hitStepsGoal) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(hitStepsGoal: true),
      );
      debugPrint('[XPProvider] Daily goal: steps goal hit ($steps steps)');

      // Award XP via backend.
      final xpAwarded = await _repository.awardGoalXP('steps_goal');
      if (xpAwarded > 0) {
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.stepsGoal,
          ),
          // Piggy-back a coach-banner event so the home screen can show
          // a persona-voiced congratulations at the same time.
          lastCoachBannerEvent: CoachBannerEvent(
            kind: CoachBannerKind.stepsGoal,
            value: steps,
            xpAwarded: xpAwarded,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'steps_goal',
            'steps': steps,
          },
        );
      }

      // Check if all daily goals are complete for activity crate unlock.
      await checkAndUnlockActivityCrate();

      // Always refresh XP data to keep progress bar in sync.
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark the daily hydration goal hit (user reached their daily fluid target).
  /// Idempotent per day.
  Future<void> markHydrationGoalHit() async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.hitHydrationGoal) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(hitHydrationGoal: true),
      );
      debugPrint('[XPProvider] Daily goal: hydration goal hit');

      final xpAwarded = await _repository.awardGoalXP('hydration_goal');
      if (xpAwarded > 0) {
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.hydrationGoal,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'hydration_goal',
          },
        );
      }

      await checkAndUnlockActivityCrate();
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Mark the daily calorie goal hit — "calorie deficit" (consumed under target
  /// after eating most of the day's planned food). Idempotent per day.
  Future<void> markCalorieGoalHit() async {
    final goals = _getOrCreateDailyGoals();
    if (!goals.hitCalorieGoal) {
      state = state.copyWith(
        dailyGoals: goals.copyWith(hitCalorieGoal: true),
      );
      debugPrint('[XPProvider] Daily goal: calorie goal hit');

      final xpAwarded = await _repository.awardGoalXP('calorie_goal');
      if (xpAwarded > 0) {
        state = state.copyWith(
          lastXPEarnedEvent: XPEarnedAnimationEvent(
            xpAmount: xpAwarded,
            goalType: XPGoalType.calorieGoal,
          ),
        );
        _posthog.capture(
          eventName: 'xp_earned',
          properties: <String, Object>{
            'xp_amount': xpAwarded,
            'goal_type': 'calorie_goal',
          },
        );
      }

      await checkAndUnlockActivityCrate();
      await loadUserXP(userId: _currentUserId, showLoading: false);
    }
  }

  /// Reset daily goals (for testing or day change)
  void resetDailyGoals() {
    state = state.copyWith(
      dailyGoals: DailyGoals.today().copyWith(
        loggedIn: state.loginStreak?.hasLoggedInToday ?? false,
      ),
    );
    debugPrint('[XPProvider] Daily goals reset');
  }

  // =========================================================================
  // Streak Milestone Tracking
  // =========================================================================

  /// Check if current streak hit a new milestone
  void checkStreakMilestone(int currentStreak) {
    final previousStreak = state.previousStreak ?? 0;

    // Check if we crossed a milestone threshold
    final milestone = StreakMilestone.forStreak(currentStreak, previousStreak);

    if (milestone != null) {
      state = state.copyWith(
        lastStreakMilestone: milestone,
        previousStreak: currentStreak,
      );
      debugPrint('[XPProvider] Streak milestone reached: ${milestone.badgeName} at $currentStreak days');
    } else {
      // Just update previous streak without triggering milestone
      state = state.copyWith(previousStreak: currentStreak);
    }
  }

  /// Clear streak milestone (after showing celebration)
  void clearStreakMilestone() {
    state = state.copyWith(clearStreakMilestone: true);
  }

  /// Initialize streak tracking (call on app start)
  void initializeStreakTracking() {
    final currentStreak = state.loginStreak?.currentStreak ?? 0;
    if (state.previousStreak == null) {
      state = state.copyWith(previousStreak: currentStreak);
      debugPrint('[XPProvider] Initialized streak tracking at $currentStreak days');
    }
  }

  /// Clear XP earned event (after showing animation)
  void clearXPEarnedEvent() {
    state = state.copyWith(clearXPEarnedEvent: true);
  }

  /// Clear the coach-banner event (after the banner has been shown +
  /// auto-dismissed).
  void clearCoachBannerEvent() {
    state = state.copyWith(clearCoachBannerEvent: true);
  }

  /// Trigger XP earned animation for daily login
  void triggerDailyLoginXPAnimation(int xpAmount) {
    if (xpAmount > 0) {
      state = state.copyWith(
        lastXPEarnedEvent: XPEarnedAnimationEvent(
          xpAmount: xpAmount,
          goalType: XPGoalType.dailyLogin,
        ),
      );
    }
  }

  // =========================================================================
  // First-Time Bonuses
  // =========================================================================

  /// Load awarded first-time bonuses from backend
  Future<void> loadAwardedBonuses() async {
    try {
      final bonuses = await _repository.getAwardedFirstTimeBonuses();
      final bonusTypes = bonuses.map((b) => b.bonusType).toSet();
      state = state.copyWith(awardedBonuses: bonusTypes);
      debugPrint('[XPProvider] Loaded ${bonusTypes.length} awarded first-time bonuses');
    } catch (e) {
      debugPrint('[XPProvider] Error loading awarded bonuses: $e');
    }
  }

  /// Check if a first-time bonus has been awarded
  bool hasBonusBeenAwarded(String bonusType) {
    return state.awardedBonuses.contains(bonusType);
  }

  /// Map bonus type to goal type for animation
  XPGoalType _bonusTypeToGoalType(String bonusType) {
    if (bonusType.contains('workout')) return XPGoalType.workoutComplete;
    if (bonusType.contains('meal') || bonusType.contains('breakfast') ||
        bonusType.contains('lunch') || bonusType.contains('dinner') ||
        bonusType.contains('snack')) return XPGoalType.mealLog;
    if (bonusType.contains('weight')) return XPGoalType.weightLog;
    if (bonusType.contains('protein')) return XPGoalType.proteinGoal;
    if (bonusType.contains('body_measurements')) return XPGoalType.bodyMeasurements;
    return XPGoalType.dailyLogin;
  }

  /// Convenience methods for common first-time bonuses

  /// Award first workout bonus (150 XP)
  Future<int> checkFirstWorkoutBonus() async {
    return awardFirstTimeBonus('first_workout');
  }

  /// Award first meal bonus based on meal type
  Future<int> checkFirstMealBonus(String mealType) async {
    final bonusType = 'first_$mealType';
    return awardFirstTimeBonus(bonusType);
  }

  /// Award first weight log bonus (50 XP)
  Future<int> checkFirstWeightLogBonus() async {
    return awardFirstTimeBonus('first_weight_log');
  }

  /// Award first protein goal bonus (100 XP)
  Future<int> checkFirstProteinGoalBonus() async {
    return awardFirstTimeBonus('first_protein_goal');
  }

  /// Award first body measurements bonus (50 XP)
  Future<int> checkFirstBodyMeasurementsBonus() async {
    return awardFirstTimeBonus('first_body_measurements');
  }

  /// Award first chat bonus (15 XP)
  Future<int> checkFirstChatBonus() async {
    return awardFirstTimeBonus('first_chat');
  }

  /// Award first habit bonus (25 XP)
  Future<int> checkFirstHabitBonus() async {
    return awardFirstTimeBonus('first_habit');
  }

  /// Award first PR bonus (100 XP)
  Future<int> checkFirstPRBonus() async {
    return awardFirstTimeBonus('first_pr');
  }

  /// Award first progress photo bonus (75 XP)
  Future<int> checkFirstProgressPhotoBonus() async {
    return awardFirstTimeBonus('first_progress_photo');
  }

  /// Award first recipe bonus (50 XP)
  Future<int> checkFirstRecipeBonus() async {
    return awardFirstTimeBonus('first_recipe');
  }

  // =========================================================================
  // Consumables System
  // =========================================================================

  /// Load user's consumable inventory
  Future<void> loadConsumables() async {
    try {
      final consumables = await _repository.getConsumables();
      state = state.copyWith(consumables: consumables);
      debugPrint('[XPProvider] Loaded consumables: shields=${consumables.streakShield}, tokens=${consumables.xpToken2x}, crates=${consumables.totalCrates}');
    } catch (e) {
      debugPrint('[XPProvider] Error loading consumables: $e');
    }
  }

  /// Activate 2x XP token (24 hour boost)
  Future<bool> activate2xXPToken() async {
    try {
      final result = await _repository.activate2xXPToken();
      if (result.success) {
        // Reload consumables to update inventory
        await loadConsumables();
        debugPrint('[XPProvider] 2x XP token activated!');
      }
      return result.success;
    } catch (e) {
      debugPrint('[XPProvider] Error activating 2x XP token: $e');
      return false;
    }
  }

  /// Use a streak shield
  Future<bool> useStreakShield() async {
    try {
      final result = await _repository.useConsumable('streak_shield');
      if (result.success) {
        // Reload consumables to update inventory
        await loadConsumables();
        debugPrint('[XPProvider] Streak shield used!');
      }
      return result.success;
    } catch (e) {
      debugPrint('[XPProvider] Error using streak shield: $e');
      return false;
    }
  }

  /// Open a crate and receive reward
  Future<CrateRewardResult> openCrate(String crateType) async {
    try {
      final result = await _repository.openCrate(crateType);
      if (result.success) {
        // Reload consumables to update inventory
        await loadConsumables();

        // If XP was awarded, trigger animation and refresh XP
        if (result.reward != null && result.reward!.isXP) {
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.reward!.amount,
              goalType: XPGoalType.dailyLogin, // Use generic type
            ),
          );
          await loadUserXP(userId: _currentUserId, showLoading: false);
        }

        debugPrint('[XPProvider] Crate opened! Reward: ${result.reward?.displayName}');
      }
      return result;
    } catch (e) {
      debugPrint('[XPProvider] Error opening crate: $e');
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Error opening crate',
      );
    }
  }

  /// Check if 2x XP is currently active
  bool get is2xXPActive => state.consumables?.is2xActive ?? false;

  /// Get remaining time for 2x XP boost
  Duration? get remaining2xTime => state.consumables?.remaining2xTime;

  // =========================================================================
  // Daily Crates System
  // =========================================================================

  /// Load today's daily crates state
  Future<void> loadDailyCrates() async {
    try {
      final dailyCrates = await _repository.getDailyCrates();
      state = state.copyWith(dailyCrates: dailyCrates);
      debugPrint('[XPProvider] Loaded daily crates: available=${dailyCrates.availableCount}, claimed=${dailyCrates.claimed}');
    } catch (e) {
      debugPrint('[XPProvider] Error loading daily crates: $e');
    }
  }

  /// Unlock activity crate when all daily goals complete
  Future<void> checkAndUnlockActivityCrate() async {
    final goals = state.dailyGoals;
    if (goals == null) return;

    // Check if all goals are complete (excluding activity crate unlock itself)
    final allComplete = goals.loggedIn &&
        goals.completedWorkout &&
        goals.loggedMeal &&
        goals.loggedWeight &&
        goals.hitProteinGoal;

    if (allComplete) {
      final unlocked = await _repository.unlockActivityCrate();
      if (unlocked) {
        // Reload daily crates to show activity crate is now available
        await loadDailyCrates();
        debugPrint('[XPProvider] Activity crate unlocked!');
      }
    }
  }

  /// Whether daily crates banner should be shown
  bool get shouldShowDailyCrateBanner {
    final crates = state.dailyCrates;
    if (crates == null) return false;
    return crates.hasAvailableCrate;
  }
}

