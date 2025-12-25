// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodItem _$FoodItemFromJson(Map<String, dynamic> json) => FoodItem(
  name: json['name'] as String,
  amount: json['amount'] as String?,
  calories: (json['calories'] as num?)?.toInt(),
  proteinG: (json['protein_g'] as num?)?.toDouble(),
  carbsG: (json['carbs_g'] as num?)?.toDouble(),
  fatG: (json['fat_g'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FoodItemToJson(FoodItem instance) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'calories': instance.calories,
  'protein_g': instance.proteinG,
  'carbs_g': instance.carbsG,
  'fat_g': instance.fatG,
};

FoodLog _$FoodLogFromJson(Map<String, dynamic> json) => FoodLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  mealType: json['meal_type'] as String,
  loggedAt: DateTime.parse(json['logged_at'] as String),
  foodItems:
      (json['food_items'] as List<dynamic>?)
          ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
  proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
  carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
  fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
  fiberG: (json['fiber_g'] as num?)?.toDouble(),
  healthScore: (json['health_score'] as num?)?.toInt(),
  aiFeedback: json['ai_feedback'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$FoodLogToJson(FoodLog instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'meal_type': instance.mealType,
  'logged_at': instance.loggedAt.toIso8601String(),
  'food_items': instance.foodItems,
  'total_calories': instance.totalCalories,
  'protein_g': instance.proteinG,
  'carbs_g': instance.carbsG,
  'fat_g': instance.fatG,
  'fiber_g': instance.fiberG,
  'health_score': instance.healthScore,
  'ai_feedback': instance.aiFeedback,
  'created_at': instance.createdAt.toIso8601String(),
};

DailyNutritionSummary _$DailyNutritionSummaryFromJson(
  Map<String, dynamic> json,
) => DailyNutritionSummary(
  date: json['date'] as String,
  totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
  totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
  totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
  totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0,
  totalFiberG: (json['total_fiber_g'] as num?)?.toDouble() ?? 0,
  mealCount: (json['meal_count'] as num?)?.toInt() ?? 0,
  avgHealthScore: (json['avg_health_score'] as num?)?.toDouble(),
  meals:
      (json['meals'] as List<dynamic>?)
          ?.map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DailyNutritionSummaryToJson(
  DailyNutritionSummary instance,
) => <String, dynamic>{
  'date': instance.date,
  'total_calories': instance.totalCalories,
  'total_protein_g': instance.totalProteinG,
  'total_carbs_g': instance.totalCarbsG,
  'total_fat_g': instance.totalFatG,
  'total_fiber_g': instance.totalFiberG,
  'meal_count': instance.mealCount,
  'avg_health_score': instance.avgHealthScore,
  'meals': instance.meals,
};

NutritionTargets _$NutritionTargetsFromJson(Map<String, dynamic> json) =>
    NutritionTargets(
      userId: json['user_id'] as String,
      dailyCalorieTarget: (json['daily_calorie_target'] as num?)?.toInt(),
      dailyProteinTargetG: (json['daily_protein_target_g'] as num?)?.toDouble(),
      dailyCarbsTargetG: (json['daily_carbs_target_g'] as num?)?.toDouble(),
      dailyFatTargetG: (json['daily_fat_target_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$NutritionTargetsToJson(NutritionTargets instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'daily_calorie_target': instance.dailyCalorieTarget,
      'daily_protein_target_g': instance.dailyProteinTargetG,
      'daily_carbs_target_g': instance.dailyCarbsTargetG,
      'daily_fat_target_g': instance.dailyFatTargetG,
    };

ProductNutrients _$ProductNutrientsFromJson(Map<String, dynamic> json) =>
    ProductNutrients(
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble() ?? 0,
      fiberPer100g: (json['fiber_per_100g'] as num?)?.toDouble() ?? 0,
      sugarPer100g: (json['sugar_per_100g'] as num?)?.toDouble(),
      sodiumPer100g: (json['sodium_per_100g'] as num?)?.toDouble(),
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProductNutrientsToJson(ProductNutrients instance) =>
    <String, dynamic>{
      'calories_per_100g': instance.caloriesPer100g,
      'protein_per_100g': instance.proteinPer100g,
      'carbs_per_100g': instance.carbsPer100g,
      'fat_per_100g': instance.fatPer100g,
      'fiber_per_100g': instance.fiberPer100g,
      'sugar_per_100g': instance.sugarPer100g,
      'sodium_per_100g': instance.sodiumPer100g,
      'serving_size_g': instance.servingSizeG,
    };

BarcodeProduct _$BarcodeProductFromJson(Map<String, dynamic> json) =>
    BarcodeProduct(
      barcode: json['barcode'] as String,
      productName: json['product_name'] as String,
      brand: json['brand'] as String?,
      categories: json['categories'] as String?,
      imageUrl: json['image_url'] as String?,
      imageThumbUrl: json['image_thumb_url'] as String?,
      nutrients: json['nutrients'] as Map<String, dynamic>? ?? const {},
      nutriscoreGrade: json['nutriscore_grade'] as String?,
      novaGroup: (json['nova_group'] as num?)?.toInt(),
      ingredientsText: json['ingredients_text'] as String?,
      allergens: json['allergens'] as String?,
    );

Map<String, dynamic> _$BarcodeProductToJson(BarcodeProduct instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'product_name': instance.productName,
      'brand': instance.brand,
      'categories': instance.categories,
      'image_url': instance.imageUrl,
      'image_thumb_url': instance.imageThumbUrl,
      'nutrients': instance.nutrients,
      'nutriscore_grade': instance.nutriscoreGrade,
      'nova_group': instance.novaGroup,
      'ingredients_text': instance.ingredientsText,
      'allergens': instance.allergens,
    };

LogBarcodeResponse _$LogBarcodeResponseFromJson(Map<String, dynamic> json) =>
    LogBarcodeResponse(
      success: json['success'] as bool,
      foodLogId: json['food_log_id'] as String,
      productName: json['product_name'] as String,
      totalCalories: (json['total_calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
    );

Map<String, dynamic> _$LogBarcodeResponseToJson(LogBarcodeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'food_log_id': instance.foodLogId,
      'product_name': instance.productName,
      'total_calories': instance.totalCalories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
    };

LogFoodResponse _$LogFoodResponseFromJson(Map<String, dynamic> json) =>
    LogFoodResponse(
      success: json['success'] as bool,
      foodLogId: json['food_log_id'] as String,
      foodItems:
          (json['food_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      totalCalories: (json['total_calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LogFoodResponseToJson(LogFoodResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'food_log_id': instance.foodLogId,
      'food_items': instance.foodItems,
      'total_calories': instance.totalCalories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
    };
