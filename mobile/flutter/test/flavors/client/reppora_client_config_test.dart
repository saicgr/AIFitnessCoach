// Reppora Client flavor config — pure-Dart unit tests.
// Run via Reppora repo: ../scripts/run_ios_client.sh (test path) or
//   `flutter test test/flavors/client/` from mobile/flutter root.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fitness_coach/flavors/client/reppora_client_config.dart';

void main() {
  group('RepporaClientConfig', () {
    test('bundle id matches App Store registration', () {
      expect(RepporaClientConfig.values.bundleId, 'com.reppora.app');
    });

    test('deep link scheme is reppora://', () {
      expect(RepporaClientConfig.values.deepLinkScheme, 'reppora');
    });

    test('app store name is Reppora', () {
      expect(RepporaClientConfig.values.appStoreName, 'Reppora');
    });

    test('powered-by footer enabled by default', () {
      expect(RepporaClientConfig.values.poweredByFooter, isTrue);
    });

    test('backend points to production reppora-backend', () {
      expect(
        RepporaClientConfig.values.backendBaseUrl,
        'https://reppora-backend.onrender.com',
      );
    });
  });
}
