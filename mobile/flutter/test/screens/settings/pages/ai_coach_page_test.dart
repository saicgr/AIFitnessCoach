import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/services/notification_service.dart';
import 'package:fitwiz/screens/settings/pages/ai_coach_page.dart';

// REGRESSION (E2E settings row 22): the AI Coach page's "Nudge Intensity"
// SegmentedButton is seeded from `prefs.accountabilityIntensity`. When that
// value isn't one of the control's own segment values, SegmentedButton
// renders with NO segment highlighted — a blank, stateless-looking control.
// `NotificationPreferences.accountabilityIntensity` defaults to 'auto', so
// every user who hasn't explicitly picked a tone hits this unless 'auto' is
// one of the selectable segments.
void main() {
  test(
    "default accountabilityIntensity ('auto') is a selectable Nudge "
    'Intensity segment',
    () {
      final defaultValue = const NotificationPreferences().accountabilityIntensity;
      expect(defaultValue, 'auto');
      expect(kNudgeIntensitySegmentValues, contains(defaultValue));
    },
  );

  test('every legitimate accountability_intensity value is representable', () {
    // 'off' is also a real stored value (skip-nudges), used and checked
    // elsewhere in the notification pipeline — must be selectable too.
    expect(kNudgeIntensitySegmentValues,
        containsAll(['auto', 'gentle', 'balanced', 'tough_love', 'off']));
  });
}
