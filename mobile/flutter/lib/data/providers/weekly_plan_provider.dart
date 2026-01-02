import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../repositories/weekly_plan_repository.dart';
import '../../core/providers/auth_provider.dart';

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
class WeeklyPlanNotifier extends StateNotifier<WeeklyPlanState> {
  final WeeklyPlanRepository _repository;
  final Ref _ref;

  WeeklyPlanNotifier(this._repository, this._ref)
      : super(const WeeklyPlanState());

  String? get _userId => _ref.read(currentUserIdProvider);

  /// Load the current week's plan
  Future<void> loadCurrentPlan() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Not logged in');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final plan = await _repository.getCurrentWeekPlan(userId);
      state = state.copyWith(
        currentPlan: plan,
        isLoading: false,
      );
      debugPrint('📅 [WeeklyPlanProvider] Loaded plan: ${plan?.id}');
    } catch (e) {
      debugPrint('❌ [WeeklyPlanProvider] Error loading plan: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
