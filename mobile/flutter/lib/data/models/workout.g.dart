// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  name: json['name'] as String?,
  type: json['type'] as String?,
  difficulty: json['difficulty'] as String?,
  scheduledDate: json['scheduled_date'] as String?,
  isCompleted: json['is_completed'] as bool?,
  exercisesJson: json['exercises_json'],
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  generationMethod: json['generation_method'] as String?,
  generationMetadata: _parseGenerationMetadata(json['generation_metadata']),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'type': instance.type,
  'difficulty': instance.difficulty,
  'scheduled_date': instance.scheduledDate,
  'is_completed': instance.isCompleted,
  'exercises_json': instance.exercisesJson,
  'duration_minutes': instance.durationMinutes,
  'generation_method': instance.generationMethod,
  'generation_metadata': instance.generationMetadata,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
