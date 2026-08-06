import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/cycle_settings_screen.dart';

// REGRESSION (E2E settings row 86): the per-type cycle reminder toggles
// used to render as active purely from the reminders master switch, with
// no dependency on whether cycle tracking itself was even on — a stored
// cycleRemindersMaster: true from before tracking was disabled rendered as
// bright orange ON toggles for reminders that cannot possibly fire (no
// tracked cycle data to base them on).
void main() {
  group('cycleRemindersActiveNow', () {
    test('inactive when tracking is off, even with remindersMaster true', () {
      expect(
        cycleRemindersActiveNow(trackingEnabled: false, remindersMaster: true),
        isFalse,
      );
    });

    test('inactive when remindersMaster is off', () {
      expect(
        cycleRemindersActiveNow(trackingEnabled: true, remindersMaster: false),
        isFalse,
      );
    });

    test('active only when both are on', () {
      expect(
        cycleRemindersActiveNow(trackingEnabled: true, remindersMaster: true),
        isTrue,
      );
    });
  });
}
