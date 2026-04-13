part of 'xp_provider.dart';


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


/// Categories of persona-voiced banners the AI coach can fire when a user
/// hits a meaningful milestone.
enum CoachBannerKind {
  stepsGoal,
}

/// Event that asks the home screen to render a coach-persona banner for a
/// just-completed milestone. The home screen picks the right copy based on
/// the user's selected [CoachPersona].
class CoachBannerEvent {
  final CoachBannerKind kind;

  /// Primary numeric value for the milestone (e.g. step count). Used to
  /// personalise the banner copy.
  final int value;

  /// How much XP was just awarded, surfaced in the banner sub-line.
  final int xpAwarded;

  final DateTime timestamp;

  CoachBannerEvent({
    required this.kind,
    required this.value,
    required this.xpAwarded,
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
  final bool hitStepsGoal;
  final DateTime date;

  const DailyGoals({
    this.loggedIn = false,
    this.completedWorkout = false,
    this.loggedMeal = false,
    this.loggedWeight = false,
    this.hitProteinGoal = false,
    this.loggedBodyMeasurements = false,
    this.hitStepsGoal = false,
    required this.date,
  });

  DailyGoals copyWith({
    bool? loggedIn,
    bool? completedWorkout,
    bool? loggedMeal,
    bool? loggedWeight,
    bool? hitProteinGoal,
    bool? loggedBodyMeasurements,
    bool? hitStepsGoal,
    DateTime? date,
  }) {
    return DailyGoals(
      loggedIn: loggedIn ?? this.loggedIn,
      completedWorkout: completedWorkout ?? this.completedWorkout,
      loggedMeal: loggedMeal ?? this.loggedMeal,
      loggedWeight: loggedWeight ?? this.loggedWeight,
      hitProteinGoal: hitProteinGoal ?? this.hitProteinGoal,
      loggedBodyMeasurements: loggedBodyMeasurements ?? this.loggedBodyMeasurements,
      hitStepsGoal: hitStepsGoal ?? this.hitStepsGoal,
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
    if (hitStepsGoal) count++;
    return count;
  }

  /// Total number of daily goals
  int get totalCount => 7;

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
    if (hitStepsGoal) xp += 30;
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

  // Coach-persona banner event (e.g. 10k-steps congrats)
  final CoachBannerEvent? lastCoachBannerEvent;

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
    // Coach banner
    this.lastCoachBannerEvent,
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
    // Coach banner
    CoachBannerEvent? lastCoachBannerEvent,
    bool clearCoachBannerEvent = false,
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
      // Coach banner
      lastCoachBannerEvent: clearCoachBannerEvent
          ? null
          : (lastCoachBannerEvent ?? this.lastCoachBannerEvent),
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
  String get title => userXp?.title ?? 'Beginner';

  /// Total XP
  int get totalXp => userXp?.totalXp ?? 0;

  /// Progress to next level (0.0 to 1.0)
  double get progressFraction => userXp?.progressFraction ?? 0;

  /// Progress percentage
  int get progressPercent => userXp?.progressPercent ?? 0;

  /// XP needed for next level
  int get xpToNextLevel => userXp?.xpToNextLevel ?? 25;

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

