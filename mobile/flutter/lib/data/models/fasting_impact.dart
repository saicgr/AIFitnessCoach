import 'package:json_annotation/json_annotation.dart';

part 'fasting_impact.g.dart';

/// Time period for fasting impact analysis
enum FastingImpactPeriod {
  week('1 Week', 7, 'week'),
  month('1 Month', 30, 'month'),
  threeMonths('3 Months', 90, '3months');

  final String displayName;
  final int days;
  final String apiValue;

  const FastingImpactPeriod(this.displayName, this.days, this.apiValue);
}

/// Correlation strength indicator
enum CorrelationStrength {
  strongPositive('Strong Positive', 0.7, 1.0),
  moderatePositive('Moderate Positive', 0.3, 0.7),
  weak('Weak/Neutral', -0.3, 0.3),
  moderateNegative('Moderate Negative', -0.7, -0.3),
  strongNegative('Strong Negative', -1.0, -0.7);

  final String displayName;
  final double minValue;
  final double maxValue;

  const CorrelationStrength(this.displayName, this.minValue, this.maxValue);

  static CorrelationStrength fromScore(double score) {
    if (score >= 0.7) return CorrelationStrength.strongPositive;
    if (score >= 0.3) return CorrelationStrength.moderatePositive;
    if (score >= -0.3) return CorrelationStrength.weak;
    if (score >= -0.7) return CorrelationStrength.moderateNegative;
    return CorrelationStrength.strongNegative;
  }

  bool get isPositive => minValue >= 0.3;
  bool get isNegative => maxValue <= -0.3;
  bool get isNeutral => !isPositive && !isNegative;
}

/// Daily data point for fasting impact analysis
@JsonSerializable()
class FastingDayData {
  final DateTime date;
  @JsonKey(name: 'is_fasting_day')
  final bool isFastingDay;
  @JsonKey(name: 'fasting_hours')
  final double? fastingHours;
  final double? weight;
  @JsonKey(name: 'weight_change')
  final double? weightChange;
  @JsonKey(name: 'had_workout')
  final bool hadWorkout;
  @JsonKey(name: 'workout_performance_score')
  final double? workoutPerformanceScore;
  @JsonKey(name: 'goals_completed')
  final int goalsCompleted;
  @JsonKey(name: 'goals_total')
  final int goalsTotal;
  @JsonKey(name: 'energy_level')
  final int? energyLevel;
  @JsonKey(name: 'calories_consumed')
  final int? caloriesConsumed;

  const FastingDayData({
    required this.date,
    required this.isFastingDay,
    this.fastingHours,
    this.weight,
    this.weightChange,
    this.hadWorkout = false,
    this.workoutPerformanceScore,
    this.goalsCompleted = 0,
    this.goalsTotal = 0,
    this.energyLevel,
    this.caloriesConsumed,
  });

  double get goalCompletionRate =>
      goalsTotal > 0 ? goalsCompleted / goalsTotal : 0;

  factory FastingDayData.fromJson(Map<String, dynamic> json) =>
      _$FastingDayDataFromJson(json);
  Map<String, dynamic> toJson() => _$FastingDayDataToJson(this);
}

/// Summary statistics for fasting vs non-fasting comparison
@JsonSerializable()
class FastingComparisonStats {
  @JsonKey(name: 'fasting_days_count')
  final int fastingDaysCount;
  @JsonKey(name: 'non_fasting_days_count')
  final int nonFastingDaysCount;

  // Weight metrics
  @JsonKey(name: 'avg_weight_fasting')
  final double? avgWeightFasting;
  @JsonKey(name: 'avg_weight_non_fasting')
  final double? avgWeightNonFasting;
  @JsonKey(name: 'weight_loss_fasting_days')
  final double? weightLossFastingDays;
  @JsonKey(name: 'weight_loss_non_fasting_days')
  final double? weightLossNonFastingDays;

  // Workout metrics
  @JsonKey(name: 'avg_workout_performance_fasting')
  final double? avgWorkoutPerformanceFasting;
  @JsonKey(name: 'avg_workout_performance_non_fasting')
  final double? avgWorkoutPerformanceNonFasting;
  @JsonKey(name: 'workouts_on_fasting_days')
  final int workoutsOnFastingDays;
  @JsonKey(name: 'workouts_on_non_fasting_days')
  final int workoutsOnNonFastingDays;

  // Goal metrics
  @JsonKey(name: 'goal_completion_rate_fasting')
  final double goalCompletionRateFasting;
  @JsonKey(name: 'goal_completion_rate_non_fasting')
  final double goalCompletionRateNonFasting;

  // Energy metrics
  @JsonKey(name: 'avg_energy_fasting')
  final double? avgEnergyFasting;
  @JsonKey(name: 'avg_energy_non_fasting')
  final double? avgEnergyNonFasting;

  const FastingComparisonStats({
    required this.fastingDaysCount,
    required this.nonFastingDaysCount,
    this.avgWeightFasting,
    this.avgWeightNonFasting,
    this.weightLossFastingDays,
    this.weightLossNonFastingDays,
    this.avgWorkoutPerformanceFasting,
    this.avgWorkoutPerformanceNonFasting,
    this.workoutsOnFastingDays = 0,
    this.workoutsOnNonFastingDays = 0,
    this.goalCompletionRateFasting = 0,
    this.goalCompletionRateNonFasting = 0,
    this.avgEnergyFasting,
    this.avgEnergyNonFasting,
  });

  /// Difference in weight loss between fasting and non-fasting days
  double? get weightLossDifference {
    if (weightLossFastingDays == null || weightLossNonFastingDays == null) {
      return null;
    }
    return weightLossFastingDays! - weightLossNonFastingDays!;
  }

  /// Difference in workout performance
  double? get workoutPerformanceDifference {
    if (avgWorkoutPerformanceFasting == null ||
        avgWorkoutPerformanceNonFasting == null) {
      return null;
    }
    return avgWorkoutPerformanceFasting! - avgWorkoutPerformanceNonFasting!;
  }

  /// Difference in goal completion rate
  double get goalCompletionDifference =>
      goalCompletionRateFasting - goalCompletionRateNonFasting;

  factory FastingComparisonStats.fromJson(Map<String, dynamic> json) =>
      _$FastingComparisonStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FastingComparisonStatsToJson(this);
}

/// AI-generated insight about fasting impact
@JsonSerializable()
class FastingInsight {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: 'insight_type')
  final String insightType; // positive, neutral, suggestion, warning
  final String? icon;
  @JsonKey(name: 'action_text')
  final String? actionText;
  final double? confidence;

  const FastingInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.insightType,
    this.icon,
    this.actionText,
    this.confidence,
  });

  bool get isPositive => insightType == 'positive';
  bool get isWarning => insightType == 'warning';
  bool get isSuggestion => insightType == 'suggestion';

  factory FastingInsight.fromJson(Map<String, dynamic> json) =>
      _$FastingInsightFromJson(json);
  Map<String, dynamic> toJson() => _$FastingInsightToJson(this);
}

/// Complete fasting impact analysis data
@JsonSerializable()
class FastingImpactData {
  @JsonKey(name: 'user_id')
  final String userId;
  final FastingImpactPeriod period;
  @JsonKey(name: 'analysis_date')
  final DateTime analysisDate;

  // Overall correlation score (-1 to 1)
  @JsonKey(name: 'weight_correlation_score')
  final double weightCorrelationScore;
  @JsonKey(name: 'workout_correlation_score')
  final double workoutCorrelationScore;
  @JsonKey(name: 'goal_correlation_score')
  final double goalCorrelationScore;
  @JsonKey(name: 'overall_correlation_score')
  final double overallCorrelationScore;

  // Daily data points
  @JsonKey(name: 'daily_data')
  final List<FastingDayData> dailyData;

  // Comparison statistics
  final FastingComparisonStats comparison;

  // AI insights
  final List<FastingInsight> insights;

  // Summary text
  @JsonKey(name: 'summary_text')
  final String? summaryText;

  const FastingImpactData({
    required this.userId,
    required this.period,
    required this.analysisDate,
    required this.weightCorrelationScore,
    required this.workoutCorrelationScore,
    required this.goalCorrelationScore,
    required this.overallCorrelationScore,
    required this.dailyData,
    required this.comparison,
    required this.insights,
    this.summaryText,
  });

  CorrelationStrength get weightCorrelation =>
      CorrelationStrength.fromScore(weightCorrelationScore);
  CorrelationStrength get workoutCorrelation =>
      CorrelationStrength.fromScore(workoutCorrelationScore);
  CorrelationStrength get goalCorrelation =>
      CorrelationStrength.fromScore(goalCorrelationScore);
  CorrelationStrength get overallCorrelation =>
      CorrelationStrength.fromScore(overallCorrelationScore);

  /// Get fasting days only
  List<FastingDayData> get fastingDays =>
      dailyData.where((d) => d.isFastingDay).toList();

  /// Get non-fasting days only
  List<FastingDayData> get nonFastingDays =>
      dailyData.where((d) => !d.isFastingDay).toList();

  /// Get days with weight logged
  List<FastingDayData> get daysWithWeight =>
      dailyData.where((d) => d.weight != null).toList();

  /// Get days with workouts
  List<FastingDayData> get daysWithWorkouts =>
      dailyData.where((d) => d.hadWorkout).toList();

  factory FastingImpactData.fromJson(Map<String, dynamic> json) =>
      _$FastingImpactDataFromJson(json);
  Map<String, dynamic> toJson() => _$FastingImpactDataToJson(this);

  /// Create empty/default data for when no analysis is available
  factory FastingImpactData.empty(String userId) => FastingImpactData(
        userId: userId,
        period: FastingImpactPeriod.month,
        analysisDate: DateTime.now(),
        weightCorrelationScore: 0,
        workoutCorrelationScore: 0,
        goalCorrelationScore: 0,
        overallCorrelationScore: 0,
        dailyData: [],
        comparison: const FastingComparisonStats(
          fastingDaysCount: 0,
          nonFastingDaysCount: 0,
        ),
        insights: [],
      );
}
