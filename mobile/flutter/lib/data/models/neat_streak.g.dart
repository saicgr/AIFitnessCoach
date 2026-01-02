// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_streak.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatStreak _$NeatStreakFromJson(Map<String, dynamic> json) => NeatStreak(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  streakType: $enumDecode(_$NeatStreakTypeEnumMap, json['streak_type']),
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  lastAchievementDate: json['last_achievement_date'] as String?,
  streakStartDate: json['streak_start_date'] as String?,
  isActive: json['is_active'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NeatStreakToJson(NeatStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'streak_type': _$NeatStreakTypeEnumMap[instance.streakType]!,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'last_achievement_date': instance.lastAchievementDate,
      'streak_start_date': instance.streakStartDate,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$NeatStreakTypeEnumMap = {
  NeatStreakType.steps: 'steps',
  NeatStreakType.activeHours: 'active_hours',
  NeatStreakType.neatScore: 'neat_score',
};

NeatStreakSummary _$NeatStreakSummaryFromJson(Map<String, dynamic> json) =>
    NeatStreakSummary(
      userId: json['user_id'] as String,
      streaks:
          (json['streaks'] as List<dynamic>?)
              ?.map((e) => NeatStreak.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bestActiveStreak: json['best_active_streak'] == null
          ? null
          : NeatStreak.fromJson(
              json['best_active_streak'] as Map<String, dynamic>,
            ),
      totalStreakDays: (json['total_streak_days'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NeatStreakSummaryToJson(NeatStreakSummary instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'streaks': instance.streaks,
      'best_active_streak': instance.bestActiveStreak,
      'total_streak_days': instance.totalStreakDays,
    };

NeatStreakMilestone _$NeatStreakMilestoneFromJson(Map<String, dynamic> json) =>
    NeatStreakMilestone(
      days: (json['days'] as num).toInt(),
      streakType: $enumDecode(_$NeatStreakTypeEnumMap, json['streak_type']),
      name: json['name'] as String,
      icon: json['icon'] as String?,
      achievedAt: json['achieved_at'] == null
          ? null
          : DateTime.parse(json['achieved_at'] as String),
    );

Map<String, dynamic> _$NeatStreakMilestoneToJson(
  NeatStreakMilestone instance,
) => <String, dynamic>{
  'days': instance.days,
  'streak_type': _$NeatStreakTypeEnumMap[instance.streakType]!,
  'name': instance.name,
  'icon': instance.icon,
  'achieved_at': instance.achievedAt?.toIso8601String(),
};
