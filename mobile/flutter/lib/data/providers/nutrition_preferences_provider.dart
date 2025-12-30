import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_preferences_repository.dart';
import '../services/api_client.dart';

// ============================================
// Nutrition Preferences State
// ============================================

/// Complete nutrition preferences state
class NutritionPreferencesState {
  final NutritionPreferences? preferences;
  final NutritionStreak? streak;
  final List<WeightLog> weightHistory;
  final WeightTrend? weightTrend;
  final DynamicNutritionTargets? dynamicTargets;
  final AdaptiveCalculation? adaptiveCalculation;
  final bool isLoading;
  final String? error;
  final bool onboardingCompleted;

  const NutritionPreferencesState({
    this.preferences,
    this.streak,
    this.weightHistory = const [],
    this.weightTrend,
    this.dynamicTargets,
    this.adaptiveCalculation,
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
  });

  NutritionPreferencesState copyWith({
    NutritionPreferences? preferences,
    NutritionStreak? streak,
    List<WeightLog>? weightHistory,
    WeightTrend? weightTrend,
    DynamicNutritionTargets? dynamicTargets,
    AdaptiveCalculation? adaptiveCalculation,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
    bool clearError = false,
  }) {
    return NutritionPreferencesState(
      preferences: preferences ?? this.preferences,
      streak: streak ?? this.streak,
      weightHistory: weightHistory ?? this.weightHistory,
      weightTrend: weightTrend ?? this.weightTrend,
      dynamicTargets: dynamicTargets ?? this.dynamicTargets,
      adaptiveCalculation: adaptiveCalculation ?? this.adaptiveCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Get current calorie target (dynamic if available, otherwise base)
  int get currentCalorieTarget =>
      dynamicTargets?.targetCalories ?? preferences?.targetCalories ?? 2000;

  /// Get current protein target
  int get currentProteinTarget =>
      dynamicTargets?.targetProteinG ?? preferences?.targetProteinG ?? 150;

  /// Get current carbs target
  int get currentCarbsTarget =>
      dynamicTargets?.targetCarbsG ?? preferences?.targetCarbsG ?? 200;

  /// Get current fat target
  int get currentFatTarget =>
      dynamicTargets?.targetFatG ?? preferences?.targetFatG ?? 65;

  /// Check if today is a training day
  bool get isTrainingDay => dynamicTargets?.isTrainingDay ?? false;

  /// Check if today is a fasting day (5:2, ADF)
  bool get isFastingDay => dynamicTargets?.isFastingDay ?? false;

  /// Get latest weight
  double? get latestWeight =>
      weightHistory.isNotEmpty ? weightHistory.first.weightKg : null;
}

// ============================================
// Nutrition Preferences Notifier
// ============================================

/// Nutrition preferences state notifier
class NutritionPreferencesNotifier extends StateNotifier<NutritionPreferencesState> {
  final NutritionPreferencesRepository _repository;
  final Ref _ref;

  NutritionPreferencesNotifier(this._repository, this._ref)
      : super(const NutritionPreferencesState());

  /// Initialize nutrition preferences for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🥗 [NutritionPrefsProvider] Initializing for $userId');

      // Load core data in parallel
      final results = await Future.wait([
        _repository.getPreferences(userId),
        _repository.getStreak(userId).catchError((_) => NutritionStreak(
              userId: userId,
              currentStreakDays: 0,
              longestStreakEver: 0,
              freezesAvailable: 2,
              freezesUsedThisWeek: 0,
              totalDaysLogged: 0,
              weeklyGoalEnabled: false,
              weeklyGoalDays: 5,
              daysLoggedThisWeek: 0,
            )),
        _repository.getWeightLogs(userId: userId, limit: 30).catchError((_) => <WeightLog>[]),
        _repository.getDynamicTargets(userId: userId).catchError((_) => const DynamicNutritionTargets()),
      ]);

      final preferences = results[0] as NutritionPreferences?;
      final streak = results[1] as NutritionStreak;
      final weightHistory = results[2] as List<WeightLog>;
      final dynamicTargets = results[3] as DynamicNutritionTargets?;

      // Get weight trend if we have enough data
      WeightTrend? weightTrend;
      if (weightHistory.length >= 2) {
        try {
          weightTrend = await _repository.getWeightTrend(userId: userId);
        } catch (e) {
          debugPrint('⚠️ [NutritionPrefsProvider] Could not get weight trend: $e');
        }
      }

      // Preserve onboardingCompleted if already true (avoid race condition)
      // This handles the case where completeOnboarding set it to true but
      // the backend fetch might return stale data momentarily
      final wasOnboardingCompleted = state.onboardingCompleted;
      final isOnboardingCompleted = preferences?.nutritionOnboardingCompleted ?? false;

      state = state.copyWith(
        preferences: preferences,
        streak: streak,
        weightHistory: weightHistory,
        weightTrend: weightTrend,
        dynamicTargets: dynamicTargets,
        isLoading: false,
        onboardingCompleted: wasOnboardingCompleted || isOnboardingCompleted,
      );

      debugPrint(
          '✅ [NutritionPrefsProvider] Initialized: onboarded=${state.onboardingCompleted} (backend=${isOnboardingCompleted}, was=$wasOnboardingCompleted), weights=${weightHistory.length}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Complete nutrition onboarding
  Future<void> completeOnboarding({
    required String userId,
    required NutritionGoal goal,
    RateOfChange? rateOfChange,
    required DietType dietType,
    List<FoodAllergen> allergies = const [],
    List<DietaryRestriction> restrictions = const [],
    required MealPattern mealPattern,
    int? fastingStartHour,
    int? fastingEndHour,
    CookingSkill cookingSkill = CookingSkill.intermediate,
    int cookingTimeMinutes = 30,
    BudgetLevel budgetLevel = BudgetLevel.moderate,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🎓 [NutritionPrefsProvider] Completing onboarding');
      final preferences = await _repository.completeOnboarding(
        userId: userId,
        goal: goal,
        rateOfChange: rateOfChange,
        dietType: dietType,
        allergies: allergies,
        restrictions: restrictions,
        mealPattern: mealPattern,
        fastingStartHour: fastingStartHour,
        fastingEndHour: fastingEndHour,
        cookingSkill: cookingSkill,
        cookingTimeMinutes: cookingTimeMinutes,
        budgetLevel: budgetLevel,
        customCarbPercent: customCarbPercent,
        customProteinPercent: customProteinPercent,
        customFatPercent: customFatPercent,
      );

      // Also get dynamic targets
      final dynamicTargets =
          await _repository.getDynamicTargets(userId: userId);

      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
        onboardingCompleted: true,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Onboarding completed');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Onboarding error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Save nutrition preferences
  Future<void> savePreferences({
    required String userId,
    required NutritionPreferences preferences,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('💾 [NutritionPrefsProvider] Saving preferences');
      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: preferences,
      );
      state = state.copyWith(preferences: saved, isLoading: false);
      debugPrint('✅ [NutritionPrefsProvider] Preferences saved');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Save preferences error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Log a weight entry
  Future<void> logWeight({
    required String userId,
    required double weightKg,
    DateTime? loggedAt,
    String? notes,
  }) async {
    try {
      debugPrint('⚖️ [NutritionPrefsProvider] Logging weight: $weightKg kg');
      final log = await _repository.logWeight(
        userId: userId,
        weightKg: weightKg,
        loggedAt: loggedAt,
        notes: notes,
      );

      // Update weight history
      final updatedHistory = [log, ...state.weightHistory];
      state = state.copyWith(weightHistory: updatedHistory);

      // Refresh weight trend if we have enough data
      if (updatedHistory.length >= 2) {
        try {
          final trend = await _repository.getWeightTrend(userId: userId);
          state = state.copyWith(weightTrend: trend);
        } catch (e) {
          debugPrint('⚠️ [NutritionPrefsProvider] Could not update trend: $e');
        }
      }

      debugPrint('✅ [NutritionPrefsProvider] Weight logged');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Log weight error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a weight log
  Future<void> deleteWeightLog({
    required String userId,
    required String logId,
  }) async {
    try {
      debugPrint('🗑️ [NutritionPrefsProvider] Deleting weight log $logId');
      await _repository.deleteWeightLog(userId: userId, logId: logId);

      // Remove from local state
      final updatedHistory =
          state.weightHistory.where((w) => w.id != logId).toList();
      state = state.copyWith(weightHistory: updatedHistory);

      debugPrint('✅ [NutritionPrefsProvider] Weight log deleted');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Delete weight error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh dynamic targets
  Future<void> refreshDynamicTargets(String userId) async {
    try {
      final targets = await _repository.getDynamicTargets(userId: userId);
      state = state.copyWith(dynamicTargets: targets);
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Refresh targets error: $e');
    }
  }

  /// Use a streak freeze
  Future<void> useStreakFreeze(String userId) async {
    try {
      debugPrint('🧊 [NutritionPrefsProvider] Using streak freeze');
      final streak = await _repository.useStreakFreeze(userId);
      state = state.copyWith(streak: streak);
      debugPrint('✅ [NutritionPrefsProvider] Streak freeze used');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Streak freeze error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Recalculate nutrition targets
  Future<void> recalculateTargets(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 [NutritionPrefsProvider] Recalculating targets');
      final preferences = await _repository.recalculateTargets(userId);
      final dynamicTargets =
          await _repository.getDynamicTargets(userId: userId);
      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Targets recalculated');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Recalculate error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Trigger adaptive calculation
  Future<void> calculateAdaptive(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🧮 [NutritionPrefsProvider] Calculating adaptive');
      final calculation = await _repository.calculateAdaptive(userId);
      state = state.copyWith(
        adaptiveCalculation: calculation,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Adaptive calculated: TDEE=${calculation.calculatedTdee}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Adaptive calculation error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Respond to weekly nutrition recommendation
  Future<void> respondToRecommendation({
    required String userId,
    required String recommendationId,
    required bool accepted,
  }) async {
    try {
      debugPrint('📝 [NutritionPrefsProvider] Responding to recommendation: accepted=$accepted');
      await _repository.respondToRecommendation(
        userId: userId,
        recommendationId: recommendationId,
        accepted: accepted,
      );

      // Refresh preferences if accepted
      if (accepted) {
        await initialize(userId);
      }

      debugPrint('✅ [NutritionPrefsProvider] Response saved');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Response error: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}

// ============================================
// Providers
// ============================================

/// Nutrition preferences state provider
final nutritionPreferencesProvider =
    StateNotifierProvider<NutritionPreferencesNotifier, NutritionPreferencesState>(
        (ref) {
  return NutritionPreferencesNotifier(
    ref.watch(nutritionPreferencesRepositoryProvider),
    ref,
  );
});

/// Nutrition onboarding completed provider (convenience)
final nutritionOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).onboardingCompleted;
});

/// Current calorie target provider (convenience)
final currentCalorieTargetProvider = Provider<int>((ref) {
  return ref.watch(nutritionPreferencesProvider).currentCalorieTarget;
});

/// Current protein target provider (convenience)
final currentProteinTargetProvider = Provider<int>((ref) {
  return ref.watch(nutritionPreferencesProvider).currentProteinTarget;
});

/// Is training day provider (convenience)
final isTrainingDayProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).isTrainingDay;
});

/// Is fasting day provider (for 5:2, ADF)
final isFastingDayProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).isFastingDay;
});

/// Latest weight provider (convenience)
final latestWeightProvider = Provider<double?>((ref) {
  return ref.watch(nutritionPreferencesProvider).latestWeight;
});

/// Weight trend direction provider
final weightTrendDirectionProvider = Provider<String>((ref) {
  return ref.watch(nutritionPreferencesProvider).weightTrend?.direction ?? 'maintaining';
});

/// Nutrition streak provider
final nutritionStreakProvider = Provider<NutritionStreak?>((ref) {
  return ref.watch(nutritionPreferencesProvider).streak;
});

/// Dynamic targets provider
final dynamicNutritionTargetsProvider = Provider<DynamicNutritionTargets?>((ref) {
  return ref.watch(nutritionPreferencesProvider).dynamicTargets;
});
