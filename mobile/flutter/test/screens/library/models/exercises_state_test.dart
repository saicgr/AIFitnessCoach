import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/library/models/exercises_state.dart';
import 'package:ai_fitness_coach/data/models/exercise.dart';

void main() {
  group('ExercisesState', () {
    test('default constructor creates correct initial state', () {
      const state = ExercisesState();

      expect(state.exercises, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
      expect(state.offset, 0);
      expect(state.error, isNull);
    });

    test('copyWith creates correct copy with no changes', () {
      const original = ExercisesState(
        isLoading: true,
        hasMore: false,
        offset: 100,
        error: 'test error',
      );

      final copy = original.copyWith();

      expect(copy.isLoading, true);
      expect(copy.hasMore, false);
      expect(copy.offset, 100);
      expect(copy.error, 'test error');
    });

    test('copyWith overrides specified fields', () {
      const original = ExercisesState(
        isLoading: true,
        hasMore: true,
        offset: 50,
      );

      final copy = original.copyWith(
        isLoading: false,
        offset: 100,
      );

      expect(copy.isLoading, false);
      expect(copy.hasMore, true); // unchanged
      expect(copy.offset, 100);
    });

    test('copyWith can set error to null', () {
      const original = ExercisesState(error: 'some error');

      final copy = original.copyWith(error: null);

      expect(copy.error, isNull);
    });

    test('equality works correctly', () {
      const state1 = ExercisesState(
        isLoading: true,
        offset: 50,
      );
      const state2 = ExercisesState(
        isLoading: true,
        offset: 50,
      );
      const state3 = ExercisesState(
        isLoading: false,
        offset: 50,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('hashCode is consistent', () {
      const state1 = ExercisesState(
        isLoading: true,
        offset: 50,
      );
      const state2 = ExercisesState(
        isLoading: true,
        offset: 50,
      );

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('exercises list can be updated via copyWith', () {
      const original = ExercisesState();
      final exercises = [
        const LibraryExercise(
          id: '1',
          nameValue: 'Bench Press',
          bodyPart: 'Chest',
        ),
      ];

      final updated = original.copyWith(exercises: exercises);

      expect(updated.exercises, hasLength(1));
      expect(updated.exercises[0].name, 'Bench Press');
    });
  });

  group('exercisesPageSize', () {
    test('is correct value', () {
      expect(exercisesPageSize, 100);
    });
  });
}
