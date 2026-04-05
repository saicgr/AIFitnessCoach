part of 'nutrition.dart';

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

