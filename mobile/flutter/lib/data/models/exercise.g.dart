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
      imageS3Path: json['image_s3_path'] as String?,
      videoS3Path: json['video_s3_path'] as String?,
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
      'image_s3_path': instance.imageS3Path,
      'video_s3_path': instance.videoS3Path,
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
      nameValue: json['name'] as String?,
      originalName: json['original_name'] as String?,
      bodyPart: json['body_part'] as String?,
      equipmentValue: json['equipment'] as String?,
      targetMuscle: json['target_muscle'] as String?,
      secondaryMuscles: json['secondary_muscles'] as String?,
      instructionsValue: json['instructions'] as String?,
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt(),
      category: json['category'] as String?,
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
    );

Map<String, dynamic> _$LibraryExerciseToJson(LibraryExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.nameValue,
      'original_name': instance.originalName,
      'body_part': instance.bodyPart,
      'equipment': instance.equipmentValue,
      'target_muscle': instance.targetMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'instructions': instance.instructionsValue,
      'difficulty_level': instance.difficultyLevel,
      'category': instance.category,
      'gif_url': instance.gifUrl,
      'video_url': instance.videoUrl,
    };
