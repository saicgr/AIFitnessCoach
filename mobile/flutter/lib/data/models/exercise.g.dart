// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetTarget _$SetTargetFromJson(Map<String, dynamic> json) => SetTarget(
  setNumber: (json['set_number'] as num).toInt(),
  setType: json['set_type'] as String? ?? 'working',
  targetReps: (json['target_reps'] as num).toInt(),
  targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
  targetRpe: (json['target_rpe'] as num?)?.toInt(),
  targetRir: (json['target_rir'] as num?)?.toInt(),
);

Map<String, dynamic> _$SetTargetToJson(SetTarget instance) => <String, dynamic>{
  'set_number': instance.setNumber,
  'set_type': instance.setType,
  'target_reps': instance.targetReps,
  'target_weight_kg': instance.targetWeightKg,
  'target_rpe': instance.targetRpe,
  'target_rir': instance.targetRir,
};

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
      alternatingHands: json['alternating_hands'] as bool?,
      weightSource: json['weight_source'] as String?,
      isFavorite: json['is_favorite'] as bool?,
      fromQueue: json['from_queue'] as bool?,
      holdSeconds: (json['hold_seconds'] as num?)?.toInt(),
      isUnilateral: json['is_unilateral'] as bool?,
      supersetGroup: (json['superset_group'] as num?)?.toInt(),
      supersetOrder: (json['superset_order'] as num?)?.toInt(),
      isDropSet: json['is_drop_set'] as bool?,
      dropSetCount: (json['drop_set_count'] as num?)?.toInt(),
      dropSetPercentage: (json['drop_set_percentage'] as num?)?.toInt(),
      isChallenge: json['is_challenge'] as bool?,
      progressionFrom: json['progression_from'] as String?,
      difficulty: json['difficulty'] as String?,
      difficultyNum: (json['difficulty_num'] as num?)?.toInt(),
      isFailureSet: json['is_failure_set'] as bool?,
      setTargets: (json['set_targets'] as List<dynamic>?)
          ?.map((e) => SetTarget.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'alternating_hands': instance.alternatingHands,
      'weight_source': instance.weightSource,
      'is_favorite': instance.isFavorite,
      'from_queue': instance.fromQueue,
      'hold_seconds': instance.holdSeconds,
      'is_unilateral': instance.isUnilateral,
      'superset_group': instance.supersetGroup,
      'superset_order': instance.supersetOrder,
      'is_drop_set': instance.isDropSet,
      'drop_set_count': instance.dropSetCount,
      'drop_set_percentage': instance.dropSetPercentage,
      'is_challenge': instance.isChallenge,
      'progression_from': instance.progressionFrom,
      'difficulty': instance.difficulty,
      'difficulty_num': instance.difficultyNum,
      'is_failure_set': instance.isFailureSet,
      'set_targets': instance.setTargets,
    };

LibraryExercise _$LibraryExerciseFromJson(Map<String, dynamic> json) =>
    LibraryExercise(
      id: json['id'] as String?,
      nameValue: json['name'] as String?,
      originalName: json['original_name'] as String?,
      bodyPart: json['body_part'] as String?,
      equipmentValue: json['equipment'] as String?,
      targetMuscle: json['target_muscle'] as String?,
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      instructionsValue: json['instructions'] as String?,
      difficultyLevelValue: json['difficulty_level'] as String?,
      category: json['category'] as String?,
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      suitableFor: (json['suitable_for'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avoidIf: (json['avoid_if'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'difficulty_level': instance.difficultyLevelValue,
      'category': instance.category,
      'gif_url': instance.gifUrl,
      'video_url': instance.videoUrl,
      'image_url': instance.imageUrl,
      'goals': instance.goals,
      'suitable_for': instance.suitableFor,
      'avoid_if': instance.avoidIf,
    };
