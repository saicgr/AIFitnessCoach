import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/subscription_provider.dart';
import 'package:fitwiz/screens/settings/subscription/subscription_management_screen.dart';

// REGRESSION (E2E settings row 21): the current-plan card's headline
// ("Inactive" for a lapsed/free-tier user) and its subtitle must agree.
// The subtitle used to hardcode "Active subscription" in every non-trial,
// non-lifetime branch — including free tier, which is exactly when the
// headline says "Inactive".
void main() {
  group('activePlanSubtitle', () {
    test('free tier (lapsed/no active subscription) does not claim active',
        () {
      final result = activePlanSubtitle(SubscriptionTier.free);
      expect(result, isNot(contains('Active subscription')));
      expect(result, 'No active subscription');
    });

    test('premium tier says active subscription', () {
      expect(
        activePlanSubtitle(SubscriptionTier.premium),
        'Active subscription',
      );
    });

    test('premiumPlus tier says active subscription', () {
      expect(
        activePlanSubtitle(SubscriptionTier.premiumPlus),
        'Active subscription',
      );
    });
  });
}
