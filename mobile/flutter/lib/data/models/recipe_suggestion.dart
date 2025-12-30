import 'package:json_annotation/json_annotation.dart';

part 'recipe_suggestion.g.dart';

/// Meal type for recipe suggestions
enum MealType {
  breakfast('breakfast', 'Breakfast'),
  lunch('lunch', 'Lunch'),
  dinner('dinner', 'Dinner'),
  snack('snack', 'Snack'),
  any('any', 'Any Meal');

  final String value;
  final String displayName;

  const MealType(this.value, this.displayName);

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (m) => m.value == value || m.name == value,
      orElse: () => MealType.any,
    );
  }
}

/// A single ingredient in a recipe
@JsonSerializable()
class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;
  final int? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeIngredientToJson(this);
}

/// An AI-generated recipe suggestion
@JsonSerializable()
class RecipeSuggestion {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'recipe_name')
  final String recipeName;
  @JsonKey(name: 'recipe_description')
  final String recipeDescription;
  final String cuisine;
  final String category;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final int servings;
  @JsonKey(name: 'calories_per_serving')
  final int caloriesPerServing;
  @JsonKey(name: 'protein_per_serving_g')
  final double proteinPerServingG;
  @JsonKey(name: 'carbs_per_serving_g')
  final double carbsPerServingG;
  @JsonKey(name: 'fat_per_serving_g')
  final double fatPerServingG;
  @JsonKey(name: 'fiber_per_serving_g')
  final double fiberPerServingG;
  @JsonKey(name: 'prep_time_minutes')
  final int prepTimeMinutes;
  @JsonKey(name: 'cook_time_minutes')
  final int cookTimeMinutes;
  @JsonKey(name: 'suggestion_reason')
  final String suggestionReason;
  @JsonKey(name: 'goal_alignment_score')
  final int goalAlignmentScore;
  @JsonKey(name: 'cuisine_match_score')
  final int cuisineMatchScore;
  @JsonKey(name: 'diet_compliance_score')
  final int dietComplianceScore;
  @JsonKey(name: 'overall_match_score')
  final int overallMatchScore;
  @JsonKey(name: 'user_rating')
  final int? userRating;
  @JsonKey(name: 'user_saved')
  final bool userSaved;
  @JsonKey(name: 'times_cooked')
  final int timesCooked;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const RecipeSuggestion({
    this.id,
    this.userId,
    this.sessionId,
    required this.recipeName,
    required this.recipeDescription,
    required this.cuisine,
    required this.category,
    required this.ingredients,
    required this.instructions,
    required this.servings,
    required this.caloriesPerServing,
    required this.proteinPerServingG,
    required this.carbsPerServingG,
    required this.fatPerServingG,
    required this.fiberPerServingG,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.suggestionReason,
    required this.goalAlignmentScore,
    required this.cuisineMatchScore,
    required this.dietComplianceScore,
    required this.overallMatchScore,
    this.userRating,
    this.userSaved = false,
    this.timesCooked = 0,
    this.createdAt,
  });

  /// Get total time in minutes
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  /// Format total time for display
  String get formattedTotalTime {
    final total = totalTimeMinutes;
    if (total < 60) return '$total min';
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  /// Get match score color (0-100)
  String get matchScoreLabel {
    if (overallMatchScore >= 90) return 'Excellent Match';
    if (overallMatchScore >= 75) return 'Great Match';
    if (overallMatchScore >= 60) return 'Good Match';
    return 'Okay Match';
  }

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) =>
      _$RecipeSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeSuggestionToJson(this);

  RecipeSuggestion copyWith({
    String? id,
    String? userId,
    String? sessionId,
    String? recipeName,
    String? recipeDescription,
    String? cuisine,
    String? category,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? servings,
    int? caloriesPerServing,
    double? proteinPerServingG,
    double? carbsPerServingG,
    double? fatPerServingG,
    double? fiberPerServingG,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    String? suggestionReason,
    int? goalAlignmentScore,
    int? cuisineMatchScore,
    int? dietComplianceScore,
    int? overallMatchScore,
    int? userRating,
    bool? userSaved,
    int? timesCooked,
    DateTime? createdAt,
  }) {
    return RecipeSuggestion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      recipeName: recipeName ?? this.recipeName,
      recipeDescription: recipeDescription ?? this.recipeDescription,
      cuisine: cuisine ?? this.cuisine,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      servings: servings ?? this.servings,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinPerServingG: proteinPerServingG ?? this.proteinPerServingG,
      carbsPerServingG: carbsPerServingG ?? this.carbsPerServingG,
      fatPerServingG: fatPerServingG ?? this.fatPerServingG,
      fiberPerServingG: fiberPerServingG ?? this.fiberPerServingG,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      suggestionReason: suggestionReason ?? this.suggestionReason,
      goalAlignmentScore: goalAlignmentScore ?? this.goalAlignmentScore,
      cuisineMatchScore: cuisineMatchScore ?? this.cuisineMatchScore,
      dietComplianceScore: dietComplianceScore ?? this.dietComplianceScore,
      overallMatchScore: overallMatchScore ?? this.overallMatchScore,
      userRating: userRating ?? this.userRating,
      userSaved: userSaved ?? this.userSaved,
      timesCooked: timesCooked ?? this.timesCooked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Recipe suggestion session for tracking suggestions
@JsonSerializable()
class RecipeSuggestionSession {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'meal_type')
  final String mealType;
  @JsonKey(name: 'suggestions_count')
  final int suggestionsCount;
  @JsonKey(name: 'additional_requirements')
  final String? additionalRequirements;
  @JsonKey(name: 'generation_context')
  final Map<String, dynamic>? generationContext;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const RecipeSuggestionSession({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.suggestionsCount,
    this.additionalRequirements,
    this.generationContext,
    this.createdAt,
  });

  factory RecipeSuggestionSession.fromJson(Map<String, dynamic> json) =>
      _$RecipeSuggestionSessionFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeSuggestionSessionToJson(this);
}

/// Request model for generating recipe suggestions
class SuggestRecipesRequest {
  final String mealType;
  final int count;
  final String? additionalRequirements;

  const SuggestRecipesRequest({
    this.mealType = 'any',
    this.count = 3,
    this.additionalRequirements,
  });

  Map<String, dynamic> toJson() => {
    'meal_type': mealType,
    'count': count,
    if (additionalRequirements != null)
      'additional_requirements': additionalRequirements,
  };
}

/// Response model for recipe suggestions
@JsonSerializable()
class SuggestRecipesResponse {
  final bool success;
  final List<RecipeSuggestion> recipes;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  final String? error;

  const SuggestRecipesResponse({
    required this.success,
    required this.recipes,
    this.sessionId,
    this.error,
  });

  factory SuggestRecipesResponse.fromJson(Map<String, dynamic> json) =>
      _$SuggestRecipesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SuggestRecipesResponseToJson(this);
}

/// Cuisine info for selection
@JsonSerializable()
class CuisineInfo {
  final String code;
  final String name;
  final String region;

  const CuisineInfo({
    required this.code,
    required this.name,
    required this.region,
  });

  factory CuisineInfo.fromJson(Map<String, dynamic> json) =>
      _$CuisineInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CuisineInfoToJson(this);
}

/// Body type info for selection
@JsonSerializable()
class BodyTypeInfo {
  final String code;
  final String name;
  final String description;
  @JsonKey(name: 'nutrition_tips')
  final String? nutritionTips;

  const BodyTypeInfo({
    required this.code,
    required this.name,
    required this.description,
    this.nutritionTips,
  });

  factory BodyTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$BodyTypeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$BodyTypeInfoToJson(this);
}

/// Recipe preferences update request
class UpdateRecipePreferencesRequest {
  final String? bodyType;
  final List<String>? favoriteCuisines;
  final String? culturalBackground;
  final String? spiceTolerance;

  const UpdateRecipePreferencesRequest({
    this.bodyType,
    this.favoriteCuisines,
    this.culturalBackground,
    this.spiceTolerance,
  });

  Map<String, dynamic> toJson() => {
    if (bodyType != null) 'body_type': bodyType,
    if (favoriteCuisines != null) 'favorite_cuisines': favoriteCuisines,
    if (culturalBackground != null) 'cultural_background': culturalBackground,
    if (spiceTolerance != null) 'spice_tolerance': spiceTolerance,
  };
}
