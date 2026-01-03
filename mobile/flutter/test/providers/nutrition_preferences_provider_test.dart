import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/nutrition_preferences.dart';
import 'package:fitwiz/data/providers/nutrition_preferences_provider.dart';
import 'package:fitwiz/data/repositories/nutrition_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionPreferencesState', () {
    test('should have default values', () {
      const state = NutritionPreferencesState();

      expect(state.preferences, isNull);
      expect(state.streak, isNull);
      expect(state.weightHistory, isEmpty);
      expect(state.weightTrend, isNull);
      expect(state.dynamicTargets, isNull);
      expect(state.adaptiveCalculation, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.onboardingCompleted, false);
    });

    test('copyWith should preserve values when not specified', () {
      const state = NutritionPreferencesState(
        isLoading: true,
        onboardingCompleted: true,
      );

      final newState = state.copyWith();

      expect(newState.isLoading, true);
      expect(newState.onboardingCompleted, true);
    });

    test('copyWith should update specified values', () {
      const state = NutritionPreferencesState(
        isLoading: true,
        onboardingCompleted: false,
      );

      final newState = state.copyWith(
        isLoading: false,
        onboardingCompleted: true,
      );

      expect(newState.isLoading, false);
      expect(newState.onboardingCompleted, true);
    });

    test('copyWith should clear error when clearError is true', () {
      const state = NutritionPreferencesState(
        error: 'Some error',
      );

      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
    });

    test('currentCalorieTarget should use dynamic targets when available', () {
      final state = NutritionPreferencesState(
        preferences: const NutritionPreferences(
          userId: 'test-user',
          targetCalories: 2000,
        ),
        dynamicTargets: const DynamicNutritionTargets(targetCalories: 2200),
      );

      expect(state.currentCalorieTarget, 2200);
    });

    test('currentCalorieTarget should fallback to preferences', () {
      final state = NutritionPreferencesState(
        preferences: const NutritionPreferences(
          userId: 'test-user',
          targetCalories: 2000,
        ),
      );

      expect(state.currentCalorieTarget, 2000);
    });

    test('currentCalorieTarget should return default when nothing set', () {
      const state = NutritionPreferencesState();

      expect(state.currentCalorieTarget, 2000);
    });

    test('onboardingCompleted should be preserved in copyWith', () {
      const state = NutritionPreferencesState(onboardingCompleted: true);

      final newState = state.copyWith(isLoading: true);

      expect(newState.onboardingCompleted, true);
    });

    test('latestWeight should return null when no weight history', () {
      const state = NutritionPreferencesState();

      expect(state.latestWeight, isNull);
    });

    test('isTrainingDay should default to false', () {
      const state = NutritionPreferencesState();

      expect(state.isTrainingDay, false);
    });

    test('isFastingDay should default to false', () {
      const state = NutritionPreferencesState();

      expect(state.isFastingDay, false);
    });
  });

  group('NutritionPreferences model', () {
    test('should correctly read nutritionOnboardingCompleted', () {
      const prefs = NutritionPreferences(
        userId: 'test-user',
        nutritionOnboardingCompleted: true,
      );

      expect(prefs.nutritionOnboardingCompleted, true);
    });

    test('should default nutritionOnboardingCompleted to false', () {
      const prefs = NutritionPreferences(userId: 'test-user');

      expect(prefs.nutritionOnboardingCompleted, false);
    });

    test('should correctly read targetCalories', () {
      const prefs = NutritionPreferences(
        userId: 'test-user',
        targetCalories: 2500,
      );

      expect(prefs.targetCalories, 2500);
    });
  });

  group('Onboarding state logic', () {
    test('state should reflect onboardingCompleted correctly', () {
      // When onboardingCompleted is false
      const stateIncomplete = NutritionPreferencesState(
        onboardingCompleted: false,
        preferences: NutritionPreferences(
          userId: 'test-user',
          nutritionOnboardingCompleted: false,
        ),
      );

      expect(stateIncomplete.onboardingCompleted, false);

      // When onboardingCompleted is true
      const stateComplete = NutritionPreferencesState(
        onboardingCompleted: true,
        preferences: NutritionPreferences(
          userId: 'test-user',
          nutritionOnboardingCompleted: true,
        ),
      );

      expect(stateComplete.onboardingCompleted, true);
    });

    test('preserving onboardingCompleted in copyWith', () {
      // Simulating: wasOnboardingCompleted || isOnboardingCompleted
      const state = NutritionPreferencesState(
        onboardingCompleted: true,
      );

      // Simulating what happens when backend returns stale data
      final newState = state.copyWith(
        preferences: const NutritionPreferences(
          userId: 'test-user',
          nutritionOnboardingCompleted: false, // Stale backend data
        ),
        // But we preserve the existing true value by not overwriting onboardingCompleted
        // onboardingCompleted: wasOnboardingCompleted || isOnboardingCompleted
      );

      // State should still have preferences, and onboardingCompleted preserved
      expect(newState.preferences?.nutritionOnboardingCompleted, false);
      expect(newState.onboardingCompleted, true); // Preserved from original state
    });
  });

  group('Provider convenience accessors', () {
    test('nutritionOnboardingCompletedProvider returns false by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isCompleted = container.read(nutritionOnboardingCompletedProvider);
      expect(isCompleted, false);
    });

    test('currentCalorieTargetProvider returns default 2000', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final calories = container.read(currentCalorieTargetProvider);
      expect(calories, 2000);
    });

    test('currentProteinTargetProvider returns default 150', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final protein = container.read(currentProteinTargetProvider);
      expect(protein, 150);
    });

    test('isTrainingDayProvider returns false by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isTraining = container.read(isTrainingDayProvider);
      expect(isTraining, false);
    });
  });

  group('DynamicNutritionTargets', () {
    test('should create with default values', () {
      const targets = DynamicNutritionTargets();

      expect(targets.targetCalories, 2000);
      expect(targets.isTrainingDay, false);
      expect(targets.isFastingDay, false);
    });

    test('should override base values when set', () {
      const targets = DynamicNutritionTargets(
        targetCalories: 2500,
        isTrainingDay: true,
      );

      expect(targets.targetCalories, 2500);
      expect(targets.isTrainingDay, true);
    });
  });
}
