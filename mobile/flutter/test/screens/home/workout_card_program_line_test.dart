/// Change 3 — "My Programs" folded into the workout card: the active
/// program's name + an ACTIVE badge now render as a line on the card itself.
/// These tests assert the RENDERED program name/badge text (and its absence
/// when there's genuinely nothing resolved yet), not just that the card
/// builds without throwing.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/user_program_assignment.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/providers/program_assignments_provider.dart';
import 'package:fitwiz/data/providers/today_workout_provider.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/screens/home/widgets/home/unified_home_widgets.dart';

import 'test_provider_stubs.dart';

/// A single non-completed workout scheduled for TODAY (bare `YYYY-MM-DD` —
/// the shape the local-day resolver treats as already-local, see
/// `home_schedule_dates.dart`). No exercises, so `_WorkoutHeroBody` never
/// attempts the exercise-image network fetch (`_firstExerciseName` returns
/// null when `exercises` is empty) — keeps the test hermetic.
Workout _todaysWorkout() {
  final now = DateTime.now();
  final iso =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return Workout(
    id: 'w1',
    name: 'Upper Body Strength',
    type: 'strength',
    scheduledDate: iso,
    isCompleted: false,
    exercisesJson: const <Map<String, dynamic>>[],
    durationMinutes: 45,
  );
}

List<Override> _baseOverrides() => [
      workoutsProvider.overrideWith(
        (ref) => StubWorkoutsNotifier(AsyncValue.data([_todaysWorkout()])),
      ),
      todayWorkoutProvider.overrideWith(
        (ref) => StubTodayWorkoutNotifier(const AsyncValue.data(null)),
      ),
    ];

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeWorkoutCard — active program line', () {
    testWidgets(
        'shows the active PRIMARY program name and an ACTIVE badge',
        (tester) async {
      final assignment = UserProgramAssignment(
        id: 'a1',
        slot: ProgramSlot.primary,
        isActive: true,
        status: 'active',
        displayName: 'Balanced Muscle Definition',
      );
      await tester.pumpWidget(_wrap(
        const HomeWorkoutCard(),
        [
          ..._baseOverrides(),
          programAssignmentsProvider.overrideWith((ref) async => [assignment]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Balanced Muscle Definition'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets(
        'falls back to the AI Coach adaptive-plan line when there is no active primary',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HomeWorkoutCard(),
        [
          ..._baseOverrides(),
          programAssignmentsProvider.overrideWith((ref) async => const []),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('AI Coach · Adaptive Plan'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets(
        'renders no program line while assignments have not resolved (no fabricated fallback)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HomeWorkoutCard(),
        [
          ..._baseOverrides(),
          // Never resolves within the test — represents the still-loading
          // state, where the real answer (primary vs. adaptive) isn't known
          // yet.
          programAssignmentsProvider.overrideWith(
            (ref) => Completer<List<UserProgramAssignment>>().future,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('AI Coach · Adaptive Plan'), findsNothing);
      expect(find.textContaining('Balanced Muscle Definition'), findsNothing);
      // The rest of the card still renders fine — this isn't a card-wide
      // loading state, just the one line staying off.
      expect(find.text('START WORKOUT →'), findsOneWidget);
    });
  });
}
