/// Regression test for E2E #152 (CRIT) — the share card must not publish a
/// workout that never happened.
///
/// `WorkoutAdapter.fromCompletion`'s `hasLoggedWork` gate used to call
/// `setsJsonByExercise.values.any((sets) => sets.isNotEmpty)` on the RAW
/// parsed `sets_json`, which does not filter `is_completed`. For a session
/// whose `sets_json` is entirely the zero-stamped placeholder sets the
/// "Complete workout now" safety net pads onto untouched exercises
/// (`is_completed: false`, `reps: 0`), that check was TRUE, so
/// `fromCompletion` did not return null and fell back to fabricating
/// `setCount`/`repCount` from `plannedExercises` — reproducing a fabricated
/// "SETS 23" headline for a workout the user never did (workout_log
/// `2730ddef-7205-4d36-a051-4fa4e57c3798`: 23 `sets_json` entries, all
/// `is_completed: false` / `reps: 0`).
///
/// The fix makes the top-level gate use the same real-work definition
/// `_buildExerciseList` already applies per-exercise: a set counts only if
/// `is_completed` is not `false` AND it has actual work (reps > 0,
/// duration, or distance).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/shareables/adapters/workout_adapter.dart';
import 'package:fitwiz/shareables/shareable_data.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const plannedExercises = [
    WorkoutExercise(nameValue: 'Dumbbell Straight Leg Deadlift', sets: 4, reps: 9),
    WorkoutExercise(nameValue: 'Dumbbell Lunge to Overhead Press', sets: 4, reps: 9),
  ];

  /// Shape of workout_log 2730ddef's `sets_json`: every entry is the
  /// "Complete workout now" placeholder — not completed, zero reps, zero
  /// weight — for an exercise the user never actually touched.
  List<Map<String, dynamic>> placeholderSetsJson() => [
        for (final ex in [
          'Dumbbell Straight Leg Deadlift',
          'Dumbbell Lunge to Overhead Press',
        ])
          for (var i = 0; i < 4; i++)
            {
              'reps': 0,
              'weight_kg': 0.0,
              'set_number': i + 1,
              'exercise_name': ex,
              'is_completed': false,
              'target_reps': 9,
              'target_weight_kg': 20.0,
            },
      ];

  testWidgets(
      'E2E #152: an all-placeholder sets_json (is_completed:false, reps:0) '
      'must not produce a share card', (tester) async {
    Shareable? built;
    var didRun = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [useKgForWorkoutProvider.overrideWithValue(false)],
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          built = WorkoutAdapter.fromCompletion(
            ref: ref,
            workoutName: 'Push Day',
            durationSeconds: 1200,
            plannedExercises: plannedExercises,
            loggedSets: null,
            setsJsonRaw: placeholderSetsJson(),
          );
          didRun = true;
          return const SizedBox.shrink();
        }),
      ),
    ));
    await tester.pump();

    expect(didRun, isTrue);
    expect(built, isNull,
        reason: 'a session with only zero-stamped placeholder sets is not '
            'a logged workout and must not be shareable (E2E #152)');
  });

  testWidgets(
      'E2E #152 control: real logged work in sets_json still produces a '
      'share card, and per-exercise sets still filter out placeholder rows',
      (tester) async {
    Shareable? built;
    final realSetsJson = [
      {
        'reps': 9,
        'weight_kg': 20.0,
        'set_number': 1,
        'exercise_name': 'Dumbbell Straight Leg Deadlift',
        'is_completed': true,
      },
      {
        'reps': 0,
        'weight_kg': 0.0,
        'set_number': 2,
        'exercise_name': 'Dumbbell Straight Leg Deadlift',
        'is_completed': false,
      },
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [useKgForWorkoutProvider.overrideWithValue(false)],
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          built = WorkoutAdapter.fromCompletion(
            ref: ref,
            workoutName: 'Push Day',
            durationSeconds: 1200,
            plannedExercises: plannedExercises,
            loggedSets: null,
            setsJsonRaw: realSetsJson,
          );
          return const SizedBox.shrink();
        }),
      ),
    ));
    await tester.pump();

    expect(built, isNotNull,
        reason: 'one real completed set is genuine evidence of logged '
            'work and must still produce a share card');
    // The exercise with real sets_json data only surfaces its one
    // completed set — the padded is_completed:false row is excluded.
    final deadlift = built!.exercises!
        .firstWhere((e) => e.name == 'Dumbbell Straight Leg Deadlift');
    expect(deadlift.sets.length, 1);
  });
}
