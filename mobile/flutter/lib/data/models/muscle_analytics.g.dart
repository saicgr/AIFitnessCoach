// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MuscleHeatmapData _$MuscleHeatmapDataFromJson(Map<String, dynamic> json) =>
    MuscleHeatmapData(
      userId: json['user_id'] as String,
      timeRange: json['time_range'] as String,
      muscleIntensities:
          (json['muscle_intensities'] as List<dynamic>?)
              ?.map((e) => MuscleIntensity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      maxIntensity: (json['max_intensity'] as num?)?.toDouble(),
      minIntensity: (json['min_intensity'] as num?)?.toDouble(),
      lastUpdated: json['last_updated'] as String?,
    );

Map<String, dynamic> _$MuscleHeatmapDataToJson(MuscleHeatmapData instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'time_range': instance.timeRange,
      'muscle_intensities': instance.muscleIntensities,
      'max_intensity': instance.maxIntensity,
      'min_intensity': instance.minIntensity,
      'last_updated': instance.lastUpdated,
    };

MuscleIntensity _$MuscleIntensityFromJson(Map<String, dynamic> json) =>
    MuscleIntensity(
      muscleId: json['muscle_id'] as String,
      muscleName: json['muscle_name'] as String?,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0,
      workoutCount: (json['workout_count'] as num?)?.toInt(),
      totalSets: (json['total_sets'] as num?)?.toInt(),
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      lastTrained: json['last_trained'] as String?,
    );

Map<String, dynamic> _$MuscleIntensityToJson(MuscleIntensity instance) =>
    <String, dynamic>{
      'muscle_id': instance.muscleId,
      'muscle_name': instance.muscleName,
      'intensity': instance.intensity,
      'workout_count': instance.workoutCount,
      'total_sets': instance.totalSets,
      'total_volume_kg': instance.totalVolumeKg,
      'last_trained': instance.lastTrained,
    };

MuscleTrainingFrequency _$MuscleTrainingFrequencyFromJson(
  Map<String, dynamic> json,
) => MuscleTrainingFrequency(
  userId: json['user_id'] as String,
  timeRange: json['time_range'] as String,
  frequencies:
      (json['frequencies'] as List<dynamic>?)
          ?.map((e) => MuscleFrequencyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalWorkouts: (json['total_workouts'] as num?)?.toInt(),
  avgWorkoutsPerWeek: (json['avg_workouts_per_week'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MuscleTrainingFrequencyToJson(
  MuscleTrainingFrequency instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'time_range': instance.timeRange,
  'frequencies': instance.frequencies,
  'total_workouts': instance.totalWorkouts,
  'avg_workouts_per_week': instance.avgWorkoutsPerWeek,
};

MuscleFrequencyData _$MuscleFrequencyDataFromJson(Map<String, dynamic> json) =>
    MuscleFrequencyData(
      muscleGroup: json['muscle_group'] as String,
      timesTrained: (json['times_trained'] as num?)?.toInt() ?? 0,
      timesPerWeek: (json['times_per_week'] as num?)?.toDouble() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt(),
      avgSetsPerWorkout: (json['avg_sets_per_workout'] as num?)?.toDouble(),
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      lastTrained: json['last_trained'] as String?,
      daysSinceTrained: (json['days_since_trained'] as num?)?.toInt(),
      recommendedFrequency: (json['recommended_frequency'] as num?)?.toDouble(),
      frequencyStatus: json['frequency_status'] as String?,
    );

Map<String, dynamic> _$MuscleFrequencyDataToJson(
  MuscleFrequencyData instance,
) => <String, dynamic>{
  'muscle_group': instance.muscleGroup,
  'times_trained': instance.timesTrained,
  'times_per_week': instance.timesPerWeek,
  'total_sets': instance.totalSets,
  'avg_sets_per_workout': instance.avgSetsPerWorkout,
  'total_volume_kg': instance.totalVolumeKg,
  'last_trained': instance.lastTrained,
  'days_since_trained': instance.daysSinceTrained,
  'recommended_frequency': instance.recommendedFrequency,
  'frequency_status': instance.frequencyStatus,
};

MuscleBalanceData _$MuscleBalanceDataFromJson(Map<String, dynamic> json) =>
    MuscleBalanceData(
      userId: json['user_id'] as String,
      timeRange: json['time_range'] as String,
      pushPullRatio: (json['push_pull_ratio'] as num?)?.toDouble(),
      pushVolumeKg: (json['push_volume_kg'] as num?)?.toDouble(),
      pullVolumeKg: (json['pull_volume_kg'] as num?)?.toDouble(),
      upperLowerRatio: (json['upper_lower_ratio'] as num?)?.toDouble(),
      upperVolumeKg: (json['upper_volume_kg'] as num?)?.toDouble(),
      lowerVolumeKg: (json['lower_volume_kg'] as num?)?.toDouble(),
      anteriorPosteriorRatio: (json['anterior_posterior_ratio'] as num?)
          ?.toDouble(),
      leftRightRatio: (json['left_right_ratio'] as num?)?.toDouble(),
      balanceScore: (json['balance_score'] as num?)?.toDouble(),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imbalances: (json['imbalances'] as List<dynamic>?)
          ?.map((e) => MuscleImbalance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MuscleBalanceDataToJson(MuscleBalanceData instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'time_range': instance.timeRange,
      'push_pull_ratio': instance.pushPullRatio,
      'push_volume_kg': instance.pushVolumeKg,
      'pull_volume_kg': instance.pullVolumeKg,
      'upper_lower_ratio': instance.upperLowerRatio,
      'upper_volume_kg': instance.upperVolumeKg,
      'lower_volume_kg': instance.lowerVolumeKg,
      'anterior_posterior_ratio': instance.anteriorPosteriorRatio,
      'left_right_ratio': instance.leftRightRatio,
      'balance_score': instance.balanceScore,
      'recommendations': instance.recommendations,
      'imbalances': instance.imbalances,
    };

MuscleImbalance _$MuscleImbalanceFromJson(Map<String, dynamic> json) =>
    MuscleImbalance(
      musclePair: json['muscle_pair'] as String,
      ratio: (json['ratio'] as num).toDouble(),
      dominantSide: json['dominant_side'] as String?,
      differencePercent: (json['difference_percent'] as num?)?.toDouble(),
      severity: json['severity'] as String?,
      recommendation: json['recommendation'] as String?,
    );

Map<String, dynamic> _$MuscleImbalanceToJson(MuscleImbalance instance) =>
    <String, dynamic>{
      'muscle_pair': instance.musclePair,
      'ratio': instance.ratio,
      'dominant_side': instance.dominantSide,
      'difference_percent': instance.differencePercent,
      'severity': instance.severity,
      'recommendation': instance.recommendation,
    };

MuscleExerciseData _$MuscleExerciseDataFromJson(Map<String, dynamic> json) =>
    MuscleExerciseData(
      muscleGroup: json['muscle_group'] as String,
      timeRange: json['time_range'] as String,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) => MuscleExerciseStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      totalExercises: (json['total_exercises'] as num?)?.toInt(),
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      totalSets: (json['total_sets'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MuscleExerciseDataToJson(MuscleExerciseData instance) =>
    <String, dynamic>{
      'muscle_group': instance.muscleGroup,
      'time_range': instance.timeRange,
      'exercises': instance.exercises,
      'total_exercises': instance.totalExercises,
      'total_volume_kg': instance.totalVolumeKg,
      'total_sets': instance.totalSets,
    };

MuscleExerciseStats _$MuscleExerciseStatsFromJson(Map<String, dynamic> json) =>
    MuscleExerciseStats(
      exerciseId: json['exercise_id'] as String?,
      exerciseName: json['exercise_name'] as String,
      timesPerformed: (json['times_performed'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt(),
      totalReps: (json['total_reps'] as num?)?.toInt(),
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
      avgWeightKg: (json['avg_weight_kg'] as num?)?.toDouble(),
      volumePercentage: (json['volume_percentage'] as num?)?.toDouble(),
      lastPerformed: json['last_performed'] as String?,
    );

Map<String, dynamic> _$MuscleExerciseStatsToJson(
  MuscleExerciseStats instance,
) => <String, dynamic>{
  'exercise_id': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'times_performed': instance.timesPerformed,
  'total_sets': instance.totalSets,
  'total_reps': instance.totalReps,
  'total_volume_kg': instance.totalVolumeKg,
  'max_weight_kg': instance.maxWeightKg,
  'avg_weight_kg': instance.avgWeightKg,
  'volume_percentage': instance.volumePercentage,
  'last_performed': instance.lastPerformed,
};

MuscleHistoryData _$MuscleHistoryDataFromJson(
  Map<String, dynamic> json,
) => MuscleHistoryData(
  userId: json['user_id'] as String,
  muscleGroup: json['muscle_group'] as String,
  timeRange: json['time_range'] as String,
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => MuscleWorkoutEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  summary: json['summary'] == null
      ? null
      : MuscleHistorySummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MuscleHistoryDataToJson(MuscleHistoryData instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'muscle_group': instance.muscleGroup,
      'time_range': instance.timeRange,
      'history': instance.history,
      'summary': instance.summary,
    };

MuscleWorkoutEntry _$MuscleWorkoutEntryFromJson(Map<String, dynamic> json) =>
    MuscleWorkoutEntry(
      workoutId: json['workout_id'] as String,
      workoutDate: json['workout_date'] as String,
      workoutName: json['workout_name'] as String?,
      exercisesCount: (json['exercises_count'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt(),
      totalReps: (json['total_reps'] as num?)?.toInt(),
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
      exerciseNames: (json['exercises'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MuscleWorkoutEntryToJson(MuscleWorkoutEntry instance) =>
    <String, dynamic>{
      'workout_id': instance.workoutId,
      'workout_date': instance.workoutDate,
      'workout_name': instance.workoutName,
      'exercises_count': instance.exercisesCount,
      'total_sets': instance.totalSets,
      'total_reps': instance.totalReps,
      'total_volume_kg': instance.totalVolumeKg,
      'max_weight_kg': instance.maxWeightKg,
      'exercises': instance.exerciseNames,
    };

MuscleHistorySummary _$MuscleHistorySummaryFromJson(
  Map<String, dynamic> json,
) => MuscleHistorySummary(
  totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
  totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
  avgVolumePerWorkoutKg: (json['avg_volume_per_workout_kg'] as num?)
      ?.toDouble(),
  maxVolumeKg: (json['max_volume_kg'] as num?)?.toDouble(),
  maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
  totalSets: (json['total_sets'] as num?)?.toInt(),
  volumeTrend: json['volume_trend'] as String?,
  volumeChangePercent: (json['volume_change_percent'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MuscleHistorySummaryToJson(
  MuscleHistorySummary instance,
) => <String, dynamic>{
  'total_workouts': instance.totalWorkouts,
  'total_volume_kg': instance.totalVolumeKg,
  'avg_volume_per_workout_kg': instance.avgVolumePerWorkoutKg,
  'max_volume_kg': instance.maxVolumeKg,
  'max_weight_kg': instance.maxWeightKg,
  'total_sets': instance.totalSets,
  'volume_trend': instance.volumeTrend,
  'volume_change_percent': instance.volumeChangePercent,
};

MuscleChartDataPoint _$MuscleChartDataPointFromJson(
  Map<String, dynamic> json,
) => MuscleChartDataPoint(
  date: json['date'] as String,
  value: (json['value'] as num).toDouble(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$MuscleChartDataPointToJson(
  MuscleChartDataPoint instance,
) => <String, dynamic>{
  'date': instance.date,
  'value': instance.value,
  'label': instance.label,
};
