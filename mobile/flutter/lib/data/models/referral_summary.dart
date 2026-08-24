import 'package:flutter/foundation.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Summary of the current user's referral program status.
/// Mirrors backend `get_referral_summary` RPC (migration 1932).
@immutable
class ReferralSummary {
  /// The user's permanent 6-char referral code.
  final String referralCode;

  /// Referrals who have signed up but haven't yet completed their first workout.
  final int pendingCount;

  /// Referrals who have completed their first workout (count toward merch tiers).
  final int qualifiedCount;

  /// Next cumulative milestone threshold (null if user has hit the final tier).
  final int? nextMilestone;

  /// Merch type awarded at the next milestone.
  final String? nextMerchType;

  const ReferralSummary({
    required this.referralCode,
    required this.pendingCount,
    required this.qualifiedCount,
    this.nextMilestone,
    this.nextMerchType,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) => ReferralSummary(
        referralCode: json['referral_code'] as String,
        pendingCount: json['pending_count'] as int? ?? 0,
        qualifiedCount: json['qualified_count'] as int? ?? 0,
        nextMilestone: json['next_milestone'] as int?,
        nextMerchType: json['next_merch_type'] as String?,
      );

  /// Progress 0.0-1.0 toward next milestone.
  double get progressToNext {
    if (nextMilestone == null || nextMilestone == 0) return 1.0;
    // Find the previous tier threshold so the bar fills incrementally
    final prevThreshold = _previousThreshold(nextMilestone!);
    final span = nextMilestone! - prevThreshold;
    if (span <= 0) return 1.0;
    return ((qualifiedCount - prevThreshold) / span).clamp(0.0, 1.0);
  }

  int get neededForNext =>
      nextMilestone == null ? 0 : (nextMilestone! - qualifiedCount).clamp(0, nextMilestone!);

  String get nextMerchDisplayName => switch (nextMerchType) {
        'sticker_pack' => '${Branding.appName} Sticker Pack',
        'shaker_bottle' => '${Branding.appName} Shaker Bottle',
        't_shirt' => '${Branding.appName} T-Shirt',
        'hoodie' => '${Branding.appName} Hoodie',
        'full_merch_kit' => 'Full Merch Kit',
        'signed_premium_kit' => 'Signed Premium Kit',
        _ => '',
      };

  String get nextMerchEmoji => switch (nextMerchType) {
        'sticker_pack' => '✨',
        'shaker_bottle' => '🥤',
        't_shirt' => '👕',
        'hoodie' => '🧥',
        'full_merch_kit' => '🎁',
        'signed_premium_kit' => '🏆',
        _ => '⭐',
      };

  static int _previousThreshold(int milestone) {
    const thresholds = [0, 3, 10, 25, 50, 100, 250];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (thresholds[i] < milestone) return thresholds[i];
    }
    return 0;
  }
}

/// One tier in the cumulative referral merch ladder.
///
/// The referral thresholds here (3/10/25/50/100/250 cumulative qualified
/// referrals) are a separate, independent ladder from the XP level ladder —
/// this fix does not touch them (see the audit note on
/// `levelEquivalentForMerchType` below).
@immutable
class ReferralTier {
  final int threshold;
  final String merchType;
  final String displayName;
  final String emoji;

  const ReferralTier({
    required this.threshold,
    required this.merchType,
    required this.displayName,
    required this.emoji,
  });

  static const List<ReferralTier> all = [
    ReferralTier(threshold: 3, merchType: 'sticker_pack', displayName: '${Branding.appName} Sticker Pack', emoji: '✨'),
    ReferralTier(threshold: 10, merchType: 'shaker_bottle', displayName: '${Branding.appName} Shaker Bottle', emoji: '🥤'),
    ReferralTier(threshold: 25, merchType: 't_shirt', displayName: '${Branding.appName} T-Shirt', emoji: '👕'),
    ReferralTier(threshold: 50, merchType: 'hoodie', displayName: '${Branding.appName} Hoodie', emoji: '🧥'),
    ReferralTier(threshold: 100, merchType: 'full_merch_kit', displayName: 'Full Merch Kit', emoji: '🎁'),
    ReferralTier(threshold: 250, merchType: 'signed_premium_kit', displayName: 'Signed Premium Kit', emoji: '🏆'),
  ];
}

/// The XP level that grants a given `merchType` independently of referrals
/// (backend `merch_type_for_level()`, migration 2424) — null when
/// [allLevels] hasn't loaded yet, or when the merch type is referral-only
/// (the shaker bottle has no level equivalent; see migration 1932's "viral
/// lever, earned not auto-granted"). Both paths are real, independent unlock
/// routes to the same reward, so the UI should say so rather than naming
/// only the referral condition.
///
/// This USED TO be a hardcoded `ReferralTier.levelEquivalent` field
/// (sticker_pack: 50, t_shirt: 100, hoodie: 150, full_merch_kit: 200,
/// signed_premium_kit: 250) — the OLD, pre-migration-2424 level ladder,
/// silently out of sync with the DB's rescaled 20/40/60/80/100 ladder. Read
/// the live level from [allLevels] (`/xp/all-levels`, `allLevelsProvider`)
/// instead of guessing it here — never reintroduce a level literal (E2E #371).
///
/// Referral-thresholds audit: the referral ladder (3/10/25/50/100/250
/// cumulative qualified referrals) and the level ladder are independent by
/// design and both still make sense post-rescale — a referral is a
/// same-effort viral action regardless of how fast levels come, so there is
/// no reason its thresholds should track the level rescale. Not changed here.
int? levelEquivalentForMerchType(String? merchType, List<Map<String, dynamic>>? allLevels) {
  if (merchType == null || allLevels == null) return null;
  for (final entry in allLevels) {
    if (entry['merch_type'] == merchType) return entry['level'] as int?;
  }
  return null;
}
