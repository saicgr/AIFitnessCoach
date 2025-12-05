// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    WorkoutExercise(
      id: json['id'] as String?,
      exerciseId: json['exercise_id'] as String?,
      libraryId: json['library_id'] as String?,
      nameValue: json['name'] as String?,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
      bodyPart: json['body_part'] as String?,
      equipment: json['equipment'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      primaryMuscle: json['primary_muscle'] as String?,
      secondaryMuscles: json['secondary_muscles'],
      instructions: json['instructions'] as String?,
      isCompleted: json['is_completed'] as bool?,
    );

Map<String, dynamic> _$WorkoutExerciseToJson(WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exercise_id': instance.exerciseId,
      'library_id': instance.libraryId,
      'name': instance.nameValue,
      'sets': instance.sets,
      'reps': instance.reps,
      'rest_seconds': instance.restSeconds,
      'duration_seconds': instance.durationSeconds,
      'weight': instance.weight,
      'notes': instance.notes,
      'gif_url': instance.gifUrl,
      'video_url': instance.videoUrl,
      'body_part': instance.bodyPart,
      'equipment': instance.equipment,
      'muscle_group': instance.muscleGroup,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'instructions': instance.instructions,
      'is_completed': instance.isCompleted,
    };

LibraryExercise _$LibraryExerciseFromJson(Map<String, dynamic> json) =>
    LibraryExercise(
      id: json['id'] as String?,
      externalId: json['external_id'] as String?,
      nameValue: json['name'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt(),
      primaryMuscle: json['primary_muscle'] as String?,
      secondaryMuscles: json['secondary_muscles'] as String?,
      equipmentRequired: json['equipment_required'] as String?,
      bodyPart: json['body_part'] as String?,
      target: json['target'] as String?,
      defaultSets: (json['default_sets'] as num?)?.toInt(),
      defaultReps: (json['default_reps'] as num?)?.toInt(),
      defaultDurationSeconds: (json['default_duration_seconds'] as num?)
          ?.toInt(),
      defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt(),
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
      instructionsValue: json['instructions'] as String?,
      isCompound: json['is_compound'] as bool?,
      isUnilateral: json['is_unilateral'] as bool?,
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$LibraryExerciseToJson(LibraryExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'external_id': instance.externalId,
      'name': instance.nameValue,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'difficulty_level': instance.difficultyLevel,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'equipment_required': instance.equipmentRequired,
      'body_part': instance.bodyPart,
      'target': instance.target,
      'default_sets': instance.defaultSets,
      'default_reps': instance.defaultReps,
      'default_duration_seconds': instance.defaultDurationSeconds,
      'default_rest_seconds': instance.defaultRestSeconds,
      'gif_url': instance.gifUrl,
      'video_url': instance.videoUrl,
      'instructions': instance.instructionsValue,
      'is_compound': instance.isCompound,
      'is_unilateral': instance.isUnilateral,
      'tags': instance.tags,
    };
