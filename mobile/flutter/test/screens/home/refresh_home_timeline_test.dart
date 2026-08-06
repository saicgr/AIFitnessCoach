/// Regression test for Home → TIMELINE (E2E row 48, HIGH).
///
/// A meal (or any) log made within a running app session never appeared on
/// Home's timeline, and the false "Nothing logged yet today" nudge survived
/// scrolling, tab switches AND an explicit pull-to-refresh — only a full
/// process relaunch picked it up.
///
/// Root cause: `refreshAllHome` (the single consolidated pull-to-refresh
/// helper Home's `AppRefreshIndicator` calls) invalidated ~15 Home-tier
/// providers but never touched `timelineProvider` at all, so pull-to-refresh
/// could never re-fetch the timeline — matching the "survived an explicit
/// pull-to-refresh" symptom exactly. This test pins that `refreshAllHome`
/// forces a `timelineProvider` refresh; a regression back to the old
/// provider list (missing the timeline call) fails it immediately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/coach_refresh_coordinator.dart';
import 'package:fitwiz/data/providers/timeline_provider.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/screens/home/refresh_home.dart';

/// Records `refresh()` calls instead of hitting the network — the exact
/// question this test asks is "did `refreshAllHome` ask the timeline to
/// refresh", not "does the timeline fetch succeed".
class _SpyTimelineNotifier extends StateNotifier<TimelineState>
    implements TimelineNotifier {
  _SpyTimelineNotifier() : super(const TimelineState());

  int refreshCalls = 0;

  @override
  Future<void> refresh({bool showLoading = true}) async {
    refreshCalls++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A real `ApiClient` but without `startAuthListener()` (which needs a live
/// Supabase auth stream) — same construction `test/services/`
/// `api_client_get_coalescing_test.dart` uses. `getUserId()` safely resolves
/// to null with no secure-storage plugin registered in the test binding, so
/// every userId-gated branch in `refreshAllHome` short-circuits harmlessly.
ApiClient _buildTestApiClient() => ApiClient(const FlutterSecureStorage());

/// `CoachRefreshCoordinator._wire()` listens to a chain of other Home
/// providers (fasting, sleep, …) that themselves reach for the network —
/// entirely out of scope for what this test is verifying. Overriding the
/// coordinator with a variant that skips `_wire()` (never invoked here,
/// unlike the real provider) keeps the test to exactly the timeline
/// question.
class _UnwiredCoachRefreshCoordinator extends CoachRefreshCoordinator {
  _UnwiredCoachRefreshCoordinator(super.ref);
}

void main() {
  testWidgets(
      'refreshAllHome (Home pull-to-refresh) forces timelineProvider to '
      'refresh, so a meal/water/workout logged this session appears without '
      'a process relaunch', (tester) async {
    final spyNotifier = _SpyTimelineNotifier();

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWith((ref) => _buildTestApiClient()),
          coachRefreshCoordinatorProvider
              .overrideWith((ref) => _UnwiredCoachRefreshCoordinator(ref)),
          timelineProvider.overrideWith((ref) => spyNotifier),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(spyNotifier.refreshCalls, 0,
        reason: 'sanity: no refresh before refreshAllHome runs');

    // `refreshAllHome` does real async I/O (ApiClient/Dio, secure storage).
    // `testWidgets`'s fake-async zone never advances real Timers/sockets on
    // its own — without `runAsync` this hangs until the whole-suite timeout
    // rather than actually running or timing out.
    await tester.runAsync(
      () => refreshAllHome(capturedRef).timeout(const Duration(seconds: 20)),
    );

    expect(spyNotifier.refreshCalls, greaterThanOrEqualTo(1),
        reason: 'refreshAllHome must refresh timelineProvider — without '
            'this, a meal logged mid-session never appears on Home\'s '
            'timeline and the false "Nothing logged yet today" nudge '
            'survives an explicit pull-to-refresh (E2E row 48)');
  });
}
