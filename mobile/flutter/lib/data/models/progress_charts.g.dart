// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_charts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyStrengthData _$WeeklyStrengthDataFromJson(Map<String, dynamic> json) =>
    WeeklyStrengthData(
      weekStart: json['week_start'] as String,
      weekNumber: (json['week_number'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      muscleGroup: json['muscle_group'] as String,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalReps: (json['total_reps'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
      maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble() ?? 0,
      workoutCount: (json['workout_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WeeklyStrengthDataToJson(WeeklyStrengthData instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_number': instance.weekNumber,
      'year': instance.year,
      'muscle_group': instance.muscleGroup,
      'total_sets': instance.totalSets,
      'total_reps': instance.totalReps,
      'total_volume_kg': instance.totalVolumeKg,
      'max_weight_kg': instance.maxWeightKg,
      'workout_count': instance.workoutCount,
    };

StrengthProgressionData _$StrengthProgressionDataFromJson(
  Map<String, dynamic> json,
) => StrengthProgressionData(
  userId: json['user_id'] as String,
  timeRange: json['time_range'] as String,
  weeksCount: (json['weeks_count'] as num?)?.toInt() ?? 0,
  muscleGroups:
      (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => WeeklyStrengthData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  summary: json['summary'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$StrengthProgressionDataToJson(
  StrengthProgressionData instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'time_range': instance.timeRange,
  'weeks_count': instance.weeksCount,
  'muscle_groups': instance.muscleGroups,
  'data': instance.data,
  'summary': instance.summary,
};

WeeklyVolumeData _$WeeklyVolumeDataFromJson(Map<String, dynamic> json) =>
    WeeklyVolumeData(
      weekStart: json['week_start'] as String,
      weekNumber: (json['week_number'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      workoutsCompleted: (json['workouts_completed'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      avgDurationMinutes:
          (json['avg_duration_minutes'] as num?)?.toDouble() ?? 0,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalReps: (json['total_reps'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WeeklyVolumeDataToJson(WeeklyVolumeData instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_number': instance.weekNumber,
      'year': instance.year,
      'workouts_completed': instance.workoutsCompleted,
      'total_minutes': instance.totalMinutes,
      'avg_duration_minutes': instance.avgDurationMinutes,
      'total_volume_kg': instance.totalVolumeKg,
      'total_sets': instance.totalSets,
      'total_reps': instance.totalReps,
    };

VolumeProgressionData _$VolumeProgressionDataFromJson(
  Map<String, dynamic> json,
) => VolumeProgressionData(
  userId: json['user_id'] as String,
  timeRange: json['time_range'] as String,
  weeksCount: (json['weeks_count'] as num?)?.toInt() ?? 0,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => WeeklyVolumeData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  trend: json['trend'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$VolumeProgressionDataToJson(
  VolumeProgressionData instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'time_range': instance.timeRange,
  'weeks_count': instance.weeksCount,
  'data': instance.data,
  'trend': instance.trend,
};

ExerciseStrengthData _$ExerciseStrengthDataFromJson(
  Map<String, dynamic> json,
) => ExerciseStrengthData(
  exerciseName: json['exercise_name'] as String,
  muscleGroup: json['muscle_group'] as String,
  weekStart: json['week_start'] as String,
  timesPerformed: (json['times_performed'] as num?)?.toInt() ?? 0,
  maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble() ?? 0,
  estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$ExerciseStrengthDataToJson(
  ExerciseStrengthData instance,
) => <String, dynamic>{
  'exercise_name': instance.exerciseName,
  'muscle_group': instance.muscleGroup,
  'week_start': instance.weekStart,
  'times_performed': instance.timesPerformed,
  'max_weight_kg': instance.maxWeightKg,
  'estimated_1rm_kg': instance.estimated1rmKg,
};

ExerciseProgressionData _$ExerciseProgressionDataFromJson(
  Map<String, dynamic> json,
) => ExerciseProgressionData(
  userId: json['user_id'] as String,
  timeRange: json['time_range'] as String,
  exerciseName: json['exercise_name'] as String,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => ExerciseStrengthData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  improvement: json['improvement'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ExerciseProgressionDataToJson(
  ExerciseProgressionData instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'time_range': instance.timeRange,
  'exercise_name': instance.exerciseName,
  'data': instance.data,
  'improvement': instance.improvement,
};

ProgressSummary _$ProgressSummaryFromJson(Map<String, dynamic> json) =>
    ProgressSummary(
      userId: json['user_id'] as String,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
      totalPRs: (json['total_prs'] as num?)?.toInt() ?? 0,
      firstWorkoutDate: json['first_workout_date'] as String?,
      lastWorkoutDate: json['last_workout_date'] as String?,
      volumeIncreasePercent:
          (json['volume_increase_percent'] as num?)?.toDouble() ?? 0,
      avgWeeklyWorkouts: (json['avg_weekly_workouts'] as num?)?.toDouble() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      muscleGroupBreakdown:
          (json['muscle_group_breakdown'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      recentPRs:
          (json['recent_prs'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      bestWeek: json['best_week'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProgressSummaryToJson(ProgressSummary instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'total_workouts': instance.totalWorkouts,
      'total_volume_kg': instance.totalVolumeKg,
      'total_prs': instance.totalPRs,
      'first_workout_date': instance.firstWorkoutDate,
      'last_workout_date': instance.lastWorkoutDate,
      'volume_increase_percent': instance.volumeIncreasePercent,
      'avg_weekly_workouts': instance.avgWeeklyWorkouts,
      'current_streak': instance.currentStreak,
      'muscle_group_breakdown': instance.muscleGroupBreakdown,
      'recent_prs': instance.recentPRs,
      'best_week': instance.bestWeek,
    };

AvailableMuscleGroups _$AvailableMuscleGroupsFromJson(
  Map<String, dynamic> json,
) => AvailableMuscleGroups(
  userId: json['user_id'] as String,
  muscleGroups:
      (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  count: (json['count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AvailableMuscleGroupsToJson(
  AvailableMuscleGroups instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'muscle_groups': instance.muscleGroups,
  'count': instance.count,
};
