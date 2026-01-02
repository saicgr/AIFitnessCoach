// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consistency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayPattern _$DayPatternFromJson(Map<String, dynamic> json) => DayPattern(
  dayOfWeek: (json['day_of_week'] as num).toInt(),
  dayName: json['day_name'] as String,
  totalCompletions: (json['total_completions'] as num?)?.toInt() ?? 0,
  totalSkips: (json['total_skips'] as num?)?.toInt() ?? 0,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
  isBestDay: json['is_best_day'] as bool? ?? false,
  isWorstDay: json['is_worst_day'] as bool? ?? false,
);

Map<String, dynamic> _$DayPatternToJson(DayPattern instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'day_name': instance.dayName,
      'total_completions': instance.totalCompletions,
      'total_skips': instance.totalSkips,
      'completion_rate': instance.completionRate,
      'is_best_day': instance.isBestDay,
      'is_worst_day': instance.isWorstDay,
    };

TimeOfDayPattern _$TimeOfDayPatternFromJson(Map<String, dynamic> json) =>
    TimeOfDayPattern(
      timeOfDay: json['time_of_day'] as String,
      displayName: json['display_name'] as String,
      totalCompletions: (json['total_completions'] as num?)?.toInt() ?? 0,
      totalSkips: (json['total_skips'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      isPreferred: json['is_preferred'] as bool? ?? false,
    );

Map<String, dynamic> _$TimeOfDayPatternToJson(TimeOfDayPattern instance) =>
    <String, dynamic>{
      'time_of_day': instance.timeOfDay,
      'display_name': instance.displayName,
      'total_completions': instance.totalCompletions,
      'total_skips': instance.totalSkips,
      'completion_rate': instance.completionRate,
      'is_preferred': instance.isPreferred,
    };

WeeklyConsistencyMetric _$WeeklyConsistencyMetricFromJson(
  Map<String, dynamic> json,
) => WeeklyConsistencyMetric(
  weekStart: json['week_start'] as String,
  weekEnd: json['week_end'] as String,
  workoutsScheduled: (json['workouts_scheduled'] as num?)?.toInt() ?? 0,
  workoutsCompleted: (json['workouts_completed'] as num?)?.toInt() ?? 0,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
  totalWorkoutMinutes: (json['total_workout_minutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$WeeklyConsistencyMetricToJson(
  WeeklyConsistencyMetric instance,
) => <String, dynamic>{
  'week_start': instance.weekStart,
  'week_end': instance.weekEnd,
  'workouts_scheduled': instance.workoutsScheduled,
  'workouts_completed': instance.workoutsCompleted,
  'completion_rate': instance.completionRate,
  'total_workout_minutes': instance.totalWorkoutMinutes,
};

ConsistencyInsights _$ConsistencyInsightsFromJson(
  Map<String, dynamic> json,
) => ConsistencyInsights(
  userId: json['user_id'] as String,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  isStreakActive: json['is_streak_active'] as bool? ?? false,
  bestDay: json['best_day'] == null
      ? null
      : DayPattern.fromJson(json['best_day'] as Map<String, dynamic>),
  worstDay: json['worst_day'] == null
      ? null
      : DayPattern.fromJson(json['worst_day'] as Map<String, dynamic>),
  dayPatterns:
      (json['day_patterns'] as List<dynamic>?)
          ?.map((e) => DayPattern.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  preferredTime: json['preferred_time'] as String?,
  timePatterns:
      (json['time_patterns'] as List<dynamic>?)
          ?.map((e) => TimeOfDayPattern.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  monthWorkoutsCompleted:
      (json['month_workouts_completed'] as num?)?.toInt() ?? 0,
  monthWorkoutsScheduled:
      (json['month_workouts_scheduled'] as num?)?.toInt() ?? 0,
  monthCompletionRate:
      (json['month_completion_rate'] as num?)?.toDouble() ?? 0.0,
  monthDisplay: json['month_display'] as String? ?? '',
  weeklyCompletionRates:
      (json['weekly_completion_rates'] as List<dynamic>?)
          ?.map(
            (e) => WeeklyConsistencyMetric.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  averageWeeklyRate: (json['average_weekly_rate'] as num?)?.toDouble() ?? 0.0,
  weeklyTrend: json['weekly_trend'] as String? ?? 'stable',
  needsRecovery: json['needs_recovery'] as bool? ?? false,
  recoverySuggestion: json['recovery_suggestion'] as String?,
  daysSinceLastWorkout: (json['days_since_last_workout'] as num?)?.toInt() ?? 0,
  lastWorkoutDate: json['last_workout_date'] as String?,
  calculatedAt: json['calculated_at'] as String?,
);

Map<String, dynamic> _$ConsistencyInsightsToJson(
  ConsistencyInsights instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'current_streak': instance.currentStreak,
  'longest_streak': instance.longestStreak,
  'is_streak_active': instance.isStreakActive,
  'best_day': instance.bestDay,
  'worst_day': instance.worstDay,
  'day_patterns': instance.dayPatterns,
  'preferred_time': instance.preferredTime,
  'time_patterns': instance.timePatterns,
  'month_workouts_completed': instance.monthWorkoutsCompleted,
  'month_workouts_scheduled': instance.monthWorkoutsScheduled,
  'month_completion_rate': instance.monthCompletionRate,
  'month_display': instance.monthDisplay,
  'weekly_completion_rates': instance.weeklyCompletionRates,
  'average_weekly_rate': instance.averageWeeklyRate,
  'weekly_trend': instance.weeklyTrend,
  'needs_recovery': instance.needsRecovery,
  'recovery_suggestion': instance.recoverySuggestion,
  'days_since_last_workout': instance.daysSinceLastWorkout,
  'last_workout_date': instance.lastWorkoutDate,
  'calculated_at': instance.calculatedAt,
};

StreakHistoryRecord _$StreakHistoryRecordFromJson(Map<String, dynamic> json) =>
    StreakHistoryRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      streakLength: (json['streak_length'] as num).toInt(),
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String,
      endReason: json['end_reason'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$StreakHistoryRecordToJson(
  StreakHistoryRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'streak_length': instance.streakLength,
  'started_at': instance.startedAt,
  'ended_at': instance.endedAt,
  'end_reason': instance.endReason,
  'created_at': instance.createdAt,
};

ConsistencyPatterns _$ConsistencyPatternsFromJson(Map<String, dynamic> json) =>
    ConsistencyPatterns(
      userId: json['user_id'] as String,
      timePatterns:
          (json['time_patterns'] as List<dynamic>?)
              ?.map((e) => TimeOfDayPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      preferredTime: json['preferred_time'] as String?,
      dayPatterns:
          (json['day_patterns'] as List<dynamic>?)
              ?.map((e) => DayPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mostConsistentDay: json['most_consistent_day'] as String?,
      leastConsistentDay: json['least_consistent_day'] as String?,
      hasSeasonalData: json['has_seasonal_data'] as bool? ?? false,
      seasonalNotes: json['seasonal_notes'] as String?,
      skipReasons:
          (json['skip_reasons'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      mostCommonSkipReason: json['most_common_skip_reason'] as String?,
      streakHistory:
          (json['streak_history'] as List<dynamic>?)
              ?.map(
                (e) => StreakHistoryRecord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      averageStreakLength:
          (json['average_streak_length'] as num?)?.toDouble() ?? 0.0,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      calculatedAt: json['calculated_at'] as String?,
    );

Map<String, dynamic> _$ConsistencyPatternsToJson(
  ConsistencyPatterns instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'time_patterns': instance.timePatterns,
  'preferred_time': instance.preferredTime,
  'day_patterns': instance.dayPatterns,
  'most_consistent_day': instance.mostConsistentDay,
  'least_consistent_day': instance.leastConsistentDay,
  'has_seasonal_data': instance.hasSeasonalData,
  'seasonal_notes': instance.seasonalNotes,
  'skip_reasons': instance.skipReasons,
  'most_common_skip_reason': instance.mostCommonSkipReason,
  'streak_history': instance.streakHistory,
  'average_streak_length': instance.averageStreakLength,
  'streak_count': instance.streakCount,
  'calculated_at': instance.calculatedAt,
};

CalendarHeatmapData _$CalendarHeatmapDataFromJson(Map<String, dynamic> json) =>
    CalendarHeatmapData(
      date: json['date'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      status: json['status'] as String,
      workoutName: json['workout_name'] as String?,
    );

Map<String, dynamic> _$CalendarHeatmapDataToJson(
  CalendarHeatmapData instance,
) => <String, dynamic>{
  'date': instance.date,
  'day_of_week': instance.dayOfWeek,
  'status': instance.status,
  'workout_name': instance.workoutName,
};

CalendarHeatmapResponse _$CalendarHeatmapResponseFromJson(
  Map<String, dynamic> json,
) => CalendarHeatmapResponse(
  userId: json['user_id'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => CalendarHeatmapData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalCompleted: (json['total_completed'] as num?)?.toInt() ?? 0,
  totalMissed: (json['total_missed'] as num?)?.toInt() ?? 0,
  totalRestDays: (json['total_rest_days'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CalendarHeatmapResponseToJson(
  CalendarHeatmapResponse instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'data': instance.data,
  'total_completed': instance.totalCompleted,
  'total_missed': instance.totalMissed,
  'total_rest_days': instance.totalRestDays,
};

StreakRecoveryResponse _$StreakRecoveryResponseFromJson(
  Map<String, dynamic> json,
) => StreakRecoveryResponse(
  success: json['success'] as bool,
  attemptId: json['attempt_id'] as String,
  message: json['message'] as String,
  motivationQuote: json['motivation_quote'] as String?,
  suggestedWorkoutType: json['suggested_workout_type'] as String?,
  suggestedDurationMinutes: (json['suggested_duration_minutes'] as num?)
      ?.toInt(),
);

Map<String, dynamic> _$StreakRecoveryResponseToJson(
  StreakRecoveryResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'attempt_id': instance.attemptId,
  'message': instance.message,
  'motivation_quote': instance.motivationQuote,
  'suggested_workout_type': instance.suggestedWorkoutType,
  'suggested_duration_minutes': instance.suggestedDurationMinutes,
};
