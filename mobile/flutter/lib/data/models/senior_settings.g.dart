// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'senior_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeniorRecoverySettings _$SeniorRecoverySettingsFromJson(
  Map<String, dynamic> json,
) => SeniorRecoverySettings(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  recoveryMultiplier: (json['recovery_multiplier'] as num?)?.toDouble() ?? 1.5,
  minRestDaysBetweenWorkouts:
      (json['min_rest_days_between_workouts'] as num?)?.toInt() ?? 1,
  maxWorkoutDaysPerWeek:
      (json['max_workout_days_per_week'] as num?)?.toInt() ?? 4,
  maxIntensityLevel: json['max_intensity_level'] as String? ?? 'moderate',
  maxRpe: (json['max_rpe'] as num?)?.toInt() ?? 7,
  reduceVolumePercentage:
      (json['reduce_volume_percentage'] as num?)?.toInt() ?? 20,
  warmupDurationMinutes:
      (json['warmup_duration_minutes'] as num?)?.toInt() ?? 10,
  cooldownDurationMinutes:
      (json['cooldown_duration_minutes'] as num?)?.toInt() ?? 10,
  extendedWarmupEnabled: json['extended_warmup_enabled'] as bool? ?? true,
  preferLowImpact: json['prefer_low_impact'] as bool? ?? true,
  avoidHighImpactCardio: json['avoid_high_impact_cardio'] as bool? ?? true,
  preferSeatedExercises: json['prefer_seated_exercises'] as bool? ?? false,
  avoidJumpingMovements: json['avoid_jumping_movements'] as bool? ?? true,
  avoidOverheadPressing: json['avoid_overhead_pressing'] as bool? ?? false,
  includeMobilityWork: json['include_mobility_work'] as bool? ?? true,
  includeBalanceExercises: json['include_balance_exercises'] as bool? ?? true,
  mobilityFocusAreas:
      (json['mobility_focus_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['hips', 'shoulders', 'spine'],
  balanceExerciseFrequency:
      json['balance_exercise_frequency'] as String? ?? 'every_workout',
  jointConsiderations:
      (json['joint_considerations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  avoidExercisePatterns:
      (json['avoid_exercise_patterns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  restBetweenSetsMultiplier:
      (json['rest_between_sets_multiplier'] as num?)?.toDouble() ?? 1.5,
  requireFullRecovery: json['require_full_recovery'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SeniorRecoverySettingsToJson(
  SeniorRecoverySettings instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'recovery_multiplier': instance.recoveryMultiplier,
  'min_rest_days_between_workouts': instance.minRestDaysBetweenWorkouts,
  'max_workout_days_per_week': instance.maxWorkoutDaysPerWeek,
  'max_intensity_level': instance.maxIntensityLevel,
  'max_rpe': instance.maxRpe,
  'reduce_volume_percentage': instance.reduceVolumePercentage,
  'warmup_duration_minutes': instance.warmupDurationMinutes,
  'cooldown_duration_minutes': instance.cooldownDurationMinutes,
  'extended_warmup_enabled': instance.extendedWarmupEnabled,
  'prefer_low_impact': instance.preferLowImpact,
  'avoid_high_impact_cardio': instance.avoidHighImpactCardio,
  'prefer_seated_exercises': instance.preferSeatedExercises,
  'avoid_jumping_movements': instance.avoidJumpingMovements,
  'avoid_overhead_pressing': instance.avoidOverheadPressing,
  'include_mobility_work': instance.includeMobilityWork,
  'include_balance_exercises': instance.includeBalanceExercises,
  'mobility_focus_areas': instance.mobilityFocusAreas,
  'balance_exercise_frequency': instance.balanceExerciseFrequency,
  'joint_considerations': instance.jointConsiderations,
  'avoid_exercise_patterns': instance.avoidExercisePatterns,
  'rest_between_sets_multiplier': instance.restBetweenSetsMultiplier,
  'require_full_recovery': instance.requireFullRecovery,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

RecoveryStatus _$RecoveryStatusFromJson(Map<String, dynamic> json) =>
    RecoveryStatus(
      userId: json['user_id'] as String,
      isReady: json['is_ready'] as bool,
      daysSinceLastWorkout:
          (json['days_since_last_workout'] as num?)?.toInt() ?? 0,
      daysUntilReady: (json['days_until_ready'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] as String,
      recoveryPercentage:
          (json['recovery_percentage'] as num?)?.toDouble() ?? 100.0,
      lastWorkoutDate: json['last_workout_date'] == null
          ? null
          : DateTime.parse(json['last_workout_date'] as String),
      lastWorkoutIntensity: json['last_workout_intensity'] as String?,
      fatigueIndicators:
          (json['fatigue_indicators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendedWorkoutType: json['recommended_workout_type'] as String?,
      suggestedIntensity: json['suggested_intensity'] as String?,
      checkedAt: DateTime.parse(json['checked_at'] as String),
    );

Map<String, dynamic> _$RecoveryStatusToJson(RecoveryStatus instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'is_ready': instance.isReady,
      'days_since_last_workout': instance.daysSinceLastWorkout,
      'days_until_ready': instance.daysUntilReady,
      'recommendation': instance.recommendation,
      'recovery_percentage': instance.recoveryPercentage,
      'last_workout_date': instance.lastWorkoutDate?.toIso8601String(),
      'last_workout_intensity': instance.lastWorkoutIntensity,
      'fatigue_indicators': instance.fatigueIndicators,
      'recommended_workout_type': instance.recommendedWorkoutType,
      'suggested_intensity': instance.suggestedIntensity,
      'checked_at': instance.checkedAt.toIso8601String(),
    };

WorkoutModificationResult _$WorkoutModificationResultFromJson(
  Map<String, dynamic> json,
) => WorkoutModificationResult(
  success: json['success'] as bool,
  message: json['message'] as String,
  originalWorkoutId: json['original_workout_id'] as String?,
  modifiedWorkoutId: json['modified_workout_id'] as String?,
  modificationsApplied:
      (json['modifications_applied'] as List<dynamic>?)
          ?.map((e) => WorkoutModification.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  exercisesSwapped: (json['exercises_swapped'] as num?)?.toInt() ?? 0,
  exercisesRemoved: (json['exercises_removed'] as num?)?.toInt() ?? 0,
  volumeReductionPercent:
      (json['volume_reduction_percent'] as num?)?.toDouble() ?? 0,
  intensityReduction: json['intensity_reduction'] as String?,
  warmupExtended: json['warmup_extended'] as bool? ?? false,
  cooldownExtended: json['cooldown_extended'] as bool? ?? false,
  balanceExercisesAdded:
      (json['balance_exercises_added'] as num?)?.toInt() ?? 0,
  mobilityExercisesAdded:
      (json['mobility_exercises_added'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WorkoutModificationResultToJson(
  WorkoutModificationResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'original_workout_id': instance.originalWorkoutId,
  'modified_workout_id': instance.modifiedWorkoutId,
  'modifications_applied': instance.modificationsApplied,
  'exercises_swapped': instance.exercisesSwapped,
  'exercises_removed': instance.exercisesRemoved,
  'volume_reduction_percent': instance.volumeReductionPercent,
  'intensity_reduction': instance.intensityReduction,
  'warmup_extended': instance.warmupExtended,
  'cooldown_extended': instance.cooldownExtended,
  'balance_exercises_added': instance.balanceExercisesAdded,
  'mobility_exercises_added': instance.mobilityExercisesAdded,
  'created_at': instance.createdAt?.toIso8601String(),
};

WorkoutModification _$WorkoutModificationFromJson(Map<String, dynamic> json) =>
    WorkoutModification(
      modificationType: json['modification_type'] as String,
      originalValue: json['original_value'] as String?,
      newValue: json['new_value'] as String?,
      reason: json['reason'] as String,
      exerciseName: json['exercise_name'] as String?,
    );

Map<String, dynamic> _$WorkoutModificationToJson(
  WorkoutModification instance,
) => <String, dynamic>{
  'modification_type': instance.modificationType,
  'original_value': instance.originalValue,
  'new_value': instance.newValue,
  'reason': instance.reason,
  'exercise_name': instance.exerciseName,
};

SeniorMobilityExercise _$SeniorMobilityExerciseFromJson(
  Map<String, dynamic> json,
) => SeniorMobilityExercise(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  targetAreas:
      (json['target_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 30,
  reps: (json['reps'] as num?)?.toInt(),
  sets: (json['sets'] as num?)?.toInt() ?? 2,
  difficultyLevel: json['difficulty_level'] as String? ?? 'easy',
  equipmentNeeded:
      (json['equipment_needed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isSeated: json['is_seated'] as bool? ?? false,
  isBalanceExercise: json['is_balance_exercise'] as bool? ?? false,
  requiresSupport: json['requires_support'] as bool? ?? false,
  benefits:
      (json['benefits'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  commonMistakes:
      (json['common_mistakes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  cues:
      (json['cues'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  videoUrl: json['video_url'] as String?,
  imageUrl: json['image_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SeniorMobilityExerciseToJson(
  SeniorMobilityExercise instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'target_areas': instance.targetAreas,
  'duration_seconds': instance.durationSeconds,
  'reps': instance.reps,
  'sets': instance.sets,
  'difficulty_level': instance.difficultyLevel,
  'equipment_needed': instance.equipmentNeeded,
  'is_seated': instance.isSeated,
  'is_balance_exercise': instance.isBalanceExercise,
  'requires_support': instance.requiresSupport,
  'benefits': instance.benefits,
  'common_mistakes': instance.commonMistakes,
  'cues': instance.cues,
  'video_url': instance.videoUrl,
  'image_url': instance.imageUrl,
  'is_active': instance.isActive,
  'created_at': instance.createdAt?.toIso8601String(),
};

SeniorWorkoutLog _$SeniorWorkoutLogFromJson(Map<String, dynamic> json) =>
    SeniorWorkoutLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      workoutName: json['workout_name'] as String,
      workoutType: json['workout_type'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      perceivedExertion: (json['perceived_exertion'] as num?)?.toInt(),
      energyLevelBefore: (json['energy_level_before'] as num?)?.toInt(),
      energyLevelAfter: (json['energy_level_after'] as num?)?.toInt(),
      jointPainReported: json['joint_pain_reported'] as bool? ?? false,
      jointPainAreas:
          (json['joint_pain_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      balanceExercisesCompleted:
          (json['balance_exercises_completed'] as num?)?.toInt() ?? 0,
      mobilityExercisesCompleted:
          (json['mobility_exercises_completed'] as num?)?.toInt() ?? 0,
      modificationsUsed:
          (json['modifications_used'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      warmupCompleted: json['warmup_completed'] as bool? ?? true,
      cooldownCompleted: json['cooldown_completed'] as bool? ?? true,
      recoveryRating: (json['recovery_rating'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SeniorWorkoutLogToJson(SeniorWorkoutLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'workout_id': instance.workoutId,
      'workout_name': instance.workoutName,
      'workout_type': instance.workoutType,
      'completed_at': instance.completedAt.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'perceived_exertion': instance.perceivedExertion,
      'energy_level_before': instance.energyLevelBefore,
      'energy_level_after': instance.energyLevelAfter,
      'joint_pain_reported': instance.jointPainReported,
      'joint_pain_areas': instance.jointPainAreas,
      'balance_exercises_completed': instance.balanceExercisesCompleted,
      'mobility_exercises_completed': instance.mobilityExercisesCompleted,
      'modifications_used': instance.modificationsUsed,
      'warmup_completed': instance.warmupCompleted,
      'cooldown_completed': instance.cooldownCompleted,
      'recovery_rating': instance.recoveryRating,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };

LowImpactAlternative _$LowImpactAlternativeFromJson(
  Map<String, dynamic> json,
) => LowImpactAlternative(
  originalExerciseId: json['original_exercise_id'] as String?,
  originalExerciseName: json['original_exercise_name'] as String,
  alternativeExerciseId: json['alternative_exercise_id'] as String?,
  alternativeExerciseName: json['alternative_exercise_name'] as String,
  alternativeDescription: json['alternative_description'] as String?,
  reason: json['reason'] as String,
  muscleSimilarityScore:
      (json['muscle_similarity_score'] as num?)?.toDouble() ?? 0.8,
  impactReduction: json['impact_reduction'] as String? ?? 'moderate',
  isSeated: json['is_seated'] as bool? ?? false,
  equipmentNeeded:
      (json['equipment_needed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  benefits:
      (json['benefits'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$LowImpactAlternativeToJson(
  LowImpactAlternative instance,
) => <String, dynamic>{
  'original_exercise_id': instance.originalExerciseId,
  'original_exercise_name': instance.originalExerciseName,
  'alternative_exercise_id': instance.alternativeExerciseId,
  'alternative_exercise_name': instance.alternativeExerciseName,
  'alternative_description': instance.alternativeDescription,
  'reason': instance.reason,
  'muscle_similarity_score': instance.muscleSimilarityScore,
  'impact_reduction': instance.impactReduction,
  'is_seated': instance.isSeated,
  'equipment_needed': instance.equipmentNeeded,
  'benefits': instance.benefits,
};

SeniorWorkoutHistoryResponse _$SeniorWorkoutHistoryResponseFromJson(
  Map<String, dynamic> json,
) => SeniorWorkoutHistoryResponse(
  workoutLogs:
      (json['workout_logs'] as List<dynamic>?)
          ?.map((e) => SeniorWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
  totalDurationMinutes: (json['total_duration_minutes'] as num?)?.toInt() ?? 0,
  averagePerceivedExertion: (json['average_perceived_exertion'] as num?)
      ?.toDouble(),
  workoutsWithJointPain:
      (json['workouts_with_joint_pain'] as num?)?.toInt() ?? 0,
  mostCommonPainAreas:
      (json['most_common_pain_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  balanceExercisesTotal:
      (json['balance_exercises_total'] as num?)?.toInt() ?? 0,
  mobilityExercisesTotal:
      (json['mobility_exercises_total'] as num?)?.toInt() ?? 0,
  consistencyScore: (json['consistency_score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SeniorWorkoutHistoryResponseToJson(
  SeniorWorkoutHistoryResponse instance,
) => <String, dynamic>{
  'workout_logs': instance.workoutLogs,
  'total_workouts': instance.totalWorkouts,
  'total_duration_minutes': instance.totalDurationMinutes,
  'average_perceived_exertion': instance.averagePerceivedExertion,
  'workouts_with_joint_pain': instance.workoutsWithJointPain,
  'most_common_pain_areas': instance.mostCommonPainAreas,
  'balance_exercises_total': instance.balanceExercisesTotal,
  'mobility_exercises_total': instance.mobilityExercisesTotal,
  'consistency_score': instance.consistencyScore,
};
