// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseWorkoutSession _$ExerciseWorkoutSessionFromJson(
  Map<String, dynamic> json,
) => ExerciseWorkoutSession(
  workoutId: json['workout_id'] as String,
  workoutDate: json['workout_date'] as String,
  workoutName: json['workout_name'] as String?,
  sets: (json['sets'] as num?)?.toInt() ?? 0,
  reps: (json['reps'] as num?)?.toInt() ?? 0,
  weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
  totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
  estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble(),
  restSeconds: (json['rest_seconds'] as num?)?.toInt(),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  isPr: json['is_pr'] as bool?,
  prType: json['pr_type'] as String?,
);

Map<String, dynamic> _$ExerciseWorkoutSessionToJson(
  ExerciseWorkoutSession instance,
) => <String, dynamic>{
  'workout_id': instance.workoutId,
  'workout_date': instance.workoutDate,
  'workout_name': instance.workoutName,
  'sets': instance.sets,
  'reps': instance.reps,
  'weight_kg': instance.weightKg,
  'total_volume_kg': instance.totalVolumeKg,
  'estimated_1rm_kg': instance.estimated1rmKg,
  'rest_seconds': instance.restSeconds,
  'duration_minutes': instance.durationMinutes,
  'notes': instance.notes,
  'is_pr': instance.isPr,
  'pr_type': instance.prType,
};

ExerciseHistoryData _$ExerciseHistoryDataFromJson(Map<String, dynamic> json) =>
    ExerciseHistoryData(
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String?,
      exerciseName: json['exercise_name'] as String,
      muscleGroup: json['muscle_group'] as String?,
      timeRange: json['time_range'] as String,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ExerciseWorkoutSession.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      summary: json['summary'] == null
          ? null
          : ExerciseProgressionSummary.fromJson(
              json['summary'] as Map<String, dynamic>,
            ),
      personalRecords: (json['personal_records'] as List<dynamic>?)
          ?.map(
            (e) => ExercisePersonalRecord.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ExerciseHistoryDataToJson(
  ExerciseHistoryData instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'exercise_id': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'muscle_group': instance.muscleGroup,
  'time_range': instance.timeRange,
  'total_sessions': instance.totalSessions,
  'sessions': instance.sessions,
  'summary': instance.summary,
  'personal_records': instance.personalRecords,
};

ExercisePersonalRecord _$ExercisePersonalRecordFromJson(
  Map<String, dynamic> json,
) => ExercisePersonalRecord(
  id: json['id'] as String,
  exerciseId: json['exercise_id'] as String?,
  exerciseName: json['exercise_name'] as String,
  prType: json['pr_type'] as String,
  prValue: (json['pr_value'] as num).toDouble(),
  achievedDate: json['achieved_date'] as String,
  workoutId: json['workout_id'] as String?,
  previousValue: (json['previous_value'] as num?)?.toDouble(),
  improvementPercent: (json['improvement_percent'] as num?)?.toDouble(),
  sets: (json['sets'] as num?)?.toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExercisePersonalRecordToJson(
  ExercisePersonalRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'exercise_id': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'pr_type': instance.prType,
  'pr_value': instance.prValue,
  'achieved_date': instance.achievedDate,
  'workout_id': instance.workoutId,
  'previous_value': instance.previousValue,
  'improvement_percent': instance.improvementPercent,
  'sets': instance.sets,
  'reps': instance.reps,
  'weight_kg': instance.weightKg,
};

ExerciseChartDataPoint _$ExerciseChartDataPointFromJson(
  Map<String, dynamic> json,
) => ExerciseChartDataPoint(
  date: json['date'] as String,
  value: (json['value'] as num).toDouble(),
  label: json['label'] as String?,
  isPr: json['is_pr'] as bool?,
  annotation: json['annotation'] as String?,
);

Map<String, dynamic> _$ExerciseChartDataPointToJson(
  ExerciseChartDataPoint instance,
) => <String, dynamic>{
  'date': instance.date,
  'value': instance.value,
  'label': instance.label,
  'is_pr': instance.isPr,
  'annotation': instance.annotation,
};

ExerciseProgressionSummary _$ExerciseProgressionSummaryFromJson(
  Map<String, dynamic> json,
) => ExerciseProgressionSummary(
  totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
  firstSessionDate: json['first_session_date'] as String?,
  lastSessionDate: json['last_session_date'] as String?,
  daysTraining: (json['days_training'] as num?)?.toInt(),
  startingWeightKg: (json['starting_weight_kg'] as num?)?.toDouble(),
  currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble(),
  weightIncreaseKg: (json['weight_increase_kg'] as num?)?.toDouble(),
  weightIncreasePercent: (json['weight_increase_percent'] as num?)?.toDouble(),
  starting1rmKg: (json['starting_1rm_kg'] as num?)?.toDouble(),
  current1rmKg: (json['current_1rm_kg'] as num?)?.toDouble(),
  oneRmIncreaseKg: (json['one_rm_increase_kg'] as num?)?.toDouble(),
  oneRmIncreasePercent: (json['one_rm_increase_percent'] as num?)?.toDouble(),
  totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
  avgVolumePerSessionKg: (json['avg_volume_per_session_kg'] as num?)
      ?.toDouble(),
  totalSets: (json['total_sets'] as num?)?.toInt(),
  totalReps: (json['total_reps'] as num?)?.toInt(),
  prCount: (json['pr_count'] as num?)?.toInt(),
  trend: json['trend'] as String?,
  avgFrequencyPerWeek: (json['avg_frequency_per_week'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExerciseProgressionSummaryToJson(
  ExerciseProgressionSummary instance,
) => <String, dynamic>{
  'total_sessions': instance.totalSessions,
  'first_session_date': instance.firstSessionDate,
  'last_session_date': instance.lastSessionDate,
  'days_training': instance.daysTraining,
  'starting_weight_kg': instance.startingWeightKg,
  'current_weight_kg': instance.currentWeightKg,
  'weight_increase_kg': instance.weightIncreaseKg,
  'weight_increase_percent': instance.weightIncreasePercent,
  'starting_1rm_kg': instance.starting1rmKg,
  'current_1rm_kg': instance.current1rmKg,
  'one_rm_increase_kg': instance.oneRmIncreaseKg,
  'one_rm_increase_percent': instance.oneRmIncreasePercent,
  'total_volume_kg': instance.totalVolumeKg,
  'avg_volume_per_session_kg': instance.avgVolumePerSessionKg,
  'total_sets': instance.totalSets,
  'total_reps': instance.totalReps,
  'pr_count': instance.prCount,
  'trend': instance.trend,
  'avg_frequency_per_week': instance.avgFrequencyPerWeek,
};

MostPerformedExercise _$MostPerformedExerciseFromJson(
  Map<String, dynamic> json,
) => MostPerformedExercise(
  exerciseId: json['exercise_id'] as String?,
  exerciseName: json['exercise_name'] as String,
  muscleGroup: json['muscle_group'] as String?,
  timesPerformed: (json['times_performed'] as num?)?.toInt() ?? 0,
  totalSets: (json['total_sets'] as num?)?.toInt(),
  totalReps: (json['total_reps'] as num?)?.toInt(),
  totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
  maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
  current1rmKg: (json['current_1rm_kg'] as num?)?.toDouble(),
  lastPerformed: json['last_performed'] as String?,
  rank: (json['rank'] as num?)?.toInt(),
);

Map<String, dynamic> _$MostPerformedExerciseToJson(
  MostPerformedExercise instance,
) => <String, dynamic>{
  'exercise_id': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'muscle_group': instance.muscleGroup,
  'times_performed': instance.timesPerformed,
  'total_sets': instance.totalSets,
  'total_reps': instance.totalReps,
  'total_volume_kg': instance.totalVolumeKg,
  'max_weight_kg': instance.maxWeightKg,
  'current_1rm_kg': instance.current1rmKg,
  'last_performed': instance.lastPerformed,
  'rank': instance.rank,
};
