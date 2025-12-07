// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AchievementType _$AchievementTypeFromJson(Map<String, dynamic> json) =>
    AchievementType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      tier: json['tier'] as String,
      points: (json['points'] as num).toInt(),
      thresholdValue: (json['threshold_value'] as num?)?.toDouble(),
      thresholdUnit: json['threshold_unit'] as String?,
      isRepeatable: json['is_repeatable'] as bool? ?? false,
    );

Map<String, dynamic> _$AchievementTypeToJson(AchievementType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'icon': instance.icon,
      'tier': instance.tier,
      'points': instance.points,
      'threshold_value': instance.thresholdValue,
      'threshold_unit': instance.thresholdUnit,
      'is_repeatable': instance.isRepeatable,
    };

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      triggerValue: (json['trigger_value'] as num?)?.toDouble(),
      triggerDetails: json['trigger_details'] as Map<String, dynamic>?,
      isNotified: json['is_notified'] as bool? ?? false,
      achievement: json['achievement'] == null
          ? null
          : AchievementType.fromJson(
              json['achievement'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'achievement_id': instance.achievementId,
      'earned_at': instance.earnedAt.toIso8601String(),
      'trigger_value': instance.triggerValue,
      'trigger_details': instance.triggerDetails,
      'is_notified': instance.isNotified,
      'achievement': instance.achievement,
    };

UserStreak _$UserStreakFromJson(Map<String, dynamic> json) => UserStreak(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  streakType: json['streak_type'] as String,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  lastActivityDate: json['last_activity_date'] as String?,
  streakStartDate: json['streak_start_date'] as String?,
);

Map<String, dynamic> _$UserStreakToJson(UserStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'streak_type': instance.streakType,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'last_activity_date': instance.lastActivityDate,
      'streak_start_date': instance.streakStartDate,
    };

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseName: json['exercise_name'] as String,
      recordType: json['record_type'] as String,
      recordValue: (json['record_value'] as num).toDouble(),
      recordUnit: json['record_unit'] as String,
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      improvementPercentage: (json['improvement_percentage'] as num?)
          ?.toDouble(),
      workoutId: json['workout_id'] as String?,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'exercise_name': instance.exerciseName,
      'record_type': instance.recordType,
      'record_value': instance.recordValue,
      'record_unit': instance.recordUnit,
      'previous_value': instance.previousValue,
      'improvement_percentage': instance.improvementPercentage,
      'workout_id': instance.workoutId,
      'achieved_at': instance.achievedAt.toIso8601String(),
    };

AchievementsSummary _$AchievementsSummaryFromJson(Map<String, dynamic> json) =>
    AchievementsSummary(
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      totalAchievements: (json['total_achievements'] as num?)?.toInt() ?? 0,
      recentAchievements:
          (json['recent_achievements'] as List<dynamic>?)
              ?.map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentStreaks:
          (json['current_streaks'] as List<dynamic>?)
              ?.map((e) => UserStreak.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      personalRecords:
          (json['personal_records'] as List<dynamic>?)
              ?.map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      achievementsByCategory:
          (json['achievements_by_category'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$AchievementsSummaryToJson(
  AchievementsSummary instance,
) => <String, dynamic>{
  'total_points': instance.totalPoints,
  'total_achievements': instance.totalAchievements,
  'recent_achievements': instance.recentAchievements,
  'current_streaks': instance.currentStreaks,
  'personal_records': instance.personalRecords,
  'achievements_by_category': instance.achievementsByCategory,
};
