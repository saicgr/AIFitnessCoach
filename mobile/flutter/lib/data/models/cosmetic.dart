import 'package:flutter/material.dart';

/// A cosmetic from the catalog (migration 1936).
@immutable
class Cosmetic {
  final String id;
  final CosmeticType type;
  final String displayName;
  final String? description;
  final String? emoji;
  final Color? color;
  final Color? gradient;
  final String? tier;
  final bool isAnimated;
  final int? unlockLevel;

  const Cosmetic({
    required this.id,
    required this.type,
    required this.displayName,
    this.description,
    this.emoji,
    this.color,
    this.gradient,
    this.tier,
    this.isAnimated = false,
    this.unlockLevel,
  });

  factory Cosmetic.fromJson(Map<String, dynamic> json) {
    Color? parseHex(String? s) {
      if (s == null || s.isEmpty) return null;
      final hex = s.replaceFirst('#', '');
      final value = int.tryParse(hex, radix: 16);
      return value == null ? null : Color(0xFF000000 | value);
    }

    return Cosmetic(
      id: json['id'] as String,
      type: CosmeticType.fromString(json['type'] as String),
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      color: parseHex(json['color_hex'] as String?),
      gradient: parseHex(json['gradient_hex'] as String?),
      tier: json['tier'] as String?,
      isAnimated: json['is_animated'] as bool? ?? false,
      unlockLevel: json['unlock_level'] as int?,
    );
  }

  bool get isRendered => type == CosmeticType.badge ||
      type == CosmeticType.frame ||
      type == CosmeticType.chatTitle;

  /// Is rendering for this cosmetic type actually wired? If false, we show a
  /// "Coming soon" tag on the UI.
  bool get isVisible => type == CosmeticType.badge || type == CosmeticType.frame;
}

enum CosmeticType {
  badge,
  frame,
  theme,
  chatTitle,
  coachVoice,
  statsCard;

  static CosmeticType fromString(String s) => switch (s) {
        'badge' => CosmeticType.badge,
        'frame' => CosmeticType.frame,
        'theme' => CosmeticType.theme,
        'chat_title' => CosmeticType.chatTitle,
        'coach_voice' => CosmeticType.coachVoice,
        'stats_card' => CosmeticType.statsCard,
        _ => CosmeticType.badge,
      };

  String get apiValue => switch (this) {
        CosmeticType.badge => 'badge',
        CosmeticType.frame => 'frame',
        CosmeticType.theme => 'theme',
        CosmeticType.chatTitle => 'chat_title',
        CosmeticType.coachVoice => 'coach_voice',
        CosmeticType.statsCard => 'stats_card',
      };

  String get label => switch (this) {
        CosmeticType.badge => 'Badges',
        CosmeticType.frame => 'Frames',
        CosmeticType.theme => 'Themes',
        CosmeticType.chatTitle => 'Chat titles',
        CosmeticType.coachVoice => 'Coach voices',
        CosmeticType.statsCard => 'Stats cards',
      };
}

/// Ownership record (migration 1936).
@immutable
class UserCosmetic {
  final String cosmeticId;
  final DateTime unlockedAt;
  final int? unlockedAtLevel;
  final bool isEquipped;

  const UserCosmetic({
    required this.cosmeticId,
    required this.unlockedAt,
    this.unlockedAtLevel,
    required this.isEquipped,
  });

  factory UserCosmetic.fromJson(Map<String, dynamic> json) => UserCosmetic(
        cosmeticId: json['cosmetic_id'] as String,
        unlockedAt: DateTime.parse(json['unlocked_at'] as String),
        unlockedAtLevel: json['unlocked_at_level'] as int?,
        isEquipped: json['is_equipped'] as bool? ?? false,
      );
}
