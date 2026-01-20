// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trophy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trophy _$TrophyFromJson(Map<String, dynamic> json) => Trophy(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  icon: json['icon'] as String,
  tier: json['tier'] as String,
  tierLevel: (json['tier_level'] as num?)?.toInt() ?? 1,
  points: (json['points'] as num).toInt(),
  thresholdValue: (json['threshold_value'] as num?)?.toDouble(),
  thresholdUnit: json['threshold_unit'] as String?,
  xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
  isSecret: json['is_secret'] as bool? ?? false,
  isHidden: json['is_hidden'] as bool? ?? false,
  hintText: json['hint_text'] as String?,
  merchReward: json['merch_reward'] as String?,
  unlockAnimation: json['unlock_animation'] as String? ?? 'standard',
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  parentAchievementId: json['parent_achievement_id'] as String?,
  rarity: json['rarity'] as String? ?? 'common',
);

Map<String, dynamic> _$TrophyToJson(Trophy instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'icon': instance.icon,
  'tier': instance.tier,
  'tier_level': instance.tierLevel,
  'points': instance.points,
  'threshold_value': instance.thresholdValue,
  'threshold_unit': instance.thresholdUnit,
  'xp_reward': instance.xpReward,
  'is_secret': instance.isSecret,
  'is_hidden': instance.isHidden,
  'hint_text': instance.hintText,
  'merch_reward': instance.merchReward,
  'unlock_animation': instance.unlockAnimation,
  'sort_order': instance.sortOrder,
  'parent_achievement_id': instance.parentAchievementId,
  'rarity': instance.rarity,
};

UserTrophy _$UserTrophyFromJson(Map<String, dynamic> json) => UserTrophy(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  achievementId: json['achievement_id'] as String,
  earnedAt: DateTime.parse(json['earned_at'] as String),
  triggerValue: (json['trigger_value'] as num?)?.toDouble(),
  triggerDetails: json['trigger_details'] as Map<String, dynamic>?,
  isNotified: json['is_notified'] as bool? ?? false,
  trophy: json['trophy'] == null
      ? null
      : Trophy.fromJson(json['trophy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserTrophyToJson(UserTrophy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'achievement_id': instance.achievementId,
      'earned_at': instance.earnedAt.toIso8601String(),
      'trigger_value': instance.triggerValue,
      'trigger_details': instance.triggerDetails,
      'is_notified': instance.isNotified,
      'trophy': instance.trophy,
    };

TrophyProgress _$TrophyProgressFromJson(Map<String, dynamic> json) =>
    TrophyProgress(
      trophy: Trophy.fromJson(json['trophy'] as Map<String, dynamic>),
      isEarned: json['is_earned'] as bool? ?? false,
      earnedAt: json['earned_at'] == null
          ? null
          : DateTime.parse(json['earned_at'] as String),
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$TrophyProgressToJson(TrophyProgress instance) =>
    <String, dynamic>{
      'trophy': instance.trophy,
      'is_earned': instance.isEarned,
      'earned_at': instance.earnedAt?.toIso8601String(),
      'current_value': instance.currentValue,
      'progress_percentage': instance.progressPercentage,
    };

TrophyRoomSummary _$TrophyRoomSummaryFromJson(Map<String, dynamic> json) =>
    TrophyRoomSummary(
      totalTrophies: (json['total_trophies'] as num?)?.toInt() ?? 0,
      earnedTrophies: (json['earned_trophies'] as num?)?.toInt() ?? 0,
      lockedTrophies: (json['locked_trophies'] as num?)?.toInt() ?? 0,
      secretDiscovered: (json['secret_discovered'] as num?)?.toInt() ?? 0,
      totalSecret: (json['total_secret'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      byTier:
          (json['by_tier'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      byCategory:
          (json['by_category'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$TrophyRoomSummaryToJson(TrophyRoomSummary instance) =>
    <String, dynamic>{
      'total_trophies': instance.totalTrophies,
      'earned_trophies': instance.earnedTrophies,
      'locked_trophies': instance.lockedTrophies,
      'secret_discovered': instance.secretDiscovered,
      'total_secret': instance.totalSecret,
      'total_points': instance.totalPoints,
      'by_tier': instance.byTier,
      'by_category': instance.byCategory,
    };

WorldRecord _$WorldRecordFromJson(Map<String, dynamic> json) => WorldRecord(
  id: json['id'] as String,
  recordType: json['record_type'] as String,
  recordCategory: json['record_category'] as String,
  recordName: json['record_name'] as String,
  currentHolderId: json['current_holder_id'] as String?,
  currentHolderName: json['current_holder_name'] as String?,
  recordValue: (json['record_value'] as num).toDouble(),
  recordUnit: json['record_unit'] as String,
  achievedAt: json['achieved_at'] == null
      ? null
      : DateTime.parse(json['achieved_at'] as String),
  previousRecord: (json['previous_record'] as num?)?.toDouble(),
  isVerified: json['is_verified'] as bool? ?? false,
);

Map<String, dynamic> _$WorldRecordToJson(WorldRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'record_type': instance.recordType,
      'record_category': instance.recordCategory,
      'record_name': instance.recordName,
      'current_holder_id': instance.currentHolderId,
      'current_holder_name': instance.currentHolderName,
      'record_value': instance.recordValue,
      'record_unit': instance.recordUnit,
      'achieved_at': instance.achievedAt?.toIso8601String(),
      'previous_record': instance.previousRecord,
      'is_verified': instance.isVerified,
    };

FormerChampion _$FormerChampionFromJson(Map<String, dynamic> json) =>
    FormerChampion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recordType: json['record_type'] as String,
      recordName: json['record_name'] as String,
      peakValue: (json['peak_value'] as num).toDouble(),
      heldFrom: DateTime.parse(json['held_from'] as String),
      heldUntil: DateTime.parse(json['held_until'] as String),
      daysHeld: (json['days_held'] as num).toInt(),
    );

Map<String, dynamic> _$FormerChampionToJson(FormerChampion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'record_type': instance.recordType,
      'record_name': instance.recordName,
      'peak_value': instance.peakValue,
      'held_from': instance.heldFrom.toIso8601String(),
      'held_until': instance.heldUntil.toIso8601String(),
      'days_held': instance.daysHeld,
    };
