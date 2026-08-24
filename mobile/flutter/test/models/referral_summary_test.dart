// Regression tests for E2E #371 — the merch-ladder single-source-of-truth
// fix (backend + level_reward.dart) also had to be extended to the referral
// surface. `ReferralTier` used to hardcode a `levelEquivalent` field at the
// OLD (pre-migration-2424) level ladder (sticker_pack: 50, t_shirt: 100,
// hoodie: 150, full_merch_kit: 200, signed_premium_kit: 250) -- a third
// disagreeing copy of the ladder that lived in referral_summary.dart. See
// mobile/flutter/lib/data/models/referral_summary.dart
// (levelEquivalentForMerchType) and mobile/flutter/lib/screens/referrals/
// referrals_screen.dart / mobile/flutter/lib/screens/merch/
// merch_claims_screen.dart (both now read the level live off
// `allLevelsProvider` instead).
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/referral_summary.dart';

void main() {
  group('levelEquivalentForMerchType', () {
    final rescaledLevels = [
      {'level': 20, 'merch_type': 'sticker_pack'},
      {'level': 40, 'merch_type': 't_shirt'},
      {'level': 60, 'merch_type': 'hoodie'},
      {'level': 80, 'merch_type': 'full_merch_kit'},
      {'level': 100, 'merch_type': 'signed_premium_kit'},
    ];

    test('reads the live (rescaled) level for a merch type, not the old ladder', () {
      // Level 50 used to be hardcoded here as the sticker_pack equivalent.
      // Under the rescaled ladder (migration 2424) it's Level 20.
      expect(levelEquivalentForMerchType('sticker_pack', rescaledLevels), 20);
      expect(levelEquivalentForMerchType('t_shirt', rescaledLevels), 40);
      expect(levelEquivalentForMerchType('hoodie', rescaledLevels), 60);
      expect(levelEquivalentForMerchType('full_merch_kit', rescaledLevels), 80);
      expect(levelEquivalentForMerchType('signed_premium_kit', rescaledLevels), 100);
    });

    test('returns null for a referral-only merch type (no level equivalent)', () {
      // The shaker bottle is referral-only (migration 1932) and has no
      // corresponding merch_type_for_level() entry.
      expect(levelEquivalentForMerchType('shaker_bottle', rescaledLevels), isNull);
    });

    test('degrades to null (never a stale guess) when allLevels has not loaded', () {
      expect(levelEquivalentForMerchType('sticker_pack', null), isNull);
    });

    test('degrades to null for a null merchType', () {
      expect(levelEquivalentForMerchType(null, rescaledLevels), isNull);
    });
  });

  group('ReferralTier.all', () {
    test('stays a pure referral-side model (threshold/merchType only)', () {
      // Regression guard: the level equivalent must be computed live via
      // levelEquivalentForMerchType, never stored as a field here again.
      expect(ReferralTier.all.length, 6);
      expect(ReferralTier.all.map((t) => t.merchType).toSet(), {
        'sticker_pack', 'shaker_bottle', 't_shirt', 'hoodie', 'full_merch_kit', 'signed_premium_kit',
      });
    });

    test('referral thresholds are unchanged by the level-ladder rescale', () {
      // The referral ladder (cumulative qualified referrals) and the level
      // ladder are independent unlock routes to the same reward; the level
      // rescale (migration 2424) has no bearing on referral thresholds.
      final thresholds = {for (final t in ReferralTier.all) t.merchType: t.threshold};
      expect(thresholds, {
        'sticker_pack': 3,
        'shaker_bottle': 10,
        't_shirt': 25,
        'hoodie': 50,
        'full_merch_kit': 100,
        'signed_premium_kit': 250,
      });
    });
  });
}
