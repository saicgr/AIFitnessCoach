/// Test fixtures for active-workout structural tests.
///
/// Builds real `Workout` + `WorkoutExercise` + `SetTarget` instances from
/// `lib/data/models/` — no mocks, no freezed stubs. These are passed to the
/// three active-workout tier screens (Easy, Simple, Advanced) so we can
/// assert structural layout properties (no vertical scrollables) at varying
/// set counts and device sizes.
library;

import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/data/models/workout.dart';

/// Build a synthetic `Workout` for widget-structure tests.
///
/// [setCount] controls how many sets per exercise (drives
/// per-set target list length — the main stressor for no-scroll layouts).
/// [exerciseCount] controls how many exercises in the workout.
///
/// Returns a `Workout` whose `exercisesJson` is a `List<Map>` — the same
/// shape the real API returns, so the lazy `Workout.exercises` getter
/// parses them through the real `WorkoutExercise.fromJson` path.
Workout makeWorkout({int setCount = 4, int exerciseCount = 1}) {
  final exercises = List<Map<String, dynamic>>.generate(
    exerciseCount,
    (i) => _exerciseJson(index: i, setCount: setCount),
  );

  return Workout(
    id: 'test-workout-fixture',
    userId: 'test-user-fixture',
    name: 'No-Scroll Test Workout',
    type: 'strength',
    difficulty: 'intermediate',
    scheduledDate: '2026-04-20',
    isCompleted: false,
    exercisesJson: exercises,
    durationMinutes: 45,
  );
}

/// Build a single exercise JSON blob with [setCount] per-set targets.
Map<String, dynamic> _exerciseJson({required int index, required int setCount}) {
  final setTargets = List<Map<String, dynamic>>.generate(
    setCount,
    (i) => {
      'set_number': i + 1,
      'set_type': 'working',
      'target_reps': 10,
      'target_weight_kg': 40.0 + (i * 2.5),
      'target_rir': 2,
    },
  );

  return {
    'id': 'exercise-$index',
    'exercise_id': 'ex-$index',
    'name': index == 0 ? 'Bench Press' : 'Exercise ${index + 1}',
    'sets': setCount,
    'reps': 10,
    'rest_seconds': 60,
    'weight': 40.0,
    'muscle_group': 'chest',
    'primary_muscle': 'chest',
    'equipment': 'Barbell',
    'instructions': 'Lower the bar to your chest, then press up.',
    'set_targets': setTargets,
  };
}

/// Convenience: guaranteed-nonempty `WorkoutExercise` list matching
/// [setCount] / [exerciseCount]. Useful for tests that want the exercise
/// list directly without going through the `Workout.exercises` getter.
List<WorkoutExercise> makeExercises({int setCount = 4, int exerciseCount = 1}) {
  return makeWorkout(setCount: setCount, exerciseCount: exerciseCount).exercises;
}
