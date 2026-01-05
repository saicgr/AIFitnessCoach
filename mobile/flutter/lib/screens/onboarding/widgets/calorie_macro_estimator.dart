/// Comprehensive nutrition estimate containing all calculated metrics
class NutritionEstimate {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double waterLiters;
  final DateTime? goalDate;
  final int? weeksToGoal;
  final int metabolicAge;
  final int maxSafeDeficit;
  final double leanMass;
  final double fatMass;
  final double bodyFatPercent;
  final double proteinPerKg;
  final double idealWeightMin;
  final double idealWeightMax;
  final int bmr;
  final int tdee;

  const NutritionEstimate({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterLiters,
    this.goalDate,
    this.weeksToGoal,
    required this.metabolicAge,
    required this.maxSafeDeficit,
    required this.leanMass,
    required this.fatMass,
    required this.bodyFatPercent,
    required this.proteinPerKg,
    required this.idealWeightMin,
    required this.idealWeightMax,
    required this.bmr,
    required this.tdee,
  });

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'water_liters': waterLiters,
    'goal_date': goalDate?.toIso8601String(),
    'weeks_to_goal': weeksToGoal,
    'metabolic_age': metabolicAge,
    'max_safe_deficit': maxSafeDeficit,
    'lean_mass': leanMass,
    'fat_mass': fatMass,
    'body_fat_percent': bodyFatPercent,
    'protein_per_kg': proteinPerKg,
    'ideal_weight_min': idealWeightMin,
    'ideal_weight_max': idealWeightMax,
    'bmr': bmr,
    'tdee': tdee,
  };
}

/// Calculator for nutrition metrics including calories, macros, and differentiating metrics.
/// Uses science-backed formulas like Mifflin-St Jeor for BMR.
class CalorieMacroEstimator {
  // Activity level multipliers for TDEE calculation
  static const Map<String, double> _activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
    'extremely_active': 1.9,
  };

  // Goal adjustments (calories per day)
  static const Map<String, Map<String, int>> _goalAdjustments = {
    'lose': {
      'slow': -250,
      'moderate': -500,
      'fast': -750,
      'aggressive': -1000,
    },
    'gain': {
      'slow': 250,
      'moderate': 375,
      'fast': 500,
    },
    'maintain': {
      'slow': 0,
      'moderate': 0,
      'fast': 0,
    },
  };

  // Macro distribution by primary nutrition goal (protein%, carbs%, fat%)
  static const Map<String, List<int>> _macroDistribution = {
    'lose_fat': [35, 30, 35],
    'build_muscle': [30, 45, 25],
    'maintain': [25, 45, 30],
    'improve_energy': [25, 50, 25],
    'eat_healthier': [25, 45, 30],
    'recomposition': [35, 35, 30],
  };

  // Protein per kg by goal
  static const Map<String, double> _proteinPerKgByGoal = {
    'lose_fat': 2.0,
    'build_muscle': 1.8,
    'maintain': 1.6,
    'improve_energy': 1.4,
    'eat_healthier': 1.4,
    'recomposition': 2.2,
  };

  // Average BMR by age for metabolic age calculation (combined male/female average)
  static const Map<int, int> _averageBmrByAge = {
    18: 1680, 20: 1660, 25: 1620, 30: 1580, 35: 1540,
    40: 1500, 45: 1460, 50: 1420, 55: 1380, 60: 1340,
    65: 1300, 70: 1260, 75: 1220, 80: 1180,
  };

  /// Calculate BMR using Mifflin-St Jeor equation (most accurate)
  /// Males:   BMR = (10 × weight) + (6.25 × height) − (5 × age) + 5
  /// Females: BMR = (10 × weight) + (6.25 × height) − (5 × age) − 161
  static int calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final adjustment = gender.toLowerCase() == 'male' ? 5 : -161;
    return (base + adjustment).round();
  }

  /// Calculate TDEE from BMR and activity level
  static int calculateTDEE(int bmr, String? activityLevel) {
    final multiplier = _activityMultipliers[activityLevel] ?? 1.375; // default to lightly active
    return (bmr * multiplier).round();
  }

  /// Calculate target calories based on TDEE and goals
  static int calculateTargetCalories({
    required int tdee,
    required String gender,
    required String? weightDirection,
    required String? weightChangeRate,
  }) {
    final direction = weightDirection ?? 'maintain';
    final rate = weightChangeRate ?? 'moderate';

    final adjustment = _goalAdjustments[direction]?[rate] ?? 0;
    final target = tdee + adjustment;

    // Apply safety minimums
    final minimum = gender.toLowerCase() == 'male' ? 1500 : 1200;
    final maximum = 4000;

    return target.clamp(minimum, maximum);
  }

  /// Calculate macros based on calories and nutrition goals
  static Map<String, int> calculateMacros({
    required int calories,
    required List<String>? nutritionGoals,
    required double weightKg,
  }) {
    // Get macro distribution based on primary goal
    final primaryGoal = nutritionGoals?.isNotEmpty == true
        ? nutritionGoals!.first
        : 'maintain';
    final distribution = _macroDistribution[primaryGoal] ?? [25, 45, 30];

    final proteinPercent = distribution[0];
    final carbsPercent = distribution[1];
    final fatPercent = distribution[2];

    // Calculate grams (protein & carbs = 4 cal/g, fat = 9 cal/g)
    final protein = ((calories * proteinPercent / 100) / 4).round();
    final carbs = ((calories * carbsPercent / 100) / 4).round();
    final fat = ((calories * fatPercent / 100) / 9).round();

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Calculate goal date based on weight difference and rate
  static DateTime? calculateGoalDate({
    required double currentWeight,
    required double? goalWeight,
    required String? weightDirection,
    required String? weightChangeRate,
  }) {
    if (goalWeight == null || weightDirection == 'maintain') return null;

    final weightDiff = (currentWeight - goalWeight).abs();
    if (weightDiff < 0.1) return null; // Already at goal

    final weeklyRate = _getWeeklyRateKg(weightDirection, weightChangeRate);
    final weeks = (weightDiff / weeklyRate).ceil();

    return DateTime.now().add(Duration(days: weeks * 7));
  }

  /// Calculate weeks to goal
  static int? calculateWeeksToGoal({
    required double currentWeight,
    required double? goalWeight,
    required String? weightDirection,
    required String? weightChangeRate,
  }) {
    if (goalWeight == null || weightDirection == 'maintain') return null;

    final weightDiff = (currentWeight - goalWeight).abs();
    if (weightDiff < 0.1) return null;

    final weeklyRate = _getWeeklyRateKg(weightDirection, weightChangeRate);
    return (weightDiff / weeklyRate).ceil();
  }

  /// Get weekly rate in kg based on direction and rate selection
  static double _getWeeklyRateKg(String? direction, String? rate) {
    if (direction == 'lose') {
      switch (rate) {
        case 'slow': return 0.25;
        case 'moderate': return 0.5;
        case 'fast': return 0.75;
        case 'aggressive': return 1.0;
        default: return 0.5;
      }
    } else if (direction == 'gain') {
      switch (rate) {
        case 'slow': return 0.25;
        case 'moderate': return 0.35;
        case 'fast': return 0.5;
        default: return 0.35;
      }
    }
    return 0.5;
  }

  /// Calculate daily water intake in liters
  /// Formula: 33ml per kg body weight + activity bonus
  static double calculateWaterIntake({
    required double weightKg,
    required int? workoutDaysPerWeek,
  }) {
    final baseWater = weightKg * 0.033;
    final activityBonus = (workoutDaysPerWeek ?? 3) * 0.5 / 7; // Average daily bonus
    return double.parse((baseWater + activityBonus).toStringAsFixed(1));
  }

  /// Calculate metabolic age by comparing user's BMR to population averages
  static int calculateMetabolicAge({
    required int userBMR,
    required int chronologicalAge,
    required String gender,
  }) {
    // Get average BMR for user's age
    final ageKey = _averageBmrByAge.keys.reduce((a, b) =>
        (chronologicalAge - a).abs() < (chronologicalAge - b).abs() ? a : b);
    final averageBMR = _averageBmrByAge[ageKey]!;

    // Adjust average for gender
    final genderAdjustedAverage = gender.toLowerCase() == 'male'
        ? averageBMR * 1.1
        : averageBMR * 0.9;

    // Calculate metabolic age
    // Higher BMR = younger metabolic age
    final ratio = genderAdjustedAverage / userBMR;
    final metabolicAge = (chronologicalAge * ratio).round();

    // Clamp to reasonable range
    return metabolicAge.clamp(15, 90);
  }

  /// Calculate body fat percentage estimate from BMI
  /// Men: BF% = 1.20 × BMI + 0.23 × Age - 16.2
  /// Women: BF% = 1.20 × BMI + 0.23 × Age - 5.4
  static double calculateBodyFatPercent({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    final genderConstant = gender.toLowerCase() == 'male' ? -16.2 : -5.4;
    final bodyFat = (1.20 * bmi) + (0.23 * age) + genderConstant;

    // Clamp to reasonable range
    return double.parse(bodyFat.clamp(5.0, 50.0).toStringAsFixed(1));
  }

  /// Calculate body composition (lean mass and fat mass)
  static Map<String, double> calculateBodyComposition({
    required double weightKg,
    required double bodyFatPercent,
  }) {
    final fatMass = weightKg * (bodyFatPercent / 100);
    final leanMass = weightKg - fatMass;

    return {
      'fatMass': double.parse(fatMass.toStringAsFixed(1)),
      'leanMass': double.parse(leanMass.toStringAsFixed(1)),
    };
  }

  /// Calculate maximum safe calorie deficit (Maximum Fat Metabolism)
  /// MFM = 31.4 × Fat Mass (kg)
  static int calculateMaxSafeDeficit({
    required double fatMassKg,
  }) {
    final mfm = (31.4 * fatMassKg).round();
    // Cap at reasonable limits
    return mfm.clamp(250, 1500);
  }

  /// Get recommended protein per kg based on goals
  static double calculateProteinPerKg({
    required List<String>? nutritionGoals,
  }) {
    final primaryGoal = nutritionGoals?.isNotEmpty == true
        ? nutritionGoals!.first
        : 'maintain';
    return _proteinPerKgByGoal[primaryGoal] ?? 1.6;
  }

  /// Calculate ideal weight range based on height using BMI 18.5-24.9
  static Map<String, double> calculateIdealWeightRange({
    required double heightCm,
    required String gender,
  }) {
    final heightM = heightCm / 100;

    // BMI-based range (18.5 - 24.9)
    final minWeight = 18.5 * heightM * heightM;
    final maxWeight = 24.9 * heightM * heightM;

    return {
      'min': double.parse(minWeight.toStringAsFixed(1)),
      'max': double.parse(maxWeight.toStringAsFixed(1)),
    };
  }

  /// Calculate all nutrition metrics at once
  static NutritionEstimate calculateAll({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String? activityLevel,
    required String? weightDirection,
    required String? weightChangeRate,
    required double? goalWeightKg,
    required List<String>? nutritionGoals,
    required int? workoutDaysPerWeek,
  }) {
    // Core calculations
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final tdee = calculateTDEE(bmr, activityLevel);

    final calories = calculateTargetCalories(
      tdee: tdee,
      gender: gender,
      weightDirection: weightDirection,
      weightChangeRate: weightChangeRate,
    );

    final macros = calculateMacros(
      calories: calories,
      nutritionGoals: nutritionGoals,
      weightKg: weightKg,
    );

    // Body composition
    final bodyFatPercent = calculateBodyFatPercent(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final bodyComp = calculateBodyComposition(
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
    );

    // Differentiating metrics
    final goalDate = calculateGoalDate(
      currentWeight: weightKg,
      goalWeight: goalWeightKg,
      weightDirection: weightDirection,
      weightChangeRate: weightChangeRate,
    );

    final weeksToGoal = calculateWeeksToGoal(
      currentWeight: weightKg,
      goalWeight: goalWeightKg,
      weightDirection: weightDirection,
      weightChangeRate: weightChangeRate,
    );

    final waterLiters = calculateWaterIntake(
      weightKg: weightKg,
      workoutDaysPerWeek: workoutDaysPerWeek,
    );

    final metabolicAge = calculateMetabolicAge(
      userBMR: bmr,
      chronologicalAge: age,
      gender: gender,
    );

    final maxSafeDeficit = calculateMaxSafeDeficit(
      fatMassKg: bodyComp['fatMass']!,
    );

    final proteinPerKg = calculateProteinPerKg(
      nutritionGoals: nutritionGoals,
    );

    final idealWeight = calculateIdealWeightRange(
      heightCm: heightCm,
      gender: gender,
    );

    return NutritionEstimate(
      calories: calories,
      protein: macros['protein']!,
      carbs: macros['carbs']!,
      fat: macros['fat']!,
      waterLiters: waterLiters,
      goalDate: goalDate,
      weeksToGoal: weeksToGoal,
      metabolicAge: metabolicAge,
      maxSafeDeficit: maxSafeDeficit,
      leanMass: bodyComp['leanMass']!,
      fatMass: bodyComp['fatMass']!,
      bodyFatPercent: bodyFatPercent,
      proteinPerKg: proteinPerKg,
      idealWeightMin: idealWeight['min']!,
      idealWeightMax: idealWeight['max']!,
      bmr: bmr,
      tdee: tdee,
    );
  }
}
