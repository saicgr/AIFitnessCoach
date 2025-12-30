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
  balanced('balanced', 'Balanced', 45, 25, 30),
  lowCarb('low_carb', 'Low Carb', 25, 35, 40),
  keto('keto', 'Keto', 5, 25, 70),
  highProtein('high_protein', 'High Protein', 35, 40, 25),
  vegetarian('vegetarian', 'Vegetarian', 50, 20, 30),
  vegan('vegan', 'Vegan', 55, 20, 25),
  mediterranean('mediterranean', 'Mediterranean', 45, 20, 35),
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
  if168('if_16_8', 'Intermittent Fasting (16:8)', 2),
  if186('if_18_6', 'Intermittent Fasting (18:6)', 2),
  smallMeals('5_6_small_meals', '5-6 Small Meals', 6);

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

/// Nutrition preferences for a user
@JsonSerializable()
class NutritionPreferences {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;

  // Goal settings
  @JsonKey(name: 'nutrition_goal')
  final String nutritionGoal;
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

  const NutritionPreferences({
    this.id,
    required this.userId,
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
    this.showAiFeedbackAfterLogging = true,
    this.calmModeEnabled = false,
    this.showWeeklyInsteadOfDaily = false,
    this.adjustCaloriesForTraining = true,
    this.adjustCaloriesForRest = false,
    this.nutritionOnboardingCompleted = false,
    this.onboardingCompletedAt,
    this.lastRecalculatedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Get nutrition goal enum
  NutritionGoal get nutritionGoalEnum => NutritionGoal.fromString(nutritionGoal);

  /// Get diet type enum
  DietType get dietTypeEnum => DietType.fromString(dietType);

  /// Get meal pattern enum
  MealPattern get mealPatternEnum => MealPattern.fromString(mealPattern);

  /// Check if using intermittent fasting pattern
  bool get isIntermittentFasting =>
      mealPattern == 'if_16_8' || mealPattern == 'if_18_6';

  factory NutritionPreferences.fromJson(Map<String, dynamic> json) =>
      _$NutritionPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionPreferencesToJson(this);

  NutritionPreferences copyWith({
    String? id,
    String? userId,
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
    bool? showAiFeedbackAfterLogging,
    bool? calmModeEnabled,
    bool? showWeeklyInsteadOfDaily,
    bool? adjustCaloriesForTraining,
    bool? adjustCaloriesForRest,
    bool? nutritionOnboardingCompleted,
    DateTime? onboardingCompletedAt,
    DateTime? lastRecalculatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      showAiFeedbackAfterLogging:
          showAiFeedbackAfterLogging ?? this.showAiFeedbackAfterLogging,
      calmModeEnabled: calmModeEnabled ?? this.calmModeEnabled,
      showWeeklyInsteadOfDaily:
          showWeeklyInsteadOfDaily ?? this.showWeeklyInsteadOfDaily,
      adjustCaloriesForTraining:
          adjustCaloriesForTraining ?? this.adjustCaloriesForTraining,
      adjustCaloriesForRest:
          adjustCaloriesForRest ?? this.adjustCaloriesForRest,
      nutritionOnboardingCompleted:
          nutritionOnboardingCompleted ?? this.nutritionOnboardingCompleted,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      lastRecalculatedAt: lastRecalculatedAt ?? this.lastRecalculatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  static NutritionPreferences calculateTargets({
    required String userId,
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required NutritionGoal goal,
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

    return NutritionPreferences(
      userId: userId,
      nutritionGoal: goal.value,
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
