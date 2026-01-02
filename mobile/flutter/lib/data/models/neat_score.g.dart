// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatDailyScore _$NeatDailyScoreFromJson(Map<String, dynamic> json) =>
    NeatDailyScore(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      scoreDate: json['score_date'] as String,
      neatScore: (json['neat_score'] as num?)?.toDouble() ?? 0.0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      activeHours: (json['active_hours'] as num?)?.toInt() ?? 0,
      sedentaryHours: (json['sedentary_hours'] as num?)?.toInt() ?? 0,
      stepGoalAchieved: json['step_goal_achieved'] as bool? ?? false,
      goalAtTime: (json['goal_at_time'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$NeatDailyScoreToJson(NeatDailyScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'score_date': instance.scoreDate,
      'neat_score': instance.neatScore,
      'total_steps': instance.totalSteps,
      'active_hours': instance.activeHours,
      'sedentary_hours': instance.sedentaryHours,
      'step_goal_achieved': instance.stepGoalAchieved,
      'goal_at_time': instance.goalAtTime,
      'distance_km': instance.distanceKm,
      'calories_burned': instance.caloriesBurned,
      'created_at': instance.createdAt?.toIso8601String(),
    };

NeatScoreTrend _$NeatScoreTrendFromJson(Map<String, dynamic> json) =>
    NeatScoreTrend(
      userId: json['user_id'] as String,
      dailyScores:
          (json['daily_scores'] as List<dynamic>?)
              ?.map((e) => NeatDailyScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      trendDirection:
          $enumDecodeNullable(
            _$NeatScoreTrendDirectionEnumMap,
            json['trend_direction'],
          ) ??
          NeatScoreTrendDirection.stable,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      averageSteps: (json['average_steps'] as num?)?.toDouble() ?? 0.0,
      averageActiveHours:
          (json['average_active_hours'] as num?)?.toDouble() ?? 0.0,
      goalAchievementRate:
          (json['goal_achievement_rate'] as num?)?.toDouble() ?? 0.0,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      trendPercentage: (json['trend_percentage'] as num?)?.toDouble(),
      insight: json['insight'] as String?,
    );

Map<String, dynamic> _$NeatScoreTrendToJson(
  NeatScoreTrend instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'daily_scores': instance.dailyScores,
  'trend_direction': _$NeatScoreTrendDirectionEnumMap[instance.trendDirection]!,
  'average_score': instance.averageScore,
  'average_steps': instance.averageSteps,
  'average_active_hours': instance.averageActiveHours,
  'goal_achievement_rate': instance.goalAchievementRate,
  'period_start': instance.periodStart,
  'period_end': instance.periodEnd,
  'trend_percentage': instance.trendPercentage,
  'insight': instance.insight,
};

const _$NeatScoreTrendDirectionEnumMap = {
  NeatScoreTrendDirection.improving: 'improving',
  NeatScoreTrendDirection.stable: 'stable',
  NeatScoreTrendDirection.declining: 'declining',
};

WeeklyNeatSummary _$WeeklyNeatSummaryFromJson(Map<String, dynamic> json) =>
    WeeklyNeatSummary(
      weekStart: json['week_start'] as String,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      averageSteps: (json['average_steps'] as num?)?.toDouble() ?? 0.0,
      daysTracked: (json['days_tracked'] as num?)?.toInt() ?? 0,
      daysGoalAchieved: (json['days_goal_achieved'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WeeklyNeatSummaryToJson(WeeklyNeatSummary instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'average_score': instance.averageScore,
      'average_steps': instance.averageSteps,
      'days_tracked': instance.daysTracked,
      'days_goal_achieved': instance.daysGoalAchieved,
    };
