/// NEAT score models for tracking daily non-exercise activity.
///
/// These models support:
/// - Daily NEAT score calculation
/// - Score trend analysis
/// - Goal achievement tracking
/// - Historical score comparisons
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_score.g.dart';

/// Trend direction for NEAT scores
enum NeatScoreTrendDirection {
  @JsonValue('improving')
  improving,
  @JsonValue('stable')
  stable,
  @JsonValue('declining')
  declining;

  String get displayName {
    switch (this) {
      case NeatScoreTrendDirection.improving:
        return 'Improving';
      case NeatScoreTrendDirection.stable:
        return 'Stable';
      case NeatScoreTrendDirection.declining:
        return 'Declining';
    }
  }

  String get icon {
    switch (this) {
      case NeatScoreTrendDirection.improving:
        return 'trending_up';
      case NeatScoreTrendDirection.stable:
        return 'trending_flat';
      case NeatScoreTrendDirection.declining:
        return 'trending_down';
    }
  }

  int get colorValue {
    switch (this) {
      case NeatScoreTrendDirection.improving:
        return 0xFF4CAF50; // Green
      case NeatScoreTrendDirection.stable:
        return 0xFFFFC107; // Amber
      case NeatScoreTrendDirection.declining:
        return 0xFFF44336; // Red
    }
  }
}

/// Score rating based on NEAT score value
enum NeatScoreRating {
  excellent,
  good,
  fair,
  needsImprovement;

  String get displayName {
    switch (this) {
      case NeatScoreRating.excellent:
        return 'Excellent';
      case NeatScoreRating.good:
        return 'Good';
      case NeatScoreRating.fair:
        return 'Fair';
      case NeatScoreRating.needsImprovement:
        return 'Needs Improvement';
    }
  }

  int get colorValue {
    switch (this) {
      case NeatScoreRating.excellent:
        return 0xFF4CAF50; // Green
      case NeatScoreRating.good:
        return 0xFF8BC34A; // Light Green
      case NeatScoreRating.fair:
        return 0xFFFFC107; // Amber
      case NeatScoreRating.needsImprovement:
        return 0xFFF44336; // Red
    }
  }
}

/// Daily NEAT score for a user
@JsonSerializable()
class NeatDailyScore {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'score_date')
  final String scoreDate;

  @JsonKey(name: 'neat_score')
  final double neatScore;

  @JsonKey(name: 'total_steps')
  final int totalSteps;

  @JsonKey(name: 'active_hours')
  final int activeHours;

  @JsonKey(name: 'sedentary_hours')
  final int sedentaryHours;

  @JsonKey(name: 'step_goal_achieved')
  final bool stepGoalAchieved;

  @JsonKey(name: 'goal_at_time')
  final int goalAtTime;

  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  @JsonKey(name: 'calories_burned')
  final int? caloriesBurned;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const NeatDailyScore({
    this.id,
    required this.userId,
    required this.scoreDate,
    this.neatScore = 0.0,
    this.totalSteps = 0,
    this.activeHours = 0,
    this.sedentaryHours = 0,
    this.stepGoalAchieved = false,
    this.goalAtTime = 0,
    this.distanceKm,
    this.caloriesBurned,
    this.createdAt,
  });

  factory NeatDailyScore.fromJson(Map<String, dynamic> json) =>
      _$NeatDailyScoreFromJson(json);

  Map<String, dynamic> toJson() => _$NeatDailyScoreToJson(this);

  /// Get the score date as DateTime
  DateTime get date => DateTime.parse(scoreDate);

  /// Get the score rating based on value
  NeatScoreRating get rating {
    if (neatScore >= 80) return NeatScoreRating.excellent;
    if (neatScore >= 60) return NeatScoreRating.good;
    if (neatScore >= 40) return NeatScoreRating.fair;
    return NeatScoreRating.needsImprovement;
  }

  /// Get score as percentage of maximum (100)
  double get scorePercentage => neatScore.clamp(0.0, 100.0);

  /// Progress toward step goal
  double get stepGoalProgress {
    if (goalAtTime <= 0) return 0.0;
    return (totalSteps / goalAtTime).clamp(0.0, 1.0);
  }

  /// Formatted step count
  String get formattedSteps {
    if (totalSteps >= 1000) {
      return '${(totalSteps / 1000).toStringAsFixed(1)}k';
    }
    return totalSteps.toString();
  }

  /// Active hours ratio
  double get activeHoursRatio {
    final totalTrackedHours = activeHours + sedentaryHours;
    if (totalTrackedHours == 0) return 0.0;
    return activeHours / totalTrackedHours;
  }

  /// Create a copy with updated values
  NeatDailyScore copyWith({
    String? id,
    String? userId,
    String? scoreDate,
    double? neatScore,
    int? totalSteps,
    int? activeHours,
    int? sedentaryHours,
    bool? stepGoalAchieved,
    int? goalAtTime,
    double? distanceKm,
    int? caloriesBurned,
    DateTime? createdAt,
  }) {
    return NeatDailyScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scoreDate: scoreDate ?? this.scoreDate,
      neatScore: neatScore ?? this.neatScore,
      totalSteps: totalSteps ?? this.totalSteps,
      activeHours: activeHours ?? this.activeHours,
      sedentaryHours: sedentaryHours ?? this.sedentaryHours,
      stepGoalAchieved: stepGoalAchieved ?? this.stepGoalAchieved,
      goalAtTime: goalAtTime ?? this.goalAtTime,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Collection of daily scores with trend analysis
@JsonSerializable()
class NeatScoreTrend {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'daily_scores')
  final List<NeatDailyScore> dailyScores;

  @JsonKey(name: 'trend_direction')
  final NeatScoreTrendDirection trendDirection;

  @JsonKey(name: 'average_score')
  final double averageScore;

  @JsonKey(name: 'average_steps')
  final double averageSteps;

  @JsonKey(name: 'average_active_hours')
  final double averageActiveHours;

  @JsonKey(name: 'goal_achievement_rate')
  final double goalAchievementRate;

  @JsonKey(name: 'period_start')
  final String? periodStart;

  @JsonKey(name: 'period_end')
  final String? periodEnd;

  @JsonKey(name: 'trend_percentage')
  final double? trendPercentage;

  @JsonKey(name: 'insight')
  final String? insight;

  const NeatScoreTrend({
    required this.userId,
    this.dailyScores = const [],
    this.trendDirection = NeatScoreTrendDirection.stable,
    this.averageScore = 0.0,
    this.averageSteps = 0.0,
    this.averageActiveHours = 0.0,
    this.goalAchievementRate = 0.0,
    this.periodStart,
    this.periodEnd,
    this.trendPercentage,
    this.insight,
  });

  factory NeatScoreTrend.fromJson(Map<String, dynamic> json) =>
      _$NeatScoreTrendFromJson(json);

  Map<String, dynamic> toJson() => _$NeatScoreTrendToJson(this);

  /// Number of days in the trend period
  int get periodDays => dailyScores.length;

  /// Total steps across the period
  int get totalSteps => dailyScores.fold(0, (sum, s) => sum + s.totalSteps);

  /// Number of days where goal was achieved
  int get daysGoalAchieved =>
      dailyScores.where((s) => s.stepGoalAchieved).length;

  /// Best day in the period
  NeatDailyScore? get bestDay {
    if (dailyScores.isEmpty) return null;
    return dailyScores.reduce((a, b) => a.neatScore >= b.neatScore ? a : b);
  }

  /// Worst day in the period
  NeatDailyScore? get worstDay {
    if (dailyScores.isEmpty) return null;
    return dailyScores.reduce((a, b) => a.neatScore <= b.neatScore ? a : b);
  }

  /// Score improvement from first to last day
  double get scoreImprovement {
    if (dailyScores.length < 2) return 0.0;
    return dailyScores.last.neatScore - dailyScores.first.neatScore;
  }

  /// Check if trend is positive
  bool get isImproving => trendDirection == NeatScoreTrendDirection.improving;

  /// Get period start date
  DateTime? get startDate =>
      periodStart != null ? DateTime.tryParse(periodStart!) : null;

  /// Get period end date
  DateTime? get endDate =>
      periodEnd != null ? DateTime.tryParse(periodEnd!) : null;

  /// Weekly averages for chart display
  List<WeeklyNeatSummary> get weeklySummaries {
    if (dailyScores.isEmpty) return [];

    final Map<String, List<NeatDailyScore>> byWeek = {};
    for (final score in dailyScores) {
      final date = score.date;
      final weekStart = date.subtract(Duration(days: date.weekday % 7));
      final weekKey =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      byWeek.putIfAbsent(weekKey, () => []).add(score);
    }

    return byWeek.entries.map((entry) {
      final scores = entry.value;
      return WeeklyNeatSummary(
        weekStart: entry.key,
        averageScore:
            scores.map((s) => s.neatScore).reduce((a, b) => a + b) / scores.length,
        averageSteps:
            scores.map((s) => s.totalSteps).reduce((a, b) => a + b) / scores.length,
        daysTracked: scores.length,
        daysGoalAchieved: scores.where((s) => s.stepGoalAchieved).length,
      );
    }).toList();
  }
}

/// Weekly summary for trend charts
@JsonSerializable()
class WeeklyNeatSummary {
  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'average_score')
  final double averageScore;

  @JsonKey(name: 'average_steps')
  final double averageSteps;

  @JsonKey(name: 'days_tracked')
  final int daysTracked;

  @JsonKey(name: 'days_goal_achieved')
  final int daysGoalAchieved;

  const WeeklyNeatSummary({
    required this.weekStart,
    this.averageScore = 0.0,
    this.averageSteps = 0.0,
    this.daysTracked = 0,
    this.daysGoalAchieved = 0,
  });

  factory WeeklyNeatSummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklyNeatSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyNeatSummaryToJson(this);

  /// Week start as DateTime
  DateTime get weekStartDate => DateTime.parse(weekStart);

  /// Goal achievement rate for the week
  double get goalAchievementRate {
    if (daysTracked == 0) return 0.0;
    return daysGoalAchieved / daysTracked;
  }
}
