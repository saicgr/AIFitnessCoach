import 'package:json_annotation/json_annotation.dart';

part 'calibration.g.dart';

/// Represents the result of a single exercise during calibration
@JsonSerializable()
class CalibrationExerciseResult {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'weight_used_kg')
  final double? weightUsedKg;
  @JsonKey(name: 'reps_completed')
  final int? repsCompleted;
  @JsonKey(name: 'sets_completed')
  final int? setsCompleted;
  @JsonKey(name: 'rpe_rating')
  final int? rpeRating;
  @JsonKey(name: 'ai_comment')
  final String? aiComment;
  /// Performance indicator: 'exceeded', 'matched', 'below'
  @JsonKey(name: 'performance_indicator')
  final String? performanceIndicator;
  @JsonKey(name: 'estimated_1rm_kg')
  final double? estimated1rmKg;

  const CalibrationExerciseResult({
    required this.exerciseName,
    this.exerciseId,
    this.weightUsedKg,
    this.repsCompleted,
    this.setsCompleted,
    this.rpeRating,
    this.aiComment,
    this.performanceIndicator,
    this.estimated1rmKg,
  });

  factory CalibrationExerciseResult.fromJson(Map<String, dynamic> json) =>
      _$CalibrationExerciseResultFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationExerciseResultToJson(this);

  /// Get color for performance indicator
  String get performanceColor {
    switch (performanceIndicator?.toLowerCase()) {
      case 'exceeded':
        return 'green';
      case 'matched':
        return 'yellow';
      case 'below':
        return 'red';
      default:
        return 'gray';
    }
  }
}

/// AI analysis of the calibration session
@JsonSerializable()
class CalibrationAnalysis {
  @JsonKey(name: 'analysis_summary')
  final String analysisSummary;
  @JsonKey(name: 'confidence_level')
  final double confidenceLevel;
  @JsonKey(name: 'is_confident')
  final bool isConfident;
  @JsonKey(name: 'stated_fitness_level')
  final String statedFitnessLevel;
  @JsonKey(name: 'detected_fitness_level')
  final String detectedFitnessLevel;
  @JsonKey(name: 'levels_match')
  final bool levelsMatch;
  @JsonKey(name: 'exercise_results')
  final List<CalibrationExerciseResult> exerciseResults;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  const CalibrationAnalysis({
    required this.analysisSummary,
    required this.confidenceLevel,
    this.isConfident = true,
    required this.statedFitnessLevel,
    required this.detectedFitnessLevel,
    this.levelsMatch = true,
    this.exerciseResults = const [],
    this.durationMinutes,
    this.completedAt,
  });

  factory CalibrationAnalysis.fromJson(Map<String, dynamic> json) =>
      _$CalibrationAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationAnalysisToJson(this);

  /// Format confidence as percentage string
  String get confidencePercentage => '${(confidenceLevel * 100).toInt()}%';

  /// Check if there's a significant difference
  bool get hasFitnessLevelMismatch => !levelsMatch;
}

/// Suggested adjustments from the AI based on calibration
@JsonSerializable()
class CalibrationSuggestedAdjustments {
  @JsonKey(name: 'suggested_fitness_level')
  final String? suggestedFitnessLevel;
  @JsonKey(name: 'current_fitness_level')
  final String? currentFitnessLevel;
  @JsonKey(name: 'should_change_fitness_level')
  final bool shouldChangeFitnessLevel;
  @JsonKey(name: 'suggested_intensity')
  final String? suggestedIntensity;
  @JsonKey(name: 'current_intensity')
  final String? currentIntensity;
  @JsonKey(name: 'should_change_intensity')
  final bool shouldChangeIntensity;
  @JsonKey(name: 'weight_multiplier')
  final double? weightMultiplier;
  @JsonKey(name: 'weight_adjustment_description')
  final String? weightAdjustmentDescription;
  @JsonKey(name: 'message_to_user')
  final String messageToUser;
  @JsonKey(name: 'detailed_recommendations')
  final List<String>? detailedRecommendations;

  const CalibrationSuggestedAdjustments({
    this.suggestedFitnessLevel,
    this.currentFitnessLevel,
    this.shouldChangeFitnessLevel = false,
    this.suggestedIntensity,
    this.currentIntensity,
    this.shouldChangeIntensity = false,
    this.weightMultiplier,
    this.weightAdjustmentDescription,
    required this.messageToUser,
    this.detailedRecommendations,
  });

  factory CalibrationSuggestedAdjustments.fromJson(Map<String, dynamic> json) =>
      _$CalibrationSuggestedAdjustmentsFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationSuggestedAdjustmentsToJson(this);

  /// Check if there are any suggested changes
  bool get hasChanges =>
      shouldChangeFitnessLevel ||
      shouldChangeIntensity ||
      weightMultiplier != null && weightMultiplier != 1.0;

  /// Get weight adjustment percentage string
  String? get weightAdjustmentPercentage {
    if (weightMultiplier == null || weightMultiplier == 1.0) return null;
    final percentage = ((weightMultiplier! - 1) * 100).round();
    return percentage > 0 ? '+$percentage%' : '$percentage%';
  }
}

/// Complete calibration result including analysis and suggestions
@JsonSerializable()
class CalibrationResult {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final CalibrationAnalysis analysis;
  @JsonKey(name: 'suggested_adjustments')
  final CalibrationSuggestedAdjustments suggestedAdjustments;
  @JsonKey(name: 'accepted_suggestions')
  final bool? acceptedSuggestions;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const CalibrationResult({
    required this.id,
    required this.userId,
    required this.analysis,
    required this.suggestedAdjustments,
    this.acceptedSuggestions,
    this.createdAt,
  });

  factory CalibrationResult.fromJson(Map<String, dynamic> json) =>
      _$CalibrationResultFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationResultToJson(this);
}
