import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../repositories/weekly_plan_repository.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/cache/cache_first_mixin.dart';

/// Sentinel thrown by the cache-first fetch when the user has no plan for the
/// current week. Routed through [CacheFirstMixin]'s `onError` so a genuine
/// "no plan" state is distinguished from a network failure.
class _NoPlanException implements Exception {
  const _NoPlanException();
  @override
  String toString() => 'No weekly plan for the current week';
}

/// State class for weekly plan
class WeeklyPlanState {
  final WeeklyPlan? currentPlan;
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final DailyPlanEntry? selectedDayEntry;

  const WeeklyPlanState({
    this.currentPlan,
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.selectedDayEntry,
  });

  WeeklyPlanState copyWith({
    WeeklyPlan? currentPlan,
    bool? isLoading,
    bool? isGenerating,
    String? error,
    DailyPlanEntry? selectedDayEntry,
    bool clearError = false,
    bool clearPlan = false,
    bool clearSelectedDay = false,
  }) {
    return WeeklyPlanState(
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      selectedDayEntry: clearSelectedDay ? null : (selectedDayEntry ?? this.selectedDayEntry),
    );
  }
}

/// Weekly plan notifier
///
/// Cache-first: [loadCurrentPlan] seeds the screen from a disk-persisted blob
/// (via [CacheFirstMixin]) before the network fetch, so a cold app start
/// renders the last-known plan instantly instead of a blocking spinner.
class WeeklyPlanNotifier extends StateNotifier<WeeklyPlanState>
    with CacheFirstMixin {
  final WeeklyPlanRepository _repository;
  final Ref _ref;

  WeeklyPlanNotifier(this._repository, this._ref)
      : super(const WeeklyPlanState());

  String? get _userId => _ref.read(currentUserIdProvider);

  /// Cache-first SWR load of the current week's plan.
  ///
  /// Emits the cached plan (if any) synchronously-fast, then revalidates from
  /// the network. A network failure keeps a cached plan on screen; only a
  /// cold-cache failure surfaces an error.
  Future<void> loadCurrentPlan() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Not logged in');
      return;
    }

    // Only show the loading flag when there is genuinely nothing to show yet —
    // a returning user keeps the cached plan visible while we revalidate.
    if (state.currentPlan == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    var sawAnyValue = false;
    await loadCacheFirst<WeeklyPlan>(
      cacheKey: 'weekly_plan_current',
      userId: userId,
      // 24h TTL — the plan is week-scoped; a stale read still beats a spinner
      // and the network revalidate immediately corrects it.
      ttl: const Duration(hours: 24),
      schemaVersion: 1,
      fetch: () async {
        final plan = await _repository.getCurrentWeekPlan(userId);
        // CacheFirstMixin requires a non-null T. A genuinely-null plan (user
        // has no plan) is surfaced via [_NoPlanException] so we never write a
        // bogus blob and the UI falls through to the empty state.
        if (plan == null) throw const _NoPlanException();
        return plan;
      },
      decode: WeeklyPlan.fromJson,
      encode: (p) => p.toJson(),
      emit: (plan, {required bool fromCache}) {
        sawAnyValue = true;
        if (!mounted) return;
        state = state.copyWith(
          currentPlan: plan,
          isLoading: false,
        );
        debugPrint(
            '📅 [WeeklyPlanProvider] ${fromCache ? 'cache' : 'network'} '
            'plan: ${plan.id}');
      },
      onError: (e, st) {
        if (!mounted) return;
        if (e is _NoPlanException) {
          // Not an error — the user simply has no plan this week. Clear any
          // cached plan and let the screen render its empty state.
          state = state.copyWith(isLoading: false, clearPlan: true);
          unawaited(invalidateCacheFirst(
            cacheKey: 'weekly_plan_current',
            userId: userId,
          ));
          return;
        }
        debugPrint('❌ [WeeklyPlanProvider] Error loading plan: $e');
        // Keep a cached plan on screen if we already emitted one.
        if (state.currentPlan != null) {
          state = state.copyWith(isLoading: false);
        } else {
          state = state.copyWith(isLoading: false, error: e.toString());
        }
      },
    );
    // Defensive: if nothing emitted and no error path ran, drop the spinner.
    if (!sawAnyValue && state.isLoading && mounted) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Generate a new weekly plan
  Future<WeeklyPlan?> generatePlan({
    required List<int> workoutDays,
    String? fastingProtocol,
    required String nutritionStrategy,
    String? preferredWorkoutTime,
    List<String>? goals,
  }) async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Not logged in');
      return null;
    }

    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final plan = await _repository.generateWeeklyPlan(
        userId: userId,
        workoutDays: workoutDays,
        fastingProtocol: fastingProtocol,
        nutritionStrategy: nutritionStrategy,
        preferredWorkoutTime: preferredWorkoutTime,
        goals: goals,
      );

      state = state.copyWith(
        currentPlan: plan,
        isGenerating: false,
      );

      // Drop the stale cached plan; the next loadCurrentPlan() repopulates the
      // disk blob with this freshly-generated plan via its write-through.
      unawaited(invalidateCacheFirst(
        cacheKey: 'weekly_plan_current',
        userId: userId,
      ));

      debugPrint('✅ [WeeklyPlanProvider] Generated plan: ${plan.id}');
      return plan;
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error generating plan: $e');
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Select a day entry for detailed view
  void selectDay(DailyPlanEntry entry) {
    state = state.copyWith(selectedDayEntry: entry);
  }

  /// Clear selected day
  void clearSelectedDay() {
    state = state.copyWith(clearSelectedDay: true);
  }

  /// Mark workout as completed for a day
  Future<void> markWorkoutCompleted(DateTime date) async {
    final userId = _userId;
    final plan = state.currentPlan;
    if (userId == null || plan == null) return;

    try {
      final updatedEntry = await _repository.updateDailyPlan(
        planId: plan.id,
        userId: userId,
        date: date,
        workoutCompleted: true,
      );

      // Update the plan's daily entries
      final updatedEntries = plan.dailyEntries.map((e) {
        if (e.planDate.year == date.year &&
            e.planDate.month == date.month &&
            e.planDate.day == date.day) {
          return updatedEntry;
        }
        return e;
      }).toList();

      state = state.copyWith(
        currentPlan: WeeklyPlan(
          id: plan.id,
          userId: plan.userId,
          weekStartDate: plan.weekStartDate,
          status: plan.status,
          workoutDays: plan.workoutDays,
          fastingProtocol: plan.fastingProtocol,
          nutritionStrategy: plan.nutritionStrategy,
          baseCalorieTarget: plan.baseCalorieTarget,
          baseProteinTargetG: plan.baseProteinTargetG,
          baseCarbsTargetG: plan.baseCarbsTargetG,
          baseFatTargetG: plan.baseFatTargetG,
          generatedAt: plan.generatedAt,
          aiModelUsed: plan.aiModelUsed,
          dailyEntries: updatedEntries,
          createdAt: plan.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      // The cached plan is now stale; drop it so the next cold start refetches.
      unawaited(invalidateCacheFirst(
        cacheKey: 'weekly_plan_current',
        userId: userId,
      ));
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error marking workout complete: $e');
    }
  }

  /// Mark nutrition as logged for a day
  Future<void> markNutritionLogged(DateTime date) async {
    final userId = _userId;
    final plan = state.currentPlan;
    if (userId == null || plan == null) return;

    try {
      final updatedEntry = await _repository.updateDailyPlan(
        planId: plan.id,
        userId: userId,
        date: date,
        nutritionLogged: true,
      );

      // Update the plan's daily entries
      final updatedEntries = plan.dailyEntries.map((e) {
        if (e.planDate.year == date.year &&
            e.planDate.month == date.month &&
            e.planDate.day == date.day) {
          return updatedEntry;
        }
        return e;
      }).toList();

      state = state.copyWith(
        currentPlan: WeeklyPlan(
          id: plan.id,
          userId: plan.userId,
          weekStartDate: plan.weekStartDate,
          status: plan.status,
          workoutDays: plan.workoutDays,
          fastingProtocol: plan.fastingProtocol,
          nutritionStrategy: plan.nutritionStrategy,
          baseCalorieTarget: plan.baseCalorieTarget,
          baseProteinTargetG: plan.baseProteinTargetG,
          baseCarbsTargetG: plan.baseCarbsTargetG,
          baseFatTargetG: plan.baseFatTargetG,
          generatedAt: plan.generatedAt,
          aiModelUsed: plan.aiModelUsed,
          dailyEntries: updatedEntries,
          createdAt: plan.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      // The cached plan is now stale; drop it so the next cold start refetches.
      unawaited(invalidateCacheFirst(
        cacheKey: 'weekly_plan_current',
        userId: userId,
      ));
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error marking nutrition logged: $e');
    }
  }

  /// Mark fasting as completed for a day
  Future<void> markFastingCompleted(DateTime date) async {
    final userId = _userId;
    final plan = state.currentPlan;
    if (userId == null || plan == null) return;

    try {
      final updatedEntry = await _repository.updateDailyPlan(
        planId: plan.id,
        userId: userId,
        date: date,
        fastingCompleted: true,
      );

      // Update the plan's daily entries
      final updatedEntries = plan.dailyEntries.map((e) {
        if (e.planDate.year == date.year &&
            e.planDate.month == date.month &&
            e.planDate.day == date.day) {
          return updatedEntry;
        }
        return e;
      }).toList();

      state = state.copyWith(
        currentPlan: WeeklyPlan(
          id: plan.id,
          userId: plan.userId,
          weekStartDate: plan.weekStartDate,
          status: plan.status,
          workoutDays: plan.workoutDays,
          fastingProtocol: plan.fastingProtocol,
          nutritionStrategy: plan.nutritionStrategy,
          baseCalorieTarget: plan.baseCalorieTarget,
          baseProteinTargetG: plan.baseProteinTargetG,
          baseCarbsTargetG: plan.baseCarbsTargetG,
          baseFatTargetG: plan.baseFatTargetG,
          generatedAt: plan.generatedAt,
          aiModelUsed: plan.aiModelUsed,
          dailyEntries: updatedEntries,
          createdAt: plan.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      // The cached plan is now stale; drop it so the next cold start refetches.
      unawaited(invalidateCacheFirst(
        cacheKey: 'weekly_plan_current',
        userId: userId,
      ));
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error marking fasting completed: $e');
    }
  }

  /// Regenerate meal suggestions for a day
  Future<List<MealSuggestion>?> regenerateMealSuggestions(
    DailyPlanEntry entry,
  ) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final suggestions = await _repository.generateMealSuggestions(
        userId: userId,
        planDate: entry.planDate,
        dayType: entry.dayType.name,
        calorieTarget: entry.calorieTarget,
        proteinTargetG: entry.proteinTargetG,
        eatingWindowStart: entry.eatingWindowStart,
        eatingWindowEnd: entry.eatingWindowEnd,
        workoutTime: entry.workoutTime,
      );

      return suggestions;
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error regenerating meals: $e');
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear the current plan
  void clearPlan() {
    state = state.copyWith(clearPlan: true);
  }
}

/// Weekly plan state provider
final weeklyPlanProvider =
    StateNotifierProvider<WeeklyPlanNotifier, WeeklyPlanState>((ref) {
  // Plan §6: recreate on user_id change so one user's plan isn't shown to
  // another.
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return WeeklyPlanNotifier(
    ref.watch(weeklyPlanRepositoryProvider),
    ref,
  );
});

/// Today's plan entry provider (convenience)
final todayPlanEntryProvider = Provider<DailyPlanEntry?>((ref) {
  final planState = ref.watch(weeklyPlanProvider);
  return planState.currentPlan?.todayEntry;
});

/// Current week has plan provider
final hasCurrentWeekPlanProvider = Provider<bool>((ref) {
  final planState = ref.watch(weeklyPlanProvider);
  return planState.currentPlan != null && planState.currentPlan!.isCurrentWeek;
});

/// Plan loading state provider
final isPlanLoadingProvider = Provider<bool>((ref) {
  return ref.watch(weeklyPlanProvider).isLoading;
});

/// Plan generating state provider
final isPlanGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(weeklyPlanProvider).isGenerating;
});
