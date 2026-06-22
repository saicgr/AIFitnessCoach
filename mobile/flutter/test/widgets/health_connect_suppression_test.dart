import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitwiz/widgets/health_connect_sheet.dart';

/// Verifies the onboarding-primer → home-popup dedup contract:
/// once the user has been through the `/health-connect-onboarding` primer
/// (which calls [markHealthPrimerSeen]), the home auto-popup's
/// [isHealthConnectPopupSuppressed] gate returns true so the same prompt
/// doesn't re-fire right after onboarding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health Connect popup suppression', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('not suppressed on a fresh install', () async {
      expect(await isHealthConnectPopupSuppressed(), isFalse);
    });

    test('suppressed after the onboarding primer is seen', () async {
      await markHealthPrimerSeen();
      expect(await isHealthConnectPopupSuppressed(), isTrue);
    });

    test('still suppressed within the 7-day window', () async {
      // Stamp a dismissal 3 days ago directly via the same pref key the
      // helper writes, then assert the window has not elapsed.
      final threeDaysAgo = DateTime.now()
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'health_connect_dismissed_at': threeDaysAgo,
      });
      expect(await isHealthConnectPopupSuppressed(), isTrue);
    });

    test('no longer suppressed once the 7-day window elapses', () async {
      final eightDaysAgo = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'health_connect_dismissed_at': eightDaysAgo,
      });
      expect(await isHealthConnectPopupSuppressed(), isFalse);
    });
  });
}
