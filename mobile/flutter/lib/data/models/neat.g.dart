// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatGoal _$NeatGoalFromJson(Map<String, dynamic> json) => NeatGoal(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  goalType: json['goal_type'] as String,
  targetValue: (json['target_value'] as num).toInt(),
  currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
  unit: json['unit'] as String,
  isProgressive: json['is_progressive'] as bool? ?? false,
  baselineValue: (json['baseline_value'] as num?)?.toInt(),
  incrementValue: (json['increment_value'] as num?)?.toInt(),
  incrementFrequencyDays: (json['increment_frequency_days'] as num?)?.toInt(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$NeatGoalToJson(NeatGoal instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'goal_type': instance.goalType,
  'target_value': instance.targetValue,
  'current_value': instance.currentValue,
  'unit': instance.unit,
  'is_progressive': instance.isProgressive,
  'baseline_value': instance.baselineValue,
  'increment_value': instance.incrementValue,
  'increment_frequency_days': instance.incrementFrequencyDays,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

HourlyActivity _$HourlyActivityFromJson(Map<String, dynamic> json) =>
    HourlyActivity(
      hour: (json['hour'] as num).toInt(),
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      activeMinutes: (json['active_minutes'] as num?)?.toInt() ?? 0,
      standing: json['standing'] as bool? ?? false,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0.0,
      movementType: json['movement_type'] as String?,
    );

Map<String, dynamic> _$HourlyActivityToJson(HourlyActivity instance) =>
    <String, dynamic>{
      'hour': instance.hour,
      'steps': instance.steps,
      'active_minutes': instance.activeMinutes,
      'standing': instance.standing,
      'calories_burned': instance.caloriesBurned,
      'movement_type': instance.movementType,
    };

NeatHourlyBreakdown _$NeatHourlyBreakdownFromJson(Map<String, dynamic> json) =>
    NeatHourlyBreakdown(
      userId: json['user_id'] as String,
      date: json['date'] as String,
      hourlyData:
          (json['hourly_data'] as List<dynamic>?)
              ?.map((e) => HourlyActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (json['total_active_minutes'] as num?)?.toInt() ?? 0,
      totalStandingHours: (json['total_standing_hours'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      peakHour: (json['peak_hour'] as num?)?.toInt(),
      leastActiveHour: (json['least_active_hour'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NeatHourlyBreakdownToJson(
  NeatHourlyBreakdown instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'date': instance.date,
  'hourly_data': instance.hourlyData,
  'total_steps': instance.totalSteps,
  'total_active_minutes': instance.totalActiveMinutes,
  'total_standing_hours': instance.totalStandingHours,
  'total_calories': instance.totalCalories,
  'peak_hour': instance.peakHour,
  'least_active_hour': instance.leastActiveHour,
};

NeatDailyScore _$NeatDailyScoreFromJson(Map<String, dynamic> json) =>
    NeatDailyScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      maxScore: (json['max_score'] as num?)?.toInt() ?? 100,
      stepsScore: (json['steps_score'] as num?)?.toInt() ?? 0,
      activeMinutesScore: (json['active_minutes_score'] as num?)?.toInt() ?? 0,
      standingHoursScore: (json['standing_hours_score'] as num?)?.toInt() ?? 0,
      consistencyBonus: (json['consistency_bonus'] as num?)?.toInt() ?? 0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (json['total_active_minutes'] as num?)?.toInt() ?? 0,
      totalStandingHours: (json['total_standing_hours'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      goalsAchieved: (json['goals_achieved'] as num?)?.toInt() ?? 0,
      totalGoals: (json['total_goals'] as num?)?.toInt() ?? 0,
      calculatedAt: json['calculated_at'] as String?,
    );

Map<String, dynamic> _$NeatDailyScoreToJson(NeatDailyScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': instance.date,
      'score': instance.score,
      'max_score': instance.maxScore,
      'steps_score': instance.stepsScore,
      'active_minutes_score': instance.activeMinutesScore,
      'standing_hours_score': instance.standingHoursScore,
      'consistency_bonus': instance.consistencyBonus,
      'total_steps': instance.totalSteps,
      'total_active_minutes': instance.totalActiveMinutes,
      'total_standing_hours': instance.totalStandingHours,
      'total_calories': instance.totalCalories,
      'goals_achieved': instance.goalsAchieved,
      'total_goals': instance.totalGoals,
      'calculated_at': instance.calculatedAt,
    };

NeatStreak _$NeatStreakFromJson(Map<String, dynamic> json) => NeatStreak(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  streakType: json['streak_type'] as String,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? false,
  startedAt: json['started_at'] as String?,
  lastActivityDate: json['last_activity_date'] as String?,
);

Map<String, dynamic> _$NeatStreakToJson(NeatStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'streak_type': instance.streakType,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'is_active': instance.isActive,
      'started_at': instance.startedAt,
      'last_activity_date': instance.lastActivityDate,
    };

UserNeatAchievement _$UserNeatAchievementFromJson(Map<String, dynamic> json) =>
    UserNeatAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      iconName: json['icon_name'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      requirementType: json['requirement_type'] as String,
      requirementValue: (json['requirement_value'] as num).toInt(),
      currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
      isEarned: json['is_earned'] as bool? ?? false,
      earnedAt: json['earned_at'] as String?,
      isCelebrated: json['is_celebrated'] as bool? ?? false,
    );

Map<String, dynamic> _$UserNeatAchievementToJson(
  UserNeatAchievement instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'icon_name': instance.iconName,
  'points': instance.points,
  'requirement_type': instance.requirementType,
  'requirement_value': instance.requirementValue,
  'current_progress': instance.currentProgress,
  'is_earned': instance.isEarned,
  'earned_at': instance.earnedAt,
  'is_celebrated': instance.isCelebrated,
};

NeatReminderPreferences _$NeatReminderPreferencesFromJson(
  Map<String, dynamic> json,
) => NeatReminderPreferences(
  userId: json['user_id'] as String,
  remindersEnabled: json['reminders_enabled'] as bool? ?? true,
  hourlyMovementEnabled: json['hourly_movement_enabled'] as bool? ?? true,
  hourlyStartTime: json['hourly_start_time'] as String? ?? '09:00',
  hourlyEndTime: json['hourly_end_time'] as String? ?? '21:00',
  stepMilestoneEnabled: json['step_milestone_enabled'] as bool? ?? true,
  stepMilestones:
      (json['step_milestones'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [2500, 5000, 7500, 10000],
  goalReminderEnabled: json['goal_reminder_enabled'] as bool? ?? true,
  goalReminderTime: json['goal_reminder_time'] as String?,
  inactivityReminderEnabled:
      json['inactivity_reminder_enabled'] as bool? ?? false,
  inactivityThresholdMinutes:
      (json['inactivity_threshold_minutes'] as num?)?.toInt() ?? 60,
  quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
  quietHoursStart: json['quiet_hours_start'] as String?,
  quietHoursEnd: json['quiet_hours_end'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$NeatReminderPreferencesToJson(
  NeatReminderPreferences instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'reminders_enabled': instance.remindersEnabled,
  'hourly_movement_enabled': instance.hourlyMovementEnabled,
  'hourly_start_time': instance.hourlyStartTime,
  'hourly_end_time': instance.hourlyEndTime,
  'step_milestone_enabled': instance.stepMilestoneEnabled,
  'step_milestones': instance.stepMilestones,
  'goal_reminder_enabled': instance.goalReminderEnabled,
  'goal_reminder_time': instance.goalReminderTime,
  'inactivity_reminder_enabled': instance.inactivityReminderEnabled,
  'inactivity_threshold_minutes': instance.inactivityThresholdMinutes,
  'quiet_hours_enabled': instance.quietHoursEnabled,
  'quiet_hours_start': instance.quietHoursStart,
  'quiet_hours_end': instance.quietHoursEnd,
  'updated_at': instance.updatedAt,
};

NeatDashboard _$NeatDashboardFromJson(
  Map<String, dynamic> json,
) => NeatDashboard(
  userId: json['user_id'] as String,
  todayScore: json['today_score'] == null
      ? null
      : NeatDailyScore.fromJson(json['today_score'] as Map<String, dynamic>),
  currentGoals:
      (json['current_goals'] as List<dynamic>?)
          ?.map((e) => NeatGoal.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hourlyBreakdown: json['hourly_breakdown'] == null
      ? null
      : NeatHourlyBreakdown.fromJson(
          json['hourly_breakdown'] as Map<String, dynamic>,
        ),
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
  weeklySummary: json['weekly_summary'] == null
      ? null
      : NeatWeeklySummary.fromJson(
          json['weekly_summary'] as Map<String, dynamic>,
        ),
  suggestions:
      (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  calculatedAt: json['calculated_at'] as String?,
);

Map<String, dynamic> _$NeatDashboardToJson(NeatDashboard instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'today_score': instance.todayScore,
      'current_goals': instance.currentGoals,
      'hourly_breakdown': instance.hourlyBreakdown,
      'streaks': instance.streaks,
      'recent_achievements': instance.recentAchievements,
      'weekly_summary': instance.weeklySummary,
      'suggestions': instance.suggestions,
      'calculated_at': instance.calculatedAt,
    };

NeatWeeklySummary _$NeatWeeklySummaryFromJson(Map<String, dynamic> json) =>
    NeatWeeklySummary(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      averageDailySteps: (json['average_daily_steps'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (json['total_active_minutes'] as num?)?.toInt() ?? 0,
      totalStandingHours: (json['total_standing_hours'] as num?)?.toInt() ?? 0,
      goalsAchievedDays: (json['goals_achieved_days'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 7,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      bestDay: json['best_day'] as String?,
      bestDaySteps: (json['best_day_steps'] as num?)?.toInt() ?? 0,
      trend: json['trend'] as String? ?? 'stable',
      trendPercentage: (json['trend_percentage'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$NeatWeeklySummaryToJson(NeatWeeklySummary instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'total_steps': instance.totalSteps,
      'average_daily_steps': instance.averageDailySteps,
      'total_active_minutes': instance.totalActiveMinutes,
      'total_standing_hours': instance.totalStandingHours,
      'goals_achieved_days': instance.goalsAchievedDays,
      'total_days': instance.totalDays,
      'average_score': instance.averageScore,
      'best_day': instance.bestDay,
      'best_day_steps': instance.bestDaySteps,
      'trend': instance.trend,
      'trend_percentage': instance.trendPercentage,
    };
