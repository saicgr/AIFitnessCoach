// Regression gate for two screenshot/production-data-confirmed defects on
// the Workout Summary tab:
//
//   4. MUSCLES WORKED summed PLANNED set counts (falling back to the
//      exercise's `sets` field whenever no completed log matched by name)
//      while the headline "SETS · REPS" stat is completed-only — production
//      example: headline "1 · 0", muscle sums "Back 6, Core 3, Hips 3,
//      Quads 3 = 15". Fixed in `_MusclesWorkedSection._extractMuscles()`
//      (workout_summary_general.dart) by dropping the planned fallback, plus
//      hiding the whole section if NOTHING was actually completed (else it
//      would render muscle silhouettes for a session with zero real work).
//
//   5. The exercise table rendered distance/timed sets as a bare "Reps 0",
//      hiding the metric that was actually logged — production example:
//      workout log 4afeaab7, "Air Swing Running" set 1:
//      {"reps": 0, "weight_kg": 0.0, "distance_meters": 19950.0,
//       "is_completed": true}. `reps: 0` is CORRECT for a distance/timed set
//      (easy_active_workout_state.dart deliberately zeroes it) — the defect
//      is purely presentational. Fixed in `summary_exercise_table.dart`:
//      SummarySetData now carries distanceMeters/metrics, a set with no real
//      reps but a real alternate metric renders THAT instead of "0", and a
//      whole-exercise-of-one-kind table relabels its Reps column
//      (DISTANCE/TIME/METRIC).
//
// Both suites assert on rendered TEXT CONTENT (the actual numbers/labels a
// user sees), not widget existence — matching the project's "assert the
// actual defect" bar.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/core/providers/user_provider.dart' show useKgForWorkoutProvider;
import 'package:fitwiz/data/models/exercise.dart' show LibraryExercise;
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/services/api_client.dart'
    show ApiClient, apiClientProvider;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart'
    show exercisesProvider;
import 'package:fitwiz/screens/workout/widgets/summary_exercise_table.dart';
import 'package:fitwiz/screens/workout/workout_summary_general.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Supabase-free, network-free API client — same pattern as
// workout_result_unbounded_layout_test.dart.
class _OfflineApiClient extends ApiClient {
  _OfflineApiClient() : super(const FlutterSecureStorage());

  static Response<T> _json<T>(String path, int status, T body) => Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: body,
      );

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path.startsWith('/feedback/recap/')) {
      return _json<T>(path, 200, <String, dynamic>{'exists': false} as T);
    }
    if (path == '/scores/recent-level-ups') {
      return _json<T>(path, 200, <String, dynamic>{
        'muscle_level_ups': const [],
        'overall_level_up': null,
      } as T);
    }
    return _json<T>(path, 404, null as T);
  }
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        exercisesProvider.overrideWith(
          (ref) => const AsyncValue<List<LibraryExercise>>.data([]),
        ),
        useKgForWorkoutProvider.overrideWith((ref) => false),
        apiClientProvider.overrideWith((ref) => _OfflineApiClient()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('Defect 4 — MUSCLES WORKED reflects COMPLETED sets, not planned', () {
    /// Mirrors the production shape: 4 exercises each planning several sets
    /// (`sets`) across 4 different primary muscles, but only ONE completed
    /// set log for the Back exercise — matching the reported "headline 1,
    /// muscle sums 15" mismatch.
    WorkoutSummaryResponse summaryWithOneCompletedSet() =>
        WorkoutSummaryResponse.fromJson({
          'workout': {
            'id': 'w1',
            'name': 'Full Body',
            'type': 'strength',
            'exercises_json': [
              {'name': 'Lat Pulldown', 'primary_muscle': 'back', 'sets': 6},
              {'name': 'Plank', 'primary_muscle': 'core', 'sets': 3},
              {'name': 'Hip Thrust', 'primary_muscle': 'hips', 'sets': 3},
              {'name': 'Leg Press', 'primary_muscle': 'quads', 'sets': 3},
            ],
          },
          'set_logs': [
            {
              'exercise_name': 'Lat Pulldown',
              'exercise_index': 0,
              'set_number': 1,
              'reps_completed': 10,
              'weight_kg': 40.0,
              'set_type': 'working',
            },
          ],
          'performance_comparison': null,
          'personal_records': const [],
          'coach_summary': null,
          'hero_narrative': null,
          'completion_method': 'completed',
          'completed_at': '2026-06-07T11:00:00Z',
        });

    WorkoutSummaryResponse summaryWithNoCompletedSets() =>
        WorkoutSummaryResponse.fromJson({
          'workout': {
            'id': 'w2',
            'name': 'Full Body',
            'type': 'strength',
            'exercises_json': [
              {'name': 'Lat Pulldown', 'primary_muscle': 'back', 'sets': 6},
              {'name': 'Plank', 'primary_muscle': 'core', 'sets': 3},
            ],
          },
          'set_logs': const [],
          'performance_comparison': null,
          'personal_records': const [],
          'coach_summary': null,
          'hero_narrative': null,
          'completion_method': 'quit_early',
          'completed_at': '2026-06-07T11:00:00Z',
        });

    testWidgets(
        'shows the completed set count (1), never the planned fallback (6/3/15)',
        (tester) async {
      await tester.pumpWidget(_wrap(WorkoutSummaryGeneral(
        data: summaryWithOneCompletedSet(),
        metadata: const {},
        topPadding: 0,
      )));
      await tester.pumpAndSettle();

      expect(find.text('1 sets'), findsOneWidget,
          reason: 'Back has exactly 1 completed set logged');
      expect(find.text('6 sets'), findsNothing,
          reason: 'planned count (Lat Pulldown sets:6) must never render');
      expect(find.text('3 sets'), findsNothing,
          reason: 'planned counts for Core/Hips/Quads (sets:3) must never '
              'render — those exercises had zero completed logs');
      expect(find.text('15 sets'), findsNothing);
    });

    testWidgets('hides the section entirely when nothing was completed',
        (tester) async {
      await tester.pumpWidget(_wrap(WorkoutSummaryGeneral(
        data: summaryWithNoCompletedSets(),
        metadata: const {},
        topPadding: 0,
      )));
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations.of(
                tester.element(find.byType(WorkoutSummaryGeneral)))
            .workoutSummaryGeneralMusclesWorked),
        findsNothing,
        reason: 'zero completed sets across the whole session must not '
            'render muscle silhouettes for what was only PLANNED',
      );
    });
  });

  group('Defect 5 — distance/timed sets show their real metric, not "0"',
      () {
    testWidgets(
        'a pure-distance exercise shows the logged distance and a DISTANCE header',
        (tester) async {
      final exercise = SummaryExerciseData(
        name: 'Air Swing Running',
        exerciseIndex: 0,
        sets: const [
          SummarySetData(
            setNumber: 1,
            targetReps: 11,
            actualReps: 0,
            actualWeightKg: 0,
            distanceMeters: 19950.0,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(
        SummaryExerciseTable(exercises: [exercise], useKg: false),
      ));
      await tester.pumpAndSettle();

      // The exact string the production fix computes — not a hand-rolled
      // duplicate, so a rounding-convention change can't silently desync
      // the test from the real formatter.
      expect(find.text(formatSetDistanceMeters(19950.0)), findsOneWidget,
          reason: 'the 19,950m the set actually logged must be visible');
      expect(find.text('DISTANCE'), findsOneWidget,
          reason: 'every set in this exercise is distance-only — the '
              'column header should say so instead of "REPS"');
      expect(find.text('0'), findsNothing,
          reason: 'no cell should show a bare "0" for a set that logged a '
              'real 19,950m distance');
    });

    testWidgets(
        'a mixed exercise (one rep set, one distance set) keeps the REPS '
        'header but still shows the distance set\'s real value',
        (tester) async {
      final exercise = SummaryExerciseData(
        name: 'Farmer Carry Circuit',
        exerciseIndex: 0,
        sets: const [
          SummarySetData(setNumber: 1, actualReps: 10, actualWeightKg: 20),
          SummarySetData(
            setNumber: 2,
            actualReps: 0,
            actualWeightKg: 0,
            distanceMeters: 500,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(
        SummaryExerciseTable(exercises: [exercise], useKg: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DISTANCE'), findsNothing,
          reason: 'mixed kinds — header must not falsely claim every row '
              'is a distance row');
      expect(find.text(formatSetDistanceMeters(500)), findsOneWidget,
          reason: 'set 2\'s real 500m must still render regardless of the '
              'header decision');
      expect(find.text('10'), findsOneWidget,
          reason: 'set 1\'s real reps must still render normally');
    });
  });
}
