/// Regression test for Library → Exercises tab → search
/// (E2E row 3, CRIT — "typing an exact exercise name does not surface it").
///
/// Backend was verified correct (exact match ranks first for the full query
/// string). Root cause is client-side: `ExercisesTab.build()` fires a new
/// `ExercisesNotifier.loadExercises(refresh: true)` on EVERY keystroke via a
/// post-frame callback (no debounce), but the notifier's
/// `if (state.isLoading) return;` guard silently dropped any call that
/// arrived while a previous one was still in flight. Typing "Barbell Bench
/// Press" fires ~19 such calls; only the FIRST character's request ever
/// reached the network — every later keystroke was a no-op, and because the
/// tab's `_prevSearch` bookkeeping advances unconditionally in the same
/// build (regardless of whether the fetch fired), no later build ever
/// retried the dropped searches. The list was left showing results for a
/// 1-2 character prefix — explaining trigram/first-letter-only matches.
///
/// The fix coalesces (not drops) an in-flight collision: a `refresh: true`
/// call that arrives mid-flight sets a pending flag, and the in-flight
/// request chases it with one more `loadExercises(refresh: true)` once it
/// settles — converging to whatever search text is current by then.
///
/// TEST-ORDER-POLLUTION NOTE (investigated during the post-fix-campaign test
/// sweep): a full-suite `flutter test` run showed exactly one failure, in
/// THIS file, at the assertion pinning the chase request. Isolated, this
/// file always passed; it only flaked when run alongside the rest of
/// `test/screens/library` (bisected down from the full suite). Instrumented
/// `ExercisesNotifier.loadExercises` with temporary logging and confirmed
/// the coalescing logic itself is correct and fires the chase promptly every
/// time — the actual shortfall was `settle()`'s fixed 64-turn budget, too
/// small to reliably drain a whole fresh Dio request pipeline (auth token +
/// timezone + app-version interceptors, several of them real platform-channel
/// round trips) under the CPU contention of a full concurrent test run.
/// Raised to 300 turns (see `settle()` below) — reproduced-clean under both
/// the full `test/screens/library` directory and artificial heavy CPU load.
/// This was test-side flakiness, not a production regression: no production
/// code changed.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart';

/// The real provider auto-fires `loadFirstPageCacheFirst()` (cache-first
/// default view) the moment it's first read — irrelevant noise for a test
/// that wants full control over exactly which `loadExercises()` calls fire
/// and when. No-op it; the test drives `loadExercises` explicitly instead.
class _NoAutoInitExercisesNotifier extends ExercisesNotifier {
  _NoAutoInitExercisesNotifier(super.ref);

  @override
  Future<void> loadFirstPageCacheFirst() async {}
}

/// Holds each response open until explicitly released, so the test can
/// deterministically simulate "user keeps typing while the first character's
/// request is still on the wire".
class _HoldingAdapter implements HttpClientAdapter {
  final List<String> requestedSearches = [];
  final Map<String, Completer<ResponseBody>> _pending = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final search = options.uri.queryParameters['search'] ?? '';
    requestedSearches.add(search);
    final completer = Completer<ResponseBody>();
    _pending[search] = completer;
    return completer.future;
  }

  /// Complete the request for [search] with [ids], as if the backend
  /// returned exactly those (in order).
  void release(String search, List<String> ids) {
    final completer = _pending.remove(search);
    if (completer == null) return;
    final items =
        ids.map((id) => '{"id":"$id","name":"$id"}').join(',');
    completer.complete(
      ResponseBody.fromString(
        '[$items]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late ApiClient client;
  late _HoldingAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    client = ApiClient(const FlutterSecureStorage());
    adapter = _HoldingAdapter();
    client.dio.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        exercisesNotifierProvider.overrideWith(
          (ref) => _NoAutoInitExercisesNotifier(ref),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Same fixed-budget interceptor-chain drain pattern as
  /// `api_client_get_coalescing_test.dart`, but with a bigger budget: unlike
  /// that file (which calls `settle()` after every small step), each call
  /// here has to drain a WHOLE Dio request pipeline from scratch — auth
  /// token lookup, the timezone header (SharedPreferences + platform-channel
  /// fallback), the app-version header (another platform channel) — before
  /// `_HoldingAdapter.fetch()` is even reached and `requestedSearches` grows.
  /// 64 turns was flaky under load (verified: test-order pollution report
  /// traced a suite-wide `flutter test` flake to this file — see the
  /// investigation note above `main()`): CPU contention from the other ~300
  /// widget tests in a full run stretches how many event-loop turns that
  /// pipeline needs before `apiClient.get()`'s follower actually reaches the
  /// adapter, and the production coalescing logic (`_pendingSearchReload` in
  /// `ExercisesNotifier.loadExercises`) was confirmed correct by tracing it
  /// with temporary instrumentation — the chase call was always issued
  /// promptly; the shortfall was purely this drain running out of turns
  /// before the adapter saw it. 300 turns is comfortably above the observed
  /// worst case (reproduced with the whole `test/screens/library` directory
  /// running concurrently, plus 14 artificial CPU-bound processes racing
  /// for cores) with margin to spare.
  Future<void> settle() async {
    for (var i = 0; i < 300; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'a search fired while an earlier keystroke\'s request is still in '
    'flight is chased, not dropped — the list ends up reflecting the FULL '
    'typed query, not just its first character',
    () async {
      final notifier = container.read(exercisesNotifierProvider.notifier);

      // Keystroke 1: "B" — starts a request that we hold open.
      container.read(exerciseSearchProvider.notifier).state = 'B';
      final call1 = notifier.loadExercises(refresh: true);
      await settle();
      expect(adapter.requestedSearches, ['B']);

      // The user keeps typing while "B" is still in flight. Each of these
      // mirrors ExercisesTab's per-keystroke `loadExercises(refresh: true)`
      // call — previously silently dropped.
      for (final partial in ['Ba', 'Bar', 'Barbell', 'Barbell Bench Press']) {
        container.read(exerciseSearchProvider.notifier).state = partial;
        await notifier.loadExercises(refresh: true);
      }
      await settle();

      // None of the mid-flight keystrokes issued their own network call —
      // only "B" is on the wire so far (the coalescing point, not a request
      // storm).
      expect(adapter.requestedSearches, ['B']);

      // "B"'s request finally resolves with broad/trigram-ish matches —
      // exactly what the reported bug showed (B-Skip, Burpee, Barbell Curl…).
      // NOT awaiting `call1` here — its Future only completes once the
      // chased trailing request (below) also resolves, so awaiting it before
      // releasing that one would deadlock the test.
      adapter.release('B', ['b-skip', 'burpee', 'barbell-curl']);
      await settle();

      // The fix: settling "B" must have chased a trailing request for the
      // LATEST text the user had typed by then, not left the list stuck on
      // "B"'s broad results.
      expect(
        adapter.requestedSearches,
        ['B', 'Barbell Bench Press'],
        reason: 'the final keystroke\'s search must reach the network once '
            'the in-flight one settles, instead of being silently dropped',
      );

      // Resolve the chased request with the real exact match.
      adapter.release('Barbell Bench Press', ['barbell-bench-press']);
      await settle();

      final finalState = container.read(exercisesNotifierProvider);
      expect(
        finalState.exercises.map((e) => e.id),
        ['barbell-bench-press'],
        reason: 'the list must reflect the exact-match result for the full '
            'typed query, not the "B"-only trigram matches',
      );

      // `call1` (the original "B" request) only resolves once its chase
      // (above) also resolves — both are released by now, so awaiting it
      // here confirms the outer Future actually completes cleanly instead
      // of hanging or throwing.
      await call1;
    },
  );
}
