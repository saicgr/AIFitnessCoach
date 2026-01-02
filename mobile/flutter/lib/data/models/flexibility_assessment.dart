import 'package:json_annotation/json_annotation.dart';

part 'flexibility_assessment.g.dart';

/// A flexibility test definition with instructions
@JsonSerializable()
class FlexibilityTest {
  final String id;
  final String name;
  final String description;
  final List<String> instructions;
  final String unit;
  @JsonKey(name: 'target_muscles')
  final List<String> targetMuscles;
  @JsonKey(name: 'equipment_needed')
  final List<String> equipmentNeeded;
  @JsonKey(name: 'higher_is_better')
  final bool higherIsBetter;
  final List<String> tips;
  @JsonKey(name: 'common_mistakes')
  final List<String> commonMistakes;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const FlexibilityTest({
    required this.id,
    required this.name,
    required this.description,
    this.instructions = const [],
    this.unit = 'inches',
    this.targetMuscles = const [],
    this.equipmentNeeded = const [],
    this.higherIsBetter = true,
    this.tips = const [],
    this.commonMistakes = const [],
    this.videoUrl,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory FlexibilityTest.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityTestFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilityTestToJson(this);

  /// Get display name for unit
  String get unitDisplay {
    switch (unit.toLowerCase()) {
      case 'inches':
        return 'in';
      case 'degrees':
        return '\u00B0'; // degree symbol
      case 'centimeters':
        return 'cm';
      default:
        return unit;
    }
  }

  /// Get icon name based on test type
  String get iconName {
    if (id.contains('shoulder')) return 'fitness_center';
    if (id.contains('hip') || id.contains('groin')) return 'accessibility_new';
    if (id.contains('hamstring') || id.contains('sit_and_reach')) return 'airline_seat_legroom_extra';
    if (id.contains('ankle') || id.contains('calf')) return 'directions_walk';
    if (id.contains('thoracic')) return 'rotate_right';
    if (id.contains('neck')) return 'face';
    if (id.contains('quad')) return 'directions_run';
    return 'self_improvement';
  }
}

/// A recorded flexibility assessment
@JsonSerializable()
class FlexibilityAssessment {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'test_type')
  final String testType;
  final double measurement;
  final String unit;
  final String? rating;
  final int? percentile;
  final String? notes;
  @JsonKey(name: 'assessed_at')
  final DateTime assessedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const FlexibilityAssessment({
    required this.id,
    required this.userId,
    required this.testType,
    required this.measurement,
    this.unit = 'inches',
    this.rating,
    this.percentile,
    this.notes,
    required this.assessedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory FlexibilityAssessment.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilityAssessmentToJson(this);

  /// Get color for rating
  String get ratingColor {
    switch (rating?.toLowerCase()) {
      case 'excellent':
        return '#4CAF50'; // Green
      case 'good':
        return '#8BC34A'; // Light Green
      case 'fair':
        return '#FFC107'; // Amber
      case 'poor':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get display text for rating
  String get ratingDisplay {
    if (rating == null) return 'Not rated';
    return rating![0].toUpperCase() + rating!.substring(1);
  }

  /// Get percentile display text
  String get percentileDisplay {
    if (percentile == null) return '';
    return 'Top ${100 - (percentile ?? 0)}%';
  }

  /// Format measurement with unit
  String get formattedMeasurement {
    final unitDisplay = unit.toLowerCase() == 'degrees' ? '\u00B0' : ' $unit';
    if (measurement == measurement.truncate()) {
      return '${measurement.toInt()}$unitDisplay';
    }
    return '${measurement.toStringAsFixed(1)}$unitDisplay';
  }
}

/// Assessment with full evaluation details
@JsonSerializable()
class FlexibilityAssessmentWithEvaluation extends FlexibilityAssessment {
  @JsonKey(name: 'test_name')
  final String? testName;
  @JsonKey(name: 'target_muscles')
  final List<String> targetMuscles;
  final List<StretchRecommendation> recommendations;
  @JsonKey(name: 'improvement_message')
  final String? improvementMessage;
  final List<String> tips;
  @JsonKey(name: 'common_mistakes')
  final List<String> commonMistakes;

  const FlexibilityAssessmentWithEvaluation({
    required super.id,
    required super.userId,
    required super.testType,
    required super.measurement,
    super.unit,
    super.rating,
    super.percentile,
    super.notes,
    required super.assessedAt,
    super.createdAt,
    super.updatedAt,
    this.testName,
    this.targetMuscles = const [],
    this.recommendations = const [],
    this.improvementMessage,
    this.tips = const [],
    this.commonMistakes = const [],
  });

  factory FlexibilityAssessmentWithEvaluation.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityAssessmentWithEvaluationFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FlexibilityAssessmentWithEvaluationToJson(this);
}

/// A stretch recommendation
@JsonSerializable()
class StretchRecommendation {
  final String name;
  final String? duration;
  final int? reps;
  final int sets;
  final String? notes;

  const StretchRecommendation({
    required this.name,
    this.duration,
    this.reps,
    this.sets = 2,
    this.notes,
  });

  factory StretchRecommendation.fromJson(Map<String, dynamic> json) =>
      _$StretchRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$StretchRecommendationToJson(this);

  /// Get formatted prescription text
  String get prescriptionText {
    if (duration != null) {
      return '$sets x $duration';
    }
    if (reps != null) {
      return '$sets x $reps reps';
    }
    return '$sets sets';
  }
}

/// Progress data for a specific test
@JsonSerializable()
class FlexibilityProgress {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'test_type')
  final String testType;
  @JsonKey(name: 'assessment_date')
  final DateTime assessmentDate;
  final double measurement;
  final String unit;
  final String? rating;
  final int? percentile;
  @JsonKey(name: 'previous_measurement')
  final double? previousMeasurement;
  final double? improvement;
  @JsonKey(name: 'previous_rating')
  final String? previousRating;
  @JsonKey(name: 'assessment_number')
  final int assessmentNumber;

  const FlexibilityProgress({
    required this.userId,
    required this.testType,
    required this.assessmentDate,
    required this.measurement,
    this.unit = 'inches',
    this.rating,
    this.percentile,
    this.previousMeasurement,
    this.improvement,
    this.previousRating,
    this.assessmentNumber = 1,
  });

  factory FlexibilityProgress.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityProgressFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilityProgressToJson(this);

  /// Check if there was improvement
  bool get hasImproved => improvement != null && improvement! > 0;

  /// Get improvement percentage
  double? get improvementPercentage {
    if (improvement == null || previousMeasurement == null || previousMeasurement == 0) {
      return null;
    }
    return (improvement! / previousMeasurement!.abs()) * 100;
  }
}

/// Trend data for a specific test type
@JsonSerializable()
class FlexibilityTrend {
  @JsonKey(name: 'test_type')
  final String testType;
  @JsonKey(name: 'test_name')
  final String testName;
  final String unit;
  @JsonKey(name: 'first_assessment')
  final Map<String, dynamic> firstAssessment;
  @JsonKey(name: 'latest_assessment')
  final Map<String, dynamic> latestAssessment;
  @JsonKey(name: 'total_assessments')
  final int totalAssessments;
  final Map<String, dynamic> improvement;
  @JsonKey(name: 'trend_data')
  final List<Map<String, dynamic>> trendData;

  const FlexibilityTrend({
    required this.testType,
    required this.testName,
    required this.unit,
    required this.firstAssessment,
    required this.latestAssessment,
    required this.totalAssessments,
    required this.improvement,
    this.trendData = const [],
  });

  factory FlexibilityTrend.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityTrendFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilityTrendToJson(this);

  /// Get improvement absolute value
  double get improvementAbsolute => (improvement['absolute'] as num?)?.toDouble() ?? 0;

  /// Get improvement percentage
  double get improvementPercentage => (improvement['percentage'] as num?)?.toDouble() ?? 0;

  /// Check if improvement is positive
  bool get isPositiveImprovement => improvement['is_positive'] == true;

  /// Get rating levels gained
  int get ratingLevelsGained => (improvement['rating_levels_gained'] as int?) ?? 0;
}

/// Overall flexibility summary
@JsonSerializable()
class FlexibilitySummary {
  @JsonKey(name: 'overall_score')
  final double overallScore;
  @JsonKey(name: 'overall_rating')
  final String overallRating;
  @JsonKey(name: 'tests_completed')
  final int testsCompleted;
  @JsonKey(name: 'total_assessments')
  final int totalAssessments;
  @JsonKey(name: 'first_assessment')
  final DateTime? firstAssessment;
  @JsonKey(name: 'latest_assessment')
  final DateTime? latestAssessment;
  @JsonKey(name: 'category_ratings')
  final Map<String, String> categoryRatings;
  @JsonKey(name: 'areas_needing_improvement')
  final List<String> areasNeedingImprovement;
  @JsonKey(name: 'improvement_priority')
  final List<Map<String, dynamic>> improvementPriority;

  const FlexibilitySummary({
    this.overallScore = 0,
    this.overallRating = 'not_assessed',
    this.testsCompleted = 0,
    this.totalAssessments = 0,
    this.firstAssessment,
    this.latestAssessment,
    this.categoryRatings = const {},
    this.areasNeedingImprovement = const [],
    this.improvementPriority = const [],
  });

  factory FlexibilitySummary.fromJson(Map<String, dynamic> json) =>
      _$FlexibilitySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilitySummaryToJson(this);

  /// Get display text for overall rating
  String get ratingDisplay {
    if (overallRating == 'not_assessed') return 'Not Assessed';
    return overallRating[0].toUpperCase() + overallRating.substring(1);
  }

  /// Get color for overall score
  String get scoreColor {
    if (overallScore >= 75) return '#4CAF50';
    if (overallScore >= 50) return '#8BC34A';
    if (overallScore >= 25) return '#FFC107';
    return '#F44336';
  }

  /// Check if user has any assessments
  bool get hasAssessments => testsCompleted > 0;
}

/// Stretch plan for a specific test type
@JsonSerializable()
class FlexibilityStretchPlan {
  @JsonKey(name: 'test_type')
  final String testType;
  @JsonKey(name: 'test_name')
  final String testName;
  final String rating;
  final List<StretchRecommendation> stretches;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const FlexibilityStretchPlan({
    required this.testType,
    required this.testName,
    required this.rating,
    this.stretches = const [],
    this.createdAt,
  });

  factory FlexibilityStretchPlan.fromJson(Map<String, dynamic> json) {
    // Handle stretches which might be a list of maps
    final stretchesList = json['stretches'] as List? ?? [];
    final stretches = stretchesList.map((s) {
      if (s is Map<String, dynamic>) {
        return StretchRecommendation.fromJson(s);
      }
      return StretchRecommendation(name: s.toString());
    }).toList();

    return FlexibilityStretchPlan(
      testType: json['test_type'] as String,
      testName: json['test_name'] as String? ?? json['test_type'] as String,
      rating: json['rating'] as String,
      stretches: stretches,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$FlexibilityStretchPlanToJson(this);
}

/// Response from recording an assessment
@JsonSerializable()
class RecordAssessmentResponse {
  final bool success;
  final String message;
  final FlexibilityAssessmentWithEvaluation assessment;
  @JsonKey(name: 'is_improvement')
  final bool isImprovement;
  @JsonKey(name: 'rating_improved')
  final bool ratingImproved;

  const RecordAssessmentResponse({
    required this.success,
    required this.message,
    required this.assessment,
    this.isImprovement = false,
    this.ratingImproved = false,
  });

  factory RecordAssessmentResponse.fromJson(Map<String, dynamic> json) =>
      _$RecordAssessmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecordAssessmentResponseToJson(this);
}

/// Flexibility score response
@JsonSerializable()
class FlexibilityScoreResponse {
  @JsonKey(name: 'overall_score')
  final double overallScore;
  @JsonKey(name: 'overall_rating')
  final String overallRating;
  @JsonKey(name: 'tests_completed')
  final int testsCompleted;
  @JsonKey(name: 'areas_needing_improvement')
  final List<String> areasNeedingImprovement;

  const FlexibilityScoreResponse({
    this.overallScore = 0,
    this.overallRating = 'not_assessed',
    this.testsCompleted = 0,
    this.areasNeedingImprovement = const [],
  });

  factory FlexibilityScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$FlexibilityScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FlexibilityScoreResponseToJson(this);
}
