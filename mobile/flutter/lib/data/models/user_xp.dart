import 'package:json_annotation/json_annotation.dart';

part 'user_xp.g.dart';

/// User's XP level title based on their current level
enum XPTitle {
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
  @JsonValue('Legend')
  legend,
  @JsonValue('Mythic')
  mythic,
}

extension XPTitleExtension on XPTitle {
  String get displayName {
    switch (this) {
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
      case XPTitle.legend:
        return 'Legend';
      case XPTitle.mythic:
        return 'Mythic';
    }
  }

  int get colorValue {
    switch (this) {
      case XPTitle.novice:
        return 0xFF9E9E9E; // Gray
      case XPTitle.apprentice:
        return 0xFF4CAF50; // Green
      case XPTitle.athlete:
        return 0xFF2196F3; // Blue
      case XPTitle.elite:
        return 0xFF9C27B0; // Purple
      case XPTitle.master:
        return 0xFFFF9800; // Orange
      case XPTitle.legend:
        return 0xFFFFD700; // Gold
      case XPTitle.mythic:
        return 0xFFE040FB; // Pink/Magenta (rainbow effect)
    }
  }

  /// Get level range for this title
  String get levelRange {
    switch (this) {
      case XPTitle.novice:
        return '1-10';
      case XPTitle.apprentice:
        return '11-25';
      case XPTitle.athlete:
        return '26-50';
      case XPTitle.elite:
        return '51-75';
      case XPTitle.master:
        return '76-99';
      case XPTitle.legend:
        return '100';
      case XPTitle.mythic:
        return '100+';
    }
  }
}

/// User's XP and level progression data
@JsonSerializable()
class UserXP {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_xp')
  final int totalXp;
  @JsonKey(name: 'current_level')
  final int currentLevel;
  @JsonKey(name: 'xp_to_next_level')
  final int xpToNextLevel;
  @JsonKey(name: 'xp_in_current_level')
  final int xpInCurrentLevel;
  @JsonKey(name: 'prestige_level')
  final int prestigeLevel;
  final String title;
  @JsonKey(name: 'trust_level')
  final int trustLevel;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserXP({
    required this.id,
    required this.userId,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.xpToNextLevel = 50, // Level 1 -> 2 requires only 50 XP (Day 1 achievable!)
    this.xpInCurrentLevel = 0,
    this.prestigeLevel = 0,
    this.title = 'Novice',
    this.trustLevel = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory UserXP.fromJson(Map<String, dynamic> json) => _$UserXPFromJson(json);
  Map<String, dynamic> toJson() => _$UserXPToJson(this);

  /// Get progress percentage to next level (0.0 to 1.0)
  double get progressFraction {
    if (xpToNextLevel == 0) return 1.0;
    return (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
  }

  /// Get progress percentage as integer (0 to 100)
  int get progressPercent => (progressFraction * 100).round();

  /// Get the XP title enum
  XPTitle get xpTitle {
    if (currentLevel <= 10) return XPTitle.novice;
    if (currentLevel <= 25) return XPTitle.apprentice;
    if (currentLevel <= 50) return XPTitle.athlete;
    if (currentLevel <= 75) return XPTitle.elite;
    if (currentLevel <= 99) return XPTitle.master;
    if (currentLevel == 100 && prestigeLevel == 0) return XPTitle.legend;
    return XPTitle.mythic;
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

  /// Get formatted XP progress string
  String get formattedProgress {
    return '$xpInCurrentLevel / $xpToNextLevel XP';
  }

  /// Get level display string (includes prestige if applicable)
  String get levelDisplay {
    if (prestigeLevel > 0) {
      return 'P$prestigeLevel Lvl $currentLevel';
    }
    return 'Level $currentLevel';
  }

  /// Check if user is at max level (before prestige)
  bool get isMaxLevel => currentLevel >= 100;

  /// Empty constructor for initial state
  factory UserXP.empty(String userId) => UserXP(
        id: '',
        userId: userId,
        totalXp: 0,
        currentLevel: 1,
        xpToNextLevel: 50, // Level 1 -> 2 requires only 50 XP (Day 1 achievable!)
        xpInCurrentLevel: 0,
        prestigeLevel: 0,
        title: 'Novice',
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
    this.title = 'Novice',
    this.xpToNextLevel = 50, // Level 1 -> 2 requires only 50 XP (Day 1 achievable!)
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
    this.title = 'Novice',
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

  const LevelUpEvent({
    required this.newLevel,
    required this.oldLevel,
    this.newTitle,
    this.oldTitle,
    this.totalXp = 0,
    this.xpEarned = 0,
    this.unlockedReward,
  });

  factory LevelUpEvent.fromJson(Map<String, dynamic> json) =>
      _$LevelUpEventFromJson(json);
  Map<String, dynamic> toJson() => _$LevelUpEventToJson(this);

  /// Check if user got a new title
  bool get hasNewTitle => newTitle != null && newTitle != oldTitle;

  /// Check if user unlocked a reward
  bool get hasReward => unlockedReward != null;

  /// Get number of levels gained
  int get levelsGained => newLevel - oldLevel;
}
