import 'package:json_annotation/json_annotation.dart';

part 'achievement.g.dart';

/// Achievement type definition
@JsonSerializable()
class AchievementType {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String tier;
  final int points;
  @JsonKey(name: 'threshold_value')
  final double? thresholdValue;
  @JsonKey(name: 'threshold_unit')
  final String? thresholdUnit;
  @JsonKey(name: 'is_repeatable')
  final bool isRepeatable;

  const AchievementType({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.tier,
    required this.points,
    this.thresholdValue,
    this.thresholdUnit,
    this.isRepeatable = false,
  });

  factory AchievementType.fromJson(Map<String, dynamic> json) =>
      _$AchievementTypeFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementTypeToJson(this);
}

/// User's earned achievement
@JsonSerializable()
class UserAchievement {
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
  final AchievementType? achievement;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.triggerValue,
    this.triggerDetails,
    this.isNotified = false,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);
  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);
}

/// User streak tracking
@JsonSerializable()
class UserStreak {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'streak_type')
  final String streakType;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'last_activity_date')
  final String? lastActivityDate;
  @JsonKey(name: 'streak_start_date')
  final String? streakStartDate;

  const UserStreak({
    required this.id,
    required this.userId,
    required this.streakType,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.streakStartDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) =>
      _$UserStreakFromJson(json);
  Map<String, dynamic> toJson() => _$UserStreakToJson(this);
}

/// Personal record
@JsonSerializable()
class PersonalRecord {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'record_type')
  final String recordType;
  @JsonKey(name: 'record_value')
  final double recordValue;
  @JsonKey(name: 'record_unit')
  final String recordUnit;
  @JsonKey(name: 'previous_value')
  final double? previousValue;
  @JsonKey(name: 'improvement_percentage')
  final double? improvementPercentage;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'achieved_at')
  final DateTime achievedAt;

  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.recordType,
    required this.recordValue,
    required this.recordUnit,
    this.previousValue,
    this.improvementPercentage,
    this.workoutId,
    required this.achievedAt,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);
}

/// Achievements summary
@JsonSerializable()
class AchievementsSummary {
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'total_achievements')
  final int totalAchievements;
  @JsonKey(name: 'recent_achievements')
  final List<UserAchievement> recentAchievements;
  @JsonKey(name: 'current_streaks')
  final List<UserStreak> currentStreaks;
  @JsonKey(name: 'personal_records')
  final List<PersonalRecord> personalRecords;
  @JsonKey(name: 'achievements_by_category')
  final Map<String, int> achievementsByCategory;

  const AchievementsSummary({
    this.totalPoints = 0,
    this.totalAchievements = 0,
    this.recentAchievements = const [],
    this.currentStreaks = const [],
    this.personalRecords = const [],
    this.achievementsByCategory = const {},
  });

  factory AchievementsSummary.fromJson(Map<String, dynamic> json) =>
      _$AchievementsSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementsSummaryToJson(this);
}
