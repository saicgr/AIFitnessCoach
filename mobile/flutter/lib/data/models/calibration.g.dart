// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calibration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalibrationExerciseResult _$CalibrationExerciseResultFromJson(
  Map<String, dynamic> json,
) => CalibrationExerciseResult(
  exerciseName: json['exercise_name'] as String,
  exerciseId: json['exercise_id'] as String?,
  weightUsedKg: (json['weight_used_kg'] as num?)?.toDouble(),
  repsCompleted: (json['reps_completed'] as num?)?.toInt(),
  setsCompleted: (json['sets_completed'] as num?)?.toInt(),
  rpeRating: (json['rpe_rating'] as num?)?.toInt(),
  aiComment: json['ai_comment'] as String?,
  performanceIndicator: json['performance_indicator'] as String?,
  estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CalibrationExerciseResultToJson(
  CalibrationExerciseResult instance,
) => <String, dynamic>{
  'exercise_name': instance.exerciseName,
  'exercise_id': instance.exerciseId,
  'weight_used_kg': instance.weightUsedKg,
  'reps_completed': instance.repsCompleted,
  'sets_completed': instance.setsCompleted,
  'rpe_rating': instance.rpeRating,
  'ai_comment': instance.aiComment,
  'performance_indicator': instance.performanceIndicator,
  'estimated_1rm_kg': instance.estimated1rmKg,
};

CalibrationAnalysis _$CalibrationAnalysisFromJson(Map<String, dynamic> json) =>
    CalibrationAnalysis(
      analysisSummary: json['analysis_summary'] as String,
      confidenceLevel: (json['confidence_level'] as num).toDouble(),
      isConfident: json['is_confident'] as bool? ?? true,
      statedFitnessLevel: json['stated_fitness_level'] as String,
      detectedFitnessLevel: json['detected_fitness_level'] as String,
      levelsMatch: json['levels_match'] as bool? ?? true,
      exerciseResults:
          (json['exercise_results'] as List<dynamic>?)
              ?.map(
                (e) => CalibrationExerciseResult.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$CalibrationAnalysisToJson(
  CalibrationAnalysis instance,
) => <String, dynamic>{
  'analysis_summary': instance.analysisSummary,
  'confidence_level': instance.confidenceLevel,
  'is_confident': instance.isConfident,
  'stated_fitness_level': instance.statedFitnessLevel,
  'detected_fitness_level': instance.detectedFitnessLevel,
  'levels_match': instance.levelsMatch,
  'exercise_results': instance.exerciseResults,
  'duration_minutes': instance.durationMinutes,
  'completed_at': instance.completedAt?.toIso8601String(),
};

CalibrationSuggestedAdjustments _$CalibrationSuggestedAdjustmentsFromJson(
  Map<String, dynamic> json,
) => CalibrationSuggestedAdjustments(
  suggestedFitnessLevel: json['suggested_fitness_level'] as String?,
  currentFitnessLevel: json['current_fitness_level'] as String?,
  shouldChangeFitnessLevel:
      json['should_change_fitness_level'] as bool? ?? false,
  suggestedIntensity: json['suggested_intensity'] as String?,
  currentIntensity: json['current_intensity'] as String?,
  shouldChangeIntensity: json['should_change_intensity'] as bool? ?? false,
  weightMultiplier: (json['weight_multiplier'] as num?)?.toDouble(),
  weightAdjustmentDescription: json['weight_adjustment_description'] as String?,
  messageToUser: json['message_to_user'] as String,
  detailedRecommendations: (json['detailed_recommendations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CalibrationSuggestedAdjustmentsToJson(
  CalibrationSuggestedAdjustments instance,
) => <String, dynamic>{
  'suggested_fitness_level': instance.suggestedFitnessLevel,
  'current_fitness_level': instance.currentFitnessLevel,
  'should_change_fitness_level': instance.shouldChangeFitnessLevel,
  'suggested_intensity': instance.suggestedIntensity,
  'current_intensity': instance.currentIntensity,
  'should_change_intensity': instance.shouldChangeIntensity,
  'weight_multiplier': instance.weightMultiplier,
  'weight_adjustment_description': instance.weightAdjustmentDescription,
  'message_to_user': instance.messageToUser,
  'detailed_recommendations': instance.detailedRecommendations,
};

CalibrationResult _$CalibrationResultFromJson(Map<String, dynamic> json) =>
    CalibrationResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      analysis: CalibrationAnalysis.fromJson(
        json['analysis'] as Map<String, dynamic>,
      ),
      suggestedAdjustments: CalibrationSuggestedAdjustments.fromJson(
        json['suggested_adjustments'] as Map<String, dynamic>,
      ),
      acceptedSuggestions: json['accepted_suggestions'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CalibrationResultToJson(CalibrationResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'analysis': instance.analysis,
      'suggested_adjustments': instance.suggestedAdjustments,
      'accepted_suggestions': instance.acceptedSuggestions,
      'created_at': instance.createdAt?.toIso8601String(),
    };
