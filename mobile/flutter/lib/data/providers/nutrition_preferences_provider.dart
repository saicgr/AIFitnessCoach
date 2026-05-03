import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_preferences_repository.dart';

/// SharedPreferences key prefix for the one-time targets-recalc migration.
/// We bumped the rate→deficit table on this date (the textbook
/// `kg/wk × 7700 / 7` rule); existing users with stale `target_calories`
/// (e.g. 2884 for a 100kg → 75kg @ 1.0 kg/wk profile) need a one-shot
/// re-derive on next app open. Stored per-user so an account switch
/// triggers a fresh check.
const String _targetsRecalcV2DonePrefPrefix = 'nutrition_targets_recalc_v2_done_';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
NutritionPreferencesState? _nutritionPrefsInMemoryCache;

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

  /// Set when the one-time targets-recalc migration ran AND actually changed
  /// the stored daily calorie target (delta != 0). NutritionScreen reads this
  /// on mount, shows a SnackBar like "Updated your daily target: 1580 cal/day
  /// (was 2884) — Review", then clears it via `consumePendingMigrationDelta`.
  /// Null when no migration was needed or the recalc happened to land on the
  /// same number.
  final ({int oldCalories, int newCalories})? pendingMigrationDelta;

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
    this.pendingMigrationDelta,
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
    ({int oldCalories, int newCalories})? pendingMigrationDelta,
    bool clearPendingMigrationDelta = false,
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
      pendingMigrationDelta: clearPendingMigrationDelta
          ? null
          : (pendingMigrationDelta ?? this.pendingMigrationDelta),
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

  // De-dupe guards. Without these, every widget that mounts and sees
  // `prefs == null && !isLoading` re-fires initialize(), and for users with
  // no nutrition prefs row that condition stays true after each call —
  // hammering the 4-endpoint init at frame rate (HTTP 429 storm).
  Future<void>? _inFlightInit;
  bool _initAttempted = false;

  NutritionPreferencesNotifier(this._repository)
      : super(_nutritionPrefsInMemoryCache ?? const NutritionPreferencesState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _nutritionPrefsInMemoryCache = null;
    debugPrint('🧹 [NutritionPrefsProvider] In-memory cache cleared');
  }

  /// Initialize nutrition preferences for a user.
  /// Set [forceRefresh] to bypass the in-memory cache and re-fetch from backend.
  Future<void> initialize(String userId, {bool forceRefresh = false}) async {
    // Coalesce concurrent callers onto the same future.
    if (_inFlightInit != null) return _inFlightInit;

    if (!forceRefresh) {
      // Skip re-initialization if already loaded and onboarding is complete
      // The in-memory flag is preserved once set
      if (state.preferences != null && state.onboardingCompleted) {
        debugPrint('🥗 [NutritionPrefsProvider] Already initialized and onboarding complete, skipping');
        return;
      }

      // Also skip if we already have preferences with backend flag set
      // This handles the case where we navigated away and back
      if (state.preferences?.nutritionOnboardingCompleted == true) {
        debugPrint('🥗 [NutritionPrefsProvider] Backend flag says complete, skipping reinit');
        if (!state.onboardingCompleted) {
          state = state.copyWith(onboardingCompleted: true);
        }
        return;
      }

      // Already attempted at least once this session and prefs are still
      // null (user has no row). Don't re-fetch unless forceRefresh — caller
      // must opt in to a retry.
      if (_initAttempted) {
        debugPrint('🥗 [NutritionPrefsProvider] Init already attempted, skipping (use forceRefresh to retry)');
        return;
      }
    }

    final future = _runInitialize(userId);
    _inFlightInit = future;
    try {
      await future;
    } finally {
      _inFlightInit = null;
      _initAttempted = true;
    }
  }

  Future<void> _runInitialize(String userId) async {
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
        _repository.getDynamicTargets(userId: userId, date: DateTime.now()).catchError((_) => const DynamicNutritionTargets()),
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

      // Use backend flag as source of truth, preserve in-memory if already set
      final wasOnboardingCompleted = state.onboardingCompleted;
      final backendOnboardingCompleted = preferences?.nutritionOnboardingCompleted ?? false;

      state = state.copyWith(
        preferences: preferences,
        streak: streak,
        weightHistory: weightHistory,
        weightTrend: weightTrend,
        dynamicTargets: dynamicTargets,
        isLoading: false,
        onboardingCompleted: wasOnboardingCompleted || backendOnboardingCompleted,
      );
      // Update in-memory cache for instant access on provider recreation
      _nutritionPrefsInMemoryCache = state;

      debugPrint(
          '✅ [NutritionPrefsProvider] Initialized: onboarded=${state.onboardingCompleted} (backend=$backendOnboardingCompleted, was=$wasOnboardingCompleted), weights=${weightHistory.length}');

      // One-time targets-recalc migration. The rate→deficit table changed
      // (slow/moderate/fast/aggressive now map to 275/550/825/1100 cal/d
      // instead of 250/500/750 with no "fast" entry). Existing users who
      // completed onboarding before this fix have stale `target_calories`.
      // Re-derive once, silently. Surfaces a SnackBar via
      // `pendingMigrationDelta` when the new target differs.
      await _maybeRunTargetsRecalcV2(userId);
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// One-shot recalc for users whose `target_calories` was computed under the
  /// old rate→deficit table. Eligible: lose_fat or build_muscle goals with a
  /// non-null rate_of_change. Idempotent — gated by a per-user
  /// SharedPreferences flag.
  Future<void> _maybeRunTargetsRecalcV2(String userId) async {
    try {
      final prefs = state.preferences;
      if (prefs == null) return;
      final goal = prefs.primaryGoalEnum;
      final rate = prefs.rateOfChange;
      // Only weight-changing goals depend on the rate-derived deficit.
      if (goal != NutritionGoal.loseFat && goal != NutritionGoal.buildMuscle) {
        return;
      }
      if (rate == null || rate.isEmpty) return;
      // Skip when TDEE isn't available — recalc would no-op or fail anyway.
      if ((prefs.calculatedTdee ?? 0) <= 0) return;

      final spref = await SharedPreferences.getInstance();
      final flagKey = '$_targetsRecalcV2DonePrefPrefix$userId';
      if (spref.getBool(flagKey) == true) return;

      final oldCal = prefs.targetCalories ?? 0;
      debugPrint('🔁 [NutritionPrefsProvider] Running v2 targets recalc (old=$oldCal cal)');

      final updated = await _repository.recalculateTargets(userId);
      final newCal = updated.targetCalories ?? oldCal;

      // Always set the flag — even if the new number happens to match the
      // old, we don't want to keep re-running the recalc on every cold start.
      await spref.setBool(flagKey, true);

      _nutritionPrefsInMemoryCache = state.copyWith(
        preferences: updated,
        // Only show the banner when the number actually moved enough to
        // matter. < 25 cal isn't worth interrupting the user over.
        pendingMigrationDelta: (oldCal > 0 && (newCal - oldCal).abs() >= 25)
            ? (oldCalories: oldCal, newCalories: newCal)
            : null,
      );
      state = _nutritionPrefsInMemoryCache!;

      debugPrint('✅ [NutritionPrefsProvider] v2 recalc done: $oldCal → $newCal cal');
    } catch (e) {
      // Don't block app start on this — surface in logs only. The user can
      // still tap "Recalculate from profile" in EditTargetsSheet manually.
      debugPrint('⚠️ [NutritionPrefsProvider] v2 recalc failed (will retry next launch): $e');
    }
  }

  /// Called by NutritionScreen after it has shown the one-time migration
  /// SnackBar. Clears the pending delta so it doesn't re-fire on rebuild.
  void consumePendingMigrationDelta() {
    if (state.pendingMigrationDelta == null) return;
    state = state.copyWith(clearPendingMigrationDelta: true);
    _nutritionPrefsInMemoryCache = state;
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

      // Also get dynamic targets (pass local date to avoid timezone mismatch with server UTC)
      final dynamicTargets =
          await _repository.getDynamicTargets(userId: userId, date: DateTime.now());

      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
        onboardingCompleted: true,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Onboarding completed (saved to backend)');
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
      debugPrint('✅ [NutritionPrefsProvider] Onboarding skipped (saved to backend)');
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

  /// Force-reload preferences from backend, bypassing the skip-if-already-loaded logic.
  /// Use this after calculate-nutrition-targets so the Profile card reflects the new goal/macros.
  Future<void> forceRefreshPreferences(String userId) async {
    try {
      debugPrint('🔄 [NutritionPrefsProvider] Force-refreshing preferences for $userId');
      final results = await Future.wait([
        _repository.getPreferences(userId),
        _repository.getDynamicTargets(userId: userId, date: DateTime.now()).catchError((_) => const DynamicNutritionTargets()),
      ]);
      final preferences = results[0] as NutritionPreferences?;
      final dynamicTargets = results[1] as DynamicNutritionTargets?;
      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
      );
      _nutritionPrefsInMemoryCache = state;
      debugPrint('✅ [NutritionPrefsProvider] Force-refresh done: goal=${preferences?.nutritionGoals}, cal=${preferences?.targetCalories}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Force-refresh error: $e');
    }
  }

  /// Refresh dynamic targets
  Future<void> refreshDynamicTargets(String userId) async {
    try {
      final targets = await _repository.getDynamicTargets(userId: userId, date: DateTime.now());
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
          await _repository.getDynamicTargets(userId: userId, date: DateTime.now());
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
    int? customProteinPercent,
    int? customCarbPercent,
    int? customFatPercent,
    String? rateOfChange,
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
        customProteinPercent: customProteinPercent ?? state.preferences!.customProteinPercent,
        customCarbPercent: customCarbPercent ?? state.preferences!.customCarbPercent,
        customFatPercent: customFatPercent ?? state.preferences!.customFatPercent,
        rateOfChange: rateOfChange ?? state.preferences!.rateOfChange,
      );

      // Save to backend
      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: updatedPreferences,
      );

      // Refresh dynamic targets as well (pass local date to avoid timezone mismatch)
      final dynamicTargets = await _repository.getDynamicTargets(userId: userId, date: DateTime.now());

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

  /// Record that weekly check-in was completed
  Future<void> recordWeeklyCheckin({required String userId}) async {
    if (state.preferences == null) {
      debugPrint('❌ [NutritionPrefsProvider] Cannot record check-in: no preferences loaded');
      return;
    }

    try {
      debugPrint('📅 [NutritionPrefsProvider] Recording weekly check-in completion');
      final updatedPreferences = state.preferences!.copyWith(
        lastWeeklyCheckinAt: DateTime.now(),
        weeklyCheckinDismissCount: 0,
      );

      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: updatedPreferences,
      );
      state = state.copyWith(preferences: saved);

      debugPrint('✅ [NutritionPrefsProvider] Weekly check-in recorded, dismiss counter reset');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Record check-in error: $e');
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
