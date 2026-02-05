import 'package:json_annotation/json_annotation.dart';

part 'user_xp.g.dart';

/// User's XP level title based on their current level (11 tiers - Migration 227)
enum XPTitle {
  @JsonValue('Beginner')
  beginner,
  @JsonValue('Novice')
  novice,
  @JsonValue('Apprentice')
  apprentice,
  @JsonValue('Athlete')
  athlete,
  @JsonValue('Elite')
  elite,
  @JsonValue('Master')
  master,
  @JsonValue('Champion')
  champion,
  @JsonValue('Legend')
  legend,
  @JsonValue('Mythic')
  mythic,
  @JsonValue('Immortal')
  immortal,
  @JsonValue('Transcendent')
  transcendent,
}

extension XPTitleExtension on XPTitle {
  String get displayName {
    switch (this) {
      case XPTitle.beginner:
        return 'Beginner';
      case XPTitle.novice:
        return 'Novice';
      case XPTitle.apprentice:
        return 'Apprentice';
      case XPTitle.athlete:
        return 'Athlete';
      case XPTitle.elite:
        return 'Elite';
      case XPTitle.master:
        return 'Master';
      case XPTitle.champion:
        return 'Champion';
      case XPTitle.legend:
        return 'Legend';
      case XPTitle.mythic:
        return 'Mythic';
      case XPTitle.immortal:
        return 'Immortal';
      case XPTitle.transcendent:
        return 'Transcendent';
    }
  }

  int get colorValue {
    switch (this) {
      case XPTitle.beginner:
        return 0xFF9E9E9E; // Gray
      case XPTitle.novice:
        return 0xFF8BC34A; // Light Green
      case XPTitle.apprentice:
        return 0xFF4CAF50; // Green
      case XPTitle.athlete:
        return 0xFF2196F3; // Blue
      case XPTitle.elite:
        return 0xFF9C27B0; // Purple
      case XPTitle.master:
        return 0xFFFF9800; // Orange
      case XPTitle.champion:
        return 0xFFFF5722; // Deep Orange
      case XPTitle.legend:
        return 0xFFFFD700; // Gold
      case XPTitle.mythic:
        return 0xFFE040FB; // Pink/Magenta
      case XPTitle.immortal:
        return 0xFF00E5FF; // Cyan (cosmic)
      case XPTitle.transcendent:
        return 0xFFFF1744; // Red (legendary)
    }
  }

  /// Get level range for this title (Migration 227 - 11 tiers)
  String get levelRange {
    switch (this) {
      case XPTitle.beginner:
        return '1-10';
      case XPTitle.novice:
        return '11-25';
      case XPTitle.apprentice:
        return '26-50';
      case XPTitle.athlete:
        return '51-75';
      case XPTitle.elite:
        return '76-100';
      case XPTitle.master:
        return '101-125';
      case XPTitle.champion:
        return '126-150';
      case XPTitle.legend:
        return '151-175';
      case XPTitle.mythic:
        return '176-200';
      case XPTitle.immortal:
        return '201-225';
      case XPTitle.transcendent:
        return '226-250';
    }
  }
}

/// User's XP and level progression data
@JsonSerializable()
class UserXP {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(name: 'user_id', defaultValue: '')
  final String userId;
  @JsonKey(name: 'total_xp', defaultValue: 0)
  final int totalXp;
  @JsonKey(name: 'current_level', defaultValue: 1)
  final int currentLevel;
  @JsonKey(name: 'xp_to_next_level', defaultValue: 25) // Level 1 -> 2 requires 25 XP (Migration 227)
  final int xpToNextLevel;
  @JsonKey(name: 'xp_in_current_level', defaultValue: 0)
  final int xpInCurrentLevel;
  @JsonKey(name: 'prestige_level', defaultValue: 0)
  final int prestigeLevel;
  @JsonKey(defaultValue: 'Beginner')
  final String title;
  @JsonKey(name: 'trust_level', defaultValue: 1)
  final int trustLevel;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserXP({
    this.id = '',
    this.userId = '',
    this.totalXp = 0,
    this.currentLevel = 1,
    this.xpToNextLevel = 25, // Level 1 -> 2 requires 25 XP (Migration 227)
    this.xpInCurrentLevel = 0,
    this.prestigeLevel = 0,
    this.title = 'Beginner',
    this.trustLevel = 1,
    this.createdAt,
    this.updatedAt,
  });

  /// Custom fromJson to handle API response variations
  factory UserXP.fromJson(Map<String, dynamic> json) {
    // Handle 'xp_title' field from API (should be 'title')
    if (json.containsKey('xp_title') && !json.containsKey('title')) {
      json['title'] = json['xp_title'];
    }
    // Ensure id exists (use user_id as fallback)
    if (!json.containsKey('id') || json['id'] == null) {
      json['id'] = json['user_id'] ?? '';
    }
    return _$UserXPFromJson(json);
  }
  Map<String, dynamic> toJson() => _$UserXPToJson(this);

  /// Get progress percentage to next level (0.0 to 1.0)
  double get progressFraction {
    if (xpToNextLevel == 0) return 1.0;
    return (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
  }

  /// Get progress percentage as integer (0 to 100)
  int get progressPercent => (progressFraction * 100).round();

  /// Get the XP title enum (Migration 227 - 11 tiers)
  XPTitle get xpTitle {
    if (currentLevel <= 10) return XPTitle.beginner;
    if (currentLevel <= 25) return XPTitle.novice;
    if (currentLevel <= 50) return XPTitle.apprentice;
    if (currentLevel <= 75) return XPTitle.athlete;
    if (currentLevel <= 100) return XPTitle.elite;
    if (currentLevel <= 125) return XPTitle.master;
    if (currentLevel <= 150) return XPTitle.champion;
    if (currentLevel <= 175) return XPTitle.legend;
    if (currentLevel <= 200) return XPTitle.mythic;
    if (currentLevel <= 225) return XPTitle.immortal;
    return XPTitle.transcendent;
  }

  /// Get formatted total XP string
  String get formattedTotalXp {
    if (totalXp >= 1000000) {
      return '${(totalXp / 1000000).toStringAsFixed(1)}M';
    } else if (totalXp >= 1000) {
      return '${(totalXp / 1000).toStringAsFixed(1)}K';
    }
    return totalXp.toString();
  }

  /// Get formatted XP progress string (ensures non-negative display)
  String get formattedProgress {
    final displayXp = xpInCurrentLevel < 0 ? 0 : xpInCurrentLevel;
    return '$displayXp / $xpToNextLevel XP';
  }

  /// Get level display string (includes prestige if applicable)
  String get levelDisplay {
    if (prestigeLevel > 0) {
      return 'P$prestigeLevel Lvl $currentLevel';
    }
    return 'Level $currentLevel';
  }

  /// Check if user is at max level (before prestige)
  bool get isMaxLevel => currentLevel >= 250;

  /// Empty constructor for initial state (Migration 227)
  factory UserXP.empty(String userId) => UserXP(
        id: '',
        userId: userId,
        totalXp: 0,
        currentLevel: 1,
        xpToNextLevel: 25, // Level 1 -> 2 requires 25 XP
        xpInCurrentLevel: 0,
        prestigeLevel: 0,
        title: 'Beginner',
        trustLevel: 1,
      );
}

/// XP transaction record
@JsonSerializable()
class XPTransaction {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'xp_amount')
  final int xpAmount;
  final String source;
  @JsonKey(name: 'source_id')
  final String? sourceId;
  final String? description;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const XPTransaction({
    required this.id,
    required this.userId,
    required this.xpAmount,
    required this.source,
    this.sourceId,
    this.description,
    this.isVerified = false,
    required this.createdAt,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) =>
      _$XPTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$XPTransactionToJson(this);

  /// Get icon for XP source
  String get sourceIcon {
    switch (source) {
      case 'workout':
        return '🏋️';
      case 'achievement':
        return '🏆';
      case 'pr':
        return '💪';
      case 'streak':
        return '🔥';
      case 'challenge':
        return '🎯';
      case 'meal_log':
        return '🥗';
      case 'weight_log':
        return '⚖️';
      case 'photo':
        return '📸';
      default:
        return '✨';
    }
  }
}

/// XP summary with rank information
@JsonSerializable()
class XPSummary {
  @JsonKey(name: 'total_xp')
  final int totalXp;
  @JsonKey(name: 'current_level')
  final int currentLevel;
  final String title;
  @JsonKey(name: 'xp_to_next_level')
  final int xpToNextLevel;
  @JsonKey(name: 'xp_in_current_level')
  final int xpInCurrentLevel;
  @JsonKey(name: 'progress_percent')
  final double progressPercent;
  @JsonKey(name: 'prestige_level')
  final int prestigeLevel;
  @JsonKey(name: 'trust_level')
  final int trustLevel;
  @JsonKey(name: 'rank_position')
  final int rankPosition;

  const XPSummary({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.title = 'Beginner',
    this.xpToNextLevel = 25, // Level 1 -> 2 requires 25 XP (Migration 227)
    this.xpInCurrentLevel = 0,
    this.progressPercent = 0,
    this.prestigeLevel = 0,
    this.trustLevel = 1,
    this.rankPosition = 0,
  });

  factory XPSummary.fromJson(Map<String, dynamic> json) =>
      _$XPSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$XPSummaryToJson(this);

  /// Get progress as fraction (0.0 to 1.0)
  double get progressFraction => progressPercent / 100;

  /// Get formatted rank
  String get formattedRank => '#$rankPosition';
}

/// XP leaderboard entry
@JsonSerializable()
class XPLeaderboardEntry {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'total_xp')
  final int totalXp;
  @JsonKey(name: 'current_level')
  final int currentLevel;
  final String title;
  @JsonKey(name: 'prestige_level')
  final int prestigeLevel;
  final int rank;

  const XPLeaderboardEntry({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.title = 'Beginner',
    this.prestigeLevel = 0,
    this.rank = 0,
  });

  factory XPLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$XPLeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$XPLeaderboardEntryToJson(this);

  /// Get display name (or fallback)
  String get displayName => fullName ?? 'Anonymous';

  /// Get level display string
  String get levelDisplay {
    if (prestigeLevel > 0) {
      return 'P$prestigeLevel Lvl $currentLevel';
    }
    return 'Lvl $currentLevel';
  }
}

/// Reward received when leveling up (Migration 231)
@JsonSerializable()
class LevelUpReward {
  final int level;
  final String type; // 'fitness_crate', 'streak_shield', 'xp_token_2x', 'premium_crate'
  final int quantity;
  final String description;
  @JsonKey(name: 'bonus_type')
  final String? bonusType;
  @JsonKey(name: 'bonus_quantity')
  final int? bonusQuantity;
  @JsonKey(name: 'bonus_description')
  final String? bonusDescription;

  const LevelUpReward({
    required this.level,
    required this.type,
    required this.quantity,
    required this.description,
    this.bonusType,
    this.bonusQuantity,
    this.bonusDescription,
  });

  factory LevelUpReward.fromJson(Map<String, dynamic> json) =>
      _$LevelUpRewardFromJson(json);
  Map<String, dynamic> toJson() => _$LevelUpRewardToJson(this);

  /// Get emoji icon for reward type
  String get icon {
    switch (type) {
      case 'fitness_crate':
        return '📦';
      case 'premium_crate':
        return '🎁';
      case 'streak_shield':
        return '🛡️';
      case 'xp_token_2x':
        return '⚡';
      default:
        return '🎉';
    }
  }

  /// Get display name for reward type
  String get displayName {
    switch (type) {
      case 'fitness_crate':
        return 'Fitness Crate';
      case 'premium_crate':
        return 'Premium Crate';
      case 'streak_shield':
        return 'Streak Shield';
      case 'xp_token_2x':
        return '2x XP Token';
      default:
        return 'Reward';
    }
  }

  /// Check if this reward has a bonus (e.g., major milestone)
  bool get hasBonus => bonusType != null && bonusQuantity != null;
}

/// Level up notification data
@JsonSerializable()
class LevelUpEvent {
  @JsonKey(name: 'new_level')
  final int newLevel;
  @JsonKey(name: 'old_level')
  final int oldLevel;
  @JsonKey(name: 'new_title')
  final String? newTitle;
  @JsonKey(name: 'old_title')
  final String? oldTitle;
  @JsonKey(name: 'total_xp')
  final int totalXp;
  @JsonKey(name: 'xp_earned')
  final int xpEarned;
  @JsonKey(name: 'unlocked_reward')
  final String? unlockedReward;
  /// Rewards distributed for this level-up (from Migration 231)
  final List<LevelUpReward>? rewards;

  const LevelUpEvent({
    required this.newLevel,
    required this.oldLevel,
    this.newTitle,
    this.oldTitle,
    this.totalXp = 0,
    this.xpEarned = 0,
    this.unlockedReward,
    this.rewards,
  });

  factory LevelUpEvent.fromJson(Map<String, dynamic> json) =>
      _$LevelUpEventFromJson(json);
  Map<String, dynamic> toJson() => _$LevelUpEventToJson(this);

  /// Check if user got a new title
  bool get hasNewTitle => newTitle != null && newTitle != oldTitle;

  /// Check if user unlocked a reward
  bool get hasReward => unlockedReward != null;

  /// Check if there are any level-up rewards
  bool get hasRewards => rewards != null && rewards!.isNotEmpty;

  /// Get number of levels gained
  int get levelsGained => newLevel - oldLevel;
}
