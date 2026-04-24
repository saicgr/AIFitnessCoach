import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cardio_log.g.dart';

/// One row from the `cardio_logs` Supabase table (migration 1965).
///
/// Sibling to the `Workout` model — that one is the planned/completed
/// strength-training workout, this is the per-session cardio record
/// imported from Strava / Peloton / Garmin / Apple Health / Fitbit
/// (and also manual entries).
@JsonSerializable()
class CardioLog extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'performed_at')
  final String performedAt;
  @JsonKey(name: 'activity_type')
  final String activityType;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @JsonKey(name: 'distance_m')
  final double? distanceM;
  @JsonKey(name: 'elevation_gain_m')
  final double? elevationGainM;
  @JsonKey(name: 'avg_heart_rate')
  final int? avgHeartRate;
  @JsonKey(name: 'max_heart_rate')
  final int? maxHeartRate;
  @JsonKey(name: 'avg_pace_seconds_per_km')
  final double? avgPaceSecondsPerKm;
  @JsonKey(name: 'avg_speed_mps')
  final double? avgSpeedMps;
  @JsonKey(name: 'avg_watts')
  final int? avgWatts;
  @JsonKey(name: 'max_watts')
  final int? maxWatts;
  @JsonKey(name: 'avg_cadence')
  final int? avgCadence;
  @JsonKey(name: 'avg_stroke_rate')
  final int? avgStrokeRate;
  @JsonKey(name: 'training_effect')
  final double? trainingEffect;
  @JsonKey(name: 'vo2max_estimate')
  final double? vo2maxEstimate;
  final int? calories;
  final double? rpe;
  final String? notes;
  @JsonKey(name: 'gps_polyline')
  final String? gpsPolyline;
  @JsonKey(name: 'splits_json')
  final List<Map<String, dynamic>>? splitsJson;
  @JsonKey(name: 'source_app')
  final String sourceApp;
  @JsonKey(name: 'source_external_id')
  final String? sourceExternalId;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const CardioLog({
    required this.id,
    required this.userId,
    required this.performedAt,
    required this.activityType,
    required this.durationSeconds,
    required this.sourceApp,
    required this.createdAt,
    this.distanceM,
    this.elevationGainM,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPaceSecondsPerKm,
    this.avgSpeedMps,
    this.avgWatts,
    this.maxWatts,
    this.avgCadence,
    this.avgStrokeRate,
    this.trainingEffect,
    this.vo2maxEstimate,
    this.calories,
    this.rpe,
    this.notes,
    this.gpsPolyline,
    this.splitsJson,
    this.sourceExternalId,
  });

  factory CardioLog.fromJson(Map<String, dynamic> json) =>
      _$CardioLogFromJson(json);

  Map<String, dynamic> toJson() => _$CardioLogToJson(this);

  /// Parsed `performed_at` as a local DateTime. The server stores UTC —
  /// `.toLocal()` converts to the device TZ, which is what users expect
  /// to see in the history list.
  DateTime get performedAtLocal =>
      DateTime.parse(performedAt).toLocal();

  /// Human-readable duration like "1h 23m" or "45m" or "52s".
  String formatDuration() {
    final total = durationSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    if (m > 0) return s > 0 && m < 5 ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
  }

  /// Distance formatted for display. Locale-agnostic (km); the UI
  /// converts to miles when the user's unit preference says so.
  String? formatDistanceKm() {
    if (distanceM == null || distanceM! <= 0) return null;
    final km = distanceM! / 1000.0;
    if (km >= 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(2)} km';
  }

  /// Pace in `min:sec` per km. Only meaningful for run / walk / hike;
  /// returns null for cycling or swimming where speed is the norm.
  String? formatPacePerKm() {
    if (avgPaceSecondsPerKm == null || avgPaceSecondsPerKm! <= 0) return null;
    final total = avgPaceSecondsPerKm!.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  /// Speed in km/h. Preferred for cycling; we omit the unit conversion
  /// from m/s in the backend response so the client does the math.
  String? formatSpeedKmh() {
    if (avgSpeedMps == null || avgSpeedMps! <= 0) return null;
    final kmh = avgSpeedMps! * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Icon hint keyed off activity_type. The cardio history screen maps
  /// these to Material icons; keeping the mapping in the model means a
  /// new activity type lands with a default emoji instead of rendering blank.
  String get iconEmoji {
    switch (activityType) {
      case 'run':
      case 'trail_run':
      case 'treadmill':
        return '🏃';
      case 'walk':
      case 'hike':
        return '🥾';
      case 'cycle':
      case 'indoor_cycle':
      case 'mountain_bike':
      case 'gravel_bike':
        return '🚴';
      case 'row':
      case 'erg':
        return '🚣';
      case 'swim':
      case 'open_water_swim':
        return '🏊';
      case 'elliptical':
      case 'stair':
      case 'stepmill':
        return '🏋️';
      case 'ski_erg':
      case 'skate_ski':
      case 'nordic_ski':
      case 'downhill_ski':
        return '⛷️';
      case 'snowboard':
        return '🏂';
      case 'yoga':
        return '🧘';
      case 'pilates':
        return '🤸';
      case 'hiit':
      case 'boxing':
      case 'kickboxing':
        return '🥊';
      default:
        return '💪';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        performedAt,
        activityType,
        durationSeconds,
        distanceM,
        avgHeartRate,
        sourceApp,
      ];
}

/// Response shape from `GET /cardio-logs/user/{id}/summary`. Used by the
/// cardio history screen header to show PRs / totals at a glance.
@JsonSerializable()
class CardioSummary extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_duration_seconds')
  final int totalDurationSeconds;
  @JsonKey(name: 'total_distance_m')
  final double totalDistanceM;
  @JsonKey(name: 'weekly_distance_m')
  final double weeklyDistanceM;
  @JsonKey(name: 'weekly_sessions')
  final int weeklySessions;
  @JsonKey(name: 'longest_run_m')
  final double? longestRunM;
  @JsonKey(name: 'per_activity')
  final List<CardioTypeSummary> perActivity;

  const CardioSummary({
    required this.userId,
    required this.totalSessions,
    required this.totalDurationSeconds,
    required this.totalDistanceM,
    required this.weeklyDistanceM,
    required this.weeklySessions,
    required this.perActivity,
    this.longestRunM,
  });

  factory CardioSummary.fromJson(Map<String, dynamic> json) =>
      _$CardioSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CardioSummaryToJson(this);

  @override
  List<Object?> get props => [
        userId,
        totalSessions,
        totalDurationSeconds,
        totalDistanceM,
        weeklyDistanceM,
        perActivity,
      ];
}

@JsonSerializable()
class CardioTypeSummary extends Equatable {
  @JsonKey(name: 'activity_type')
  final String activityType;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_duration_seconds')
  final int totalDurationSeconds;
  @JsonKey(name: 'total_distance_m')
  final double totalDistanceM;
  @JsonKey(name: 'max_distance_m')
  final double maxDistanceM;
  @JsonKey(name: 'max_duration_seconds')
  final int maxDurationSeconds;
  @JsonKey(name: 'fastest_pace_seconds_per_km')
  final double? fastestPaceSecondsPerKm;
  @JsonKey(name: 'last_performed_at')
  final String? lastPerformedAt;

  const CardioTypeSummary({
    required this.activityType,
    required this.totalSessions,
    required this.totalDurationSeconds,
    required this.totalDistanceM,
    required this.maxDistanceM,
    required this.maxDurationSeconds,
    this.fastestPaceSecondsPerKm,
    this.lastPerformedAt,
  });

  factory CardioTypeSummary.fromJson(Map<String, dynamic> json) =>
      _$CardioTypeSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CardioTypeSummaryToJson(this);

  @override
  List<Object?> get props => [
        activityType,
        totalSessions,
        totalDurationSeconds,
        totalDistanceM,
        maxDistanceM,
      ];
}
