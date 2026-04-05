import 'package:json_annotation/json_annotation.dart';


part 'nutrition_preferences_part_nutrition_goal.dart';
part 'nutrition_preferences_part_meal_template.dart';
part 'nutrition_preferences_part_weekly_nutrition_data.dart';


/// Nutrition preferences for a user
@JsonSerializable()
class NutritionPreferences {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;

  // Goal settings (multi-select)
  @JsonKey(name: 'nutrition_goals')
  final List<String> nutritionGoals;
  @JsonKey(name: 'nutrition_goal')
  final String nutritionGoal; // Legacy field for backward compatibility
  @JsonKey(name: 'rate_of_change')
  final String? rateOfChange;
  @JsonKey(name: 'goal_weight_kg')
  final double? goalWeightKg;
  @JsonKey(name: 'goal_date')
  final DateTime? goalDate;
  @JsonKey(name: 'weeks_to_goal')
  final int? weeksToGoal;

  // Calculated targets
  @JsonKey(name: 'calculated_bmr')
  final int? calculatedBmr;
  @JsonKey(name: 'calculated_tdee')
  final int? calculatedTdee;
  @JsonKey(name: 'target_calories')
  final int? targetCalories;
  @JsonKey(name: 'target_protein_g')
  final int? targetProteinG;
  @JsonKey(name: 'target_carbs_g')
  final int? targetCarbsG;
  @JsonKey(name: 'target_fat_g')
  final int? targetFatG;
  @JsonKey(name: 'target_fiber_g')
  final int targetFiberG;

  // Diet type
  @JsonKey(name: 'diet_type')
  final String dietType;
  @JsonKey(name: 'custom_carb_percent')
  final int? customCarbPercent;
  @JsonKey(name: 'custom_protein_percent')
  final int? customProteinPercent;
  @JsonKey(name: 'custom_fat_percent')
  final int? customFatPercent;

  // Restrictions
  final List<String> allergies;
  @JsonKey(name: 'dietary_restrictions')
  final List<String> dietaryRestrictions;
  @JsonKey(name: 'disliked_foods')
  final List<String> dislikedFoods;

  // Meal patterns
  @JsonKey(name: 'meal_pattern')
  final String mealPattern;

  // Lifestyle
  @JsonKey(name: 'cooking_skill')
  final String cookingSkill;
  @JsonKey(name: 'cooking_time_minutes')
  final int cookingTimeMinutes;
  @JsonKey(name: 'budget_level')
  final String budgetLevel;

  // Recipe suggestion preferences (body type, culture, spice)
  @JsonKey(name: 'body_type')
  final String bodyType;
  @JsonKey(name: 'favorite_cuisines')
  final List<String> favoriteCuisines;
  @JsonKey(name: 'cultural_background')
  final String? culturalBackground;
  @JsonKey(name: 'spice_tolerance')
  final String spiceTolerance;

  // Settings
  @JsonKey(name: 'show_ai_feedback_after_logging')
  final bool showAiFeedbackAfterLogging;
  @JsonKey(name: 'calm_mode_enabled')
  final bool calmModeEnabled;
  @JsonKey(name: 'show_weekly_instead_of_daily')
  final bool showWeeklyInsteadOfDaily;
  @JsonKey(name: 'adjust_calories_for_training')
  final bool adjustCaloriesForTraining;
  @JsonKey(name: 'adjust_calories_for_rest')
  final bool adjustCaloriesForRest;

  // Logging & Display settings
  @JsonKey(name: 'quick_log_mode_enabled')
  final bool quickLogModeEnabled;
  @JsonKey(name: 'compact_tracker_view_enabled')
  final bool compactTrackerViewEnabled;
  @JsonKey(name: 'show_macros_on_log')
  final bool showMacrosOnLog;

  // Tracking
  @JsonKey(name: 'nutrition_onboarding_completed')
  final bool nutritionOnboardingCompleted;
  @JsonKey(name: 'onboarding_completed_at')
  final DateTime? onboardingCompletedAt;
  @JsonKey(name: 'last_recalculated_at')
  final DateTime? lastRecalculatedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Calorie estimate bias
  @JsonKey(name: 'calorie_estimate_bias')
  final int calorieEstimateBias;

  // Weekly check-in settings
  @JsonKey(name: 'weekly_checkin_enabled')
  final bool weeklyCheckinEnabled;
  @JsonKey(name: 'last_weekly_checkin_at')
  final DateTime? lastWeeklyCheckinAt;
  @JsonKey(name: 'weekly_checkin_dismiss_count')
  final int weeklyCheckinDismissCount;

  const NutritionPreferences({
    this.id,
    required this.userId,
    this.nutritionGoals = const ['maintain'],
    this.nutritionGoal = 'maintain',
    this.rateOfChange,
    this.goalWeightKg,
    this.goalDate,
    this.weeksToGoal,
    this.calculatedBmr,
    this.calculatedTdee,
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.targetFiberG = 25,
    this.dietType = 'balanced',
    this.customCarbPercent,
    this.customProteinPercent,
    this.customFatPercent,
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.dislikedFoods = const [],
    this.mealPattern = '3_meals',
    this.cookingSkill = 'intermediate',
    this.cookingTimeMinutes = 30,
    this.budgetLevel = 'moderate',
    this.bodyType = 'balanced',
    this.favoriteCuisines = const [],
    this.culturalBackground,
    this.spiceTolerance = 'medium',
    this.showAiFeedbackAfterLogging = true,
    this.calmModeEnabled = false,
    this.showWeeklyInsteadOfDaily = false,
    this.adjustCaloriesForTraining = true,
    this.adjustCaloriesForRest = false,
    this.quickLogModeEnabled = false,
    this.compactTrackerViewEnabled = false,
    this.showMacrosOnLog = true,
    this.nutritionOnboardingCompleted = false,
    this.onboardingCompletedAt,
    this.lastRecalculatedAt,
    this.createdAt,
    this.updatedAt,
    this.calorieEstimateBias = 0,
    this.weeklyCheckinEnabled = true,
    this.lastWeeklyCheckinAt,
    this.weeklyCheckinDismissCount = 0,
  });

  /// Get nutrition goals as enums (multi-select)
  List<NutritionGoal> get nutritionGoalEnums => nutritionGoals
      .map((g) => NutritionGoal.fromString(g))
      .toList();

  /// Get primary nutrition goal enum (first in list)
  NutritionGoal get primaryGoalEnum => nutritionGoals.isNotEmpty
      ? NutritionGoal.fromString(nutritionGoals.first)
      : NutritionGoal.fromString(nutritionGoal);

  /// Get nutrition goal enum (legacy, uses primary goal)
  NutritionGoal get nutritionGoalEnum => primaryGoalEnum;

  /// Get diet type enum
  DietType get dietTypeEnum => DietType.fromString(dietType);

  /// Get meal pattern enum
  MealPattern get mealPatternEnum => MealPattern.fromString(mealPattern);

  /// Check if using intermittent fasting pattern
  bool get isIntermittentFasting =>
      mealPattern == 'if_16_8' || mealPattern == 'if_18_6';

  /// Get body type enum for recipe suggestions
  BodyType get bodyTypeEnum => BodyType.fromString(bodyType);

  /// Get spice tolerance enum for recipe suggestions
  SpiceTolerance get spiceToleranceEnum => SpiceTolerance.fromString(spiceTolerance);

  /// Get favorite cuisines as enums
  List<CuisineType> get favoriteCuisineEnums =>
      favoriteCuisines.map((c) => CuisineType.fromString(c)).toList();

  /// Check if weekly check-in is due (7+ days since last check-in)
  bool get isWeeklyCheckinDue {
    if (!weeklyCheckinEnabled) return false;
    if (lastWeeklyCheckinAt == null) return true; // Never checked in
    final daysSince = DateTime.now().difference(lastWeeklyCheckinAt!).inDays;
    return daysSince >= 7;
  }

  /// Days since last weekly check-in
  int? get daysSinceLastCheckin {
    if (lastWeeklyCheckinAt == null) return null;
    return DateTime.now().difference(lastWeeklyCheckinAt!).inDays;
  }

  factory NutritionPreferences.fromJson(Map<String, dynamic> json) =>
      _$NutritionPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionPreferencesToJson(this);

  NutritionPreferences copyWith({
    String? id,
    String? userId,
    List<String>? nutritionGoals,
    String? nutritionGoal,
    String? rateOfChange,
    double? goalWeightKg,
    DateTime? goalDate,
    int? weeksToGoal,
    int? calculatedBmr,
    int? calculatedTdee,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
    int? targetFiberG,
    String? dietType,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
    List<String>? dislikedFoods,
    String? mealPattern,
    String? cookingSkill,
    int? cookingTimeMinutes,
    String? budgetLevel,
    String? bodyType,
    List<String>? favoriteCuisines,
    String? culturalBackground,
    String? spiceTolerance,
    bool? showAiFeedbackAfterLogging,
    bool? calmModeEnabled,
    bool? showWeeklyInsteadOfDaily,
    bool? adjustCaloriesForTraining,
    bool? adjustCaloriesForRest,
    bool? quickLogModeEnabled,
    bool? compactTrackerViewEnabled,
    bool? showMacrosOnLog,
    bool? nutritionOnboardingCompleted,
    DateTime? onboardingCompletedAt,
    DateTime? lastRecalculatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? calorieEstimateBias,
    bool? weeklyCheckinEnabled,
    DateTime? lastWeeklyCheckinAt,
    int? weeklyCheckinDismissCount,
  }) {
    return NutritionPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      nutritionGoal: nutritionGoal ?? this.nutritionGoal,
      rateOfChange: rateOfChange ?? this.rateOfChange,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      goalDate: goalDate ?? this.goalDate,
      weeksToGoal: weeksToGoal ?? this.weeksToGoal,
      calculatedBmr: calculatedBmr ?? this.calculatedBmr,
      calculatedTdee: calculatedTdee ?? this.calculatedTdee,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      targetFatG: targetFatG ?? this.targetFatG,
      targetFiberG: targetFiberG ?? this.targetFiberG,
      dietType: dietType ?? this.dietType,
      customCarbPercent: customCarbPercent ?? this.customCarbPercent,
      customProteinPercent: customProteinPercent ?? this.customProteinPercent,
      customFatPercent: customFatPercent ?? this.customFatPercent,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      mealPattern: mealPattern ?? this.mealPattern,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      bodyType: bodyType ?? this.bodyType,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      culturalBackground: culturalBackground ?? this.culturalBackground,
      spiceTolerance: spiceTolerance ?? this.spiceTolerance,
      showAiFeedbackAfterLogging:
          showAiFeedbackAfterLogging ?? this.showAiFeedbackAfterLogging,
      calmModeEnabled: calmModeEnabled ?? this.calmModeEnabled,
      showWeeklyInsteadOfDaily:
          showWeeklyInsteadOfDaily ?? this.showWeeklyInsteadOfDaily,
      adjustCaloriesForTraining:
          adjustCaloriesForTraining ?? this.adjustCaloriesForTraining,
      adjustCaloriesForRest:
          adjustCaloriesForRest ?? this.adjustCaloriesForRest,
      quickLogModeEnabled:
          quickLogModeEnabled ?? this.quickLogModeEnabled,
      compactTrackerViewEnabled:
          compactTrackerViewEnabled ?? this.compactTrackerViewEnabled,
      showMacrosOnLog: showMacrosOnLog ?? this.showMacrosOnLog,
      nutritionOnboardingCompleted:
          nutritionOnboardingCompleted ?? this.nutritionOnboardingCompleted,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      lastRecalculatedAt: lastRecalculatedAt ?? this.lastRecalculatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      calorieEstimateBias:
          calorieEstimateBias ?? this.calorieEstimateBias,
      weeklyCheckinEnabled:
          weeklyCheckinEnabled ?? this.weeklyCheckinEnabled,
      lastWeeklyCheckinAt:
          lastWeeklyCheckinAt ?? this.lastWeeklyCheckinAt,
      weeklyCheckinDismissCount:
          weeklyCheckinDismissCount ?? this.weeklyCheckinDismissCount,
    );
  }
}

/// Weight log entry for tracking
@JsonSerializable()

/// Nutrition streak for consistency tracking
@JsonSerializable()

// ============================================
// Nutrition UI Preferences
// ============================================

/// UI preferences for nutrition tracking experience
@JsonSerializable()

// ============================================
// Meal Templates
// ============================================

/// A food item within a meal template
@JsonSerializable()

/// A saved meal template for quick logging
@JsonSerializable()

// ============================================
// Quick Suggestions
// ============================================

/// A quick food suggestion based on user history and time of day
@JsonSerializable()

// ============================================
// Food Search Result
// ============================================

/// Food search result for the search functionality
@JsonSerializable()
