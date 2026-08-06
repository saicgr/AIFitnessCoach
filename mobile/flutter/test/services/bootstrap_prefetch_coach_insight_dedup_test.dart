/// Regression gate for Sentry FITWIZ-FLUTTER-AX (30s receive timeout on
/// `/splash`) and FITWIZ-FLUTTER-FY ("N+1 API Call" on
/// `/coach/daily-insight`).
///
/// `BootstrapPrefetchService.prefetchCoachInsight` (fired fire-and-forget from
/// the `/splash` → home router redirect) used to warm the coach-insight disk
/// cache with its OWN independent `api.get('/coach/daily-insight', ...)`
/// call — completely uncoordinated with `dailyCoachInsightProvider`'s own
/// fetch (triggered the moment `CoachHeroCard` watches it, or by
/// `MainShell`'s prewarm waves). Both check the disk cache first, but
/// check-then-fetch has no lock between two unrelated callers: on a genuine
/// cold start (fresh install, or a new calendar day — no cache entry yet)
/// both callers see a miss and BOTH fire a GET at the same slow (up to the
/// full 30s receive-timeout), Gemini-backed endpoint. Two concurrent
/// requests instead of one doubles the odds either one eats the timeout
/// (AX) and shows up as a duplicate-shaped call to Sentry's N+1 detector
/// (FY) — both tagged `route=/splash`, right in the app's most
/// latency-sensitive cold-start window.
///
/// `prefetchCoachInsight` now reads THROUGH `dailyCoachInsightProvider.future`
/// instead of making its own request, so Riverpod's normal
/// single-Future-per-provider-instance semantics dedupe the two callers onto
/// ONE network request. This test drives that exact chokepoint directly
/// (not the full `prefetch()` → `/home/bootstrap` flow, which needs a real
/// Supabase session and has nothing to do with this bug) by simulating both
/// callers racing the same cold-start window a real device hits.
///
/// Why this has to reproduce the tz-resolution timing, not just "two
/// concurrent reads": `ApiClient.get` already coalesces identical in-flight
/// GETs (see `api_client_get_coalescing_test.dart`), so two callers hitting
/// the exact same query string would already collapse to one request even
/// under the OLD code. The bug survived that because the OLD
/// `prefetchCoachInsight` built its OWN `tz` query param by hand
/// (`timezoneProvider.isLoading ? DateTime.now().timeZoneName :
/// tzState.timezone` — a device offset abbreviation fallback while the real
/// IANA zone is still resolving), while `dailyCoachInsightProvider` simply
/// refuses to fetch at all until `timezoneProvider` settles. On the very
/// early redirect-time call (timezone genuinely still loading at cold
/// start), the OLD code fired with e.g. `tz=CDT`; once the zone resolved and
/// `CoachHeroCard` watched the provider moments later, IT fired with
/// `tz=America/Chicago` — two DIFFERENT query strings, so `ApiClient`'s
/// coalescing (keyed on the full query) never even saw them as the same
/// request. This test drives exactly that timing.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/timezone_provider.dart';
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/data/providers/daily_coach_insight_provider.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/data/services/bootstrap_prefetch_service.dart';

import '../helpers/fake_supabase.dart';

/// Records every request and holds each open until [releaseAll] — lets the
/// test deterministically observe how many requests were opened BEFORE
/// either caller's fetch resolves. Mirrors
/// `test/services/api_client_get_coalescing_test.dart`'s `_CountingAdapter`.
class _CountingAdapter implements HttpClientAdapter {
  final List<String> requests = [];
  final List<Completer<ResponseBody>> _pending = [];

  final String body =
      '{"headline":"Test headline","body":"Test body","delivery":"generated",'
      '"chips":[],"cta_primary":null,"cta_secondary":null}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add('${options.method} ${options.uri}');
    final c = Completer<ResponseBody>();
    _pending.add(c);
    return c.future;
  }

  void releaseAll() {
    for (final c in _pending) {
      if (!c.isCompleted) {
        c.complete(
          ResponseBody.fromString(
            body,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
      }
    }
    _pending.clear();
  }

  @override
  void close({bool force = false}) {}
}

app_user.User _testUser() => const app_user.User(
      id: 'user-123',
      email: 'test@example.com',
      name: 'Test User',
      createdAt: '2026-01-01T00:00:00.000Z',
    );

/// Fixed, already-authenticated auth state — `dailyCoachInsightProvider` only
/// ever reads `.state` off this (via `authStateProvider.select`), so a bare
/// `StateNotifier` implementing the interface (never calling any
/// `AuthNotifier`-specific method) is sufficient.
class _FixedAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FixedAuthNotifier()
      : super(AuthState(status: AuthStatus.authenticated, user: _testUser()));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Starts `isLoading: true` (the real cold-start state — the IANA zone
/// hasn't resolved from disk/plugin yet) and exposes [resolve] to flip to the
/// settled `America/Chicago` state a moment later, reproducing the actual
/// production timing `dailyCoachInsightProvider`'s own gate depends on.
class _RaceyTimezoneNotifier extends StateNotifier<TimezoneState>
    implements TimezoneNotifier {
  _RaceyTimezoneNotifier() : super(const TimezoneState(isLoading: true));

  void resolve() {
    state = const TimezoneState(timezone: 'America/Chicago', isLoading: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late _CountingAdapter adapter;
  late ProviderContainer container;
  late _RaceyTimezoneNotifier tzNotifier;

  /// Drains the async interceptor chain (auth header, secure-storage read,
  /// etc.) deterministically — same fixed-budget approach as
  /// `api_client_get_coalescing_test.dart`'s `settle()`, and for the same
  /// reason: an early exit on "request count didn't move" would make this
  /// gate flaky in either direction.
  Future<void> settle() async {
    for (var i = 0; i < 64; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    await initFakeSupabase(); // signed-out Supabase singleton; also resets
    // SharedPreferences to empty — genuine cold start, no coach-insight
    // cache entry, so both callers below actually reach the network.

    adapter = _CountingAdapter();
    final client = ApiClient(const FlutterSecureStorage());
    client.dio.httpClientAdapter = adapter;

    tzNotifier = _RaceyTimezoneNotifier();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authStateProvider.overrideWith((ref) => _FixedAuthNotifier()),
        timezoneProvider.overrideWith((ref) => tzNotifier),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'BootstrapPrefetchService.prefetchCoachInsight does not fire its own '
    '/coach/daily-insight request while the timezone is still resolving — '
    'it shares whatever dailyCoachInsightProvider fetches once it settles',
    () async {
      // `Provider<Ref>` is the standard headless way to hand a real `Ref` to
      // a static function under test without pumping a widget tree.
      final refCaptureProvider = Provider<Ref>((ref) => ref);
      final ref = container.read(refCaptureProvider);

      // Step 1 — the redirect-time warm-up fires at the earliest possible
      // moment: timezone genuinely still loading (the real cold-start
      // state). The OLD code built its own request here with a
      // device-offset fallback tz; the FIX must not hit the network at all
      // yet (mirrors dailyCoachInsightProvider's own gate).
      final prefetchFuture =
          BootstrapPrefetchService.prefetchCoachInsight(ref, 'user-123');
      await settle();

      // Step 2 — the timezone settles a moment later (disk/plugin resolves)
      // and CoachHeroCard mounts, watching the provider for real.
      tzNotifier.resolve();
      final heroCardFuture = container.read(dailyCoachInsightProvider.future);
      await settle();

      expect(
        adapter.requests.length,
        1,
        reason:
            'BootstrapPrefetchService.prefetchCoachInsight must not open its '
            'own /coach/daily-insight request while the timezone is still '
            'resolving (it used a device-offset tz fallback that never '
            'matched what dailyCoachInsightProvider fetches once the real '
            'IANA zone settles) — that mismatched pair is exactly the FY '
            '(N+1) / AX (receive timeout) issue.',
      );

      adapter.releaseAll();
      await heroCardFuture;
      await prefetchFuture;

      // Still exactly one — releasing/awaiting must not trigger a second,
      // deferred request.
      expect(adapter.requests.length, 1);
      expect(
        adapter.requests.single,
        contains('tz=America%2FChicago'),
        reason: 'the one request that IS made must carry the real IANA '
            'zone, not a device-offset placeholder',
      );
    },
  );
}
