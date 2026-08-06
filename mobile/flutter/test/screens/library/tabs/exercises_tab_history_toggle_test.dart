/// Regression test for Library → Exercises tab → HISTORY toggle
/// (E2E row 92, MED — "4 EXERCISES FOUND" header over an empty
/// "No exercises found" body).
///
/// Root cause: the header count and the rendered list independently computed
/// the client-side "performed only" (HISTORY toggle) filter — the header
/// from the RAW unfiltered page (`exercisesState.exercises.length`), the list
/// from that same source filtered down to only-performed exercises. When
/// none of the currently-loaded exercises had been performed, the list went
/// to zero while the header kept reporting the raw count.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/screens/library/models/exercises_state.dart';
import 'package:fitwiz/screens/library/models/filter_option.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart';
import 'package:fitwiz/screens/library/tabs/exercises_tab.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';

class _FakeExercisesNotifier extends ExercisesNotifier {
  _FakeExercisesNotifier(super.ref, ExercisesState seed) {
    state = seed;
  }

  @override
  Future<void> loadExercises({bool refresh = false}) async {}
}

LibraryExercise _ex(String id, String name) =>
    LibraryExercise(id: id, nameValue: name, bodyPart: 'Core');

Widget _app({
  required bool performedOnly,
  required List<String> performedExerciseNames,
  int? totalCount,
  Set<String> selectedMuscles = const {},
}) {
  return ProviderScope(
    overrides: [
      exercisesNotifierProvider.overrideWith(
        (ref) => _FakeExercisesNotifier(
          ref,
          ExercisesState(
            exercises: [
              _ex('1', 'Shirshasana (Headstand)'),
              _ex('2', 'Single-Leg Balance On Hay Bale'),
              _ex('3', 'Lathi Single-Leg Balance'),
              _ex('4', 'Mallakhamb Pole Sit (Danda)'),
            ],
            hasMore: false,
            filterSignature: 'seed',
            totalCount: totalCount,
          ),
        ),
      ),
      if (selectedMuscles.isNotEmpty)
        selectedMuscleGroupsProvider.overrideWith((ref) => selectedMuscles),
      performedOnlyProvider.overrideWith((ref) => performedOnly),
      exerciseHistoryProvider.overrideWith(
        (ref) async => performedExerciseNames
            .map((n) => ExerciseHistoryItem(exerciseName: n, totalSets: 1))
            .toList(),
      ),
      filterOptionsProvider.overrideWith(
        (ref) async => const ExerciseFilterOptions(
          bodyParts: [],
          equipment: [],
          exerciseTypes: [],
          goals: [],
          suitableFor: [],
          avoidIf: [],
          totalExercises: 2377,
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ExercisesTab()),
    ),
  );
}

void main() {
  testWidgets(
    'header count matches the body when HISTORY filters everything out '
    '(no fabricated non-zero count over an empty state)',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        performedOnly: true,
        // A non-empty history that just doesn't overlap with the 4 loaded
        // exercises — matching the real repro (user has logged history,
        // just none of it is in this filtered set). An EMPTY history list
        // deliberately takes the "still loading" fallback branch instead
        // (below), which is a distinct case.
        performedExerciseNames: const ['Some Other Exercise'],
      ));
      // The empty-state illustration/shimmer can carry a non-terminating
      // animation (same as `library_screen_test.dart`'s note) — drive fixed
      // frames instead of `pumpAndSettle()`.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The defect: this used to say "4 EXERCISES FOUND".
      expect(find.text('4 EXERCISES FOUND'), findsNothing);
      expect(find.text('0 EXERCISES FOUND'), findsOneWidget);
      expect(find.text('No exercises found'), findsOneWidget);
    },
  );

  testWidgets(
    'header count matches the body when HISTORY keeps some exercises',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        performedOnly: true,
        performedExerciseNames: const ['Shirshasana (Headstand)'],
      ));
      // The empty-state illustration/shimmer can carry a non-terminating
      // animation (same as `library_screen_test.dart`'s note) — drive fixed
      // frames instead of `pumpAndSettle()`.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('1 EXERCISES FOUND'), findsOneWidget);
      expect(find.text('No exercises found'), findsNothing);
    },
  );

  testWidgets(
    'header count uses the backend X-Total-Count total (row 25) when a '
    'filter is active and HISTORY is off — not just the 4 loaded rows',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        performedOnly: false,
        performedExerciseNames: const [],
        selectedMuscles: const {'Balance'},
        totalCount: 4, // matches the real "Balance" category repro
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('4 EXERCISES FOUND'), findsOneWidget);
    },
  );

  testWidgets(
    'HISTORY on ignores the backend total (it is not history-aware) and '
    'uses the client-filtered count instead',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        performedOnly: true,
        performedExerciseNames: const ['Shirshasana (Headstand)'],
        selectedMuscles: const {'Balance'},
        // Backend total for "Balance" ignores the HISTORY toggle entirely
        // (it's client-only) — showing it here would be exactly the row 92
        // bug again, just sourced from the header instead of exercises.length.
        totalCount: 4,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('4 EXERCISES FOUND'), findsNothing);
      expect(find.text('1 EXERCISES FOUND'), findsOneWidget);
    },
  );
}
