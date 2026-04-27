import 'package:flutter/foundation.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// One persisted level-up (migration 1935). Shown as a retroactive banner
/// so users never miss a reward moment.
@immutable
class LevelUpEvent {
  final String id;
  final int levelReached;
  final bool isMilestone;
  final String? merchType; // non-null for levels that award physical merch
  final List<LevelUpRewardItem> items;
  final DateTime createdAt;

  const LevelUpEvent({
    required this.id,
    required this.levelReached,
    required this.isMilestone,
    this.merchType,
    required this.items,
    required this.createdAt,
  });

  factory LevelUpEvent.fromJson(Map<String, dynamic> json) {
    final raw = (json['rewards_snapshot'] as List? ?? const []);
    return LevelUpEvent(
      id: json['id'] as String,
      levelReached: json['level_reached'] as int,
      isMilestone: json['is_milestone'] as bool? ?? false,
      merchType: json['merch_type'] as String?,
      items: raw.map((e) => LevelUpRewardItem.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@immutable
class LevelUpRewardItem {
  final String type;      // 'streak_shield' | 'xp_token_2x' | 'fitness_crate' | 'premium_crate' | 'merch'
  final int quantity;
  final String? merchType;
  final String? claimId;

  const LevelUpRewardItem({
    required this.type,
    required this.quantity,
    this.merchType,
    this.claimId,
  });

  factory LevelUpRewardItem.fromJson(Map<String, dynamic> json) => LevelUpRewardItem(
        type: json['type'] as String,
        quantity: json['quantity'] as int? ?? 1,
        merchType: json['merch_type'] as String?,
        claimId: json['claim_id'] as String?,
      );

  String get displayName {
    if (type == 'merch') {
      return switch (merchType) {
        'sticker_pack' => '${Branding.appName} Sticker Pack',
        'shaker_bottle' => '${Branding.appName} Shaker Bottle',
        't_shirt' => '${Branding.appName} T-Shirt',
        'hoodie' => '${Branding.appName} Hoodie',
        'full_merch_kit' => 'Full Merch Kit',
        'signed_premium_kit' => 'Signed Premium Kit',
        _ => 'Merch',
      };
    }
    return switch (type) {
      'streak_shield' => 'Streak Shield',
      'xp_token_2x' => '2× XP Token',
      'fitness_crate' => 'Fitness Crate',
      'premium_crate' => 'Premium Crate',
      _ => type.replaceAll('_', ' '),
    };
  }

  String get emoji => switch (type) {
        'streak_shield' => '🛡️',
        'xp_token_2x' => '⚡',
        'fitness_crate' => '📦',
        'premium_crate' => '🎁',
        'merch' => switch (merchType) {
            'sticker_pack' => '✨',
            'shaker_bottle' => '🥤',
            't_shirt' => '👕',
            'hoodie' => '🧥',
            'full_merch_kit' => '🎁',
            'signed_premium_kit' => '🏆',
            _ => '🎁',
          },
        _ => '⭐',
      };
}
