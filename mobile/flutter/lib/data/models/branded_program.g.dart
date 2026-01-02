// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branded_program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrandedProgram _$BrandedProgramFromJson(
  Map<String, dynamic> json,
) => BrandedProgram(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String?,
  subcategory: json['subcategory'] as String?,
  difficultyLevel: json['difficulty_level'] as String?,
  durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
  sessionsPerWeek: (json['sessions_per_week'] as num?)?.toInt(),
  sessionDurationMinutes: (json['session_duration_minutes'] as num?)?.toInt(),
  description: json['description'] as String?,
  shortDescription: json['short_description'] as String?,
  imageUrl: json['image_url'] as String?,
  celebrityName: json['celebrity_name'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  goals: (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isFeatured: json['is_featured'] as bool?,
  isPopular: json['is_popular'] as bool?,
  isPremium: json['is_premium'] as bool?,
  requiresGym: json['requires_gym'] as bool?,
  iconName: json['icon_name'] as String?,
  colorHex: json['color_hex'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$BrandedProgramToJson(BrandedProgram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'difficulty_level': instance.difficultyLevel,
      'duration_weeks': instance.durationWeeks,
      'sessions_per_week': instance.sessionsPerWeek,
      'session_duration_minutes': instance.sessionDurationMinutes,
      'description': instance.description,
      'short_description': instance.shortDescription,
      'image_url': instance.imageUrl,
      'celebrity_name': instance.celebrityName,
      'tags': instance.tags,
      'goals': instance.goals,
      'is_featured': instance.isFeatured,
      'is_popular': instance.isPopular,
      'is_premium': instance.isPremium,
      'requires_gym': instance.requiresGym,
      'icon_name': instance.iconName,
      'color_hex': instance.colorHex,
      'created_at': instance.createdAt,
    };

UserProgram _$UserProgramFromJson(Map<String, dynamic> json) => UserProgram(
  userId: json['user_id'] as String,
  programId: json['program_id'] as String,
  customName: json['custom_name'] as String?,
  startedAt: json['started_at'] as String?,
  currentWeek: (json['current_week'] as num?)?.toInt(),
  isActive: json['is_active'] as bool?,
  program: json['program'] == null
      ? null
      : BrandedProgram.fromJson(json['program'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserProgramToJson(UserProgram instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'program_id': instance.programId,
      'custom_name': instance.customName,
      'started_at': instance.startedAt,
      'current_week': instance.currentWeek,
      'is_active': instance.isActive,
      'program': instance.program,
    };
