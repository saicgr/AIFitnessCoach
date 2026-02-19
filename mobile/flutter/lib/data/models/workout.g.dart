// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  name: json['name'] as String?,
  description: json['description'] as String?,
  type: json['type'] as String?,
  difficulty: json['difficulty'] as String?,
  scheduledDate: json['scheduled_date'] as String?,
  isCompleted: json['is_completed'] as bool?,
  exercisesJson: json['exercises_json'],
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  durationMinutesMin: (json['duration_minutes_min'] as num?)?.toInt(),
  durationMinutesMax: (json['duration_minutes_max'] as num?)?.toInt(),
  estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)
      ?.toInt(),
  generationMethod: json['generation_method'] as String?,
  generationMetadata: _parseGenerationMetadata(json['generation_metadata']),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  completedAt: json['completed_at'] as String?,
  completionMethod: json['completion_method'] as String?,
  isFavorite: json['is_favorite'] as bool?,
);

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'type': instance.type,
  'difficulty': instance.difficulty,
  'scheduled_date': instance.scheduledDate,
  'is_completed': instance.isCompleted,
  'exercises_json': instance.exercisesJson,
  'duration_minutes': instance.durationMinutes,
  'duration_minutes_min': instance.durationMinutesMin,
  'duration_minutes_max': instance.durationMinutesMax,
  'estimated_duration_minutes': instance.estimatedDurationMinutes,
  'generation_method': instance.generationMethod,
  'generation_metadata': instance.generationMetadata,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'completed_at': instance.completedAt,
  'completion_method': instance.completionMethod,
  'is_favorite': instance.isFavorite,
};
