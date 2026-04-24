// GENERATED CODE — hand-written to match project convention (no build_runner).
// Mirror of what json_serializable would emit for cardio_log.dart.
// See project_codegen_gotcha.md — do NOT run `flutter pub run build_runner`.

part of 'cardio_log.dart';

// ---------------------------------------------------------------------------
// CardioLog
// ---------------------------------------------------------------------------

CardioLog _$CardioLogFromJson(Map<String, dynamic> json) => CardioLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      performedAt: json['performed_at'] as String,
      activityType: json['activity_type'] as String,
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      sourceApp: json['source_app'] as String,
      createdAt: json['created_at'] as String,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble(),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
      avgPaceSecondsPerKm: (json['avg_pace_seconds_per_km'] as num?)?.toDouble(),
      avgSpeedMps: (json['avg_speed_mps'] as num?)?.toDouble(),
      avgWatts: (json['avg_watts'] as num?)?.toInt(),
      maxWatts: (json['max_watts'] as num?)?.toInt(),
      avgCadence: (json['avg_cadence'] as num?)?.toInt(),
      avgStrokeRate: (json['avg_stroke_rate'] as num?)?.toInt(),
      trainingEffect: (json['training_effect'] as num?)?.toDouble(),
      vo2maxEstimate: (json['vo2max_estimate'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toInt(),
      rpe: (json['rpe'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      gpsPolyline: json['gps_polyline'] as String?,
      splitsJson: (json['splits_json'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      sourceExternalId: json['source_external_id'] as String?,
    );

Map<String, dynamic> _$CardioLogToJson(CardioLog instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'performed_at': instance.performedAt,
      'activity_type': instance.activityType,
      'duration_seconds': instance.durationSeconds,
      'distance_m': instance.distanceM,
      'elevation_gain_m': instance.elevationGainM,
      'avg_heart_rate': instance.avgHeartRate,
      'max_heart_rate': instance.maxHeartRate,
      'avg_pace_seconds_per_km': instance.avgPaceSecondsPerKm,
      'avg_speed_mps': instance.avgSpeedMps,
      'avg_watts': instance.avgWatts,
      'max_watts': instance.maxWatts,
      'avg_cadence': instance.avgCadence,
      'avg_stroke_rate': instance.avgStrokeRate,
      'training_effect': instance.trainingEffect,
      'vo2max_estimate': instance.vo2maxEstimate,
      'calories': instance.calories,
      'rpe': instance.rpe,
      'notes': instance.notes,
      'gps_polyline': instance.gpsPolyline,
      'splits_json': instance.splitsJson,
      'source_app': instance.sourceApp,
      'source_external_id': instance.sourceExternalId,
      'created_at': instance.createdAt,
    };

// ---------------------------------------------------------------------------
// CardioSummary
// ---------------------------------------------------------------------------

CardioSummary _$CardioSummaryFromJson(Map<String, dynamic> json) =>
    CardioSummary(
      userId: json['user_id'] as String,
      totalSessions: (json['total_sessions'] as num).toInt(),
      totalDurationSeconds: (json['total_duration_seconds'] as num).toInt(),
      totalDistanceM: (json['total_distance_m'] as num).toDouble(),
      weeklyDistanceM: (json['weekly_distance_m'] as num).toDouble(),
      weeklySessions: (json['weekly_sessions'] as num).toInt(),
      perActivity: (json['per_activity'] as List<dynamic>)
          .map((e) => CardioTypeSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      longestRunM: (json['longest_run_m'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CardioSummaryToJson(CardioSummary instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'total_sessions': instance.totalSessions,
      'total_duration_seconds': instance.totalDurationSeconds,
      'total_distance_m': instance.totalDistanceM,
      'weekly_distance_m': instance.weeklyDistanceM,
      'weekly_sessions': instance.weeklySessions,
      'longest_run_m': instance.longestRunM,
      'per_activity': instance.perActivity.map((e) => e.toJson()).toList(),
    };

// ---------------------------------------------------------------------------
// CardioTypeSummary
// ---------------------------------------------------------------------------

CardioTypeSummary _$CardioTypeSummaryFromJson(Map<String, dynamic> json) =>
    CardioTypeSummary(
      activityType: json['activity_type'] as String,
      totalSessions: (json['total_sessions'] as num).toInt(),
      totalDurationSeconds: (json['total_duration_seconds'] as num).toInt(),
      totalDistanceM: (json['total_distance_m'] as num).toDouble(),
      maxDistanceM: (json['max_distance_m'] as num).toDouble(),
      maxDurationSeconds: (json['max_duration_seconds'] as num).toInt(),
      fastestPaceSecondsPerKm:
          (json['fastest_pace_seconds_per_km'] as num?)?.toDouble(),
      lastPerformedAt: json['last_performed_at'] as String?,
    );

Map<String, dynamic> _$CardioTypeSummaryToJson(CardioTypeSummary instance) =>
    <String, dynamic>{
      'activity_type': instance.activityType,
      'total_sessions': instance.totalSessions,
      'total_duration_seconds': instance.totalDurationSeconds,
      'total_distance_m': instance.totalDistanceM,
      'max_distance_m': instance.maxDistanceM,
      'max_duration_seconds': instance.maxDurationSeconds,
      'fastest_pace_seconds_per_km': instance.fastestPaceSecondsPerKm,
      'last_performed_at': instance.lastPerformedAt,
    };
