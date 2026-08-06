import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/pages/health_devices_page.dart';

// REGRESSION (E2E settings row 86, "same pattern" evidence): the
// auto-import-workouts toggle used to render ON purely from the stored
// SharedPreferences flag, regardless of whether Apple Health / Health
// Connect was actually connected — a setting that cannot possibly fire.
void main() {
  group('autoImportActiveNow', () {
    test('inactive when not connected, even with storedEnabled true', () {
      expect(
        autoImportActiveNow(isConnected: false, storedEnabled: true),
        isFalse,
      );
    });

    test('inactive when the stored preference is off', () {
      expect(
        autoImportActiveNow(isConnected: true, storedEnabled: false),
        isFalse,
      );
    });

    test('active only when both are true', () {
      expect(
        autoImportActiveNow(isConnected: true, storedEnabled: true),
        isTrue,
      );
    });
  });
}
