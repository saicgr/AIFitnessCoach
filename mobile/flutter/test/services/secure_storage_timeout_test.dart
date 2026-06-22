@Timeout(Duration(seconds: 60))
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitwiz/core/constants/api_constants.dart';
import 'package:fitwiz/data/services/api_client.dart';

/// Regression test for the "signup hangs on Create Account" bug.
///
/// Root cause: `setUserId` / `setAuthToken` (run on the auth critical path for
/// EVERY provider — Google/Apple/email/restore) write to FlutterSecureStorage,
/// which serializes every op through ONE platform channel. Under contention a
/// write can STALL (hang, not throw) with no native timeout, wedging the auth
/// notifier in `loading` forever — an infinite spinner with no exception
/// (invisible to Sentry/backend).
///
/// These tests reproduce the stall headlessly (no emulator) by mocking the
/// flutter_secure_storage MethodChannel to never return, and prove the fix:
/// `_ResilientSecureStorage.write`/`read` now `.timeout(secureStorageOpTimeout)`
/// and fall back to SharedPreferences, so the call always completes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // A channel handler whose write/read NEVER complete — the wedged Keychain.
  Completer<Object?>? hang;
  void installHangingChannel() {
    hang = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (call) {
      if (call.method == 'write' || call.method == 'read') {
        return hang!.future; // never completes → simulates the stall
      }
      return Future<Object?>.value(null);
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installHangingChannel();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    // Let the abandoned native call "resolve" so no future leaks across tests.
    if (hang != null && !hang!.isCompleted) hang!.complete(null);
  });

  // The cap the fix introduces; the buffer absorbs scheduling slop.
  final cap = ApiConstants.secureStorageOpTimeout;
  final upperBound = cap + const Duration(seconds: 3);

  FlutterSecureStorage realStorage() {
    // Public seam → the real _ResilientSecureStorage (the class under test).
    return ProviderContainer().read(secureStorageProvider);
  }

  group('root cause (proves the bug exists without a cap)', () {
    test('an un-capped secure-storage write hangs indefinitely', () async {
      // Base FlutterSecureStorage with NO resilient wrapper / NO timeout.
      const raw = FlutterSecureStorage();
      // Without a cap the write never returns — a 500ms probe must time out.
      await expectLater(
        raw
            .write(key: 'probe', value: 'v')
            .timeout(const Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('fix: writes are bounded and fall back to SharedPreferences', () {
    test(
      'setAuthToken completes within the cap when Keychain stalls',
      () async {
        final client = ApiClient(realStorage());
        final sw = Stopwatch()..start();

        // Must NOT throw and must NOT hang past the cap.
        await client.setAuthToken('tok-123').timeout(upperBound);
        sw.stop();

        expect(
          sw.elapsed,
          lessThan(upperBound),
          reason: 'write should resolve via the timeout cap, not hang',
        );
        // The value persisted via the SharedPreferences fallback.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('secure.auth_token'), 'tok-123');
      },
    );

    test('setUserId completes within the cap when Keychain stalls', () async {
      final client = ApiClient(realStorage());

      await client.setUserId('uid-999').timeout(upperBound);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('secure.user_id'), 'uid-999');
    });
  });

  group('fix: reads are bounded and fall back to SharedPreferences', () {
    test(
      'a stalled Keychain read falls back to the prefs shadow copy',
      () async {
        // Seed the shadow copy a prior fallback write would have left.
        SharedPreferences.setMockInitialValues({'secure.auth_token': 'cached'});
        installHangingChannel(); // re-install after resetting prefs

        final storage = realStorage();
        final sw = Stopwatch()..start();

        final value = await storage.read(key: 'auth_token').timeout(upperBound);
        sw.stop();

        expect(value, 'cached');
        expect(
          sw.elapsed,
          lessThan(upperBound),
          reason: 'read should resolve via the timeout cap, not hang',
        );
      },
    );
  });
}
