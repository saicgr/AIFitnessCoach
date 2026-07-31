// E2E register #1 client half — a failed offline finalize strands a
// session at `in_progress`.
//
// `runEasyBackgroundSave`'s step (1) — the finalize write that fills
// `sets_json`/`metadata`/final `total_time_seconds` on the parent
// `workout_log` row — called `updateWorkoutLog`/`createWorkoutLog` directly
// with NO queue and NO retry; both swallow every failure and return `null`.
// Only step (2) (`/complete`) was queued. So a device offline at Finish
// permanently stranded the log at `sets_json='[]'` (in_progress,
// post-migration-2390) even though every individual set had already
// persisted.
//
// This gate drives `runEasyBackgroundSave` with the finalize PATCH forced
// to fail (simulating offline) and asserts the write lands in the new
// `workout_finalize_easy` offline queue instead of being silently dropped.
//
// Negative-tested: reverting `easy_persistence_helpers.dart` to call
// `repo.updateWorkoutLog(...)` directly (no `_easyFinalizeWithOfflineFallback`
// wrapper) reproduces "nothing queued, set data lost" and fails this test.
@Timeout(Duration(seconds: 30))
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/cache/offline_write_queue.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/screens/workout/easy/easy_persistence_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;

  // A failed finalize calls `OfflineWriteQueue.bindConnectivity`, which opens
  // `Connectivity().onConnectivityChanged` — a real EventChannel with no
  // native counterpart in a widget test. Left unmocked, listening on it can
  // stall the test binding waiting on a platform message that never resolves.
  // Mock it to an empty, immediately-open stream (same pattern as
  // `secure_storage_timeout_test.dart`'s MethodChannel mock).
  const connectivityEventChannel =
      EventChannel('dev.fluttercommunity.plus/connectivity_status');

  setUp(() {
    setUpMocks();
    // THE hang, not the connectivity channel: OfflineWriteQueue persists to
    // SharedPreferences, and in a widget test `getInstance()` never resolves
    // unless mock values are installed — so the test blocked on a platform
    // message forever instead of failing.
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      connectivityEventChannel,
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
    mockApiClient = MockApiClient();
    when(() => mockApiClient.getUserId()).thenAnswer((_) async => 'user-1');
    // /complete (step 2) — let it succeed trivially so it never enqueues on
    // its own queue, keeping this test's assertion scoped to step 1.
    when(() => mockApiClient.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/complete'),
              statusCode: 200,
              data: {'message': 'ok', 'has_prs': false},
            ));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(connectivityEventChannel, null);
  });

  Future<WidgetRef> pumpRef(WidgetTester tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
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

  EasyLocalAggregates aggregates() => const EasyLocalAggregates(
        totalSets: 1,
        totalReps: 8,
        totalVolumeKg: 480,
        calories: 100,
        exercisesPerformance: [],
        exerciseSets: [],
        setsJson: '[{"reps":8,"weight_kg":60}]',
        setsJsonList: [
          {'reps': 8, 'weight_kg': 60},
        ],
      );

  testWidgets(
      'an offline finalize (update path) enqueues instead of dropping the sets',
      (tester) async {
    // Clear any leftover queue state from a previous test run in this process.
    await OfflineWriteQueue(feature: 'workout_finalize_easy').clear('user-1');

    when(() => mockApiClient.patch(any(), data: any(named: 'data')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/performance/workout-logs/log-1'),
      type: DioExceptionType.connectionError,
    ));
    // `runEasyBackgroundSave` is a TWO-step sequence: step (1) is the finalize
    // PATCH under test, step (2) fires `/complete` through its own offline
    // fallback. Only stubbing `patch` left step (2)'s `post` unstubbed, so the
    // call hung the binding for the full 10-minute timeout instead of failing
    // fast — a hanging test is worse for CI than a failing one. Stub it to the
    // same offline error so the whole finalize runs its offline path, which is
    // the scenario this test exists to cover.
    when(() => mockApiClient.post(any(), data: any(named: 'data')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/workouts/w1/complete'),
      type: DioExceptionType.connectionError,
    ));
    when(() => mockApiClient.getUserId()).thenAnswer((_) async => 'user-1');

    final ref = await pumpRef(tester);

    // Drive the finalize step directly. `runEasyBackgroundSave` is a two-step
    // sequence whose second step (/complete) binds its own connectivity
    // listener, which stalls the test binding on a platform channel that never
    // resolves — the test hung for the full 10-minute timeout instead of
    // asserting. `bindReplay: false` skips only the replay SUBSCRIPTION; the
    // enqueue under test runs exactly as it does in production.
    await easyFinalizeWithOfflineFallbackForTest(
      ref: ref,
      workout: const Workout(id: 'w1', name: 'Test Workout'),
      workoutLogId: 'log-1',
      setsJson: aggregates().setsJson,
      totalTimeSeconds: 600,
      metadata: const {'logging_mode': 'easy'},
    );

    final depth =
        await OfflineWriteQueue(feature: 'workout_finalize_easy').depth('user-1');
    expect(depth, 1,
        reason: 'a failed finalize must be queued for replay, never dropped');
  });
}
