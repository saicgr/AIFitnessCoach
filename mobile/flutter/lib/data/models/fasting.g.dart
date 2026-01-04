// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FastingZoneEntry _$FastingZoneEntryFromJson(Map<String, dynamic> json) =>
    FastingZoneEntry(
      zoneName: json['zone_name'] as String,
      enteredAt: DateTime.parse(json['entered_at'] as String),
      minutesInZone: (json['minutes_in_zone'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FastingZoneEntryToJson(FastingZoneEntry instance) =>
    <String, dynamic>{
      'zone_name': instance.zoneName,
      'entered_at': instance.enteredAt.toIso8601String(),
      'minutes_in_zone': instance.minutesInZone,
    };

FastingRecord _$FastingRecordFromJson(Map<String, dynamic> json) =>
    FastingRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      goalDurationMinutes: (json['goal_duration_minutes'] as num).toInt(),
      actualDurationMinutes: (json['actual_duration_minutes'] as num?)?.toInt(),
      protocol: json['protocol'] as String,
      protocolType: json['protocol_type'] as String,
      status: json['status'] as String? ?? 'active',
      completedGoal: json['completed_goal'] as bool? ?? false,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble(),
      zonesReached: (json['zones_reached'] as List<dynamic>?)
          ?.map((e) => FastingZoneEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      moodBefore: json['mood_before'] as String?,
      moodAfter: json['mood_after'] as String?,
      energyLevelBefore: (json['energy_level_before'] as num?)?.toInt(),
      energyLevelAfter: (json['energy_level_after'] as num?)?.toInt(),
      endedBy: json['ended_by'] as String?,
      breakingMealId: json['breaking_meal_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FastingRecordToJson(FastingRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'goal_duration_minutes': instance.goalDurationMinutes,
      'actual_duration_minutes': instance.actualDurationMinutes,
      'protocol': instance.protocol,
      'protocol_type': instance.protocolType,
      'status': instance.status,
      'completed_goal': instance.completedGoal,
      'completion_percentage': instance.completionPercentage,
      'zones_reached': instance.zonesReached,
      'notes': instance.notes,
      'mood_before': instance.moodBefore,
      'mood_after': instance.moodAfter,
      'energy_level_before': instance.energyLevelBefore,
      'energy_level_after': instance.energyLevelAfter,
      'ended_by': instance.endedBy,
      'breaking_meal_id': instance.breakingMealId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

FastingPreferences _$FastingPreferencesFromJson(Map<String, dynamic> json) =>
    FastingPreferences(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      defaultProtocol: json['default_protocol'] as String? ?? '16:8',
      customFastingHours: (json['custom_fasting_hours'] as num?)?.toInt(),
      customEatingHours: (json['custom_eating_hours'] as num?)?.toInt(),
      typicalFastStartHour:
          (json['typical_fast_start_hour'] as num?)?.toInt() ?? 20,
      typicalEatingStartHour:
          (json['typical_eating_start_hour'] as num?)?.toInt() ?? 12,
      fastingDays: (json['fasting_days'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      notifyZoneTransitions: json['notify_zone_transitions'] as bool? ?? true,
      notifyGoalReached: json['notify_goal_reached'] as bool? ?? true,
      notifyEatingWindowEnd: json['notify_eating_window_end'] as bool? ?? true,
      notifyFastStartReminder:
          json['notify_fast_start_reminder'] as bool? ?? true,
      safetyScreeningCompleted:
          json['safety_screening_completed'] as bool? ?? false,
      safetyWarningsAcknowledged:
          (json['safety_warnings_acknowledged'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      hasMedicalConditions: json['has_medical_conditions'] as bool? ?? false,
      fastingOnboardingCompleted:
          json['fasting_onboarding_completed'] as bool? ?? false,
      onboardingCompletedAt: json['onboarding_completed_at'] == null
          ? null
          : DateTime.parse(json['onboarding_completed_at'] as String),
      experienceLevel: json['experience_level'] as String? ?? 'beginner',
    );

Map<String, dynamic> _$FastingPreferencesToJson(
  FastingPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'default_protocol': instance.defaultProtocol,
  'custom_fasting_hours': instance.customFastingHours,
  'custom_eating_hours': instance.customEatingHours,
  'typical_fast_start_hour': instance.typicalFastStartHour,
  'typical_eating_start_hour': instance.typicalEatingStartHour,
  'fasting_days': instance.fastingDays,
  'notifications_enabled': instance.notificationsEnabled,
  'notify_zone_transitions': instance.notifyZoneTransitions,
  'notify_goal_reached': instance.notifyGoalReached,
  'notify_eating_window_end': instance.notifyEatingWindowEnd,
  'notify_fast_start_reminder': instance.notifyFastStartReminder,
  'safety_screening_completed': instance.safetyScreeningCompleted,
  'safety_warnings_acknowledged': instance.safetyWarningsAcknowledged,
  'has_medical_conditions': instance.hasMedicalConditions,
  'fasting_onboarding_completed': instance.fastingOnboardingCompleted,
  'onboarding_completed_at': instance.onboardingCompletedAt?.toIso8601String(),
  'experience_level': instance.experienceLevel,
};

FastingStreak _$FastingStreakFromJson(
  Map<String, dynamic> json,
) => FastingStreak(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  totalFastsCompleted: (json['total_fasts_completed'] as num?)?.toInt() ?? 0,
  totalFastingMinutes: (json['total_fasting_minutes'] as num?)?.toInt() ?? 0,
  lastFastDate: json['last_fast_date'] == null
      ? null
      : DateTime.parse(json['last_fast_date'] as String),
  streakStartDate: json['streak_start_date'] == null
      ? null
      : DateTime.parse(json['streak_start_date'] as String),
  fastsThisWeek: (json['fasts_this_week'] as num?)?.toInt() ?? 0,
  weekStartDate: json['week_start_date'] == null
      ? null
      : DateTime.parse(json['week_start_date'] as String),
  freezesAvailable: (json['freezes_available'] as num?)?.toInt() ?? 2,
  freezesUsedThisWeek: (json['freezes_used_this_week'] as num?)?.toInt() ?? 0,
  weeklyGoalEnabled: json['weekly_goal_enabled'] as bool? ?? false,
  weeklyGoalFasts: (json['weekly_goal_fasts'] as num?)?.toInt() ?? 5,
);

Map<String, dynamic> _$FastingStreakToJson(FastingStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'total_fasts_completed': instance.totalFastsCompleted,
      'total_fasting_minutes': instance.totalFastingMinutes,
      'last_fast_date': instance.lastFastDate?.toIso8601String(),
      'streak_start_date': instance.streakStartDate?.toIso8601String(),
      'fasts_this_week': instance.fastsThisWeek,
      'week_start_date': instance.weekStartDate?.toIso8601String(),
      'freezes_available': instance.freezesAvailable,
      'freezes_used_this_week': instance.freezesUsedThisWeek,
      'weekly_goal_enabled': instance.weeklyGoalEnabled,
      'weekly_goal_fasts': instance.weeklyGoalFasts,
    };

FastingStats _$FastingStatsFromJson(Map<String, dynamic> json) => FastingStats(
  userId: json['user_id'] as String,
  completedFasts: (json['completed_fasts'] as num?)?.toInt() ?? 0,
  totalFasts: (json['total_fasts'] as num?)?.toInt() ?? 0,
  avgDurationMinutes: (json['avg_duration_minutes'] as num?)?.toDouble() ?? 0,
  longestFastMinutes: (json['longest_fast_minutes'] as num?)?.toInt() ?? 0,
  totalFastingMinutes: (json['total_fasting_minutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FastingStatsToJson(FastingStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'completed_fasts': instance.completedFasts,
      'total_fasts': instance.totalFasts,
      'avg_duration_minutes': instance.avgDurationMinutes,
      'longest_fast_minutes': instance.longestFastMinutes,
      'total_fasting_minutes': instance.totalFastingMinutes,
    };

FastingScore _$FastingScoreFromJson(Map<String, dynamic> json) => FastingScore(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  score: (json['score'] as num).toInt(),
  completionComponent: (json['completion_component'] as num?)?.toDouble() ?? 0,
  streakComponent: (json['streak_component'] as num?)?.toDouble() ?? 0,
  durationComponent: (json['duration_component'] as num?)?.toDouble() ?? 0,
  weeklyComponent: (json['weekly_component'] as num?)?.toDouble() ?? 0,
  protocolComponent: (json['protocol_component'] as num?)?.toDouble() ?? 0,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  fastsThisWeek: (json['fasts_this_week'] as num?)?.toInt() ?? 0,
  weeklyGoal: (json['weekly_goal'] as num?)?.toInt() ?? 5,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
  avgDurationMinutes: (json['avg_duration_minutes'] as num?)?.toInt() ?? 0,
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$FastingScoreToJson(FastingScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'score': instance.score,
      'completion_component': instance.completionComponent,
      'streak_component': instance.streakComponent,
      'duration_component': instance.durationComponent,
      'weekly_component': instance.weeklyComponent,
      'protocol_component': instance.protocolComponent,
      'current_streak': instance.currentStreak,
      'fasts_this_week': instance.fastsThisWeek,
      'weekly_goal': instance.weeklyGoal,
      'completion_rate': instance.completionRate,
      'avg_duration_minutes': instance.avgDurationMinutes,
      'recorded_at': instance.recordedAt?.toIso8601String(),
    };
