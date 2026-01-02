// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionPreferences _$NutritionPreferencesFromJson(
  Map<String, dynamic> json,
) => NutritionPreferences(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  nutritionGoals:
      (json['nutrition_goals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['maintain'],
  nutritionGoal: json['nutrition_goal'] as String? ?? 'maintain',
  rateOfChange: json['rate_of_change'] as String?,
  calculatedBmr: (json['calculated_bmr'] as num?)?.toInt(),
  calculatedTdee: (json['calculated_tdee'] as num?)?.toInt(),
  targetCalories: (json['target_calories'] as num?)?.toInt(),
  targetProteinG: (json['target_protein_g'] as num?)?.toInt(),
  targetCarbsG: (json['target_carbs_g'] as num?)?.toInt(),
  targetFatG: (json['target_fat_g'] as num?)?.toInt(),
  targetFiberG: (json['target_fiber_g'] as num?)?.toInt() ?? 25,
  dietType: json['diet_type'] as String? ?? 'balanced',
  customCarbPercent: (json['custom_carb_percent'] as num?)?.toInt(),
  customProteinPercent: (json['custom_protein_percent'] as num?)?.toInt(),
  customFatPercent: (json['custom_fat_percent'] as num?)?.toInt(),
  allergies:
      (json['allergies'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dietaryRestrictions:
      (json['dietary_restrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dislikedFoods:
      (json['disliked_foods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  mealPattern: json['meal_pattern'] as String? ?? '3_meals',
  cookingSkill: json['cooking_skill'] as String? ?? 'intermediate',
  cookingTimeMinutes: (json['cooking_time_minutes'] as num?)?.toInt() ?? 30,
  budgetLevel: json['budget_level'] as String? ?? 'moderate',
  bodyType: json['body_type'] as String? ?? 'balanced',
  favoriteCuisines:
      (json['favorite_cuisines'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  culturalBackground: json['cultural_background'] as String?,
  spiceTolerance: json['spice_tolerance'] as String? ?? 'medium',
  showAiFeedbackAfterLogging:
      json['show_ai_feedback_after_logging'] as bool? ?? true,
  calmModeEnabled: json['calm_mode_enabled'] as bool? ?? false,
  showWeeklyInsteadOfDaily:
      json['show_weekly_instead_of_daily'] as bool? ?? false,
  adjustCaloriesForTraining:
      json['adjust_calories_for_training'] as bool? ?? true,
  adjustCaloriesForRest: json['adjust_calories_for_rest'] as bool? ?? false,
  quickLogModeEnabled: json['quick_log_mode_enabled'] as bool? ?? false,
  compactTrackerViewEnabled:
      json['compact_tracker_view_enabled'] as bool? ?? false,
  showMacrosOnLog: json['show_macros_on_log'] as bool? ?? true,
  nutritionOnboardingCompleted:
      json['nutrition_onboarding_completed'] as bool? ?? false,
  onboardingCompletedAt: json['onboarding_completed_at'] == null
      ? null
      : DateTime.parse(json['onboarding_completed_at'] as String),
  lastRecalculatedAt: json['last_recalculated_at'] == null
      ? null
      : DateTime.parse(json['last_recalculated_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NutritionPreferencesToJson(
  NutritionPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'nutrition_goals': instance.nutritionGoals,
  'nutrition_goal': instance.nutritionGoal,
  'rate_of_change': instance.rateOfChange,
  'calculated_bmr': instance.calculatedBmr,
  'calculated_tdee': instance.calculatedTdee,
  'target_calories': instance.targetCalories,
  'target_protein_g': instance.targetProteinG,
  'target_carbs_g': instance.targetCarbsG,
  'target_fat_g': instance.targetFatG,
  'target_fiber_g': instance.targetFiberG,
  'diet_type': instance.dietType,
  'custom_carb_percent': instance.customCarbPercent,
  'custom_protein_percent': instance.customProteinPercent,
  'custom_fat_percent': instance.customFatPercent,
  'allergies': instance.allergies,
  'dietary_restrictions': instance.dietaryRestrictions,
  'disliked_foods': instance.dislikedFoods,
  'meal_pattern': instance.mealPattern,
  'cooking_skill': instance.cookingSkill,
  'cooking_time_minutes': instance.cookingTimeMinutes,
  'budget_level': instance.budgetLevel,
  'body_type': instance.bodyType,
  'favorite_cuisines': instance.favoriteCuisines,
  'cultural_background': instance.culturalBackground,
  'spice_tolerance': instance.spiceTolerance,
  'show_ai_feedback_after_logging': instance.showAiFeedbackAfterLogging,
  'calm_mode_enabled': instance.calmModeEnabled,
  'show_weekly_instead_of_daily': instance.showWeeklyInsteadOfDaily,
  'adjust_calories_for_training': instance.adjustCaloriesForTraining,
  'adjust_calories_for_rest': instance.adjustCaloriesForRest,
  'quick_log_mode_enabled': instance.quickLogModeEnabled,
  'compact_tracker_view_enabled': instance.compactTrackerViewEnabled,
  'show_macros_on_log': instance.showMacrosOnLog,
  'nutrition_onboarding_completed': instance.nutritionOnboardingCompleted,
  'onboarding_completed_at': instance.onboardingCompletedAt?.toIso8601String(),
  'last_recalculated_at': instance.lastRecalculatedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

WeightLog _$WeightLogFromJson(Map<String, dynamic> json) => WeightLog(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  weightKg: (json['weight_kg'] as num).toDouble(),
  loggedAt: DateTime.parse(json['logged_at'] as String),
  source: json['source'] as String? ?? 'manual',
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WeightLogToJson(WeightLog instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'weight_kg': instance.weightKg,
  'logged_at': instance.loggedAt.toIso8601String(),
  'source': instance.source,
  'notes': instance.notes,
  'created_at': instance.createdAt?.toIso8601String(),
};

NutritionStreak _$NutritionStreakFromJson(Map<String, dynamic> json) =>
    NutritionStreak(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      currentStreakDays: (json['current_streak_days'] as num?)?.toInt() ?? 0,
      streakStartDate: json['streak_start_date'] == null
          ? null
          : DateTime.parse(json['streak_start_date'] as String),
      lastLoggedDate: json['last_logged_date'] == null
          ? null
          : DateTime.parse(json['last_logged_date'] as String),
      freezesAvailable: (json['freezes_available'] as num?)?.toInt() ?? 2,
      freezesUsedThisWeek:
          (json['freezes_used_this_week'] as num?)?.toInt() ?? 0,
      weekStartDate: json['week_start_date'] == null
          ? null
          : DateTime.parse(json['week_start_date'] as String),
      longestStreakEver: (json['longest_streak_ever'] as num?)?.toInt() ?? 0,
      totalDaysLogged: (json['total_days_logged'] as num?)?.toInt() ?? 0,
      weeklyGoalEnabled: json['weekly_goal_enabled'] as bool? ?? false,
      weeklyGoalDays: (json['weekly_goal_days'] as num?)?.toInt() ?? 5,
      daysLoggedThisWeek: (json['days_logged_this_week'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NutritionStreakToJson(NutritionStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'current_streak_days': instance.currentStreakDays,
      'streak_start_date': instance.streakStartDate?.toIso8601String(),
      'last_logged_date': instance.lastLoggedDate?.toIso8601String(),
      'freezes_available': instance.freezesAvailable,
      'freezes_used_this_week': instance.freezesUsedThisWeek,
      'week_start_date': instance.weekStartDate?.toIso8601String(),
      'longest_streak_ever': instance.longestStreakEver,
      'total_days_logged': instance.totalDaysLogged,
      'weekly_goal_enabled': instance.weeklyGoalEnabled,
      'weekly_goal_days': instance.weeklyGoalDays,
      'days_logged_this_week': instance.daysLoggedThisWeek,
    };

NutritionUIPreferences _$NutritionUIPreferencesFromJson(
  Map<String, dynamic> json,
) => NutritionUIPreferences(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  disableAiTips: json['disable_ai_tips'] as bool? ?? false,
  defaultMealType: json['default_meal_type'] as String? ?? 'auto',
  quickLogMode: json['quick_log_mode'] as bool? ?? true,
  showMacrosOnLog: json['show_macros_on_log'] as bool? ?? true,
  compactTrackerView: json['compact_tracker_view'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NutritionUIPreferencesToJson(
  NutritionUIPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'disable_ai_tips': instance.disableAiTips,
  'default_meal_type': instance.defaultMealType,
  'quick_log_mode': instance.quickLogMode,
  'show_macros_on_log': instance.showMacrosOnLog,
  'compact_tracker_view': instance.compactTrackerView,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

TemplateFoodItem _$TemplateFoodItemFromJson(Map<String, dynamic> json) =>
    TemplateFoodItem(
      name: json['name'] as String,
      calories: (json['calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      amount: json['amount'] as String?,
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$TemplateFoodItemToJson(TemplateFoodItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'sodium_mg': instance.sodiumMg,
      'amount': instance.amount,
      'unit': instance.unit,
    };

MealTemplate _$MealTemplateFromJson(Map<String, dynamic> json) => MealTemplate(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  name: json['name'] as String,
  mealType: json['meal_type'] as String,
  foodItems:
      (json['food_items'] as List<dynamic>?)
          ?.map((e) => TemplateFoodItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalCalories: (json['total_calories'] as num?)?.toInt(),
  totalProteinG: (json['total_protein_g'] as num?)?.toDouble(),
  totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble(),
  totalFatG: (json['total_fat_g'] as num?)?.toDouble(),
  isSystemTemplate: json['is_system_template'] as bool? ?? false,
  useCount: (json['use_count'] as num?)?.toInt() ?? 0,
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  description: json['description'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$MealTemplateToJson(MealTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'meal_type': instance.mealType,
      'food_items': instance.foodItems,
      'total_calories': instance.totalCalories,
      'total_protein_g': instance.totalProteinG,
      'total_carbs_g': instance.totalCarbsG,
      'total_fat_g': instance.totalFatG,
      'is_system_template': instance.isSystemTemplate,
      'use_count': instance.useCount,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'description': instance.description,
      'tags': instance.tags,
      'image_url': instance.imageUrl,
    };

QuickSuggestion _$QuickSuggestionFromJson(Map<String, dynamic> json) =>
    QuickSuggestion(
      foodName: json['food_name'] as String,
      mealType: json['meal_type'] as String,
      calories: (json['calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      logCount: (json['log_count'] as num?)?.toInt() ?? 0,
      timeOfDayBucket: json['time_of_day_bucket'] as String?,
      savedFoodId: json['saved_food_id'] as String?,
      templateId: json['template_id'] as String?,
      lastLoggedAt: json['last_logged_at'] == null
          ? null
          : DateTime.parse(json['last_logged_at'] as String),
      avgServings: (json['avg_servings'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$QuickSuggestionToJson(QuickSuggestion instance) =>
    <String, dynamic>{
      'food_name': instance.foodName,
      'meal_type': instance.mealType,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'log_count': instance.logCount,
      'time_of_day_bucket': instance.timeOfDayBucket,
      'saved_food_id': instance.savedFoodId,
      'template_id': instance.templateId,
      'last_logged_at': instance.lastLoggedAt?.toIso8601String(),
      'avg_servings': instance.avgServings,
      'description': instance.description,
    };

FoodSearchResult _$FoodSearchResultFromJson(Map<String, dynamic> json) =>
    FoodSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      servingSize: json['serving_size'] as String?,
      servingUnit: json['serving_unit'] as String?,
      calories: (json['calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceType: json['source_type'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );

Map<String, dynamic> _$FoodSearchResultToJson(FoodSearchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'category': instance.category,
      'serving_size': instance.servingSize,
      'serving_unit': instance.servingUnit,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'barcode': instance.barcode,
      'image_url': instance.imageUrl,
      'source_type': instance.sourceType,
      'is_verified': instance.isVerified,
    };
