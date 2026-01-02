import 'package:json_annotation/json_annotation.dart';

part 'inflammation_analysis.g.dart';

/// Classification of ingredient inflammation effect
enum InflammationType {
  @JsonValue('inflammatory')
  inflammatory,
  @JsonValue('anti_inflammatory')
  antiInflammatory,
  @JsonValue('neutral')
  neutral,
  @JsonValue('additive')
  additive,
  @JsonValue('unknown')
  unknown;

  String get displayName {
    switch (this) {
      case InflammationType.inflammatory:
        return 'Inflammatory';
      case InflammationType.antiInflammatory:
        return 'Anti-Inflammatory';
      case InflammationType.neutral:
        return 'Neutral';
      case InflammationType.additive:
        return 'Additive';
      case InflammationType.unknown:
        return 'Unknown';
    }
  }
}

/// Overall inflammation category for a product
enum InflammationCategory {
  @JsonValue('highly_inflammatory')
  highlyInflammatory,
  @JsonValue('moderately_inflammatory')
  moderatelyInflammatory,
  @JsonValue('neutral')
  neutral,
  @JsonValue('anti_inflammatory')
  antiInflammatory,
  @JsonValue('highly_anti_inflammatory')
  highlyAntiInflammatory;

  String get displayName {
    switch (this) {
      case InflammationCategory.highlyInflammatory:
        return 'Highly Inflammatory';
      case InflammationCategory.moderatelyInflammatory:
        return 'Moderately Inflammatory';
      case InflammationCategory.neutral:
        return 'Neutral';
      case InflammationCategory.antiInflammatory:
        return 'Anti-Inflammatory';
      case InflammationCategory.highlyAntiInflammatory:
        return 'Highly Anti-Inflammatory';
    }
  }
}

/// Individual ingredient with inflammation classification
@JsonSerializable()
class AnalyzedIngredient {
  final String name;
  final String category;
  final int score;
  final String reason;
  @JsonKey(name: 'is_inflammatory')
  final bool isInflammatory;
  @JsonKey(name: 'is_additive')
  final bool isAdditive;
  @JsonKey(name: 'scientific_notes')
  final String? scientificNotes;

  const AnalyzedIngredient({
    required this.name,
    required this.category,
    required this.score,
    required this.reason,
    required this.isInflammatory,
    this.isAdditive = false,
    this.scientificNotes,
  });

  /// Get the inflammation type from category string
  InflammationType get type {
    switch (category) {
      case 'inflammatory':
      case 'highly_inflammatory':
        return InflammationType.inflammatory;
      case 'anti_inflammatory':
      case 'highly_anti_inflammatory':
        return InflammationType.antiInflammatory;
      case 'additive':
        return InflammationType.additive;
      case 'neutral':
        return InflammationType.neutral;
      default:
        return InflammationType.unknown;
    }
  }

  factory AnalyzedIngredient.fromJson(Map<String, dynamic> json) =>
      _$AnalyzedIngredientFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyzedIngredientToJson(this);
}

/// Complete inflammation analysis response
@JsonSerializable()
class InflammationAnalysis {
  @JsonKey(name: 'analysis_id')
  final String analysisId;

  final String barcode;

  @JsonKey(name: 'product_name')
  final String? productName;

  /// Overall inflammation score (1-10, where 1 is highly inflammatory, 10 is anti-inflammatory)
  @JsonKey(name: 'overall_score')
  final int overallScore;

  /// Overall category
  @JsonKey(name: 'overall_category')
  final String overallCategory;

  /// Human-readable summary
  final String summary;

  /// AI-generated recommendation
  final String? recommendation;

  /// List of analyzed ingredients with classifications
  @JsonKey(name: 'ingredient_analyses')
  final List<AnalyzedIngredient> ingredientAnalyses;

  /// List of inflammatory ingredient names
  @JsonKey(name: 'inflammatory_ingredients')
  final List<String> inflammatoryIngredients;

  /// List of anti-inflammatory ingredient names
  @JsonKey(name: 'anti_inflammatory_ingredients')
  final List<String> antiInflammatoryIngredients;

  /// List of additives found
  @JsonKey(name: 'additives_found')
  final List<String> additivesFound;

  /// Count of inflammatory ingredients
  @JsonKey(name: 'inflammatory_count')
  final int inflammatoryCount;

  /// Count of anti-inflammatory ingredients
  @JsonKey(name: 'anti_inflammatory_count')
  final int antiInflammatoryCount;

  /// Count of neutral ingredients
  @JsonKey(name: 'neutral_count')
  final int neutralCount;

  /// Whether the result was from cache
  @JsonKey(name: 'from_cache')
  final bool fromCache;

  /// AI confidence in the analysis
  @JsonKey(name: 'analysis_confidence')
  final double? analysisConfidence;

  /// Analysis timestamp
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const InflammationAnalysis({
    required this.analysisId,
    required this.barcode,
    this.productName,
    required this.overallScore,
    required this.overallCategory,
    required this.summary,
    this.recommendation,
    this.ingredientAnalyses = const [],
    this.inflammatoryIngredients = const [],
    this.antiInflammatoryIngredients = const [],
    this.additivesFound = const [],
    this.inflammatoryCount = 0,
    this.antiInflammatoryCount = 0,
    this.neutralCount = 0,
    this.fromCache = false,
    this.analysisConfidence,
    required this.createdAt,
  });

  /// Get the inflammation category enum
  InflammationCategory get category {
    switch (overallCategory) {
      case 'highly_inflammatory':
        return InflammationCategory.highlyInflammatory;
      case 'moderately_inflammatory':
        return InflammationCategory.moderatelyInflammatory;
      case 'neutral':
        return InflammationCategory.neutral;
      case 'anti_inflammatory':
        return InflammationCategory.antiInflammatory;
      case 'highly_anti_inflammatory':
        return InflammationCategory.highlyAntiInflammatory;
      default:
        return InflammationCategory.neutral;
    }
  }

  /// Get description based on overall score
  String get scoreDescription {
    if (overallScore >= 9) return 'Excellent - Highly Anti-Inflammatory';
    if (overallScore >= 7) return 'Good - Anti-Inflammatory';
    if (overallScore >= 5) return 'Moderate - Mostly Neutral';
    if (overallScore >= 3) return 'Poor - Inflammatory';
    return 'Very Poor - Highly Inflammatory';
  }

  factory InflammationAnalysis.fromJson(Map<String, dynamic> json) =>
      _$InflammationAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$InflammationAnalysisToJson(this);
}

/// Request to analyze inflammation from barcode scan
@JsonSerializable()
class AnalyzeInflammationRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  final String barcode;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'ingredients_text')
  final String ingredientsText;

  const AnalyzeInflammationRequest({
    required this.userId,
    required this.barcode,
    this.productName,
    required this.ingredientsText,
  });

  factory AnalyzeInflammationRequest.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeInflammationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyzeInflammationRequestToJson(this);
}

/// State for async inflammation analysis
class InflammationAnalysisState {
  final bool isLoading;
  final String? error;
  final InflammationAnalysis? analysis;

  const InflammationAnalysisState({
    this.isLoading = false,
    this.error,
    this.analysis,
  });

  InflammationAnalysisState copyWith({
    bool? isLoading,
    String? error,
    InflammationAnalysis? analysis,
  }) {
    return InflammationAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      analysis: analysis ?? this.analysis,
    );
  }

  /// Initial loading state
  factory InflammationAnalysisState.loading() =>
      const InflammationAnalysisState(isLoading: true);

  /// Error state
  factory InflammationAnalysisState.error(String message) =>
      InflammationAnalysisState(error: message);

  /// Success state with analysis
  factory InflammationAnalysisState.success(InflammationAnalysis analysis) =>
      InflammationAnalysisState(analysis: analysis);
}
