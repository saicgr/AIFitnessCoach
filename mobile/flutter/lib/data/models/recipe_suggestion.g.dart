// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredient _$RecipeIngredientFromJson(Map<String, dynamic> json) =>
    RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      calories: (json['calories'] as num?)?.toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RecipeIngredientToJson(RecipeIngredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'unit': instance.unit,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
    };

RecipeSuggestion _$RecipeSuggestionFromJson(Map<String, dynamic> json) =>
    RecipeSuggestion(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      recipeName: json['recipe_name'] as String,
      recipeDescription: json['recipe_description'] as String,
      cuisine: json['cuisine'] as String,
      category: json['category'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      servings: (json['servings'] as num).toInt(),
      caloriesPerServing: (json['calories_per_serving'] as num).toInt(),
      proteinPerServingG: (json['protein_per_serving_g'] as num).toDouble(),
      carbsPerServingG: (json['carbs_per_serving_g'] as num).toDouble(),
      fatPerServingG: (json['fat_per_serving_g'] as num).toDouble(),
      fiberPerServingG: (json['fiber_per_serving_g'] as num).toDouble(),
      prepTimeMinutes: (json['prep_time_minutes'] as num).toInt(),
      cookTimeMinutes: (json['cook_time_minutes'] as num).toInt(),
      suggestionReason: json['suggestion_reason'] as String,
      goalAlignmentScore: (json['goal_alignment_score'] as num).toInt(),
      cuisineMatchScore: (json['cuisine_match_score'] as num).toInt(),
      dietComplianceScore: (json['diet_compliance_score'] as num).toInt(),
      overallMatchScore: (json['overall_match_score'] as num).toInt(),
      userRating: (json['user_rating'] as num?)?.toInt(),
      userSaved: json['user_saved'] as bool? ?? false,
      timesCooked: (json['times_cooked'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RecipeSuggestionToJson(RecipeSuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'session_id': instance.sessionId,
      'recipe_name': instance.recipeName,
      'recipe_description': instance.recipeDescription,
      'cuisine': instance.cuisine,
      'category': instance.category,
      'ingredients': instance.ingredients,
      'instructions': instance.instructions,
      'servings': instance.servings,
      'calories_per_serving': instance.caloriesPerServing,
      'protein_per_serving_g': instance.proteinPerServingG,
      'carbs_per_serving_g': instance.carbsPerServingG,
      'fat_per_serving_g': instance.fatPerServingG,
      'fiber_per_serving_g': instance.fiberPerServingG,
      'prep_time_minutes': instance.prepTimeMinutes,
      'cook_time_minutes': instance.cookTimeMinutes,
      'suggestion_reason': instance.suggestionReason,
      'goal_alignment_score': instance.goalAlignmentScore,
      'cuisine_match_score': instance.cuisineMatchScore,
      'diet_compliance_score': instance.dietComplianceScore,
      'overall_match_score': instance.overallMatchScore,
      'user_rating': instance.userRating,
      'user_saved': instance.userSaved,
      'times_cooked': instance.timesCooked,
      'created_at': instance.createdAt?.toIso8601String(),
    };

RecipeSuggestionSession _$RecipeSuggestionSessionFromJson(
  Map<String, dynamic> json,
) => RecipeSuggestionSession(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  mealType: json['meal_type'] as String,
  suggestionsCount: (json['suggestions_count'] as num).toInt(),
  additionalRequirements: json['additional_requirements'] as String?,
  generationContext: json['generation_context'] as Map<String, dynamic>?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RecipeSuggestionSessionToJson(
  RecipeSuggestionSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'meal_type': instance.mealType,
  'suggestions_count': instance.suggestionsCount,
  'additional_requirements': instance.additionalRequirements,
  'generation_context': instance.generationContext,
  'created_at': instance.createdAt?.toIso8601String(),
};

SuggestRecipesResponse _$SuggestRecipesResponseFromJson(
  Map<String, dynamic> json,
) => SuggestRecipesResponse(
  success: json['success'] as bool,
  recipes: (json['recipes'] as List<dynamic>)
      .map((e) => RecipeSuggestion.fromJson(e as Map<String, dynamic>))
      .toList(),
  sessionId: json['session_id'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$SuggestRecipesResponseToJson(
  SuggestRecipesResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'recipes': instance.recipes,
  'session_id': instance.sessionId,
  'error': instance.error,
};

CuisineInfo _$CuisineInfoFromJson(Map<String, dynamic> json) => CuisineInfo(
  code: json['code'] as String,
  name: json['name'] as String,
  region: json['region'] as String,
);

Map<String, dynamic> _$CuisineInfoToJson(CuisineInfo instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'region': instance.region,
    };

BodyTypeInfo _$BodyTypeInfoFromJson(Map<String, dynamic> json) => BodyTypeInfo(
  code: json['code'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  nutritionTips: json['nutrition_tips'] as String?,
);

Map<String, dynamic> _$BodyTypeInfoToJson(BodyTypeInfo instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'nutrition_tips': instance.nutritionTips,
    };
