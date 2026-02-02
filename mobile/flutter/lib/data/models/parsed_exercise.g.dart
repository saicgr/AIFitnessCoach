// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParsedExercise _$ParsedExerciseFromJson(Map<String, dynamic> json) =>
    ParsedExercise(
      name: json['name'] as String,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      weightLbs: (json['weight_lbs'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String? ?? 'lbs',
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 60,
      originalText: json['original_text'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ParsedExerciseToJson(ParsedExercise instance) =>
    <String, dynamic>{
      'name': instance.name,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight_kg': instance.weightKg,
      'weight_lbs': instance.weightLbs,
      'weight_unit': instance.weightUnit,
      'rest_seconds': instance.restSeconds,
      'original_text': instance.originalText,
      'confidence': instance.confidence,
      'notes': instance.notes,
    };

ParseWorkoutInputResponse _$ParseWorkoutInputResponseFromJson(
  Map<String, dynamic> json,
) => ParseWorkoutInputResponse(
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => ParsedExercise.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: json['summary'] as String,
  warnings:
      (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ParseWorkoutInputResponseToJson(
  ParseWorkoutInputResponse instance,
) => <String, dynamic>{
  'exercises': instance.exercises,
  'summary': instance.summary,
  'warnings': instance.warnings,
};

SetToLog _$SetToLogFromJson(Map<String, dynamic> json) => SetToLog(
  weight: (json['weight'] as num).toDouble(),
  reps: (json['reps'] as num).toInt(),
  unit: json['unit'] as String? ?? 'lbs',
  isBodyweight: json['is_bodyweight'] as bool? ?? false,
  isFailure: json['is_failure'] as bool? ?? false,
  isWarmup: json['is_warmup'] as bool? ?? false,
  originalInput: json['original_input'] as String? ?? '',
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SetToLogToJson(SetToLog instance) => <String, dynamic>{
  'weight': instance.weight,
  'reps': instance.reps,
  'unit': instance.unit,
  'is_bodyweight': instance.isBodyweight,
  'is_failure': instance.isFailure,
  'is_warmup': instance.isWarmup,
  'original_input': instance.originalInput,
  'notes': instance.notes,
};

ExerciseToAdd _$ExerciseToAddFromJson(Map<String, dynamic> json) =>
    ExerciseToAdd(
      name: json['name'] as String,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      weightLbs: (json['weight_lbs'] as num?)?.toDouble(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 60,
      isBodyweight: json['is_bodyweight'] as bool? ?? false,
      originalText: json['original_text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ExerciseToAddToJson(ExerciseToAdd instance) =>
    <String, dynamic>{
      'name': instance.name,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight_kg': instance.weightKg,
      'weight_lbs': instance.weightLbs,
      'rest_seconds': instance.restSeconds,
      'is_bodyweight': instance.isBodyweight,
      'original_text': instance.originalText,
      'confidence': instance.confidence,
      'notes': instance.notes,
    };

ParseWorkoutInputV2Response _$ParseWorkoutInputV2ResponseFromJson(
  Map<String, dynamic> json,
) => ParseWorkoutInputV2Response(
  setsToLog:
      (json['sets_to_log'] as List<dynamic>?)
          ?.map((e) => SetToLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  exercisesToAdd:
      (json['exercises_to_add'] as List<dynamic>?)
          ?.map((e) => ExerciseToAdd.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  summary: json['summary'] as String,
  warnings:
      (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ParseWorkoutInputV2ResponseToJson(
  ParseWorkoutInputV2Response instance,
) => <String, dynamic>{
  'sets_to_log': instance.setsToLog,
  'exercises_to_add': instance.exercisesToAdd,
  'summary': instance.summary,
  'warnings': instance.warnings,
};
