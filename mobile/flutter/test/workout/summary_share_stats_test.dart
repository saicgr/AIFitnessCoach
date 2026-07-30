import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/screens/workout/widgets/summary_session_totals.dart';
import 'package:fitwiz/shareables/adapters/workout_adapter.dart';
import 'package:fitwiz/shareables/shareable_data.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('summary share card carries the session\'s real numbers',
      (tester) async {
    // The exact summary shape the E2E hit: no set_logs rows, no planned
    // duration on the workout, but a real sets_json blob in metadata.
    final summary = WorkoutSummaryResponse(
      workout: const {},
      durationSeconds: 2040,
      caloriesKcal: 310,
      setLogs: const [],
    );
    const metadata = {
      'sets_json': [
        {'reps_completed': 8, 'weight_kg': 60.0, 'is_completed': true},
        {'reps_completed': 8, 'weight_kg': 60.0, 'is_completed': true},
        {'reps_completed': 12, 'weight_kg': 0.0, 'is_completed': true},
      ],
    };

    final totals = SummarySessionTotals.resolve(
      summary: summary,
      metadata: metadata,
      exerciseCount: 2,
    );
    // ignore: avoid_print
    print('totals: dur=${totals.durationSeconds} vol=${totals.volumeKg} '
        'sets=${totals.sets} reps=${totals.reps} ex=${totals.exercises}');
    expect(totals.durationSeconds, 2040);
    expect(totals.volumeKg, 960.0);
    expect(totals.sets, 3);
    expect(totals.reps, 28);

    Shareable? built;
    await tester.pumpWidget(ProviderScope(
      overrides: [useKgForWorkoutProvider.overrideWithValue(false)],
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          built = WorkoutAdapter.fromCompletion(
            ref: ref,
            workoutName: 'Push Day',
            durationSeconds: totals.durationSeconds,
            plannedExercises: const [
              WorkoutExercise(nameValue: 'Bench Press'),
              WorkoutExercise(nameValue: 'Push-Up'),
            ],
            loggedSets: null,
            calories: totals.caloriesKcal,
            totalVolumeKgFromCaller: totals.volumeKg,
            totalSets: totals.sets,
            totalReps: totals.reps,
          );
          return const SizedBox.shrink();
        }),
      ),
    ));
    await tester.pump();

    final labels =
        built!.highlights.map((h) => '${h.label}=${h.value}').toList();
    // ignore: avoid_print
    print('share highlights: $labels');
    expect(labels, contains('DURATION=34m'));
    expect(labels.any((l) => l.startsWith('VOLUME=')), isTrue);
    expect(labels, contains('SETS=3'));
    expect(labels, contains('REPS=28'));
    expect(labels, contains('CALORIES=310 kcal'));
  });
}
