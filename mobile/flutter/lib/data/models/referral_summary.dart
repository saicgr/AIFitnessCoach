import 'package:flutter/foundation.dart';

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
        'sticker_pack' => 'FitWiz Sticker Pack',
        'shaker_bottle' => 'FitWiz Shaker Bottle',
        't_shirt' => 'FitWiz T-Shirt',
        'hoodie' => 'FitWiz Hoodie',
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

  const ReferralTier({
    required this.threshold,
    required this.merchType,
    required this.displayName,
    required this.emoji,
  });

  static const List<ReferralTier> all = [
    ReferralTier(threshold: 3, merchType: 'sticker_pack', displayName: 'FitWiz Sticker Pack', emoji: '✨'),
    ReferralTier(threshold: 10, merchType: 'shaker_bottle', displayName: 'FitWiz Shaker Bottle', emoji: '🥤'),
    ReferralTier(threshold: 25, merchType: 't_shirt', displayName: 'FitWiz T-Shirt', emoji: '👕'),
    ReferralTier(threshold: 50, merchType: 'hoodie', displayName: 'FitWiz Hoodie', emoji: '🧥'),
    ReferralTier(threshold: 100, merchType: 'full_merch_kit', displayName: 'Full Merch Kit', emoji: '🎁'),
    ReferralTier(threshold: 250, merchType: 'signed_premium_kit', displayName: 'Signed Premium Kit', emoji: '🏆'),
  ];
}
