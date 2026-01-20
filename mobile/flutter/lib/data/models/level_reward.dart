/// Types of rewards that can be earned per level
enum LevelRewardType {
  xpBonus,       // Permanent +X% XP multiplier
  streakShield,  // Protects streak if missed day
  doubleXpToken, // 24h of 2x XP
  cosmetic,      // Profile badge, frame, theme, etc.
  merch,         // Physical merchandise (T-shirt, hoodie, etc.)
  crate,         // Fitness crate with random rewards
}

/// A reward earned for reaching a specific level
class LevelReward {
  final LevelRewardType type;
  final String name;
  final String description;
  final String? icon;
  final int? amount; // For consumables (1x, 2x, etc.)
  final int? xpBonusPercent; // For XP bonus rewards
  final String? cosmeticId; // For cosmetic unlocks
  final bool isMilestone; // Major milestone (5, 10, 25, 50, 75, 100)

  const LevelReward({
    required this.type,
    required this.name,
    required this.description,
    this.icon,
    this.amount,
    this.xpBonusPercent,
    this.cosmeticId,
    this.isMilestone = false,
  });

  /// XP Bonus reward factory
  factory LevelReward.xpBonus(int percent) => LevelReward(
    type: LevelRewardType.xpBonus,
    name: '+$percent% XP Bonus',
    description: 'Permanent XP multiplier increase',
    icon: '⚡',
    xpBonusPercent: percent,
  );

  /// Streak Shield reward factory
  factory LevelReward.streakShield(int count) => LevelReward(
    type: LevelRewardType.streakShield,
    name: '${count}x Streak Shield${count > 1 ? 's' : ''}',
    description: 'Protect your streak if you miss a day',
    icon: '🛡️',
    amount: count,
  );

  /// Double XP Token reward factory
  factory LevelReward.doubleXpToken(int count) => LevelReward(
    type: LevelRewardType.doubleXpToken,
    name: '${count}x Double XP Token${count > 1 ? 's' : ''}',
    description: '24 hours of 2x XP earnings',
    icon: '✨',
    amount: count,
  );

  /// Cosmetic reward factory (badge, frame, theme, etc.)
  factory LevelReward.cosmetic({
    required String name,
    required String description,
    String? icon,
    String? cosmeticId,
  }) => LevelReward(
    type: LevelRewardType.cosmetic,
    name: name,
    description: description,
    icon: icon ?? '🎨',
    cosmeticId: cosmeticId,
    isMilestone: true,
  );

  /// Merch reward factory (physical items)
  factory LevelReward.merch({
    required String name,
    required String description,
    String? icon,
  }) => LevelReward(
    type: LevelRewardType.merch,
    name: name,
    description: description,
    icon: icon ?? '🎁',
    isMilestone: true,
  );

  /// Fitness crate reward factory
  factory LevelReward.crate(CrateTier tier) => LevelReward(
    type: LevelRewardType.crate,
    name: '${tier.displayName} Fitness Crate',
    description: tier.description,
    icon: tier.icon,
  );
}

/// Tier of fitness crate based on user level
enum CrateTier {
  bronze,    // Levels 1-10
  silver,    // Levels 11-25
  gold,      // Levels 26-50
  diamond,   // Levels 51-75
  legendary, // Levels 76-99
  ultimate,  // Level 100
}

extension CrateTierExtension on CrateTier {
  String get displayName {
    switch (this) {
      case CrateTier.bronze:
        return 'Bronze';
      case CrateTier.silver:
        return 'Silver';
      case CrateTier.gold:
        return 'Gold';
      case CrateTier.diamond:
        return 'Diamond';
      case CrateTier.legendary:
        return 'Legendary';
      case CrateTier.ultimate:
        return 'Ultimate';
    }
  }

  String get description {
    switch (this) {
      case CrateTier.bronze:
        return 'Contains common consumables and bonus XP';
      case CrateTier.silver:
        return 'Better consumables with a chance of theme unlock';
      case CrateTier.gold:
        return 'Good consumables with a chance of badge or frame';
      case CrateTier.diamond:
        return 'Great consumables with high chance of cosmetics';
      case CrateTier.legendary:
        return 'Best consumables with rare cosmetic rewards';
      case CrateTier.ultimate:
        return 'The ultimate crate with everything + merch!';
    }
  }

  String get icon {
    switch (this) {
      case CrateTier.bronze:
        return '📦';
      case CrateTier.silver:
        return '🎁';
      case CrateTier.gold:
        return '✨';
      case CrateTier.diamond:
        return '💎';
      case CrateTier.legendary:
        return '🏆';
      case CrateTier.ultimate:
        return '👑';
    }
  }

  int get colorValue {
    switch (this) {
      case CrateTier.bronze:
        return 0xFFCD7F32; // Bronze
      case CrateTier.silver:
        return 0xFFC0C0C0; // Silver
      case CrateTier.gold:
        return 0xFFFFD700; // Gold
      case CrateTier.diamond:
        return 0xFF4FC3F7; // Light Blue
      case CrateTier.legendary:
        return 0xFFE040FB; // Purple/Magenta
      case CrateTier.ultimate:
        return 0xFFFFD700; // Gold with rainbow effect
    }
  }

  /// Get crate tier for a given level
  static CrateTier forLevel(int level) {
    if (level <= 10) return CrateTier.bronze;
    if (level <= 25) return CrateTier.silver;
    if (level <= 50) return CrateTier.gold;
    if (level <= 75) return CrateTier.diamond;
    if (level < 100) return CrateTier.legendary;
    return CrateTier.ultimate;
  }
}

/// A single reward item from a crate
class CrateRewardItem {
  final String name;
  final String description;
  final String icon;
  final LevelRewardType type;
  final int? amount;
  final String? cosmeticId;
  final bool isRare;

  const CrateRewardItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.amount,
    this.cosmeticId,
    this.isRare = false,
  });
}

/// Streak milestone data for celebrations
class StreakMilestone {
  final int days;
  final String badgeName;
  final String badgeIcon;
  final int shieldCount;
  final int? bonusXp;
  final String? cosmeticReward;
  final bool hasMerch;

  const StreakMilestone({
    required this.days,
    required this.badgeName,
    required this.badgeIcon,
    required this.shieldCount,
    this.bonusXp,
    this.cosmeticReward,
    this.hasMerch = false,
  });

  /// Get all streak milestones
  static List<StreakMilestone> get all => [
    const StreakMilestone(
      days: 7,
      badgeName: 'Bronze Streak Badge',
      badgeIcon: '🔥',
      shieldCount: 1,
    ),
    const StreakMilestone(
      days: 14,
      badgeName: 'Week Warrior',
      badgeIcon: '🔥',
      shieldCount: 2,
      bonusXp: 100,
    ),
    const StreakMilestone(
      days: 30,
      badgeName: 'Silver Streak Badge',
      badgeIcon: '🔥',
      shieldCount: 3,
    ),
    const StreakMilestone(
      days: 60,
      badgeName: 'Gold Streak Badge',
      badgeIcon: '🔥',
      shieldCount: 5,
    ),
    const StreakMilestone(
      days: 90,
      badgeName: 'Platinum Streak Badge',
      badgeIcon: '🔥',
      shieldCount: 10,
    ),
    const StreakMilestone(
      days: 180,
      badgeName: 'Diamond Streak Badge',
      badgeIcon: '💎',
      shieldCount: 10,
      cosmeticReward: 'Streak Master Profile Flair',
    ),
    const StreakMilestone(
      days: 365,
      badgeName: 'YEAR WARRIOR',
      badgeIcon: '🏆',
      shieldCount: 20,
      cosmeticReward: 'Legendary Streak Crown',
      hasMerch: true,
    ),
  ];

  /// Get milestone for a given streak (if any)
  static StreakMilestone? forStreak(int currentStreak, int previousStreak) {
    for (final milestone in all) {
      if (currentStreak >= milestone.days && previousStreak < milestone.days) {
        return milestone;
      }
    }
    return null;
  }

  /// Get next milestone for current streak
  static StreakMilestone? nextMilestone(int currentStreak) {
    for (final milestone in all) {
      if (currentStreak < milestone.days) {
        return milestone;
      }
    }
    return null;
  }

  /// Days remaining until next milestone
  static int? daysUntilNext(int currentStreak) {
    final next = nextMilestone(currentStreak);
    if (next == null) return null;
    return next.days - currentStreak;
  }
}

/// Helper class to get rewards for any level
class LevelRewards {
  /// Milestone levels that have special cosmetic/merch rewards
  static const milestones = [5, 10, 15, 25, 35, 50, 75, 100];

  /// Levels that give fitness crates (non-milestone, every 5 levels offset by 3)
  /// Example: 3, 8, 13, 18, 23, 28, etc.
  static bool isCrateLevel(int level) {
    if (level < 3) return false;
    return (level - 3) % 5 == 0 && !milestones.contains(level);
  }

  /// Get the reward for a specific level
  static LevelReward getRewardForLevel(int level) {
    // Level 1 has no reward (starting point)
    if (level <= 1) {
      return const LevelReward(
        type: LevelRewardType.xpBonus,
        name: 'Welcome!',
        description: 'Your fitness journey begins',
        icon: '🌟',
      );
    }

    // Check for milestone rewards first
    final milestoneReward = _getMilestoneReward(level);
    if (milestoneReward != null) {
      return milestoneReward;
    }

    // Check for crate levels
    if (isCrateLevel(level)) {
      return LevelReward.crate(CrateTierExtension.forLevel(level));
    }

    // Even levels: XP bonus
    if (level % 2 == 0) {
      return LevelReward.xpBonus(1);
    }

    // Odd levels: Consumables (alternating between shields and tokens)
    if (level % 4 == 1) {
      return LevelReward.streakShield(1);
    } else {
      return LevelReward.doubleXpToken(1);
    }
  }

  /// Get milestone reward for specific levels
  static LevelReward? _getMilestoneReward(int level) {
    switch (level) {
      case 5:
        return LevelReward.cosmetic(
          name: '"Rising Star" Badge',
          description: 'Your first milestone! New profile border unlocked.',
          icon: '⭐',
          cosmeticId: 'badge_rising_star',
        );
      case 10:
        return LevelReward.cosmetic(
          name: 'Bronze Profile Frame',
          description: 'A shiny new frame for your profile.',
          icon: '🖼️',
          cosmeticId: 'frame_bronze',
        );
      case 15:
        return LevelReward.cosmetic(
          name: 'Exclusive Theme Colors',
          description: 'Unlock new app theme color options.',
          icon: '🎨',
          cosmeticId: 'theme_exclusive',
        );
      case 25:
        return LevelReward.cosmetic(
          name: '"Dedicated" Animated Badge',
          description: 'An animated badge showing your dedication.',
          icon: '💫',
          cosmeticId: 'badge_dedicated_animated',
        );
      case 35:
        return LevelReward.cosmetic(
          name: 'Animated Profile Effects',
          description: 'Your profile now has animated effects!',
          icon: '✨',
          cosmeticId: 'profile_effects_animated',
        );
      case 50:
        return LevelReward.merch(
          name: '"Veteran" Badge + FREE T-Shirt!',
          description: 'Claim your free FitWiz T-Shirt in the Rewards tab.',
          icon: '👕',
        );
      case 75:
        return LevelReward.merch(
          name: '"Elite" Holographic Badge + FREE Shaker Bottle!',
          description: 'Claim your free shaker bottle in the Rewards tab.',
          icon: '🥤',
        );
      case 100:
        return LevelReward.merch(
          name: '"Legend" Badge + Full Merch Kit!',
          description: 'Claim your FREE Hoodie + Merch Kit in the Rewards tab.',
          icon: '👑',
        );
      default:
        return null;
    }
  }
}
