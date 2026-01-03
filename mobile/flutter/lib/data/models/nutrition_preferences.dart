import 'package:json_annotation/json_annotation.dart';

part 'nutrition_preferences.g.dart';

/// Nutrition goal options
enum NutritionGoal {
  loseFat('lose_fat', 'Lose Fat', -500, 2.0),
  buildMuscle('build_muscle', 'Build Muscle', 300, 1.8),
  maintain('maintain', 'Maintain Weight', 0, 1.6),
  improveEnergy('improve_energy', 'Improve Energy', 0, 1.4),
  eatHealthier('eat_healthier', 'Eat Healthier', 0, 1.4),
  recomposition('recomposition', 'Body Recomposition', -200, 2.2);

  final String value;
  final String displayName;
  final int calorieAdjustment;
  final double proteinPerKg;

  const NutritionGoal(
    this.value,
    this.displayName,
    this.calorieAdjustment,
    this.proteinPerKg,
  );

  static NutritionGoal fromString(String value) {
    return NutritionGoal.values.firstWhere(
      (g) => g.value == value || g.name == value,
      orElse: () => NutritionGoal.maintain,
    );
  }
}

/// Rate of change options
enum RateOfChange {
  slow('slow', 'Slow & Steady', 0.25, 250),
  moderate('moderate', 'Moderate (Recommended)', 0.5, 500),
  aggressive('aggressive', 'Aggressive', 0.75, 750);

  final String value;
  final String displayName;
  final double kgPerWeek;
  final int calorieAdjustment;

  const RateOfChange(
    this.value,
    this.displayName,
    this.kgPerWeek,
    this.calorieAdjustment,
  );

  static RateOfChange fromString(String value) {
    return RateOfChange.values.firstWhere(
      (r) => r.value == value || r.name == value,
      orElse: () => RateOfChange.moderate,
    );
  }
}

/// Diet type options
enum DietType {
  // No restrictions
  noDiet('no_diet', 'I Eat Everything', 45, 25, 30),

  // Macro-focused diets
  balanced('balanced', 'Balanced', 45, 25, 30),
  lowCarb('low_carb', 'Low Carb', 25, 35, 40),
  keto('keto', 'Keto', 5, 25, 70),
  highProtein('high_protein', 'High Protein', 35, 40, 25),
  mediterranean('mediterranean', 'Mediterranean', 45, 20, 35),

  // Plant-based diets (strict to flexible)
  vegan('vegan', 'Vegan', 55, 20, 25),
  vegetarian('vegetarian', 'Vegetarian', 50, 20, 30),
  lactoOvo('lacto_ovo', 'Lacto-Ovo Vegetarian', 50, 22, 28),
  pescatarian('pescatarian', 'Pescatarian', 45, 25, 30),

  // Flexible/part-time diets
  flexitarian('flexitarian', 'Flexitarian', 45, 25, 30),
  partTimeVeg('part_time_veg', 'Part-Time Vegetarian', 50, 20, 30),

  // Custom
  custom('custom', 'Custom', 0, 0, 0);

  final String value;
  final String displayName;
  final int carbPercent;
  final int proteinPercent;
  final int fatPercent;

  const DietType(
    this.value,
    this.displayName,
    this.carbPercent,
    this.proteinPercent,
    this.fatPercent,
  );

  static DietType fromString(String value) {
    return DietType.values.firstWhere(
      (d) => d.value == value || d.name == value,
      orElse: () => DietType.balanced,
    );
  }
}

/// Meal pattern options
enum MealPattern {
  threeMeals('3_meals', '3 Meals', 3),
  threeMealsSnacks('3_meals_snacks', '3 Meals + Snacks', 5),
  twoMeals('2_meals', '2 Meals', 2),
  omad('omad', 'One Meal a Day (OMAD)', 1),
  if168('if_16_8', 'Intermittent Fasting (16:8)', 2),
  if186('if_18_6', 'Intermittent Fasting (18:6)', 2),
  if204('if_20_4', 'Intermittent Fasting (20:4)', 1),
  smallMeals('5_6_small_meals', '5-6 Small Meals', 6),
  religiousFasting('religious_fasting', 'Religious/Traditional Fasting', 3),
  custom('custom', 'Custom Schedule', 3);

  final String value;
  final String displayName;
  final int typicalMeals;

  const MealPattern(this.value, this.displayName, this.typicalMeals);

  static MealPattern fromString(String value) {
    return MealPattern.values.firstWhere(
      (m) => m.value == value || m.name == value,
      orElse: () => MealPattern.threeMeals,
    );
  }
}

/// FDA Big 9 allergens + common restrictions
enum FoodAllergen {
  milk('milk', 'Milk/Dairy'),
  eggs('eggs', 'Eggs'),
  fish('fish', 'Fish'),
  shellfish('shellfish', 'Shellfish'),
  treeNuts('tree_nuts', 'Tree Nuts'),
  peanuts('peanuts', 'Peanuts'),
  wheat('wheat', 'Wheat/Gluten'),
  soy('soy', 'Soy'),
  sesame('sesame', 'Sesame');

  final String value;
  final String displayName;

  const FoodAllergen(this.value, this.displayName);
}

/// Dietary restrictions
enum DietaryRestriction {
  vegetarian('vegetarian', 'Vegetarian'),
  vegan('vegan', 'Vegan'),
  halal('halal', 'Halal'),
  kosher('kosher', 'Kosher'),
  lactoseFree('lactose_free', 'Lactose Free'),
  glutenFree('gluten_free', 'Gluten Free'),
  noPork('no_pork', 'No Pork'),
  noBeef('no_beef', 'No Beef'),
  noAlcohol('no_alcohol', 'No Alcohol');

  final String value;
  final String displayName;

  const DietaryRestriction(this.value, this.displayName);
}

/// Cooking skill levels
enum CookingSkill {
  beginner('beginner', 'Beginner', 'Quick & easy recipes'),
  intermediate('intermediate', 'Intermediate', 'Some cooking experience'),
  advanced('advanced', 'Advanced', 'Complex recipes welcome');

  final String value;
  final String displayName;
  final String description;

  const CookingSkill(this.value, this.displayName, this.description);

  static CookingSkill fromString(String value) {
    return CookingSkill.values.firstWhere(
      (c) => c.value == value || c.name == value,
      orElse: () => CookingSkill.intermediate,
    );
  }
}

/// Budget levels
enum BudgetLevel {
  budget('budget', 'Budget-Friendly'),
  moderate('moderate', 'Moderate'),
  noConstraints('no_constraints', 'No Constraints');

  final String value;
  final String displayName;

  const BudgetLevel(this.value, this.displayName);

  static BudgetLevel fromString(String value) {
    return BudgetLevel.values.firstWhere(
      (b) => b.value == value || b.name == value,
      orElse: () => BudgetLevel.moderate,
    );
  }
}

/// Body type for metabolic-based recipe suggestions
enum BodyType {
  ectomorph('ectomorph', 'Ectomorph', 'Lean build, fast metabolism - needs calorie-dense meals'),
  mesomorph('mesomorph', 'Mesomorph', 'Athletic build, moderate metabolism - balanced approach'),
  endomorph('endomorph', 'Endomorph', 'Solid build, slower metabolism - lower carb focus'),
  balanced('balanced', 'Balanced', 'No specific body type - general recommendations');

  final String value;
  final String displayName;
  final String description;

  const BodyType(this.value, this.displayName, this.description);

  static BodyType fromString(String value) {
    return BodyType.values.firstWhere(
      (b) => b.value == value || b.name == value,
      orElse: () => BodyType.balanced,
    );
  }
}

/// Spice tolerance levels for recipe suggestions
enum SpiceTolerance {
  none('none', 'No Spice', 'Mild flavors only'),
  mild('mild', 'Mild', 'Light seasoning'),
  medium('medium', 'Medium', 'Moderate heat'),
  hot('hot', 'Hot', 'Spicy food lover'),
  extreme('extreme', 'Extreme', 'Bring on the heat!');

  final String value;
  final String displayName;
  final String description;

  const SpiceTolerance(this.value, this.displayName, this.description);

  static SpiceTolerance fromString(String value) {
    return SpiceTolerance.values.firstWhere(
      (s) => s.value == value || s.name == value,
      orElse: () => SpiceTolerance.medium,
    );
  }
}

/// Cuisine types for recipe suggestions
enum CuisineType {
  american('american', 'American', 'North America'),
  mexican('mexican', 'Mexican', 'North America'),
  italian('italian', 'Italian', 'Europe'),
  french('french', 'French', 'Europe'),
  spanish('spanish', 'Spanish', 'Europe'),
  greek('greek', 'Greek', 'Europe'),
  british('british', 'British', 'Europe'),
  german('german', 'German', 'Europe'),
  indian('indian', 'Indian', 'South Asia'),
  chinese('chinese', 'Chinese', 'East Asia'),
  japanese('japanese', 'Japanese', 'East Asia'),
  korean('korean', 'Korean', 'East Asia'),
  thai('thai', 'Thai', 'Southeast Asia'),
  vietnamese('vietnamese', 'Vietnamese', 'Southeast Asia'),
  mediterranean('mediterranean', 'Mediterranean', 'Mediterranean'),
  middleEastern('middle_eastern', 'Middle Eastern', 'Middle East'),
  african('african', 'African', 'Africa'),
  caribbean('caribbean', 'Caribbean', 'Caribbean'),
  brazilian('brazilian', 'Brazilian', 'South America'),
  fusion('fusion', 'Fusion', 'Mixed');

  final String value;
  final String displayName;
  final String region;

  const CuisineType(this.value, this.displayName, this.region);

  static CuisineType fromString(String value) {
    return CuisineType.values.firstWhere(
      (c) => c.value == value || c.name == value,
      orElse: () => CuisineType.american,
    );
  }
}

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

  // Weekly check-in settings
  @JsonKey(name: 'weekly_checkin_enabled')
  final bool weeklyCheckinEnabled;
  @JsonKey(name: 'last_weekly_checkin_at')
  final DateTime? lastWeeklyCheckinAt;

  const NutritionPreferences({
    this.id,
    required this.userId,
    this.nutritionGoals = const ['maintain'],
    this.nutritionGoal = 'maintain',
    this.rateOfChange,
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
    this.weeklyCheckinEnabled = true,
    this.lastWeeklyCheckinAt,
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
    bool? weeklyCheckinEnabled,
    DateTime? lastWeeklyCheckinAt,
  }) {
    return NutritionPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      nutritionGoal: nutritionGoal ?? this.nutritionGoal,
      rateOfChange: rateOfChange ?? this.rateOfChange,
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
      weeklyCheckinEnabled:
          weeklyCheckinEnabled ?? this.weeklyCheckinEnabled,
      lastWeeklyCheckinAt:
          lastWeeklyCheckinAt ?? this.lastWeeklyCheckinAt,
    );
  }
}

/// Weight log entry for tracking
@JsonSerializable()
class WeightLog {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'weight_kg')
  final double weightKg;
  @JsonKey(name: 'logged_at')
  final DateTime loggedAt;
  final String source;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const WeightLog({
    this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
    this.source = 'manual',
    this.notes,
    this.createdAt,
  });

  /// Get weight in pounds
  double get weightLbs => weightKg * 2.20462;

  factory WeightLog.fromJson(Map<String, dynamic> json) =>
      _$WeightLogFromJson(json);
  Map<String, dynamic> toJson() => _$WeightLogToJson(this);
}

/// Nutrition streak for consistency tracking
@JsonSerializable()
class NutritionStreak {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'current_streak_days')
  final int currentStreakDays;
  @JsonKey(name: 'streak_start_date')
  final DateTime? streakStartDate;
  @JsonKey(name: 'last_logged_date')
  final DateTime? lastLoggedDate;
  @JsonKey(name: 'freezes_available')
  final int freezesAvailable;
  @JsonKey(name: 'freezes_used_this_week')
  final int freezesUsedThisWeek;
  @JsonKey(name: 'week_start_date')
  final DateTime? weekStartDate;
  @JsonKey(name: 'longest_streak_ever')
  final int longestStreakEver;
  @JsonKey(name: 'total_days_logged')
  final int totalDaysLogged;
  @JsonKey(name: 'weekly_goal_enabled')
  final bool weeklyGoalEnabled;
  @JsonKey(name: 'weekly_goal_days')
  final int weeklyGoalDays;
  @JsonKey(name: 'days_logged_this_week')
  final int daysLoggedThisWeek;

  const NutritionStreak({
    this.id,
    required this.userId,
    this.currentStreakDays = 0,
    this.streakStartDate,
    this.lastLoggedDate,
    this.freezesAvailable = 2,
    this.freezesUsedThisWeek = 0,
    this.weekStartDate,
    this.longestStreakEver = 0,
    this.totalDaysLogged = 0,
    this.weeklyGoalEnabled = false,
    this.weeklyGoalDays = 5,
    this.daysLoggedThisWeek = 0,
  });

  /// Check if weekly goal is met
  bool get weeklyGoalMet =>
      weeklyGoalEnabled && daysLoggedThisWeek >= weeklyGoalDays;

  /// Days remaining to meet weekly goal
  int get daysRemainingForGoal {
    if (!weeklyGoalEnabled) return 0;
    final remaining = weeklyGoalDays - daysLoggedThisWeek;
    return remaining > 0 ? remaining : 0;
  }

  factory NutritionStreak.fromJson(Map<String, dynamic> json) =>
      _$NutritionStreakFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionStreakToJson(this);
}

/// Nutrition calculator for BMR/TDEE/macros
class NutritionCalculator {
  /// Activity level multipliers for TDEE
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
    'extra_active': 1.9,
  };

  /// Minimum calorie thresholds by gender
  static const int minCaloriesFemale = 1200;
  static const int minCaloriesMale = 1500;

  /// Calculate BMR using Mifflin-St Jeor equation
  static int calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return ((10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5).round();
    } else {
      return ((10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161).round();
    }
  }

  /// Calculate TDEE from BMR and activity level
  static int calculateTdee(int bmr, String activityLevel) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return (bmr * multiplier).round();
  }

  /// Calculate safe target calories with minimum thresholds
  static ({int calories, bool wasAdjusted, String? adjustmentReason})
      calculateSafeTarget({
    required int tdee,
    required String gender,
    required NutritionGoal goal,
    required RateOfChange rate,
  }) {
    // Calculate raw adjustment based on goal
    int adjustment = goal.calorieAdjustment;

    // Apply rate of change modifier for weight goals
    if (goal == NutritionGoal.loseFat) {
      adjustment = -rate.calorieAdjustment;
    } else if (goal == NutritionGoal.buildMuscle) {
      adjustment = rate.calorieAdjustment ~/ 2; // Smaller surplus
    }

    int targetCalories = tdee + adjustment;

    // Apply minimum threshold
    final minimum =
        gender.toLowerCase() == 'female' ? minCaloriesFemale : minCaloriesMale;

    if (targetCalories < minimum) {
      return (
        calories: minimum,
        wasAdjusted: true,
        adjustmentReason:
            'Adjusted to safe minimum of $minimum calories per day.',
      );
    }

    return (calories: targetCalories, wasAdjusted: false, adjustmentReason: null);
  }

  /// Calculate macro targets from calories and diet type
  static ({int protein, int carbs, int fat}) calculateMacros({
    required int calories,
    required DietType dietType,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
  }) {
    int carbPercent, proteinPercent, fatPercent;

    if (dietType == DietType.custom &&
        customCarbPercent != null &&
        customProteinPercent != null &&
        customFatPercent != null) {
      carbPercent = customCarbPercent;
      proteinPercent = customProteinPercent;
      fatPercent = customFatPercent;
    } else {
      carbPercent = dietType.carbPercent;
      proteinPercent = dietType.proteinPercent;
      fatPercent = dietType.fatPercent;
    }

    // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    final protein = ((calories * proteinPercent / 100) / 4).round();
    final carbs = ((calories * carbPercent / 100) / 4).round();
    final fat = ((calories * fatPercent / 100) / 9).round();

    return (protein: protein, carbs: carbs, fat: fat);
  }

  /// Calculate all nutrition targets from user data
  /// Accepts multiple goals - uses the first goal for calorie calculations
  /// but stores all goals in the preferences
  static NutritionPreferences calculateTargets({
    required String userId,
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required NutritionGoal goal, // Primary goal for calculations
    List<NutritionGoal>? goals, // All selected goals (multi-select)
    required RateOfChange rate,
    required DietType dietType,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
  }) {
    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final tdee = calculateTdee(bmr, activityLevel);

    final (:calories, :wasAdjusted, :adjustmentReason) = calculateSafeTarget(
      tdee: tdee,
      gender: gender,
      goal: goal,
      rate: rate,
    );

    final (:protein, :carbs, :fat) = calculateMacros(
      calories: calories,
      dietType: dietType,
      customCarbPercent: customCarbPercent,
      customProteinPercent: customProteinPercent,
      customFatPercent: customFatPercent,
    );

    // Build goals list - use provided goals or default to single goal
    final goalsList = goals?.map((g) => g.value).toList() ?? [goal.value];

    return NutritionPreferences(
      userId: userId,
      nutritionGoals: goalsList,
      nutritionGoal: goal.value, // Legacy field
      rateOfChange: rate.value,
      calculatedBmr: bmr,
      calculatedTdee: tdee,
      targetCalories: calories,
      targetProteinG: protein,
      targetCarbsG: carbs,
      targetFatG: fat,
      dietType: dietType.value,
      customCarbPercent: customCarbPercent,
      customProteinPercent: customProteinPercent,
      customFatPercent: customFatPercent,
    );
  }
}

// ============================================
// Weekly Check-in Models
// ============================================

/// Weekly nutrition summary data for check-in
class WeeklySummaryData {
  final int daysLogged;
  final int avgCalories;
  final int avgProtein;
  final double? weightChange;

  const WeeklySummaryData({
    required this.daysLogged,
    required this.avgCalories,
    required this.avgProtein,
    this.weightChange,
  });

  factory WeeklySummaryData.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryData(
      daysLogged: json['days_logged'] as int? ?? 0,
      avgCalories: (json['avg_calories'] as num?)?.toInt() ?? 0,
      avgProtein: (json['avg_protein'] as num?)?.toInt() ?? 0,
      weightChange: (json['weight_change'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'days_logged': daysLogged,
    'avg_calories': avgCalories,
    'avg_protein': avgProtein,
    'weight_change': weightChange,
  };
}

/// Adaptive TDEE calculation result
class AdaptiveCalculation {
  final String id;
  final String? userId;
  final DateTime? calculatedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int calculatedTdee;
  final double dataQualityScore;
  final String confidenceLevel;
  final int avgDailyIntake;
  final double? startTrendWeightKg;
  final double? endTrendWeightKg;
  final int daysLogged;
  final int weightEntries;

  const AdaptiveCalculation({
    required this.id,
    this.userId,
    this.calculatedAt,
    this.periodStart,
    this.periodEnd,
    required this.calculatedTdee,
    required this.dataQualityScore,
    this.confidenceLevel = 'low',
    required this.avgDailyIntake,
    this.startTrendWeightKg,
    this.endTrendWeightKg,
    required this.daysLogged,
    required this.weightEntries,
  });

  /// Get confidence display text
  String get confidenceDisplay {
    switch (confidenceLevel) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Medium confidence';
      default:
        return 'Low confidence - need more data';
    }
  }

  /// Check if enough data for reliable calculation
  bool get hasEnoughData => dataQualityScore >= 0.6;

  /// Check if there's enough data for reliable calculation
  bool get hasReliableData => dataQualityScore >= 0.6 && daysLogged >= 6;

  factory AdaptiveCalculation.fromJson(Map<String, dynamic> json) {
    return AdaptiveCalculation(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'] as String)
          : null,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
      calculatedTdee: json['calculated_tdee'] as int? ?? 0,
      dataQualityScore: (json['data_quality_score'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidence_level'] as String? ?? 'low',
      avgDailyIntake: json['avg_daily_intake'] as int? ?? 0,
      startTrendWeightKg: (json['start_trend_weight_kg'] as num?)?.toDouble(),
      endTrendWeightKg: (json['end_trend_weight_kg'] as num?)?.toDouble(),
      daysLogged: json['days_logged'] as int? ?? 0,
      weightEntries: json['weight_entries'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'calculated_at': calculatedAt?.toIso8601String(),
    'period_start': periodStart?.toIso8601String(),
    'period_end': periodEnd?.toIso8601String(),
    'calculated_tdee': calculatedTdee,
    'data_quality_score': dataQualityScore,
    'confidence_level': confidenceLevel,
    'avg_daily_intake': avgDailyIntake,
    'start_trend_weight_kg': startTrendWeightKg,
    'end_trend_weight_kg': endTrendWeightKg,
    'days_logged': daysLogged,
    'weight_entries': weightEntries,
  };
}

/// Weekly nutrition recommendation from adaptive algorithm
class WeeklyRecommendation {
  final String id;
  final String userId;
  final int recommendedCalories;
  final int recommendedProteinG;
  final int recommendedCarbsG;
  final int recommendedFatG;
  final String? adjustmentReason;
  final int adjustmentAmount;
  final String currentGoal;
  final double targetRatePerWeek;
  final bool userAccepted;
  final bool userModified;
  final int? modifiedCalories;

  const WeeklyRecommendation({
    required this.id,
    required this.userId,
    required this.recommendedCalories,
    required this.recommendedProteinG,
    required this.recommendedCarbsG,
    required this.recommendedFatG,
    this.adjustmentReason,
    this.adjustmentAmount = 0,
    required this.currentGoal,
    required this.targetRatePerWeek,
    this.userAccepted = false,
    this.userModified = false,
    this.modifiedCalories,
  });

  /// Get goal display name
  String get goalDisplayName {
    switch (currentGoal) {
      case 'lose_fat':
        return 'Fat Loss';
      case 'build_muscle':
        return 'Muscle Gain';
      case 'maintain':
        return 'Maintenance';
      case 'recomposition':
        return 'Body Recomposition';
      default:
        return 'General Health';
    }
  }

  /// Format target rate for display
  String get formattedRate {
    if (targetRatePerWeek == 0) return 'Maintain weight';
    final sign = targetRatePerWeek > 0 ? '+' : '';
    return '$sign${targetRatePerWeek.toStringAsFixed(2)} kg/week';
  }

  factory WeeklyRecommendation.fromJson(Map<String, dynamic> json) {
    return WeeklyRecommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recommendedCalories: json['recommended_calories'] as int,
      recommendedProteinG: json['recommended_protein_g'] as int,
      recommendedCarbsG: json['recommended_carbs_g'] as int,
      recommendedFatG: json['recommended_fat_g'] as int,
      adjustmentReason: json['adjustment_reason'] as String?,
      adjustmentAmount: json['adjustment_amount'] as int? ?? 0,
      currentGoal: json['current_goal'] as String? ?? 'maintain',
      targetRatePerWeek: (json['target_rate_per_week'] as num?)?.toDouble() ?? 0.0,
      userAccepted: json['user_accepted'] as bool? ?? false,
      userModified: json['user_modified'] as bool? ?? false,
      modifiedCalories: json['modified_calories'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'recommended_calories': recommendedCalories,
    'recommended_protein_g': recommendedProteinG,
    'recommended_carbs_g': recommendedCarbsG,
    'recommended_fat_g': recommendedFatG,
    'adjustment_reason': adjustmentReason,
    'adjustment_amount': adjustmentAmount,
    'current_goal': currentGoal,
    'target_rate_per_week': targetRatePerWeek,
    'user_accepted': userAccepted,
    'user_modified': userModified,
    'modified_calories': modifiedCalories,
  };
}

// ============================================
// Nutrition UI Preferences
// ============================================

/// UI preferences for nutrition tracking experience
@JsonSerializable()
class NutritionUIPreferences {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;

  /// Toggle to hide AI suggestions after logging
  @JsonKey(name: 'disable_ai_tips')
  final bool disableAiTips;

  /// Default meal type: auto, breakfast, lunch, dinner, snack
  @JsonKey(name: 'default_meal_type')
  final String defaultMealType;

  /// Enable/disable quick add button
  @JsonKey(name: 'quick_log_mode')
  final bool quickLogMode;

  /// Show macro breakdown on log confirmation
  @JsonKey(name: 'show_macros_on_log')
  final bool showMacrosOnLog;

  /// Use compact nutrition tracker layout
  @JsonKey(name: 'compact_tracker_view')
  final bool compactTrackerView;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const NutritionUIPreferences({
    this.id,
    required this.userId,
    this.disableAiTips = false,
    this.defaultMealType = 'auto',
    this.quickLogMode = true,
    this.showMacrosOnLog = true,
    this.compactTrackerView = false,
    this.createdAt,
    this.updatedAt,
  });

  factory NutritionUIPreferences.fromJson(Map<String, dynamic> json) =>
      _$NutritionUIPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionUIPreferencesToJson(this);

  NutritionUIPreferences copyWith({
    String? id,
    String? userId,
    bool? disableAiTips,
    String? defaultMealType,
    bool? quickLogMode,
    bool? showMacrosOnLog,
    bool? compactTrackerView,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionUIPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      disableAiTips: disableAiTips ?? this.disableAiTips,
      defaultMealType: defaultMealType ?? this.defaultMealType,
      quickLogMode: quickLogMode ?? this.quickLogMode,
      showMacrosOnLog: showMacrosOnLog ?? this.showMacrosOnLog,
      compactTrackerView: compactTrackerView ?? this.compactTrackerView,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create default preferences for a user
  static NutritionUIPreferences defaultPreferences(String userId) {
    return NutritionUIPreferences(
      userId: userId,
      disableAiTips: false,
      defaultMealType: 'auto',
      quickLogMode: true,
      showMacrosOnLog: true,
      compactTrackerView: false,
    );
  }

  /// Check if using auto meal type detection
  bool get isAutoMealType => defaultMealType == 'auto';

  /// Get suggested meal type based on current time
  String get suggestedMealType {
    if (!isAutoMealType) return defaultMealType;

    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    if (hour >= 18 && hour < 22) return 'dinner';
    return 'snack'; // Late night
  }
}

// ============================================
// Meal Templates
// ============================================

/// A food item within a meal template
@JsonSerializable()
class TemplateFoodItem {
  final String name;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  @JsonKey(name: 'sodium_mg')
  final double? sodiumMg;
  final String? amount;
  final String? unit;

  const TemplateFoodItem({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sodiumMg,
    this.amount,
    this.unit,
  });

  factory TemplateFoodItem.fromJson(Map<String, dynamic> json) =>
      _$TemplateFoodItemFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateFoodItemToJson(this);

  TemplateFoodItem copyWith({
    String? name,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? sodiumMg,
    String? amount,
    String? unit,
  }) {
    return TemplateFoodItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}

/// A saved meal template for quick logging
@JsonSerializable()
class MealTemplate {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String name;
  @JsonKey(name: 'meal_type')
  final String mealType;
  @JsonKey(name: 'food_items')
  final List<TemplateFoodItem> foodItems;
  @JsonKey(name: 'total_calories')
  final int? totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double? totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double? totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double? totalFatG;
  @JsonKey(name: 'is_system_template')
  final bool isSystemTemplate;
  @JsonKey(name: 'use_count')
  final int useCount;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  final String? description;
  final List<String>? tags;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  const MealTemplate({
    this.id,
    this.userId,
    required this.name,
    required this.mealType,
    this.foodItems = const [],
    this.totalCalories,
    this.totalProteinG,
    this.totalCarbsG,
    this.totalFatG,
    this.isSystemTemplate = false,
    this.useCount = 0,
    this.lastUsedAt,
    this.createdAt,
    this.description,
    this.tags,
    this.imageUrl,
  });

  factory MealTemplate.fromJson(Map<String, dynamic> json) =>
      _$MealTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$MealTemplateToJson(this);

  MealTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? mealType,
    List<TemplateFoodItem>? foodItems,
    int? totalCalories,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    bool? isSystemTemplate,
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    String? description,
    List<String>? tags,
    String? imageUrl,
  }) {
    return MealTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      foodItems: foodItems ?? this.foodItems,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Calculate total calories from food items if not set
  int get calculatedCalories =>
      totalCalories ??
      foodItems.fold(0, (sum, item) => sum + item.calories);

  /// Calculate total protein from food items if not set
  double get calculatedProtein =>
      totalProteinG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.proteinG ?? 0));

  /// Calculate total carbs from food items if not set
  double get calculatedCarbs =>
      totalCarbsG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.carbsG ?? 0));

  /// Calculate total fat from food items if not set
  double get calculatedFat =>
      totalFatG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.fatG ?? 0));

  /// Check if this is a user-created template
  bool get isUserTemplate => !isSystemTemplate;

  /// Get display name with meal type emoji
  String get displayName {
    final emoji = _mealTypeEmoji;
    return '$emoji $name';
  }

  String get _mealTypeEmoji {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}

// ============================================
// Quick Suggestions
// ============================================

/// A quick food suggestion based on user history and time of day
@JsonSerializable()
class QuickSuggestion {
  @JsonKey(name: 'food_name')
  final String foodName;
  @JsonKey(name: 'meal_type')
  final String mealType;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'log_count')
  final int logCount;
  @JsonKey(name: 'time_of_day_bucket')
  final String? timeOfDayBucket;
  @JsonKey(name: 'saved_food_id')
  final String? savedFoodId;
  @JsonKey(name: 'template_id')
  final String? templateId;
  @JsonKey(name: 'last_logged_at')
  final DateTime? lastLoggedAt;
  @JsonKey(name: 'avg_servings')
  final double? avgServings;
  final String? description;

  const QuickSuggestion({
    required this.foodName,
    required this.mealType,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.logCount = 0,
    this.timeOfDayBucket,
    this.savedFoodId,
    this.templateId,
    this.lastLoggedAt,
    this.avgServings,
    this.description,
  });

  factory QuickSuggestion.fromJson(Map<String, dynamic> json) =>
      _$QuickSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuickSuggestionToJson(this);

  /// Check if this is a frequently logged item
  bool get isFrequent => logCount >= 3;

  /// Check if this is a recent item
  bool get isRecent {
    if (lastLoggedAt == null) return false;
    final daysSinceLog = DateTime.now().difference(lastLoggedAt!).inDays;
    return daysSinceLog <= 7;
  }

  /// Get relevance score for sorting (higher = more relevant)
  double get relevanceScore {
    double score = 0;

    // Frequency bonus
    score += logCount.clamp(0, 10) * 2;

    // Recency bonus
    if (lastLoggedAt != null) {
      final daysSinceLog = DateTime.now().difference(lastLoggedAt!).inDays;
      if (daysSinceLog <= 1) {
        score += 20;
      } else if (daysSinceLog <= 3) {
        score += 15;
      } else if (daysSinceLog <= 7) {
        score += 10;
      } else if (daysSinceLog <= 14) {
        score += 5;
      }
    }

    // Time of day match bonus
    final currentBucket = _getCurrentTimeOfDayBucket();
    if (timeOfDayBucket == currentBucket) {
      score += 15;
    }

    return score;
  }

  static String _getCurrentTimeOfDayBucket() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 15) return 'midday';
    if (hour >= 15 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  /// Get display subtitle
  String get subtitle {
    final parts = <String>[];
    parts.add('$calories cal');
    if (proteinG != null) parts.add('${proteinG!.round()}g protein');
    return parts.join(' | ');
  }

  /// Check if this suggestion is from a template
  bool get isFromTemplate => templateId != null;

  /// Check if this suggestion is from a saved food
  bool get isFromSavedFood => savedFoodId != null;
}

// ============================================
// Food Search Result
// ============================================

/// Food search result for the search functionality
@JsonSerializable()
class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  @JsonKey(name: 'serving_size')
  final String? servingSize;
  @JsonKey(name: 'serving_unit')
  final String? servingUnit;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  final String? barcode;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'source_type')
  final String? sourceType;
  @JsonKey(name: 'is_verified')
  final bool isVerified;

  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.servingSize,
    this.servingUnit,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.barcode,
    this.imageUrl,
    this.sourceType,
    this.isVerified = false,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) =>
      _$FoodSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchResultToJson(this);

  /// Get display name with brand if available
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$name ($brand)';
    }
    return name;
  }

  /// Get serving info string
  String get servingInfo {
    if (servingSize != null && servingUnit != null) {
      return '$servingSize $servingUnit';
    }
    if (servingSize != null) return servingSize!;
    return '1 serving';
  }

  /// Get macro summary string
  String get macroSummary {
    final parts = <String>[];
    if (proteinG != null) parts.add('P: ${proteinG!.round()}g');
    if (carbsG != null) parts.add('C: ${carbsG!.round()}g');
    if (fatG != null) parts.add('F: ${fatG!.round()}g');
    return parts.join(' | ');
  }
}
