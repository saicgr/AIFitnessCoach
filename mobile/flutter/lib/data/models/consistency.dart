import 'package:json_annotation/json_annotation.dart';

part 'consistency.g.dart';

/// Day of week enum (0=Sunday, 6=Saturday - matching backend)
enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  String get displayName {
    switch (this) {
      case DayOfWeek.sunday:
        return 'Sunday';
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.sunday:
        return 'Sun';
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
    }
  }

  static DayOfWeek fromInt(int value) {
    return DayOfWeek.values[value.clamp(0, 6)];
  }
}

/// Weekly trend direction
enum WeeklyTrend {
  @JsonValue('improving')
  improving,
  @JsonValue('stable')
  stable,
  @JsonValue('declining')
  declining;

  String get displayName {
    switch (this) {
      case WeeklyTrend.improving:
        return 'Improving';
      case WeeklyTrend.stable:
        return 'Stable';
      case WeeklyTrend.declining:
        return 'Declining';
    }
  }
}

/// Calendar heatmap status
enum CalendarStatus {
  @JsonValue('completed')
  completed,
  @JsonValue('missed')
  missed,
  @JsonValue('rest')
  rest,
  @JsonValue('future')
  future;
}

/// Day pattern data for a specific day of the week
@JsonSerializable()
class DayPattern {
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  @JsonKey(name: 'day_name')
  final String dayName;

  @JsonKey(name: 'total_completions')
  final int totalCompletions;

  @JsonKey(name: 'total_skips')
  final int totalSkips;

  @JsonKey(name: 'completion_rate')
  final double completionRate;

  @JsonKey(name: 'is_best_day')
  final bool isBestDay;

  @JsonKey(name: 'is_worst_day')
  final bool isWorstDay;

  const DayPattern({
    required this.dayOfWeek,
    required this.dayName,
    this.totalCompletions = 0,
    this.totalSkips = 0,
    this.completionRate = 0.0,
    this.isBestDay = false,
    this.isWorstDay = false,
  });

  factory DayPattern.fromJson(Map<String, dynamic> json) =>
      _$DayPatternFromJson(json);
  Map<String, dynamic> toJson() => _$DayPatternToJson(this);

  DayOfWeek get dayOfWeekEnum => DayOfWeek.fromInt(dayOfWeek);

  int get totalAttempts => totalCompletions + totalSkips;
}

/// Time of day pattern data
@JsonSerializable()
class TimeOfDayPattern {
  @JsonKey(name: 'time_of_day')
  final String timeOfDay;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'total_completions')
  final int totalCompletions;

  @JsonKey(name: 'total_skips')
  final int totalSkips;

  @JsonKey(name: 'completion_rate')
  final double completionRate;

  @JsonKey(name: 'is_preferred')
  final bool isPreferred;

  const TimeOfDayPattern({
    required this.timeOfDay,
    required this.displayName,
    this.totalCompletions = 0,
    this.totalSkips = 0,
    this.completionRate = 0.0,
    this.isPreferred = false,
  });

  factory TimeOfDayPattern.fromJson(Map<String, dynamic> json) =>
      _$TimeOfDayPatternFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayPatternToJson(this);
}

/// Weekly consistency metric
@JsonSerializable()
class WeeklyConsistencyMetric {
  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'week_end')
  final String weekEnd;

  @JsonKey(name: 'workouts_scheduled')
  final int workoutsScheduled;

  @JsonKey(name: 'workouts_completed')
  final int workoutsCompleted;

  @JsonKey(name: 'completion_rate')
  final double completionRate;

  @JsonKey(name: 'total_workout_minutes')
  final int totalWorkoutMinutes;

  const WeeklyConsistencyMetric({
    required this.weekStart,
    required this.weekEnd,
    this.workoutsScheduled = 0,
    this.workoutsCompleted = 0,
    this.completionRate = 0.0,
    this.totalWorkoutMinutes = 0,
  });

  factory WeeklyConsistencyMetric.fromJson(Map<String, dynamic> json) =>
      _$WeeklyConsistencyMetricFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyConsistencyMetricToJson(this);

  DateTime get weekStartDate => DateTime.parse(weekStart);
  DateTime get weekEndDate => DateTime.parse(weekEnd);

  int get workoutsMissed => workoutsScheduled - workoutsCompleted;
}

/// Comprehensive consistency insights
@JsonSerializable()
class ConsistencyInsights {
  @JsonKey(name: 'user_id')
  final String userId;

  // Current state
  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'longest_streak')
  final int longestStreak;

  @JsonKey(name: 'is_streak_active')
  final bool isStreakActive;

  // Day patterns
  @JsonKey(name: 'best_day')
  final DayPattern? bestDay;

  @JsonKey(name: 'worst_day')
  final DayPattern? worstDay;

  @JsonKey(name: 'day_patterns')
  final List<DayPattern> dayPatterns;

  // Time preferences
  @JsonKey(name: 'preferred_time')
  final String? preferredTime;

  @JsonKey(name: 'time_patterns')
  final List<TimeOfDayPattern> timePatterns;

  // Monthly stats
  @JsonKey(name: 'month_workouts_completed')
  final int monthWorkoutsCompleted;

  @JsonKey(name: 'month_workouts_scheduled')
  final int monthWorkoutsScheduled;

  @JsonKey(name: 'month_completion_rate')
  final double monthCompletionRate;

  @JsonKey(name: 'month_display')
  final String monthDisplay;

  // Weekly stats
  @JsonKey(name: 'weekly_completion_rates')
  final List<WeeklyConsistencyMetric> weeklyCompletionRates;

  @JsonKey(name: 'average_weekly_rate')
  final double averageWeeklyRate;

  @JsonKey(name: 'weekly_trend')
  final String weeklyTrend;

  // Recovery
  @JsonKey(name: 'needs_recovery')
  final bool needsRecovery;

  @JsonKey(name: 'recovery_suggestion')
  final String? recoverySuggestion;

  @JsonKey(name: 'days_since_last_workout')
  final int daysSinceLastWorkout;

  @JsonKey(name: 'last_workout_date')
  final String? lastWorkoutDate;

  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const ConsistencyInsights({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isStreakActive = false,
    this.bestDay,
    this.worstDay,
    this.dayPatterns = const [],
    this.preferredTime,
    this.timePatterns = const [],
    this.monthWorkoutsCompleted = 0,
    this.monthWorkoutsScheduled = 0,
    this.monthCompletionRate = 0.0,
    this.monthDisplay = '',
    this.weeklyCompletionRates = const [],
    this.averageWeeklyRate = 0.0,
    this.weeklyTrend = 'stable',
    this.needsRecovery = false,
    this.recoverySuggestion,
    this.daysSinceLastWorkout = 0,
    this.lastWorkoutDate,
    this.calculatedAt,
  });

  factory ConsistencyInsights.fromJson(Map<String, dynamic> json) =>
      _$ConsistencyInsightsFromJson(json);
  Map<String, dynamic> toJson() => _$ConsistencyInsightsToJson(this);

  WeeklyTrend get weeklyTrendEnum {
    switch (weeklyTrend.toLowerCase()) {
      case 'improving':
        return WeeklyTrend.improving;
      case 'declining':
        return WeeklyTrend.declining;
      default:
        return WeeklyTrend.stable;
    }
  }

  DateTime? get lastWorkoutDateTime =>
      lastWorkoutDate != null ? DateTime.tryParse(lastWorkoutDate!) : null;

  /// Get a motivational message based on streak status
  String get streakMessage {
    if (currentStreak == 0) {
      if (needsRecovery) {
        return 'Start fresh today!';
      }
      return 'Begin your streak today!';
    } else if (currentStreak == 1) {
      return 'Day 1 - Great start!';
    } else if (currentStreak < 7) {
      return '$currentStreak days strong!';
    } else if (currentStreak < 30) {
      return '$currentStreak day streak!';
    } else {
      return '$currentStreak days - Incredible!';
    }
  }

  /// Get best day display string
  String? get bestDayDisplay {
    if (bestDay == null) return null;
    return '${bestDay!.dayName} (${bestDay!.completionRate.toStringAsFixed(0)}%)';
  }

  /// Get worst day display string
  String? get worstDayDisplay {
    if (worstDay == null) return null;
    return '${worstDay!.dayName} (${worstDay!.completionRate.toStringAsFixed(0)}%)';
  }
}

/// Streak history record
@JsonSerializable()
class StreakHistoryRecord {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'streak_length')
  final int streakLength;

  @JsonKey(name: 'started_at')
  final String startedAt;

  @JsonKey(name: 'ended_at')
  final String endedAt;

  @JsonKey(name: 'end_reason')
  final String? endReason;

  @JsonKey(name: 'created_at')
  final String createdAt;

  const StreakHistoryRecord({
    required this.id,
    required this.userId,
    required this.streakLength,
    required this.startedAt,
    required this.endedAt,
    this.endReason,
    required this.createdAt,
  });

  factory StreakHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$StreakHistoryRecordFromJson(json);
  Map<String, dynamic> toJson() => _$StreakHistoryRecordToJson(this);

  DateTime get startedAtDate => DateTime.parse(startedAt);
  DateTime get endedAtDate => DateTime.parse(endedAt);
}

/// Detailed consistency patterns
@JsonSerializable()
class ConsistencyPatterns {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_patterns')
  final List<TimeOfDayPattern> timePatterns;

  @JsonKey(name: 'preferred_time')
  final String? preferredTime;

  @JsonKey(name: 'day_patterns')
  final List<DayPattern> dayPatterns;

  @JsonKey(name: 'most_consistent_day')
  final String? mostConsistentDay;

  @JsonKey(name: 'least_consistent_day')
  final String? leastConsistentDay;

  @JsonKey(name: 'has_seasonal_data')
  final bool hasSeasonalData;

  @JsonKey(name: 'seasonal_notes')
  final String? seasonalNotes;

  @JsonKey(name: 'skip_reasons')
  final Map<String, int> skipReasons;

  @JsonKey(name: 'most_common_skip_reason')
  final String? mostCommonSkipReason;

  @JsonKey(name: 'streak_history')
  final List<StreakHistoryRecord> streakHistory;

  @JsonKey(name: 'average_streak_length')
  final double averageStreakLength;

  @JsonKey(name: 'streak_count')
  final int streakCount;

  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const ConsistencyPatterns({
    required this.userId,
    this.timePatterns = const [],
    this.preferredTime,
    this.dayPatterns = const [],
    this.mostConsistentDay,
    this.leastConsistentDay,
    this.hasSeasonalData = false,
    this.seasonalNotes,
    this.skipReasons = const {},
    this.mostCommonSkipReason,
    this.streakHistory = const [],
    this.averageStreakLength = 0.0,
    this.streakCount = 0,
    this.calculatedAt,
  });

  factory ConsistencyPatterns.fromJson(Map<String, dynamic> json) =>
      _$ConsistencyPatternsFromJson(json);
  Map<String, dynamic> toJson() => _$ConsistencyPatternsToJson(this);
}

/// Calendar heatmap data point
@JsonSerializable()
class CalendarHeatmapData {
  final String date;

  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  final String status;

  @JsonKey(name: 'workout_name')
  final String? workoutName;

  const CalendarHeatmapData({
    required this.date,
    required this.dayOfWeek,
    required this.status,
    this.workoutName,
  });

  factory CalendarHeatmapData.fromJson(Map<String, dynamic> json) =>
      _$CalendarHeatmapDataFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarHeatmapDataToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  CalendarStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'completed':
        return CalendarStatus.completed;
      case 'missed':
        return CalendarStatus.missed;
      case 'future':
        return CalendarStatus.future;
      default:
        return CalendarStatus.rest;
    }
  }
}

/// Calendar heatmap response
@JsonSerializable()
class CalendarHeatmapResponse {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'start_date')
  final String startDate;

  @JsonKey(name: 'end_date')
  final String endDate;

  final List<CalendarHeatmapData> data;

  @JsonKey(name: 'total_completed')
  final int totalCompleted;

  @JsonKey(name: 'total_missed')
  final int totalMissed;

  @JsonKey(name: 'total_rest_days')
  final int totalRestDays;

  const CalendarHeatmapResponse({
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.data = const [],
    this.totalCompleted = 0,
    this.totalMissed = 0,
    this.totalRestDays = 0,
  });

  factory CalendarHeatmapResponse.fromJson(Map<String, dynamic> json) =>
      _$CalendarHeatmapResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarHeatmapResponseToJson(this);

  DateTime get startDateTime => DateTime.parse(startDate);
  DateTime get endDateTime => DateTime.parse(endDate);

  int get totalDays => data.length;
}

/// Streak recovery response
@JsonSerializable()
class StreakRecoveryResponse {
  final bool success;

  @JsonKey(name: 'attempt_id')
  final String attemptId;

  final String message;

  @JsonKey(name: 'motivation_quote')
  final String? motivationQuote;

  @JsonKey(name: 'suggested_workout_type')
  final String? suggestedWorkoutType;

  @JsonKey(name: 'suggested_duration_minutes')
  final int? suggestedDurationMinutes;

  const StreakRecoveryResponse({
    required this.success,
    required this.attemptId,
    required this.message,
    this.motivationQuote,
    this.suggestedWorkoutType,
    this.suggestedDurationMinutes,
  });

  factory StreakRecoveryResponse.fromJson(Map<String, dynamic> json) =>
      _$StreakRecoveryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StreakRecoveryResponseToJson(this);
}
