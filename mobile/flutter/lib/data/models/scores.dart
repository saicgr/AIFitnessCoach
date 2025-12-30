import 'package:json_annotation/json_annotation.dart';

part 'scores.g.dart';

/// Strength level classification
enum StrengthLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('novice')
  novice,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('elite')
  elite,
}

/// Readiness level classification
enum ReadinessLevel {
  @JsonValue('low')
  low,
  @JsonValue('moderate')
  moderate,
  @JsonValue('good')
  good,
  @JsonValue('optimal')
  optimal,
}

/// Workout intensity recommendation
enum WorkoutIntensity {
  @JsonValue('rest')
  rest,
  @JsonValue('light')
  light,
  @JsonValue('moderate')
  moderate,
  @JsonValue('high')
  high,
  @JsonValue('max')
  max,
}

/// Trend direction
enum TrendDirection {
  @JsonValue('improving')
  improving,
  @JsonValue('maintaining')
  maintaining,
  @JsonValue('declining')
  declining,
}

// ============================================================================
// Readiness Models
// ============================================================================

/// Request model for daily readiness check-in
@JsonSerializable()
class ReadinessCheckInRequest {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'score_date')
  final String? scoreDate;

  @JsonKey(name: 'sleep_quality')
  final int sleepQuality; // 1-7 (1=excellent, 7=very poor)

  @JsonKey(name: 'fatigue_level')
  final int fatigueLevel; // 1-7 (1=fresh, 7=exhausted)

  @JsonKey(name: 'stress_level')
  final int stressLevel; // 1-7 (1=relaxed, 7=extremely stressed)

  @JsonKey(name: 'muscle_soreness')
  final int muscleSoreness; // 1-7 (1=none, 7=severe)

  final int? mood; // 1-7
  @JsonKey(name: 'energy_level')
  final int? energyLevel; // 1-7

  const ReadinessCheckInRequest({
    required this.userId,
    this.scoreDate,
    required this.sleepQuality,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.muscleSoreness,
    this.mood,
    this.energyLevel,
  });

  factory ReadinessCheckInRequest.fromJson(Map<String, dynamic> json) =>
      _$ReadinessCheckInRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReadinessCheckInRequestToJson(this);
}

/// Response model for readiness data
@JsonSerializable()
class ReadinessScore {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'score_date')
  final String scoreDate;
  @JsonKey(name: 'sleep_quality')
  final int sleepQuality;
  @JsonKey(name: 'fatigue_level')
  final int fatigueLevel;
  @JsonKey(name: 'stress_level')
  final int stressLevel;
  @JsonKey(name: 'muscle_soreness')
  final int muscleSoreness;
  final int? mood;
  @JsonKey(name: 'energy_level')
  final int? energyLevel;
  @JsonKey(name: 'hooper_index')
  final int hooperIndex;
  @JsonKey(name: 'readiness_score')
  final int readinessScore;
  @JsonKey(name: 'readiness_level')
  final String readinessLevel;
  @JsonKey(name: 'ai_workout_recommendation')
  final String? aiWorkoutRecommendation;
  @JsonKey(name: 'recommended_intensity')
  final String? recommendedIntensity;
  @JsonKey(name: 'ai_insight')
  final String? aiInsight;
  @JsonKey(name: 'submitted_at')
  final String submittedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ReadinessScore({
    required this.id,
    required this.userId,
    required this.scoreDate,
    required this.sleepQuality,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.muscleSoreness,
    this.mood,
    this.energyLevel,
    required this.hooperIndex,
    required this.readinessScore,
    required this.readinessLevel,
    this.aiWorkoutRecommendation,
    this.recommendedIntensity,
    this.aiInsight,
    required this.submittedAt,
    required this.createdAt,
  });

  factory ReadinessScore.fromJson(Map<String, dynamic> json) =>
      _$ReadinessScoreFromJson(json);
  Map<String, dynamic> toJson() => _$ReadinessScoreToJson(this);

  /// Get the ReadinessLevel enum from string
  ReadinessLevel get level {
    switch (readinessLevel.toLowerCase()) {
      case 'optimal':
        return ReadinessLevel.optimal;
      case 'good':
        return ReadinessLevel.good;
      case 'moderate':
        return ReadinessLevel.moderate;
      default:
        return ReadinessLevel.low;
    }
  }

  /// Get intensity recommendation as enum
  WorkoutIntensity get intensity {
    switch (recommendedIntensity?.toLowerCase()) {
      case 'max':
        return WorkoutIntensity.max;
      case 'high':
        return WorkoutIntensity.high;
      case 'moderate':
        return WorkoutIntensity.moderate;
      case 'light':
        return WorkoutIntensity.light;
      default:
        return WorkoutIntensity.rest;
    }
  }

  /// Get color for readiness level (0xAARRGGBB format)
  int get levelColor {
    switch (level) {
      case ReadinessLevel.optimal:
        return 0xFF4CAF50; // Green
      case ReadinessLevel.good:
        return 0xFF8BC34A; // Light Green
      case ReadinessLevel.moderate:
        return 0xFFFF9800; // Orange
      case ReadinessLevel.low:
        return 0xFFF44336; // Red
    }
  }
}

/// Response model for readiness history
@JsonSerializable()
class ReadinessHistory {
  @JsonKey(name: 'readiness_scores')
  final List<ReadinessScore> readinessScores;
  @JsonKey(name: 'average_score')
  final double averageScore;
  final String trend;
  @JsonKey(name: 'days_above_60')
  final int daysAbove60;
  @JsonKey(name: 'total_days')
  final int totalDays;

  const ReadinessHistory({
    required this.readinessScores,
    required this.averageScore,
    required this.trend,
    required this.daysAbove60,
    required this.totalDays,
  });

  factory ReadinessHistory.fromJson(Map<String, dynamic> json) =>
      _$ReadinessHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ReadinessHistoryToJson(this);

  TrendDirection get trendDirection {
    switch (trend.toLowerCase()) {
      case 'improving':
        return TrendDirection.improving;
      case 'declining':
        return TrendDirection.declining;
      default:
        return TrendDirection.maintaining;
    }
  }
}

// ============================================================================
// Strength Score Models
// ============================================================================

/// Response model for muscle group strength score
@JsonSerializable()
class StrengthScoreData {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'strength_score')
  final int strengthScore;
  @JsonKey(name: 'strength_level')
  final String strengthLevel;
  @JsonKey(name: 'best_exercise_name')
  final String? bestExerciseName;
  @JsonKey(name: 'best_estimated_1rm_kg')
  final double? bestEstimated1rmKg;
  @JsonKey(name: 'bodyweight_ratio')
  final double? bodyweightRatio;
  @JsonKey(name: 'weekly_sets')
  final int weeklySets;
  @JsonKey(name: 'weekly_volume_kg')
  final double weeklyVolumeKg;
  final String trend;
  @JsonKey(name: 'previous_score')
  final int? previousScore;
  @JsonKey(name: 'score_change')
  final int? scoreChange;
  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const StrengthScoreData({
    this.id,
    required this.userId,
    required this.muscleGroup,
    required this.strengthScore,
    required this.strengthLevel,
    this.bestExerciseName,
    this.bestEstimated1rmKg,
    this.bodyweightRatio,
    this.weeklySets = 0,
    this.weeklyVolumeKg = 0,
    this.trend = 'maintaining',
    this.previousScore,
    this.scoreChange,
    this.calculatedAt,
  });

  factory StrengthScoreData.fromJson(Map<String, dynamic> json) =>
      _$StrengthScoreDataFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthScoreDataToJson(this);

  /// Get the StrengthLevel enum from string
  StrengthLevel get level {
    switch (strengthLevel.toLowerCase()) {
      case 'elite':
        return StrengthLevel.elite;
      case 'advanced':
        return StrengthLevel.advanced;
      case 'intermediate':
        return StrengthLevel.intermediate;
      case 'novice':
        return StrengthLevel.novice;
      default:
        return StrengthLevel.beginner;
    }
  }

  /// Get trend direction
  TrendDirection get trendDirection {
    switch (trend.toLowerCase()) {
      case 'improving':
        return TrendDirection.improving;
      case 'declining':
        return TrendDirection.declining;
      default:
        return TrendDirection.maintaining;
    }
  }

  /// Get display name for muscle group
  String get muscleGroupDisplayName {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get level display name
  String get levelDisplayName {
    return strengthLevel[0].toUpperCase() + strengthLevel.substring(1);
  }

  /// Get color for strength level (0xAARRGGBB format)
  int get levelColor {
    switch (level) {
      case StrengthLevel.elite:
        return 0xFF9C27B0; // Purple
      case StrengthLevel.advanced:
        return 0xFF2196F3; // Blue
      case StrengthLevel.intermediate:
        return 0xFF4CAF50; // Green
      case StrengthLevel.novice:
        return 0xFFFF9800; // Orange
      case StrengthLevel.beginner:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Get progress to next level (0.0 - 1.0)
  double get progressToNextLevel {
    // Approximate thresholds
    const thresholds = [0, 25, 50, 70, 90, 100];
    final currentIndex = level.index;
    if (currentIndex >= thresholds.length - 1) return 1.0;

    final currentThreshold = thresholds[currentIndex];
    final nextThreshold = thresholds[currentIndex + 1];
    final range = nextThreshold - currentThreshold;

    return ((strengthScore - currentThreshold) / range).clamp(0.0, 1.0);
  }
}

/// Response model for all strength scores
@JsonSerializable()
class AllStrengthScores {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'overall_score')
  final int overallScore;
  @JsonKey(name: 'overall_level')
  final String overallLevel;
  @JsonKey(name: 'muscle_scores')
  final Map<String, StrengthScoreData> muscleScores;
  @JsonKey(name: 'calculated_at')
  final String calculatedAt;

  const AllStrengthScores({
    required this.userId,
    required this.overallScore,
    required this.overallLevel,
    required this.muscleScores,
    required this.calculatedAt,
  });

  factory AllStrengthScores.fromJson(Map<String, dynamic> json) =>
      _$AllStrengthScoresFromJson(json);
  Map<String, dynamic> toJson() => _$AllStrengthScoresToJson(this);

  /// Get the overall StrengthLevel enum
  StrengthLevel get level {
    switch (overallLevel.toLowerCase()) {
      case 'elite':
        return StrengthLevel.elite;
      case 'advanced':
        return StrengthLevel.advanced;
      case 'intermediate':
        return StrengthLevel.intermediate;
      case 'novice':
        return StrengthLevel.novice;
      default:
        return StrengthLevel.beginner;
    }
  }

  /// Get sorted muscle scores (by score descending)
  List<StrengthScoreData> get sortedMuscleScores {
    final scores = muscleScores.values.toList();
    scores.sort((a, b) => b.strengthScore.compareTo(a.strengthScore));
    return scores;
  }

  /// Get strongest muscle groups
  List<StrengthScoreData> get strongestMuscles =>
      sortedMuscleScores.take(3).toList();

  /// Get weakest muscle groups
  List<StrengthScoreData> get weakestMuscles =>
      sortedMuscleScores.reversed.take(3).toList();
}

/// Response model for detailed muscle group strength
@JsonSerializable()
class StrengthDetail {
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'strength_score')
  final int strengthScore;
  @JsonKey(name: 'strength_level')
  final String strengthLevel;
  @JsonKey(name: 'best_exercise_name')
  final String? bestExerciseName;
  @JsonKey(name: 'best_estimated_1rm_kg')
  final double? bestEstimated1rmKg;
  @JsonKey(name: 'bodyweight_ratio')
  final double? bodyweightRatio;
  final List<Map<String, dynamic>> exercises;
  @JsonKey(name: 'trend_data')
  final List<Map<String, dynamic>> trendData;
  final List<String> recommendations;

  const StrengthDetail({
    required this.muscleGroup,
    required this.strengthScore,
    required this.strengthLevel,
    this.bestExerciseName,
    this.bestEstimated1rmKg,
    this.bodyweightRatio,
    this.exercises = const [],
    this.trendData = const [],
    this.recommendations = const [],
  });

  factory StrengthDetail.fromJson(Map<String, dynamic> json) =>
      _$StrengthDetailFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthDetailToJson(this);
}

// ============================================================================
// Personal Records Models
// ============================================================================

/// Response model for a personal record
@JsonSerializable()
class PersonalRecordScore {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;
  @JsonKey(name: 'weight_kg')
  final double weightKg;
  final int reps;
  @JsonKey(name: 'estimated_1rm_kg')
  final double estimated1rmKg;
  @JsonKey(name: 'set_type')
  final String setType;
  final double? rpe;
  @JsonKey(name: 'achieved_at')
  final String achievedAt;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'previous_weight_kg')
  final double? previousWeightKg;
  @JsonKey(name: 'previous_1rm_kg')
  final double? previous1rmKg;
  @JsonKey(name: 'improvement_kg')
  final double? improvementKg;
  @JsonKey(name: 'improvement_percent')
  final double? improvementPercent;
  @JsonKey(name: 'is_all_time_pr')
  final bool isAllTimePr;
  @JsonKey(name: 'celebration_message')
  final String? celebrationMessage;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const PersonalRecordScore({
    required this.id,
    required this.userId,
    required this.exerciseName,
    this.exerciseId,
    this.muscleGroup,
    required this.weightKg,
    required this.reps,
    required this.estimated1rmKg,
    this.setType = 'working',
    this.rpe,
    required this.achievedAt,
    this.workoutId,
    this.previousWeightKg,
    this.previous1rmKg,
    this.improvementKg,
    this.improvementPercent,
    this.isAllTimePr = true,
    this.celebrationMessage,
    required this.createdAt,
  });

  factory PersonalRecordScore.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordScoreFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalRecordScoreToJson(this);

  /// Get display name for exercise
  String get exerciseDisplayName {
    return exerciseName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Format the lift as "weight x reps"
  String get liftDescription => '${weightKg.toStringAsFixed(1)}kg x $reps';
}

/// Response model for PR statistics
@JsonSerializable()
class PRStats {
  @JsonKey(name: 'total_prs')
  final int totalPrs;
  @JsonKey(name: 'prs_this_period')
  final int prsThisPeriod;
  @JsonKey(name: 'exercises_with_prs')
  final int exercisesWithPrs;
  @JsonKey(name: 'best_improvement_percent')
  final double? bestImprovementPercent;
  @JsonKey(name: 'most_improved_exercise')
  final String? mostImprovedExercise;
  @JsonKey(name: 'longest_pr_streak')
  final int longestPrStreak;
  @JsonKey(name: 'current_pr_streak')
  final int currentPrStreak;
  @JsonKey(name: 'recent_prs')
  final List<PersonalRecordScore> recentPrs;

  const PRStats({
    required this.totalPrs,
    required this.prsThisPeriod,
    required this.exercisesWithPrs,
    this.bestImprovementPercent,
    this.mostImprovedExercise,
    required this.longestPrStreak,
    required this.currentPrStreak,
    this.recentPrs = const [],
  });

  factory PRStats.fromJson(Map<String, dynamic> json) =>
      _$PRStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PRStatsToJson(this);
}

// ============================================================================
// Overview/Dashboard Model
// ============================================================================

/// Combined dashboard response
@JsonSerializable()
class ScoresOverview {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'today_readiness')
  final ReadinessScore? todayReadiness;
  @JsonKey(name: 'has_checked_in_today')
  final bool hasCheckedInToday;
  @JsonKey(name: 'overall_strength_score')
  final int overallStrengthScore;
  @JsonKey(name: 'overall_strength_level')
  final String overallStrengthLevel;
  @JsonKey(name: 'muscle_scores_summary')
  final Map<String, int> muscleScoresSummary;
  @JsonKey(name: 'recent_prs')
  final List<PersonalRecordScore> recentPrs;
  @JsonKey(name: 'pr_count_30_days')
  final int prCount30Days;
  @JsonKey(name: 'readiness_average_7_days')
  final double? readinessAverage7Days;

  const ScoresOverview({
    required this.userId,
    this.todayReadiness,
    required this.hasCheckedInToday,
    required this.overallStrengthScore,
    required this.overallStrengthLevel,
    required this.muscleScoresSummary,
    this.recentPrs = const [],
    required this.prCount30Days,
    this.readinessAverage7Days,
  });

  factory ScoresOverview.fromJson(Map<String, dynamic> json) =>
      _$ScoresOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$ScoresOverviewToJson(this);

  /// Get overall strength level enum
  StrengthLevel get strengthLevel {
    switch (overallStrengthLevel.toLowerCase()) {
      case 'elite':
        return StrengthLevel.elite;
      case 'advanced':
        return StrengthLevel.advanced;
      case 'intermediate':
        return StrengthLevel.intermediate;
      case 'novice':
        return StrengthLevel.novice;
      default:
        return StrengthLevel.beginner;
    }
  }
}
