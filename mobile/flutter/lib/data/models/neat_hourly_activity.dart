/// NEAT hourly activity tracking models.
///
/// These models support:
/// - Hourly step and activity tracking
/// - Sedentary detection
/// - Movement reminder tracking
/// - Daily activity breakdown with analytics
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_hourly_activity.g.dart';

/// Source of the activity data
enum NeatActivitySource {
  @JsonValue('health_kit')
  healthKit,
  @JsonValue('google_fit')
  googleFit,
  @JsonValue('manual')
  manual,
  @JsonValue('watch')
  watch,
  @JsonValue('pedometer')
  pedometer;

  String get displayName {
    switch (this) {
      case NeatActivitySource.healthKit:
        return 'Apple Health';
      case NeatActivitySource.googleFit:
        return 'Google Fit';
      case NeatActivitySource.manual:
        return 'Manual Entry';
      case NeatActivitySource.watch:
        return 'Smart Watch';
      case NeatActivitySource.pedometer:
        return 'Pedometer';
    }
  }
}

/// Single hour of activity data
@JsonSerializable()
class NeatHourlyActivity {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'activity_date')
  final String activityDate;

  final int hour;

  final int steps;

  @JsonKey(name: 'is_sedentary')
  final bool isSedentary;

  @JsonKey(name: 'reminder_sent')
  final bool reminderSent;

  final NeatActivitySource source;

  @JsonKey(name: 'active_minutes')
  final int? activeMinutes;

  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const NeatHourlyActivity({
    this.id,
    required this.userId,
    required this.activityDate,
    required this.hour,
    this.steps = 0,
    this.isSedentary = false,
    this.reminderSent = false,
    this.source = NeatActivitySource.healthKit,
    this.activeMinutes,
    this.distanceMeters,
    this.createdAt,
  });

  factory NeatHourlyActivity.fromJson(Map<String, dynamic> json) =>
      _$NeatHourlyActivityFromJson(json);

  Map<String, dynamic> toJson() => _$NeatHourlyActivityToJson(this);

  /// Get the date as DateTime
  DateTime get date => DateTime.parse(activityDate);

  /// Get a formatted hour label (e.g., "9 AM", "2 PM")
  String get hourLabel {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  /// Whether this hour is considered active (not sedentary)
  bool get isActive => !isSedentary && steps > 0;

  /// Create a copy with updated values
  NeatHourlyActivity copyWith({
    String? id,
    String? userId,
    String? activityDate,
    int? hour,
    int? steps,
    bool? isSedentary,
    bool? reminderSent,
    NeatActivitySource? source,
    int? activeMinutes,
    double? distanceMeters,
    DateTime? createdAt,
  }) {
    return NeatHourlyActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityDate: activityDate ?? this.activityDate,
      hour: hour ?? this.hour,
      steps: steps ?? this.steps,
      isSedentary: isSedentary ?? this.isSedentary,
      reminderSent: reminderSent ?? this.reminderSent,
      source: source ?? this.source,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Complete hourly breakdown for a day
@JsonSerializable()
class NeatHourlyBreakdown {
  @JsonKey(name: 'user_id')
  final String userId;

  final String date;

  @JsonKey(name: 'hourly_activities')
  final List<NeatHourlyActivity> hourlyActivities;

  @JsonKey(name: 'step_goal')
  final int? stepGoal;

  const NeatHourlyBreakdown({
    required this.userId,
    required this.date,
    this.hourlyActivities = const [],
    this.stepGoal,
  });

  factory NeatHourlyBreakdown.fromJson(Map<String, dynamic> json) =>
      _$NeatHourlyBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$NeatHourlyBreakdownToJson(this);

  /// Total steps for the day
  int get totalSteps => hourlyActivities.fold(0, (sum, h) => sum + h.steps);

  /// Number of active hours (hours with steps > threshold)
  int get activeHours => hourlyActivities.where((h) => !h.isSedentary).length;

  /// Number of sedentary hours
  int get sedentaryHours => hourlyActivities.where((h) => h.isSedentary).length;

  /// Total active minutes
  int get totalActiveMinutes => hourlyActivities
      .where((h) => h.activeMinutes != null)
      .fold(0, (sum, h) => sum + (h.activeMinutes ?? 0));

  /// Total distance in meters
  double get totalDistanceMeters => hourlyActivities
      .where((h) => h.distanceMeters != null)
      .fold(0.0, (sum, h) => sum + (h.distanceMeters ?? 0.0));

  /// Total distance in kilometers
  double get totalDistanceKm => totalDistanceMeters / 1000;

  /// Total distance in miles
  double get totalDistanceMiles => totalDistanceMeters / 1609.34;

  /// Average steps per active hour
  double get averageStepsPerActiveHour {
    if (activeHours == 0) return 0;
    return totalSteps / activeHours;
  }

  /// Peak hour (hour with most steps)
  NeatHourlyActivity? get peakHour {
    if (hourlyActivities.isEmpty) return null;
    return hourlyActivities.reduce((a, b) => a.steps >= b.steps ? a : b);
  }

  /// Hours when reminders were sent
  List<NeatHourlyActivity> get hoursWithReminders =>
      hourlyActivities.where((h) => h.reminderSent).toList();

  /// Progress toward step goal (0.0 to 1.0)
  double get goalProgress {
    if (stepGoal == null || stepGoal == 0) return 0.0;
    return (totalSteps / stepGoal!).clamp(0.0, 1.0);
  }

  /// Whether the step goal was achieved
  bool get goalAchieved => stepGoal != null && totalSteps >= stepGoal!;

  /// Get activity data for a specific hour
  NeatHourlyActivity? activityForHour(int hour) {
    try {
      return hourlyActivities.firstWhere((h) => h.hour == hour);
    } catch (_) {
      return null;
    }
  }

  /// Get date as DateTime
  DateTime get dateTime => DateTime.parse(date);

  /// Check if there's a sedentary stretch (consecutive sedentary hours)
  int get longestSedentaryStretch {
    int maxStretch = 0;
    int currentStretch = 0;

    final sorted = [...hourlyActivities]..sort((a, b) => a.hour.compareTo(b.hour));

    for (final activity in sorted) {
      if (activity.isSedentary) {
        currentStretch++;
        if (currentStretch > maxStretch) {
          maxStretch = currentStretch;
        }
      } else {
        currentStretch = 0;
      }
    }

    return maxStretch;
  }
}

/// Summary of hourly activity patterns
@JsonSerializable()
class NeatHourlyPatternSummary {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'most_active_hours')
  final List<int> mostActiveHours;

  @JsonKey(name: 'least_active_hours')
  final List<int> leastActiveHours;

  @JsonKey(name: 'average_steps_by_hour')
  final Map<String, double> averageStepsByHour;

  @JsonKey(name: 'sedentary_pattern')
  final String? sedentaryPattern;

  @JsonKey(name: 'recommendation')
  final String? recommendation;

  const NeatHourlyPatternSummary({
    required this.userId,
    this.mostActiveHours = const [],
    this.leastActiveHours = const [],
    this.averageStepsByHour = const {},
    this.sedentaryPattern,
    this.recommendation,
  });

  factory NeatHourlyPatternSummary.fromJson(Map<String, dynamic> json) =>
      _$NeatHourlyPatternSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$NeatHourlyPatternSummaryToJson(this);
}
