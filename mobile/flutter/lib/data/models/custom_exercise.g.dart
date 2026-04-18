// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentExercise _$ComponentExerciseFromJson(Map<String, dynamic> json) =>
    ComponentExercise(
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      transitionNote: json['transition_note'] as String?,
    );

Map<String, dynamic> _$ComponentExerciseToJson(ComponentExercise instance) =>
    <String, dynamic>{
      'name': instance.name,
      'order': instance.order,
      'reps': instance.reps,
      'duration_seconds': instance.durationSeconds,
      'transition_note': instance.transitionNote,
    };

CustomExercise _$CustomExerciseFromJson(Map<String, dynamic> json) =>
    CustomExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscle: json['primary_muscle'] as String,
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipment: json['equipment'] as String,
      instructions: json['instructions'] as String?,
      defaultSets: (json['default_sets'] as num).toInt(),
      defaultReps: (json['default_reps'] as num?)?.toInt(),
      defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt(),
      isCompound: json['is_compound'] as bool,
      isComposite: json['is_composite'] as bool,
      comboType: json['combo_type'] as String?,
      componentExercises: (json['component_exercises'] as List<dynamic>?)
          ?.map((e) => ComponentExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      customNotes: json['custom_notes'] as String?,
      customVideoUrl: json['custom_video_url'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      usageCount: (json['usage_count'] as num).toInt(),
      lastUsed: json['last_used'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$CustomExerciseToJson(CustomExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'equipment': instance.equipment,
      'instructions': instance.instructions,
      'default_sets': instance.defaultSets,
      'default_reps': instance.defaultReps,
      'default_rest_seconds': instance.defaultRestSeconds,
      'is_compound': instance.isCompound,
      'is_composite': instance.isComposite,
      'combo_type': instance.comboType,
      'component_exercises': instance.componentExercises,
      'custom_notes': instance.customNotes,
      'custom_video_url': instance.customVideoUrl,
      'tags': instance.tags,
      'usage_count': instance.usageCount,
      'last_used': instance.lastUsed,
      'created_at': instance.createdAt,
    };

CreateCustomExerciseRequest _$CreateCustomExerciseRequestFromJson(
  Map<String, dynamic> json,
) => CreateCustomExerciseRequest(
  name: json['name'] as String,
  primaryMuscle: json['primary_muscle'] as String,
  equipment: json['equipment'] as String,
  instructions: json['instructions'] as String?,
  defaultSets: (json['default_sets'] as num?)?.toInt() ?? 3,
  defaultReps: (json['default_reps'] as num?)?.toInt() ?? 10,
  defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt(),
  isCompound: json['is_compound'] as bool? ?? false,
  defaultRpe: (json['default_rpe'] as num?)?.toInt(),
  defaultTempo: json['default_tempo'] as String?,
  defaultBandColor: json['default_band_color'] as String?,
  defaultNotes: json['default_notes'] as String?,
  defaultRangeOfMotion: json['default_range_of_motion'] as String?,
  defaultInclinePercent: (json['default_incline_percent'] as num?)?.toDouble(),
  defaultDurationSeconds: (json['default_duration_seconds'] as num?)?.toInt(),
  defaultDistanceMiles: (json['default_distance_miles'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CreateCustomExerciseRequestToJson(
  CreateCustomExerciseRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'primary_muscle': instance.primaryMuscle,
  'equipment': instance.equipment,
  'instructions': instance.instructions,
  'default_sets': instance.defaultSets,
  'default_reps': instance.defaultReps,
  'default_rest_seconds': instance.defaultRestSeconds,
  'is_compound': instance.isCompound,
  'default_rpe': instance.defaultRpe,
  'default_tempo': instance.defaultTempo,
  'default_band_color': instance.defaultBandColor,
  'default_notes': instance.defaultNotes,
  'default_range_of_motion': instance.defaultRangeOfMotion,
  'default_incline_percent': instance.defaultInclinePercent,
  'default_duration_seconds': instance.defaultDurationSeconds,
  'default_distance_miles': instance.defaultDistanceMiles,
};

CreateCompositeExerciseRequest _$CreateCompositeExerciseRequestFromJson(
  Map<String, dynamic> json,
) => CreateCompositeExerciseRequest(
  name: json['name'] as String,
  primaryMuscle: json['primary_muscle'] as String,
  secondaryMuscles:
      (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  equipment: json['equipment'] as String,
  comboType: json['combo_type'] as String,
  componentExercises: (json['component_exercises'] as List<dynamic>)
      .map((e) => ComponentExercise.fromJson(e as Map<String, dynamic>))
      .toList(),
  instructions: json['instructions'] as String?,
  customNotes: json['custom_notes'] as String?,
  defaultSets: (json['default_sets'] as num?)?.toInt() ?? 3,
  defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt() ?? 60,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$CreateCompositeExerciseRequestToJson(
  CreateCompositeExerciseRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'primary_muscle': instance.primaryMuscle,
  'secondary_muscles': instance.secondaryMuscles,
  'equipment': instance.equipment,
  'combo_type': instance.comboType,
  'component_exercises': instance.componentExercises,
  'instructions': instance.instructions,
  'custom_notes': instance.customNotes,
  'default_sets': instance.defaultSets,
  'default_rest_seconds': instance.defaultRestSeconds,
  'tags': instance.tags,
};

CustomExerciseStats _$CustomExerciseStatsFromJson(Map<String, dynamic> json) =>
    CustomExerciseStats(
      totalCustomExercises: (json['total_custom_exercises'] as num).toInt(),
      simpleExercises: (json['simple_exercises'] as num).toInt(),
      compositeExercises: (json['composite_exercises'] as num).toInt(),
      totalUses: (json['total_uses'] as num).toInt(),
      mostUsed: (json['most_used'] as List<dynamic>)
          .map((e) => MostUsedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomExerciseStatsToJson(
  CustomExerciseStats instance,
) => <String, dynamic>{
  'total_custom_exercises': instance.totalCustomExercises,
  'simple_exercises': instance.simpleExercises,
  'composite_exercises': instance.compositeExercises,
  'total_uses': instance.totalUses,
  'most_used': instance.mostUsed,
};

MostUsedExercise _$MostUsedExerciseFromJson(Map<String, dynamic> json) =>
    MostUsedExercise(
      exerciseId: json['exercise_id'] as String,
      name: json['name'] as String,
      usageCount: (json['usage_count'] as num).toInt(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MostUsedExerciseToJson(MostUsedExercise instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'name': instance.name,
      'usage_count': instance.usageCount,
      'avg_rating': instance.avgRating,
    };

ExerciseSearchResult _$ExerciseSearchResultFromJson(
  Map<String, dynamic> json,
) => ExerciseSearchResult(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  bodyPart: json['body_part'] as String?,
  equipment: json['equipment'] as String?,
  targetMuscle: json['target_muscle'] as String?,
);

Map<String, dynamic> _$ExerciseSearchResultToJson(
  ExerciseSearchResult instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'body_part': instance.bodyPart,
  'equipment': instance.equipment,
  'target_muscle': instance.targetMuscle,
};
