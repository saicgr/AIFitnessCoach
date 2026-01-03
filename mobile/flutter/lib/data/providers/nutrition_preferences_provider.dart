import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_preferences_repository.dart';

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

  NutritionPreferencesNotifier(this._repository)
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
          '✅ [NutritionPrefsProvider] Initialized: onboarded=${state.onboardingCompleted} (backend=$isOnboardingCompleted, was=$wasOnboardingCompleted), weights=${weightHistory.length}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Complete nutrition onboarding (supports multi-select goals)
  Future<void> completeOnboarding({
    required String userId,
    required List<NutritionGoal> goals, // Multi-select goals
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
    // Pre-calculated values from frontend to ensure consistency
    int? calculatedBmr,
    int? calculatedTdee,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🎓 [NutritionPrefsProvider] Completing onboarding with ${goals.length} goals');
      if (targetCalories != null) {
        debugPrint('🎓 [NutritionPrefsProvider] Using frontend-calculated values: $targetCalories cal');
      }
      final preferences = await _repository.completeOnboarding(
        userId: userId,
        goals: goals,
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
        calculatedBmr: calculatedBmr,
        calculatedTdee: calculatedTdee,
        targetCalories: targetCalories,
        targetProteinG: targetProteinG,
        targetCarbsG: targetCarbsG,
        targetFatG: targetFatG,
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

  /// Skip nutrition onboarding permanently
  /// This saves the skip to the database so the user won't see onboarding again
  Future<void> skipOnboarding({required String userId}) async {
    try {
      debugPrint('⏭️ [NutritionPrefsProvider] Skipping onboarding for user $userId');
      await _repository.skipOnboarding(userId: userId);
      state = state.copyWith(onboardingCompleted: true);
      debugPrint('✅ [NutritionPrefsProvider] Onboarding skipped');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Skip onboarding error: $e');
      // Still mark as completed in memory so user isn't bothered again this session
      state = state.copyWith(onboardingCompleted: true);
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

  /// Update nutrition targets (calories and macros)
  /// This allows users to manually edit their calorie/macro goals
  Future<void> updateTargets({
    required String userId,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
  }) async {
    if (state.preferences == null) {
      debugPrint('❌ [NutritionPrefsProvider] Cannot update targets: no preferences loaded');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('📝 [NutritionPrefsProvider] Updating targets: cal=$targetCalories, p=$targetProteinG, c=$targetCarbsG, f=$targetFatG');

      // Create updated preferences with new target values
      final updatedPreferences = state.preferences!.copyWith(
        targetCalories: targetCalories ?? state.preferences!.targetCalories,
        targetProteinG: targetProteinG ?? state.preferences!.targetProteinG,
        targetCarbsG: targetCarbsG ?? state.preferences!.targetCarbsG,
        targetFatG: targetFatG ?? state.preferences!.targetFatG,
      );

      // Save to backend
      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: updatedPreferences,
      );

      // Refresh dynamic targets as well
      final dynamicTargets = await _repository.getDynamicTargets(userId: userId);

      state = state.copyWith(
        preferences: saved,
        dynamicTargets: dynamicTargets,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Targets updated');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Update targets error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
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

// ============================================
// Nutrition UI Preferences Providers
// ============================================

/// Nutrition UI preferences state
class NutritionUIPreferencesState {
  final NutritionUIPreferences? preferences;
  final bool isLoading;
  final String? error;

  const NutritionUIPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
  });

  NutritionUIPreferencesState copyWith({
    NutritionUIPreferences? preferences,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NutritionUIPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get suggested meal type based on preferences and time
  String get suggestedMealType =>
      preferences?.suggestedMealType ?? 'breakfast';

  /// Check if AI tips are disabled
  bool get aiTipsDisabled => preferences?.disableAiTips ?? false;

  /// Check if quick log mode is enabled
  bool get quickLogEnabled => preferences?.quickLogMode ?? true;

  /// Check if compact tracker view is enabled
  bool get compactViewEnabled => preferences?.compactTrackerView ?? false;

  /// Check if macros should be shown on log
  bool get showMacrosOnLog => preferences?.showMacrosOnLog ?? true;
}

/// Nutrition UI preferences notifier
class NutritionUIPreferencesNotifier extends StateNotifier<NutritionUIPreferencesState> {
  final NutritionPreferencesRepository _repository;

  NutritionUIPreferencesNotifier(this._repository)
      : super(const NutritionUIPreferencesState());

  /// Load UI preferences for a user
  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔍 [NutritionUIPrefsProvider] Loading for $userId');
      final prefs = await _repository.getUIPreferences(userId);
      state = state.copyWith(preferences: prefs, isLoading: false);
      debugPrint('✅ [NutritionUIPrefsProvider] Loaded');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle AI tips on/off
  Future<void> toggleAiTips(bool disabled) async {
    if (state.preferences == null) return;
    try {
      debugPrint('🤖 [NutritionUIPrefsProvider] Setting AI tips disabled: $disabled');
      final updated = state.preferences!.copyWith(disableAiTips: disabled);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] AI tips updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set quick log mode
  Future<void> setQuickLogMode(bool enabled) async {
    if (state.preferences == null) return;
    try {
      debugPrint('⚡ [NutritionUIPrefsProvider] Setting quick log mode: $enabled');
      final updated = state.preferences!.copyWith(quickLogMode: enabled);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Quick log mode updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set compact view mode
  Future<void> setCompactView(bool compact) async {
    if (state.preferences == null) return;
    try {
      debugPrint('📐 [NutritionUIPrefsProvider] Setting compact view: $compact');
      final updated = state.preferences!.copyWith(compactTrackerView: compact);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Compact view updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set show macros on log
  Future<void> setShowMacrosOnLog(bool show) async {
    if (state.preferences == null) return;
    try {
      debugPrint('📊 [NutritionUIPrefsProvider] Setting show macros on log: $show');
      final updated = state.preferences!.copyWith(showMacrosOnLog: show);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Show macros updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set default meal type
  Future<void> setDefaultMealType(String mealType) async {
    if (state.preferences == null) return;
    try {
      debugPrint('🍽️ [NutritionUIPrefsProvider] Setting default meal type: $mealType');
      final updated = state.preferences!.copyWith(defaultMealType: mealType);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Default meal type updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update all preferences at once
  Future<void> updatePreferences(NutritionUIPreferences prefs) async {
    try {
      debugPrint('💾 [NutritionUIPrefsProvider] Updating all preferences');
      final saved = await _repository.updateUIPreferences(prefs);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Preferences updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reset to defaults
  Future<void> reset(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 [NutritionUIPrefsProvider] Resetting to defaults');
      final prefs = await _repository.resetUIPreferences(userId);
      state = state.copyWith(preferences: prefs, isLoading: false);
      debugPrint('✅ [NutritionUIPrefsProvider] Reset complete');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Reset error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Nutrition UI preferences provider
final nutritionUIPreferencesProvider =
    StateNotifierProvider<NutritionUIPreferencesNotifier, NutritionUIPreferencesState>(
        (ref) {
  return NutritionUIPreferencesNotifier(
    ref.watch(nutritionPreferencesRepositoryProvider),
  );
});

/// Provider for meal templates
final mealTemplatesProvider = FutureProvider.autoDispose.family<List<MealTemplate>, String?>((ref, mealType) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getTemplates(mealType: mealType);
});

/// Provider for all meal templates (no filter)
final allMealTemplatesProvider = FutureProvider.autoDispose<List<MealTemplate>>((ref) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getTemplates();
});

/// Provider for quick suggestions
final quickSuggestionsProvider = FutureProvider.autoDispose.family<List<QuickSuggestion>, String?>((ref, mealType) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getQuickSuggestions(mealType: mealType);
});

/// Provider for food search results
final foodSearchProvider = FutureProvider.autoDispose.family<List<FoodSearchResult>, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.searchFoods(query);
});

/// Convenience provider for AI tips disabled state
final aiTipsDisabledProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).aiTipsDisabled;
});

/// Convenience provider for quick log mode
final quickLogModeProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).quickLogEnabled;
});

/// Convenience provider for compact view mode
final compactTrackerViewProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).compactViewEnabled;
});

/// Convenience provider for suggested meal type
final suggestedMealTypeProvider = Provider<String>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).suggestedMealType;
});
