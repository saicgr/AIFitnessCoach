import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level_reward.dart';
import '../models/user_xp.dart';
import '../models/trophy.dart';
import '../models/xp_event.dart';
import '../repositories/xp_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

// ============================================
// XP Earned Animation Event
// ============================================

/// Types of goals that can earn XP
enum XPGoalType {
  dailyLogin,
  weightLog,
  mealLog,
  workoutComplete,
  proteinGoal,
  bodyMeasurements,
}

/// Event representing XP earned that triggers an animation
class XPEarnedAnimationEvent {
  final int xpAmount;
  final XPGoalType goalType;
  final DateTime timestamp;

  XPEarnedAnimationEvent({
    required this.xpAmount,
    required this.goalType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ============================================
// Daily Goals Model
// ============================================

/// Tracks daily goal completion for the current day
class DailyGoals {
  final bool loggedIn;
  final bool completedWorkout;
  final bool loggedMeal;
  final bool loggedWeight;
  final bool hitProteinGoal;
  final bool loggedBodyMeasurements;
  final DateTime date;

  const DailyGoals({
    this.loggedIn = false,
    this.completedWorkout = false,
    this.loggedMeal = false,
    this.loggedWeight = false,
    this.hitProteinGoal = false,
    this.loggedBodyMeasurements = false,
    required this.date,
  });

  DailyGoals copyWith({
    bool? loggedIn,
    bool? completedWorkout,
    bool? loggedMeal,
    bool? loggedWeight,
    bool? hitProteinGoal,
    bool? loggedBodyMeasurements,
    DateTime? date,
  }) {
    return DailyGoals(
      loggedIn: loggedIn ?? this.loggedIn,
      completedWorkout: completedWorkout ?? this.completedWorkout,
      loggedMeal: loggedMeal ?? this.loggedMeal,
      loggedWeight: loggedWeight ?? this.loggedWeight,
      hitProteinGoal: hitProteinGoal ?? this.hitProteinGoal,
      loggedBodyMeasurements: loggedBodyMeasurements ?? this.loggedBodyMeasurements,
      date: date ?? this.date,
    );
  }

  /// Number of goals completed
  int get completedCount {
    int count = 0;
    if (loggedIn) count++;
    if (completedWorkout) count++;
    if (loggedMeal) count++;
    if (loggedWeight) count++;
    if (hitProteinGoal) count++;
    if (loggedBodyMeasurements) count++;
    return count;
  }

  /// Total number of daily goals
  int get totalCount => 6;

  /// Progress as a fraction (0.0 to 1.0)
  double get progress => completedCount / totalCount;

  /// Total XP available from daily goals
  /// Login XP is fixed at 5 XP per day (one-time, doesn't stack with streak)
  int xpEarned(int streak, double multiplier) {
    int xp = 0;
    // Fixed +5 XP for daily login (one-time per day)
    if (loggedIn) xp += 5;
    if (completedWorkout) xp += 100;
    if (loggedMeal) xp += 25;
    if (loggedWeight) xp += 15;
    if (hitProteinGoal) xp += 50;
    if (loggedBodyMeasurements) xp += 20;
    return (xp * multiplier).round();
  }

  /// Whether it's a new day since the last goals were tracked
  bool isStale(DateTime now) {
    return date.year != now.year ||
        date.month != now.month ||
        date.day != now.day;
  }

  /// Create a fresh daily goals for today
  factory DailyGoals.today() {
    return DailyGoals(date: DateTime.now());
  }
}

// ============================================
// XP State
// ============================================

/// Complete XP and trophy state
class XPState {
  final UserXP? userXp;
  final List<TrophyProgress> allTrophies;
  final List<TrophyProgress> earnedTrophies;
  final List<XPTransaction> recentTransactions;
  final List<XPLeaderboardEntry> leaderboard;
  final List<WorldRecord> worldRecords;
  final List<FormerChampion> formerChampions;
  final TrophyRoomSummary? trophySummary;
  final bool isLoading;
  final bool isLoadingTrophies;
  final String? error;
  final LevelUpEvent? lastLevelUp;

  // XP Events (Daily Login, Double XP, etc.)
  final List<XPEvent> activeEvents;
  final LoginStreakInfo? loginStreak;
  final DailyLoginResult? lastDailyLoginResult;
  final List<XPBonusTemplate> bonusTemplates;
  final CheckpointProgress? weeklyCheckpoints;
  final CheckpointProgress? monthlyCheckpoints;

  // Daily Goals tracking
  final DailyGoals? dailyGoals;

  // Streak milestone tracking
  final StreakMilestone? lastStreakMilestone;
  final int? previousStreak; // To detect milestone transitions

  // XP earned animation tracking
  final XPEarnedAnimationEvent? lastXPEarnedEvent;

  // First-time bonuses tracking
  final Set<String> awardedBonuses;

  // Consumables inventory
  final UserConsumables? consumables;

  // Daily crates state
  final DailyCratesState? dailyCrates;

  const XPState({
    this.userXp,
    this.allTrophies = const [],
    this.earnedTrophies = const [],
    this.recentTransactions = const [],
    this.leaderboard = const [],
    this.worldRecords = const [],
    this.formerChampions = const [],
    this.trophySummary,
    this.isLoading = false,
    this.isLoadingTrophies = false,
    this.error,
    this.lastLevelUp,
    // XP Events
    this.activeEvents = const [],
    this.loginStreak,
    this.lastDailyLoginResult,
    this.bonusTemplates = const [],
    this.weeklyCheckpoints,
    this.monthlyCheckpoints,
    // Daily Goals
    this.dailyGoals,
    // Streak milestones
    this.lastStreakMilestone,
    this.previousStreak,
    // XP earned animation
    this.lastXPEarnedEvent,
    // First-time bonuses
    this.awardedBonuses = const {},
    // Consumables
    this.consumables,
    // Daily crates
    this.dailyCrates,
  });

  XPState copyWith({
    UserXP? userXp,
    List<TrophyProgress>? allTrophies,
    List<TrophyProgress>? earnedTrophies,
    List<XPTransaction>? recentTransactions,
    List<XPLeaderboardEntry>? leaderboard,
    List<WorldRecord>? worldRecords,
    List<FormerChampion>? formerChampions,
    TrophyRoomSummary? trophySummary,
    bool? isLoading,
    bool? isLoadingTrophies,
    String? error,
    LevelUpEvent? lastLevelUp,
    bool clearError = false,
    bool clearLevelUp = false,
    // XP Events
    List<XPEvent>? activeEvents,
    LoginStreakInfo? loginStreak,
    DailyLoginResult? lastDailyLoginResult,
    List<XPBonusTemplate>? bonusTemplates,
    CheckpointProgress? weeklyCheckpoints,
    CheckpointProgress? monthlyCheckpoints,
    bool clearDailyLoginResult = false,
    // Daily Goals
    DailyGoals? dailyGoals,
    // Streak milestones
    StreakMilestone? lastStreakMilestone,
    int? previousStreak,
    bool clearStreakMilestone = false,
    // XP earned animation
    XPEarnedAnimationEvent? lastXPEarnedEvent,
    bool clearXPEarnedEvent = false,
    // First-time bonuses
    Set<String>? awardedBonuses,
    // Consumables
    UserConsumables? consumables,
    // Daily crates
    DailyCratesState? dailyCrates,
  }) {
    return XPState(
      userXp: userXp ?? this.userXp,
      allTrophies: allTrophies ?? this.allTrophies,
      earnedTrophies: earnedTrophies ?? this.earnedTrophies,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      leaderboard: leaderboard ?? this.leaderboard,
      worldRecords: worldRecords ?? this.worldRecords,
      formerChampions: formerChampions ?? this.formerChampions,
      trophySummary: trophySummary ?? this.trophySummary,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTrophies: isLoadingTrophies ?? this.isLoadingTrophies,
      error: clearError ? null : (error ?? this.error),
      lastLevelUp: clearLevelUp ? null : (lastLevelUp ?? this.lastLevelUp),
      // XP Events
      activeEvents: activeEvents ?? this.activeEvents,
      loginStreak: loginStreak ?? this.loginStreak,
      lastDailyLoginResult: clearDailyLoginResult
          ? null
          : (lastDailyLoginResult ?? this.lastDailyLoginResult),
      bonusTemplates: bonusTemplates ?? this.bonusTemplates,
      weeklyCheckpoints: weeklyCheckpoints ?? this.weeklyCheckpoints,
      monthlyCheckpoints: monthlyCheckpoints ?? this.monthlyCheckpoints,
      // Daily Goals
      dailyGoals: dailyGoals ?? this.dailyGoals,
      // Streak milestones
      lastStreakMilestone: clearStreakMilestone ? null : (lastStreakMilestone ?? this.lastStreakMilestone),
      previousStreak: previousStreak ?? this.previousStreak,
      // XP earned animation
      lastXPEarnedEvent: clearXPEarnedEvent ? null : (lastXPEarnedEvent ?? this.lastXPEarnedEvent),
      // First-time bonuses
      awardedBonuses: awardedBonuses ?? this.awardedBonuses,
      // Consumables
      consumables: consumables ?? this.consumables,
      // Daily crates
      dailyCrates: dailyCrates ?? this.dailyCrates,
    );
  }

  /// Current level
  int get currentLevel => userXp?.currentLevel ?? 1;

  /// Current title
  String get title => userXp?.title ?? 'Novice';

  /// Total XP
  int get totalXp => userXp?.totalXp ?? 0;

  /// Progress to next level (0.0 to 1.0)
  double get progressFraction => userXp?.progressFraction ?? 0;

  /// Progress percentage
  int get progressPercent => userXp?.progressPercent ?? 0;

  /// XP needed for next level
  int get xpToNextLevel => userXp?.xpToNextLevel ?? 1000;

  /// XP earned in current level
  int get xpInCurrentLevel => userXp?.xpInCurrentLevel ?? 0;

  /// Prestige level
  int get prestigeLevel => userXp?.prestigeLevel ?? 0;

  /// Check if user has leveled up
  bool get hasLevelUp => lastLevelUp != null;

  /// Total earned trophies count
  int get earnedCount => earnedTrophies.length;

  /// Total trophies count
  int get totalCount => allTrophies.length;

  /// Trophies by category
  Map<TrophyCategory, List<TrophyProgress>> get trophiesByCategory {
    final map = <TrophyCategory, List<TrophyProgress>>{};
    for (final trophy in allTrophies) {
      final category = trophy.trophy.trophyCategory;
      map.putIfAbsent(category, () => []);
      map[category]!.add(trophy);
    }
    return map;
  }

  /// Get trophies for a specific category
  List<TrophyProgress> getTrophiesForCategory(TrophyCategory category) {
    return allTrophies
        .where((t) => t.trophy.trophyCategory == category)
        .toList();
  }

  /// Get in-progress trophies (started but not earned)
  List<TrophyProgress> get inProgressTrophies {
    return allTrophies
        .where((t) => !t.isEarned && t.progressPercentage > 0)
        .toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
  }

  /// Get locked trophies
  List<TrophyProgress> get lockedTrophies {
    return allTrophies.where((t) => !t.isEarned).toList();
  }

  // =========================================================================
  // XP Events Getters
  // =========================================================================

  /// Whether Double XP is currently active
  bool get hasDoubleXP => activeEvents.any((e) => e.isDoubleXP && e.isActive);

  /// Get the active Double XP event (if any)
  XPEvent? get activeDoubleXPEvent =>
      activeEvents.where((e) => e.isDoubleXP && e.isActive).firstOrNull;

  /// Current XP multiplier (from active events)
  double get currentMultiplier {
    if (activeEvents.isEmpty) return 1.0;
    final activeMultipliers = activeEvents
        .where((e) => e.isActive)
        .map((e) => e.xpMultiplier)
        .toList();
    if (activeMultipliers.isEmpty) return 1.0;
    // Use the highest multiplier if multiple events are active
    return activeMultipliers.reduce((a, b) => a > b ? a : b);
  }

  /// Current login streak days
  int get currentStreak => loginStreak?.currentStreak ?? 0;

  /// Longest login streak days
  int get longestStreak => loginStreak?.longestStreak ?? 0;

  /// Whether user has logged in today
  bool get hasLoggedInToday => loginStreak?.hasLoggedInToday ?? false;

  /// Days until next streak milestone
  int? get daysToNextMilestone => loginStreak?.daysToNextMilestone;

  /// Next streak milestone (7, 30, 100, 365)
  int? get nextMilestone => loginStreak?.nextMilestone;

  /// Whether daily login result is significant (first login, milestone, etc.)
  bool get hasDailyLoginCelebration =>
      lastDailyLoginResult != null && lastDailyLoginResult!.isSignificant;

  /// Weekly checkpoint progress percentage
  double get weeklyProgress => weeklyCheckpoints?.progressPercentage ?? 0;

  /// Monthly checkpoint progress percentage
  double get monthlyProgress => monthlyCheckpoints?.progressPercentage ?? 0;

  // =========================================================================
  // Streak Milestone Getters
  // =========================================================================

  /// Whether there's a streak milestone to celebrate
  bool get hasStreakMilestone => lastStreakMilestone != null;

  /// Get next streak milestone info
  StreakMilestone? get nextStreakMilestone => StreakMilestone.nextMilestone(currentStreak);

  /// Days until next streak milestone
  int? get daysToNextStreakMilestone => StreakMilestone.daysUntilNext(currentStreak);

  // =========================================================================
  // XP Earned Animation Getters
  // =========================================================================

  /// Whether there's an XP earned event to animate
  bool get hasXPEarnedEvent => lastXPEarnedEvent != null;
}

// ============================================
// XP Notifier
// ============================================

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
XPState? _xpInMemoryCache;

class XPNotifier extends StateNotifier<XPState> {
  final XPRepository _repository;
  String? _currentUserId;

  XPNotifier(this._repository)
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
      final userXp = await _repository.getUserXP(uid);
      state = state.copyWith(
        userXp: userXp,
        isLoading: false,
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

  // =========================================================================
  // XP Events (Daily Login, Double XP, Checkpoints)
  // =========================================================================

  /// Process daily login and get XP bonuses
  Future<DailyLoginResult?> processDailyLogin() async {
    try {
      final result = await _repository.processDailyLogin();
      if (result != null) {
        // Update state with result - always set hasLoggedInToday to true
        // since we successfully contacted the server
        state = state.copyWith(
          lastDailyLoginResult: result,
          loginStreak: LoginStreakInfo(
            currentStreak: result.currentStreak,
            longestStreak: result.longestStreak,
            totalLogins: result.totalLogins,
            hasLoggedInToday: true,
          ),
          activeEvents: result.activeEvents ?? state.activeEvents,
        );

        // If XP was awarded, reload from server for accurate total
        // (instead of doing local math which can get out of sync)
        if (result.totalXpAwarded > 0) {
          // Trigger XP earned animation for daily login
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.totalXpAwarded,
              goalType: XPGoalType.dailyLogin,
            ),
          );
          await loadUserXP(userId: _currentUserId, showLoading: false);
        }

        debugPrint(
            '[XPProvider] Daily login: +${result.totalXpAwarded} XP, streak: ${result.currentStreak}, already_claimed: ${result.alreadyClaimed}');
      } else {
        debugPrint('[XPProvider] Daily login returned null - API may have failed');
      }
      return result;
    } catch (e) {
      debugPrint('[XPProvider] Error processing daily login: $e');
      return null;
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
      );

      state = state.copyWith(dailyGoals: goals);
      debugPrint('[XPProvider] Synced daily goals: ${goals.completedCount}/${goals.totalCount} (weight=${status.weightLog}, meal=${status.mealLog}, workout=${status.workoutComplete}, protein=${status.proteinGoal}, bodyMeasurements=${status.bodyMeasurements})');
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
      }

      // Check for first-time body measurements bonus (+50 XP)
      await checkFirstBodyMeasurementsBonus();

      // Check if all daily goals are complete for activity crate unlock
      await checkAndUnlockActivityCrate();

      // Always refresh XP data to keep progress bar in sync
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

  /// Award a first-time bonus if not already awarded
  /// Returns the XP awarded (0 if already claimed)
  Future<int> awardFirstTimeBonus(String bonusType) async {
    // Skip if already awarded locally
    if (state.awardedBonuses.contains(bonusType)) {
      debugPrint('[XPProvider] Bonus $bonusType already awarded (local check)');
      return 0;
    }

    try {
      final result = await _repository.awardFirstTimeBonus(bonusType);

      if (result.awarded) {
        // Update local state
        state = state.copyWith(
          awardedBonuses: {...state.awardedBonuses, bonusType},
        );

        // Trigger animation event
        if (result.xp > 0) {
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.xp,
              goalType: _bonusTypeToGoalType(bonusType),
            ),
          );
        }

        // Refresh XP data
        await loadUserXP(userId: _currentUserId, showLoading: false);

        debugPrint('[XPProvider] Awarded first-time bonus: $bonusType (+${result.xp} XP)');
        return result.xp;
      } else {
        // Mark as awarded even if backend says it was already awarded
        state = state.copyWith(
          awardedBonuses: {...state.awardedBonuses, bonusType},
        );
        debugPrint('[XPProvider] Bonus $bonusType was already awarded (backend check)');
        return 0;
      }
    } catch (e) {
      debugPrint('[XPProvider] Error awarding first-time bonus: $e');
      return 0;
    }
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

  /// Award first chat bonus (50 XP)
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

  /// Claim a daily crate (pick 1 of 3)
  Future<CrateRewardResult> claimDailyCrate(String crateType) async {
    try {
      final result = await _repository.claimDailyCrate(crateType);

      if (result.success) {
        // Reload daily crates state
        await loadDailyCrates();

        // Reload consumables in case we got items
        await loadConsumables();

        // If XP was awarded, trigger animation and refresh XP
        if (result.reward != null && result.reward!.isXP) {
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.reward!.amount,
              goalType: XPGoalType.dailyLogin,
            ),
          );
          await loadUserXP(userId: _currentUserId, showLoading: false);
        }

        debugPrint('[XPProvider] Daily crate claimed! Reward: ${result.reward?.displayName}');
      }

      return result;
    } catch (e) {
      debugPrint('[XPProvider] Error claiming daily crate: $e');
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Error claiming crate',
      );
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

// ============================================
// Providers
// ============================================

/// XP Repository provider
final xpRepositoryProvider = Provider<XPRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return XPRepository(apiClient);
});

/// Main XP provider
final xpProvider = StateNotifierProvider<XPNotifier, XPState>((ref) {
  final repository = ref.watch(xpRepositoryProvider);
  return XPNotifier(repository);
});

/// Current user XP (convenience provider)
final userXpProvider = Provider<UserXP?>((ref) {
  return ref.watch(xpProvider).userXp;
});

/// Current level (convenience provider)
final currentLevelProvider = Provider<int>((ref) {
  return ref.watch(xpProvider).currentLevel;
});

/// Current title (convenience provider)
final currentTitleProvider = Provider<String>((ref) {
  return ref.watch(xpProvider).title;
});

/// Total XP (convenience provider)
final totalXpProvider = Provider<int>((ref) {
  return ref.watch(xpProvider).totalXp;
});

/// XP progress fraction (convenience provider)
final xpProgressProvider = Provider<double>((ref) {
  return ref.watch(xpProvider).progressFraction;
});

/// Trophy summary (convenience provider)
final trophySummaryProvider = Provider<TrophyRoomSummary?>((ref) {
  return ref.watch(xpProvider).trophySummary;
});

/// All trophies (convenience provider)
final allTrophiesProvider = Provider<List<TrophyProgress>>((ref) {
  return ref.watch(xpProvider).allTrophies;
});

/// Earned trophies (convenience provider)
final earnedTrophiesProvider = Provider<List<TrophyProgress>>((ref) {
  return ref.watch(xpProvider).earnedTrophies;
});

/// In-progress trophies (convenience provider)
final inProgressTrophiesProvider = Provider<List<TrophyProgress>>((ref) {
  return ref.watch(xpProvider).inProgressTrophies;
});

/// XP leaderboard (convenience provider)
final xpLeaderboardProvider = Provider<List<XPLeaderboardEntry>>((ref) {
  return ref.watch(xpProvider).leaderboard;
});

/// World records (convenience provider)
final worldRecordsProvider = Provider<List<WorldRecord>>((ref) {
  return ref.watch(xpProvider).worldRecords;
});

/// XP loading state (convenience provider)
final xpLoadingProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).isLoading;
});

/// Level up event (convenience provider)
final levelUpEventProvider = Provider<LevelUpEvent?>((ref) {
  return ref.watch(xpProvider).lastLevelUp;
});

/// Trophies by category provider
final trophiesByCategoryProvider =
    Provider.family<List<TrophyProgress>, TrophyCategory>((ref, category) {
  return ref.watch(xpProvider).getTrophiesForCategory(category);
});

// ============================================
// XP Events Providers
// ============================================

/// Active XP events (Double XP, etc.)
final activeXPEventsProvider = Provider<List<XPEvent>>((ref) {
  return ref.watch(xpProvider).activeEvents;
});

/// Whether Double XP is currently active
final hasDoubleXPProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).hasDoubleXP;
});

/// Active Double XP event (if any)
final activeDoubleXPEventProvider = Provider<XPEvent?>((ref) {
  return ref.watch(xpProvider).activeDoubleXPEvent;
});

/// Current XP multiplier
final xpMultiplierProvider = Provider<double>((ref) {
  return ref.watch(xpProvider).currentMultiplier;
});

/// Login streak info
final loginStreakProvider = Provider<LoginStreakInfo?>((ref) {
  return ref.watch(xpProvider).loginStreak;
});

/// Current login streak days (from XP system)
final xpCurrentStreakProvider = Provider<int>((ref) {
  return ref.watch(xpProvider).currentStreak;
});

/// Whether user has logged in today
final hasLoggedInTodayProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).hasLoggedInToday;
});

/// Daily login result (for celebration)
final dailyLoginResultProvider = Provider<DailyLoginResult?>((ref) {
  return ref.watch(xpProvider).lastDailyLoginResult;
});

/// Whether to show daily login celebration
final showDailyLoginCelebrationProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).hasDailyLoginCelebration;
});

/// Weekly checkpoint progress
final weeklyCheckpointsProvider = Provider<CheckpointProgress?>((ref) {
  return ref.watch(xpProvider).weeklyCheckpoints;
});

/// Monthly checkpoint progress
final monthlyCheckpointsProvider = Provider<CheckpointProgress?>((ref) {
  return ref.watch(xpProvider).monthlyCheckpoints;
});

/// Weekly progress percentage (0.0 to 1.0)
final weeklyProgressProvider = Provider<double>((ref) {
  return ref.watch(xpProvider).weeklyProgress;
});

/// Monthly progress percentage (0.0 to 1.0)
final monthlyProgressProvider = Provider<double>((ref) {
  return ref.watch(xpProvider).monthlyProgress;
});

/// XP bonus templates
final xpBonusTemplatesProvider = Provider<List<XPBonusTemplate>>((ref) {
  return ref.watch(xpProvider).bonusTemplates;
});

// ============================================
// Daily Goals Providers
// ============================================

/// Daily goals state
final dailyGoalsProvider = Provider<DailyGoals?>((ref) {
  return ref.watch(xpProvider).dailyGoals;
});

/// Daily goals completed count
final dailyGoalsCompletedProvider = Provider<int>((ref) {
  return ref.watch(dailyGoalsProvider)?.completedCount ?? 0;
});

/// Daily goals total count
final dailyGoalsTotalProvider = Provider<int>((ref) {
  return ref.watch(dailyGoalsProvider)?.totalCount ?? 4;
});

/// Daily goals progress (0.0 to 1.0)
final dailyGoalsProgressProvider = Provider<double>((ref) {
  return ref.watch(dailyGoalsProvider)?.progress ?? 0.0;
});

/// Daily XP earned (considering multiplier)
final dailyXpEarnedProvider = Provider<int>((ref) {
  final goals = ref.watch(dailyGoalsProvider);
  final streak = ref.watch(xpCurrentStreakProvider);
  final multiplier = ref.watch(xpMultiplierProvider);
  return goals?.xpEarned(streak, multiplier) ?? 0;
});

// ============================================
// Streak Milestone Providers
// ============================================

/// Last achieved streak milestone (for celebration)
final streakMilestoneProvider = Provider<StreakMilestone?>((ref) {
  return ref.watch(xpProvider).lastStreakMilestone;
});

/// Whether there's a streak milestone to celebrate
final hasStreakMilestoneProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).hasStreakMilestone;
});

/// Next streak milestone to achieve
final nextStreakMilestoneProvider = Provider<StreakMilestone?>((ref) {
  return ref.watch(xpProvider).nextStreakMilestone;
});

/// Days until next streak milestone
final daysToNextStreakMilestoneProvider = Provider<int?>((ref) {
  return ref.watch(xpProvider).daysToNextStreakMilestone;
});

// ============================================
// XP Earned Animation Providers
// ============================================

/// Last XP earned event (for animation)
final xpEarnedEventProvider = Provider<XPEarnedAnimationEvent?>((ref) {
  return ref.watch(xpProvider).lastXPEarnedEvent;
});

/// Whether there's an XP earned event to animate
final hasXPEarnedEventProvider = Provider<bool>((ref) {
  return ref.watch(xpProvider).hasXPEarnedEvent;
});

// ============================================
// First-Time Bonus Providers
// ============================================

/// Set of awarded first-time bonus types
final awardedBonusesProvider = Provider<Set<String>>((ref) {
  return ref.watch(xpProvider).awardedBonuses;
});

/// Check if a specific bonus has been awarded
final hasBonusProvider = Provider.family<bool, String>((ref, bonusType) {
  return ref.watch(awardedBonusesProvider).contains(bonusType);
});

/// Number of first-time bonuses awarded
final awardedBonusCountProvider = Provider<int>((ref) {
  return ref.watch(awardedBonusesProvider).length;
});

// ============================================
// Consumables Providers
// ============================================

/// User's consumables inventory
final consumablesProvider = Provider<UserConsumables?>((ref) {
  return ref.watch(xpProvider).consumables;
});

/// Number of streak shields
final streakShieldsProvider = Provider<int>((ref) {
  return ref.watch(consumablesProvider)?.streakShield ?? 0;
});

/// Number of 2x XP tokens
final xpTokensProvider = Provider<int>((ref) {
  return ref.watch(consumablesProvider)?.xpToken2x ?? 0;
});

/// Number of fitness crates
final fitnessCratesProvider = Provider<int>((ref) {
  return ref.watch(consumablesProvider)?.fitnessCrate ?? 0;
});

/// Number of premium crates
final premiumCratesProvider = Provider<int>((ref) {
  return ref.watch(consumablesProvider)?.premiumCrate ?? 0;
});

/// Total number of crates
final totalCratesProvider = Provider<int>((ref) {
  return ref.watch(consumablesProvider)?.totalCrates ?? 0;
});

/// Whether 2x XP is currently active
final is2xXPActiveProvider = Provider<bool>((ref) {
  return ref.watch(consumablesProvider)?.is2xActive ?? false;
});

/// Time remaining for 2x XP boost
final remaining2xTimeProvider = Provider<Duration?>((ref) {
  return ref.watch(consumablesProvider)?.remaining2xTime;
});

// ============================================
// Daily Crates Providers
// ============================================

/// Daily crates state
final dailyCratesProvider = Provider<DailyCratesState?>((ref) {
  return ref.watch(xpProvider).dailyCrates;
});

/// Whether daily crates banner should be shown
final showDailyCrateBannerProvider = Provider<bool>((ref) {
  final crates = ref.watch(dailyCratesProvider);
  if (crates == null) return false;
  return crates.hasAvailableCrate;
});

/// Number of crates available to choose from
final availableCratesCountProvider = Provider<int>((ref) {
  return ref.watch(dailyCratesProvider)?.availableCount ?? 0;
});

/// Whether daily crate has been claimed today
final dailyCrateClaimedProvider = Provider<bool>((ref) {
  return ref.watch(dailyCratesProvider)?.claimed ?? false;
});

/// Whether streak crate is available
final streakCrateAvailableProvider = Provider<bool>((ref) {
  return ref.watch(dailyCratesProvider)?.streakCrateAvailable ?? false;
});

/// Whether activity crate is available
final activityCrateAvailableProvider = Provider<bool>((ref) {
  return ref.watch(dailyCratesProvider)?.activityCrateAvailable ?? false;
});

// ============================================
// Extended Weekly Progress Providers
// ============================================

/// Extended weekly progress with all 10 checkpoints
final extendedWeeklyProgressProvider = FutureProvider<ExtendedWeeklyProgress>((ref) async {
  final repository = ref.watch(xpRepositoryProvider);
  return repository.getExtendedWeeklyProgress();
});

/// Total XP earned from weekly checkpoints
final weeklyXpEarnedProvider = Provider<int>((ref) {
  final progress = ref.watch(extendedWeeklyProgressProvider);
  return progress.when(
    data: (data) => data.totalXpEarned,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Number of completed weekly checkpoints
final weeklyCheckpointsCompletedProvider = Provider<int>((ref) {
  final progress = ref.watch(extendedWeeklyProgressProvider);
  return progress.when(
    data: (data) => data.completedCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============================================
// Monthly Achievements Providers
// ============================================

/// Monthly achievements progress with all 12 achievements
final monthlyAchievementsProgressProvider = FutureProvider<MonthlyAchievementsProgress>((ref) async {
  final repository = ref.watch(xpRepositoryProvider);
  return repository.getMonthlyAchievements();
});

/// Total XP earned from monthly achievements
final monthlyXpEarnedProvider = Provider<int>((ref) {
  final progress = ref.watch(monthlyAchievementsProgressProvider);
  return progress.when(
    data: (data) => data.totalXpEarned,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Number of completed monthly achievements
final monthlyAchievementsCompletedProvider = Provider<int>((ref) {
  final progress = ref.watch(monthlyAchievementsProgressProvider);
  return progress.when(
    data: (data) => data.completedCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Days remaining in the current month
final monthlyDaysRemainingProvider = Provider<int>((ref) {
  final progress = ref.watch(monthlyAchievementsProgressProvider);
  return progress.when(
    data: (data) => data.daysRemaining,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Current month name
final currentMonthNameProvider = Provider<String>((ref) {
  final progress = ref.watch(monthlyAchievementsProgressProvider);
  return progress.when(
    data: (data) => data.monthName,
    loading: () => '',
    error: (_, __) => '',
  );
});
