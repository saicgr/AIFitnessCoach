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
    required this.createdAt,
  });

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

/// Response after logging food from image or text
@JsonSerializable()
class LogFoodResponse {
  final bool success;
  @JsonKey(name: 'food_log_id')
  final String foodLogId;
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

  const LogFoodResponse({
    required this.success,
    required this.foodLogId,
    this.foodItems = const [],
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
  });

  factory LogFoodResponse.fromJson(Map<String, dynamic> json) =>
      _$LogFoodResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogFoodResponseToJson(this);
}
