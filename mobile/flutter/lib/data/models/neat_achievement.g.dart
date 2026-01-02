// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatAchievement _$NeatAchievementFromJson(Map<String, dynamic> json) =>
    NeatAchievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      requirementType: $enumDecode(
        _$NeatAchievementRequirementTypeEnumMap,
        json['requirement_type'],
      ),
      requirementValue: (json['requirement_value'] as num).toDouble(),
      tier:
          $enumDecodeNullable(_$NeatAchievementTierEnumMap, json['tier']) ??
          NeatAchievementTier.bronze,
      points: (json['points'] as num?)?.toInt() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      shareMessage: json['share_message'] as String?,
    );

Map<String, dynamic> _$NeatAchievementToJson(NeatAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'requirement_type':
          _$NeatAchievementRequirementTypeEnumMap[instance.requirementType]!,
      'requirement_value': instance.requirementValue,
      'tier': _$NeatAchievementTierEnumMap[instance.tier]!,
      'points': instance.points,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'share_message': instance.shareMessage,
    };

const _$NeatAchievementRequirementTypeEnumMap = {
  NeatAchievementRequirementType.totalSteps: 'total_steps',
  NeatAchievementRequirementType.dailySteps: 'daily_steps',
  NeatAchievementRequirementType.stepStreak: 'step_streak',
  NeatAchievementRequirementType.activeHoursStreak: 'active_hours_streak',
  NeatAchievementRequirementType.neatScoreStreak: 'neat_score_streak',
  NeatAchievementRequirementType.averageNeatScore: 'average_neat_score',
  NeatAchievementRequirementType.totalActiveHours: 'total_active_hours',
  NeatAchievementRequirementType.goalAchievements: 'goal_achievements',
  NeatAchievementRequirementType.distanceKm: 'distance_km',
  NeatAchievementRequirementType.perfectWeeks: 'perfect_weeks',
};

const _$NeatAchievementTierEnumMap = {
  NeatAchievementTier.bronze: 'bronze',
  NeatAchievementTier.silver: 'silver',
  NeatAchievementTier.gold: 'gold',
  NeatAchievementTier.platinum: 'platinum',
  NeatAchievementTier.diamond: 'diamond',
};

UserNeatAchievement _$UserNeatAchievementFromJson(Map<String, dynamic> json) =>
    UserNeatAchievement(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      achievement: NeatAchievement.fromJson(
        json['achievement'] as Map<String, dynamic>,
      ),
      achievedAt: json['achieved_at'] == null
          ? null
          : DateTime.parse(json['achieved_at'] as String),
      currentProgress: (json['current_progress'] as num?)?.toDouble() ?? 0.0,
      isNotified: json['is_notified'] as bool? ?? false,
      isCelebrated: json['is_celebrated'] as bool? ?? false,
      sharedAt: json['shared_at'] == null
          ? null
          : DateTime.parse(json['shared_at'] as String),
    );

Map<String, dynamic> _$UserNeatAchievementToJson(
  UserNeatAchievement instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'achievement': instance.achievement,
  'achieved_at': instance.achievedAt?.toIso8601String(),
  'current_progress': instance.currentProgress,
  'is_notified': instance.isNotified,
  'is_celebrated': instance.isCelebrated,
  'shared_at': instance.sharedAt?.toIso8601String(),
};

NeatAchievementsSummary _$NeatAchievementsSummaryFromJson(
  Map<String, dynamic> json,
) => NeatAchievementsSummary(
  userId: json['user_id'] as String,
  earnedAchievements:
      (json['earned_achievements'] as List<dynamic>?)
          ?.map((e) => UserNeatAchievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  upcomingAchievements:
      (json['upcoming_achievements'] as List<dynamic>?)
          ?.map((e) => UserNeatAchievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
  totalEarned: (json['total_earned'] as num?)?.toInt() ?? 0,
  totalAvailable: (json['total_available'] as num?)?.toInt() ?? 0,
  recentAchievement: json['recent_achievement'] == null
      ? null
      : UserNeatAchievement.fromJson(
          json['recent_achievement'] as Map<String, dynamic>,
        ),
  nextAchievement: json['next_achievement'] == null
      ? null
      : UserNeatAchievement.fromJson(
          json['next_achievement'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$NeatAchievementsSummaryToJson(
  NeatAchievementsSummary instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'earned_achievements': instance.earnedAchievements,
  'upcoming_achievements': instance.upcomingAchievements,
  'total_points': instance.totalPoints,
  'total_earned': instance.totalEarned,
  'total_available': instance.totalAvailable,
  'recent_achievement': instance.recentAchievement,
  'next_achievement': instance.nextAchievement,
};

NewNeatAchievement _$NewNeatAchievementFromJson(Map<String, dynamic> json) =>
    NewNeatAchievement(
      achievement: NeatAchievement.fromJson(
        json['achievement'] as Map<String, dynamic>,
      ),
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      triggerValue: (json['trigger_value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$NewNeatAchievementToJson(NewNeatAchievement instance) =>
    <String, dynamic>{
      'achievement': instance.achievement,
      'achieved_at': instance.achievedAt.toIso8601String(),
      'trigger_value': instance.triggerValue,
    };
