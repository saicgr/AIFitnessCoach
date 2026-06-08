// Guards the single post-workout-mutation refresh chokepoint.
//
// The bug: after completing a workout, Home + the Workout tab stayed stale
// because the only full refresh ran from a dispose-gated Timer that never
// fired, and the 11-provider refresh set was duplicated across 5 call sites.
// refreshAfterWorkoutMutation + kWorkoutMutationProviders collapse that into
// one dispose-proof chokepoint. These tests lock the invariants.
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/workout_mutation_coordinator.dart';
import 'package:fitwiz/data/providers/consistency_provider.dart';
import 'package:fitwiz/data/providers/milestones_provider.dart';
import 'package:fitwiz/data/providers/muscle_analytics_provider.dart';
import 'package:fitwiz/data/providers/scores_provider.dart';

void main() {
  group('kWorkoutMutationProviders', () {
    test('is the complete single-source-of-truth refresh set', () {
      // If a provider is dropped from this list, some surface silently stops
      // refreshing after a workout mutation — exactly the class of bug we fixed.
      expect(
        kWorkoutMutationProviders,
        containsAll(<Object>[
          muscleHeatmapProvider,
          muscleFrequencyProvider,
          muscleBalanceProvider,
          scoresProvider,
          milestonesProvider,
          consistencyProvider,
          consistencyDataProvider,
          activityHeatmapProvider,
          calendarHeatmapProvider,
        ]),
      );
      expect(kWorkoutMutationProviders.length, 9);
    });
  });

  group('refreshAfterWorkoutMutation', () {
    test('no-ops safely before the root container is wired (no throw)', () async {
      appProviderContainer = null; // simulate very-early startup
      await expectLater(
        refreshAfterWorkoutMutation(
            source: 'test', workoutId: 'w1', debounce: Duration.zero),
        completes,
      );
    });
  });
}
