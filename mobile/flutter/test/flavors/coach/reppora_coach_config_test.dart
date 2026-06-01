import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/flavors/coach/reppora_coach_config.dart';

void main() {
  group('RepporaCoachConfig', () {
    test('bundle id matches App Store registration', () {
      expect(RepporaCoachConfig.values.bundleId, 'com.reppora.coach');
    });

    test('deep link scheme is reppora-coach://', () {
      expect(RepporaCoachConfig.values.deepLinkScheme, 'reppora-coach');
    });

    test('app store name is Reppora for Coach', () {
      expect(RepporaCoachConfig.values.appStoreName, 'Reppora for Coach');
    });

    test('backend points to production reppora-backend', () {
      expect(
        RepporaCoachConfig.values.backendBaseUrl,
        'https://reppora-backend.onrender.com',
      );
    });
  });
}
