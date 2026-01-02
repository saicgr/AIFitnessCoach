// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flexibility_assessment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlexibilityTest _$FlexibilityTestFromJson(Map<String, dynamic> json) =>
    FlexibilityTest(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      unit: json['unit'] as String? ?? 'inches',
      targetMuscles:
          (json['target_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      equipmentNeeded:
          (json['equipment_needed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      higherIsBetter: json['higher_is_better'] as bool? ?? true,
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      commonMistakes:
          (json['common_mistakes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FlexibilityTestToJson(FlexibilityTest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'instructions': instance.instructions,
      'unit': instance.unit,
      'target_muscles': instance.targetMuscles,
      'equipment_needed': instance.equipmentNeeded,
      'higher_is_better': instance.higherIsBetter,
      'tips': instance.tips,
      'common_mistakes': instance.commonMistakes,
      'video_url': instance.videoUrl,
      'image_url': instance.imageUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };

FlexibilityAssessment _$FlexibilityAssessmentFromJson(
  Map<String, dynamic> json,
) => FlexibilityAssessment(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  testType: json['test_type'] as String,
  measurement: (json['measurement'] as num).toDouble(),
  unit: json['unit'] as String? ?? 'inches',
  rating: json['rating'] as String?,
  percentile: (json['percentile'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  assessedAt: DateTime.parse(json['assessed_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FlexibilityAssessmentToJson(
  FlexibilityAssessment instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'test_type': instance.testType,
  'measurement': instance.measurement,
  'unit': instance.unit,
  'rating': instance.rating,
  'percentile': instance.percentile,
  'notes': instance.notes,
  'assessed_at': instance.assessedAt.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

FlexibilityAssessmentWithEvaluation
_$FlexibilityAssessmentWithEvaluationFromJson(Map<String, dynamic> json) =>
    FlexibilityAssessmentWithEvaluation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      testType: json['test_type'] as String,
      measurement: (json['measurement'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'inches',
      rating: json['rating'] as String?,
      percentile: (json['percentile'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      assessedAt: DateTime.parse(json['assessed_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      testName: json['test_name'] as String?,
      targetMuscles:
          (json['target_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map(
                (e) =>
                    StretchRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      improvementMessage: json['improvement_message'] as String?,
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      commonMistakes:
          (json['common_mistakes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FlexibilityAssessmentWithEvaluationToJson(
  FlexibilityAssessmentWithEvaluation instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'test_type': instance.testType,
  'measurement': instance.measurement,
  'unit': instance.unit,
  'rating': instance.rating,
  'percentile': instance.percentile,
  'notes': instance.notes,
  'assessed_at': instance.assessedAt.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'test_name': instance.testName,
  'target_muscles': instance.targetMuscles,
  'recommendations': instance.recommendations,
  'improvement_message': instance.improvementMessage,
  'tips': instance.tips,
  'common_mistakes': instance.commonMistakes,
};

StretchRecommendation _$StretchRecommendationFromJson(
  Map<String, dynamic> json,
) => StretchRecommendation(
  name: json['name'] as String,
  duration: json['duration'] as String?,
  reps: (json['reps'] as num?)?.toInt(),
  sets: (json['sets'] as num?)?.toInt() ?? 2,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$StretchRecommendationToJson(
  StretchRecommendation instance,
) => <String, dynamic>{
  'name': instance.name,
  'duration': instance.duration,
  'reps': instance.reps,
  'sets': instance.sets,
  'notes': instance.notes,
};

FlexibilityProgress _$FlexibilityProgressFromJson(Map<String, dynamic> json) =>
    FlexibilityProgress(
      userId: json['user_id'] as String,
      testType: json['test_type'] as String,
      assessmentDate: DateTime.parse(json['assessment_date'] as String),
      measurement: (json['measurement'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'inches',
      rating: json['rating'] as String?,
      percentile: (json['percentile'] as num?)?.toInt(),
      previousMeasurement: (json['previous_measurement'] as num?)?.toDouble(),
      improvement: (json['improvement'] as num?)?.toDouble(),
      previousRating: json['previous_rating'] as String?,
      assessmentNumber: (json['assessment_number'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$FlexibilityProgressToJson(
  FlexibilityProgress instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'test_type': instance.testType,
  'assessment_date': instance.assessmentDate.toIso8601String(),
  'measurement': instance.measurement,
  'unit': instance.unit,
  'rating': instance.rating,
  'percentile': instance.percentile,
  'previous_measurement': instance.previousMeasurement,
  'improvement': instance.improvement,
  'previous_rating': instance.previousRating,
  'assessment_number': instance.assessmentNumber,
};

FlexibilityTrend _$FlexibilityTrendFromJson(Map<String, dynamic> json) =>
    FlexibilityTrend(
      testType: json['test_type'] as String,
      testName: json['test_name'] as String,
      unit: json['unit'] as String,
      firstAssessment: json['first_assessment'] as Map<String, dynamic>,
      latestAssessment: json['latest_assessment'] as Map<String, dynamic>,
      totalAssessments: (json['total_assessments'] as num).toInt(),
      improvement: json['improvement'] as Map<String, dynamic>,
      trendData:
          (json['trend_data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FlexibilityTrendToJson(FlexibilityTrend instance) =>
    <String, dynamic>{
      'test_type': instance.testType,
      'test_name': instance.testName,
      'unit': instance.unit,
      'first_assessment': instance.firstAssessment,
      'latest_assessment': instance.latestAssessment,
      'total_assessments': instance.totalAssessments,
      'improvement': instance.improvement,
      'trend_data': instance.trendData,
    };

FlexibilitySummary _$FlexibilitySummaryFromJson(Map<String, dynamic> json) =>
    FlexibilitySummary(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      overallRating: json['overall_rating'] as String? ?? 'not_assessed',
      testsCompleted: (json['tests_completed'] as num?)?.toInt() ?? 0,
      totalAssessments: (json['total_assessments'] as num?)?.toInt() ?? 0,
      firstAssessment: json['first_assessment'] == null
          ? null
          : DateTime.parse(json['first_assessment'] as String),
      latestAssessment: json['latest_assessment'] == null
          ? null
          : DateTime.parse(json['latest_assessment'] as String),
      categoryRatings:
          (json['category_ratings'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      areasNeedingImprovement:
          (json['areas_needing_improvement'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      improvementPriority:
          (json['improvement_priority'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FlexibilitySummaryToJson(FlexibilitySummary instance) =>
    <String, dynamic>{
      'overall_score': instance.overallScore,
      'overall_rating': instance.overallRating,
      'tests_completed': instance.testsCompleted,
      'total_assessments': instance.totalAssessments,
      'first_assessment': instance.firstAssessment?.toIso8601String(),
      'latest_assessment': instance.latestAssessment?.toIso8601String(),
      'category_ratings': instance.categoryRatings,
      'areas_needing_improvement': instance.areasNeedingImprovement,
      'improvement_priority': instance.improvementPriority,
    };

FlexibilityStretchPlan _$FlexibilityStretchPlanFromJson(
  Map<String, dynamic> json,
) => FlexibilityStretchPlan(
  testType: json['test_type'] as String,
  testName: json['test_name'] as String,
  rating: json['rating'] as String,
  stretches:
      (json['stretches'] as List<dynamic>?)
          ?.map(
            (e) => StretchRecommendation.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$FlexibilityStretchPlanToJson(
  FlexibilityStretchPlan instance,
) => <String, dynamic>{
  'test_type': instance.testType,
  'test_name': instance.testName,
  'rating': instance.rating,
  'stretches': instance.stretches,
  'created_at': instance.createdAt?.toIso8601String(),
};

RecordAssessmentResponse _$RecordAssessmentResponseFromJson(
  Map<String, dynamic> json,
) => RecordAssessmentResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  assessment: FlexibilityAssessmentWithEvaluation.fromJson(
    json['assessment'] as Map<String, dynamic>,
  ),
  isImprovement: json['is_improvement'] as bool? ?? false,
  ratingImproved: json['rating_improved'] as bool? ?? false,
);

Map<String, dynamic> _$RecordAssessmentResponseToJson(
  RecordAssessmentResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'assessment': instance.assessment,
  'is_improvement': instance.isImprovement,
  'rating_improved': instance.ratingImproved,
};

FlexibilityScoreResponse _$FlexibilityScoreResponseFromJson(
  Map<String, dynamic> json,
) => FlexibilityScoreResponse(
  overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
  overallRating: json['overall_rating'] as String? ?? 'not_assessed',
  testsCompleted: (json['tests_completed'] as num?)?.toInt() ?? 0,
  areasNeedingImprovement:
      (json['areas_needing_improvement'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$FlexibilityScoreResponseToJson(
  FlexibilityScoreResponse instance,
) => <String, dynamic>{
  'overall_score': instance.overallScore,
  'overall_rating': instance.overallRating,
  'tests_completed': instance.testsCompleted,
  'areas_needing_improvement': instance.areasNeedingImprovement,
};
