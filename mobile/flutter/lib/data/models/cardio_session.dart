import 'package:json_annotation/json_annotation.dart';

part 'cardio_session.g.dart';

/// Cardio activity types
enum CardioType {
  running('running', 'Running'),
  cycling('cycling', 'Cycling'),
  rowing('rowing', 'Rowing'),
  elliptical('elliptical', 'Elliptical'),
  swimming('swimming', 'Swimming'),
  walking('walking', 'Walking');

  final String value;
  final String label;

  const CardioType(this.value, this.label);

  static CardioType fromValue(String value) {
    return CardioType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => CardioType.running,
    );
  }

  /// Get icon name for this cardio type
  String get iconName {
    switch (this) {
      case CardioType.running:
        return 'directions_run';
      case CardioType.cycling:
        return 'directions_bike';
      case CardioType.rowing:
        return 'rowing';
      case CardioType.elliptical:
        return 'fitness_center';
      case CardioType.swimming:
        return 'pool';
      case CardioType.walking:
        return 'directions_walk';
    }
  }
}

/// Location types for cardio sessions
enum CardioLocation {
  indoor('indoor', 'Indoor'),
  outdoor('outdoor', 'Outdoor'),
  treadmill('treadmill', 'Treadmill'),
  track('track', 'Track'),
  trail('trail', 'Trail'),
  pool('pool', 'Pool');

  final String value;
  final String label;

  const CardioLocation(this.value, this.label);

  static CardioLocation fromValue(String value) {
    return CardioLocation.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => CardioLocation.indoor,
    );
  }

  /// Whether this location is considered outdoor
  bool get isOutdoor =>
      this == CardioLocation.outdoor ||
      this == CardioLocation.track ||
      this == CardioLocation.trail;

  /// Get icon name for this location
  String get iconName {
    switch (this) {
      case CardioLocation.indoor:
        return 'home';
      case CardioLocation.outdoor:
        return 'nature_people';
      case CardioLocation.treadmill:
        return 'fitness_center';
      case CardioLocation.track:
        return 'stadium';
      case CardioLocation.trail:
        return 'terrain';
      case CardioLocation.pool:
        return 'pool';
    }
  }
}

/// Weather conditions for outdoor cardio sessions
enum WeatherCondition {
  sunny('sunny', 'Sunny'),
  cloudy('cloudy', 'Cloudy'),
  partlyCloudy('partly_cloudy', 'Partly Cloudy'),
  rainy('rainy', 'Rainy'),
  windy('windy', 'Windy'),
  hot('hot', 'Hot'),
  cold('cold', 'Cold'),
  humid('humid', 'Humid');

  final String value;
  final String label;

  const WeatherCondition(this.value, this.label);

  static WeatherCondition fromValue(String value) {
    return WeatherCondition.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => WeatherCondition.sunny,
    );
  }

  /// Get icon name for this weather condition
  String get iconName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'wb_sunny';
      case WeatherCondition.cloudy:
        return 'cloud';
      case WeatherCondition.partlyCloudy:
        return 'partly_cloudy_day';
      case WeatherCondition.rainy:
        return 'water_drop';
      case WeatherCondition.windy:
        return 'air';
      case WeatherCondition.hot:
        return 'thermostat';
      case WeatherCondition.cold:
        return 'ac_unit';
      case WeatherCondition.humid:
        return 'water';
    }
  }
}

/// Cardio session model
@JsonSerializable()
class CardioSession {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'cardio_type')
  final String cardioType;
  final String location;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'avg_pace_per_km')
  final double? avgPacePerKm;
  @JsonKey(name: 'avg_speed_kmh')
  final double? avgSpeedKmh;
  @JsonKey(name: 'elevation_gain_m')
  final double? elevationGainM;
  @JsonKey(name: 'avg_heart_rate')
  final int? avgHeartRate;
  @JsonKey(name: 'max_heart_rate')
  final int? maxHeartRate;
  @JsonKey(name: 'calories_burned')
  final int? caloriesBurned;
  final String? notes;
  @JsonKey(name: 'weather_conditions')
  final String? weatherConditions;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const CardioSession({
    this.id,
    required this.userId,
    this.workoutId,
    required this.cardioType,
    required this.location,
    this.distanceKm,
    required this.durationMinutes,
    this.avgPacePerKm,
    this.avgSpeedKmh,
    this.elevationGainM,
    this.avgHeartRate,
    this.maxHeartRate,
    this.caloriesBurned,
    this.notes,
    this.weatherConditions,
    this.createdAt,
  });

  factory CardioSession.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);

  /// Get the CardioType enum
  CardioType get type => CardioType.fromValue(cardioType);

  /// Get the CardioLocation enum
  CardioLocation get locationEnum => CardioLocation.fromValue(location);

  /// Get the WeatherCondition enum (if available)
  WeatherCondition? get weather =>
      weatherConditions != null ? WeatherCondition.fromValue(weatherConditions!) : null;

  /// Format duration as string
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  /// Format pace as string (min:sec per km)
  String get formattedPace {
    if (avgPacePerKm == null) return '--:--';
    final totalSeconds = (avgPacePerKm! * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Format distance as string
  String get formattedDistance {
    if (distanceKm == null) return '--';
    return '${distanceKm!.toStringAsFixed(2)} km';
  }

  /// Format speed as string
  String get formattedSpeed {
    if (avgSpeedKmh == null) return '--';
    return '${avgSpeedKmh!.toStringAsFixed(1)} km/h';
  }

  /// Calculate pace from distance and duration
  static double? calculatePace(double? distanceKm, int durationMinutes) {
    if (distanceKm == null || distanceKm <= 0) return null;
    return durationMinutes / distanceKm;
  }

  /// Calculate speed from distance and duration
  static double? calculateSpeed(double? distanceKm, int durationMinutes) {
    if (distanceKm == null || durationMinutes <= 0) return null;
    return distanceKm / (durationMinutes / 60);
  }

  CardioSession copyWith({
    String? id,
    String? userId,
    String? workoutId,
    String? cardioType,
    String? location,
    double? distanceKm,
    int? durationMinutes,
    double? avgPacePerKm,
    double? avgSpeedKmh,
    double? elevationGainM,
    int? avgHeartRate,
    int? maxHeartRate,
    int? caloriesBurned,
    String? notes,
    String? weatherConditions,
    DateTime? createdAt,
  }) {
    return CardioSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      cardioType: cardioType ?? this.cardioType,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      avgPacePerKm: avgPacePerKm ?? this.avgPacePerKm,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Daily cardio summary
@JsonSerializable()
class DailyCardioSummary {
  final String date;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_duration_minutes')
  final int totalDurationMinutes;
  @JsonKey(name: 'total_distance_km')
  final double totalDistanceKm;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  @JsonKey(name: 'avg_heart_rate')
  final int? avgHeartRate;
  final List<CardioSession> sessions;

  const DailyCardioSummary({
    required this.date,
    this.totalSessions = 0,
    this.totalDurationMinutes = 0,
    this.totalDistanceKm = 0,
    this.totalCalories = 0,
    this.avgHeartRate,
    this.sessions = const [],
  });

  factory DailyCardioSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyCardioSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyCardioSummaryToJson(this);
}

/// Cardio statistics
@JsonSerializable()
class CardioStats {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_duration_minutes')
  final int totalDurationMinutes;
  @JsonKey(name: 'total_distance_km')
  final double totalDistanceKm;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  @JsonKey(name: 'avg_session_duration')
  final double avgSessionDuration;
  @JsonKey(name: 'avg_pace_per_km')
  final double? avgPacePerKm;
  @JsonKey(name: 'best_pace_per_km')
  final double? bestPacePerKm;
  @JsonKey(name: 'longest_session_minutes')
  final int longestSessionMinutes;
  @JsonKey(name: 'longest_distance_km')
  final double longestDistanceKm;

  const CardioStats({
    required this.userId,
    this.totalSessions = 0,
    this.totalDurationMinutes = 0,
    this.totalDistanceKm = 0,
    this.totalCalories = 0,
    this.avgSessionDuration = 0,
    this.avgPacePerKm,
    this.bestPacePerKm,
    this.longestSessionMinutes = 0,
    this.longestDistanceKm = 0,
  });

  factory CardioStats.fromJson(Map<String, dynamic> json) =>
      _$CardioStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CardioStatsToJson(this);

  /// Total duration in hours
  double get totalDurationHours => totalDurationMinutes / 60;
}
