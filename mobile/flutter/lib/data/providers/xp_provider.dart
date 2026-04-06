import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_reward.dart';
import '../models/user_xp.dart';
import '../models/trophy.dart';
import '../models/xp_event.dart';
import '../repositories/xp_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import '../../core/services/posthog_service.dart';

part 'xp_provider_part_x_p_earned_animation_event.dart';
part 'xp_provider_part_x_p_notifier.dart';
part 'xp_provider_part_daily_x_p_strip_enabled_notifier.dart';
part 'xp_provider_part_x_p_notifier_ext.dart';


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

// ============================================
// XP Notifier
// ============================================

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
XPState? _xpInMemoryCache;

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
  final posthog = ref.watch(posthogServiceProvider);
  return XPNotifier(repository, posthog);
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

/// Accumulated unclaimed crates (up to 9 most recent days).
final unclaimedCratesProvider = FutureProvider.autoDispose<List<UnclaimedCrate>>((ref) async {
  final repository = ref.watch(xpRepositoryProvider);
  return repository.getUnclaimedCrates();
});

/// Total number of unclaimed crate days (how many crates user can open).
final unclaimedCratesCountProvider = Provider<int>((ref) {
  return ref.watch(unclaimedCratesProvider).valueOrNull?.length ?? 0;
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

// ============================================
// Daily XP Strip Providers (merged from daily_xp_strip_provider.dart)
// ============================================

/// Keys for SharedPreferences
const String _kDailyXPStripEnabled = 'daily_xp_strip_enabled';
const String _kDailyXPStripDismissedDate = 'daily_xp_strip_dismissed_date';

/// Provider for whether the daily XP strip is permanently enabled in settings
/// Default is true (enabled)
final dailyXPStripEnabledProvider =
    StateNotifierProvider<DailyXPStripEnabledNotifier, bool>((ref) {
  return DailyXPStripEnabledNotifier();
});

/// Provider for whether the strip is dismissed for today
/// Resets at midnight
final dailyXPStripDismissedTodayProvider =
    StateNotifierProvider<DailyXPStripDismissedNotifier, bool>((ref) {
  return DailyXPStripDismissedNotifier();
});

/// Combined provider that determines if the strip should be visible
/// Returns true only if enabled in settings AND not dismissed for today
final dailyXPStripVisibleProvider = Provider<bool>((ref) {
  final enabled = ref.watch(dailyXPStripEnabledProvider);
  final dismissedToday = ref.watch(dailyXPStripDismissedTodayProvider);
  return enabled && !dismissedToday;
});
