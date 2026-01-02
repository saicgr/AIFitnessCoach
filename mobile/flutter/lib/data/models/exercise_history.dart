import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'exercise_history.g.dart';

// ============================================================================
// Time Range for Exercise History
// ============================================================================

/// Time range options for exercise history queries
enum ExerciseHistoryTimeRange {
  @JsonValue('1_month')
  oneMonth,
  @JsonValue('3_months')
  threeMonths,
  @JsonValue('6_months')
  sixMonths,
  @JsonValue('1_year')
  oneYear,
  @JsonValue('all_time')
  allTime;

  String get value {
    switch (this) {
      case ExerciseHistoryTimeRange.oneMonth:
        return '1_month';
      case ExerciseHistoryTimeRange.threeMonths:
        return '3_months';
      case ExerciseHistoryTimeRange.sixMonths:
        return '6_months';
      case ExerciseHistoryTimeRange.oneYear:
        return '1_year';
      case ExerciseHistoryTimeRange.allTime:
        return 'all_time';
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseHistoryTimeRange.oneMonth:
        return '1 Month';
      case ExerciseHistoryTimeRange.threeMonths:
        return '3 Months';
      case ExerciseHistoryTimeRange.sixMonths:
        return '6 Months';
      case ExerciseHistoryTimeRange.oneYear:
        return '1 Year';
      case ExerciseHistoryTimeRange.allTime:
        return 'All Time';
    }
  }

  int get days {
    switch (this) {
      case ExerciseHistoryTimeRange.oneMonth:
        return 30;
      case ExerciseHistoryTimeRange.threeMonths:
        return 90;
      case ExerciseHistoryTimeRange.sixMonths:
        return 180;
      case ExerciseHistoryTimeRange.oneYear:
        return 365;
      case ExerciseHistoryTimeRange.allTime:
        return 3650; // ~10 years
    }
  }
}

// ============================================================================
// Exercise Workout Session
// ============================================================================

/// A single workout session for an exercise
@JsonSerializable()
class ExerciseWorkoutSession {
  @JsonKey(name: 'workout_id')
  final String workoutId;

  @JsonKey(name: 'workout_date')
  final String workoutDate;

  @JsonKey(name: 'workout_name')
  final String? workoutName;

  final int sets;

  final int reps;

  @JsonKey(name: 'weight_kg')
  final double weightKg;

  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;

  @JsonKey(name: 'estimated_1rm_kg')
  final double? estimated1rmKg;

  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;

  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;

  final String? notes;

  @JsonKey(name: 'is_pr')
  final bool? isPr;

  @JsonKey(name: 'pr_type')
  final String? prType; // 'weight', 'volume', '1rm'

  const ExerciseWorkoutSession({
    required this.workoutId,
    required this.workoutDate,
    this.workoutName,
    this.sets = 0,
    this.reps = 0,
    this.weightKg = 0,
    this.totalVolumeKg = 0,
    this.estimated1rmKg,
    this.restSeconds,
    this.durationMinutes,
    this.notes,
    this.isPr,
    this.prType,
  });

  factory ExerciseWorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$ExerciseWorkoutSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseWorkoutSessionToJson(this);

  /// Get DateTime from workout date string
  DateTime? get workoutDateTime {
    try {
      return DateTime.parse(workoutDate);
    } catch (_) {
      return null;
    }
  }

  /// Format workout date for display (e.g., "Dec 25, 2024")
  String get formattedDate {
    final date = workoutDateTime;
    if (date == null) return workoutDate;
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format workout date short (e.g., "Dec 25")
  String get formattedDateShort {
    final date = workoutDateTime;
    if (date == null) return workoutDate;
    return DateFormat('MMM d').format(date);
  }

  /// Format weight for display (e.g., "60 kg" or "60.5 kg")
  String get formattedWeight {
    if (weightKg == 0) return '-';
    if (weightKg == weightKg.toInt()) {
      return '${weightKg.toInt()} kg';
    }
    return '${weightKg.toStringAsFixed(1)} kg';
  }

  /// Format volume for display (e.g., "1,200 kg")
  String get formattedVolume {
    if (totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg >= 1000) {
      return '${formatter.format(totalVolumeKg.round())} kg';
    }
    return '${totalVolumeKg.toStringAsFixed(0)} kg';
  }

  /// Format sets x reps display (e.g., "3 x 10")
  String get setsRepsDisplay => '$sets x $reps';

  /// Format estimated 1RM for display
  String get formatted1rm {
    if (estimated1rmKg == null || estimated1rmKg == 0) return '-';
    if (estimated1rmKg == estimated1rmKg!.toInt()) {
      return '${estimated1rmKg!.toInt()} kg';
    }
    return '${estimated1rmKg!.toStringAsFixed(1)} kg';
  }

  /// Whether this session had a personal record
  bool get hadPr => isPr == true;

  /// Get PR badge text
  String? get prBadge {
    if (!hadPr) return null;
    switch (prType) {
      case 'weight':
        return 'Weight PR';
      case 'volume':
        return 'Volume PR';
      case '1rm':
        return '1RM PR';
      default:
        return 'PR';
    }
  }

  /// Days ago from today
  int get daysAgo {
    final date = workoutDateTime;
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  /// Relative date display (e.g., "Today", "Yesterday", "3 days ago", "Dec 25")
  String get relativeDateDisplay {
    final days = daysAgo;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return formattedDateShort;
  }
}

// ============================================================================
// Exercise History Data (Full Response)
// ============================================================================

/// Full response containing exercise history with sessions list
@JsonSerializable()
class ExerciseHistoryData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'exercise_id')
  final String? exerciseId;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'total_sessions')
  final int totalSessions;

  final List<ExerciseWorkoutSession> sessions;

  final ExerciseProgressionSummary? summary;

  @JsonKey(name: 'personal_records')
  final List<ExercisePersonalRecord>? personalRecords;

  const ExerciseHistoryData({
    required this.userId,
    this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    required this.timeRange,
    this.totalSessions = 0,
    this.sessions = const [],
    this.summary,
    this.personalRecords,
  });

  factory ExerciseHistoryData.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseHistoryDataToJson(this);

  /// Get sessions sorted by date (newest first)
  List<ExerciseWorkoutSession> get sortedSessionsNewestFirst {
    final sorted = List<ExerciseWorkoutSession>.from(sessions);
    sorted.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
    return sorted;
  }

  /// Get sessions sorted by date (oldest first)
  List<ExerciseWorkoutSession> get sortedSessionsOldestFirst {
    final sorted = List<ExerciseWorkoutSession>.from(sessions);
    sorted.sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    return sorted;
  }

  /// Get the most recent session
  ExerciseWorkoutSession? get mostRecentSession {
    if (sessions.isEmpty) return null;
    return sortedSessionsNewestFirst.first;
  }

  /// Get the first session (oldest)
  ExerciseWorkoutSession? get firstSession {
    if (sessions.isEmpty) return null;
    return sortedSessionsOldestFirst.first;
  }

  /// Check if there's any data
  bool get hasData => sessions.isNotEmpty;

  /// Get average weight across all sessions
  double get averageWeight {
    if (sessions.isEmpty) return 0;
    final total = sessions.fold<double>(0, (sum, s) => sum + s.weightKg);
    return total / sessions.length;
  }

  /// Get max weight across all sessions
  double get maxWeight {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
  }

  /// Get total volume across all sessions
  double get totalVolume {
    return sessions.fold<double>(0, (sum, s) => sum + s.totalVolumeKg);
  }

  /// Get sessions with PRs
  List<ExerciseWorkoutSession> get prSessions {
    return sessions.where((s) => s.hadPr).toList();
  }

  /// Get chart data points for weight progression
  List<ExerciseChartDataPoint> get weightChartData {
    return sortedSessionsOldestFirst
        .map((s) => ExerciseChartDataPoint(
              date: s.workoutDate,
              value: s.weightKg,
              label: s.formattedWeight,
            ))
        .toList();
  }

  /// Get chart data points for volume progression
  List<ExerciseChartDataPoint> get volumeChartData {
    return sortedSessionsOldestFirst
        .map((s) => ExerciseChartDataPoint(
              date: s.workoutDate,
              value: s.totalVolumeKg,
              label: s.formattedVolume,
            ))
        .toList();
  }

  /// Get chart data points for estimated 1RM progression
  List<ExerciseChartDataPoint> get oneRmChartData {
    return sortedSessionsOldestFirst
        .where((s) => s.estimated1rmKg != null && s.estimated1rmKg! > 0)
        .map((s) => ExerciseChartDataPoint(
              date: s.workoutDate,
              value: s.estimated1rmKg!,
              label: s.formatted1rm,
            ))
        .toList();
  }

  /// Format muscle group name
  String get formattedMuscleGroup {
    if (muscleGroup == null) return '';
    return muscleGroup!
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

// ============================================================================
// Exercise Personal Record
// ============================================================================

/// A personal record for an exercise
@JsonSerializable()
class ExercisePersonalRecord {
  final String id;

  @JsonKey(name: 'exercise_id')
  final String? exerciseId;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'pr_type')
  final String prType; // 'weight', 'volume', '1rm', 'reps'

  @JsonKey(name: 'pr_value')
  final double prValue;

  @JsonKey(name: 'achieved_date')
  final String achievedDate;

  @JsonKey(name: 'workout_id')
  final String? workoutId;

  @JsonKey(name: 'previous_value')
  final double? previousValue;

  @JsonKey(name: 'improvement_percent')
  final double? improvementPercent;

  final int? sets;

  final int? reps;

  @JsonKey(name: 'weight_kg')
  final double? weightKg;

  const ExercisePersonalRecord({
    required this.id,
    this.exerciseId,
    required this.exerciseName,
    required this.prType,
    required this.prValue,
    required this.achievedDate,
    this.workoutId,
    this.previousValue,
    this.improvementPercent,
    this.sets,
    this.reps,
    this.weightKg,
  });

  factory ExercisePersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$ExercisePersonalRecordFromJson(json);

  Map<String, dynamic> toJson() => _$ExercisePersonalRecordToJson(this);

  /// Get DateTime from achieved date string
  DateTime? get achievedDateTime {
    try {
      return DateTime.parse(achievedDate);
    } catch (_) {
      return null;
    }
  }

  /// Format achieved date for display
  String get formattedAchievedDate {
    final date = achievedDateTime;
    if (date == null) return achievedDate;
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Get PR type display name
  String get prTypeDisplayName {
    switch (prType) {
      case 'weight':
        return 'Max Weight';
      case 'volume':
        return 'Total Volume';
      case '1rm':
        return 'Est. 1RM';
      case 'reps':
        return 'Max Reps';
      default:
        return prType.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Format PR value for display
  String get formattedValue {
    if (prType == 'reps') {
      return '${prValue.toInt()} reps';
    }
    if (prValue == prValue.toInt()) {
      return '${prValue.toInt()} kg';
    }
    return '${prValue.toStringAsFixed(1)} kg';
  }

  /// Format improvement for display
  String? get formattedImprovement {
    if (improvementPercent == null) return null;
    final sign = improvementPercent! >= 0 ? '+' : '';
    return '$sign${improvementPercent!.toStringAsFixed(1)}%';
  }

  /// Whether this is a recent PR (within last 7 days)
  bool get isRecent {
    final date = achievedDateTime;
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 7;
  }

  /// Days since PR was achieved
  int get daysSinceAchieved {
    final date = achievedDateTime;
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }
}

// ============================================================================
// Exercise Chart Data Point
// ============================================================================

/// A data point for exercise progression charts
@JsonSerializable()
class ExerciseChartDataPoint {
  final String date;

  final double value;

  final String? label;

  @JsonKey(name: 'is_pr')
  final bool? isPr;

  final String? annotation;

  const ExerciseChartDataPoint({
    required this.date,
    required this.value,
    this.label,
    this.isPr,
    this.annotation,
  });

  factory ExerciseChartDataPoint.fromJson(Map<String, dynamic> json) =>
      _$ExerciseChartDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseChartDataPointToJson(this);

  /// Get DateTime from date string
  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  /// Format date for chart axis (e.g., "Dec 25")
  String get axisLabel {
    final dt = dateTime;
    if (dt == null) return date;
    return DateFormat('MMM d').format(dt);
  }

  /// Format date for tooltip (e.g., "Dec 25, 2024")
  String get tooltipDate {
    final dt = dateTime;
    if (dt == null) return date;
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ============================================================================
// Exercise Progression Summary
// ============================================================================

/// Summary of progression over time for an exercise
@JsonSerializable()
class ExerciseProgressionSummary {
  @JsonKey(name: 'total_sessions')
  final int totalSessions;

  @JsonKey(name: 'first_session_date')
  final String? firstSessionDate;

  @JsonKey(name: 'last_session_date')
  final String? lastSessionDate;

  @JsonKey(name: 'days_training')
  final int? daysTraining;

  @JsonKey(name: 'starting_weight_kg')
  final double? startingWeightKg;

  @JsonKey(name: 'current_weight_kg')
  final double? currentWeightKg;

  @JsonKey(name: 'weight_increase_kg')
  final double? weightIncreaseKg;

  @JsonKey(name: 'weight_increase_percent')
  final double? weightIncreasePercent;

  @JsonKey(name: 'starting_1rm_kg')
  final double? starting1rmKg;

  @JsonKey(name: 'current_1rm_kg')
  final double? current1rmKg;

  @JsonKey(name: 'one_rm_increase_kg')
  final double? oneRmIncreaseKg;

  @JsonKey(name: 'one_rm_increase_percent')
  final double? oneRmIncreasePercent;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'avg_volume_per_session_kg')
  final double? avgVolumePerSessionKg;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'total_reps')
  final int? totalReps;

  @JsonKey(name: 'pr_count')
  final int? prCount;

  @JsonKey(name: 'trend')
  final String? trend; // 'improving', 'maintaining', 'declining'

  @JsonKey(name: 'avg_frequency_per_week')
  final double? avgFrequencyPerWeek;

  const ExerciseProgressionSummary({
    this.totalSessions = 0,
    this.firstSessionDate,
    this.lastSessionDate,
    this.daysTraining,
    this.startingWeightKg,
    this.currentWeightKg,
    this.weightIncreaseKg,
    this.weightIncreasePercent,
    this.starting1rmKg,
    this.current1rmKg,
    this.oneRmIncreaseKg,
    this.oneRmIncreasePercent,
    this.totalVolumeKg,
    this.avgVolumePerSessionKg,
    this.totalSets,
    this.totalReps,
    this.prCount,
    this.trend,
    this.avgFrequencyPerWeek,
  });

  factory ExerciseProgressionSummary.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseProgressionSummaryToJson(this);

  /// Format weight increase for display
  String get formattedWeightIncrease {
    if (weightIncreaseKg == null) return '-';
    final sign = weightIncreaseKg! >= 0 ? '+' : '';
    if (weightIncreaseKg == weightIncreaseKg!.toInt()) {
      return '$sign${weightIncreaseKg!.toInt()} kg';
    }
    return '$sign${weightIncreaseKg!.toStringAsFixed(1)} kg';
  }

  /// Format weight increase percent for display
  String get formattedWeightIncreasePercent {
    if (weightIncreasePercent == null) return '-';
    final sign = weightIncreasePercent! >= 0 ? '+' : '';
    return '$sign${weightIncreasePercent!.toStringAsFixed(1)}%';
  }

  /// Format 1RM increase for display
  String get formattedOneRmIncrease {
    if (oneRmIncreaseKg == null) return '-';
    final sign = oneRmIncreaseKg! >= 0 ? '+' : '';
    if (oneRmIncreaseKg == oneRmIncreaseKg!.toInt()) {
      return '$sign${oneRmIncreaseKg!.toInt()} kg';
    }
    return '$sign${oneRmIncreaseKg!.toStringAsFixed(1)} kg';
  }

  /// Format total volume for display
  String get formattedTotalVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Get trend display
  String get trendDisplay {
    switch (trend) {
      case 'improving':
        return 'Improving';
      case 'maintaining':
        return 'Maintaining';
      case 'declining':
        return 'Declining';
      default:
        return 'N/A';
    }
  }

  /// Check if showing improvement
  bool get isImproving => trend == 'improving';

  /// Check if maintaining
  bool get isMaintaining => trend == 'maintaining';

  /// Check if declining
  bool get isDeclining => trend == 'declining';

  /// Format frequency per week
  String get formattedFrequency {
    if (avgFrequencyPerWeek == null) return '-';
    return '${avgFrequencyPerWeek!.toStringAsFixed(1)}x/week';
  }
}

// ============================================================================
// Most Performed Exercise
// ============================================================================

/// An exercise with its performance count (for rankings/stats)
@JsonSerializable()
class MostPerformedExercise {
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;

  @JsonKey(name: 'times_performed')
  final int timesPerformed;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'total_reps')
  final int? totalReps;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'max_weight_kg')
  final double? maxWeightKg;

  @JsonKey(name: 'current_1rm_kg')
  final double? current1rmKg;

  @JsonKey(name: 'last_performed')
  final String? lastPerformed;

  final int? rank;

  const MostPerformedExercise({
    this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.timesPerformed = 0,
    this.totalSets,
    this.totalReps,
    this.totalVolumeKg,
    this.maxWeightKg,
    this.current1rmKg,
    this.lastPerformed,
    this.rank,
  });

  factory MostPerformedExercise.fromJson(Map<String, dynamic> json) =>
      _$MostPerformedExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$MostPerformedExerciseToJson(this);

  /// Format times performed (e.g., "12 times", "1 time")
  String get formattedTimesPerformed {
    return timesPerformed == 1 ? '1 time' : '$timesPerformed times';
  }

  /// Format max weight for display
  String get formattedMaxWeight {
    if (maxWeightKg == null || maxWeightKg == 0) return '-';
    if (maxWeightKg == maxWeightKg!.toInt()) {
      return '${maxWeightKg!.toInt()} kg';
    }
    return '${maxWeightKg!.toStringAsFixed(1)} kg';
  }

  /// Format total volume for display
  String get formattedTotalVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Format current 1RM for display
  String get formattedCurrent1rm {
    if (current1rmKg == null || current1rmKg == 0) return '-';
    if (current1rmKg == current1rmKg!.toInt()) {
      return '${current1rmKg!.toInt()} kg';
    }
    return '${current1rmKg!.toStringAsFixed(1)} kg';
  }

  /// Format muscle group name
  String get formattedMuscleGroup {
    if (muscleGroup == null) return '';
    return muscleGroup!
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get last performed date
  DateTime? get lastPerformedDate {
    if (lastPerformed == null) return null;
    try {
      return DateTime.parse(lastPerformed!);
    } catch (_) {
      return null;
    }
  }

  /// Format last performed date
  String get formattedLastPerformed {
    final date = lastPerformedDate;
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('MMM d').format(date);
  }
}
