// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting_impact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FastingDayData _$FastingDayDataFromJson(Map<String, dynamic> json) =>
    FastingDayData(
      date: DateTime.parse(json['date'] as String),
      isFastingDay: json['is_fasting_day'] as bool,
      fastingHours: (json['fasting_hours'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      weightChange: (json['weight_change'] as num?)?.toDouble(),
      hadWorkout: json['had_workout'] as bool? ?? false,
      workoutPerformanceScore: (json['workout_performance_score'] as num?)
          ?.toDouble(),
      goalsCompleted: (json['goals_completed'] as num?)?.toInt() ?? 0,
      goalsTotal: (json['goals_total'] as num?)?.toInt() ?? 0,
      energyLevel: (json['energy_level'] as num?)?.toInt(),
      caloriesConsumed: (json['calories_consumed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FastingDayDataToJson(FastingDayData instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'is_fasting_day': instance.isFastingDay,
      'fasting_hours': instance.fastingHours,
      'weight': instance.weight,
      'weight_change': instance.weightChange,
      'had_workout': instance.hadWorkout,
      'workout_performance_score': instance.workoutPerformanceScore,
      'goals_completed': instance.goalsCompleted,
      'goals_total': instance.goalsTotal,
      'energy_level': instance.energyLevel,
      'calories_consumed': instance.caloriesConsumed,
    };

FastingComparisonStats _$FastingComparisonStatsFromJson(
  Map<String, dynamic> json,
) => FastingComparisonStats(
  fastingDaysCount: (json['fasting_days_count'] as num).toInt(),
  nonFastingDaysCount: (json['non_fasting_days_count'] as num).toInt(),
  avgWeightFasting: (json['avg_weight_fasting'] as num?)?.toDouble(),
  avgWeightNonFasting: (json['avg_weight_non_fasting'] as num?)?.toDouble(),
  weightLossFastingDays: (json['weight_loss_fasting_days'] as num?)?.toDouble(),
  weightLossNonFastingDays: (json['weight_loss_non_fasting_days'] as num?)
      ?.toDouble(),
  avgWorkoutPerformanceFasting:
      (json['avg_workout_performance_fasting'] as num?)?.toDouble(),
  avgWorkoutPerformanceNonFasting:
      (json['avg_workout_performance_non_fasting'] as num?)?.toDouble(),
  workoutsOnFastingDays:
      (json['workouts_on_fasting_days'] as num?)?.toInt() ?? 0,
  workoutsOnNonFastingDays:
      (json['workouts_on_non_fasting_days'] as num?)?.toInt() ?? 0,
  goalCompletionRateFasting:
      (json['goal_completion_rate_fasting'] as num?)?.toDouble() ?? 0,
  goalCompletionRateNonFasting:
      (json['goal_completion_rate_non_fasting'] as num?)?.toDouble() ?? 0,
  avgEnergyFasting: (json['avg_energy_fasting'] as num?)?.toDouble(),
  avgEnergyNonFasting: (json['avg_energy_non_fasting'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FastingComparisonStatsToJson(
  FastingComparisonStats instance,
) => <String, dynamic>{
  'fasting_days_count': instance.fastingDaysCount,
  'non_fasting_days_count': instance.nonFastingDaysCount,
  'avg_weight_fasting': instance.avgWeightFasting,
  'avg_weight_non_fasting': instance.avgWeightNonFasting,
  'weight_loss_fasting_days': instance.weightLossFastingDays,
  'weight_loss_non_fasting_days': instance.weightLossNonFastingDays,
  'avg_workout_performance_fasting': instance.avgWorkoutPerformanceFasting,
  'avg_workout_performance_non_fasting':
      instance.avgWorkoutPerformanceNonFasting,
  'workouts_on_fasting_days': instance.workoutsOnFastingDays,
  'workouts_on_non_fasting_days': instance.workoutsOnNonFastingDays,
  'goal_completion_rate_fasting': instance.goalCompletionRateFasting,
  'goal_completion_rate_non_fasting': instance.goalCompletionRateNonFasting,
  'avg_energy_fasting': instance.avgEnergyFasting,
  'avg_energy_non_fasting': instance.avgEnergyNonFasting,
};

FastingInsight _$FastingInsightFromJson(Map<String, dynamic> json) =>
    FastingInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      insightType: json['insight_type'] as String,
      icon: json['icon'] as String?,
      actionText: json['action_text'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FastingInsightToJson(FastingInsight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'insight_type': instance.insightType,
      'icon': instance.icon,
      'action_text': instance.actionText,
      'confidence': instance.confidence,
    };

FastingImpactData _$FastingImpactDataFromJson(Map<String, dynamic> json) =>
    FastingImpactData(
      userId: json['user_id'] as String,
      period: $enumDecode(_$FastingImpactPeriodEnumMap, json['period']),
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      weightCorrelationScore: (json['weight_correlation_score'] as num)
          .toDouble(),
      workoutCorrelationScore: (json['workout_correlation_score'] as num)
          .toDouble(),
      goalCorrelationScore: (json['goal_correlation_score'] as num).toDouble(),
      overallCorrelationScore: (json['overall_correlation_score'] as num)
          .toDouble(),
      dailyData: (json['daily_data'] as List<dynamic>)
          .map((e) => FastingDayData.fromJson(e as Map<String, dynamic>))
          .toList(),
      comparison: FastingComparisonStats.fromJson(
        json['comparison'] as Map<String, dynamic>,
      ),
      insights: (json['insights'] as List<dynamic>)
          .map((e) => FastingInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      summaryText: json['summary_text'] as String?,
    );

Map<String, dynamic> _$FastingImpactDataToJson(FastingImpactData instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'period': _$FastingImpactPeriodEnumMap[instance.period]!,
      'analysis_date': instance.analysisDate.toIso8601String(),
      'weight_correlation_score': instance.weightCorrelationScore,
      'workout_correlation_score': instance.workoutCorrelationScore,
      'goal_correlation_score': instance.goalCorrelationScore,
      'overall_correlation_score': instance.overallCorrelationScore,
      'daily_data': instance.dailyData,
      'comparison': instance.comparison,
      'insights': instance.insights,
      'summary_text': instance.summaryText,
    };

const _$FastingImpactPeriodEnumMap = {
  FastingImpactPeriod.week: 'week',
  FastingImpactPeriod.month: 'month',
  FastingImpactPeriod.threeMonths: 'threeMonths',
};
