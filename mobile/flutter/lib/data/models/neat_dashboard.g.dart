// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatDashboard _$NeatDashboardFromJson(
  Map<String, dynamic> json,
) => NeatDashboard(
  userId: json['user_id'] as String,
  goal: json['goal'] == null
      ? null
      : NeatGoal.fromJson(json['goal'] as Map<String, dynamic>),
  todayScore: json['today_score'] == null
      ? null
      : NeatDailyScore.fromJson(json['today_score'] as Map<String, dynamic>),
  streaks:
      (json['streaks'] as List<dynamic>?)
          ?.map((e) => NeatStreak.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  recentAchievements:
      (json['recent_achievements'] as List<dynamic>?)
          ?.map((e) => UserNeatAchievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hourlyBreakdown: json['hourly_breakdown'] == null
      ? null
      : NeatHourlyBreakdown.fromJson(
          json['hourly_breakdown'] as Map<String, dynamic>,
        ),
  weeklyTrend: json['weekly_trend'] == null
      ? null
      : NeatScoreTrend.fromJson(json['weekly_trend'] as Map<String, dynamic>),
  insight: json['insight'] as String?,
  recommendation: json['recommendation'] as String?,
  lastUpdated: json['last_updated'] == null
      ? null
      : DateTime.parse(json['last_updated'] as String),
);

Map<String, dynamic> _$NeatDashboardToJson(NeatDashboard instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'goal': instance.goal,
      'today_score': instance.todayScore,
      'streaks': instance.streaks,
      'recent_achievements': instance.recentAchievements,
      'hourly_breakdown': instance.hourlyBreakdown,
      'weekly_trend': instance.weeklyTrend,
      'insight': instance.insight,
      'recommendation': instance.recommendation,
      'last_updated': instance.lastUpdated?.toIso8601String(),
    };

NeatQuickStats _$NeatQuickStatsFromJson(Map<String, dynamic> json) =>
    NeatQuickStats(
      stepsToday: (json['steps_today'] as num?)?.toInt() ?? 0,
      stepGoal: (json['step_goal'] as num?)?.toInt() ?? 10000,
      neatScore: (json['neat_score'] as num?)?.toDouble() ?? 0.0,
      activeHours: (json['active_hours'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      totalAchievements: (json['total_achievements'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NeatQuickStatsToJson(NeatQuickStats instance) =>
    <String, dynamic>{
      'steps_today': instance.stepsToday,
      'step_goal': instance.stepGoal,
      'neat_score': instance.neatScore,
      'active_hours': instance.activeHours,
      'best_streak': instance.bestStreak,
      'total_achievements': instance.totalAchievements,
    };

NeatInsights _$NeatInsightsFromJson(Map<String, dynamic> json) => NeatInsights(
  userId: json['user_id'] as String,
  mostActiveDay: json['most_active_day'] as String?,
  leastActiveDay: json['least_active_day'] as String?,
  mostActiveHour: (json['most_active_hour'] as num?)?.toInt(),
  averageDailySteps: (json['average_daily_steps'] as num?)?.toDouble() ?? 0.0,
  averageNeatScore: (json['average_neat_score'] as num?)?.toDouble() ?? 0.0,
  goalAchievementRate:
      (json['goal_achievement_rate'] as num?)?.toDouble() ?? 0.0,
  sedentaryPercentage:
      (json['sedentary_percentage'] as num?)?.toDouble() ?? 0.0,
  recommendations:
      (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  improvementAreas:
      (json['improvement_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$NeatInsightsToJson(NeatInsights instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'most_active_day': instance.mostActiveDay,
      'least_active_day': instance.leastActiveDay,
      'most_active_hour': instance.mostActiveHour,
      'average_daily_steps': instance.averageDailySteps,
      'average_neat_score': instance.averageNeatScore,
      'goal_achievement_rate': instance.goalAchievementRate,
      'sedentary_percentage': instance.sedentaryPercentage,
      'recommendations': instance.recommendations,
      'achievements': instance.achievements,
      'improvement_areas': instance.improvementAreas,
    };

NeatSyncStatus _$NeatSyncStatusFromJson(Map<String, dynamic> json) =>
    NeatSyncStatus(
      healthKitConnected: json['health_kit_connected'] as bool? ?? false,
      googleFitConnected: json['google_fit_connected'] as bool? ?? false,
      lastSync: json['last_sync'] == null
          ? null
          : DateTime.parse(json['last_sync'] as String),
      syncError: json['sync_error'] as String?,
      stepsSource: json['steps_source'] as String?,
    );

Map<String, dynamic> _$NeatSyncStatusToJson(NeatSyncStatus instance) =>
    <String, dynamic>{
      'health_kit_connected': instance.healthKitConnected,
      'google_fit_connected': instance.googleFitConnected,
      'last_sync': instance.lastSync?.toIso8601String(),
      'sync_error': instance.syncError,
      'steps_source': instance.stepsSource,
    };
