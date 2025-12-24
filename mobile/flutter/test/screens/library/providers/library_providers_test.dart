import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/library/providers/library_providers.dart';
import 'package:ai_fitness_coach/screens/library/models/exercises_state.dart';

void main() {
  group('Library Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('selectedMuscleGroupsProvider', () {
      test('initial state is empty set', () {
        final muscles = container.read(selectedMuscleGroupsProvider);
        expect(muscles, isEmpty);
      });

      test('can add values', () {
        container.read(selectedMuscleGroupsProvider.notifier).state = {'Chest'};
        final muscles = container.read(selectedMuscleGroupsProvider);
        expect(muscles, contains('Chest'));
      });

      test('can add multiple values', () {
        container.read(selectedMuscleGroupsProvider.notifier).state = {
          'Chest',
          'Back',
          'Legs',
        };
        final muscles = container.read(selectedMuscleGroupsProvider);
        expect(muscles.length, 3);
      });
    });

    group('selectedEquipmentsProvider', () {
      test('initial state is empty set', () {
        final equipment = container.read(selectedEquipmentsProvider);
        expect(equipment, isEmpty);
      });

      test('can add values', () {
        container.read(selectedEquipmentsProvider.notifier).state = {
          'Barbell',
          'Dumbbell',
        };
        final equipment = container.read(selectedEquipmentsProvider);
        expect(equipment.length, 2);
      });
    });

    group('selectedExerciseTypesProvider', () {
      test('initial state is empty set', () {
        final types = container.read(selectedExerciseTypesProvider);
        expect(types, isEmpty);
      });
    });

    group('selectedGoalsProvider', () {
      test('initial state is empty set', () {
        final goals = container.read(selectedGoalsProvider);
        expect(goals, isEmpty);
      });
    });

    group('exerciseSearchProvider', () {
      test('initial state is empty string', () {
        final search = container.read(exerciseSearchProvider);
        expect(search, isEmpty);
      });

      test('can set search query', () {
        container.read(exerciseSearchProvider.notifier).state = 'bench';
        final search = container.read(exerciseSearchProvider);
        expect(search, 'bench');
      });
    });

    group('programSearchProvider', () {
      test('initial state is empty string', () {
        final search = container.read(programSearchProvider);
        expect(search, isEmpty);
      });

      test('can set search query', () {
        container.read(programSearchProvider.notifier).state = 'strength';
        final search = container.read(programSearchProvider);
        expect(search, 'strength');
      });
    });

    group('selectedProgramCategoryProvider', () {
      test('initial state is null', () {
        final category = container.read(selectedProgramCategoryProvider);
        expect(category, isNull);
      });

      test('can set category', () {
        container.read(selectedProgramCategoryProvider.notifier).state =
            'Goal-Based';
        final category = container.read(selectedProgramCategoryProvider);
        expect(category, 'Goal-Based');
      });

      test('can clear category', () {
        container.read(selectedProgramCategoryProvider.notifier).state =
            'Sport Training';
        container.read(selectedProgramCategoryProvider.notifier).state = null;
        final category = container.read(selectedProgramCategoryProvider);
        expect(category, isNull);
      });
    });

    group('ExercisesState', () {
      test('initial state is correct', () {
        const state = ExercisesState();
        expect(state.exercises, isEmpty);
        expect(state.isLoading, false);
        expect(state.hasMore, true);
        expect(state.offset, 0);
        expect(state.error, isNull);
      });
    });
  });

  group('Helper Functions', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // Note: getActiveFilterCount and clearAllFilters require WidgetRef,
    // so we test the underlying state instead

    test('filter states can be cleared independently', () {
      // Set some filters
      container.read(selectedMuscleGroupsProvider.notifier).state = {
        'Chest',
        'Back',
      };
      container.read(selectedEquipmentsProvider.notifier).state = {'Barbell'};

      // Clear one
      container.read(selectedMuscleGroupsProvider.notifier).state = {};

      // Verify
      expect(container.read(selectedMuscleGroupsProvider), isEmpty);
      expect(container.read(selectedEquipmentsProvider), isNotEmpty);
    });

    test('all filter states can be cleared', () {
      // Set filters
      container.read(selectedMuscleGroupsProvider.notifier).state = {'Chest'};
      container.read(selectedEquipmentsProvider.notifier).state = {'Barbell'};
      container.read(selectedExerciseTypesProvider.notifier).state = {
        'Compound'
      };
      container.read(selectedGoalsProvider.notifier).state = {'Strength'};
      container.read(selectedSuitableForSetProvider.notifier).state = {
        'Beginners'
      };
      container.read(selectedAvoidSetProvider.notifier).state = {
        'Back pain'
      };

      // Clear all
      container.read(selectedMuscleGroupsProvider.notifier).state = {};
      container.read(selectedEquipmentsProvider.notifier).state = {};
      container.read(selectedExerciseTypesProvider.notifier).state = {};
      container.read(selectedGoalsProvider.notifier).state = {};
      container.read(selectedSuitableForSetProvider.notifier).state = {};
      container.read(selectedAvoidSetProvider.notifier).state = {};

      // Verify all empty
      expect(container.read(selectedMuscleGroupsProvider), isEmpty);
      expect(container.read(selectedEquipmentsProvider), isEmpty);
      expect(container.read(selectedExerciseTypesProvider), isEmpty);
      expect(container.read(selectedGoalsProvider), isEmpty);
      expect(container.read(selectedSuitableForSetProvider), isEmpty);
      expect(container.read(selectedAvoidSetProvider), isEmpty);
    });
  });
}
