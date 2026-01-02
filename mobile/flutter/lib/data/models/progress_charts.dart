import 'package:json_annotation/json_annotation.dart';

part 'progress_charts.g.dart';

/// Time range options for progress charts
enum ProgressTimeRange {
  @JsonValue('4_weeks')
  fourWeeks,
  @JsonValue('8_weeks')
  eightWeeks,
  @JsonValue('12_weeks')
  twelveWeeks,
  @JsonValue('all_time')
  allTime;

  String get value {
    switch (this) {
      case ProgressTimeRange.fourWeeks:
        return '4_weeks';
      case ProgressTimeRange.eightWeeks:
        return '8_weeks';
      case ProgressTimeRange.twelveWeeks:
        return '12_weeks';
      case ProgressTimeRange.allTime:
        return 'all_time';
    }
  }

  String get displayName {
    switch (this) {
      case ProgressTimeRange.fourWeeks:
        return '4 Weeks';
      case ProgressTimeRange.eightWeeks:
        return '8 Weeks';
      case ProgressTimeRange.twelveWeeks:
        return '12 Weeks';
      case ProgressTimeRange.allTime:
        return 'All Time';
    }
  }

  int get weeks {
    switch (this) {
      case ProgressTimeRange.fourWeeks:
        return 4;
      case ProgressTimeRange.eightWeeks:
        return 8;
      case ProgressTimeRange.twelveWeeks:
        return 12;
      case ProgressTimeRange.allTime:
        return 52; // Default to 1 year for "all time"
    }
  }
}

/// Chart type for analytics logging
enum ChartType {
  @JsonValue('strength')
  strength,
  @JsonValue('volume')
  volume,
  @JsonValue('summary')
  summary,
  @JsonValue('muscle_group')
  muscleGroup,
  @JsonValue('all')
  all;

  String get value {
    switch (this) {
      case ChartType.strength:
        return 'strength';
      case ChartType.volume:
        return 'volume';
      case ChartType.summary:
        return 'summary';
      case ChartType.muscleGroup:
        return 'muscle_group';
      case ChartType.all:
        return 'all';
    }
  }
}

/// Volume trend direction
enum VolumeTrendDirection {
  improving,
  maintaining,
  declining,
  insufficientData,
  noData;

  static VolumeTrendDirection fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'improving':
        return VolumeTrendDirection.improving;
      case 'maintaining':
        return VolumeTrendDirection.maintaining;
      case 'declining':
        return VolumeTrendDirection.declining;
      case 'insufficient_data':
        return VolumeTrendDirection.insufficientData;
      default:
        return VolumeTrendDirection.noData;
    }
  }
}

// ============================================================================
// Weekly Strength Data
// ============================================================================

@JsonSerializable()
class WeeklyStrengthData {
  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'week_number')
  final int weekNumber;

  final int year;

  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  @JsonKey(name: 'total_sets')
  final int totalSets;

  @JsonKey(name: 'total_reps')
  final int totalReps;

  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;

  @JsonKey(name: 'max_weight_kg')
  final double maxWeightKg;

  @JsonKey(name: 'workout_count')
  final int workoutCount;

  const WeeklyStrengthData({
    required this.weekStart,
    required this.weekNumber,
    required this.year,
    required this.muscleGroup,
    this.totalSets = 0,
    this.totalReps = 0,
    this.totalVolumeKg = 0,
    this.maxWeightKg = 0,
    this.workoutCount = 0,
  });

  factory WeeklyStrengthData.fromJson(Map<String, dynamic> json) =>
      _$WeeklyStrengthDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyStrengthDataToJson(this);

  /// Get formatted muscle group name
  String get formattedMuscleGroup {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get DateTime from week start string
  DateTime? get weekStartDate {
    try {
      return DateTime.parse(weekStart);
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// Strength Progression Response
// ============================================================================

@JsonSerializable()
class StrengthProgressionData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'weeks_count')
  final int weeksCount;

  @JsonKey(name: 'muscle_groups')
  final List<String> muscleGroups;

  final List<WeeklyStrengthData> data;

  final Map<String, dynamic> summary;

  const StrengthProgressionData({
    required this.userId,
    required this.timeRange,
    this.weeksCount = 0,
    this.muscleGroups = const [],
    this.data = const [],
    this.summary = const {},
  });

  factory StrengthProgressionData.fromJson(Map<String, dynamic> json) =>
      _$StrengthProgressionDataFromJson(json);

  Map<String, dynamic> toJson() => _$StrengthProgressionDataToJson(this);

  /// Get total volume across all weeks
  double get totalVolumeKg => summary['total_volume_kg'] as double? ?? 0;

  /// Get total sets
  int get totalSets => summary['total_sets'] as int? ?? 0;

  /// Get average weekly volume
  double get avgWeeklyVolumeKg =>
      summary['avg_weekly_volume_kg'] as double? ?? 0;

  /// Get top muscle group
  String? get topMuscleGroup => summary['top_muscle_group'] as String?;

  /// Get volume trend
  String get volumeTrend => summary['volume_trend'] as String? ?? 'no_data';

  /// Get data filtered by muscle group
  List<WeeklyStrengthData> getDataForMuscleGroup(String muscleGroup) {
    return data.where((d) => d.muscleGroup == muscleGroup.toLowerCase()).toList();
  }

  /// Get unique weeks sorted chronologically
  List<String> get sortedWeeks {
    final weeks = data.map((d) => d.weekStart).toSet().toList();
    weeks.sort();
    return weeks;
  }
}

// ============================================================================
// Weekly Volume Data
// ============================================================================

@JsonSerializable()
class WeeklyVolumeData {
  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'week_number')
  final int weekNumber;

  final int year;

  @JsonKey(name: 'workouts_completed')
  final int workoutsCompleted;

  @JsonKey(name: 'total_minutes')
  final int totalMinutes;

  @JsonKey(name: 'avg_duration_minutes')
  final double avgDurationMinutes;

  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;

  @JsonKey(name: 'total_sets')
  final int totalSets;

  @JsonKey(name: 'total_reps')
  final int totalReps;

  const WeeklyVolumeData({
    required this.weekStart,
    required this.weekNumber,
    required this.year,
    this.workoutsCompleted = 0,
    this.totalMinutes = 0,
    this.avgDurationMinutes = 0,
    this.totalVolumeKg = 0,
    this.totalSets = 0,
    this.totalReps = 0,
  });

  factory WeeklyVolumeData.fromJson(Map<String, dynamic> json) =>
      _$WeeklyVolumeDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyVolumeDataToJson(this);

  /// Get DateTime from week start string
  DateTime? get weekStartDate {
    try {
      return DateTime.parse(weekStart);
    } catch (_) {
      return null;
    }
  }

  /// Get formatted week label (e.g., "Week 1", "Dec 23")
  String get weekLabel {
    final date = weekStartDate;
    if (date != null) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
    return 'Week $weekNumber';
  }
}

// ============================================================================
// Volume Progression Response
// ============================================================================

@JsonSerializable()
class VolumeProgressionData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'weeks_count')
  final int weeksCount;

  final List<WeeklyVolumeData> data;

  final Map<String, dynamic> trend;

  const VolumeProgressionData({
    required this.userId,
    required this.timeRange,
    this.weeksCount = 0,
    this.data = const [],
    this.trend = const {},
  });

  factory VolumeProgressionData.fromJson(Map<String, dynamic> json) =>
      _$VolumeProgressionDataFromJson(json);

  Map<String, dynamic> toJson() => _$VolumeProgressionDataToJson(this);

  /// Get trend direction
  VolumeTrendDirection get trendDirection =>
      VolumeTrendDirection.fromString(trend['direction'] as String?);

  /// Get percent change
  double get percentChange => (trend['percent_change'] as num?)?.toDouble() ?? 0;

  /// Get average weekly volume
  double get avgWeeklyVolumeKg =>
      (trend['avg_weekly_volume_kg'] as num?)?.toDouble() ?? 0;

  /// Get peak volume
  double get peakVolumeKg =>
      (trend['peak_volume_kg'] as num?)?.toDouble() ?? 0;

  /// Get peak week
  String? get peakWeek => trend['peak_week'] as String?;

  /// Get total volume across all weeks
  double get totalVolumeKg =>
      data.fold(0.0, (sum, week) => sum + week.totalVolumeKg);

  /// Get total workouts
  int get totalWorkouts =>
      data.fold(0, (sum, week) => sum + week.workoutsCompleted);

  /// Get sorted data (chronologically)
  List<WeeklyVolumeData> get sortedData {
    final sorted = List<WeeklyVolumeData>.from(data);
    sorted.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return sorted;
  }
}

// ============================================================================
// Exercise Strength Data
// ============================================================================

@JsonSerializable()
class ExerciseStrengthData {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'times_performed')
  final int timesPerformed;

  @JsonKey(name: 'max_weight_kg')
  final double maxWeightKg;

  @JsonKey(name: 'estimated_1rm_kg')
  final double estimated1rmKg;

  const ExerciseStrengthData({
    required this.exerciseName,
    required this.muscleGroup,
    required this.weekStart,
    this.timesPerformed = 0,
    this.maxWeightKg = 0,
    this.estimated1rmKg = 0,
  });

  factory ExerciseStrengthData.fromJson(Map<String, dynamic> json) =>
      _$ExerciseStrengthDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseStrengthDataToJson(this);
}

// ============================================================================
// Exercise Progression Response
// ============================================================================

@JsonSerializable()
class ExerciseProgressionData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  final List<ExerciseStrengthData> data;

  final Map<String, dynamic> improvement;

  const ExerciseProgressionData({
    required this.userId,
    required this.timeRange,
    required this.exerciseName,
    this.data = const [],
    this.improvement = const {},
  });

  factory ExerciseProgressionData.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressionDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseProgressionDataToJson(this);

  /// Check if there is improvement
  bool get hasImprovement => improvement['has_improvement'] as bool? ?? false;

  /// Get weight increase in kg
  double get weightIncreaseKg =>
      (improvement['weight_increase_kg'] as num?)?.toDouble() ?? 0;

  /// Get weight increase percentage
  double get weightIncreasePercent =>
      (improvement['weight_increase_percent'] as num?)?.toDouble() ?? 0;

  /// Get 1RM increase in kg
  double get rmIncreaseKg =>
      (improvement['rm_increase_kg'] as num?)?.toDouble() ?? 0;

  /// Get 1RM increase percentage
  double get rmIncreasePercent =>
      (improvement['rm_increase_percent'] as num?)?.toDouble() ?? 0;

  /// Get current max weight
  double get currentMaxWeightKg =>
      (improvement['current_max_weight_kg'] as num?)?.toDouble() ?? 0;

  /// Get current estimated 1RM
  double get current1rmKg =>
      (improvement['current_1rm_kg'] as num?)?.toDouble() ?? 0;
}

// ============================================================================
// Progress Summary Response
// ============================================================================

@JsonSerializable()
class ProgressSummary {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;

  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;

  @JsonKey(name: 'total_prs')
  final int totalPRs;

  @JsonKey(name: 'first_workout_date')
  final String? firstWorkoutDate;

  @JsonKey(name: 'last_workout_date')
  final String? lastWorkoutDate;

  @JsonKey(name: 'volume_increase_percent')
  final double volumeIncreasePercent;

  @JsonKey(name: 'avg_weekly_workouts')
  final double avgWeeklyWorkouts;

  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'muscle_group_breakdown')
  final List<Map<String, dynamic>> muscleGroupBreakdown;

  @JsonKey(name: 'recent_prs')
  final List<Map<String, dynamic>> recentPRs;

  @JsonKey(name: 'best_week')
  final Map<String, dynamic>? bestWeek;

  const ProgressSummary({
    required this.userId,
    this.totalWorkouts = 0,
    this.totalVolumeKg = 0,
    this.totalPRs = 0,
    this.firstWorkoutDate,
    this.lastWorkoutDate,
    this.volumeIncreasePercent = 0,
    this.avgWeeklyWorkouts = 0,
    this.currentStreak = 0,
    this.muscleGroupBreakdown = const [],
    this.recentPRs = const [],
    this.bestWeek,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) =>
      _$ProgressSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressSummaryToJson(this);

  /// Get formatted total volume (e.g., "1,234.5 kg")
  String get formattedTotalVolume {
    if (totalVolumeKg >= 1000) {
      return '${(totalVolumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg.toStringAsFixed(0)} kg';
  }

  /// Get volume trend description
  String get volumeTrendDescription {
    if (volumeIncreasePercent > 10) {
      return 'Strong growth';
    } else if (volumeIncreasePercent > 0) {
      return 'Steady progress';
    } else if (volumeIncreasePercent > -10) {
      return 'Maintaining';
    } else {
      return 'Declining';
    }
  }

  /// Check if user has recent PRs
  bool get hasRecentPRs => recentPRs.isNotEmpty;

  /// Get days since first workout
  int? get daysSinceFirstWorkout {
    if (firstWorkoutDate == null) return null;
    try {
      final first = DateTime.parse(firstWorkoutDate!);
      return DateTime.now().difference(first).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Get best week volume
  double? get bestWeekVolume =>
      (bestWeek?['total_volume_kg'] as num?)?.toDouble();

  /// Get best week date
  String? get bestWeekDate => bestWeek?['week_start'] as String?;
}

// ============================================================================
// Muscle Groups Response
// ============================================================================

@JsonSerializable()
class AvailableMuscleGroups {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'muscle_groups')
  final List<String> muscleGroups;

  final int count;

  const AvailableMuscleGroups({
    required this.userId,
    this.muscleGroups = const [],
    this.count = 0,
  });

  factory AvailableMuscleGroups.fromJson(Map<String, dynamic> json) =>
      _$AvailableMuscleGroupsFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableMuscleGroupsToJson(this);

  /// Get formatted muscle group names
  List<String> get formattedMuscleGroups {
    return muscleGroups.map((mg) {
      return mg
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) =>
              word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    }).toList();
  }
}
