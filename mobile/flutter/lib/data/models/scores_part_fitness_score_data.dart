part of 'scores.dart';

class FitnessScoreData {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'calculated_date')
  final String? calculatedDate;
  @JsonKey(name: 'strength_score')
  final int strengthScore;
  @JsonKey(name: 'readiness_score')
  final int readinessScore;
  @JsonKey(name: 'consistency_score')
  final int consistencyScore;
  @JsonKey(name: 'nutrition_score')
  final int nutritionScore;
  @JsonKey(name: 'overall_fitness_score')
  final int overallFitnessScore;
  @JsonKey(name: 'fitness_level')
  final String fitnessLevel;
  @JsonKey(name: 'strength_weight')
  final double strengthWeight;
  @JsonKey(name: 'consistency_weight')
  final double consistencyWeight;
  @JsonKey(name: 'nutrition_weight')
  final double nutritionWeight;
  @JsonKey(name: 'readiness_weight')
  final double readinessWeight;
  @JsonKey(name: 'ai_summary')
  final String? aiSummary;
  @JsonKey(name: 'focus_recommendation')
  final String? focusRecommendation;
  @JsonKey(name: 'previous_score')
  final int? previousScore;
  @JsonKey(name: 'score_change')
  final int? scoreChange;
  final String trend;
  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const FitnessScoreData({
    this.id,
    required this.userId,
    this.calculatedDate,
    this.strengthScore = 0,
    this.readinessScore = 0,
    this.consistencyScore = 0,
    this.nutritionScore = 0,
    this.overallFitnessScore = 0,
    this.fitnessLevel = 'beginner',
    this.strengthWeight = 0.40,
    this.consistencyWeight = 0.30,
    this.nutritionWeight = 0.20,
    this.readinessWeight = 0.10,
    this.aiSummary,
    this.focusRecommendation,
    this.previousScore,
    this.scoreChange,
    this.trend = 'maintaining',
    this.calculatedAt,
  });

  factory FitnessScoreData.fromJson(Map<String, dynamic> json) =>
      _$FitnessScoreDataFromJson(json);
  Map<String, dynamic> toJson() => _$FitnessScoreDataToJson(this);

  /// Get the FitnessLevel enum from string
  FitnessLevel get level {
    switch (fitnessLevel.toLowerCase()) {
      case 'elite':
        return FitnessLevel.elite;
      case 'athletic':
        return FitnessLevel.athletic;
      case 'fit':
        return FitnessLevel.fit;
      case 'developing':
        return FitnessLevel.developing;
      default:
        return FitnessLevel.beginner;
    }
  }

  /// Get trend direction
  TrendDirection get trendDirection {
    switch (trend.toLowerCase()) {
      case 'improving':
        return TrendDirection.improving;
      case 'declining':
        return TrendDirection.declining;
      default:
        return TrendDirection.maintaining;
    }
  }

  /// Get color for fitness level (0xAARRGGBB format)
  int get levelColor {
    switch (level) {
      case FitnessLevel.elite:
        return 0xFF9C27B0; // Purple
      case FitnessLevel.athletic:
        return 0xFF2196F3; // Blue
      case FitnessLevel.fit:
        return 0xFF4CAF50; // Green
      case FitnessLevel.developing:
        return 0xFFFF9800; // Orange
      case FitnessLevel.beginner:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Get display name for level
  String get levelDisplayName {
    switch (level) {
      case FitnessLevel.elite:
        return 'Elite';
      case FitnessLevel.athletic:
        return 'Athletic';
      case FitnessLevel.fit:
        return 'Fit';
      case FitnessLevel.developing:
        return 'Developing';
      case FitnessLevel.beginner:
        return 'Beginner';
    }
  }

  /// Get description for level
  String get levelDescription {
    switch (level) {
      case FitnessLevel.elite:
        return 'Top-tier fitness with excellent strength, consistency, and nutrition.';
      case FitnessLevel.athletic:
        return 'Strong overall fitness with room for minor improvements.';
      case FitnessLevel.fit:
        return 'Good fitness foundation with balanced metrics.';
      case FitnessLevel.developing:
        return 'Building fitness habits with clear progress potential.';
      case FitnessLevel.beginner:
        return 'Starting your fitness journey - focus on consistency.';
    }
  }
}

class FitnessScoreBreakdown {
  @JsonKey(name: 'fitness_score')
  final FitnessScoreData fitnessScore;
  final List<Map<String, dynamic>> breakdown;
  @JsonKey(name: 'level_description')
  final String levelDescription;
  @JsonKey(name: 'level_color')
  final String levelColor;

  const FitnessScoreBreakdown({
    required this.fitnessScore,
    this.breakdown = const [],
    required this.levelDescription,
    required this.levelColor,
  });

  factory FitnessScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      _$FitnessScoreBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$FitnessScoreBreakdownToJson(this);

  /// Get color as int
  int get levelColorValue {
    final hex = levelColor.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  // Convenience getters to delegate to fitnessScore
  int get overallScore => fitnessScore.overallFitnessScore;
  int get strengthScore => fitnessScore.strengthScore;
  int get nutritionScore => fitnessScore.nutritionScore;
  int get consistencyScore => fitnessScore.consistencyScore;
  int get readinessScore => fitnessScore.readinessScore;
  FitnessLevel get level => fitnessScore.level;
  String? get trend => fitnessScore.trend;
  int? get previousScore => fitnessScore.previousScore;
  int? get scoreChange => fitnessScore.scoreChange;
}

