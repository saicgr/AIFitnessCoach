import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trophy.g.dart';

/// Trophy tier levels with visual properties
enum TrophyTier {
  @JsonValue('bronze')
  bronze,
  @JsonValue('silver')
  silver,
  @JsonValue('gold')
  gold,
  @JsonValue('platinum')
  platinum,
  @JsonValue('diamond')
  diamond,
}

extension TrophyTierExtension on TrophyTier {
  String get displayName {
    switch (this) {
      case TrophyTier.bronze:
        return 'Bronze';
      case TrophyTier.silver:
        return 'Silver';
      case TrophyTier.gold:
        return 'Gold';
      case TrophyTier.platinum:
        return 'Platinum';
      case TrophyTier.diamond:
        return 'Diamond';
    }
  }

  int get tierLevel {
    switch (this) {
      case TrophyTier.bronze:
        return 1;
      case TrophyTier.silver:
        return 2;
      case TrophyTier.gold:
        return 3;
      case TrophyTier.platinum:
        return 4;
      case TrophyTier.diamond:
        return 5;
    }
  }

  Color get primaryColor {
    switch (this) {
      case TrophyTier.bronze:
        return const Color(0xFFCD7F32);
      case TrophyTier.silver:
        return const Color(0xFFC0C0C0);
      case TrophyTier.gold:
        return const Color(0xFFFFD700);
      case TrophyTier.platinum:
        return const Color(0xFFE5E4E2);
      case TrophyTier.diamond:
        return const Color(0xFF00BFFF);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case TrophyTier.bronze:
        return const Color(0xFF8B4513);
      case TrophyTier.silver:
        return const Color(0xFFE8E8E8);
      case TrophyTier.gold:
        return const Color(0xFFFFA500);
      case TrophyTier.platinum:
        return const Color(0xFFFFFFFF);
      case TrophyTier.diamond:
        return const Color(0xFF87CEEB);
    }
  }

  /// Get gradient colors for the tier
  List<Color> get gradientColors {
    switch (this) {
      case TrophyTier.bronze:
        return [
          const Color(0xFFCD7F32),
          const Color(0xFF8B4513),
          const Color(0xFFCD7F32),
        ];
      case TrophyTier.silver:
        return [
          const Color(0xFFC0C0C0),
          const Color(0xFFE8E8E8),
          const Color(0xFFC0C0C0),
        ];
      case TrophyTier.gold:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFFFFD700),
        ];
      case TrophyTier.platinum:
        return [
          const Color(0xFFE5E4E2),
          const Color(0xFFFFFFFF),
          const Color(0xFFE5E4E2),
        ];
      case TrophyTier.diamond:
        return [
          const Color(0xFF00BFFF),
          const Color(0xFF87CEEB),
          const Color(0xFFE0FFFF),
          const Color(0xFF00BFFF),
        ];
    }
  }

  /// Animation type for the tier
  String get animationType {
    switch (this) {
      case TrophyTier.bronze:
        return 'none';
      case TrophyTier.silver:
        return 'shimmer';
      case TrophyTier.gold:
        return 'sparkle';
      case TrophyTier.platinum:
        return 'iridescent';
      case TrophyTier.diamond:
        return 'rainbow';
    }
  }

  /// XP multiplier for the tier
  int get xpMultiplier {
    switch (this) {
      case TrophyTier.bronze:
        return 1;
      case TrophyTier.silver:
        return 2;
      case TrophyTier.gold:
        return 4;
      case TrophyTier.platinum:
        return 10;
      case TrophyTier.diamond:
        return 20;
    }
  }
}

/// Trophy category
enum TrophyCategory {
  @JsonValue('exercise_mastery')
  exerciseMastery,
  @JsonValue('volume')
  volume,
  @JsonValue('time')
  time,
  @JsonValue('consistency')
  consistency,
  @JsonValue('personal_records')
  personalRecords,
  @JsonValue('social')
  social,
  @JsonValue('body_composition')
  bodyComposition,
  @JsonValue('nutrition')
  nutrition,
  @JsonValue('fasting')
  fasting,
  @JsonValue('ai_coach')
  aiCoach,
  @JsonValue('special')
  special,
  @JsonValue('world_record')
  worldRecord,
}

extension TrophyCategoryExtension on TrophyCategory {
  String get displayName {
    switch (this) {
      case TrophyCategory.exerciseMastery:
        return 'Exercise Mastery';
      case TrophyCategory.volume:
        return 'Volume';
      case TrophyCategory.time:
        return 'Time';
      case TrophyCategory.consistency:
        return 'Consistency';
      case TrophyCategory.personalRecords:
        return 'Personal Records';
      case TrophyCategory.social:
        return 'Social';
      case TrophyCategory.bodyComposition:
        return 'Body Composition';
      case TrophyCategory.nutrition:
        return 'Nutrition';
      case TrophyCategory.fasting:
        return 'Fasting';
      case TrophyCategory.aiCoach:
        return 'AI Coach';
      case TrophyCategory.special:
        return 'Special';
      case TrophyCategory.worldRecord:
        return 'World Records';
    }
  }

  String get icon {
    switch (this) {
      case TrophyCategory.exerciseMastery:
        return '🏋️';
      case TrophyCategory.volume:
        return '📊';
      case TrophyCategory.time:
        return '⏱️';
      case TrophyCategory.consistency:
        return '🔥';
      case TrophyCategory.personalRecords:
        return '💪';
      case TrophyCategory.social:
        return '👥';
      case TrophyCategory.bodyComposition:
        return '📏';
      case TrophyCategory.nutrition:
        return '🥗';
      case TrophyCategory.fasting:
        return '⏳';
      case TrophyCategory.aiCoach:
        return '🤖';
      case TrophyCategory.special:
        return '✨';
      case TrophyCategory.worldRecord:
        return '🏆';
    }
  }

  IconData get iconData {
    switch (this) {
      case TrophyCategory.exerciseMastery:
        return Icons.fitness_center;
      case TrophyCategory.volume:
        return Icons.bar_chart;
      case TrophyCategory.time:
        return Icons.timer;
      case TrophyCategory.consistency:
        return Icons.local_fire_department;
      case TrophyCategory.personalRecords:
        return Icons.emoji_events;
      case TrophyCategory.social:
        return Icons.people;
      case TrophyCategory.bodyComposition:
        return Icons.straighten;
      case TrophyCategory.nutrition:
        return Icons.restaurant;
      case TrophyCategory.fasting:
        return Icons.hourglass_empty;
      case TrophyCategory.aiCoach:
        return Icons.smart_toy;
      case TrophyCategory.special:
        return Icons.auto_awesome;
      case TrophyCategory.worldRecord:
        return Icons.military_tech;
    }
  }
}

/// Trophy definition (achievement type with extended properties)
@JsonSerializable()
class Trophy {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String tier;
  @JsonKey(name: 'tier_level')
  final int tierLevel;
  final int points;
  @JsonKey(name: 'threshold_value')
  final double? thresholdValue;
  @JsonKey(name: 'threshold_unit')
  final String? thresholdUnit;
  @JsonKey(name: 'xp_reward')
  final int xpReward;
  @JsonKey(name: 'is_secret')
  final bool isSecret;
  @JsonKey(name: 'is_hidden')
  final bool isHidden;
  @JsonKey(name: 'hint_text')
  final String? hintText;
  @JsonKey(name: 'merch_reward')
  final String? merchReward;
  @JsonKey(name: 'unlock_animation')
  final String unlockAnimation;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'parent_achievement_id')
  final String? parentAchievementId;
  @JsonKey(name: 'rarity')
  final String rarity;

  const Trophy({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.tier,
    this.tierLevel = 1,
    required this.points,
    this.thresholdValue,
    this.thresholdUnit,
    this.xpReward = 0,
    this.isSecret = false,
    this.isHidden = false,
    this.hintText,
    this.merchReward,
    this.unlockAnimation = 'standard',
    this.sortOrder = 0,
    this.parentAchievementId,
    this.rarity = 'common',
  });

  factory Trophy.fromJson(Map<String, dynamic> json) => _$TrophyFromJson(json);
  Map<String, dynamic> toJson() => _$TrophyToJson(this);

  /// Get trophy tier enum
  TrophyTier get trophyTier {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return TrophyTier.bronze;
      case 'silver':
        return TrophyTier.silver;
      case 'gold':
        return TrophyTier.gold;
      case 'platinum':
        return TrophyTier.platinum;
      case 'diamond':
        return TrophyTier.diamond;
      default:
        return TrophyTier.bronze;
    }
  }

  /// Get trophy category enum
  TrophyCategory get trophyCategory {
    switch (category.toLowerCase()) {
      case 'exercise_mastery':
        return TrophyCategory.exerciseMastery;
      case 'volume':
        return TrophyCategory.volume;
      case 'time':
        return TrophyCategory.time;
      case 'consistency':
        return TrophyCategory.consistency;
      case 'personal_records':
        return TrophyCategory.personalRecords;
      case 'social':
        return TrophyCategory.social;
      case 'body_composition':
        return TrophyCategory.bodyComposition;
      case 'nutrition':
        return TrophyCategory.nutrition;
      case 'fasting':
        return TrophyCategory.fasting;
      case 'ai_coach':
        return TrophyCategory.aiCoach;
      case 'special':
        return TrophyCategory.special;
      case 'world_record':
        return TrophyCategory.worldRecord;
      default:
        return TrophyCategory.special;
    }
  }

  /// Check if trophy has a physical reward
  bool get hasMerchReward => merchReward != null && merchReward!.isNotEmpty;
}

/// User's earned trophy
@JsonSerializable()
class UserTrophy {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'achievement_id')
  final String achievementId;
  @JsonKey(name: 'earned_at')
  final DateTime earnedAt;
  @JsonKey(name: 'trigger_value')
  final double? triggerValue;
  @JsonKey(name: 'trigger_details')
  final Map<String, dynamic>? triggerDetails;
  @JsonKey(name: 'is_notified')
  final bool isNotified;
  final Trophy? trophy;

  const UserTrophy({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.triggerValue,
    this.triggerDetails,
    this.isNotified = false,
    this.trophy,
  });

  factory UserTrophy.fromJson(Map<String, dynamic> json) =>
      _$UserTrophyFromJson(json);
  Map<String, dynamic> toJson() => _$UserTrophyToJson(this);
}

/// Trophy progress for display
@JsonSerializable()
class TrophyProgress {
  final Trophy trophy;
  @JsonKey(name: 'is_earned')
  final bool isEarned;
  @JsonKey(name: 'earned_at')
  final DateTime? earnedAt;
  @JsonKey(name: 'current_value')
  final double currentValue;
  @JsonKey(name: 'progress_percentage')
  final double progressPercentage;

  const TrophyProgress({
    required this.trophy,
    this.isEarned = false,
    this.earnedAt,
    this.currentValue = 0,
    this.progressPercentage = 0,
  });

  factory TrophyProgress.fromJson(Map<String, dynamic> json) =>
      _$TrophyProgressFromJson(json);
  Map<String, dynamic> toJson() => _$TrophyProgressToJson(this);

  /// Get progress as fraction (0.0 to 1.0)
  double get progressFraction => (progressPercentage / 100).clamp(0.0, 1.0);

  /// Get remaining value to earn
  double get remainingValue {
    final threshold = trophy.thresholdValue ?? 0;
    return (threshold - currentValue).clamp(0, threshold);
  }

  /// Check if trophy is a mystery trophy (hidden or secret, not earned)
  bool get isMystery => !isEarned && (trophy.isHidden || trophy.isSecret);

  /// All trophies are visible - mystery ones show masked info
  bool get isVisible => true;

  /// Get display name (mystery shows "Mystery Trophy")
  String get displayName {
    if (isMystery) return 'Mystery Trophy';
    return trophy.name;
  }

  /// Get display description (mystery shows vague hint)
  String get displayDescription {
    if (isMystery) {
      return trophy.hintText ?? 'A special achievement shrouded in mystery...';
    }
    return trophy.description;
  }

  /// Get display icon (mystery shows ❓)
  String get displayIcon {
    if (isMystery) return '❓';
    return trophy.icon;
  }

  /// Get display XP (mystery hides XP value)
  String get displayXp {
    if (isMystery) return '??? XP';
    return '+${trophy.xpReward} XP';
  }

  /// Get display tier (mystery hides tier)
  String get displayTier {
    if (isMystery) return 'Mystery';
    return trophy.trophyTier.displayName;
  }

  /// Get muscle group from threshold_unit (for filtering)
  String? get muscleGroup {
    final unit = trophy.thresholdUnit?.toLowerCase();
    if (unit == null) return null;
    if (unit.contains('chest')) return 'Chest';
    if (unit.contains('back')) return 'Back';
    if (unit.contains('shoulder') || unit.contains('delt')) return 'Shoulders';
    if (unit.contains('arm') || unit.contains('bicep') || unit.contains('tricep')) return 'Arms';
    if (unit.contains('leg') || unit.contains('quad') || unit.contains('hamstring') || unit.contains('calf') || unit.contains('glute')) return 'Legs';
    if (unit.contains('core') || unit.contains('ab')) return 'Core';
    return null;
  }
}

/// Trophy room summary
@JsonSerializable()
class TrophyRoomSummary {
  @JsonKey(name: 'total_trophies')
  final int totalTrophies;
  @JsonKey(name: 'earned_trophies')
  final int earnedTrophies;
  @JsonKey(name: 'locked_trophies')
  final int lockedTrophies;
  @JsonKey(name: 'secret_discovered')
  final int secretDiscovered;
  @JsonKey(name: 'total_secret')
  final int totalSecret;
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'by_tier')
  final Map<String, int> byTier;
  @JsonKey(name: 'by_category')
  final Map<String, int> byCategory;

  const TrophyRoomSummary({
    this.totalTrophies = 0,
    this.earnedTrophies = 0,
    this.lockedTrophies = 0,
    this.secretDiscovered = 0,
    this.totalSecret = 0,
    this.totalPoints = 0,
    this.byTier = const {},
    this.byCategory = const {},
  });

  factory TrophyRoomSummary.fromJson(Map<String, dynamic> json) =>
      _$TrophyRoomSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$TrophyRoomSummaryToJson(this);

  /// Get completion percentage
  double get completionPercent {
    if (totalTrophies == 0) return 0;
    return (earnedTrophies / totalTrophies * 100);
  }
}

/// World record entry
@JsonSerializable()
class WorldRecord {
  final String id;
  @JsonKey(name: 'record_type')
  final String recordType;
  @JsonKey(name: 'record_category')
  final String recordCategory;
  @JsonKey(name: 'record_name')
  final String recordName;
  @JsonKey(name: 'current_holder_id')
  final String? currentHolderId;
  @JsonKey(name: 'current_holder_name')
  final String? currentHolderName;
  @JsonKey(name: 'record_value')
  final double recordValue;
  @JsonKey(name: 'record_unit')
  final String recordUnit;
  @JsonKey(name: 'achieved_at')
  final DateTime? achievedAt;
  @JsonKey(name: 'previous_record')
  final double? previousRecord;
  @JsonKey(name: 'is_verified')
  final bool isVerified;

  const WorldRecord({
    required this.id,
    required this.recordType,
    required this.recordCategory,
    required this.recordName,
    this.currentHolderId,
    this.currentHolderName,
    required this.recordValue,
    required this.recordUnit,
    this.achievedAt,
    this.previousRecord,
    this.isVerified = false,
  });

  factory WorldRecord.fromJson(Map<String, dynamic> json) =>
      _$WorldRecordFromJson(json);
  Map<String, dynamic> toJson() => _$WorldRecordToJson(this);

  /// Get formatted record value
  String get formattedValue {
    if (recordUnit == 'lbs' || recordUnit == 'kg') {
      return '${recordValue.toStringAsFixed(1)} $recordUnit';
    } else if (recordUnit == 'reps') {
      return '${recordValue.toInt()} reps';
    } else if (recordUnit == 'seconds') {
      final mins = (recordValue / 60).floor();
      final secs = (recordValue % 60).toInt();
      return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    } else if (recordUnit == 'minutes') {
      return '${recordValue.toInt()} min';
    }
    return '${recordValue.toStringAsFixed(1)} $recordUnit';
  }

  /// Check if record has a holder
  bool get hasHolder => currentHolderId != null;
}

/// Former champion badge
@JsonSerializable()
class FormerChampion {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'record_type')
  final String recordType;
  @JsonKey(name: 'record_name')
  final String recordName;
  @JsonKey(name: 'peak_value')
  final double peakValue;
  @JsonKey(name: 'held_from')
  final DateTime heldFrom;
  @JsonKey(name: 'held_until')
  final DateTime heldUntil;
  @JsonKey(name: 'days_held')
  final int daysHeld;

  const FormerChampion({
    required this.id,
    required this.userId,
    required this.recordType,
    required this.recordName,
    required this.peakValue,
    required this.heldFrom,
    required this.heldUntil,
    required this.daysHeld,
  });

  factory FormerChampion.fromJson(Map<String, dynamic> json) =>
      _$FormerChampionFromJson(json);
  Map<String, dynamic> toJson() => _$FormerChampionToJson(this);
}
