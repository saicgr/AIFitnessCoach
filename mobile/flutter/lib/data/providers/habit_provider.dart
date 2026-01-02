import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../repositories/habit_repository.dart';
import '../repositories/auth_repository.dart';

// ============================================
// State Classes
// ============================================

/// Main state for habits tracking
class HabitsState {
  final List<HabitWithStatus> habits;
  final bool isLoading;
  final String? error;
  final int completedToday;
  final int totalHabits;
  final double completionPercentage;

  const HabitsState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
    this.completedToday = 0,
    this.totalHabits = 0,
    this.completionPercentage = 0.0,
  });

  HabitsState copyWith({
    List<HabitWithStatus>? habits,
    bool? isLoading,
    String? error,
    int? completedToday,
    int? totalHabits,
    double? completionPercentage,
    bool clearError = false,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      completedToday: completedToday ?? this.completedToday,
      totalHabits: totalHabits ?? this.totalHabits,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  // Computed properties
  bool get hasHabits => habits.isNotEmpty;
  bool get allCompleted => totalHabits > 0 && completedToday >= totalHabits;
  List<HabitWithStatus> get pendingHabits =>
      habits.where((h) => !h.todayCompleted).toList();
  List<HabitWithStatus> get completedHabits =>
      habits.where((h) => h.todayCompleted).toList();
  int get remainingCount => totalHabits - completedToday;
}

// ============================================
// Habits Notifier
// ============================================

/// Main state notifier for habit tracking
class HabitsNotifier extends StateNotifier<HabitsState> {
  final HabitRepository _repository;
  final String _userId;

  HabitsNotifier(this._repository, this._userId) : super(const HabitsState()) {
    loadTodayHabits();
  }

  /// Load today's habits with completion status
  Future<void> loadTodayHabits() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('🎯 [HabitsProvider] Loading today habits for user $_userId');
      final response = await _repository.getTodayHabits(_userId);

      state = state.copyWith(
        isLoading: false,
        habits: response.habits,
        completedToday: response.completedToday,
        totalHabits: response.totalHabits,
        completionPercentage: response.completionPercentage,
      );
      debugPrint(
          '✅ [HabitsProvider] Loaded ${response.habits.length} habits, '
          '${response.completedToday}/${response.totalHabits} completed');
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error loading habits: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load habits: $e',
      );
    }
  }

  /// Toggle habit completion with optimistic update
  Future<void> toggleHabit(String habitId, bool completed,
      {double? value}) async {
    // Store previous state for rollback
    final previousHabits = List<HabitWithStatus>.from(state.habits);
    final previousCompleted = state.completedToday;
    final previousPercentage = state.completionPercentage;

    // Optimistically update UI
    final updatedHabits = state.habits.map((h) {
      if (h.id == habitId) {
        return h.copyWith(todayCompleted: completed, todayValue: value);
      }
      return h;
    }).toList();

    final newCompleted = updatedHabits.where((h) => h.todayCompleted).length;
    final newPercentage = state.totalHabits > 0
        ? (newCompleted / state.totalHabits) * 100
        : 0.0;

    state = state.copyWith(
      habits: updatedHabits,
      completedToday: newCompleted,
      completionPercentage: newPercentage,
    );

    debugPrint(
        '🎯 [HabitsProvider] Optimistically toggled habit $habitId to $completed');

    try {
      await _repository.toggleTodayHabit(_userId, habitId, completed,
          value: value);
      debugPrint('✅ [HabitsProvider] Habit toggle persisted');

      // Reload to get updated streak info from server
      await loadTodayHabits();
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error toggling habit, rolling back: $e');
      // Rollback on error
      state = state.copyWith(
        habits: previousHabits,
        completedToday: previousCompleted,
        completionPercentage: previousPercentage,
        error: 'Failed to update habit: $e',
      );
    }
  }

  /// Create a new habit
  Future<void> createHabit(HabitCreate habit) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('🎯 [HabitsProvider] Creating habit: ${habit.name}');
      await _repository.createHabit(_userId, habit);
      debugPrint('✅ [HabitsProvider] Habit created successfully');
      await loadTodayHabits();
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error creating habit: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create habit: $e',
      );
    }
  }

  /// Create habit from a template
  Future<void> createFromTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint(
          '🎯 [HabitsProvider] Creating habit from template: $templateId');
      await _repository.createHabitFromTemplate(_userId, templateId);
      debugPrint('✅ [HabitsProvider] Habit created from template');
      await loadTodayHabits();
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error creating from template: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create habit from template: $e',
      );
    }
  }

  /// Update an existing habit
  Future<void> updateHabit(String habitId, HabitUpdate update) async {
    try {
      debugPrint('🎯 [HabitsProvider] Updating habit: $habitId');
      await _repository.updateHabit(_userId, habitId, update);
      debugPrint('✅ [HabitsProvider] Habit updated successfully');
      await loadTodayHabits();
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error updating habit: $e');
      state = state.copyWith(error: 'Failed to update habit: $e');
    }
  }

  /// Delete a habit
  Future<void> deleteHabit(String habitId) async {
    // Store for rollback
    final previousHabits = List<HabitWithStatus>.from(state.habits);

    // Optimistic delete
    final updatedHabits =
        state.habits.where((h) => h.id != habitId).toList();
    final newTotal = updatedHabits.length;
    final newCompleted = updatedHabits.where((h) => h.todayCompleted).length;

    state = state.copyWith(
      habits: updatedHabits,
      totalHabits: newTotal,
      completedToday: newCompleted,
      completionPercentage: newTotal > 0 ? (newCompleted / newTotal) * 100 : 0.0,
    );

    try {
      debugPrint('🎯 [HabitsProvider] Deleting habit: $habitId');
      await _repository.deleteHabit(_userId, habitId);
      debugPrint('✅ [HabitsProvider] Habit deleted successfully');
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error deleting habit, rolling back: $e');
      // Rollback
      state = state.copyWith(
        habits: previousHabits,
        totalHabits: previousHabits.length,
        completedToday:
            previousHabits.where((h) => h.todayCompleted).length,
        error: 'Failed to delete habit: $e',
      );
    }
  }

  /// Archive a habit (soft delete)
  Future<void> archiveHabit(String habitId) async {
    // Store for rollback
    final previousHabits = List<HabitWithStatus>.from(state.habits);

    // Optimistic archive (remove from list)
    final updatedHabits =
        state.habits.where((h) => h.id != habitId).toList();
    final newTotal = updatedHabits.length;
    final newCompleted = updatedHabits.where((h) => h.todayCompleted).length;

    state = state.copyWith(
      habits: updatedHabits,
      totalHabits: newTotal,
      completedToday: newCompleted,
      completionPercentage: newTotal > 0 ? (newCompleted / newTotal) * 100 : 0.0,
    );

    try {
      debugPrint('🎯 [HabitsProvider] Archiving habit: $habitId');
      await _repository.archiveHabit(_userId, habitId);
      debugPrint('✅ [HabitsProvider] Habit archived successfully');
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error archiving habit, rolling back: $e');
      // Rollback
      state = state.copyWith(
        habits: previousHabits,
        totalHabits: previousHabits.length,
        completedToday:
            previousHabits.where((h) => h.todayCompleted).length,
        error: 'Failed to archive habit: $e',
      );
    }
  }

  /// Reorder habits
  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final previousHabits = List<HabitWithStatus>.from(state.habits);

    // Optimistic reorder
    final reorderedHabits = List<HabitWithStatus>.from(state.habits);
    final habit = reorderedHabits.removeAt(oldIndex);
    reorderedHabits.insert(
        newIndex > oldIndex ? newIndex - 1 : newIndex, habit);

    // Update order values
    final withUpdatedOrder = reorderedHabits.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    state = state.copyWith(habits: withUpdatedOrder);

    try {
      debugPrint('🎯 [HabitsProvider] Reordering habits');
      final orderMap = {
        for (var h in withUpdatedOrder) h.id: h.order ?? 0,
      };
      await _repository.reorderHabits(_userId, orderMap);
      debugPrint('✅ [HabitsProvider] Habits reordered successfully');
    } catch (e) {
      debugPrint('❌ [HabitsProvider] Error reordering habits: $e');
      state = state.copyWith(
        habits: previousHabits,
        error: 'Failed to reorder habits: $e',
      );
    }
  }

  /// Refresh habits
  Future<void> refresh() async {
    await loadTodayHabits();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Main habits provider with user ID parameter
final habitsProvider =
    StateNotifierProvider.family<HabitsNotifier, HabitsState, String>(
  (ref, userId) => HabitsNotifier(
    ref.watch(habitRepositoryProvider),
    userId,
  ),
);

/// Habit templates provider
final habitTemplatesProvider =
    FutureProvider.autoDispose.family<List<HabitTemplate>, String?>(
  (ref, category) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitTemplates] Fetching templates, category: $category');
      final templates = await repository.getHabitTemplates(category: category);
      debugPrint('✅ [HabitTemplates] Fetched ${templates.length} templates');
      return templates;
    } catch (e) {
      debugPrint('❌ [HabitTemplates] Error: $e');
      return [];
    }
  },
);

/// Habit summary provider (aggregate stats)
final habitsSummaryProvider =
    FutureProvider.autoDispose.family<HabitsSummary, String>(
  (ref, userId) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitsSummary] Fetching summary for user $userId');
      final summary = await repository.getHabitsSummary(userId);
      debugPrint('✅ [HabitsSummary] Summary loaded');
      return summary;
    } catch (e) {
      debugPrint('❌ [HabitsSummary] Error: $e');
      rethrow;
    }
  },
);

/// Habit insights provider (AI-generated insights)
final habitInsightsProvider =
    FutureProvider.autoDispose.family<HabitInsights, String>(
  (ref, userId) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitInsights] Fetching insights for user $userId');
      final insights = await repository.getHabitInsights(userId);
      debugPrint('✅ [HabitInsights] Insights loaded');
      return insights;
    } catch (e) {
      debugPrint('❌ [HabitInsights] Error: $e');
      rethrow;
    }
  },
);

/// Weekly summary provider (7-day breakdown)
final habitWeeklySummaryProvider =
    FutureProvider.autoDispose.family<List<HabitWeeklySummary>, String>(
  (ref, userId) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitWeekly] Fetching weekly summary for user $userId');
      final summary = await repository.getWeeklySummary(userId);
      debugPrint('✅ [HabitWeekly] Weekly summary loaded: ${summary.length} days');
      return summary;
    } catch (e) {
      debugPrint('❌ [HabitWeekly] Error: $e');
      return [];
    }
  },
);

/// All habit streaks provider
final habitStreaksProvider =
    FutureProvider.autoDispose.family<List<HabitStreak>, String>(
  (ref, userId) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitStreaks] Fetching streaks for user $userId');
      final streaks = await repository.getAllStreaks(userId);
      debugPrint('✅ [HabitStreaks] Loaded ${streaks.length} streaks');
      return streaks;
    } catch (e) {
      debugPrint('❌ [HabitStreaks] Error: $e');
      return [];
    }
  },
);

/// Habit history provider (for a specific habit)
final habitHistoryProvider = FutureProvider.autoDispose
    .family<List<HabitLog>, ({String userId, String habitId, int days})>(
  (ref, params) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint(
          '🎯 [HabitHistory] Fetching history for habit ${params.habitId}');
      final history = await repository.getHabitHistory(
        params.userId,
        params.habitId,
        days: params.days,
      );
      debugPrint('✅ [HabitHistory] Loaded ${history.length} history entries');
      return history;
    } catch (e) {
      debugPrint('❌ [HabitHistory] Error: $e');
      return [];
    }
  },
);

/// Single habit detail provider
final habitDetailProvider =
    FutureProvider.autoDispose.family<HabitDetail?, ({String userId, String habitId})>(
  (ref, params) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [HabitDetail] Fetching habit ${params.habitId}');
      final detail = await repository.getHabitDetail(
        params.userId,
        params.habitId,
      );
      debugPrint('✅ [HabitDetail] Loaded habit detail');
      return detail;
    } catch (e) {
      debugPrint('❌ [HabitDetail] Error: $e');
      return null;
    }
  },
);

/// Archived habits provider
final archivedHabitsProvider =
    FutureProvider.autoDispose.family<List<HabitWithStatus>, String>(
  (ref, userId) async {
    final repository = ref.watch(habitRepositoryProvider);
    try {
      debugPrint('🎯 [ArchivedHabits] Fetching archived habits for $userId');
      final habits = await repository.getArchivedHabits(userId);
      debugPrint('✅ [ArchivedHabits] Loaded ${habits.length} archived habits');
      return habits;
    } catch (e) {
      debugPrint('❌ [ArchivedHabits] Error: $e');
      return [];
    }
  },
);

// ============================================
// Convenience Providers
// ============================================

/// Helper provider to get current user's habits
final currentUserHabitsProvider = Provider<AsyncValue<HabitsState>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(ref.watch(habitsProvider(userId)));
});

/// Helper provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.id;
});

/// Today's completion percentage (convenience)
final todayHabitCompletionProvider = Provider.family<double, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).completionPercentage;
});

/// Today's completed count (convenience)
final todayCompletedHabitsCountProvider = Provider.family<int, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).completedToday;
});

/// Total habits count (convenience)
final totalHabitsCountProvider = Provider.family<int, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).totalHabits;
});

/// All habits completed today (convenience)
final allHabitsCompletedProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).allCompleted;
});

/// Habits loading state (convenience)
final habitsLoadingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).isLoading;
});

/// Pending habits list (convenience)
final pendingHabitsProvider =
    Provider.family<List<HabitWithStatus>, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).pendingHabits;
});

/// Completed habits list (convenience)
final completedHabitsListProvider =
    Provider.family<List<HabitWithStatus>, String>((ref, userId) {
  return ref.watch(habitsProvider(userId)).completedHabits;
});

// ============================================
// Auto-Loading Provider
// ============================================

/// Auto-loading provider that loads habits when user ID is available
final habitDataProvider = FutureProvider.autoDispose<HabitsState?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    debugPrint('🎯 [HabitData] No user ID, skipping load');
    return null;
  }

  // Trigger the load
  final notifier = ref.read(habitsProvider(userId).notifier);
  await notifier.loadTodayHabits();

  return ref.read(habitsProvider(userId));
});
