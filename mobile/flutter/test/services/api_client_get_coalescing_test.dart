/// Regression gate for the duplicate-request class fixed in `ApiClient.get`.
///
/// Production logs showed identical GETs (hydration daily summary, daily
/// micronutrients) completing in the SAME millisecond — two independent
/// providers/widgets asking for one answer, each opening its own socket.
/// `ApiClient.get` now shares an in-flight GET; these tests pin the exact
/// semantics, including the cases that must NOT share.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fitwiz/data/services/api_client.dart';

/// Counts requests and holds each response open until released, so a test can
/// deterministically issue a second call while the first is still in flight.
class _CountingAdapter implements HttpClientAdapter {
  final List<String> requests = [];
  final List<_Pending> _pending = [];

  /// Body handed back on release. A nested map + list so the deep-copy
  /// isolation test has something structural to mutate.
  String body = '{"ok":true,"nested":{"n":1},"items":[{"i":1}]}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final label = '${options.method} ${options.uri}';
    requests.add(label);
    final c = Completer<ResponseBody>();
    _pending.add(_Pending(label, c));
    return c.future;
  }

  void releaseAll() => releaseWhere((_) => true);

  /// Complete only the in-flight requests whose label matches — lets a test
  /// finish a write while a GET stays genuinely on the wire.
  void releaseWhere(bool Function(String label) test) {
    _pending.removeWhere((p) {
      if (!test(p.label)) return false;
      if (!p.completer.isCompleted) {
        p.completer.complete(
          ResponseBody.fromString(
            body,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
      }
      return true;
    });
  }

  /// Fail (rather than complete) the matching in-flight requests.
  void failWhere(bool Function(String label) test) {
    _pending.removeWhere((p) {
      if (!test(p.label)) return false;
      if (!p.completer.isCompleted) {
        p.completer.completeError(
          DioException.connectionError(
            requestOptions: RequestOptions(path: p.label),
            reason: 'test-induced failure',
          ),
        );
      }
      return true;
    });
  }

  @override
  void close({bool force = false}) {}
}

class _Pending {
  _Pending(this.label, this.completer);

  final String label;
  final Completer<ResponseBody> completer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late ApiClient client;
  late _CountingAdapter adapter;

  setUp(() {
    client = ApiClient(const FlutterSecureStorage());
    adapter = _CountingAdapter();
    client.dio.httpClientAdapter = adapter;
  });

  /// Number of event-loop turns [settle] always pumps. Each
  /// `Future.delayed(Duration.zero)` yields a full turn (timer queue), which
  /// also drains every microtask queued behind it — so this drives the async
  /// interceptor chain (secure-storage token read, timezone header) all the
  /// way to the adapter.
  const settleTurns = 64;

  /// Drains the async interceptor chain deterministically.
  ///
  /// It always pumps the SAME fixed budget of turns and never exits early on
  /// "the request count didn't move" — that early exit is what made this gate
  /// timing-flaky in two ways:
  ///   • one slow tick before the first request reached the adapter ended the
  ///     wait with ZERO requests recorded, failing `expect(length, 1)` for
  ///     reasons unrelated to coalescing;
  ///   • a request that reached the adapter after a momentary lull was never
  ///     observed, so a "must NOT share" assertion could pass spuriously.
  /// Fixed-budget pumping makes the observed request count a pure function of
  /// the code under test, not of host timing.
  Future<void> settle() async {
    for (var i = 0; i < settleTurns; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('identical in-flight GETs issue ONE network request', () async {
    final a = client.get<Map<String, dynamic>>(
      '/hydration/daily/u1',
      queryParameters: {'date_str': '2026-07-21'},
    );
    final b = client.get<Map<String, dynamic>>(
      '/hydration/daily/u1',
      queryParameters: {'date_str': '2026-07-21'},
    );

    await settle();
    expect(adapter.requests.length, 1,
        reason: 'second identical GET must ride the in-flight one');

    adapter.releaseAll();
    final ra = await a;
    final rb = await b;
    expect(ra.data, rb.data);
    expect(adapter.requests.length, 1);
  });

  test('different query parameters are NOT shared', () async {
    final a = client.get<Map<String, dynamic>>(
      '/hydration/daily/u1',
      queryParameters: {'date_str': '2026-07-21'},
    );
    final b = client.get<Map<String, dynamic>>(
      '/hydration/daily/u1',
      queryParameters: {'date_str': '2026-07-20'},
    );
    await settle();
    expect(adapter.requests.length, 2);
    adapter.releaseAll();
    await a;
    await b;
  });

  test('a GET issued AFTER a write never rides a pre-write GET', () async {
    final before = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 1);

    // A write lands mid-flight — the post-write read must see post-write data.
    final write = client.post<Map<String, dynamic>>('/nutrition/log-direct');
    await settle();

    final after = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 3,
        reason: 'read-after-write must open its own request');

    adapter.releaseAll();
    await before;
    await write;
    await after;
  });

  test('a completed GET is not replayed — refresh still hits the network',
      () async {
    final first = client.get<Map<String, dynamic>>('/coach/daily-insight');
    await settle();
    adapter.releaseAll();
    await first;

    final second = client.get<Map<String, dynamic>>('/coach/daily-insight');
    await settle();
    expect(adapter.requests.length, 2,
        reason: 'coalescing is in-flight only, never a response cache');
    adapter.releaseAll();
    await second;
  });

  test(
    'a GET issued after a write COMPLETES never rides a GET opened while that '
    'write was in flight',
    () async {
      // The hole the write-START-only barrier left open. Ordering matters:
      //   1. write starts        (epoch moves — start edge)
      //   2. read A starts       (opened under the SAME epoch as the write)
      //   3. write COMPLETES     (row now exists; epoch must move again)
      //   4. read B issued       (must NOT be answered by A, which was already
      //                           on the wire before the row existed)
      // With the completion edge missing, B rode A and got the pre-write body.
      final write = client.post<Map<String, dynamic>>('/nutrition/log-direct');
      await settle();
      expect(adapter.requests.length, 1);

      final a = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
      await settle();
      expect(adapter.requests.length, 2);

      adapter.releaseWhere((r) => r.contains('log-direct'));
      await write; // write has now COMPLETED

      final b = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
      await settle();
      expect(
        adapter.requests.length,
        3,
        reason: 'a read issued after the write landed must open its own '
            'request, not ride the mid-write read',
      );

      adapter.releaseAll();
      await a;
      await b;
    },
  );

  test('a FAILED write also moves the barrier', () async {
    final write = client.post<Map<String, dynamic>>('/nutrition/log-direct');
    await settle();
    final a = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 2);

    // Fail the write instead of completing it. A write that errored may still
    // have hit the DB (timeout after commit), so the barrier must move.
    adapter.failWhere((r) => r.contains('log-direct'));
    await expectLater(write, throwsA(isA<DioException>()));

    final b = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 3);

    adapter.releaseAll();
    await a;
    await b;
  });

  test('an explicit user refresh is never answered by a pre-refresh GET',
      () async {
    final a = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 1);

    // What `refreshAllHome` calls on pull-to-refresh.
    client.beginUserInitiatedRefresh();

    final b = client.get<Map<String, dynamic>>('/nutrition/summary/daily');
    await settle();
    expect(adapter.requests.length, 2,
        reason: 'pull-to-refresh must issue a fresh request');

    adapter.releaseAll();
    await a;
    await b;
  });

  test('coalesced callers get independent copies of the decoded body',
      () async {
    final a = client.get<Map<String, dynamic>>('/hydration/daily/u1');
    final b = client.get<Map<String, dynamic>>('/hydration/daily/u1');
    await settle();
    expect(adapter.requests.length, 1);
    adapter.releaseAll();

    final ra = await a;
    final rb = await b;

    expect(ra.data, rb.data, reason: 'same payload by value');
    expect(identical(ra.data, rb.data), isFalse,
        reason: 'each caller owns its own map');
    expect(
      identical(
        (ra.data!['nested'] as Map),
        (rb.data!['nested'] as Map),
      ),
      isFalse,
      reason: 'the copy is deep, not shallow',
    );
    expect(
      identical(ra.data!['items'] as List, rb.data!['items'] as List),
      isFalse,
    );

    // Mutating one caller's payload must not corrupt the other's.
    (rb.data!['nested'] as Map)['n'] = 99;
    rb.data!['added'] = true;
    (rb.data!['items'] as List).add({'i': 2});
    expect((ra.data!['nested'] as Map)['n'], 1);
    expect(ra.data!.containsKey('added'), isFalse);
    expect((ra.data!['items'] as List).length, 1);
  });

  test(
    'the ORIGINATING caller cannot corrupt a coalesced follower',
    () async {
      // Dart's `_propagateToListeners` walks a completed future's listeners
      // DEPTH-FIRST: it runs listener #1, completes the future that listener
      // derived, and immediately propagates into THAT future's listeners —
      // before listener #2 is reached. The originator registers listener #1
      // (it called `get` first); the follower registers listener #2.
      //
      // So the originator's own continuation runs BEFORE the follower's
      // isolation callback. Handing the originator the raw shared `Response`
      // therefore let it mutate the payload the follower was about to copy —
      // "each caller gets an isolated deep copy" was true only if the
      // originator happened not to touch its data first.
      //
      // The fix is structural: once a second caller attaches, NOBODY receives
      // the raw response — the originator gets a copy too — so the shared
      // payload is unreachable from application code and every copy is taken
      // from a pristine tree regardless of listener order.
      final a = client.get<Map<String, dynamic>>('/hydration/daily/u1');

      // Registered on the originator's returned future, i.e. it runs at
      // listener-#1 depth, strictly before the follower's copy is taken.
      final aMutated = a.then((r) {
        (r.data!['nested'] as Map)['n'] = 999;
        (r.data!['items'] as List).add({'i': 2});
        r.data!['originatorOnly'] = true;
        return r;
      });

      final b = client.get<Map<String, dynamic>>('/hydration/daily/u1');
      await settle();
      expect(adapter.requests.length, 1);
      adapter.releaseAll();

      final ra = await aMutated;
      final rb = await b;

      expect(identical(ra.data, rb.data), isFalse);
      expect(
        (rb.data!['nested'] as Map)['n'],
        1,
        reason: 'follower must see the payload as it came off the wire, not '
            'as the originating caller left it',
      );
      expect((rb.data!['items'] as List).length, 1);
      expect(rb.data!.containsKey('originatorOnly'), isFalse);

      // And the originator really did keep its own edits.
      expect((ra.data!['nested'] as Map)['n'], 999);
      expect(ra.data!['originatorOnly'], isTrue);
    },
  );

  test('a follower attaching to a FAILED shared GET still gets the error',
      () async {
    final a = client.get<Map<String, dynamic>>('/hydration/daily/u1');
    final b = client.get<Map<String, dynamic>>('/hydration/daily/u1');
    await settle();
    expect(adapter.requests.length, 1);

    adapter.failWhere((_) => true);
    await expectLater(a, throwsA(isA<DioException>()));
    await expectLater(b, throwsA(isA<DioException>()));

    // The failed entry must not linger and poison the next read.
    final c = client.get<Map<String, dynamic>>('/hydration/daily/u1');
    await settle();
    expect(adapter.requests.length, 2,
        reason: 'a failed GET must be released from the in-flight map');
    adapter.releaseAll();
    await c;
  });

  test('a GET carrying a CancelToken opts out of sharing', () async {
    final token = CancelToken();
    final a = client.get<Map<String, dynamic>>('/workouts/today');
    final b = client.get<Map<String, dynamic>>(
      '/workouts/today',
      cancelToken: token,
    );
    await settle();
    expect(adapter.requests.length, 2,
        reason: 'one caller cancelling must not abort another');
    adapter.releaseAll();
    await a;
    await b;
  });

  // ── Chokepoint gate ──────────────────────────────────────────────────────
  //
  // GET coalescing is GLOBAL, so the `beginUserInitiatedRefresh()` opt-out is
  // not optional: on any screen that skips it, a pull-to-refresh issued while
  // an identical GET is in flight is answered by the older request and "pull
  // to refresh" silently does not refresh. That opt-out used to be spelled out
  // at 2 of the 96 files containing a `RefreshIndicator`.
  //
  // `AppRefreshIndicator` (lib/screens/common/app_refresh_indicator.dart) now
  // makes the call for every screen. This test is what keeps that true: a
  // convention nobody enforces decays back to 2/96 with the next screen
  // someone writes. It lives in this file because the invariant it protects is
  // `ApiClient`'s, not any one screen's.
  test('no screen constructs Material RefreshIndicator directly', () {
    final wrapper = File(
      'lib/screens/common/app_refresh_indicator.dart',
    ).absolute.path;
    // `RefreshIndicator(`, `RefreshIndicator.adaptive(`,
    // `RefreshIndicator.noSpinner(` — but not `RefreshIndicatorState` or
    // `RefreshIndicatorTriggerMode`, which are fine to reference.
    final ctor = RegExp(
      r'(?<![A-Za-z0-9_$])RefreshIndicator\s*(?:\(|\.\s*(?:adaptive|noSpinner)\s*\()',
    );

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.absolute.path == wrapper) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (ctor.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use AppRefreshIndicator instead — it calls '
          'ApiClient.beginUserInitiatedRefresh() before the handler runs, so '
          'the refresh cannot be answered by a GET that was already on the '
          'wire when the user pulled. Offending sites:\n'
          '${offenders.join('\n')}',
    );
  });

  test('AppRefreshIndicator is the only opt-out screens need', () {
    final wrapper = File('lib/screens/common/app_refresh_indicator.dart')
        .readAsStringSync();
    expect(
      wrapper.contains('beginUserInitiatedRefresh()'),
      isTrue,
      reason: 'the wrapper is the chokepoint — if it stops bumping the epoch, '
          'every pull-to-refresh in the app silently stops refreshing',
    );
    expect(
      RegExp(r'(?<![A-Za-z0-9_$])RefreshIndicator\s*\(').hasMatch(wrapper),
      isTrue,
      reason: 'and it must still actually render a RefreshIndicator',
    );
  });
}
