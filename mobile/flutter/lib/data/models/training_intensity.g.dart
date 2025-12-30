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
    );

Map<String, dynamic> _$WorkingWeightResultToJson(
  WorkingWeightResult instance,
) => <String, dynamic>{
  'exercise_name': instance.exerciseName,
  'one_rep_max_kg': instance.oneRepMaxKg,
  'intensity_percent': instance.intensityPercent,
  'working_weight_kg': instance.workingWeightKg,
  'is_from_override': instance.isFromOverride,
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
