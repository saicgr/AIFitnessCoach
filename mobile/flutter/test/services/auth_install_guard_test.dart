/// Regression gate for E2E register #41 — "uninstalling the app does not
/// sign you out".
///
/// `AuthInstallGuard` (lib/core/services/auth_install_guard.dart) was written
/// correctly but shipped as dead code: nothing imported it, nothing called
/// `.run()`. These tests exercise the guard's own decision logic headlessly
/// (mocking the flutter_secure_storage MethodChannel the same way
/// test/services/secure_storage_timeout_test.dart does) so its behavior is
/// pinned independent of the wiring fix. The wiring itself — that `main()`
/// actually calls `AuthInstallGuard.run()` before `runApp()` — is covered by
/// test/lint/auth_install_guard_wiring_test.dart, since a fix nobody calls is
/// not a fix.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/services/auth_install_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // In-memory fake Keychain, keyed by the 'key' argument every call carries.
  late Map<String, String> keychain;
  late List<String> deleteCalls;

  void installFakeKeychain(Map<String, String> seed) {
    keychain = Map<String, String>.from(seed);
    deleteCalls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return keychain[key];
        case 'write':
          keychain[key!] = args['value'] as String;
          return null;
        case 'delete':
          deleteCalls.add(key!);
          keychain.remove(key);
          return null;
        case 'containsKey':
          return keychain.containsKey(key);
        case 'deleteAll':
          deleteCalls.addAll(keychain.keys);
          keychain.clear();
          return null;
        default:
          return null;
      }
    });
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('AuthInstallGuard.shouldClearStaleCredentials (pure predicate)', () {
    test('fires exactly when the install marker is missing', () {
      expect(
        AuthInstallGuard.shouldClearStaleCredentials(hasInstallMarker: false),
        isTrue,
      );
      expect(
        AuthInstallGuard.shouldClearStaleCredentials(hasInstallMarker: true),
        isFalse,
      );
    });
  });

  group('AuthInstallGuard.run()', () {
    test(
      'clean first install: no marker, no stale credentials -> '
      'firstRunClean, and the marker is written so later launches no-op',
      () async {
        SharedPreferences.setMockInitialValues({});
        installFakeKeychain({});

        final outcome = await AuthInstallGuard.run();

        expect(outcome, AuthInstallGuardOutcome.firstRunClean);
        expect(deleteCalls, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(AuthInstallGuard.installMarkerKey),
          isTrue,
          reason:
              'without the marker every launch would look like a first run',
        );
      },
    );

    test(
      'reinstall with a stale Keychain token -> '
      'firstRunClearedStaleSession, and the credentials are actually wiped',
      () async {
        SharedPreferences.setMockInitialValues({});
        installFakeKeychain({
          'auth_token': 'stale-token-from-previous-install',
          'user_id': 'stale-user-id',
        });

        final outcome = await AuthInstallGuard.run();

        expect(outcome, AuthInstallGuardOutcome.firstRunClearedStaleSession);
        expect(deleteCalls, containsAll(<String>['auth_token', 'user_id']));
        expect(keychain.containsKey('auth_token'), isFalse);
        expect(keychain.containsKey('user_id'), isFalse);
      },
    );

    test(
      'subsequent launch: marker already present -> subsequentRun, and the '
      'Keychain is never touched (a real, live session must survive)',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthInstallGuard.installMarkerKey: true,
        });
        installFakeKeychain({
          'auth_token': 'a-real-live-session-token',
          'user_id': 'real-user-id',
        });

        final outcome = await AuthInstallGuard.run();

        expect(outcome, AuthInstallGuardOutcome.subsequentRun);
        expect(
          deleteCalls,
          isEmpty,
          reason: 'a normal launch must never touch stored credentials',
        );
        expect(keychain['auth_token'], 'a-real-live-session-token');
        expect(keychain['user_id'], 'real-user-id');
      },
    );

    test(
      'is idempotent: a second run() call (same launch or a later one) never '
      're-fires the clear',
      () async {
        SharedPreferences.setMockInitialValues({});
        installFakeKeychain({'auth_token': 'stale'});

        final first = await AuthInstallGuard.run();
        final second = await AuthInstallGuard.run();

        expect(first, AuthInstallGuardOutcome.firstRunClearedStaleSession);
        expect(second, AuthInstallGuardOutcome.subsequentRun);
        expect(deleteCalls.where((k) => k == 'auth_token').length, 1);
      },
    );
  });
}
