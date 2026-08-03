// E2E register #179 — a reshape triggered from the pain-report sheet was
// invisible to the session that just triggered it: `report_pain_sheet.dart`
// called `reshape-for-readiness?apply=true`, which rewrites the workout's
// `exercises_json` server-side, but never re-synced `activeWorkoutLiveProvider`
// — unlike the sibling exercise-swap feature, which explicitly does
// (`easy_active_workout_state.dart:1647`). So the server had the new plan and
// #178's after-the-fact notice told the user about it, but the screen behind
// the notice kept showing the OLD exercise list until the next load.
//
// Fix: `_confirm()` in report_pain_sheet.dart now publishes
// `base.copyWith(exercisesJson: reshaped_exercises)` to
// `activeWorkoutLiveProvider` right after a successful reshaped:true response
// — mirroring the swap feature's re-sync exactly. `base` prefers whatever is
// already live (so an earlier in-session swap survives), falling back to the
// `activeWorkout` snapshot the caller passed into `ReportPainSheet.show`.
//
// Deliberately NOT covered here (out of scope per #178): duration/calories.
// `ReshapeResponse` doesn't carry them, and re-deriving them client-side is
// exactly the divergent-duration-model class #146 was about — so this test
// also pins that `durationMinutes` is left untouched by the resync, proving
// the fix didn't overreach into that territory.
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/avoided_provider.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/providers/active_workout_live_provider.dart';
import 'package:fitwiz/screens/workout/widgets/report_pain_sheet.dart';
import '../../helpers/test_helpers.dart';

/// Stands in for the real notifier so `_confirm()`'s first call
/// (`avoidedProvider.notifier.reportPain`) succeeds without touching the real
/// avoided-list repository / today-workout invalidation chain — this test is
/// only about the reshape re-sync, not the avoid-list write path.
class _FakeAvoidedNotifier extends AvoidedNotifier {
  _FakeAvoidedNotifier(super.ref);

  @override
  Future<bool> reportPain(
    String exerciseName, {
    String? exerciseId,
    required String severity,
    Duration? duration,
  }) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(FakeResponse());
  });

  testWidgets(
      '#179 — a sharp pain report reshape re-syncs activeWorkoutLiveProvider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final baseWorkout = TestFixtures.createWorkout(
      id: 'w-179',
      durationMinutes: 45,
      exercisesJson: [
        {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
        {'name': 'Bench Press', 'sets': 3, 'reps': 10},
        {'name': 'Squats', 'sets': 4, 'reps': 8},
        {'name': 'Deadlift', 'sets': 3, 'reps': 5},
        {'name': 'Lat Pulldown', 'sets': 3, 'reps': 10},
        {'name': 'Bicep Curl', 'sets': 3, 'reps': 12},
      ],
    );

    final mockApiClient = MockApiClient();
    when(() => mockApiClient.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response<dynamic>(
              requestOptions:
                  RequestOptions(path: '/workouts/w-179/reshape-for-readiness'),
              statusCode: 200,
              data: <String, dynamic>{
                'reshaped': true,
                'reasons': ['Swapped shoulder-loading moves for reported pain'],
                'original_exercises':
                    baseWorkout.exercises.map((_) => <String, dynamic>{}).toList(),
                'reshaped_exercises': [
                  {'name': 'Goblet Squat', 'sets': 3, 'reps': 10},
                  {'name': 'Leg Press', 'sets': 3, 'reps': 12},
                  {'name': 'Bicep Curl', 'sets': 3, 'reps': 12},
                ],
              },
            ));

    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient),
      avoidedProvider.overrideWith((ref) => _FakeAvoidedNotifier(ref)),
    ]);
    addTearDown(container.dispose);

    // Nothing live before the flow runs.
    expect(container.read(activeWorkoutLiveProvider), isNull);

    late BuildContext capturedContext;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(builder: (ctx, ref, _) {
          capturedContext = ctx;
          return const Scaffold(body: SizedBox.shrink());
        }),
      ),
    ));
    await tester.pump();

    // Drives the sheet exactly the way both production call sites do:
    // ReportPainSheet.show(..., workoutId: ..., activeWorkout: <current Workout>).
    unawaited(ReportPainSheet.show(
      capturedContext,
      exerciseName: 'Overhead Press',
      exerciseId: 'ex-ohp',
      bodyPart: 'shoulder',
      workoutId: 'w-179',
      activeWorkout: baseWorkout,
    ));
    await tester.pumpAndSettle();

    // Sharp/severe is the "swap zone" (#3) that fires the reshape call.
    await tester.tap(find.text('Sharp'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Skip & avoid'));
    await tester.pumpAndSettle();

    verify(() => mockApiClient.post(
          '/workouts/w-179/reshape-for-readiness',
          data: any(named: 'data'),
        )).called(1);

    final live = container.read(activeWorkoutLiveProvider);
    expect(live, isNotNull,
        reason: 'reshape response was reshaped:true — the live session '
            'should now mirror the server exercise list');
    expect(live!.id, 'w-179');
    expect(
      live.exercises.map((e) => e.name).toList(),
      ['Goblet Squat', 'Leg Press', 'Bicep Curl'],
      reason: 'exercise list must come from reshaped_exercises, not the '
          'stale 6-exercise base workout',
    );
    // Duration/calories are NOT in ReshapeResponse (#178) — the resync must
    // not re-derive them client-side. copyWith without those args means the
    // base workout's own values pass through untouched.
    expect(live.durationMinutes, baseWorkout.durationMinutes);
  });
}
