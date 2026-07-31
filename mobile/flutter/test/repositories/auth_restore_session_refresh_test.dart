/// Regression gate for E2E register #82 — "the session drops after an idle
/// period and the app returns to the intro carousel".
///
/// Root cause: on a cold start after the app has been idle long enough for
/// the stored Supabase session's access token to expire (the proactive
/// refresh timer only runs while the app is alive), `AuthRepository
/// .restoreSession()`'s `/users/by-auth/:id` lookup 401s — and the old code
/// treated any non-404 failure as terminal, returning `null` without ever
/// attempting a session refresh. `AuthNotifier._init()` then flips straight
/// to `AuthStatus.unauthenticated` and the router sends the user back to
/// `/intro`, even though the session was perfectly recoverable with one
/// refresh.
///
/// `AuthRepository.resolveAuthLookupWithOneRefreshRetry` (the state machine
/// `restoreSession()` now delegates to) is a pure decision loop over two
/// injected closures — no Dio, no Supabase — so it's directly testable
/// headlessly, the same way `AuthInstallGuard.shouldClearStaleCredentials`
/// is tested as a pure predicate rather than driving the real Keychain for
/// every case.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';

User _testUser() => const User(
  id: 'user-123',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: '2026-01-01T00:00:00.000Z',
);

void main() {
  group('resolveAuthLookupWithOneRefreshRetry', () {
    test(
      'a healthy lookup (200 on the first try) returns the user without '
      'ever attempting a refresh',
      () async {
        final user = _testUser();
        var lookupCalls = 0;
        var refreshCalls = 0;

        final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
          attemptLookup: () async {
            lookupCalls++;
            return (status: 200, user: user);
          },
          refresh: () async {
            refreshCalls++;
            return true;
          },
        );

        expect(result, user);
        expect(lookupCalls, 1);
        expect(
          refreshCalls,
          0,
          reason: 'a token that is still valid must never trigger a refresh',
        );
      },
    );

    test(
      'expired JWT + refresh succeeds => the retried lookup resolves and '
      'the session stays authenticated (E2E #82, the happy path)',
      () async {
        final user = _testUser();
        var lookupCalls = 0;
        var refreshCalls = 0;

        final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
          attemptLookup: () async {
            lookupCalls++;
            // First attempt sees the stale token (401); the retry — issued
            // only after a successful refresh — sees a live one.
            if (lookupCalls == 1) return (status: 401, user: null);
            return (status: 200, user: user);
          },
          refresh: () async {
            refreshCalls++;
            return true;
          },
        );

        expect(
          result,
          user,
          reason: 'a merely-idle, refreshable session must resolve back to '
              'authenticated, not fall through to signed-out',
        );
        expect(lookupCalls, 2, reason: 'the lookup must be retried exactly once');
        expect(refreshCalls, 1);
      },
    );

    test(
      'expired JWT + refresh fails => unauthenticated, not a hang, not a '
      'crash (a genuinely dead session must still end signed-out)',
      () async {
        var lookupCalls = 0;
        var refreshCalls = 0;

        final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
          attemptLookup: () async {
            lookupCalls++;
            return (status: 401, user: null);
          },
          refresh: () async {
            refreshCalls++;
            return false;
          },
        ).timeout(const Duration(seconds: 2));

        expect(result, isNull);
        expect(lookupCalls, 1, reason: 'no retry after a failed refresh');
        expect(refreshCalls, 1);
      },
    );

    test(
      'expired JWT + refresh throws => unauthenticated, the exception is '
      'contained (a refresh transport error must not crash startup)',
      () async {
        var lookupCalls = 0;
        var refreshCalls = 0;

        final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
          attemptLookup: () async {
            lookupCalls++;
            return (status: 401, user: null);
          },
          refresh: () async {
            refreshCalls++;
            throw Exception('network unreachable');
          },
        ).timeout(const Duration(seconds: 2));

        expect(result, isNull);
        expect(lookupCalls, 1);
        expect(refreshCalls, 1);
      },
    );

    test(
      'a 401 that SURVIVES a successful refresh is not retried a second '
      'time — refreshes at most once',
      () async {
        var lookupCalls = 0;
        var refreshCalls = 0;

        final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
          attemptLookup: () async {
            lookupCalls++;
            // Every attempt 401s, even after a "successful" refresh — e.g.
            // the refresh token itself was already revoked server-side.
            return (status: 401, user: null);
          },
          refresh: () async {
            refreshCalls++;
            return true;
          },
        ).timeout(const Duration(seconds: 2));

        expect(result, isNull);
        expect(
          lookupCalls,
          2,
          reason: 'one retry is attempted after the refresh reports success',
        );
        expect(
          refreshCalls,
          1,
          reason: 'a session that is still bad after one refresh is dead — '
              'looping would spin forever instead of resolving to signed-out',
        );
      },
    );

    test('a non-401, non-200 status (e.g. 500) never triggers a refresh',
        () async {
      var lookupCalls = 0;
      var refreshCalls = 0;

      final result = await AuthRepository.resolveAuthLookupWithOneRefreshRetry(
        attemptLookup: () async {
          lookupCalls++;
          return (status: 500, user: null);
        },
        refresh: () async {
          refreshCalls++;
          return true;
        },
      );

      expect(result, isNull);
      expect(lookupCalls, 1);
      expect(
        refreshCalls,
        0,
        reason: 'a server error is not a token-expiry signal; refreshing '
            'would not help and would just add a spurious Supabase call',
      );
    });
  });
}
