/// NEAT achievement models for gamification.
///
/// These models support:
/// - Achievement definitions with tiers
/// - User achievement progress tracking
/// - Various requirement types (steps, streaks, scores)
/// - Achievement celebration and display
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_achievement.g.dart';

/// Tier levels for NEAT achievements
enum NeatAchievementTier {
  @JsonValue('bronze')
  bronze,
  @JsonValue('silver')
  silver,
  @JsonValue('gold')
  gold,
  @JsonValue('platinum')
  platinum,
  @JsonValue('diamond')
  diamond;

  String get displayName {
    switch (this) {
      case NeatAchievementTier.bronze:
        return 'Bronze';
      case NeatAchievementTier.silver:
        return 'Silver';
      case NeatAchievementTier.gold:
        return 'Gold';
      case NeatAchievementTier.platinum:
        return 'Platinum';
      case NeatAchievementTier.diamond:
        return 'Diamond';
    }
  }

  int get colorValue {
    switch (this) {
      case NeatAchievementTier.bronze:
        return 0xFFCD7F32; // Bronze
      case NeatAchievementTier.silver:
        return 0xFFC0C0C0; // Silver
      case NeatAchievementTier.gold:
        return 0xFFFFD700; // Gold
      case NeatAchievementTier.platinum:
        return 0xFFE5E4E2; // Platinum
      case NeatAchievementTier.diamond:
        return 0xFF00BFFF; // Diamond blue
    }
  }

  int get sortOrder {
    switch (this) {
      case NeatAchievementTier.bronze:
        return 0;
      case NeatAchievementTier.silver:
        return 1;
      case NeatAchievementTier.gold:
        return 2;
      case NeatAchievementTier.platinum:
        return 3;
      case NeatAchievementTier.diamond:
        return 4;
    }
  }
}

/// Types of requirements for earning achievements
enum NeatAchievementRequirementType {
  @JsonValue('total_steps')
  totalSteps,
  @JsonValue('daily_steps')
  dailySteps,
  @JsonValue('step_streak')
  stepStreak,
  @JsonValue('active_hours_streak')
  activeHoursStreak,
  @JsonValue('neat_score_streak')
  neatScoreStreak,
  @JsonValue('average_neat_score')
  averageNeatScore,
  @JsonValue('total_active_hours')
  totalActiveHours,
  @JsonValue('goal_achievements')
  goalAchievements,
  @JsonValue('distance_km')
  distanceKm,
  @JsonValue('perfect_weeks')
  perfectWeeks;

  String get displayName {
    switch (this) {
      case NeatAchievementRequirementType.totalSteps:
        return 'Total Steps';
      case NeatAchievementRequirementType.dailySteps:
        return 'Daily Steps';
      case NeatAchievementRequirementType.stepStreak:
        return 'Step Streak';
      case NeatAchievementRequirementType.activeHoursStreak:
        return 'Active Hours Streak';
      case NeatAchievementRequirementType.neatScoreStreak:
        return 'NEAT Score Streak';
      case NeatAchievementRequirementType.averageNeatScore:
        return 'Average NEAT Score';
      case NeatAchievementRequirementType.totalActiveHours:
        return 'Total Active Hours';
      case NeatAchievementRequirementType.goalAchievements:
        return 'Goals Achieved';
      case NeatAchievementRequirementType.distanceKm:
        return 'Distance Walked';
      case NeatAchievementRequirementType.perfectWeeks:
        return 'Perfect Weeks';
    }
  }

  String get unit {
    switch (this) {
      case NeatAchievementRequirementType.totalSteps:
      case NeatAchievementRequirementType.dailySteps:
        return 'steps';
      case NeatAchievementRequirementType.stepStreak:
      case NeatAchievementRequirementType.activeHoursStreak:
      case NeatAchievementRequirementType.neatScoreStreak:
      case NeatAchievementRequirementType.goalAchievements:
        return 'days';
      case NeatAchievementRequirementType.averageNeatScore:
        return 'score';
      case NeatAchievementRequirementType.totalActiveHours:
        return 'hours';
      case NeatAchievementRequirementType.distanceKm:
        return 'km';
      case NeatAchievementRequirementType.perfectWeeks:
        return 'weeks';
    }
  }
}

/// Definition of a NEAT achievement
@JsonSerializable()
class NeatAchievement {
  final String id;

  final String name;

  final String? description;

  final String? icon;

  @JsonKey(name: 'requirement_type')
  final NeatAchievementRequirementType requirementType;

  @JsonKey(name: 'requirement_value')
  final double requirementValue;

  final NeatAchievementTier tier;

  final int points;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @JsonKey(name: 'share_message')
  final String? shareMessage;

  const NeatAchievement({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.requirementType,
    required this.requirementValue,
    this.tier = NeatAchievementTier.bronze,
    this.points = 10,
    this.isActive = true,
    this.sortOrder = 0,
    this.shareMessage,
  });

  factory NeatAchievement.fromJson(Map<String, dynamic> json) =>
      _$NeatAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$NeatAchievementToJson(this);

  /// Formatted requirement text
  String get requirementText {
    final formattedValue = requirementValue >= 1000
        ? '${(requirementValue / 1000).toStringAsFixed(requirementValue % 1000 == 0 ? 0 : 1)}k'
        : requirementValue.toStringAsFixed(requirementValue % 1 == 0 ? 0 : 1);
    return '$formattedValue ${requirementType.unit}';
  }
}

/// A user's progress toward or achievement of a NEAT achievement
@JsonSerializable()
class UserNeatAchievement {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  final NeatAchievement achievement;

  @JsonKey(name: 'achieved_at')
  final DateTime? achievedAt;

  @JsonKey(name: 'current_progress')
  final double currentProgress;

  @JsonKey(name: 'is_notified')
  final bool isNotified;

  @JsonKey(name: 'is_celebrated')
  final bool isCelebrated;

  @JsonKey(name: 'shared_at')
  final DateTime? sharedAt;

  const UserNeatAchievement({
    this.id,
    required this.userId,
    required this.achievement,
    this.achievedAt,
    this.currentProgress = 0.0,
    this.isNotified = false,
    this.isCelebrated = false,
    this.sharedAt,
  });

  factory UserNeatAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserNeatAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$UserNeatAchievementToJson(this);

  /// Whether the achievement has been earned
  bool get isAchieved => achievedAt != null;

  /// Progress as a fraction (0.0 to 1.0)
  double get progressFraction {
    if (achievement.requirementValue <= 0) return 0.0;
    return (currentProgress / achievement.requirementValue).clamp(0.0, 1.0);
  }

  /// Progress as a percentage (0 to 100)
  double get progressPercentage => progressFraction * 100;

  /// Remaining amount to achieve
  double get remaining {
    final rem = achievement.requirementValue - currentProgress;
    return rem > 0 ? rem : 0;
  }

  /// Create a copy with updated values
  UserNeatAchievement copyWith({
    String? id,
    String? userId,
    NeatAchievement? achievement,
    DateTime? achievedAt,
    double? currentProgress,
    bool? isNotified,
    bool? isCelebrated,
    DateTime? sharedAt,
  }) {
    return UserNeatAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievement: achievement ?? this.achievement,
      achievedAt: achievedAt ?? this.achievedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      isNotified: isNotified ?? this.isNotified,
      isCelebrated: isCelebrated ?? this.isCelebrated,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}

/// Summary of NEAT achievements for a user
@JsonSerializable()
class NeatAchievementsSummary {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'earned_achievements')
  final List<UserNeatAchievement> earnedAchievements;

  @JsonKey(name: 'upcoming_achievements')
  final List<UserNeatAchievement> upcomingAchievements;

  @JsonKey(name: 'total_points')
  final int totalPoints;

  @JsonKey(name: 'total_earned')
  final int totalEarned;

  @JsonKey(name: 'total_available')
  final int totalAvailable;

  @JsonKey(name: 'recent_achievement')
  final UserNeatAchievement? recentAchievement;

  @JsonKey(name: 'next_achievement')
  final UserNeatAchievement? nextAchievement;

  const NeatAchievementsSummary({
    required this.userId,
    this.earnedAchievements = const [],
    this.upcomingAchievements = const [],
    this.totalPoints = 0,
    this.totalEarned = 0,
    this.totalAvailable = 0,
    this.recentAchievement,
    this.nextAchievement,
  });

  factory NeatAchievementsSummary.fromJson(Map<String, dynamic> json) =>
      _$NeatAchievementsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$NeatAchievementsSummaryToJson(this);

  /// Completion percentage
  double get completionPercentage {
    if (totalAvailable == 0) return 0.0;
    return (totalEarned / totalAvailable) * 100;
  }

  /// Achievements by tier
  Map<NeatAchievementTier, List<UserNeatAchievement>> get earnedByTier {
    final Map<NeatAchievementTier, List<UserNeatAchievement>> result = {};
    for (final achievement in earnedAchievements) {
      final tier = achievement.achievement.tier;
      result.putIfAbsent(tier, () => []).add(achievement);
    }
    return result;
  }

  /// Count of earned achievements by tier
  Map<NeatAchievementTier, int> get earnedCountByTier {
    return earnedByTier.map((tier, achievements) =>
        MapEntry(tier, achievements.length));
  }
}

/// Newly earned achievement notification
@JsonSerializable()
class NewNeatAchievement {
  final NeatAchievement achievement;

  @JsonKey(name: 'achieved_at')
  final DateTime achievedAt;

  @JsonKey(name: 'trigger_value')
  final double? triggerValue;

  const NewNeatAchievement({
    required this.achievement,
    required this.achievedAt,
    this.triggerValue,
  });

  factory NewNeatAchievement.fromJson(Map<String, dynamic> json) =>
      _$NewNeatAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$NewNeatAchievementToJson(this);
}
