// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XPEvent _$XPEventFromJson(Map<String, dynamic> json) => XPEvent(
  id: json['id'] as String,
  eventName: json['event_name'] as String,
  eventType: json['event_type'] as String,
  description: json['description'] as String?,
  xpMultiplier: (json['xp_multiplier'] as num).toDouble(),
  startAt: DateTime.parse(json['start_at'] as String),
  endAt: DateTime.parse(json['end_at'] as String),
  iconName: json['icon_name'] as String?,
  bannerColor: json['banner_color'] as String?,
);

Map<String, dynamic> _$XPEventToJson(XPEvent instance) => <String, dynamic>{
  'id': instance.id,
  'event_name': instance.eventName,
  'event_type': instance.eventType,
  'description': instance.description,
  'xp_multiplier': instance.xpMultiplier,
  'start_at': instance.startAt.toIso8601String(),
  'end_at': instance.endAt.toIso8601String(),
  'icon_name': instance.iconName,
  'banner_color': instance.bannerColor,
};

LoginStreakInfo _$LoginStreakInfoFromJson(Map<String, dynamic> json) =>
    LoginStreakInfo(
      currentStreak: (json['current_streak'] as num).toInt(),
      longestStreak: (json['longest_streak'] as num).toInt(),
      totalLogins: (json['total_logins'] as num).toInt(),
      lastLoginDate: json['last_login_date'] as String?,
      firstLoginAt: json['first_login_at'] == null
          ? null
          : DateTime.parse(json['first_login_at'] as String),
      streakStartDate: json['streak_start_date'] as String?,
      hasLoggedInToday: json['has_logged_in_today'] as bool,
    );

Map<String, dynamic> _$LoginStreakInfoToJson(LoginStreakInfo instance) =>
    <String, dynamic>{
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'total_logins': instance.totalLogins,
      'last_login_date': instance.lastLoginDate,
      'first_login_at': instance.firstLoginAt?.toIso8601String(),
      'streak_start_date': instance.streakStartDate,
      'has_logged_in_today': instance.hasLoggedInToday,
    };

DailyLoginResult _$DailyLoginResultFromJson(Map<String, dynamic> json) =>
    DailyLoginResult(
      isFirstLogin: json['is_first_login'] as bool,
      streakBroken: json['streak_broken'] as bool,
      currentStreak: (json['current_streak'] as num).toInt(),
      longestStreak: (json['longest_streak'] as num).toInt(),
      totalLogins: (json['total_logins'] as num).toInt(),
      dailyXp: (json['daily_xp'] as num).toInt(),
      firstLoginXp: (json['first_login_xp'] as num).toInt(),
      streakMilestoneXp: (json['streak_milestone_xp'] as num).toInt(),
      totalXpAwarded: (json['total_xp_awarded'] as num).toInt(),
      activeEvents: (json['active_events'] as List<dynamic>?)
          ?.map((e) => XPEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      multiplier: (json['multiplier'] as num).toDouble(),
      message: json['message'] as String,
      alreadyClaimed: json['already_claimed'] as bool? ?? false,
    );

Map<String, dynamic> _$DailyLoginResultToJson(DailyLoginResult instance) =>
    <String, dynamic>{
      'is_first_login': instance.isFirstLogin,
      'streak_broken': instance.streakBroken,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'total_logins': instance.totalLogins,
      'daily_xp': instance.dailyXp,
      'first_login_xp': instance.firstLoginXp,
      'streak_milestone_xp': instance.streakMilestoneXp,
      'total_xp_awarded': instance.totalXpAwarded,
      'active_events': instance.activeEvents,
      'multiplier': instance.multiplier,
      'message': instance.message,
      'already_claimed': instance.alreadyClaimed,
    };

XPBonusTemplate _$XPBonusTemplateFromJson(Map<String, dynamic> json) =>
    XPBonusTemplate(
      id: json['id'] as String,
      bonusType: json['bonus_type'] as String,
      baseXp: (json['base_xp'] as num).toInt(),
      description: json['description'] as String?,
      streakMultiplier: json['streak_multiplier'] as bool,
      maxStreakMultiplier: (json['max_streak_multiplier'] as num).toInt(),
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$XPBonusTemplateToJson(XPBonusTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bonus_type': instance.bonusType,
      'base_xp': instance.baseXp,
      'description': instance.description,
      'streak_multiplier': instance.streakMultiplier,
      'max_streak_multiplier': instance.maxStreakMultiplier,
      'is_active': instance.isActive,
    };

CheckpointProgress _$CheckpointProgressFromJson(Map<String, dynamic> json) =>
    CheckpointProgress(
      checkpointType: json['checkpoint_type'] as String,
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      checkpointsEarned: (json['checkpoints_earned'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalXpEarned: (json['total_xp_earned'] as num).toInt(),
    );

Map<String, dynamic> _$CheckpointProgressToJson(CheckpointProgress instance) =>
    <String, dynamic>{
      'checkpoint_type': instance.checkpointType,
      'period_start': instance.periodStart,
      'period_end': instance.periodEnd,
      'checkpoints_earned': instance.checkpointsEarned,
      'total_xp_earned': instance.totalXpEarned,
    };
