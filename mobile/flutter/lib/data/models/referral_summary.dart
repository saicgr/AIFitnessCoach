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
@immutable
class ReferralTier {
  final int threshold;
  final String merchType;
  final String displayName;
  final String emoji;

  /// The XP level that grants this SAME merch type independently (backend
  /// `MERCH_TYPE_FOR_LEVEL`) — null when a tier is referral-only (the
  /// shaker bottle has no level equivalent; see migration 1932's "viral
  /// lever, earned not auto-granted"). Both paths are real, independent
  /// unlock routes to the same reward, so the UI should say so rather than
  /// naming only the referral condition.
  final int? levelEquivalent;

  const ReferralTier({
    required this.threshold,
    required this.merchType,
    required this.displayName,
    required this.emoji,
    this.levelEquivalent,
  });

  static const List<ReferralTier> all = [
    ReferralTier(threshold: 3, merchType: 'sticker_pack', displayName: '${Branding.appName} Sticker Pack', emoji: '✨', levelEquivalent: 50),
    ReferralTier(threshold: 10, merchType: 'shaker_bottle', displayName: '${Branding.appName} Shaker Bottle', emoji: '🥤'),
    ReferralTier(threshold: 25, merchType: 't_shirt', displayName: '${Branding.appName} T-Shirt', emoji: '👕', levelEquivalent: 100),
    ReferralTier(threshold: 50, merchType: 'hoodie', displayName: '${Branding.appName} Hoodie', emoji: '🧥', levelEquivalent: 150),
    ReferralTier(threshold: 100, merchType: 'full_merch_kit', displayName: 'Full Merch Kit', emoji: '🎁', levelEquivalent: 200),
    ReferralTier(threshold: 250, merchType: 'signed_premium_kit', displayName: 'Signed Premium Kit', emoji: '🏆', levelEquivalent: 250),
  ];
}
