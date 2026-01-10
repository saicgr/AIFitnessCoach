// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_day_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutDayDetail _$WorkoutDayDetailFromJson(Map<String, dynamic> json) =>
    WorkoutDayDetail(
      date: json['date'] as String,
      status: json['status'] as String,
      workoutId: json['workout_id'] as String?,
      workoutName: json['workout_name'] as String?,
      workoutType: json['workout_type'] as String?,
      difficulty: json['difficulty'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toInt(),
      musclesWorked:
          (json['muscles_worked'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) => ExerciseSetDetail.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      sharedImages: (json['shared_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      coachFeedback: json['coach_feedback'] as String?,
      completedAt: json['completed_at'] as String?,
      averageRpe: (json['average_rpe'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WorkoutDayDetailToJson(WorkoutDayDetail instance) =>
    <String, dynamic>{
      'date': instance.date,
      'status': instance.status,
      'workout_id': instance.workoutId,
      'workout_name': instance.workoutName,
      'workout_type': instance.workoutType,
      'difficulty': instance.difficulty,
      'duration_minutes': instance.durationMinutes,
      'total_volume': instance.totalVolume,
      'calories_burned': instance.caloriesBurned,
      'muscles_worked': instance.musclesWorked,
      'exercises': instance.exercises,
      'shared_images': instance.sharedImages,
      'coach_feedback': instance.coachFeedback,
      'completed_at': instance.completedAt,
      'average_rpe': instance.averageRpe,
    };

ExerciseSetDetail _$ExerciseSetDetailFromJson(Map<String, dynamic> json) =>
    ExerciseSetDetail(
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      muscleGroup: json['muscle_group'] as String,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => SetData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      hasPr: json['has_pr'] as bool? ?? false,
      prType: json['pr_type'] as String?,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      bestSetWeight: (json['best_set_weight'] as num?)?.toDouble(),
      bestSetReps: (json['best_set_reps'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExerciseSetDetailToJson(ExerciseSetDetail instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'exercise_id': instance.exerciseId,
      'muscle_group': instance.muscleGroup,
      'sets': instance.sets,
      'has_pr': instance.hasPr,
      'pr_type': instance.prType,
      'total_volume': instance.totalVolume,
      'best_set_weight': instance.bestSetWeight,
      'best_set_reps': instance.bestSetReps,
    };

SetData _$SetDataFromJson(Map<String, dynamic> json) => SetData(
  setNumber: (json['set_number'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  weightKg: (json['weight_kg'] as num).toDouble(),
  rpe: (json['rpe'] as num?)?.toInt(),
  rir: (json['rir'] as num?)?.toInt(),
  isPr: json['is_pr'] as bool? ?? false,
  setType: json['set_type'] as String?,
);

Map<String, dynamic> _$SetDataToJson(SetData instance) => <String, dynamic>{
  'set_number': instance.setNumber,
  'reps': instance.reps,
  'weight_kg': instance.weightKg,
  'rpe': instance.rpe,
  'rir': instance.rir,
  'is_pr': instance.isPr,
  'set_type': instance.setType,
};

ExerciseSearchResult _$ExerciseSearchResultFromJson(
  Map<String, dynamic> json,
) => ExerciseSearchResult(
  date: json['date'] as String,
  workoutId: json['workout_id'] as String,
  workoutName: json['workout_name'] as String,
  exerciseName: json['exercise_name'] as String,
  setsCompleted: (json['sets_completed'] as num).toInt(),
  bestWeight: (json['best_weight'] as num).toDouble(),
  bestReps: (json['best_reps'] as num).toInt(),
  totalVolume: (json['total_volume'] as num?)?.toDouble(),
  hasPr: json['has_pr'] as bool? ?? false,
  prType: json['pr_type'] as String?,
  averageRpe: (json['average_rpe'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExerciseSearchResultToJson(
  ExerciseSearchResult instance,
) => <String, dynamic>{
  'date': instance.date,
  'workout_id': instance.workoutId,
  'workout_name': instance.workoutName,
  'exercise_name': instance.exerciseName,
  'sets_completed': instance.setsCompleted,
  'best_weight': instance.bestWeight,
  'best_reps': instance.bestReps,
  'total_volume': instance.totalVolume,
  'has_pr': instance.hasPr,
  'pr_type': instance.prType,
  'average_rpe': instance.averageRpe,
};

ExerciseSearchResponse _$ExerciseSearchResponseFromJson(
  Map<String, dynamic> json,
) => ExerciseSearchResponse(
  exerciseName: json['exercise_name'] as String,
  totalResults: (json['total_results'] as num).toInt(),
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => ExerciseSearchResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  matchingDates:
      (json['matching_dates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$ExerciseSearchResponseToJson(
  ExerciseSearchResponse instance,
) => <String, dynamic>{
  'exercise_name': instance.exerciseName,
  'total_results': instance.totalResults,
  'results': instance.results,
  'matching_dates': instance.matchingDates,
};

ExerciseSuggestion _$ExerciseSuggestionFromJson(Map<String, dynamic> json) =>
    ExerciseSuggestion(
      name: json['name'] as String,
      timesPerformed: (json['times_performed'] as num?)?.toInt() ?? 0,
      lastPerformed: json['last_performed'] as String?,
    );

Map<String, dynamic> _$ExerciseSuggestionToJson(ExerciseSuggestion instance) =>
    <String, dynamic>{
      'name': instance.name,
      'times_performed': instance.timesPerformed,
      'last_performed': instance.lastPerformed,
    };
