// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diabetes_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseSummary _$GlucoseSummaryFromJson(Map<String, dynamic> json) =>
    GlucoseSummary(
      avgGlucose: (json['avg_glucose'] as num?)?.toDouble() ?? 0,
      minGlucose: (json['min_glucose'] as num?)?.toInt() ?? 0,
      maxGlucose: (json['max_glucose'] as num?)?.toInt() ?? 0,
      readingCount: (json['reading_count'] as num?)?.toInt() ?? 0,
      timeInRangePercent:
          (json['time_in_range_percent'] as num?)?.toDouble() ?? 0,
      timeBelowRangePercent:
          (json['time_below_range_percent'] as num?)?.toDouble() ?? 0,
      timeAboveRangePercent:
          (json['time_above_range_percent'] as num?)?.toDouble() ?? 0,
      glucoseVariability: (json['glucose_variability'] as num?)?.toDouble(),
      standardDeviation: (json['standard_deviation'] as num?)?.toDouble(),
      estimatedA1c: (json['estimated_a1c'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GlucoseSummaryToJson(GlucoseSummary instance) =>
    <String, dynamic>{
      'avg_glucose': instance.avgGlucose,
      'min_glucose': instance.minGlucose,
      'max_glucose': instance.maxGlucose,
      'reading_count': instance.readingCount,
      'time_in_range_percent': instance.timeInRangePercent,
      'time_below_range_percent': instance.timeBelowRangePercent,
      'time_above_range_percent': instance.timeAboveRangePercent,
      'glucose_variability': instance.glucoseVariability,
      'standard_deviation': instance.standardDeviation,
      'estimated_a1c': instance.estimatedA1c,
    };

GlucoseTrend _$GlucoseTrendFromJson(Map<String, dynamic> json) => GlucoseTrend(
  direction: json['direction'] as String? ?? 'stable',
  rateOfChange: (json['rate_of_change'] as num?)?.toDouble(),
  description: json['description'] as String?,
  lastReading: (json['last_reading'] as num?)?.toInt(),
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$GlucoseTrendToJson(GlucoseTrend instance) =>
    <String, dynamic>{
      'direction': instance.direction,
      'rate_of_change': instance.rateOfChange,
      'description': instance.description,
      'last_reading': instance.lastReading,
      'recorded_at': instance.recordedAt?.toIso8601String(),
    };

PatternInsight _$PatternInsightFromJson(Map<String, dynamic> json) =>
    PatternInsight(
      patternType: json['pattern_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      recommendation: json['recommendation'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      affectedTimes:
          (json['affected_times'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      avgGlucoseDuring: (json['avg_glucose_during'] as num?)?.toDouble(),
      occurrenceCount: (json['occurrence_count'] as num?)?.toInt() ?? 0,
      firstDetected: json['first_detected'] == null
          ? null
          : DateTime.parse(json['first_detected'] as String),
    );

Map<String, dynamic> _$PatternInsightToJson(PatternInsight instance) =>
    <String, dynamic>{
      'pattern_type': instance.patternType,
      'title': instance.title,
      'description': instance.description,
      'recommendation': instance.recommendation,
      'confidence': instance.confidence,
      'affected_times': instance.affectedTimes,
      'avg_glucose_during': instance.avgGlucoseDuring,
      'occurrence_count': instance.occurrenceCount,
      'first_detected': instance.firstDetected?.toIso8601String(),
    };

DiabetesDashboard _$DiabetesDashboardFromJson(
  Map<String, dynamic> json,
) => DiabetesDashboard(
  userId: json['user_id'] as String,
  generatedAt: DateTime.parse(json['generated_at'] as String),
  currentGlucose: (json['current_glucose'] as num?)?.toInt(),
  currentTrend: json['current_trend'] == null
      ? null
      : GlucoseTrend.fromJson(json['current_trend'] as Map<String, dynamic>),
  lastReadingTime: json['last_reading_time'] == null
      ? null
      : DateTime.parse(json['last_reading_time'] as String),
  todaySummary: json['today_summary'] == null
      ? null
      : GlucoseSummary.fromJson(json['today_summary'] as Map<String, dynamic>),
  weekSummary: json['week_summary'] == null
      ? null
      : GlucoseSummary.fromJson(json['week_summary'] as Map<String, dynamic>),
  monthSummary: json['month_summary'] == null
      ? null
      : GlucoseSummary.fromJson(json['month_summary'] as Map<String, dynamic>),
  latestA1c: (json['latest_a1c'] as num?)?.toDouble(),
  a1cDate: json['a1c_date'] == null
      ? null
      : DateTime.parse(json['a1c_date'] as String),
  estimatedA1c: (json['estimated_a1c'] as num?)?.toDouble(),
  todayInsulinUnits: (json['today_insulin_units'] as num?)?.toDouble(),
  avgDailyInsulin: (json['avg_daily_insulin'] as num?)?.toDouble(),
  patternInsights:
      (json['pattern_insights'] as List<dynamic>?)
          ?.map((e) => PatternInsight.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  timeInRangeGoal: (json['time_in_range_goal'] as num?)?.toDouble(),
  readingsToday: (json['readings_today'] as num?)?.toInt() ?? 0,
  readingsGoal: (json['readings_goal'] as num?)?.toInt() ?? 4,
  activeAlerts:
      (json['active_alerts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  medicationReminders:
      (json['medication_reminders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$DiabetesDashboardToJson(DiabetesDashboard instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'generated_at': instance.generatedAt.toIso8601String(),
      'current_glucose': instance.currentGlucose,
      'current_trend': instance.currentTrend,
      'last_reading_time': instance.lastReadingTime?.toIso8601String(),
      'today_summary': instance.todaySummary,
      'week_summary': instance.weekSummary,
      'month_summary': instance.monthSummary,
      'latest_a1c': instance.latestA1c,
      'a1c_date': instance.a1cDate?.toIso8601String(),
      'estimated_a1c': instance.estimatedA1c,
      'today_insulin_units': instance.todayInsulinUnits,
      'avg_daily_insulin': instance.avgDailyInsulin,
      'pattern_insights': instance.patternInsights,
      'time_in_range_goal': instance.timeInRangeGoal,
      'readings_today': instance.readingsToday,
      'readings_goal': instance.readingsGoal,
      'active_alerts': instance.activeAlerts,
      'medication_reminders': instance.medicationReminders,
    };

WeeklyDiabetesReport _$WeeklyDiabetesReportFromJson(
  Map<String, dynamic> json,
) => WeeklyDiabetesReport(
  weekStart: DateTime.parse(json['week_start'] as String),
  weekEnd: DateTime.parse(json['week_end'] as String),
  glucoseSummary: GlucoseSummary.fromJson(
    json['glucose_summary'] as Map<String, dynamic>,
  ),
  totalReadings: (json['total_readings'] as num?)?.toInt() ?? 0,
  daysWithReadings: (json['days_with_readings'] as num?)?.toInt() ?? 0,
  hypoEvents: (json['hypo_events'] as num?)?.toInt() ?? 0,
  hyperEvents: (json['hyper_events'] as num?)?.toInt() ?? 0,
  totalInsulinUnits: (json['total_insulin_units'] as num?)?.toDouble(),
  avgCarbsPerDay: (json['avg_carbs_per_day'] as num?)?.toInt(),
  patternInsights:
      (json['pattern_insights'] as List<dynamic>?)
          ?.map((e) => PatternInsight.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  aiSummary: json['ai_summary'] as String?,
  aiRecommendations:
      (json['ai_recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$WeeklyDiabetesReportToJson(
  WeeklyDiabetesReport instance,
) => <String, dynamic>{
  'week_start': instance.weekStart.toIso8601String(),
  'week_end': instance.weekEnd.toIso8601String(),
  'glucose_summary': instance.glucoseSummary,
  'total_readings': instance.totalReadings,
  'days_with_readings': instance.daysWithReadings,
  'hypo_events': instance.hypoEvents,
  'hyper_events': instance.hyperEvents,
  'total_insulin_units': instance.totalInsulinUnits,
  'avg_carbs_per_day': instance.avgCarbsPerDay,
  'pattern_insights': instance.patternInsights,
  'ai_summary': instance.aiSummary,
  'ai_recommendations': instance.aiRecommendations,
};
