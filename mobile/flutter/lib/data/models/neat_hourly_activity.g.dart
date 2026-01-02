// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_hourly_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatHourlyActivity _$NeatHourlyActivityFromJson(Map<String, dynamic> json) =>
    NeatHourlyActivity(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      activityDate: json['activity_date'] as String,
      hour: (json['hour'] as num).toInt(),
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      isSedentary: json['is_sedentary'] as bool? ?? false,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      source:
          $enumDecodeNullable(_$NeatActivitySourceEnumMap, json['source']) ??
          NeatActivitySource.healthKit,
      activeMinutes: (json['active_minutes'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$NeatHourlyActivityToJson(NeatHourlyActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'activity_date': instance.activityDate,
      'hour': instance.hour,
      'steps': instance.steps,
      'is_sedentary': instance.isSedentary,
      'reminder_sent': instance.reminderSent,
      'source': _$NeatActivitySourceEnumMap[instance.source]!,
      'active_minutes': instance.activeMinutes,
      'distance_meters': instance.distanceMeters,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$NeatActivitySourceEnumMap = {
  NeatActivitySource.healthKit: 'health_kit',
  NeatActivitySource.googleFit: 'google_fit',
  NeatActivitySource.manual: 'manual',
  NeatActivitySource.watch: 'watch',
  NeatActivitySource.pedometer: 'pedometer',
};

NeatHourlyBreakdown _$NeatHourlyBreakdownFromJson(Map<String, dynamic> json) =>
    NeatHourlyBreakdown(
      userId: json['user_id'] as String,
      date: json['date'] as String,
      hourlyActivities:
          (json['hourly_activities'] as List<dynamic>?)
              ?.map(
                (e) => NeatHourlyActivity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      stepGoal: (json['step_goal'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NeatHourlyBreakdownToJson(
  NeatHourlyBreakdown instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'date': instance.date,
  'hourly_activities': instance.hourlyActivities,
  'step_goal': instance.stepGoal,
};

NeatHourlyPatternSummary _$NeatHourlyPatternSummaryFromJson(
  Map<String, dynamic> json,
) => NeatHourlyPatternSummary(
  userId: json['user_id'] as String,
  mostActiveHours:
      (json['most_active_hours'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  leastActiveHours:
      (json['least_active_hours'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  averageStepsByHour:
      (json['average_steps_by_hour'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  sedentaryPattern: json['sedentary_pattern'] as String?,
  recommendation: json['recommendation'] as String?,
);

Map<String, dynamic> _$NeatHourlyPatternSummaryToJson(
  NeatHourlyPatternSummary instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'most_active_hours': instance.mostActiveHours,
  'least_active_hours': instance.leastActiveHours,
  'average_steps_by_hour': instance.averageStepsByHour,
  'sedentary_pattern': instance.sedentaryPattern,
  'recommendation': instance.recommendation,
};
