import 'package:json_annotation/json_annotation.dart';

part 'nutrition.g.dart';

/// Individual food item
@JsonSerializable()
class FoodItem {
  final String name;
  final String? amount;
  final int? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;

  const FoodItem({
    required this.name,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
  Map<String, dynamic> toJson() => _$FoodItemToJson(this);
}

/// Mood options for food-mood tracking
enum FoodMood {
  great('great', 'Great', '😊'),
  good('good', 'Good', '🙂'),
  neutral('neutral', 'Neutral', '😐'),
  tired('tired', 'Tired', '😴'),
  stressed('stressed', 'Stressed', '😰'),
  hungry('hungry', 'Hungry', '🍽️'),
  satisfied('satisfied', 'Satisfied', '😌'),
  bloated('bloated', 'Bloated', '🫃');

  final String value;
  final String displayName;
  final String emoji;

  const FoodMood(this.value, this.displayName, this.emoji);

  /// Convenience getter for UI
  String get label => displayName;

  static FoodMood? fromString(String? value) {
    if (value == null) return null;
    return FoodMood.values.firstWhere(
      (m) => m.value == value,
      orElse: () => FoodMood.neutral,
    );
  }
}

/// Food log entry
@JsonSerializable()
class FoodLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'meal_type')
  final String mealType;
  @JsonKey(name: 'logged_at')
  final DateTime loggedAt;
  @JsonKey(name: 'food_items')
  final List<FoodItem> foodItems;
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
  @JsonKey(name: 'health_score')
  final int? healthScore;
  @JsonKey(name: 'ai_feedback')
  final String? aiFeedback;
  @JsonKey(name: 'mood_before')
  final String? moodBefore;
  @JsonKey(name: 'mood_after')
  final String? moodAfter;
  @JsonKey(name: 'energy_level')
  final int? energyLevel;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const FoodLog({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.loggedAt,
    this.foodItems = const [],
    this.totalCalories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG,
    this.healthScore,
    this.aiFeedback,
    this.moodBefore,
    this.moodAfter,
    this.energyLevel,
    required this.createdAt,
  });

  /// Get mood before as enum
  FoodMood? get moodBeforeEnum => FoodMood.fromString(moodBefore);

  /// Get mood after as enum
  FoodMood? get moodAfterEnum => FoodMood.fromString(moodAfter);

  factory FoodLog.fromJson(Map<String, dynamic> json) =>
      _$FoodLogFromJson(json);
  Map<String, dynamic> toJson() => _$FoodLogToJson(this);
}

/// Daily nutrition summary
@JsonSerializable()
class DailyNutritionSummary {
  final String date;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double totalFatG;
  @JsonKey(name: 'total_fiber_g')
  final double totalFiberG;
  @JsonKey(name: 'meal_count')
  final int mealCount;
  @JsonKey(name: 'avg_health_score')
  final double? avgHealthScore;
  final List<FoodLog> meals;

  const DailyNutritionSummary({
    required this.date,
    this.totalCalories = 0,
    this.totalProteinG = 0,
    this.totalCarbsG = 0,
    this.totalFatG = 0,
    this.totalFiberG = 0,
    this.mealCount = 0,
    this.avgHealthScore,
    this.meals = const [],
  });

  factory DailyNutritionSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyNutritionSummaryToJson(this);
}

/// Nutrition targets
@JsonSerializable()
class NutritionTargets {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'daily_calorie_target')
  final int? dailyCalorieTarget;
  @JsonKey(name: 'daily_protein_target_g')
  final double? dailyProteinTargetG;
  @JsonKey(name: 'daily_carbs_target_g')
  final double? dailyCarbsTargetG;
  @JsonKey(name: 'daily_fat_target_g')
  final double? dailyFatTargetG;

  const NutritionTargets({
    required this.userId,
    this.dailyCalorieTarget,
    this.dailyProteinTargetG,
    this.dailyCarbsTargetG,
    this.dailyFatTargetG,
  });

  factory NutritionTargets.fromJson(Map<String, dynamic> json) =>
      _$NutritionTargetsFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionTargetsToJson(this);
}

/// Meal type enum
enum MealType {
  breakfast('breakfast', 'Breakfast', '🌅'),
  lunch('lunch', 'Lunch', '☀️'),
  dinner('dinner', 'Dinner', '🌙'),
  snack('snack', 'Snack', '🍎');

  final String value;
  final String label;
  final String emoji;

  const MealType(this.value, this.label, this.emoji);

  static MealType fromValue(String value) {
    return MealType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealType.snack,
    );
  }
}

/// Product nutrients from barcode lookup
@JsonSerializable()
class ProductNutrients {
  @JsonKey(name: 'calories_per_100g')
  final double caloriesPer100g;
  @JsonKey(name: 'protein_per_100g')
  final double proteinPer100g;
  @JsonKey(name: 'carbs_per_100g')
  final double carbsPer100g;
  @JsonKey(name: 'fat_per_100g')
  final double fatPer100g;
  @JsonKey(name: 'fiber_per_100g')
  final double fiberPer100g;
  @JsonKey(name: 'sugar_per_100g')
  final double? sugarPer100g;
  @JsonKey(name: 'sodium_per_100g')
  final double? sodiumPer100g;
  @JsonKey(name: 'serving_size_g')
  final double? servingSizeG;

  const ProductNutrients({
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.fiberPer100g = 0,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.servingSizeG,
  });

  factory ProductNutrients.fromJson(Map<String, dynamic> json) =>
      _$ProductNutrientsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductNutrientsToJson(this);
}

/// Barcode product lookup response
@JsonSerializable()
class BarcodeProduct {
  final String barcode;
  @JsonKey(name: 'product_name')
  final String productName;
  final String? brand;
  final String? categories;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'image_thumb_url')
  final String? imageThumbUrl;
  final Map<String, dynamic> nutrients;
  @JsonKey(name: 'nutriscore_grade')
  final String? nutriscoreGrade;
  @JsonKey(name: 'nova_group')
  final int? novaGroup;
  @JsonKey(name: 'ingredients_text')
  final String? ingredientsText;
  final String? allergens;

  const BarcodeProduct({
    required this.barcode,
    required this.productName,
    this.brand,
    this.categories,
    this.imageUrl,
    this.imageThumbUrl,
    this.nutrients = const {},
    this.nutriscoreGrade,
    this.novaGroup,
    this.ingredientsText,
    this.allergens,
  });

  factory BarcodeProduct.fromJson(Map<String, dynamic> json) =>
      _$BarcodeProductFromJson(json);
  Map<String, dynamic> toJson() => _$BarcodeProductToJson(this);

  /// Get calories per 100g from nutrients map
  double get caloriesPer100g =>
      (nutrients['calories_per_100g'] as num?)?.toDouble() ?? 0;

  /// Get protein per 100g from nutrients map
  double get proteinPer100g =>
      (nutrients['protein_per_100g'] as num?)?.toDouble() ?? 0;

  /// Get carbs per 100g from nutrients map
  double get carbsPer100g =>
      (nutrients['carbs_per_100g'] as num?)?.toDouble() ?? 0;

  /// Get fat per 100g from nutrients map
  double get fatPer100g =>
      (nutrients['fat_per_100g'] as num?)?.toDouble() ?? 0;

  /// Get serving size in grams
  double? get servingSizeG =>
      (nutrients['serving_size_g'] as num?)?.toDouble();
}

/// Response after logging food from barcode
@JsonSerializable()
class LogBarcodeResponse {
  final bool success;
  @JsonKey(name: 'food_log_id')
  final String foodLogId;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  @JsonKey(name: 'protein_g')
  final double proteinG;
  @JsonKey(name: 'carbs_g')
  final double carbsG;
  @JsonKey(name: 'fat_g')
  final double fatG;

  const LogBarcodeResponse({
    required this.success,
    required this.foodLogId,
    required this.productName,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory LogBarcodeResponse.fromJson(Map<String, dynamic> json) =>
      _$LogBarcodeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogBarcodeResponseToJson(this);
}

/// Individual food item with goal-based ranking
@JsonSerializable()
class FoodItemRanking {
  final String name;
  final String? amount;
  final int? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  // Goal-based ranking fields
  @JsonKey(name: 'goal_score')
  final int? goalScore;  // 1-10 based on user goals
  @JsonKey(name: 'goal_alignment')
  final String? goalAlignment;  // "excellent", "good", "neutral", "poor"
  final String? reason;  // Brief explanation

  const FoodItemRanking({
    required this.name,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.goalScore,
    this.goalAlignment,
    this.reason,
  });

  factory FoodItemRanking.fromJson(Map<String, dynamic> json) =>
      _$FoodItemRankingFromJson(json);
  Map<String, dynamic> toJson() => _$FoodItemRankingToJson(this);

  /// Get color for goal score
  String get scoreColor {
    if (goalScore == null) return 'neutral';
    if (goalScore! >= 8) return 'green';
    if (goalScore! >= 5) return 'yellow';
    return 'red';
  }
}

/// Response after logging food from image or text with goal-based analysis
@JsonSerializable()
class LogFoodResponse {
  final bool success;
  @JsonKey(name: 'food_log_id')
  final String? foodLogId;  // Nullable for analyze-only responses (not yet saved)
  @JsonKey(name: 'food_items')
  final List<Map<String, dynamic>> foodItems;
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
  // Enhanced goal-based analysis fields
  @JsonKey(name: 'overall_meal_score')
  final int? overallMealScore;  // 1-10 weighted average
  @JsonKey(name: 'health_score')
  final int? healthScore;  // 1-10 general health score
  @JsonKey(name: 'goal_alignment_percentage')
  final int? goalAlignmentPercentage;  // 0-100%
  @JsonKey(name: 'ai_suggestion')
  final String? aiSuggestion;  // Personalized AI feedback
  final List<String>? encouragements;  // Positive aspects
  final List<String>? warnings;  // Concerns (high sodium, etc.)
  @JsonKey(name: 'recommended_swap')
  final String? recommendedSwap;  // Healthier alternative
  // AI confidence for estimates
  @JsonKey(name: 'confidence_score')
  final double? confidenceScore;  // 0.0-1.0 confidence in analysis
  @JsonKey(name: 'confidence_level')
  final String? confidenceLevel;  // 'low', 'medium', 'high'
  @JsonKey(name: 'source_type')
  final String? sourceType;  // 'image', 'text', 'barcode', 'restaurant'

  // Micronutrients (vitamins & minerals)
  @JsonKey(name: 'sodium_mg')
  final double? sodiumMg;
  @JsonKey(name: 'sugar_g')
  final double? sugarG;
  @JsonKey(name: 'saturated_fat_g')
  final double? saturatedFatG;
  @JsonKey(name: 'cholesterol_mg')
  final double? cholesterolMg;
  @JsonKey(name: 'potassium_mg')
  final double? potassiumMg;
  @JsonKey(name: 'vitamin_a_iu')
  final double? vitaminAIu;
  @JsonKey(name: 'vitamin_c_mg')
  final double? vitaminCMg;
  @JsonKey(name: 'vitamin_d_iu')
  final double? vitaminDIu;
  @JsonKey(name: 'calcium_mg')
  final double? calciumMg;
  @JsonKey(name: 'iron_mg')
  final double? ironMg;

  const LogFoodResponse({
    required this.success,
    this.foodLogId,  // Optional for analyze-only responses
    this.foodItems = const [],
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.overallMealScore,
    this.healthScore,
    this.goalAlignmentPercentage,
    this.aiSuggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    this.confidenceScore,
    this.confidenceLevel,
    this.sourceType,
    this.sodiumMg,
    this.sugarG,
    this.saturatedFatG,
    this.cholesterolMg,
    this.potassiumMg,
    this.vitaminAIu,
    this.vitaminCMg,
    this.vitaminDIu,
    this.calciumMg,
    this.ironMg,
  });

  factory LogFoodResponse.fromJson(Map<String, dynamic> json) =>
      _$LogFoodResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogFoodResponseToJson(this);

  /// Get typed food items with rankings
  List<FoodItemRanking> get foodItemsRanked {
    return foodItems.map((item) => FoodItemRanking.fromJson(item)).toList();
  }

  /// Get color for overall meal score
  String get mealScoreColor {
    if (overallMealScore == null) return 'neutral';
    if (overallMealScore! >= 8) return 'green';
    if (overallMealScore! >= 5) return 'yellow';
    return 'red';
  }

  /// Get confidence display info
  String get confidenceDisplay {
    if (confidenceLevel == null) return 'Unknown';
    switch (confidenceLevel) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Medium confidence';
      case 'low':
        return 'Estimate - please verify';
      default:
        return confidenceLevel!;
    }
  }

  /// Get confidence color
  String get confidenceColor {
    if (confidenceScore == null) return 'neutral';
    if (confidenceScore! >= 0.75) return 'green';
    if (confidenceScore! >= 0.5) return 'orange';
    return 'red';
  }
}

/// Source type for saved foods
enum FoodSourceType {
  text('text'),
  barcode('barcode'),
  image('image');

  final String value;
  const FoodSourceType(this.value);

  static FoodSourceType fromValue(String value) {
    return FoodSourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FoodSourceType.text,
    );
  }
}

/// Saved food item with goal-based ranking
@JsonSerializable()
class SavedFoodItem {
  final String name;
  final String? amount;
  final int? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  @JsonKey(name: 'goal_score')
  final int? goalScore;
  @JsonKey(name: 'goal_alignment')
  final String? goalAlignment;

  const SavedFoodItem({
    required this.name,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.goalScore,
    this.goalAlignment,
  });

  factory SavedFoodItem.fromJson(Map<String, dynamic> json) =>
      _$SavedFoodItemFromJson(json);
  Map<String, dynamic> toJson() => _$SavedFoodItemToJson(this);
}

/// Saved food (favorite recipe)
@JsonSerializable()
class SavedFood {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  @JsonKey(name: 'source_type')
  final String sourceType;
  final String? barcode;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'total_calories')
  final int? totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double? totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double? totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double? totalFatG;
  @JsonKey(name: 'total_fiber_g')
  final double? totalFiberG;
  @JsonKey(name: 'food_items')
  final List<Map<String, dynamic>> foodItems;
  @JsonKey(name: 'overall_meal_score')
  final int? overallMealScore;
  @JsonKey(name: 'goal_alignment_percentage')
  final int? goalAlignmentPercentage;
  final List<String>? tags;
  final String? notes;
  @JsonKey(name: 'times_logged')
  final int timesLogged;
  @JsonKey(name: 'last_logged_at')
  final DateTime? lastLoggedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SavedFood({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.sourceType = 'text',
    this.barcode,
    this.imageUrl,
    this.totalCalories,
    this.totalProteinG,
    this.totalCarbsG,
    this.totalFatG,
    this.totalFiberG,
    this.foodItems = const [],
    this.overallMealScore,
    this.goalAlignmentPercentage,
    this.tags,
    this.notes,
    this.timesLogged = 0,
    this.lastLoggedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedFood.fromJson(Map<String, dynamic> json) =>
      _$SavedFoodFromJson(json);
  Map<String, dynamic> toJson() => _$SavedFoodToJson(this);

  /// Get typed food items with rankings
  List<SavedFoodItem> get foodItemsTyped {
    return foodItems.map((item) => SavedFoodItem.fromJson(item)).toList();
  }

  /// Get source type as enum
  FoodSourceType get sourceTypeEnum => FoodSourceType.fromValue(sourceType);

  /// Get icon for source type
  String get sourceIcon {
    switch (sourceTypeEnum) {
      case FoodSourceType.text:
        return '📝';
      case FoodSourceType.barcode:
        return '📷';
      case FoodSourceType.image:
        return '🖼️';
    }
  }

  /// Get color for meal score
  String get scoreColor {
    if (overallMealScore == null) return 'neutral';
    if (overallMealScore! >= 8) return 'green';
    if (overallMealScore! >= 5) return 'yellow';
    return 'red';
  }
}

/// Response for saved foods list
@JsonSerializable()
class SavedFoodsResponse {
  final List<SavedFood> items;
  @JsonKey(name: 'total_count')
  final int totalCount;

  const SavedFoodsResponse({
    this.items = const [],
    this.totalCount = 0,
  });

  factory SavedFoodsResponse.fromJson(Map<String, dynamic> json) =>
      _$SavedFoodsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SavedFoodsResponseToJson(this);
}

/// Request to save a food from log
@JsonSerializable()
class SaveFoodRequest {
  final String name;
  final String? description;
  @JsonKey(name: 'source_type')
  final String sourceType;
  final String? barcode;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'total_calories')
  final int? totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double? totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double? totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double? totalFatG;
  @JsonKey(name: 'total_fiber_g')
  final double? totalFiberG;
  @JsonKey(name: 'food_items')
  final List<Map<String, dynamic>> foodItems;
  @JsonKey(name: 'overall_meal_score')
  final int? overallMealScore;
  @JsonKey(name: 'goal_alignment_percentage')
  final int? goalAlignmentPercentage;
  final List<String>? tags;

  const SaveFoodRequest({
    required this.name,
    this.description,
    this.sourceType = 'text',
    this.barcode,
    this.imageUrl,
    this.totalCalories,
    this.totalProteinG,
    this.totalCarbsG,
    this.totalFatG,
    this.totalFiberG,
    this.foodItems = const [],
    this.overallMealScore,
    this.goalAlignmentPercentage,
    this.tags,
  });

  factory SaveFoodRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveFoodRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SaveFoodRequestToJson(this);

  /// Create from LogFoodResponse
  factory SaveFoodRequest.fromLogResponse(
    LogFoodResponse response,
    String name, {
    String? description,
    String sourceType = 'text',
    String? barcode,
    String? imageUrl,
    List<String>? tags,
  }) {
    return SaveFoodRequest(
      name: name,
      description: description,
      sourceType: sourceType,
      barcode: barcode,
      imageUrl: imageUrl,
      totalCalories: response.totalCalories,
      totalProteinG: response.proteinG,
      totalCarbsG: response.carbsG,
      totalFatG: response.fatG,
      totalFiberG: response.fiberG,
      foodItems: response.foodItems,
      overallMealScore: response.overallMealScore,
      goalAlignmentPercentage: response.goalAlignmentPercentage,
      tags: tags,
    );
  }

  /// Create from FoodLog (for saving logged meals as favorites)
  factory SaveFoodRequest.fromFoodLog(
    FoodLog log, {
    String? name,
    String? description,
    List<String>? tags,
  }) {
    // Use first food item name or a default
    final displayName = name ??
        (log.foodItems.isNotEmpty
            ? (log.foodItems.length == 1
                ? log.foodItems.first.name
                : '${log.foodItems.first.name} + ${log.foodItems.length - 1} more')
            : 'Saved Meal');

    return SaveFoodRequest(
      name: displayName,
      description: description ?? log.aiFeedback,
      sourceType: 'logged',
      totalCalories: log.totalCalories,
      totalProteinG: log.proteinG,
      totalCarbsG: log.carbsG,
      totalFatG: log.fatG,
      totalFiberG: log.fiberG,
      foodItems: log.foodItems.map((item) => item.toJson()).toList(),
      overallMealScore: log.healthScore,
      tags: tags,
    );
  }
}

/// Request to re-log a saved food
@JsonSerializable()
class RelogSavedFoodRequest {
  @JsonKey(name: 'meal_type')
  final String mealType;

  const RelogSavedFoodRequest({
    required this.mealType,
  });

  factory RelogSavedFoodRequest.fromJson(Map<String, dynamic> json) =>
      _$RelogSavedFoodRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RelogSavedFoodRequestToJson(this);
}
