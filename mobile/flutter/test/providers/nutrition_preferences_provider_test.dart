import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/nutrition_preferences.dart';
import 'package:fitwiz/data/providers/nutrition_preferences_provider.dart';
import 'package:fitwiz/data/repositories/nutrition_preferences_repository.dart';
import 'package:fitwiz/data/services/api_client.dart' show ApiClient;

/// A container whose [nutritionPreferencesProvider] is a real notifier holding
/// the real initial state — but built WITHOUT walking the live dependency
/// chain (`authStateProvider` → `authRepositoryProvider` → `apiClientProvider`
/// → `ApiClient.startAuthListener()` → `Supabase.instance`). A unit test never
/// initialises Supabase, so reading any convenience accessor used to blow up on
/// that assertion. The `ApiClient` object itself is Supabase-free to construct;
/// only the provider body's auth-listener side effect is not, and these tests
/// never issue a request.
ProviderContainer _container() => ProviderContainer(
      overrides: [
        nutritionPreferencesProvider.overrideWith(
          (ref) => NutritionPreferencesNotifier(
            NutritionPreferencesRepository(ApiClient(const FlutterSecureStorage())),
          ),
        ),
      ],
    );

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

    // NOT a fallback to 2000 — nullable by design. A fabricated default let an
    // unconfigured target masquerade as a real plan on any surface that forgot
    // to check `hasConfiguredTargets`, so the magic number was removed and the
    // type made nullable to force every consumer to handle "no plan set".
    test('currentCalorieTarget should be null when nothing set', () {
      const state = NutritionPreferencesState();

      expect(state.currentCalorieTarget, isNull);
      expect(state.hasConfiguredTargets, isFalse);
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
      final container = _container();
      addTearDown(container.dispose);

      final isCompleted = container.read(nutritionOnboardingCompletedProvider);
      expect(isCompleted, false);
    });

    // Nullable, NOT 2000 — the provider mirrors
    // `NutritionPreferencesState.currentCalorieTarget`, which deliberately has
    // no magic-number fallback. Presenting surfaces must gate on
    // `hasConfiguredTargets` and show a "set a target" CTA instead.
    test('currentCalorieTargetProvider returns null until targets are set', () {
      final container = _container();
      addTearDown(container.dispose);

      final calories = container.read(currentCalorieTargetProvider);
      expect(calories, isNull);
    });

    test('currentProteinTargetProvider returns null until targets are set', () {
      final container = _container();
      addTearDown(container.dispose);

      final protein = container.read(currentProteinTargetProvider);
      expect(protein, isNull);
    });

    test('isTrainingDayProvider returns false by default', () {
      final container = _container();
      addTearDown(container.dispose);

      final isTraining = container.read(isTrainingDayProvider);
      expect(isTraining, false);
    });
  });

  group('DynamicNutritionTargets', () {
    // Macro fields are nullable with NO numeric default: a missing/failed
    // dynamic target must stay null so it can't shadow the real base target
    // through `dynamicTargets?.targetCalories ?? preferences?.targetCalories`.
    test('should leave macro targets null by default', () {
      const targets = DynamicNutritionTargets();

      expect(targets.targetCalories, isNull);
      expect(targets.targetProteinG, isNull);
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
