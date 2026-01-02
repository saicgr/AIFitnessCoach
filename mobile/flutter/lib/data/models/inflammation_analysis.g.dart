// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inflammation_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyzedIngredient _$AnalyzedIngredientFromJson(Map<String, dynamic> json) =>
    AnalyzedIngredient(
      name: json['name'] as String,
      category: json['category'] as String,
      score: (json['score'] as num).toInt(),
      reason: json['reason'] as String,
      isInflammatory: json['is_inflammatory'] as bool,
      isAdditive: json['is_additive'] as bool? ?? false,
      scientificNotes: json['scientific_notes'] as String?,
    );

Map<String, dynamic> _$AnalyzedIngredientToJson(AnalyzedIngredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'category': instance.category,
      'score': instance.score,
      'reason': instance.reason,
      'is_inflammatory': instance.isInflammatory,
      'is_additive': instance.isAdditive,
      'scientific_notes': instance.scientificNotes,
    };

InflammationAnalysis _$InflammationAnalysisFromJson(
  Map<String, dynamic> json,
) => InflammationAnalysis(
  analysisId: json['analysis_id'] as String,
  barcode: json['barcode'] as String,
  productName: json['product_name'] as String?,
  overallScore: (json['overall_score'] as num).toInt(),
  overallCategory: json['overall_category'] as String,
  summary: json['summary'] as String,
  recommendation: json['recommendation'] as String?,
  ingredientAnalyses:
      (json['ingredient_analyses'] as List<dynamic>?)
          ?.map((e) => AnalyzedIngredient.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  inflammatoryIngredients:
      (json['inflammatory_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  antiInflammatoryIngredients:
      (json['anti_inflammatory_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  additivesFound:
      (json['additives_found'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  inflammatoryCount: (json['inflammatory_count'] as num?)?.toInt() ?? 0,
  antiInflammatoryCount:
      (json['anti_inflammatory_count'] as num?)?.toInt() ?? 0,
  neutralCount: (json['neutral_count'] as num?)?.toInt() ?? 0,
  fromCache: json['from_cache'] as bool? ?? false,
  analysisConfidence: (json['analysis_confidence'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InflammationAnalysisToJson(
  InflammationAnalysis instance,
) => <String, dynamic>{
  'analysis_id': instance.analysisId,
  'barcode': instance.barcode,
  'product_name': instance.productName,
  'overall_score': instance.overallScore,
  'overall_category': instance.overallCategory,
  'summary': instance.summary,
  'recommendation': instance.recommendation,
  'ingredient_analyses': instance.ingredientAnalyses,
  'inflammatory_ingredients': instance.inflammatoryIngredients,
  'anti_inflammatory_ingredients': instance.antiInflammatoryIngredients,
  'additives_found': instance.additivesFound,
  'inflammatory_count': instance.inflammatoryCount,
  'anti_inflammatory_count': instance.antiInflammatoryCount,
  'neutral_count': instance.neutralCount,
  'from_cache': instance.fromCache,
  'analysis_confidence': instance.analysisConfidence,
  'created_at': instance.createdAt.toIso8601String(),
};

AnalyzeInflammationRequest _$AnalyzeInflammationRequestFromJson(
  Map<String, dynamic> json,
) => AnalyzeInflammationRequest(
  userId: json['user_id'] as String,
  barcode: json['barcode'] as String,
  productName: json['product_name'] as String?,
  ingredientsText: json['ingredients_text'] as String,
);

Map<String, dynamic> _$AnalyzeInflammationRequestToJson(
  AnalyzeInflammationRequest instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'barcode': instance.barcode,
  'product_name': instance.productName,
  'ingredients_text': instance.ingredientsText,
};
