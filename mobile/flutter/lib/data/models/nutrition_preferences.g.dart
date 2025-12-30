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
  showAiFeedbackAfterLogging:
      json['show_ai_feedback_after_logging'] as bool? ?? true,
  calmModeEnabled: json['calm_mode_enabled'] as bool? ?? false,
  showWeeklyInsteadOfDaily:
      json['show_weekly_instead_of_daily'] as bool? ?? false,
  adjustCaloriesForTraining:
      json['adjust_calories_for_training'] as bool? ?? true,
  adjustCaloriesForRest: json['adjust_calories_for_rest'] as bool? ?? false,
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
  'show_ai_feedback_after_logging': instance.showAiFeedbackAfterLogging,
  'calm_mode_enabled': instance.calmModeEnabled,
  'show_weekly_instead_of_daily': instance.showWeeklyInsteadOfDaily,
  'adjust_calories_for_training': instance.adjustCaloriesForTraining,
  'adjust_calories_for_rest': instance.adjustCaloriesForRest,
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
