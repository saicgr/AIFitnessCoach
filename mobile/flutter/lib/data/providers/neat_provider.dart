import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/neat.dart';
import '../repositories/neat_repository.dart';
import '../services/api_client.dart';

// ============================================
// Date Range Helper
// ============================================

/// Helper class for date range parameters
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// ============================================
// NEAT State
// ============================================

/// Complete state for NEAT tracking
class NeatState {
  final NeatDashboard? dashboard;
  final NeatGoal? currentGoal;
  final NeatDailyScore? todayScore;
  final NeatHourlyBreakdown? hourlyBreakdown;
  final List<NeatStreak> streaks;
  final List<UserNeatAchievement> achievements;
  final List<UserNeatAchievement> uncelebratedAchievements;
  final NeatReminderPreferences? reminderPreferences;
  final NeatWeeklySummary? weeklySummary;
  final List<NeatDailyScore> scoreHistory;
  final bool isLoading;
  final bool isLoadingHistory;
  final bool isSyncing;
  final String? error;

  const NeatState({
    this.dashboard,
    this.currentGoal,
    this.todayScore,
    this.hourlyBreakdown,
    this.streaks = const [],
    this.achievements = const [],
    this.uncelebratedAchievements = const [],
    this.reminderPreferences,
    this.weeklySummary,
    this.scoreHistory = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.isSyncing = false,
    this.error,
  });

  NeatState copyWith({
    NeatDashboard? dashboard,
    NeatGoal? currentGoal,
    NeatDailyScore? todayScore,
    NeatHourlyBreakdown? hourlyBreakdown,
    List<NeatStreak>? streaks,
    List<UserNeatAchievement>? achievements,
    List<UserNeatAchievement>? uncelebratedAchievements,
    NeatReminderPreferences? reminderPreferences,
    NeatWeeklySummary? weeklySummary,
    List<NeatDailyScore>? scoreHistory,
    bool? isLoading,
    bool? isLoadingHistory,
    bool? isSyncing,
    String? error,
    bool clearError = false,
  }) {
    return NeatState(
      dashboard: dashboard ?? this.dashboard,
      currentGoal: currentGoal ?? this.currentGoal,
      todayScore: todayScore ?? this.todayScore,
      hourlyBreakdown: hourlyBreakdown ?? this.hourlyBreakdown,
      streaks: streaks ?? this.streaks,
      achievements: achievements ?? this.achievements,
      uncelebratedAchievements:
          uncelebratedAchievements ?? this.uncelebratedAchievements,
      reminderPreferences: reminderPreferences ?? this.reminderPreferences,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Computed properties
  int get currentSteps => todayScore?.totalSteps ?? 0;
  int get stepGoal => currentGoal?.targetValue ?? 10000;
  double get stepProgress => stepGoal > 0 ? currentSteps / stepGoal : 0.0;
  bool get stepGoalAchieved => currentSteps >= stepGoal;
  int get todayScoreValue => todayScore?.score ?? 0;
  int get currentStreak => streaks.isNotEmpty ? streaks.first.currentStreak : 0;
  bool get hasUncelebrated => uncelebratedAchievements.isNotEmpty;
  bool get hasData => dashboard != null || todayScore != null;
}

// ============================================
// NEAT Notifier
// ============================================

class NeatNotifier extends StateNotifier<NeatState> {
  final NeatRepository _repository;
  String? _currentUserId;

  NeatNotifier(this._repository) : super(const NeatState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // -------------------------------------------------------------------------
  // Dashboard Loading
  // -------------------------------------------------------------------------

  /// Load complete dashboard data
  Future<void> loadDashboard({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('\u{1F6B6} [NeatProvider] No user ID, skipping dashboard load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dashboard = await _repository.getNeatDashboard(uid);
      state = state.copyWith(
        dashboard: dashboard,
        todayScore: dashboard.todayScore,
        currentGoal: dashboard.stepGoal,
        hourlyBreakdown: dashboard.hourlyBreakdown,
        streaks: dashboard.streaks,
        achievements: dashboard.recentAchievements,
        weeklySummary: dashboard.weeklySummary,
        isLoading: false,
      );
      debugPrint('\u{1F6B6} [NeatProvider] Dashboard loaded - steps: ${dashboard.todayScore?.totalSteps ?? 0}');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading dashboard: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load activity data: $e',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Goal Management
  // -------------------------------------------------------------------------

  /// Load current goal
  Future<void> loadGoal({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      final goal = await _repository.getNeatGoals(uid);
      state = state.copyWith(currentGoal: goal);
      debugPrint('\u{1F6B6} [NeatProvider] Goal loaded: ${goal.targetValue} steps');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading goal: $e');
    }
  }

  /// Update step goal
  Future<bool> updateStepGoal(int newGoal) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final goal = await _repository.updateStepGoal(uid, newGoal);
      state = state.copyWith(currentGoal: goal);
      debugPrint('\u{1F6B6} [NeatProvider] Step goal updated to $newGoal');
      return true;
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error updating step goal: $e');
      return false;
    }
  }

  /// Calculate and set progressive goal
  Future<bool> setProgressiveGoal() async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final goal = await _repository.calculateProgressiveGoal(uid);
      state = state.copyWith(currentGoal: goal);
      debugPrint('\u{1F6B6} [NeatProvider] Progressive goal set: ${goal.targetValue}');
      return true;
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error setting progressive goal: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Activity Syncing
  // -------------------------------------------------------------------------

  /// Sync hourly activity from health sources
  Future<bool> syncActivity(List<HourlyActivity> activities) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    state = state.copyWith(isSyncing: true);

    try {
      await _repository.syncHourlyActivity(uid, activities);
      state = state.copyWith(isSyncing: false);
      debugPrint('\u{1F6B6} [NeatProvider] Synced ${activities.length} activities');

      // Reload today's data after sync
      await loadTodayScore();
      await loadHourlyBreakdown();

      return true;
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error syncing activity: $e');
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  /// Load hourly breakdown for today
  Future<void> loadHourlyBreakdown({DateTime? date}) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final breakdown = await _repository.getHourlyBreakdown(
        uid,
        date ?? DateTime.now(),
      );
      state = state.copyWith(hourlyBreakdown: breakdown);
      debugPrint('\u{1F6B6} [NeatProvider] Hourly breakdown loaded');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading hourly breakdown: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Scores
  // -------------------------------------------------------------------------

  /// Load today's score
  Future<void> loadTodayScore({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      final score = await _repository.getTodayScore(uid);
      state = state.copyWith(todayScore: score);
      debugPrint('\u{1F6B6} [NeatProvider] Today score: ${score.score}');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading today score: $e');
    }
  }

  /// Load score history for a date range
  Future<void> loadScoreHistory(DateTime startDate, DateTime endDate) async {
    final uid = _currentUserId;
    if (uid == null) return;

    state = state.copyWith(isLoadingHistory: true);

    try {
      final history = await _repository.getScoreHistory(uid, startDate, endDate);
      state = state.copyWith(
        scoreHistory: history,
        isLoadingHistory: false,
      );
      debugPrint('\u{1F6B6} [NeatProvider] Loaded ${history.length} score records');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading score history: $e');
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  // -------------------------------------------------------------------------
  // Streaks
  // -------------------------------------------------------------------------

  /// Load all streaks
  Future<void> loadStreaks({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      final streaks = await _repository.getStreaks(uid);
      state = state.copyWith(streaks: streaks);
      debugPrint('\u{1F6B6} [NeatProvider] Loaded ${streaks.length} streaks');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading streaks: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Achievements
  // -------------------------------------------------------------------------

  /// Load earned achievements
  Future<void> loadAchievements({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      final achievements = await _repository.getAchievements(uid);
      final uncelebrated =
          achievements.where((a) => a.isEarned && !a.isCelebrated).toList();
      state = state.copyWith(
        achievements: achievements,
        uncelebratedAchievements: uncelebrated,
      );
      debugPrint('\u{1F6B6} [NeatProvider] Loaded ${achievements.length} achievements');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading achievements: $e');
    }
  }

  /// Load all available achievements with progress
  Future<List<UserNeatAchievement>> loadAvailableAchievements() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    try {
      return await _repository.getAvailableAchievements(uid);
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading available achievements: $e');
      return [];
    }
  }

  /// Mark achievements as celebrated
  Future<bool> celebrateAchievements(List<String> achievementIds) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final success = await _repository.markAchievementsCelebrated(
        uid,
        achievementIds,
      );
      if (success) {
        // Remove from uncelebrated list
        final remaining = state.uncelebratedAchievements
            .where((a) => !achievementIds.contains(a.id))
            .toList();
        state = state.copyWith(uncelebratedAchievements: remaining);
      }
      return success;
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error celebrating achievements: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Reminder Preferences
  // -------------------------------------------------------------------------

  /// Load reminder preferences
  Future<void> loadReminderPreferences({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      final prefs = await _repository.getReminderPreferences(uid);
      state = state.copyWith(reminderPreferences: prefs);
      debugPrint('\u{1F6B6} [NeatProvider] Loaded reminder preferences');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading reminder preferences: $e');
    }
  }

  /// Update reminder preferences
  Future<bool> updateReminderPreferences(NeatReminderPreferences prefs) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final updated = await _repository.updateReminderPreferences(uid, prefs);
      state = state.copyWith(reminderPreferences: updated);
      debugPrint('\u{1F6B6} [NeatProvider] Reminder preferences updated');
      return true;
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error updating reminder preferences: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Weekly Summary
  // -------------------------------------------------------------------------

  /// Load weekly summary
  Future<void> loadWeeklySummary({DateTime? weekStart}) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final summary = await _repository.getWeeklySummary(uid, weekStart: weekStart);
      state = state.copyWith(weeklySummary: summary);
      debugPrint('\u{1F6B6} [NeatProvider] Weekly summary loaded: ${summary.totalSteps} steps');
    } catch (e) {
      debugPrint('\u274C [NeatProvider] Error loading weekly summary: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Bulk Loading
  // -------------------------------------------------------------------------

  /// Load all NEAT data at once
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('\u{1F6B6} [NeatProvider] No user ID, skipping load all');
      return;
    }
    _currentUserId = uid;

    // Load dashboard first (contains most data)
    await loadDashboard(userId: uid);

    // Load additional data in parallel
    await Future.wait([
      loadAchievements(userId: uid),
      loadReminderPreferences(userId: uid),
    ]);

    debugPrint('\u{1F6B6} [NeatProvider] All NEAT data loaded');
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Main NEAT state provider
final neatProvider = StateNotifierProvider<NeatNotifier, NeatState>((ref) {
  final repository = ref.watch(neatRepositoryProvider);
  return NeatNotifier(repository);
});

/// NEAT goal provider - FutureProvider for current goal
final neatGoalProvider =
    FutureProvider.autoDispose.family<NeatGoal?, String>((ref, userId) async {
  final repository = ref.watch(neatRepositoryProvider);
  try {
    return await repository.getNeatGoals(userId);
  } catch (e) {
    debugPrint('\u274C [neatGoalProvider] Error: $e');
    return null;
  }
});

/// NEAT dashboard provider - FutureProvider for dashboard data
final neatDashboardProvider =
    FutureProvider.autoDispose.family<NeatDashboard?, String>((ref, userId) async {
  final repository = ref.watch(neatRepositoryProvider);
  try {
    return await repository.getNeatDashboard(userId);
  } catch (e) {
    debugPrint('\u274C [neatDashboardProvider] Error: $e');
    return null;
  }
});

/// NEAT score history provider
final neatScoreHistoryProvider = FutureProvider.autoDispose
    .family<List<NeatDailyScore>, ({String userId, DateRange dateRange})>(
  (ref, params) async {
    final repository = ref.watch(neatRepositoryProvider);
    try {
      return await repository.getScoreHistory(
        params.userId,
        params.dateRange.start,
        params.dateRange.end,
      );
    } catch (e) {
      debugPrint('\u274C [neatScoreHistoryProvider] Error: $e');
      return [];
    }
  },
);

/// NEAT streaks provider
final neatStreaksProvider =
    FutureProvider.autoDispose.family<List<NeatStreak>, String>((ref, userId) async {
  final repository = ref.watch(neatRepositoryProvider);
  try {
    return await repository.getStreaks(userId);
  } catch (e) {
    debugPrint('\u274C [neatStreaksProvider] Error: $e');
    return [];
  }
});

/// NEAT achievements provider
final neatAchievementsProvider =
    FutureProvider.autoDispose.family<List<UserNeatAchievement>, String>(
  (ref, userId) async {
    final repository = ref.watch(neatRepositoryProvider);
    try {
      return await repository.getAchievements(userId);
    } catch (e) {
      debugPrint('\u274C [neatAchievementsProvider] Error: $e');
      return [];
    }
  },
);

/// NEAT available achievements provider (includes progress)
final neatAvailableAchievementsProvider =
    FutureProvider.autoDispose.family<List<UserNeatAchievement>, String>(
  (ref, userId) async {
    final repository = ref.watch(neatRepositoryProvider);
    try {
      return await repository.getAvailableAchievements(userId);
    } catch (e) {
      debugPrint('\u274C [neatAvailableAchievementsProvider] Error: $e');
      return [];
    }
  },
);

// ============================================
// Reminder Preferences State Notifier
// ============================================

/// State notifier for reminder preferences with optimistic updates
class NeatReminderPreferencesNotifier
    extends StateNotifier<AsyncValue<NeatReminderPreferences?>> {
  final NeatRepository _repository;
  final String _userId;

  NeatReminderPreferencesNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _repository.getReminderPreferences(_userId);
      state = AsyncValue.data(prefs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update preferences with optimistic update
  Future<bool> updatePreferences(NeatReminderPreferences prefs) async {
    final previousState = state;

    // Optimistic update
    state = AsyncValue.data(prefs);

    try {
      final updated = await _repository.updateReminderPreferences(_userId, prefs);
      state = AsyncValue.data(updated);
      return true;
    } catch (e) {
      // Rollback on error
      state = previousState;
      debugPrint('\u274C [NeatReminderPreferencesNotifier] Update failed: $e');
      return false;
    }
  }

  /// Toggle reminders enabled
  Future<bool> toggleReminders(bool enabled) async {
    final current = state.value;
    if (current == null) return false;
    return updatePreferences(current.copyWith(remindersEnabled: enabled));
  }

  /// Toggle hourly movement reminders
  Future<bool> toggleHourlyMovement(bool enabled) async {
    final current = state.value;
    if (current == null) return false;
    return updatePreferences(current.copyWith(hourlyMovementEnabled: enabled));
  }

  /// Toggle step milestone notifications
  Future<bool> toggleStepMilestones(bool enabled) async {
    final current = state.value;
    if (current == null) return false;
    return updatePreferences(current.copyWith(stepMilestoneEnabled: enabled));
  }

  /// Refresh preferences from server
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPreferences();
  }
}

/// NEAT reminder preferences provider - StateNotifierProvider
final neatReminderPreferencesProvider = StateNotifierProvider.autoDispose
    .family<NeatReminderPreferencesNotifier, AsyncValue<NeatReminderPreferences?>,
        String>(
  (ref, userId) {
    final repository = ref.watch(neatRepositoryProvider);
    return NeatReminderPreferencesNotifier(repository, userId);
  },
);

// ============================================
// Convenience Providers
// ============================================

/// Current step count (convenience provider)
final currentStepsProvider = Provider<int>((ref) {
  return ref.watch(neatProvider).currentSteps;
});

/// Step goal (convenience provider)
final stepGoalProvider = Provider<int>((ref) {
  return ref.watch(neatProvider).stepGoal;
});

/// Step progress percentage (convenience provider)
final stepProgressProvider = Provider<double>((ref) {
  return ref.watch(neatProvider).stepProgress;
});

/// Step goal achieved (convenience provider)
final stepGoalAchievedProvider = Provider<bool>((ref) {
  return ref.watch(neatProvider).stepGoalAchieved;
});

/// Today's NEAT score (convenience provider)
final todayNeatScoreProvider = Provider<int>((ref) {
  return ref.watch(neatProvider).todayScoreValue;
});

/// Current NEAT streak (convenience provider)
final currentNeatStreakProvider = Provider<int>((ref) {
  return ref.watch(neatProvider).currentStreak;
});

/// Has uncelebrated achievements (convenience provider)
final hasUncelebratedNeatAchievementsProvider = Provider<bool>((ref) {
  return ref.watch(neatProvider).hasUncelebrated;
});

/// NEAT loading state (convenience provider)
final neatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(neatProvider).isLoading;
});

/// NEAT weekly summary (convenience provider)
final neatWeeklySummaryProvider = Provider<NeatWeeklySummary?>((ref) {
  return ref.watch(neatProvider).weeklySummary;
});

/// Auto-loading provider that loads data when user ID is available
final neatDataProvider =
    FutureProvider.autoDispose<NeatDashboard?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();

  if (userId == null) {
    return null;
  }

  // Set user ID and load dashboard
  final notifier = ref.read(neatProvider.notifier);
  notifier.setUserId(userId);
  await notifier.loadDashboard();

  return ref.read(neatProvider).dashboard;
});
