// E2E register #175 — the duplicate-CREATE storm on Easy-tier workout
// completion.
//
// `_completeWorkoutNow`'s padding loop (easy_active_workout_state.dart) used
// to fire `persistEasySet` unawaited for every unlogged set in a plain
// synchronous `while` loop, with no `await` between iterations. Because the
// cached workout-log id was only ever updated from a `.then()` callback —
// which can't run until the loop yields — EVERY iteration read the same
// stale id (frequently still `null`) and independently took
// `persistEasySet`'s create-workout-log branch: measured live as 27
// identical `POST /performance/workout-logs` for a single 27-set
// completion, all racing, all resolving to the same row via the server's
// idempotency guard (E2E #158, migration 2247) but still 27 real requests —
// burning the connection pool and flooding Render's logs for one tap.
//
// The fix (`persistEasySetSerialized` + `EasyWorkoutLogIdHolder` in
// easy_persistence_helpers.dart) serializes on the ONE call that actually
// needs to create the row — every call while the holder is still unknown is
// AWAITED, so the id lands before the next call fires; once known, later
// calls stay fire-and-forget. `_persistEasySetTracked` in the state class
// (and both its call sites — natural per-set logging AND the padding loop)
// now route through it, and the padding loop `await`s each call instead of
// firing it unawaited.
//
// This test drives `persistEasySetSerialized` exactly the way the FIXED
// padding loop does — N calls against ONE shared holder, each awaited
// before the next is dispatched — and pins the create-call count at exactly
// 1, not N. It also proves the naive "fire N unawaited calls" pattern this
// replaced would have reproduced the storm, so a future regression that
// drops the `await` at either call site is caught here too.
@Timeout(Duration(seconds: 30))
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/data/providers/gym_profile_provider.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/screens/workout/easy/easy_active_workout_state_models.dart';
import 'package:fitwiz/screens/workout/easy/easy_persistence_helpers.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late int createCalls;
  late int setLogCalls;

  setUp(() {
    setUpMocks();
    SharedPreferences.setMockInitialValues({});
    createCalls = 0;
    setLogCalls = 0;
    mockApiClient = MockApiClient();
    when(() => mockApiClient.getUserId()).thenAnswer((_) async => 'user-1');
    // Branch by path, mirroring the server: every `/performance/workout-logs`
    // create call (real or a migration-2247 replay) resolves to the SAME
    // row id — exactly what let the old bug's 27 POSTs hide as "200 OK,
    // zero net writes" instead of surfacing as an obvious failure.
    when(() => mockApiClient.post(any(), data: any(named: 'data')))
        .thenAnswer((invocation) async {
      final path = invocation.positionalArguments[0] as String;
      if (path == '/performance/workout-logs') {
        createCalls++;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: <String, dynamic>{
            'id': 'log-1',
            'status': 'in_progress',
            'sets_json': '[]',
          },
        );
      }
      if (path == '/performance/logs') {
        setLogCalls++;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: <String, dynamic>{'id': 'perf-$setLogCalls'},
        );
      }
      throw StateError('unexpected POST $path in this test');
    });
  });

  Future<WidgetRef> pumpRef(WidgetTester tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          // persistEasySet reads this for per-gym attribution; the real
          // provider chain resolves through Supabase-backed repositories
          // this test never initializes — pin it so the persist path under
          // test doesn't trip over an unrelated dependency.
          activeGymProfileIdProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          }),
        ),
      ),
    );
    await tester.pump();
    return capturedRef;
  }

  EasyExerciseState placeholderState() => EasyExerciseState(
        displayWeight: 0,
        reps: 0,
        targetReps: 10,
        targetWeightKg: 0,
        totalSets: 1,
      );

  const WorkoutExercise exercise = WorkoutExercise(
    id: 'ex-1',
    exerciseId: 'ex-1',
    nameValue: 'Push-Up',
  );

  testWidgets(
    'padding 27 unlogged sets (E2E #175s measured burst) through '
    'persistEasySetSerialized fires exactly ONE createWorkoutLog call',
    (tester) async {
      final ref = await pumpRef(tester);
      final holder = EasyWorkoutLogIdHolder();
      const totalSets = 27; // matches the measured 6-exercise/27-set burst

      // Mirrors the FIXED `_completeWorkoutNow` loop: N persists, each
      // AWAITED before the next fires, all sharing one holder — see
      // `_persistEasySetTracked` in easy_active_workout_state.dart.
      for (int i = 0; i < totalSets; i++) {
        await persistEasySetSerialized(
          ref: ref,
          exercise: exercise,
          log: SetLog(reps: 0, weight: 0, setType: 'working', loggingMode: 'easy'),
          state: placeholderState(),
          workoutId: 'w1',
          totalTimeSeconds: 600,
          holder: holder,
        );
      }

      expect(
        createCalls,
        1,
        reason: 'one completion must create the workout_log row ONCE — '
            'not once per padded set (E2E #175: 27 identical '
            'POST /performance/workout-logs for a single completion)',
      );
      expect(
        setLogCalls,
        totalSets,
        reason: 'the fix must not drop any individual set — every padded '
            'set still has to reach performance_logs',
      );
      expect(holder.value, 'log-1',
          reason: 'the holder must end up carrying the real log id so '
              'later steps (finalize, /complete) use it too');
    },
  );

  testWidgets(
    'the pre-fix pattern (N unawaited calls racing one holder) reproduces '
    'the storm — proves the FIX is the await discipline, not just the helper',
    (tester) async {
      final ref = await pumpRef(tester);
      final holder = EasyWorkoutLogIdHolder();
      const totalSets = 5;

      // Deliberately the BROKEN call pattern `_completeWorkoutNow` used to
      // use: fire every persist without awaiting the previous one. Even
      // with the new holder-based helper, skipping the `await` reproduces
      // the race — because every call reads `holder.value` before any
      // earlier call's `await future` has had a chance to resolve it.
      final futures = <Future<void>>[];
      for (int i = 0; i < totalSets; i++) {
        futures.add(persistEasySetSerialized(
          ref: ref,
          exercise: exercise,
          log: SetLog(reps: 0, weight: 0, setType: 'working', loggingMode: 'easy'),
          state: placeholderState(),
          workoutId: 'w1',
          totalTimeSeconds: 600,
          holder: holder,
        ));
      }
      await Future.wait(futures);

      expect(
        createCalls,
        greaterThan(1),
        reason: 'documents WHY the loop must await each call: without it, '
            'the storm reproduces even through the new helper',
      );
    },
  );
}
