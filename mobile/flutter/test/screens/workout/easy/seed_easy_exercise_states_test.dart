// E2E register #133 — a rep-targeted exercise renders as a 5-second timer
// and logs 0 reps.
//
// Bird Dog carried `target_reps = 5` (an authored rep count) but the LIBRARY
// also marks it `is_timed = true` (many floor/quadruped moves default to
// this). `seedEasyExerciseStates` used to compute
// `timed = metric.isTime || ex.isTimedExercise` — the `ex.isTimedExercise`
// OR-clause bypassed the classifier's rep-count precedence entirely, so
// even a classifier fix couldn't stop the timer from rendering. This gate
// asserts the seed trusts the classifier ALONE.
//
// Negative-tested: reintroducing the `|| ex.isTimedExercise` OR-clause
// reproduces `isTimed == true` for Bird Dog and fails this test (see the
// diff / commit message for the before/after run).

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/screens/workout/easy/easy_persistence_helpers.dart';

void main() {
  group('seedEasyExerciseStates (#133)', () {
    test(
        'a rep-targeted exercise with a LIBRARY is_timed hint is NOT seeded as timed',
        () {
      final ex = WorkoutExercise(
        id: 'bird_dog',
        nameValue: 'Bird Dog',
        sets: 3,
        reps: 5, // authored rep count
        equipment: 'Bodyweight',
        isTimed: true, // library-sourced hint (the false positive)
      );

      final states = seedEasyExerciseStates([ex], useKg: true);
      final state = states[0]!;

      expect(state.isTimed, isFalse,
          reason: 'authored reps=5 must win over the library is_timed hint');
      expect(state.reps, 5);
      expect(state.isBodyweight, isTrue);
    });

    test('a genuine timed hold with no rep count IS seeded as timed', () {
      final ex = WorkoutExercise(
        id: 'plank',
        nameValue: 'Plank Hold',
        sets: 3,
        equipment: 'Bodyweight',
        isTimed: true,
        holdSeconds: 45,
      );

      final states = seedEasyExerciseStates([ex], useKg: true);
      final state = states[0]!;

      expect(state.isTimed, isTrue);
      expect(state.durationSeconds, 45);
    });

    test('a rep-targeted exercise with a library holdSeconds hint is NOT timed',
        () {
      final ex = WorkoutExercise(
        id: 'bird_dog2',
        nameValue: 'Bird Dog',
        sets: 3,
        reps: 5,
        equipment: 'Bodyweight',
        holdSeconds: 30, // library default hold, no isTimed flag set
      );

      final states = seedEasyExerciseStates([ex], useKg: true);
      expect(states[0]!.isTimed, isFalse);
    });
  });
}
