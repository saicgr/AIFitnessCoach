import 'package:json_annotation/json_annotation.dart';

part 'diabetes_analytics.g.dart';

/// Trend direction for glucose patterns
enum GlucoseTrendDirection {
  @JsonValue('rising_fast')
  risingFast('rising_fast', 'Rising Fast', 0xFFF44336),
  @JsonValue('rising')
  rising('rising', 'Rising', 0xFFFF9800),
  @JsonValue('stable')
  stable('stable', 'Stable', 0xFF4CAF50),
  @JsonValue('falling')
  falling('falling', 'Falling', 0xFFFF9800),
  @JsonValue('falling_fast')
  fallingFast('falling_fast', 'Falling Fast', 0xFFF44336);

  final String value;
  final String displayName;
  final int colorValue;

  const GlucoseTrendDirection(this.value, this.displayName, this.colorValue);

  static GlucoseTrendDirection fromValue(String? value) {
    if (value == null) return GlucoseTrendDirection.stable;
    return GlucoseTrendDirection.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GlucoseTrendDirection.stable,
    );
  }

  /// Get trend arrow icon
  String get arrowIcon {
    switch (this) {
      case GlucoseTrendDirection.risingFast:
        return 'arrow_upward';
      case GlucoseTrendDirection.rising:
        return 'trending_up';
      case GlucoseTrendDirection.stable:
        return 'trending_flat';
      case GlucoseTrendDirection.falling:
        return 'trending_down';
      case GlucoseTrendDirection.fallingFast:
        return 'arrow_downward';
    }
  }
}

/// Pattern insight type
enum PatternType {
  @JsonValue('dawn_phenomenon')
  dawnPhenomenon('dawn_phenomenon', 'Dawn Phenomenon', 'Higher morning glucose'),
  @JsonValue('post_meal_spike')
  postMealSpike('post_meal_spike', 'Post-Meal Spike', 'High glucose after eating'),
  @JsonValue('nocturnal_hypo')
  nocturnalHypo('nocturnal_hypo', 'Nocturnal Hypoglycemia', 'Low glucose at night'),
  @JsonValue('exercise_effect')
  exerciseEffect('exercise_effect', 'Exercise Effect', 'Glucose changes with exercise'),
  @JsonValue('stress_response')
  stressResponse('stress_response', 'Stress Response', 'Elevated glucose from stress'),
  @JsonValue('medication_timing')
  medicationTiming('medication_timing', 'Medication Timing', 'Glucose pattern related to meds'),
  @JsonValue('consistent_high')
  consistentHigh('consistent_high', 'Consistently High', 'Persistent elevated glucose'),
  @JsonValue('consistent_low')
  consistentLow('consistent_low', 'Consistently Low', 'Persistent low glucose'),
  @JsonValue('high_variability')
  highVariability('high_variability', 'High Variability', 'Unpredictable glucose swings');

  final String value;
  final String displayName;
  final String description;

  const PatternType(this.value, this.displayName, this.description);

  static PatternType fromValue(String? value) {
    if (value == null) return PatternType.postMealSpike;
    return PatternType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PatternType.postMealSpike,
    );
  }
}

/// Summary of glucose readings for a period
@JsonSerializable()
class GlucoseSummary {
  @JsonKey(name: 'avg_glucose')
  final double avgGlucose;
  @JsonKey(name: 'min_glucose')
  final int minGlucose;
  @JsonKey(name: 'max_glucose')
  final int maxGlucose;
  @JsonKey(name: 'reading_count')
  final int readingCount;
  @JsonKey(name: 'time_in_range_percent')
  final double timeInRangePercent;
  @JsonKey(name: 'time_below_range_percent')
  final double timeBelowRangePercent;
  @JsonKey(name: 'time_above_range_percent')
  final double timeAboveRangePercent;
  @JsonKey(name: 'glucose_variability')
  final double? glucoseVariability; // Coefficient of variation
  @JsonKey(name: 'standard_deviation')
  final double? standardDeviation;
  @JsonKey(name: 'estimated_a1c')
  final double? estimatedA1c;

  const GlucoseSummary({
    this.avgGlucose = 0,
    this.minGlucose = 0,
    this.maxGlucose = 0,
    this.readingCount = 0,
    this.timeInRangePercent = 0,
    this.timeBelowRangePercent = 0,
    this.timeAboveRangePercent = 0,
    this.glucoseVariability,
    this.standardDeviation,
    this.estimatedA1c,
  });

  factory GlucoseSummary.fromJson(Map<String, dynamic> json) =>
      _$GlucoseSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$GlucoseSummaryToJson(this);

  /// Get average glucose display
  String get avgDisplay => avgGlucose.toStringAsFixed(0);

  /// Get range display
  String get rangeDisplay => '$minGlucose - $maxGlucose mg/dL';

  /// Get time in range color
  int get tirColor {
    if (timeInRangePercent >= 70) return 0xFF4CAF50; // Green
    if (timeInRangePercent >= 50) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Check if variability is high (CV > 36%)
  bool get hasHighVariability => (glucoseVariability ?? 0) > 36;

  /// Get estimated A1C display
  String? get estimatedA1cDisplay =>
      estimatedA1c != null ? '${estimatedA1c!.toStringAsFixed(1)}%' : null;
}

/// Glucose trend data point
@JsonSerializable()
class GlucoseTrend {
  final String direction;
  @JsonKey(name: 'rate_of_change')
  final double? rateOfChange; // mg/dL per minute
  final String? description;
  @JsonKey(name: 'last_reading')
  final int? lastReading;
  @JsonKey(name: 'recorded_at')
  final DateTime? recordedAt;

  const GlucoseTrend({
    this.direction = 'stable',
    this.rateOfChange,
    this.description,
    this.lastReading,
    this.recordedAt,
  });

  factory GlucoseTrend.fromJson(Map<String, dynamic> json) =>
      _$GlucoseTrendFromJson(json);
  Map<String, dynamic> toJson() => _$GlucoseTrendToJson(this);

  GlucoseTrendDirection get directionEnum =>
      GlucoseTrendDirection.fromValue(direction);

  /// Get trend arrow icon name
  String get arrowIcon => directionEnum.arrowIcon;

  /// Get trend color
  int get colorValue => directionEnum.colorValue;
}

/// Pattern insight from glucose data analysis
@JsonSerializable()
class PatternInsight {
  @JsonKey(name: 'pattern_type')
  final String patternType;
  final String title;
  final String description;
  final String? recommendation;
  final double confidence; // 0.0 - 1.0
  @JsonKey(name: 'affected_times')
  final List<String> affectedTimes;
  @JsonKey(name: 'avg_glucose_during')
  final double? avgGlucoseDuring;
  @JsonKey(name: 'occurrence_count')
  final int occurrenceCount;
  @JsonKey(name: 'first_detected')
  final DateTime? firstDetected;

  const PatternInsight({
    required this.patternType,
    required this.title,
    required this.description,
    this.recommendation,
    this.confidence = 0.5,
    this.affectedTimes = const [],
    this.avgGlucoseDuring,
    this.occurrenceCount = 0,
    this.firstDetected,
  });

  factory PatternInsight.fromJson(Map<String, dynamic> json) =>
      _$PatternInsightFromJson(json);
  Map<String, dynamic> toJson() => _$PatternInsightToJson(this);

  PatternType get patternTypeEnum => PatternType.fromValue(patternType);

  /// Get confidence as percentage string
  String get confidenceDisplay => '${(confidence * 100).round()}%';

  /// Check if high confidence (> 70%)
  bool get isHighConfidence => confidence >= 0.7;
}

/// Comprehensive diabetes dashboard
@JsonSerializable()
class DiabetesDashboard {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;

  // Current status
  @JsonKey(name: 'current_glucose')
  final int? currentGlucose;
  @JsonKey(name: 'current_trend')
  final GlucoseTrend? currentTrend;
  @JsonKey(name: 'last_reading_time')
  final DateTime? lastReadingTime;

  // Summaries for different periods
  @JsonKey(name: 'today_summary')
  final GlucoseSummary? todaySummary;
  @JsonKey(name: 'week_summary')
  final GlucoseSummary? weekSummary;
  @JsonKey(name: 'month_summary')
  final GlucoseSummary? monthSummary;

  // A1C data
  @JsonKey(name: 'latest_a1c')
  final double? latestA1c;
  @JsonKey(name: 'a1c_date')
  final DateTime? a1cDate;
  @JsonKey(name: 'estimated_a1c')
  final double? estimatedA1c;

  // Insulin summary
  @JsonKey(name: 'today_insulin_units')
  final double? todayInsulinUnits;
  @JsonKey(name: 'avg_daily_insulin')
  final double? avgDailyInsulin;

  // Pattern insights
  @JsonKey(name: 'pattern_insights')
  final List<PatternInsight> patternInsights;

  // Goals progress
  @JsonKey(name: 'time_in_range_goal')
  final double? timeInRangeGoal;
  @JsonKey(name: 'readings_today')
  final int readingsToday;
  @JsonKey(name: 'readings_goal')
  final int readingsGoal;

  // Alerts and reminders
  @JsonKey(name: 'active_alerts')
  final List<String> activeAlerts;
  @JsonKey(name: 'medication_reminders')
  final List<String> medicationReminders;

  const DiabetesDashboard({
    required this.userId,
    required this.generatedAt,
    this.currentGlucose,
    this.currentTrend,
    this.lastReadingTime,
    this.todaySummary,
    this.weekSummary,
    this.monthSummary,
    this.latestA1c,
    this.a1cDate,
    this.estimatedA1c,
    this.todayInsulinUnits,
    this.avgDailyInsulin,
    this.patternInsights = const [],
    this.timeInRangeGoal,
    this.readingsToday = 0,
    this.readingsGoal = 4,
    this.activeAlerts = const [],
    this.medicationReminders = const [],
  });

  factory DiabetesDashboard.fromJson(Map<String, dynamic> json) =>
      _$DiabetesDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$DiabetesDashboardToJson(this);

  /// Get current glucose display
  String get currentGlucoseDisplay =>
      currentGlucose != null ? '$currentGlucose mg/dL' : '--';

  /// Check if readings goal is met
  bool get readingsGoalMet => readingsToday >= readingsGoal;

  /// Get readings progress (0.0 - 1.0)
  double get readingsProgress =>
      readingsGoal > 0 ? (readingsToday / readingsGoal).clamp(0.0, 1.0) : 0.0;

  /// Check if time in range goal is met
  bool get tirGoalMet {
    if (timeInRangeGoal == null || todaySummary == null) return false;
    return todaySummary!.timeInRangePercent >= timeInRangeGoal!;
  }

  /// Get minutes since last reading
  int? get minutesSinceLastReading {
    if (lastReadingTime == null) return null;
    return DateTime.now().difference(lastReadingTime!).inMinutes;
  }

  /// Check if last reading is stale (> 15 min for CGM)
  bool get isReadingStale => (minutesSinceLastReading ?? 999) > 15;

  /// Has any active alerts
  bool get hasAlerts => activeAlerts.isNotEmpty;

  /// Has pattern insights worth showing
  bool get hasPatterns => patternInsights.isNotEmpty;

  /// Get highest priority patterns
  List<PatternInsight> get topPatterns =>
      patternInsights.where((p) => p.isHighConfidence).take(3).toList();
}

/// Weekly report for diabetes management
@JsonSerializable()
class WeeklyDiabetesReport {
  @JsonKey(name: 'week_start')
  final DateTime weekStart;
  @JsonKey(name: 'week_end')
  final DateTime weekEnd;
  @JsonKey(name: 'glucose_summary')
  final GlucoseSummary glucoseSummary;
  @JsonKey(name: 'total_readings')
  final int totalReadings;
  @JsonKey(name: 'days_with_readings')
  final int daysWithReadings;
  @JsonKey(name: 'hypo_events')
  final int hypoEvents;
  @JsonKey(name: 'hyper_events')
  final int hyperEvents;
  @JsonKey(name: 'total_insulin_units')
  final double? totalInsulinUnits;
  @JsonKey(name: 'avg_carbs_per_day')
  final int? avgCarbsPerDay;
  @JsonKey(name: 'pattern_insights')
  final List<PatternInsight> patternInsights;
  @JsonKey(name: 'ai_summary')
  final String? aiSummary;
  @JsonKey(name: 'ai_recommendations')
  final List<String> aiRecommendations;

  const WeeklyDiabetesReport({
    required this.weekStart,
    required this.weekEnd,
    required this.glucoseSummary,
    this.totalReadings = 0,
    this.daysWithReadings = 0,
    this.hypoEvents = 0,
    this.hyperEvents = 0,
    this.totalInsulinUnits,
    this.avgCarbsPerDay,
    this.patternInsights = const [],
    this.aiSummary,
    this.aiRecommendations = const [],
  });

  factory WeeklyDiabetesReport.fromJson(Map<String, dynamic> json) =>
      _$WeeklyDiabetesReportFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyDiabetesReportToJson(this);

  /// Get average readings per day
  double get avgReadingsPerDay =>
      daysWithReadings > 0 ? totalReadings / daysWithReadings : 0;

  /// Check if monitoring is consistent
  bool get isConsistent => daysWithReadings >= 5;

  /// Get week summary label
  String get weekLabel {
    final startMonth = weekStart.month;
    final startDay = weekStart.day;
    final endMonth = weekEnd.month;
    final endDay = weekEnd.day;
    if (startMonth == endMonth) {
      return '$startMonth/$startDay - $endDay';
    }
    return '$startMonth/$startDay - $endMonth/$endDay';
  }
}
