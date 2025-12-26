import 'package:json_annotation/json_annotation.dart';
import 'micronutrients.dart';

part 'recipe.g.dart';

/// Recipe category options
enum RecipeCategory {
  breakfast('breakfast', 'Breakfast', '🌅'),
  lunch('lunch', 'Lunch', '☀️'),
  dinner('dinner', 'Dinner', '🌙'),
  snack('snack', 'Snack', '🍎'),
  dessert('dessert', 'Dessert', '🍰'),
  drink('drink', 'Drink', '🥤'),
  other('other', 'Other', '🍽️');

  final String value;
  final String label;
  final String emoji;

  const RecipeCategory(this.value, this.label, this.emoji);

  static RecipeCategory fromValue(String? value) {
    if (value == null) return RecipeCategory.other;
    return RecipeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecipeCategory.other,
    );
  }
}

/// How the recipe was created
enum RecipeSourceType {
  manual('manual', 'Created manually'),
  imported('imported', 'Imported from URL'),
  aiGenerated('ai_generated', 'AI Generated');

  final String value;
  final String description;

  const RecipeSourceType(this.value, this.description);

  static RecipeSourceType fromValue(String? value) {
    if (value == null) return RecipeSourceType.manual;
    return RecipeSourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecipeSourceType.manual,
    );
  }
}

/// Individual ingredient in a recipe
@JsonSerializable()
class RecipeIngredient {
  final String id;
  @JsonKey(name: 'recipe_id')
  final String recipeId;
  @JsonKey(name: 'ingredient_order')
  final int ingredientOrder;
  @JsonKey(name: 'food_name')
  final String foodName;
  final String? brand;
  final double amount;
  final String unit;
  @JsonKey(name: 'amount_grams')
  final double? amountGrams;
  final String? barcode;

  // Nutrition for this ingredient amount
  final double? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  @JsonKey(name: 'sugar_g')
  final double? sugarG;

  // Key micronutrients
  @JsonKey(name: 'vitamin_d_iu')
  final double? vitaminDIu;
  @JsonKey(name: 'calcium_mg')
  final double? calciumMg;
  @JsonKey(name: 'iron_mg')
  final double? ironMg;
  @JsonKey(name: 'sodium_mg')
  final double? sodiumMg;
  @JsonKey(name: 'omega3_g')
  final double? omega3G;

  // Full micronutrients (optional)
  final MicronutrientData? micronutrients;

  // Notes
  final String? notes;
  @JsonKey(name: 'is_optional')
  final bool isOptional;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    this.ingredientOrder = 0,
    required this.foodName,
    this.brand,
    required this.amount,
    required this.unit,
    this.amountGrams,
    this.barcode,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.vitaminDIu,
    this.calciumMg,
    this.ironMg,
    this.sodiumMg,
    this.omega3G,
    this.micronutrients,
    this.notes,
    this.isOptional = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeIngredientToJson(this);

  /// Get formatted amount with unit
  String get formattedAmount => '$amount $unit';

  /// Get calories as int
  int get caloriesInt => (calories ?? 0).round();
}

/// Request to create a new ingredient
@JsonSerializable()
class RecipeIngredientCreate {
  @JsonKey(name: 'food_name')
  final String foodName;
  final String? brand;
  final double amount;
  final String unit;
  @JsonKey(name: 'amount_grams')
  final double? amountGrams;
  final String? barcode;

  // Nutrition
  final double? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  @JsonKey(name: 'sugar_g')
  final double? sugarG;

  // Micronutrients
  @JsonKey(name: 'vitamin_d_iu')
  final double? vitaminDIu;
  @JsonKey(name: 'calcium_mg')
  final double? calciumMg;
  @JsonKey(name: 'iron_mg')
  final double? ironMg;
  @JsonKey(name: 'sodium_mg')
  final double? sodiumMg;
  @JsonKey(name: 'omega3_g')
  final double? omega3G;

  final MicronutrientData? micronutrients;
  final String? notes;
  @JsonKey(name: 'is_optional')
  final bool isOptional;
  @JsonKey(name: 'ingredient_order')
  final int ingredientOrder;

  const RecipeIngredientCreate({
    required this.foodName,
    this.brand,
    required this.amount,
    required this.unit,
    this.amountGrams,
    this.barcode,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.vitaminDIu,
    this.calciumMg,
    this.ironMg,
    this.sodiumMg,
    this.omega3G,
    this.micronutrients,
    this.notes,
    this.isOptional = false,
    this.ingredientOrder = 0,
  });

  factory RecipeIngredientCreate.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientCreateFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeIngredientCreateToJson(this);
}

/// Full recipe with all details
@JsonSerializable()
class Recipe {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final int servings;
  @JsonKey(name: 'prep_time_minutes')
  final int? prepTimeMinutes;
  @JsonKey(name: 'cook_time_minutes')
  final int? cookTimeMinutes;
  final String? instructions;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? category;
  final String? cuisine;
  final List<String>? tags;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  @JsonKey(name: 'source_type')
  final String sourceType;
  @JsonKey(name: 'is_public')
  final bool isPublic;

  // Calculated nutrition per serving
  @JsonKey(name: 'calories_per_serving')
  final int? caloriesPerServing;
  @JsonKey(name: 'protein_per_serving_g')
  final double? proteinPerServingG;
  @JsonKey(name: 'carbs_per_serving_g')
  final double? carbsPerServingG;
  @JsonKey(name: 'fat_per_serving_g')
  final double? fatPerServingG;
  @JsonKey(name: 'fiber_per_serving_g')
  final double? fiberPerServingG;
  @JsonKey(name: 'sugar_per_serving_g')
  final double? sugarPerServingG;

  // Key micronutrients per serving
  @JsonKey(name: 'vitamin_d_per_serving_iu')
  final double? vitaminDPerServingIu;
  @JsonKey(name: 'calcium_per_serving_mg')
  final double? calciumPerServingMg;
  @JsonKey(name: 'iron_per_serving_mg')
  final double? ironPerServingMg;
  @JsonKey(name: 'omega3_per_serving_g')
  final double? omega3PerServingG;
  @JsonKey(name: 'sodium_per_serving_mg')
  final double? sodiumPerServingMg;

  // Full micronutrients per serving (optional)
  @JsonKey(name: 'micronutrients_per_serving')
  final Map<String, dynamic>? micronutrientsPerServing;

  // Usage stats
  @JsonKey(name: 'times_logged')
  final int timesLogged;
  @JsonKey(name: 'last_logged_at')
  final DateTime? lastLoggedAt;

  // Ingredients
  final List<RecipeIngredient> ingredients;
  @JsonKey(name: 'ingredient_count')
  final int? ingredientCount;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.servings = 1,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
    this.imageUrl,
    this.category,
    this.cuisine,
    this.tags,
    this.sourceUrl,
    this.sourceType = 'manual',
    this.isPublic = false,
    this.caloriesPerServing,
    this.proteinPerServingG,
    this.carbsPerServingG,
    this.fatPerServingG,
    this.fiberPerServingG,
    this.sugarPerServingG,
    this.vitaminDPerServingIu,
    this.calciumPerServingMg,
    this.ironPerServingMg,
    this.omega3PerServingG,
    this.sodiumPerServingMg,
    this.micronutrientsPerServing,
    this.timesLogged = 0,
    this.lastLoggedAt,
    this.ingredients = const [],
    this.ingredientCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);

  /// Get category as enum
  RecipeCategory get categoryEnum => RecipeCategory.fromValue(category);

  /// Get source type as enum
  RecipeSourceType get sourceTypeEnum => RecipeSourceType.fromValue(sourceType);

  /// Get total prep + cook time
  int get totalTimeMinutes =>
      (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  /// Get formatted total time
  String get formattedTotalTime {
    final total = totalTimeMinutes;
    if (total == 0) return '-';
    if (total < 60) return '$total min';
    final hours = total ~/ 60;
    final mins = total % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  /// Get actual ingredient count
  int get actualIngredientCount => ingredientCount ?? ingredients.length;

  /// Whether this recipe has been logged before
  bool get hasBeenLogged => timesLogged > 0;

  /// Get macro summary string
  String get macroSummary {
    final parts = <String>[];
    if (proteinPerServingG != null) parts.add('${proteinPerServingG!.round()}g P');
    if (carbsPerServingG != null) parts.add('${carbsPerServingG!.round()}g C');
    if (fatPerServingG != null) parts.add('${fatPerServingG!.round()}g F');
    return parts.join(' | ');
  }
}

/// Brief recipe info for lists
@JsonSerializable()
class RecipeSummary {
  final String id;
  final String name;
  final String? category;
  @JsonKey(name: 'calories_per_serving')
  final int? caloriesPerServing;
  @JsonKey(name: 'protein_per_serving_g')
  final double? proteinPerServingG;
  final int servings;
  @JsonKey(name: 'ingredient_count')
  final int ingredientCount;
  @JsonKey(name: 'times_logged')
  final int timesLogged;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const RecipeSummary({
    required this.id,
    required this.name,
    this.category,
    this.caloriesPerServing,
    this.proteinPerServingG,
    this.servings = 1,
    this.ingredientCount = 0,
    this.timesLogged = 0,
    this.imageUrl,
    required this.createdAt,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeSummaryToJson(this);

  /// Get category as enum
  RecipeCategory get categoryEnum => RecipeCategory.fromValue(category);
}

/// List of recipes response
@JsonSerializable()
class RecipesResponse {
  final List<RecipeSummary> items;
  @JsonKey(name: 'total_count')
  final int totalCount;

  const RecipesResponse({
    this.items = const [],
    this.totalCount = 0,
  });

  factory RecipesResponse.fromJson(Map<String, dynamic> json) =>
      _$RecipesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecipesResponseToJson(this);
}

/// Request to create a recipe
@JsonSerializable()
class RecipeCreate {
  final String name;
  final String? description;
  final int servings;
  @JsonKey(name: 'prep_time_minutes')
  final int? prepTimeMinutes;
  @JsonKey(name: 'cook_time_minutes')
  final int? cookTimeMinutes;
  final String? instructions;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? category;
  final String? cuisine;
  final List<String>? tags;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  @JsonKey(name: 'source_type')
  final String sourceType;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  final List<RecipeIngredientCreate> ingredients;

  const RecipeCreate({
    required this.name,
    this.description,
    this.servings = 1,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
    this.imageUrl,
    this.category,
    this.cuisine,
    this.tags,
    this.sourceUrl,
    this.sourceType = 'manual',
    this.isPublic = false,
    this.ingredients = const [],
  });

  factory RecipeCreate.fromJson(Map<String, dynamic> json) =>
      _$RecipeCreateFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeCreateToJson(this);
}

/// Request to update a recipe
@JsonSerializable()
class RecipeUpdate {
  final String? name;
  final String? description;
  final int? servings;
  @JsonKey(name: 'prep_time_minutes')
  final int? prepTimeMinutes;
  @JsonKey(name: 'cook_time_minutes')
  final int? cookTimeMinutes;
  final String? instructions;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? category;
  final String? cuisine;
  final List<String>? tags;
  @JsonKey(name: 'is_public')
  final bool? isPublic;

  const RecipeUpdate({
    this.name,
    this.description,
    this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
    this.imageUrl,
    this.category,
    this.cuisine,
    this.tags,
    this.isPublic,
  });

  factory RecipeUpdate.fromJson(Map<String, dynamic> json) =>
      _$RecipeUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeUpdateToJson(this);
}

/// Request to log a recipe as a meal
@JsonSerializable()
class LogRecipeRequest {
  @JsonKey(name: 'meal_type')
  final String mealType;
  final double servings;

  const LogRecipeRequest({
    required this.mealType,
    this.servings = 1.0,
  });

  factory LogRecipeRequest.fromJson(Map<String, dynamic> json) =>
      _$LogRecipeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LogRecipeRequestToJson(this);
}

/// Response after logging a recipe
@JsonSerializable()
class LogRecipeResponse {
  final bool success;
  @JsonKey(name: 'food_log_id')
  final String foodLogId;
  @JsonKey(name: 'recipe_name')
  final String recipeName;
  final double servings;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  @JsonKey(name: 'protein_g')
  final double proteinG;
  @JsonKey(name: 'carbs_g')
  final double carbsG;
  @JsonKey(name: 'fat_g')
  final double fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;

  const LogRecipeResponse({
    required this.success,
    required this.foodLogId,
    required this.recipeName,
    required this.servings,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
  });

  factory LogRecipeResponse.fromJson(Map<String, dynamic> json) =>
      _$LogRecipeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogRecipeResponseToJson(this);
}

/// Request to import a recipe from URL
@JsonSerializable()
class ImportRecipeRequest {
  final String url;
  @JsonKey(name: 'servings_override')
  final int? servingsOverride;

  const ImportRecipeRequest({
    required this.url,
    this.servingsOverride,
  });

  factory ImportRecipeRequest.fromJson(Map<String, dynamic> json) =>
      _$ImportRecipeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ImportRecipeRequestToJson(this);
}

/// Response after importing a recipe
@JsonSerializable()
class ImportRecipeResponse {
  final bool success;
  final Recipe? recipe;
  final String? error;
  @JsonKey(name: 'ingredients_found')
  final int ingredientsFound;
  @JsonKey(name: 'ingredients_with_nutrition')
  final int ingredientsWithNutrition;

  const ImportRecipeResponse({
    required this.success,
    this.recipe,
    this.error,
    this.ingredientsFound = 0,
    this.ingredientsWithNutrition = 0,
  });

  factory ImportRecipeResponse.fromJson(Map<String, dynamic> json) =>
      _$ImportRecipeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ImportRecipeResponseToJson(this);
}
