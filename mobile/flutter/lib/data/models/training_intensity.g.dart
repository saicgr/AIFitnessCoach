// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_intensity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserExercise1RM _$UserExercise1RMFromJson(Map<String, dynamic> json) =>
    UserExercise1RM(
      exerciseName: json['exercise_name'] as String,
      oneRepMaxKg: (json['one_rep_max_kg'] as num).toDouble(),
      source: json['source'] as String? ?? 'manual',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      lastTestedAt: json['last_tested_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UserExercise1RMToJson(UserExercise1RM instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'one_rep_max_kg': instance.oneRepMaxKg,
      'source': instance.source,
      'confidence': instance.confidence,
      'last_tested_at': instance.lastTestedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

TrainingIntensitySettings _$TrainingIntensitySettingsFromJson(
  Map<String, dynamic> json,
) => TrainingIntensitySettings(
  globalIntensityPercent:
      (json['global_intensity_percent'] as num?)?.toInt() ?? 75,
  globalDescription:
      json['global_description'] as String? ?? 'Working Weight / Hypertrophy',
  exerciseOverrides:
      (json['exercise_overrides'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
);

Map<String, dynamic> _$TrainingIntensitySettingsToJson(
  TrainingIntensitySettings instance,
) => <String, dynamic>{
  'global_intensity_percent': instance.globalIntensityPercent,
  'global_description': instance.globalDescription,
  'exercise_overrides': instance.exerciseOverrides,
};

IntensityResponse _$IntensityResponseFromJson(Map<String, dynamic> json) =>
    IntensityResponse(
      intensityPercent: (json['intensity_percent'] as num).toInt(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$IntensityResponseToJson(IntensityResponse instance) =>
    <String, dynamic>{
      'intensity_percent': instance.intensityPercent,
      'description': instance.description,
    };

WorkingWeightResult _$WorkingWeightResultFromJson(Map<String, dynamic> json) =>
    WorkingWeightResult(
      exerciseName: json['exercise_name'] as String,
      oneRepMaxKg: (json['one_rep_max_kg'] as num).toDouble(),
      intensityPercent: (json['intensity_percent'] as num).toInt(),
      workingWeightKg: (json['working_weight_kg'] as num).toDouble(),
      isFromOverride: json['is_from_override'] as bool? ?? false,
      sourceType: json['source_type'] as String? ?? 'direct',
      sourceExercise: json['source_exercise'] as String?,
      equipmentMultiplier:
          (json['equipment_multiplier'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$WorkingWeightResultToJson(
  WorkingWeightResult instance,
) => <String, dynamic>{
  'exercise_name': instance.exerciseName,
  'one_rep_max_kg': instance.oneRepMaxKg,
  'intensity_percent': instance.intensityPercent,
  'working_weight_kg': instance.workingWeightKg,
  'is_from_override': instance.isFromOverride,
  'source_type': instance.sourceType,
  'source_exercise': instance.sourceExercise,
  'equipment_multiplier': instance.equipmentMultiplier,
};

LinkedExercise _$LinkedExerciseFromJson(Map<String, dynamic> json) =>
    LinkedExercise(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      primaryExerciseName: json['primary_exercise_name'] as String,
      linkedExerciseName: json['linked_exercise_name'] as String,
      strengthMultiplier:
          (json['strength_multiplier'] as num?)?.toDouble() ?? 0.85,
      relationshipType: json['relationship_type'] as String? ?? 'variant',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$LinkedExerciseToJson(LinkedExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'primary_exercise_name': instance.primaryExerciseName,
      'linked_exercise_name': instance.linkedExerciseName,
      'strength_multiplier': instance.strengthMultiplier,
      'relationship_type': instance.relationshipType,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

ExerciseLinkSuggestion _$ExerciseLinkSuggestionFromJson(
  Map<String, dynamic> json,
) => ExerciseLinkSuggestion(
  name: json['name'] as String,
  equipment: json['equipment'] as String,
  suggestedMultiplier: (json['suggested_multiplier'] as num).toDouble(),
  muscleGroup: json['muscle_group'] as String,
);

Map<String, dynamic> _$ExerciseLinkSuggestionToJson(
  ExerciseLinkSuggestion instance,
) => <String, dynamic>{
  'name': instance.name,
  'equipment': instance.equipment,
  'suggested_multiplier': instance.suggestedMultiplier,
  'muscle_group': instance.muscleGroup,
};

AutoPopulateResponse _$AutoPopulateResponseFromJson(
  Map<String, dynamic> json,
) => AutoPopulateResponse(
  count: (json['count'] as num).toInt(),
  message: json['message'] as String,
);

Map<String, dynamic> _$AutoPopulateResponseToJson(
  AutoPopulateResponse instance,
) => <String, dynamic>{'count': instance.count, 'message': instance.message};
