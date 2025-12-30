// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scores.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadinessCheckInRequest _$ReadinessCheckInRequestFromJson(
  Map<String, dynamic> json,
) => ReadinessCheckInRequest(
  userId: json['user_id'] as String,
  scoreDate: json['score_date'] as String?,
  sleepQuality: (json['sleep_quality'] as num).toInt(),
  fatigueLevel: (json['fatigue_level'] as num).toInt(),
  stressLevel: (json['stress_level'] as num).toInt(),
  muscleSoreness: (json['muscle_soreness'] as num).toInt(),
  mood: (json['mood'] as num?)?.toInt(),
  energyLevel: (json['energy_level'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReadinessCheckInRequestToJson(
  ReadinessCheckInRequest instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'score_date': instance.scoreDate,
  'sleep_quality': instance.sleepQuality,
  'fatigue_level': instance.fatigueLevel,
  'stress_level': instance.stressLevel,
  'muscle_soreness': instance.muscleSoreness,
  'mood': instance.mood,
  'energy_level': instance.energyLevel,
};

ReadinessScore _$ReadinessScoreFromJson(Map<String, dynamic> json) =>
    ReadinessScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scoreDate: json['score_date'] as String,
      sleepQuality: (json['sleep_quality'] as num).toInt(),
      fatigueLevel: (json['fatigue_level'] as num).toInt(),
      stressLevel: (json['stress_level'] as num).toInt(),
      muscleSoreness: (json['muscle_soreness'] as num).toInt(),
      mood: (json['mood'] as num?)?.toInt(),
      energyLevel: (json['energy_level'] as num?)?.toInt(),
      hooperIndex: (json['hooper_index'] as num).toInt(),
      readinessScore: (json['readiness_score'] as num).toInt(),
      readinessLevel: json['readiness_level'] as String,
      aiWorkoutRecommendation: json['ai_workout_recommendation'] as String?,
      recommendedIntensity: json['recommended_intensity'] as String?,
      aiInsight: json['ai_insight'] as String?,
      submittedAt: json['submitted_at'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ReadinessScoreToJson(ReadinessScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'score_date': instance.scoreDate,
      'sleep_quality': instance.sleepQuality,
      'fatigue_level': instance.fatigueLevel,
      'stress_level': instance.stressLevel,
      'muscle_soreness': instance.muscleSoreness,
      'mood': instance.mood,
      'energy_level': instance.energyLevel,
      'hooper_index': instance.hooperIndex,
      'readiness_score': instance.readinessScore,
      'readiness_level': instance.readinessLevel,
      'ai_workout_recommendation': instance.aiWorkoutRecommendation,
      'recommended_intensity': instance.recommendedIntensity,
      'ai_insight': instance.aiInsight,
      'submitted_at': instance.submittedAt,
      'created_at': instance.createdAt,
    };

ReadinessHistory _$ReadinessHistoryFromJson(Map<String, dynamic> json) =>
    ReadinessHistory(
      readinessScores: (json['readiness_scores'] as List<dynamic>)
          .map((e) => ReadinessScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageScore: (json['average_score'] as num).toDouble(),
      trend: json['trend'] as String,
      daysAbove60: (json['days_above_60'] as num).toInt(),
      totalDays: (json['total_days'] as num).toInt(),
    );

Map<String, dynamic> _$ReadinessHistoryToJson(ReadinessHistory instance) =>
    <String, dynamic>{
      'readiness_scores': instance.readinessScores,
      'average_score': instance.averageScore,
      'trend': instance.trend,
      'days_above_60': instance.daysAbove60,
      'total_days': instance.totalDays,
    };

StrengthScoreData _$StrengthScoreDataFromJson(Map<String, dynamic> json) =>
    StrengthScoreData(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      muscleGroup: json['muscle_group'] as String,
      strengthScore: (json['strength_score'] as num).toInt(),
      strengthLevel: json['strength_level'] as String,
      bestExerciseName: json['best_exercise_name'] as String?,
      bestEstimated1rmKg: (json['best_estimated_1rm_kg'] as num?)?.toDouble(),
      bodyweightRatio: (json['bodyweight_ratio'] as num?)?.toDouble(),
      weeklySets: (json['weekly_sets'] as num?)?.toInt() ?? 0,
      weeklyVolumeKg: (json['weekly_volume_kg'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] as String? ?? 'maintaining',
      previousScore: (json['previous_score'] as num?)?.toInt(),
      scoreChange: (json['score_change'] as num?)?.toInt(),
      calculatedAt: json['calculated_at'] as String?,
    );

Map<String, dynamic> _$StrengthScoreDataToJson(StrengthScoreData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'muscle_group': instance.muscleGroup,
      'strength_score': instance.strengthScore,
      'strength_level': instance.strengthLevel,
      'best_exercise_name': instance.bestExerciseName,
      'best_estimated_1rm_kg': instance.bestEstimated1rmKg,
      'bodyweight_ratio': instance.bodyweightRatio,
      'weekly_sets': instance.weeklySets,
      'weekly_volume_kg': instance.weeklyVolumeKg,
      'trend': instance.trend,
      'previous_score': instance.previousScore,
      'score_change': instance.scoreChange,
      'calculated_at': instance.calculatedAt,
    };

AllStrengthScores _$AllStrengthScoresFromJson(Map<String, dynamic> json) =>
    AllStrengthScores(
      userId: json['user_id'] as String,
      overallScore: (json['overall_score'] as num).toInt(),
      overallLevel: json['overall_level'] as String,
      muscleScores: (json['muscle_scores'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, StrengthScoreData.fromJson(e as Map<String, dynamic>)),
      ),
      calculatedAt: json['calculated_at'] as String,
    );

Map<String, dynamic> _$AllStrengthScoresToJson(AllStrengthScores instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'overall_score': instance.overallScore,
      'overall_level': instance.overallLevel,
      'muscle_scores': instance.muscleScores,
      'calculated_at': instance.calculatedAt,
    };

StrengthDetail _$StrengthDetailFromJson(Map<String, dynamic> json) =>
    StrengthDetail(
      muscleGroup: json['muscle_group'] as String,
      strengthScore: (json['strength_score'] as num).toInt(),
      strengthLevel: json['strength_level'] as String,
      bestExerciseName: json['best_exercise_name'] as String?,
      bestEstimated1rmKg: (json['best_estimated_1rm_kg'] as num?)?.toDouble(),
      bodyweightRatio: (json['bodyweight_ratio'] as num?)?.toDouble(),
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      trendData:
          (json['trend_data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$StrengthDetailToJson(StrengthDetail instance) =>
    <String, dynamic>{
      'muscle_group': instance.muscleGroup,
      'strength_score': instance.strengthScore,
      'strength_level': instance.strengthLevel,
      'best_exercise_name': instance.bestExerciseName,
      'best_estimated_1rm_kg': instance.bestEstimated1rmKg,
      'bodyweight_ratio': instance.bodyweightRatio,
      'exercises': instance.exercises,
      'trend_data': instance.trendData,
      'recommendations': instance.recommendations,
    };

PersonalRecordScore _$PersonalRecordScoreFromJson(Map<String, dynamic> json) =>
    PersonalRecordScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      weightKg: (json['weight_kg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      estimated1rmKg: (json['estimated_1rm_kg'] as num).toDouble(),
      setType: json['set_type'] as String? ?? 'working',
      rpe: (json['rpe'] as num?)?.toDouble(),
      achievedAt: json['achieved_at'] as String,
      workoutId: json['workout_id'] as String?,
      previousWeightKg: (json['previous_weight_kg'] as num?)?.toDouble(),
      previous1rmKg: (json['previous_1rm_kg'] as num?)?.toDouble(),
      improvementKg: (json['improvement_kg'] as num?)?.toDouble(),
      improvementPercent: (json['improvement_percent'] as num?)?.toDouble(),
      isAllTimePr: json['is_all_time_pr'] as bool? ?? true,
      celebrationMessage: json['celebration_message'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$PersonalRecordScoreToJson(
  PersonalRecordScore instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'exercise_name': instance.exerciseName,
  'exercise_id': instance.exerciseId,
  'muscle_group': instance.muscleGroup,
  'weight_kg': instance.weightKg,
  'reps': instance.reps,
  'estimated_1rm_kg': instance.estimated1rmKg,
  'set_type': instance.setType,
  'rpe': instance.rpe,
  'achieved_at': instance.achievedAt,
  'workout_id': instance.workoutId,
  'previous_weight_kg': instance.previousWeightKg,
  'previous_1rm_kg': instance.previous1rmKg,
  'improvement_kg': instance.improvementKg,
  'improvement_percent': instance.improvementPercent,
  'is_all_time_pr': instance.isAllTimePr,
  'celebration_message': instance.celebrationMessage,
  'created_at': instance.createdAt,
};

PRStats _$PRStatsFromJson(Map<String, dynamic> json) => PRStats(
  totalPrs: (json['total_prs'] as num).toInt(),
  prsThisPeriod: (json['prs_this_period'] as num).toInt(),
  exercisesWithPrs: (json['exercises_with_prs'] as num).toInt(),
  bestImprovementPercent: (json['best_improvement_percent'] as num?)
      ?.toDouble(),
  mostImprovedExercise: json['most_improved_exercise'] as String?,
  longestPrStreak: (json['longest_pr_streak'] as num).toInt(),
  currentPrStreak: (json['current_pr_streak'] as num).toInt(),
  recentPrs:
      (json['recent_prs'] as List<dynamic>?)
          ?.map((e) => PersonalRecordScore.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PRStatsToJson(PRStats instance) => <String, dynamic>{
  'total_prs': instance.totalPrs,
  'prs_this_period': instance.prsThisPeriod,
  'exercises_with_prs': instance.exercisesWithPrs,
  'best_improvement_percent': instance.bestImprovementPercent,
  'most_improved_exercise': instance.mostImprovedExercise,
  'longest_pr_streak': instance.longestPrStreak,
  'current_pr_streak': instance.currentPrStreak,
  'recent_prs': instance.recentPrs,
};

ScoresOverview _$ScoresOverviewFromJson(
  Map<String, dynamic> json,
) => ScoresOverview(
  userId: json['user_id'] as String,
  todayReadiness: json['today_readiness'] == null
      ? null
      : ReadinessScore.fromJson(
          json['today_readiness'] as Map<String, dynamic>,
        ),
  hasCheckedInToday: json['has_checked_in_today'] as bool,
  overallStrengthScore: (json['overall_strength_score'] as num).toInt(),
  overallStrengthLevel: json['overall_strength_level'] as String,
  muscleScoresSummary: Map<String, int>.from(
    json['muscle_scores_summary'] as Map,
  ),
  recentPrs:
      (json['recent_prs'] as List<dynamic>?)
          ?.map((e) => PersonalRecordScore.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  prCount30Days: (json['pr_count_30_days'] as num).toInt(),
  readinessAverage7Days: (json['readiness_average_7_days'] as num?)?.toDouble(),
  nutritionScore: (json['nutrition_score'] as num?)?.toInt(),
  nutritionLevel: json['nutrition_level'] as String?,
  consistencyScore: (json['consistency_score'] as num?)?.toInt(),
  overallFitnessScore: (json['overall_fitness_score'] as num?)?.toInt(),
  fitnessLevel: json['fitness_level'] as String?,
);

Map<String, dynamic> _$ScoresOverviewToJson(ScoresOverview instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'today_readiness': instance.todayReadiness,
      'has_checked_in_today': instance.hasCheckedInToday,
      'overall_strength_score': instance.overallStrengthScore,
      'overall_strength_level': instance.overallStrengthLevel,
      'muscle_scores_summary': instance.muscleScoresSummary,
      'recent_prs': instance.recentPrs,
      'pr_count_30_days': instance.prCount30Days,
      'readiness_average_7_days': instance.readinessAverage7Days,
      'nutrition_score': instance.nutritionScore,
      'nutrition_level': instance.nutritionLevel,
      'consistency_score': instance.consistencyScore,
      'overall_fitness_score': instance.overallFitnessScore,
      'fitness_level': instance.fitnessLevel,
    };

NutritionScoreData _$NutritionScoreDataFromJson(Map<String, dynamic> json) =>
    NutritionScoreData(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      weekStart: json['week_start'] as String?,
      weekEnd: json['week_end'] as String?,
      daysLogged: (json['days_logged'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 7,
      adherencePercent: (json['adherence_percent'] as num?)?.toDouble() ?? 0.0,
      calorieAdherencePercent:
          (json['calorie_adherence_percent'] as num?)?.toDouble() ?? 0.0,
      proteinAdherencePercent:
          (json['protein_adherence_percent'] as num?)?.toDouble() ?? 0.0,
      carbAdherencePercent:
          (json['carb_adherence_percent'] as num?)?.toDouble() ?? 0.0,
      fatAdherencePercent:
          (json['fat_adherence_percent'] as num?)?.toDouble() ?? 0.0,
      avgHealthScore: (json['avg_health_score'] as num?)?.toDouble() ?? 0.0,
      fiberTargetMetDays: (json['fiber_target_met_days'] as num?)?.toInt() ?? 0,
      nutritionScore: (json['nutrition_score'] as num?)?.toInt() ?? 0,
      nutritionLevel: json['nutrition_level'] as String? ?? 'needs_work',
      aiWeeklySummary: json['ai_weekly_summary'] as String?,
      aiImprovementTips:
          (json['ai_improvement_tips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      calculatedAt: json['calculated_at'] as String?,
    );

Map<String, dynamic> _$NutritionScoreDataToJson(NutritionScoreData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'days_logged': instance.daysLogged,
      'total_days': instance.totalDays,
      'adherence_percent': instance.adherencePercent,
      'calorie_adherence_percent': instance.calorieAdherencePercent,
      'protein_adherence_percent': instance.proteinAdherencePercent,
      'carb_adherence_percent': instance.carbAdherencePercent,
      'fat_adherence_percent': instance.fatAdherencePercent,
      'avg_health_score': instance.avgHealthScore,
      'fiber_target_met_days': instance.fiberTargetMetDays,
      'nutrition_score': instance.nutritionScore,
      'nutrition_level': instance.nutritionLevel,
      'ai_weekly_summary': instance.aiWeeklySummary,
      'ai_improvement_tips': instance.aiImprovementTips,
      'calculated_at': instance.calculatedAt,
    };

FitnessScoreData _$FitnessScoreDataFromJson(
  Map<String, dynamic> json,
) => FitnessScoreData(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  calculatedDate: json['calculated_date'] as String?,
  strengthScore: (json['strength_score'] as num?)?.toInt() ?? 0,
  readinessScore: (json['readiness_score'] as num?)?.toInt() ?? 0,
  consistencyScore: (json['consistency_score'] as num?)?.toInt() ?? 0,
  nutritionScore: (json['nutrition_score'] as num?)?.toInt() ?? 0,
  overallFitnessScore: (json['overall_fitness_score'] as num?)?.toInt() ?? 0,
  fitnessLevel: json['fitness_level'] as String? ?? 'beginner',
  strengthWeight: (json['strength_weight'] as num?)?.toDouble() ?? 0.40,
  consistencyWeight: (json['consistency_weight'] as num?)?.toDouble() ?? 0.30,
  nutritionWeight: (json['nutrition_weight'] as num?)?.toDouble() ?? 0.20,
  readinessWeight: (json['readiness_weight'] as num?)?.toDouble() ?? 0.10,
  aiSummary: json['ai_summary'] as String?,
  focusRecommendation: json['focus_recommendation'] as String?,
  previousScore: (json['previous_score'] as num?)?.toInt(),
  scoreChange: (json['score_change'] as num?)?.toInt(),
  trend: json['trend'] as String? ?? 'maintaining',
  calculatedAt: json['calculated_at'] as String?,
);

Map<String, dynamic> _$FitnessScoreDataToJson(FitnessScoreData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'calculated_date': instance.calculatedDate,
      'strength_score': instance.strengthScore,
      'readiness_score': instance.readinessScore,
      'consistency_score': instance.consistencyScore,
      'nutrition_score': instance.nutritionScore,
      'overall_fitness_score': instance.overallFitnessScore,
      'fitness_level': instance.fitnessLevel,
      'strength_weight': instance.strengthWeight,
      'consistency_weight': instance.consistencyWeight,
      'nutrition_weight': instance.nutritionWeight,
      'readiness_weight': instance.readinessWeight,
      'ai_summary': instance.aiSummary,
      'focus_recommendation': instance.focusRecommendation,
      'previous_score': instance.previousScore,
      'score_change': instance.scoreChange,
      'trend': instance.trend,
      'calculated_at': instance.calculatedAt,
    };

FitnessScoreBreakdown _$FitnessScoreBreakdownFromJson(
  Map<String, dynamic> json,
) => FitnessScoreBreakdown(
  fitnessScore: FitnessScoreData.fromJson(
    json['fitness_score'] as Map<String, dynamic>,
  ),
  breakdown:
      (json['breakdown'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  levelDescription: json['level_description'] as String,
  levelColor: json['level_color'] as String,
);

Map<String, dynamic> _$FitnessScoreBreakdownToJson(
  FitnessScoreBreakdown instance,
) => <String, dynamic>{
  'fitness_score': instance.fitnessScore,
  'breakdown': instance.breakdown,
  'level_description': instance.levelDescription,
  'level_color': instance.levelColor,
};
