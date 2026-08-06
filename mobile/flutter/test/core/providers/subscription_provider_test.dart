// Regression gate for FITWIZ-FLUTTER-1B ("RevenueCat API key missing at
// configure" — 15 users, 81+ events in Sentry, still firing at fix time).
//
// Root cause: EVERY affected "user" in that Sentry issue was
// `device.simulator: true` (14 iOS Simulator installs + 1 Android emulator).
// `configureRevenueCat()` unconditionally escalated a missing/placeholder
// RevenueCat API key to a Sentry warning-level alert — but on a simulator
// this is expected, not a bug: the local run scripts (run_ios.sh,
// run_ios_debug.sh, run_ios_dev.sh) only pass REVENUECAT_APPLE_KEY /
// REVENUECAT_GOOGLE_KEY when a developer explicitly exports them, and no
// simulator/emulator can complete a real in-app purchase regardless of
// whether a key is configured. Alerting unconditionally made every dev/QA
// simulator session masquerade as a production purchase outage. No real
// device/user in this issue was ever found.
//
// The fix: `configureRevenueCat()` now checks `isPhysicalDeviceForBilling()`
// before deciding whether a missing key is alert-worthy (real device — a
// genuine release-config bug, still loud) or breadcrumb-only (simulator/
// emulator — expected, not paged).
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/subscription_provider.dart';

void main() {
  setUp(() {
    // Reset the test-only static seams between cases so each test controls
    // its own device-class outcome independent of prior tests/isolate reuse.
    SubscriptionNotifier.isPhysicalDeviceCache = null;
    SubscriptionNotifier.lastMissingApiKeyAlertedToSentry = null;
  });

  group('FITWIZ-FLUTTER-1B: missing RevenueCat key at configure', () {
    test(
      'on a real device, a missing/placeholder key IS escalated to a Sentry alert',
      () async {
        // Seed the device-class cache directly (skips the platform channel —
        // `flutter test` runs on the host, so Platform.isIOS/isAndroid are
        // both false and would never reach device_info_plus at all).
        SubscriptionNotifier.isPhysicalDeviceCache = true;

        // No --dart-define is passed under `flutter test`, so the RevenueCat
        // key is guaranteed to be the 'test_key_placeholder' default here —
        // exactly the "missing key" condition this issue is about.
        await SubscriptionNotifier.configureRevenueCat();

        expect(
          SubscriptionNotifier.lastMissingApiKeyAlertedToSentry,
          isTrue,
          reason: 'a genuinely missing key on a real device must still page '
              'as a production billing bug',
        );
      },
    );

    test(
      'on a simulator/emulator, a missing/placeholder key is only breadcrumbed — '
      'never escalated to a Sentry alert',
      () async {
        SubscriptionNotifier.isPhysicalDeviceCache = false;

        await SubscriptionNotifier.configureRevenueCat();

        expect(
          SubscriptionNotifier.lastMissingApiKeyAlertedToSentry,
          isFalse,
          reason: 'this is the FITWIZ-FLUTTER-1B defect: dev/QA simulator '
              'sessions without an exported RevenueCat key must not be '
              'reported as real-user purchase outages',
        );
      },
    );
  });
}
