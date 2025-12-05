// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInsight _$UserInsightFromJson(Map<String, dynamic> json) => UserInsight(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  insightType: json['insight_type'] as String?,
  message: json['message'] as String?,
  emoji: json['emoji'] as String?,
  priority: (json['priority'] as num?)?.toInt(),
  isActive: json['is_active'] as bool?,
  generatedAt: json['generated_at'] as String?,
);

Map<String, dynamic> _$UserInsightToJson(UserInsight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'insight_type': instance.insightType,
      'message': instance.message,
      'emoji': instance.emoji,
      'priority': instance.priority,
      'is_active': instance.isActive,
      'generated_at': instance.generatedAt,
    };

WeeklyProgress _$WeeklyProgressFromJson(Map<String, dynamic> json) =>
    WeeklyProgress(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      weekStartDate: json['week_start_date'] as String?,
      year: (json['year'] as num?)?.toInt(),
      weekNumber: (json['week_number'] as num?)?.toInt(),
      plannedWorkouts: (json['planned_workouts'] as num?)?.toInt(),
      completedWorkouts: (json['completed_workouts'] as num?)?.toInt(),
      totalDurationMinutes: (json['total_duration_minutes'] as num?)?.toInt(),
      totalCaloriesBurned: (json['total_calories_burned'] as num?)?.toInt(),
      targetWorkouts: (json['target_workouts'] as num?)?.toInt(),
      goalsMet: json['goals_met'] as bool?,
    );

Map<String, dynamic> _$WeeklyProgressToJson(WeeklyProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start_date': instance.weekStartDate,
      'year': instance.year,
      'week_number': instance.weekNumber,
      'planned_workouts': instance.plannedWorkouts,
      'completed_workouts': instance.completedWorkouts,
      'total_duration_minutes': instance.totalDurationMinutes,
      'total_calories_burned': instance.totalCaloriesBurned,
      'target_workouts': instance.targetWorkouts,
      'goals_met': instance.goalsMet,
    };

InsightsResponse _$InsightsResponseFromJson(Map<String, dynamic> json) =>
    InsightsResponse(
      insights:
          (json['insights'] as List<dynamic>?)
              ?.map((e) => UserInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      weeklyProgress: json['weekly_progress'] == null
          ? null
          : WeeklyProgress.fromJson(
              json['weekly_progress'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$InsightsResponseToJson(InsightsResponse instance) =>
    <String, dynamic>{
      'insights': instance.insights,
      'weekly_progress': instance.weeklyProgress,
    };

GenerateInsightsResponse _$GenerateInsightsResponseFromJson(
  Map<String, dynamic> json,
) => GenerateInsightsResponse(
  message: json['message'] as String,
  generated: json['generated'] as bool?,
  insightsCount: (json['insights_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$GenerateInsightsResponseToJson(
  GenerateInsightsResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'generated': instance.generated,
  'insights_count': instance.insightsCount,
};
