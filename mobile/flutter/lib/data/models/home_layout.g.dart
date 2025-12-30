// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_layout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeTile _$HomeTileFromJson(Map<String, dynamic> json) => HomeTile(
  id: json['id'] as String,
  type: $enumDecode(_$TileTypeEnumMap, json['type']),
  size: $enumDecode(_$TileSizeEnumMap, json['size']),
  order: (json['order'] as num).toInt(),
  isVisible: json['is_visible'] as bool? ?? true,
);

Map<String, dynamic> _$HomeTileToJson(HomeTile instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$TileTypeEnumMap[instance.type]!,
  'size': _$TileSizeEnumMap[instance.size]!,
  'order': instance.order,
  'is_visible': instance.isVisible,
};

const _$TileTypeEnumMap = {
  TileType.nextWorkout: 'nextWorkout',
  TileType.fitnessScore: 'fitnessScore',
  TileType.moodPicker: 'moodPicker',
  TileType.dailyActivity: 'dailyActivity',
  TileType.quickActions: 'quickActions',
  TileType.weeklyProgress: 'weeklyProgress',
  TileType.weeklyGoals: 'weeklyGoals',
  TileType.weekChanges: 'weekChanges',
  TileType.upcomingFeatures: 'upcomingFeatures',
  TileType.upcomingWorkouts: 'upcomingWorkouts',
  TileType.streakCounter: 'streakCounter',
  TileType.personalRecords: 'personalRecords',
  TileType.aiCoachTip: 'aiCoachTip',
  TileType.challengeProgress: 'challengeProgress',
  TileType.caloriesSummary: 'caloriesSummary',
  TileType.macroRings: 'macroRings',
  TileType.bodyWeight: 'bodyWeight',
  TileType.progressPhoto: 'progressPhoto',
  TileType.socialFeed: 'socialFeed',
  TileType.leaderboardRank: 'leaderboardRank',
  TileType.fasting: 'fasting',
  TileType.weeklyCalendar: 'weeklyCalendar',
  TileType.muscleHeatmap: 'muscleHeatmap',
  TileType.sleepScore: 'sleepScore',
  TileType.restDayTip: 'restDayTip',
};

const _$TileSizeEnumMap = {
  TileSize.full: 'full',
  TileSize.half: 'half',
  TileSize.compact: 'compact',
};

HomeLayout _$HomeLayoutFromJson(Map<String, dynamic> json) => HomeLayout(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  tiles: (json['tiles'] as List<dynamic>)
      .map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
      .toList(),
  isActive: json['is_active'] as bool? ?? false,
  templateId: json['template_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$HomeLayoutToJson(HomeLayout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'tiles': instance.tiles,
      'is_active': instance.isActive,
      'template_id': instance.templateId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

HomeLayoutTemplate _$HomeLayoutTemplateFromJson(Map<String, dynamic> json) =>
    HomeLayoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tiles: (json['tiles'] as List<dynamic>)
          .map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
          .toList(),
      icon: json['icon'] as String?,
      category: json['category'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$HomeLayoutTemplateToJson(HomeLayoutTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'tiles': instance.tiles,
      'icon': instance.icon,
      'category': instance.category,
      'created_at': instance.createdAt?.toIso8601String(),
    };

CreateLayoutRequest _$CreateLayoutRequestFromJson(Map<String, dynamic> json) =>
    CreateLayoutRequest(
      name: json['name'] as String,
      tiles: (json['tiles'] as List<dynamic>)
          .map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
          .toList(),
      templateId: json['template_id'] as String?,
    );

Map<String, dynamic> _$CreateLayoutRequestToJson(
  CreateLayoutRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'tiles': instance.tiles,
  'template_id': instance.templateId,
};

UpdateLayoutRequest _$UpdateLayoutRequestFromJson(Map<String, dynamic> json) =>
    UpdateLayoutRequest(
      name: json['name'] as String?,
      tiles: (json['tiles'] as List<dynamic>?)
          ?.map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateLayoutRequestToJson(
  UpdateLayoutRequest instance,
) => <String, dynamic>{'name': instance.name, 'tiles': instance.tiles};
