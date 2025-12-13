// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryProgram _$LibraryProgramFromJson(Map<String, dynamic> json) =>
    LibraryProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
      sessionsPerWeek: (json['sessions_per_week'] as num?)?.toInt(),
      sessionDurationMinutes:
          (json['session_duration_minutes'] as num?)?.toInt(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      goals:
          (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList(),
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      celebrityName: json['celebrity_name'] as String?,
    );

Map<String, dynamic> _$LibraryProgramToJson(LibraryProgram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'difficulty_level': instance.difficultyLevel,
      'duration_weeks': instance.durationWeeks,
      'sessions_per_week': instance.sessionsPerWeek,
      'session_duration_minutes': instance.sessionDurationMinutes,
      'tags': instance.tags,
      'goals': instance.goals,
      'description': instance.description,
      'short_description': instance.shortDescription,
      'celebrity_name': instance.celebrityName,
    };
