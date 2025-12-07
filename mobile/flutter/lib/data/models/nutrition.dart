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
