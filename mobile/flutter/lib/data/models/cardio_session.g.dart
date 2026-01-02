// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioSession _$CardioSessionFromJson(Map<String, dynamic> json) =>
    CardioSession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      cardioType: json['cardio_type'] as String,
      location: json['location'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      avgPacePerKm: (json['avg_pace_per_km'] as num?)?.toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
      elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble(),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
      caloriesBurned: (json['calories_burned'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      weatherConditions: json['weather_conditions'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CardioSessionToJson(CardioSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'workout_id': instance.workoutId,
      'cardio_type': instance.cardioType,
      'location': instance.location,
      'distance_km': instance.distanceKm,
      'duration_minutes': instance.durationMinutes,
      'avg_pace_per_km': instance.avgPacePerKm,
      'avg_speed_kmh': instance.avgSpeedKmh,
      'elevation_gain_m': instance.elevationGainM,
      'avg_heart_rate': instance.avgHeartRate,
      'max_heart_rate': instance.maxHeartRate,
      'calories_burned': instance.caloriesBurned,
      'notes': instance.notes,
      'weather_conditions': instance.weatherConditions,
      'created_at': instance.createdAt?.toIso8601String(),
    };

DailyCardioSummary _$DailyCardioSummaryFromJson(Map<String, dynamic> json) =>
    DailyCardioSummary(
      date: json['date'] as String,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      totalDurationMinutes:
          (json['total_duration_minutes'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => CardioSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyCardioSummaryToJson(DailyCardioSummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_sessions': instance.totalSessions,
      'total_duration_minutes': instance.totalDurationMinutes,
      'total_distance_km': instance.totalDistanceKm,
      'total_calories': instance.totalCalories,
      'avg_heart_rate': instance.avgHeartRate,
      'sessions': instance.sessions,
    };

CardioStats _$CardioStatsFromJson(Map<String, dynamic> json) => CardioStats(
  userId: json['user_id'] as String,
  totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
  totalDurationMinutes: (json['total_duration_minutes'] as num?)?.toInt() ?? 0,
  totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
  totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
  avgSessionDuration: (json['avg_session_duration'] as num?)?.toDouble() ?? 0,
  avgPacePerKm: (json['avg_pace_per_km'] as num?)?.toDouble(),
  bestPacePerKm: (json['best_pace_per_km'] as num?)?.toDouble(),
  longestSessionMinutes:
      (json['longest_session_minutes'] as num?)?.toInt() ?? 0,
  longestDistanceKm: (json['longest_distance_km'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$CardioStatsToJson(CardioStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'total_sessions': instance.totalSessions,
      'total_duration_minutes': instance.totalDurationMinutes,
      'total_distance_km': instance.totalDistanceKm,
      'total_calories': instance.totalCalories,
      'avg_session_duration': instance.avgSessionDuration,
      'avg_pace_per_km': instance.avgPacePerKm,
      'best_pace_per_km': instance.bestPacePerKm,
      'longest_session_minutes': instance.longestSessionMinutes,
      'longest_distance_km': instance.longestDistanceKm,
    };
