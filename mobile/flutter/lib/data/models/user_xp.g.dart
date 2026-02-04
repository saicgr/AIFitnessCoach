// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_xp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserXP _$UserXPFromJson(Map<String, dynamic> json) => UserXP(
  id: json['id'] as String? ?? '',
  userId: json['user_id'] as String? ?? '',
  totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
  currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
  xpToNextLevel: (json['xp_to_next_level'] as num?)?.toInt() ?? 25,
  xpInCurrentLevel: (json['xp_in_current_level'] as num?)?.toInt() ?? 0,
  prestigeLevel: (json['prestige_level'] as num?)?.toInt() ?? 0,
  title: json['title'] as String? ?? 'Beginner',
  trustLevel: (json['trust_level'] as num?)?.toInt() ?? 1,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserXPToJson(UserXP instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'total_xp': instance.totalXp,
  'current_level': instance.currentLevel,
  'xp_to_next_level': instance.xpToNextLevel,
  'xp_in_current_level': instance.xpInCurrentLevel,
  'prestige_level': instance.prestigeLevel,
  'title': instance.title,
  'trust_level': instance.trustLevel,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

XPTransaction _$XPTransactionFromJson(Map<String, dynamic> json) =>
    XPTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      xpAmount: (json['xp_amount'] as num).toInt(),
      source: json['source'] as String,
      sourceId: json['source_id'] as String?,
      description: json['description'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$XPTransactionToJson(XPTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'xp_amount': instance.xpAmount,
      'source': instance.source,
      'source_id': instance.sourceId,
      'description': instance.description,
      'is_verified': instance.isVerified,
      'created_at': instance.createdAt.toIso8601String(),
    };

XPSummary _$XPSummaryFromJson(Map<String, dynamic> json) => XPSummary(
  totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
  currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
  title: json['title'] as String? ?? 'Beginner',
  xpToNextLevel: (json['xp_to_next_level'] as num?)?.toInt() ?? 25,
  xpInCurrentLevel: (json['xp_in_current_level'] as num?)?.toInt() ?? 0,
  progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
  prestigeLevel: (json['prestige_level'] as num?)?.toInt() ?? 0,
  trustLevel: (json['trust_level'] as num?)?.toInt() ?? 1,
  rankPosition: (json['rank_position'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$XPSummaryToJson(XPSummary instance) => <String, dynamic>{
  'total_xp': instance.totalXp,
  'current_level': instance.currentLevel,
  'title': instance.title,
  'xp_to_next_level': instance.xpToNextLevel,
  'xp_in_current_level': instance.xpInCurrentLevel,
  'progress_percent': instance.progressPercent,
  'prestige_level': instance.prestigeLevel,
  'trust_level': instance.trustLevel,
  'rank_position': instance.rankPosition,
};

XPLeaderboardEntry _$XPLeaderboardEntryFromJson(Map<String, dynamic> json) =>
    XPLeaderboardEntry(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Beginner',
      prestigeLevel: (json['prestige_level'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$XPLeaderboardEntryToJson(XPLeaderboardEntry instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'total_xp': instance.totalXp,
      'current_level': instance.currentLevel,
      'title': instance.title,
      'prestige_level': instance.prestigeLevel,
      'rank': instance.rank,
    };

LevelUpEvent _$LevelUpEventFromJson(Map<String, dynamic> json) => LevelUpEvent(
  newLevel: (json['new_level'] as num).toInt(),
  oldLevel: (json['old_level'] as num).toInt(),
  newTitle: json['new_title'] as String?,
  oldTitle: json['old_title'] as String?,
  totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
  xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
  unlockedReward: json['unlocked_reward'] as String?,
);

Map<String, dynamic> _$LevelUpEventToJson(LevelUpEvent instance) =>
    <String, dynamic>{
      'new_level': instance.newLevel,
      'old_level': instance.oldLevel,
      'new_title': instance.newTitle,
      'old_title': instance.oldTitle,
      'total_xp': instance.totalXp,
      'xp_earned': instance.xpEarned,
      'unlocked_reward': instance.unlockedReward,
    };
