// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sauna_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaunaLog _$SaunaLogFromJson(Map<String, dynamic> json) => SaunaLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  workoutId: json['workout_id'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  estimatedCalories: (json['estimated_calories'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  loggedAt: json['logged_at'] == null
      ? null
      : DateTime.parse(json['logged_at'] as String),
);

Map<String, dynamic> _$SaunaLogToJson(SaunaLog instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'workout_id': instance.workoutId,
  'duration_minutes': instance.durationMinutes,
  'estimated_calories': instance.estimatedCalories,
  'notes': instance.notes,
  'logged_at': instance.loggedAt?.toIso8601String(),
};

DailySaunaSummary _$DailySaunaSummaryFromJson(Map<String, dynamic> json) =>
    DailySaunaSummary(
      date: json['date'] as String,
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => SaunaLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailySaunaSummaryToJson(DailySaunaSummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_minutes': instance.totalMinutes,
      'total_calories': instance.totalCalories,
      'entries': instance.entries,
    };
