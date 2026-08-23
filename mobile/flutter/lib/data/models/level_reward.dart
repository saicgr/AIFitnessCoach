import 'package:fitwiz/core/constants/branding.dart';
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

/// Display metadata for a `merch_type` string as returned by the backend
/// `/xp/all-levels` endpoint (`merch_type_for_level()` SQL function,
/// migration 2424). Purely cosmetic (name/icon) — the LEVEL -> TYPE
/// mapping itself is never guessed client-side; see E2E #371.
const Map<String, ({String label, String icon})> _merchTypeDisplay = {
  'sticker_pack': (label: 'Sticker Pack', icon: '✨'),
  't_shirt': (label: 'T-Shirt', icon: '👕'),
  'hoodie': (label: 'Hoodie', icon: '🧥'),
  'full_merch_kit': (label: 'Full Merch Kit', icon: '🎁'),
  'signed_premium_kit': (label: 'Signed Premium Kit', icon: '🏆'),
};

/// Helper class to get rewards for any level
class LevelRewards {
  /// Milestone levels that have special cosmetic/merch rewards.
  /// Must stay in sync with backend `MAJOR_MILESTONE_LEVELS`.
  static const milestones = [5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 175, 200, 225, 250];

  /// Levels that give fitness crates (non-milestone, every 5 levels offset by 3)
  /// Example: 3, 8, 13, 18, 23, 28, etc.
  static bool isCrateLevel(int level) {
    if (level < 3) return false;
    return (level - 3) % 5 == 0 && !milestones.contains(level);
  }

  /// Get the reward for a specific level.
  ///
  /// [merchType] is the backend's `merch_type` value for this level, read
  /// from `/xp/all-levels` (see `allLevelsProvider`) — the single source
  /// of truth for which levels unlock physical merch (E2E #371: this used
  /// to be a hardcoded Level 50/100/150/200/250 ladder here that silently
  /// drifted out of sync with the DB's rescaled 20/40/60/80/100 ladder,
  /// migration 2424). When non-null it always wins over the local
  /// milestone-flavor switch below. Pass null only when the backend data
  /// genuinely isn't available yet (e.g. `allLevelsProvider` still
  /// loading) — the switch's per-level cosmetic copy is then used as a
  /// degraded-mode fallback, never as an alternate source of truth.
  static LevelReward getRewardForLevel(int level, {String? merchType}) {
    // Level 1 has no reward (starting point)
    if (level <= 1) {
      return const LevelReward(
        type: LevelRewardType.xpBonus,
        name: 'Welcome!',
        description: 'Your fitness journey begins',
        icon: '🌟',
      );
    }

    // Backend-confirmed merch unlock — always takes priority.
    if (merchType != null) {
      final display = _merchTypeDisplay[merchType];
      final label = display?.label ?? merchType;
      return LevelReward.merch(
        name: 'FREE ${Branding.appName} $label',
        description: 'Real ${Branding.appName} $label shipped to you for reaching Level $level.',
        icon: display?.icon,
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

  /// Get milestone reward for specific levels.
  /// Mirrors backend `MILESTONE_REWARDS_DISPLAY` (crate/token/badge flavor
  /// only). Does NOT decide merch — that comes from the backend `merchType`
  /// argument on `getRewardForLevel` (E2E #371).
  static LevelReward? _getMilestoneReward(int level) {
    switch (level) {
      case 5:
        return LevelReward.cosmetic(
          name: 'Rising Star Milestone',
          // Quantities mirror migration 1935 (post-1940 fix): 3 shields,
          // 2 fitness crates, 1 premium crate, 2 "2x XP Token" consumables.
          description: '3x Streak Shield + 2x Fitness Crate + Premium Crate + 2x 2x XP Token. '
              '"Rising Star" animated badge unlocked — equip in Cosmetics.',
          icon: '⭐',
          cosmeticId: 'badge_rising_star',
        );
      case 10:
        return LevelReward.cosmetic(
          name: 'Iron Will Milestone',
          description: '5x 2x XP Token + 3x Fitness Crate + 2x Premium Crate + 2x Streak Shield. '
              '"Iron Will" animated badge + Iron accent theme unlocked.',
          icon: '🏅',
          cosmeticId: 'badge_iron_will_animated',
        );
      case 15:
        return LevelReward.cosmetic(
          name: 'Premium Crate Bundle',
          description: '3x Fitness + 2x Premium + 2x 2x XP Token.',
          icon: '📦',
        );
      case 20:
        return LevelReward.cosmetic(
          name: 'Streak Shield Stash',
          description: '4x Streak Shield + 2x Premium Crate + 2x 2x XP Token.',
          icon: '🛡️',
        );
      case 25:
        return LevelReward.cosmetic(
          name: 'Dedicated Milestone',
          description: '4x 2x XP Token + 3x Premium Crate + 3x Fitness Crate. '
              'Bronze animated frame + "Dedicated" chat title unlocked.',
          icon: '🖼️',
          cosmeticId: 'frame_bronze_animated',
        );
      case 30:
        return LevelReward.cosmetic(
          name: 'Milestone Crate Haul',
          description: '5x 2x XP Token + 3x Premium Crate + more.',
          icon: '🎁',
        );
      case 40:
        return LevelReward.cosmetic(
          name: 'Shield Wall Bundle',
          description: '5x Streak Shield + 4x Premium Crate + more.',
          icon: '🛡️',
        );
      case 50:
        // NOTE: this used to claim a free merch shipment at this level.
        // The merch unlock ladder moved (E2E #371) — the real answer for
        // "does level 50 unlock merch" now comes from the backend
        // `merchType` argument above, not from a level literal here.
        return LevelReward.cosmetic(
          name: 'Veteran Milestone',
          description: '6x 2x XP Token + 5x Premium Crate + 5x Fitness Crate + 5x Streak Shield.',
          icon: '✨',
        );
      case 60:
        return LevelReward.cosmetic(
          name: 'Fitness Crate Avalanche',
          description: '7x Fitness Crate + 5x Premium Crate + 5x 2x XP Token + more.',
          icon: '📦',
        );
      case 75:
        return LevelReward.cosmetic(
          name: 'Elite Milestone',
          description: '7x Premium Crate + 5x 2x XP Token + 5x Fitness Crate. '
              'Gold holographic frame + "Elite" chat title + Gold accent theme + Elite stats card unlocked.',
          icon: '👑',
          cosmeticId: 'frame_gold_holographic',
        );
      case 100:
        // See the level-50 note above — merch is now backend-decided, not
        // hardcoded to this level literal (E2E #371).
        return LevelReward.cosmetic(
          name: 'Elite Badge Milestone',
          description: 'Elite status + premium crate bundle.',
          icon: '👕',
        );
      case 125:
        return LevelReward.cosmetic(
          name: 'Master Badge',
          description: '12x Premium Crate + 8x 2x XP Token + 8x Fitness Crate.',
          icon: '🎖️',
        );
      case 150:
        // See the level-50 note above — merch is now backend-decided, not
        // hardcoded to this level literal (E2E #371).
        return LevelReward.cosmetic(
          name: 'Champion Badge Milestone',
          description: 'Champion status unlocked.',
          icon: '🧥',
        );
      case 175:
        return LevelReward.cosmetic(
          name: 'Legend Badge',
          description: '17x Premium Crate + 12x 2x XP Token + 12x Fitness Crate.',
          icon: '🎖️',
        );
      case 200:
        // See the level-50 note above — merch is now backend-decided, not
        // hardcoded to this level literal (E2E #371).
        return LevelReward.cosmetic(
          name: 'Mythic Badge Milestone',
          description: 'Mythic status unlocked.',
          icon: '🎁',
        );
      case 225:
        return LevelReward.cosmetic(
          name: 'Immortal Badge',
          description: '25x Premium Crate + 20x 2x XP Token + 20x Fitness Crate.',
          icon: '🎖️',
        );
      case 250:
        // See the level-50 note above — merch is now backend-decided, not
        // hardcoded to this level literal (E2E #371).
        return LevelReward.cosmetic(
          name: 'Transcendent Badge Milestone',
          description: 'The ultimate status badge.',
          icon: '🏆',
        );
      default:
        return null;
    }
  }
}
