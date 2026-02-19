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
  moodBefore: json['mood_before'] as String?,
  moodAfter: json['mood_after'] as String?,
  energyLevel: (json['energy_level'] as num?)?.toInt(),
  createdAt: _parseDateTimeOrNow(json['created_at'] as String?),
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
  'mood_before': instance.moodBefore,
  'mood_after': instance.moodAfter,
  'energy_level': instance.energyLevel,
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

USDANutrientData _$USDANutrientDataFromJson(Map<String, dynamic> json) =>
    USDANutrientData(
      fdcId: (json['fdc_id'] as num?)?.toInt(),
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble() ?? 0,
      fiberPer100g: (json['fiber_per_100g'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$USDANutrientDataToJson(USDANutrientData instance) =>
    <String, dynamic>{
      'fdc_id': instance.fdcId,
      'calories_per_100g': instance.caloriesPer100g,
      'protein_per_100g': instance.proteinPer100g,
      'carbs_per_100g': instance.carbsPer100g,
      'fat_per_100g': instance.fatPer100g,
      'fiber_per_100g': instance.fiberPer100g,
    };

AiPerGramData _$AiPerGramDataFromJson(Map<String, dynamic> json) =>
    AiPerGramData(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$AiPerGramDataToJson(AiPerGramData instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'fiber': instance.fiber,
    };

FoodItemRanking _$FoodItemRankingFromJson(Map<String, dynamic> json) =>
    FoodItemRanking(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      goalScore: (json['goal_score'] as num?)?.toInt(),
      goalAlignment: json['goal_alignment'] as String?,
      reason: json['reason'] as String?,
      weightG: (json['weight_g'] as num?)?.toDouble(),
      weightSource: json['weight_source'] as String?,
      usdaData: json['usda_data'] == null
          ? null
          : USDANutrientData.fromJson(
              json['usda_data'] as Map<String, dynamic>,
            ),
      aiPerGram: json['ai_per_gram'] == null
          ? null
          : AiPerGramData.fromJson(json['ai_per_gram'] as Map<String, dynamic>),
      count: (json['count'] as num?)?.toInt(),
      weightPerUnitG: (json['weight_per_unit_g'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$FoodItemRankingToJson(FoodItemRanking instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'goal_score': instance.goalScore,
      'goal_alignment': instance.goalAlignment,
      'reason': instance.reason,
      'weight_g': instance.weightG,
      'weight_source': instance.weightSource,
      'usda_data': instance.usdaData?.toJson(),
      'ai_per_gram': instance.aiPerGram?.toJson(),
      'count': instance.count,
      'weight_per_unit_g': instance.weightPerUnitG,
      'unit': instance.unit,
    };

LogFoodResponse _$LogFoodResponseFromJson(Map<String, dynamic> json) =>
    LogFoodResponse(
      success: json['success'] as bool,
      foodLogId: json['food_log_id'] as String?,
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
      overallMealScore: (json['overall_meal_score'] as num?)?.toInt(),
      healthScore: (json['health_score'] as num?)?.toInt(),
      goalAlignmentPercentage: (json['goal_alignment_percentage'] as num?)
          ?.toInt(),
      aiSuggestion: json['ai_suggestion'] as String?,
      encouragements: (json['encouragements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recommendedSwap: json['recommended_swap'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      confidenceLevel: json['confidence_level'] as String?,
      sourceType: json['source_type'] as String?,
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      sugarG: (json['sugar_g'] as num?)?.toDouble(),
      saturatedFatG: (json['saturated_fat_g'] as num?)?.toDouble(),
      cholesterolMg: (json['cholesterol_mg'] as num?)?.toDouble(),
      potassiumMg: (json['potassium_mg'] as num?)?.toDouble(),
      vitaminAIu: (json['vitamin_a_iu'] as num?)?.toDouble(),
      vitaminCMg: (json['vitamin_c_mg'] as num?)?.toDouble(),
      vitaminDIu: (json['vitamin_d_iu'] as num?)?.toDouble(),
      calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
      ironMg: (json['iron_mg'] as num?)?.toDouble(),
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
      'overall_meal_score': instance.overallMealScore,
      'health_score': instance.healthScore,
      'goal_alignment_percentage': instance.goalAlignmentPercentage,
      'ai_suggestion': instance.aiSuggestion,
      'encouragements': instance.encouragements,
      'warnings': instance.warnings,
      'recommended_swap': instance.recommendedSwap,
      'confidence_score': instance.confidenceScore,
      'confidence_level': instance.confidenceLevel,
      'source_type': instance.sourceType,
      'sodium_mg': instance.sodiumMg,
      'sugar_g': instance.sugarG,
      'saturated_fat_g': instance.saturatedFatG,
      'cholesterol_mg': instance.cholesterolMg,
      'potassium_mg': instance.potassiumMg,
      'vitamin_a_iu': instance.vitaminAIu,
      'vitamin_c_mg': instance.vitaminCMg,
      'vitamin_d_iu': instance.vitaminDIu,
      'calcium_mg': instance.calciumMg,
      'iron_mg': instance.ironMg,
    };

SavedFoodItem _$SavedFoodItemFromJson(Map<String, dynamic> json) =>
    SavedFoodItem(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      goalScore: (json['goal_score'] as num?)?.toInt(),
      goalAlignment: json['goal_alignment'] as String?,
      weightG: (json['weight_g'] as num?)?.toDouble(),
      usdaData: json['usda_data'] == null
          ? null
          : USDANutrientData.fromJson(
              json['usda_data'] as Map<String, dynamic>,
            ),
      aiPerGram: json['ai_per_gram'] == null
          ? null
          : AiPerGramData.fromJson(json['ai_per_gram'] as Map<String, dynamic>),
      count: (json['count'] as num?)?.toInt(),
      weightPerUnitG: (json['weight_per_unit_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SavedFoodItemToJson(SavedFoodItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'goal_score': instance.goalScore,
      'goal_alignment': instance.goalAlignment,
      'weight_g': instance.weightG,
      'usda_data': instance.usdaData?.toJson(),
      'ai_per_gram': instance.aiPerGram?.toJson(),
      'count': instance.count,
      'weight_per_unit_g': instance.weightPerUnitG,
    };

SavedFood _$SavedFoodFromJson(Map<String, dynamic> json) => SavedFood(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  sourceType: json['source_type'] as String? ?? 'text',
  barcode: json['barcode'] as String?,
  imageUrl: json['image_url'] as String?,
  totalCalories: (json['total_calories'] as num?)?.toInt(),
  totalProteinG: (json['total_protein_g'] as num?)?.toDouble(),
  totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble(),
  totalFatG: (json['total_fat_g'] as num?)?.toDouble(),
  totalFiberG: (json['total_fiber_g'] as num?)?.toDouble(),
  foodItems:
      (json['food_items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  overallMealScore: (json['overall_meal_score'] as num?)?.toInt(),
  goalAlignmentPercentage: (json['goal_alignment_percentage'] as num?)?.toInt(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  notes: json['notes'] as String?,
  timesLogged: (json['times_logged'] as num?)?.toInt() ?? 0,
  lastLoggedAt: json['last_logged_at'] == null
      ? null
      : DateTime.parse(json['last_logged_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SavedFoodToJson(SavedFood instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'source_type': instance.sourceType,
  'barcode': instance.barcode,
  'image_url': instance.imageUrl,
  'total_calories': instance.totalCalories,
  'total_protein_g': instance.totalProteinG,
  'total_carbs_g': instance.totalCarbsG,
  'total_fat_g': instance.totalFatG,
  'total_fiber_g': instance.totalFiberG,
  'food_items': instance.foodItems,
  'overall_meal_score': instance.overallMealScore,
  'goal_alignment_percentage': instance.goalAlignmentPercentage,
  'tags': instance.tags,
  'notes': instance.notes,
  'times_logged': instance.timesLogged,
  'last_logged_at': instance.lastLoggedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

SavedFoodsResponse _$SavedFoodsResponseFromJson(Map<String, dynamic> json) =>
    SavedFoodsResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SavedFood.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SavedFoodsResponseToJson(SavedFoodsResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
    };

SaveFoodRequest _$SaveFoodRequestFromJson(Map<String, dynamic> json) =>
    SaveFoodRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      sourceType: json['source_type'] as String? ?? 'text',
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      totalCalories: (json['total_calories'] as num?)?.toInt(),
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble(),
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble(),
      totalFatG: (json['total_fat_g'] as num?)?.toDouble(),
      totalFiberG: (json['total_fiber_g'] as num?)?.toDouble(),
      foodItems:
          (json['food_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      overallMealScore: (json['overall_meal_score'] as num?)?.toInt(),
      goalAlignmentPercentage: (json['goal_alignment_percentage'] as num?)
          ?.toInt(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SaveFoodRequestToJson(SaveFoodRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'source_type': instance.sourceType,
      'barcode': instance.barcode,
      'image_url': instance.imageUrl,
      'total_calories': instance.totalCalories,
      'total_protein_g': instance.totalProteinG,
      'total_carbs_g': instance.totalCarbsG,
      'total_fat_g': instance.totalFatG,
      'total_fiber_g': instance.totalFiberG,
      'food_items': instance.foodItems,
      'overall_meal_score': instance.overallMealScore,
      'goal_alignment_percentage': instance.goalAlignmentPercentage,
      'tags': instance.tags,
    };

RelogSavedFoodRequest _$RelogSavedFoodRequestFromJson(
  Map<String, dynamic> json,
) => RelogSavedFoodRequest(mealType: json['meal_type'] as String);

Map<String, dynamic> _$RelogSavedFoodRequestToJson(
  RelogSavedFoodRequest instance,
) => <String, dynamic>{'meal_type': instance.mealType};
