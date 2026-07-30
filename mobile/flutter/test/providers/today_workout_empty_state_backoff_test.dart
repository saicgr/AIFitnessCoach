// REGRESSION GATE — E2E 2026-07-28, issues #12 and #92.
//
// #12: the bounded empty-state ladder (3 → 6 → 12 → 24 → 48s, then stand down)
// shipped but never advanced. `_cancelPolling()` called
// `_resetEmptyStateRefreshBackoff()`, and `_cancelPolling()` runs on EVERY
// non-generating response — a strict superset of every empty response — BEFORE
// `_scheduleEmptyStateRefresh()` arms the next timer. So the counter was 0 on
// entry to every cycle, the delay was pinned at `3 * (1 << 0)` = 3s, and the
// ceiling could never latch: 20 requests a minute, forever, per client.
//
// #92: the rest-day half of the loop fix leaned on a DEAD term.
// `hasDisplayableContent` counts `restDayMessage != null`, but the backend's
// TodayWorkoutResponse (backend/api/v1/workouts/today.py:286-310) has no
// `rest_day_message` field at all, so it is always null in production. A rest
// day with nothing upcoming — `today:null, next:null, completed:false,
// generating:false, needs_generation:false`, reachable for any user with empty
// `ai_generation_days` (needs_generation is gated on it at today.py:1496) —
// therefore read as "nothing to show", the watchdog called it stuck, and the
// cache guard refused to store it. 21 watchdog fires in 120s on device.
//
// The real settled signal is the one the BACKEND uses: it caches a response
// under the full TTL when `is_generating` and `needs_generation` are both false
// and under a 30s transient TTL otherwise (today.py:1595-1601).
//
// These tests drive the real notifier through the real repository against a
// mocked ApiClient — no code reading.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/local/database_provider.dart';
import 'package:fitwiz/data/providers/today_workout_provider.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/data/services/data_cache_service.dart';

import '../helpers/test_helpers.dart';

/// The notifier reads `authStateProvider` on every fetch (to gate auto-gen on
/// onboarding completion) and the real one opens a Supabase auth listener.
/// A signed-out fake is enough: `onboarding_completed == false` short-circuits
/// the auto-generation branch, which is exactly what we want out of the way.
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// A `/today` 200 with a FINAL answer and nothing to show: the unscheduled
/// rest day / end-of-program shape.
Map<String, dynamic> settledEmptyJson() => <String, dynamic>{
      'has_workout_today': false,
      'today_workout': null,
      'next_workout': null,
      'extra_today_workouts': <dynamic>[],
      'completed_today': false,
      'is_generating': false,
      'needs_generation': false,
    };

/// A `/today` 200 that carries a workout — ends the empty-state cycle.
Map<String, dynamic> contentJson() => <String, dynamic>{
      'has_workout_today': true,
      'today_workout': <String, dynamic>{
        'id': 'w1',
        'name': 'Push Day',
        'type': 'strength',
        'difficulty': 'moderate',
        'duration_minutes': 45,
        'exercise_count': 6,
        'primary_muscles': <String>['Chest'],
        'scheduled_date': '2026-07-29',
        'is_today': true,
        'is_completed': false,
        'exercises': <dynamic>[],
      },
      'completed_today': false,
      'is_generating': false,
      'needs_generation': false,
    };

/// A `/today` 200 the backend has NOT settled — it still owes us a workout.
Map<String, dynamic> needsGenerationJson() => <String, dynamic>{
      'has_workout_today': false,
      'today_workout': null,
      'next_workout': null,
      'completed_today': false,
      'is_generating': false,
      'needs_generation': true,
      'next_workout_date': '2026-07-30',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient api;
  late ProviderContainer container;
  late Map<String, dynamic> payload;
  late int getCalls;

  /// The notifier under test, built directly so the test doesn't depend on the
  /// auth-state rebuild boundary in the real `todayWorkoutProvider`.
  final underTest = StateNotifierProvider<TodayWorkoutNotifier,
      AsyncValue<TodayWorkoutResponse?>>((ref) => TodayWorkoutNotifier(ref));

  setUp(() async {
    setUpMocks();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TodayWorkoutNotifier.clearCache();
    // DataCacheService holds a static SharedPreferences handle, so
    // setMockInitialValues alone does not clear what an earlier test wrote.
    await DataCacheService.instance.invalidate(DataCacheService.todayWorkoutKey);
    api = MockApiClient();
    payload = settledEmptyJson();
    getCalls = 0;

    when(() => api.getUserId()).thenAnswer((_) async => 'test-user-id');
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async {
      getCalls++;
      return Response<dynamic>(
        requestOptions: RequestOptions(path: '/workouts/today'),
        statusCode: 200,
        data: payload,
      );
    });

    container = ProviderContainer(overrides: <Override>[
      workoutRepositoryProvider.overrideWithValue(WorkoutRepository(api)),
      authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
      // The Drift/SQLite mirror is out of scope here (and its plugins aren't
      // available in a unit test). The notifier reads it inside try/catch;
      // failing the read synchronously keeps the failure inside that guard
      // instead of leaking an async plugin error into the test zone.
      appDatabaseProvider.overrideWith(
        (ref) => throw UnimplementedError('local DB not used in this test'),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
    TodayWorkoutNotifier.clearCache();
  });

  /// Wait until the constructor's own fetch has armed [n] ladder rungs.
  Future<void> waitForAttempts(TodayWorkoutNotifier n, int target) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (n.debugEmptyStateAttempts < target &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  group('#12 — bounded empty-state ladder actually advances', () {
    test('the ladder walks 3 → 6 → 12 → 24 → 48s and then stands down',
        () async {
      final notifier = container.read(underTest.notifier);
      await waitForAttempts(notifier, 1);

      // Rung 1 comes from the constructor's own fetch.
      expect(notifier.debugEmptyStateAttempts, 1);
      expect(notifier.debugLastEmptyStateDelay, const Duration(seconds: 3));

      final observed = <int>[notifier.debugLastEmptyStateDelay!.inSeconds];
      // Each further fetch is one more rung. `debugFetchOnce` deliberately
      // does NOT reset the ladder — that is the whole point of the fix.
      for (var i = 0; i < 4; i++) {
        await notifier.debugFetchOnce();
        observed.add(notifier.debugLastEmptyStateDelay!.inSeconds);
      }

      expect(observed, <int>[3, 6, 12, 24, 48],
          reason: 'the ladder must advance; before the fix every rung was 3s');
      expect(notifier.debugEmptyStateAttempts, 5);

      // Ceiling: a 6th empty response must NOT arm another timer.
      await notifier.debugFetchOnce();
      expect(notifier.debugEmptyStateAttempts, 5,
          reason: 'the counter only increments when a timer is armed, so a '
              'flat 5 proves the ladder stood down');
      expect(notifier.debugLastEmptyStateDelay, const Duration(seconds: 48));

      // And it really did keep polling that many times and no more: 1
      // constructor fetch + 5 driven fetches.
      expect(getCalls, 6);
    });

    test('a response with content resets the ladder', () async {
      final notifier = container.read(underTest.notifier);
      await waitForAttempts(notifier, 1);
      await notifier.debugFetchOnce();
      expect(notifier.debugEmptyStateAttempts, 2);

      payload = contentJson();
      await notifier.debugFetchOnce();
      expect(notifier.debugEmptyStateAttempts, 0);
      expect(notifier.debugLastEmptyStateDelay, isNull);

      // Next empty day starts a fresh ladder at 3s.
      payload = settledEmptyJson();
      await notifier.debugFetchOnce();
      expect(notifier.debugLastEmptyStateDelay, const Duration(seconds: 3));
    });

    test('an explicit user refresh re-arms an exhausted ladder', () async {
      final notifier = container.read(underTest.notifier);
      await waitForAttempts(notifier, 1);
      for (var i = 0; i < 5; i++) {
        await notifier.debugFetchOnce();
      }
      expect(notifier.debugEmptyStateAttempts, 5);

      await notifier.refresh();
      expect(notifier.debugLastEmptyStateDelay, const Duration(seconds: 3),
          reason: 'pull-to-refresh must recover a client that backed all the '
              'way off');
      expect(notifier.debugEmptyStateAttempts, 1);
    });

    test('an unsettled (needs_generation) response never enters the ladder',
        () async {
      payload = needsGenerationJson();
      final notifier = container.read(underTest.notifier);
      // Give the constructor fetch time to complete.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(notifier.debugEmptyStateAttempts, 0);
      expect(notifier.debugLastEmptyStateDelay, isNull);
    });

    test('the rung delays are exactly 3/6/12/24/48', () {
      expect(
        List<int>.generate(
          5,
          (i) => TodayWorkoutNotifier.emptyStateRefreshDelayFor(i).inSeconds,
        ),
        <int>[3, 6, 12, 24, 48],
      );
    });
  });

  group('#92 — a settled rest day is a final answer, not a stuck state', () {
    test('the watchdog does not consider a settled empty response stuck',
        () async {
      final notifier = container.read(underTest.notifier);
      await waitForAttempts(notifier, 1);

      expect(notifier.state.valueOrNull, isNotNull);
      expect(notifier.state.valueOrNull!.hasDisplayableContent, isFalse,
          reason: 'this is precisely the shape that has nothing to show — and '
              'restDayMessage is null because the backend never sends it');
      expect(notifier.debugIsStuckState, isFalse,
          reason: 'a final answer is never stuck; treating it as stuck is the '
              '#92 5s watchdog loop');
    });

    test('a settled rest day is allowed to replace a populated cache',
        () async {
      // Yesterday's good response is still in the in-memory cache.
      TodayWorkoutNotifier.preSeedCache(TodayWorkoutResponse.fromJson(
        contentJson(),
      ));
      expect(
        TodayWorkoutNotifier.debugInMemoryCache!.hasDisplayableContent,
        isTrue,
      );

      final notifier = container.read(underTest.notifier);
      await waitForAttempts(notifier, 1);

      final cached = TodayWorkoutNotifier.debugInMemoryCache;
      expect(cached, isNotNull);
      expect(cached!.hasWorkoutToday, isFalse);
      expect(cached.todayWorkout, isNull,
          reason: 'the cache guard must let a FINAL answer through; refusing '
              'it left the cache populated and the state unchanged forever');
    });

    test('an unsettled empty response still cannot clobber a populated cache',
        () async {
      TodayWorkoutNotifier.preSeedCache(TodayWorkoutResponse.fromJson(
        contentJson(),
      ));
      payload = needsGenerationJson();

      final notifier = container.read(underTest.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(TodayWorkoutNotifier.debugInMemoryCache!.todayWorkout, isNotNull,
          reason: 'while the backend still owes us a workout, an empty '
              'response is "no data right now" — keep the last good one');
      // Silence the unused-variable lint without weakening the assertion.
      expect(notifier.debugEmptyStateAttempts, 0);
    });

    test('a cold state with no answer at all IS stuck', () async {
      final never = Completer<Response<dynamic>>();
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) => never.future);

      final notifier = container.read(underTest.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.valueOrNull, isNull);
      expect(notifier.debugIsStuckState, isTrue,
          reason: 'the one case the watchdog exists for: a fetch that never '
              'landed');
    });
  });
}
