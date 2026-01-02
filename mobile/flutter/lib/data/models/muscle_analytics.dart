import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'muscle_analytics.g.dart';

// ============================================================================
// Muscle Heatmap Data
// ============================================================================

/// Intensity data for muscle body diagram visualization
@JsonSerializable()
class MuscleHeatmapData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'muscle_intensities')
  final List<MuscleIntensity> muscleIntensities;

  @JsonKey(name: 'max_intensity')
  final double? maxIntensity;

  @JsonKey(name: 'min_intensity')
  final double? minIntensity;

  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  const MuscleHeatmapData({
    required this.userId,
    required this.timeRange,
    this.muscleIntensities = const [],
    this.maxIntensity,
    this.minIntensity,
    this.lastUpdated,
  });

  factory MuscleHeatmapData.fromJson(Map<String, dynamic> json) =>
      _$MuscleHeatmapDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleHeatmapDataToJson(this);

  /// Get intensity for a specific muscle
  double getIntensityForMuscle(String muscleId) {
    final muscle = muscleIntensities.firstWhere(
      (m) => m.muscleId.toLowerCase() == muscleId.toLowerCase(),
      orElse: () => MuscleIntensity(muscleId: muscleId, intensity: 0),
    );
    return muscle.intensity;
  }

  /// Get normalized intensity (0-1) for a muscle
  double getNormalizedIntensity(String muscleId) {
    if (maxIntensity == null || maxIntensity == 0) return 0;
    return getIntensityForMuscle(muscleId) / maxIntensity!;
  }

  /// Get muscles sorted by intensity (highest first)
  List<MuscleIntensity> get sortedByIntensity {
    final sorted = List<MuscleIntensity>.from(muscleIntensities);
    sorted.sort((a, b) => b.intensity.compareTo(a.intensity));
    return sorted;
  }

  /// Get top N trained muscles
  List<MuscleIntensity> getTopMuscles(int count) {
    return sortedByIntensity.take(count).toList();
  }

  /// Get neglected muscles (below threshold)
  List<MuscleIntensity> getNeglectedMuscles({double threshold = 0.2}) {
    if (maxIntensity == null || maxIntensity == 0) return [];
    return muscleIntensities
        .where((m) => (m.intensity / maxIntensity!) < threshold)
        .toList();
  }

  /// Check if there's any data
  bool get hasData => muscleIntensities.isNotEmpty;
}

/// Single muscle intensity data
@JsonSerializable()
class MuscleIntensity {
  @JsonKey(name: 'muscle_id')
  final String muscleId;

  @JsonKey(name: 'muscle_name')
  final String? muscleName;

  final double intensity;

  @JsonKey(name: 'workout_count')
  final int? workoutCount;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'last_trained')
  final String? lastTrained;

  const MuscleIntensity({
    required this.muscleId,
    this.muscleName,
    this.intensity = 0,
    this.workoutCount,
    this.totalSets,
    this.totalVolumeKg,
    this.lastTrained,
  });

  factory MuscleIntensity.fromJson(Map<String, dynamic> json) =>
      _$MuscleIntensityFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleIntensityToJson(this);

  /// Get formatted muscle name
  String get formattedMuscleName {
    if (muscleName != null) return muscleName!;
    return muscleId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get intensity as percentage string
  String get intensityPercent => '${(intensity * 100).toStringAsFixed(0)}%';

  /// Get last trained date
  DateTime? get lastTrainedDate {
    if (lastTrained == null) return null;
    try {
      return DateTime.parse(lastTrained!);
    } catch (_) {
      return null;
    }
  }

  /// Get formatted last trained
  String get formattedLastTrained {
    final date = lastTrainedDate;
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('MMM d').format(date);
  }

  /// Get formatted volume
  String get formattedVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }
}

// ============================================================================
// Muscle Training Frequency
// ============================================================================

/// Frequency statistics per muscle group
@JsonSerializable()
class MuscleTrainingFrequency {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'frequencies')
  final List<MuscleFrequencyData> frequencies;

  @JsonKey(name: 'total_workouts')
  final int? totalWorkouts;

  @JsonKey(name: 'avg_workouts_per_week')
  final double? avgWorkoutsPerWeek;

  const MuscleTrainingFrequency({
    required this.userId,
    required this.timeRange,
    this.frequencies = const [],
    this.totalWorkouts,
    this.avgWorkoutsPerWeek,
  });

  factory MuscleTrainingFrequency.fromJson(Map<String, dynamic> json) =>
      _$MuscleTrainingFrequencyFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleTrainingFrequencyToJson(this);

  /// Get frequency for a specific muscle
  MuscleFrequencyData? getFrequencyForMuscle(String muscleGroup) {
    try {
      return frequencies.firstWhere(
        (f) => f.muscleGroup.toLowerCase() == muscleGroup.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get muscles sorted by frequency (highest first)
  List<MuscleFrequencyData> get sortedByFrequency {
    final sorted = List<MuscleFrequencyData>.from(frequencies);
    sorted.sort((a, b) => b.timesPerWeek.compareTo(a.timesPerWeek));
    return sorted;
  }

  /// Get muscles that are undertrained (less than target)
  List<MuscleFrequencyData> getUndertrainedMuscles({double targetPerWeek = 2.0}) {
    return frequencies.where((f) => f.timesPerWeek < targetPerWeek).toList();
  }

  /// Get muscles that are overtrained (more than max)
  List<MuscleFrequencyData> getOvertrainedMuscles({double maxPerWeek = 4.0}) {
    return frequencies.where((f) => f.timesPerWeek > maxPerWeek).toList();
  }

  /// Check if there's any data
  bool get hasData => frequencies.isNotEmpty;
}

/// Frequency data for a single muscle group
@JsonSerializable()
class MuscleFrequencyData {
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  @JsonKey(name: 'times_trained')
  final int timesTrained;

  @JsonKey(name: 'times_per_week')
  final double timesPerWeek;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'avg_sets_per_workout')
  final double? avgSetsPerWorkout;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'last_trained')
  final String? lastTrained;

  @JsonKey(name: 'days_since_trained')
  final int? daysSinceTrained;

  @JsonKey(name: 'recommended_frequency')
  final double? recommendedFrequency;

  @JsonKey(name: 'frequency_status')
  final String? frequencyStatus; // 'optimal', 'undertrained', 'overtrained'

  const MuscleFrequencyData({
    required this.muscleGroup,
    this.timesTrained = 0,
    this.timesPerWeek = 0,
    this.totalSets,
    this.avgSetsPerWorkout,
    this.totalVolumeKg,
    this.lastTrained,
    this.daysSinceTrained,
    this.recommendedFrequency,
    this.frequencyStatus,
  });

  factory MuscleFrequencyData.fromJson(Map<String, dynamic> json) =>
      _$MuscleFrequencyDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleFrequencyDataToJson(this);

  /// Get formatted muscle group name
  String get formattedMuscleGroup {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get frequency display (e.g., "2.5x/week")
  String get frequencyDisplay => '${timesPerWeek.toStringAsFixed(1)}x/week';

  /// Get formatted volume
  String get formattedVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Get last trained date
  DateTime? get lastTrainedDate {
    if (lastTrained == null) return null;
    try {
      return DateTime.parse(lastTrained!);
    } catch (_) {
      return null;
    }
  }

  /// Get formatted last trained
  String get formattedLastTrained {
    if (daysSinceTrained != null) {
      if (daysSinceTrained == 0) return 'Today';
      if (daysSinceTrained == 1) return 'Yesterday';
      if (daysSinceTrained! < 7) return '$daysSinceTrained days ago';
    }
    final date = lastTrainedDate;
    if (date == null) return '-';
    return DateFormat('MMM d').format(date);
  }

  /// Whether this muscle is undertrained
  bool get isUndertrained => frequencyStatus == 'undertrained';

  /// Whether this muscle is overtrained
  bool get isOvertrained => frequencyStatus == 'overtrained';

  /// Whether this muscle has optimal training frequency
  bool get isOptimal => frequencyStatus == 'optimal';

  /// Get status color suggestion (for UI)
  String get statusColorHint {
    switch (frequencyStatus) {
      case 'undertrained':
        return 'warning';
      case 'overtrained':
        return 'error';
      case 'optimal':
        return 'success';
      default:
        return 'neutral';
    }
  }
}

// ============================================================================
// Muscle Balance Data
// ============================================================================

/// Push/pull and other balance ratios
@JsonSerializable()
class MuscleBalanceData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'push_pull_ratio')
  final double? pushPullRatio;

  @JsonKey(name: 'push_volume_kg')
  final double? pushVolumeKg;

  @JsonKey(name: 'pull_volume_kg')
  final double? pullVolumeKg;

  @JsonKey(name: 'upper_lower_ratio')
  final double? upperLowerRatio;

  @JsonKey(name: 'upper_volume_kg')
  final double? upperVolumeKg;

  @JsonKey(name: 'lower_volume_kg')
  final double? lowerVolumeKg;

  @JsonKey(name: 'anterior_posterior_ratio')
  final double? anteriorPosteriorRatio;

  @JsonKey(name: 'left_right_ratio')
  final double? leftRightRatio;

  @JsonKey(name: 'balance_score')
  final double? balanceScore; // 0-100 overall balance

  @JsonKey(name: 'recommendations')
  final List<String>? recommendations;

  @JsonKey(name: 'imbalances')
  final List<MuscleImbalance>? imbalances;

  const MuscleBalanceData({
    required this.userId,
    required this.timeRange,
    this.pushPullRatio,
    this.pushVolumeKg,
    this.pullVolumeKg,
    this.upperLowerRatio,
    this.upperVolumeKg,
    this.lowerVolumeKg,
    this.anteriorPosteriorRatio,
    this.leftRightRatio,
    this.balanceScore,
    this.recommendations,
    this.imbalances,
  });

  factory MuscleBalanceData.fromJson(Map<String, dynamic> json) =>
      _$MuscleBalanceDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleBalanceDataToJson(this);

  /// Get push/pull ratio as formatted string
  String get formattedPushPullRatio {
    if (pushPullRatio == null) return '-';
    return '${pushPullRatio!.toStringAsFixed(2)}:1';
  }

  /// Get upper/lower ratio as formatted string
  String get formattedUpperLowerRatio {
    if (upperLowerRatio == null) return '-';
    return '${upperLowerRatio!.toStringAsFixed(2)}:1';
  }

  /// Get balance score as percentage
  String get formattedBalanceScore {
    if (balanceScore == null) return '-';
    return '${balanceScore!.toStringAsFixed(0)}%';
  }

  /// Check if push/pull is balanced (ideal is ~1:1)
  bool get isPushPullBalanced {
    if (pushPullRatio == null) return false;
    return pushPullRatio! >= 0.8 && pushPullRatio! <= 1.2;
  }

  /// Check if upper/lower is balanced (ideal is ~1:1)
  bool get isUpperLowerBalanced {
    if (upperLowerRatio == null) return false;
    return upperLowerRatio! >= 0.8 && upperLowerRatio! <= 1.2;
  }

  /// Get push/pull status
  String get pushPullStatus {
    if (pushPullRatio == null) return 'unknown';
    if (pushPullRatio! > 1.3) return 'push_dominant';
    if (pushPullRatio! < 0.7) return 'pull_dominant';
    return 'balanced';
  }

  /// Get upper/lower status
  String get upperLowerStatus {
    if (upperLowerRatio == null) return 'unknown';
    if (upperLowerRatio! > 1.5) return 'upper_dominant';
    if (upperLowerRatio! < 0.67) return 'lower_dominant';
    return 'balanced';
  }

  /// Get formatted push volume
  String get formattedPushVolume {
    if (pushVolumeKg == null || pushVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (pushVolumeKg! >= 1000) {
      return '${(pushVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(pushVolumeKg!.round())} kg';
  }

  /// Get formatted pull volume
  String get formattedPullVolume {
    if (pullVolumeKg == null || pullVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (pullVolumeKg! >= 1000) {
      return '${(pullVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(pullVolumeKg!.round())} kg';
  }

  /// Check if there's any data
  bool get hasData =>
      pushPullRatio != null ||
      upperLowerRatio != null ||
      balanceScore != null;

  /// Check if there are any imbalances
  bool get hasImbalances => imbalances != null && imbalances!.isNotEmpty;
}

/// Specific muscle imbalance data
@JsonSerializable()
class MuscleImbalance {
  @JsonKey(name: 'muscle_pair')
  final String musclePair;

  final double ratio;

  @JsonKey(name: 'dominant_side')
  final String? dominantSide;

  @JsonKey(name: 'difference_percent')
  final double? differencePercent;

  final String? severity; // 'mild', 'moderate', 'severe'

  final String? recommendation;

  const MuscleImbalance({
    required this.musclePair,
    required this.ratio,
    this.dominantSide,
    this.differencePercent,
    this.severity,
    this.recommendation,
  });

  factory MuscleImbalance.fromJson(Map<String, dynamic> json) =>
      _$MuscleImbalanceFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleImbalanceToJson(this);

  /// Get formatted ratio
  String get formattedRatio => '${ratio.toStringAsFixed(2)}:1';

  /// Get formatted difference
  String get formattedDifference {
    if (differencePercent == null) return '-';
    return '${differencePercent!.toStringAsFixed(0)}%';
  }

  /// Whether this is a significant imbalance
  bool get isSignificant => severity == 'moderate' || severity == 'severe';
}

// ============================================================================
// Muscle Exercise Data
// ============================================================================

/// Exercises performed for a specific muscle group
@JsonSerializable()
class MuscleExerciseData {
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  @JsonKey(name: 'time_range')
  final String timeRange;

  final List<MuscleExerciseStats> exercises;

  @JsonKey(name: 'total_exercises')
  final int? totalExercises;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  const MuscleExerciseData({
    required this.muscleGroup,
    required this.timeRange,
    this.exercises = const [],
    this.totalExercises,
    this.totalVolumeKg,
    this.totalSets,
  });

  factory MuscleExerciseData.fromJson(Map<String, dynamic> json) =>
      _$MuscleExerciseDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleExerciseDataToJson(this);

  /// Get formatted muscle group name
  String get formattedMuscleGroup {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get exercises sorted by volume (highest first)
  List<MuscleExerciseStats> get sortedByVolume {
    final sorted = List<MuscleExerciseStats>.from(exercises);
    sorted.sort((a, b) => (b.totalVolumeKg ?? 0).compareTo(a.totalVolumeKg ?? 0));
    return sorted;
  }

  /// Get exercises sorted by frequency (highest first)
  List<MuscleExerciseStats> get sortedByFrequency {
    final sorted = List<MuscleExerciseStats>.from(exercises);
    sorted.sort((a, b) => b.timesPerformed.compareTo(a.timesPerformed));
    return sorted;
  }

  /// Get top N exercises by volume
  List<MuscleExerciseStats> getTopExercises(int count) {
    return sortedByVolume.take(count).toList();
  }

  /// Get formatted total volume
  String get formattedTotalVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Check if there's any data
  bool get hasData => exercises.isNotEmpty;
}

/// Stats for a single exercise targeting a muscle
@JsonSerializable()
class MuscleExerciseStats {
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

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

  @JsonKey(name: 'avg_weight_kg')
  final double? avgWeightKg;

  @JsonKey(name: 'volume_percentage')
  final double? volumePercentage; // Percentage of total muscle volume

  @JsonKey(name: 'last_performed')
  final String? lastPerformed;

  const MuscleExerciseStats({
    this.exerciseId,
    required this.exerciseName,
    this.timesPerformed = 0,
    this.totalSets,
    this.totalReps,
    this.totalVolumeKg,
    this.maxWeightKg,
    this.avgWeightKg,
    this.volumePercentage,
    this.lastPerformed,
  });

  factory MuscleExerciseStats.fromJson(Map<String, dynamic> json) =>
      _$MuscleExerciseStatsFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleExerciseStatsToJson(this);

  /// Get formatted volume
  String get formattedVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Get formatted max weight
  String get formattedMaxWeight {
    if (maxWeightKg == null || maxWeightKg == 0) return '-';
    if (maxWeightKg == maxWeightKg!.toInt()) {
      return '${maxWeightKg!.toInt()} kg';
    }
    return '${maxWeightKg!.toStringAsFixed(1)} kg';
  }

  /// Get volume percentage display
  String get volumePercentDisplay {
    if (volumePercentage == null) return '-';
    return '${volumePercentage!.toStringAsFixed(0)}%';
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

  /// Get formatted last performed
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

// ============================================================================
// Muscle History Data
// ============================================================================

/// Workout history for a specific muscle group
@JsonSerializable()
class MuscleHistoryData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  @JsonKey(name: 'time_range')
  final String timeRange;

  final List<MuscleWorkoutEntry> history;

  final MuscleHistorySummary? summary;

  const MuscleHistoryData({
    required this.userId,
    required this.muscleGroup,
    required this.timeRange,
    this.history = const [],
    this.summary,
  });

  factory MuscleHistoryData.fromJson(Map<String, dynamic> json) =>
      _$MuscleHistoryDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleHistoryDataToJson(this);

  /// Get formatted muscle group name
  String get formattedMuscleGroup {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get history sorted by date (newest first)
  List<MuscleWorkoutEntry> get sortedNewestFirst {
    final sorted = List<MuscleWorkoutEntry>.from(history);
    sorted.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
    return sorted;
  }

  /// Get history sorted by date (oldest first)
  List<MuscleWorkoutEntry> get sortedOldestFirst {
    final sorted = List<MuscleWorkoutEntry>.from(history);
    sorted.sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    return sorted;
  }

  /// Get chart data points for volume
  List<MuscleChartDataPoint> get volumeChartData {
    return sortedOldestFirst
        .map((e) => MuscleChartDataPoint(
              date: e.workoutDate,
              value: e.totalVolumeKg ?? 0,
              label: e.formattedVolume,
            ))
        .toList();
  }

  /// Check if there's any data
  bool get hasData => history.isNotEmpty;
}

/// Single workout entry for muscle history
@JsonSerializable()
class MuscleWorkoutEntry {
  @JsonKey(name: 'workout_id')
  final String workoutId;

  @JsonKey(name: 'workout_date')
  final String workoutDate;

  @JsonKey(name: 'workout_name')
  final String? workoutName;

  @JsonKey(name: 'exercises_count')
  final int exercisesCount;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'total_reps')
  final int? totalReps;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'max_weight_kg')
  final double? maxWeightKg;

  @JsonKey(name: 'exercises')
  final List<String>? exerciseNames;

  const MuscleWorkoutEntry({
    required this.workoutId,
    required this.workoutDate,
    this.workoutName,
    this.exercisesCount = 0,
    this.totalSets,
    this.totalReps,
    this.totalVolumeKg,
    this.maxWeightKg,
    this.exerciseNames,
  });

  factory MuscleWorkoutEntry.fromJson(Map<String, dynamic> json) =>
      _$MuscleWorkoutEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleWorkoutEntryToJson(this);

  /// Get workout date
  DateTime? get workoutDateTime {
    try {
      return DateTime.parse(workoutDate);
    } catch (_) {
      return null;
    }
  }

  /// Get formatted date
  String get formattedDate {
    final date = workoutDateTime;
    if (date == null) return workoutDate;
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Get formatted date short
  String get formattedDateShort {
    final date = workoutDateTime;
    if (date == null) return workoutDate;
    return DateFormat('MMM d').format(date);
  }

  /// Get formatted volume
  String get formattedVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Get formatted max weight
  String get formattedMaxWeight {
    if (maxWeightKg == null || maxWeightKg == 0) return '-';
    if (maxWeightKg == maxWeightKg!.toInt()) {
      return '${maxWeightKg!.toInt()} kg';
    }
    return '${maxWeightKg!.toStringAsFixed(1)} kg';
  }

  /// Get sets x reps display
  String get setsRepsDisplay {
    if (totalSets == null) return '-';
    if (totalReps != null) {
      return '$totalSets sets, $totalReps reps';
    }
    return '$totalSets sets';
  }
}

/// Summary for muscle history
@JsonSerializable()
class MuscleHistorySummary {
  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;

  @JsonKey(name: 'total_volume_kg')
  final double? totalVolumeKg;

  @JsonKey(name: 'avg_volume_per_workout_kg')
  final double? avgVolumePerWorkoutKg;

  @JsonKey(name: 'max_volume_kg')
  final double? maxVolumeKg;

  @JsonKey(name: 'max_weight_kg')
  final double? maxWeightKg;

  @JsonKey(name: 'total_sets')
  final int? totalSets;

  @JsonKey(name: 'volume_trend')
  final String? volumeTrend; // 'increasing', 'stable', 'decreasing'

  @JsonKey(name: 'volume_change_percent')
  final double? volumeChangePercent;

  const MuscleHistorySummary({
    this.totalWorkouts = 0,
    this.totalVolumeKg,
    this.avgVolumePerWorkoutKg,
    this.maxVolumeKg,
    this.maxWeightKg,
    this.totalSets,
    this.volumeTrend,
    this.volumeChangePercent,
  });

  factory MuscleHistorySummary.fromJson(Map<String, dynamic> json) =>
      _$MuscleHistorySummaryFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleHistorySummaryToJson(this);

  /// Get formatted total volume
  String get formattedTotalVolume {
    if (totalVolumeKg == null || totalVolumeKg == 0) return '-';
    final formatter = NumberFormat('#,###');
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${formatter.format(totalVolumeKg!.round())} kg';
  }

  /// Get formatted average volume
  String get formattedAvgVolume {
    if (avgVolumePerWorkoutKg == null || avgVolumePerWorkoutKg == 0) return '-';
    return '${avgVolumePerWorkoutKg!.toStringAsFixed(0)} kg';
  }

  /// Get formatted max weight
  String get formattedMaxWeight {
    if (maxWeightKg == null || maxWeightKg == 0) return '-';
    if (maxWeightKg == maxWeightKg!.toInt()) {
      return '${maxWeightKg!.toInt()} kg';
    }
    return '${maxWeightKg!.toStringAsFixed(1)} kg';
  }

  /// Get trend display
  String get trendDisplay {
    switch (volumeTrend) {
      case 'increasing':
        return 'Increasing';
      case 'stable':
        return 'Stable';
      case 'decreasing':
        return 'Decreasing';
      default:
        return 'N/A';
    }
  }

  /// Get volume change display
  String get volumeChangeDisplay {
    if (volumeChangePercent == null) return '-';
    final sign = volumeChangePercent! >= 0 ? '+' : '';
    return '$sign${volumeChangePercent!.toStringAsFixed(1)}%';
  }

  /// Check if volume is increasing
  bool get isIncreasing => volumeTrend == 'increasing';

  /// Check if volume is stable
  bool get isStable => volumeTrend == 'stable';

  /// Check if volume is decreasing
  bool get isDecreasing => volumeTrend == 'decreasing';
}

/// Chart data point for muscle analytics
@JsonSerializable()
class MuscleChartDataPoint {
  final String date;

  final double value;

  final String? label;

  const MuscleChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  factory MuscleChartDataPoint.fromJson(Map<String, dynamic> json) =>
      _$MuscleChartDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleChartDataPointToJson(this);

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
}
