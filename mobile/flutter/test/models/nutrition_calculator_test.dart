import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/models/nutrition_preferences.dart';

void main() {
  group('NutritionCalculator', () {
    group('calculateBmr', () {
      test('should calculate BMR for male using Mifflin-St Jeor', () {
        // Formula: BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
        // For 80kg, 180cm, 30yo male:
        // BMR = (10 × 80) + (6.25 × 180) − (5 × 30) + 5
        // BMR = 800 + 1125 - 150 + 5 = 1780

        final bmr = NutritionCalculator.calculateBmr(
          weightKg: 80,
          heightCm: 180,
          age: 30,
          gender: 'male',
        );

        expect(bmr, closeTo(1780, 10));
      });

      test('should calculate BMR for female using Mifflin-St Jeor', () {
        // Formula: BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
        // For 60kg, 165cm, 25yo female:
        // BMR = (10 × 60) + (6.25 × 165) − (5 × 25) − 161
        // BMR = 600 + 1031.25 - 125 - 161 = 1345.25

        final bmr = NutritionCalculator.calculateBmr(
          weightKg: 60,
          heightCm: 165,
          age: 25,
          gender: 'female',
        );

        expect(bmr, closeTo(1345, 10));
      });

      test('should handle non-binary gender as female calculation', () {
        final bmr = NutritionCalculator.calculateBmr(
          weightKg: 70,
          heightCm: 170,
          age: 30,
          gender: 'other',
        );

        // Should use female formula (more conservative)
        expect(bmr, greaterThan(1300));
        expect(bmr, lessThan(1600));
      });
    });

    group('calculateTdee', () {
      const baseBmr = 1800;

      test('should calculate TDEE for sedentary activity level', () {
        final tdee = NutritionCalculator.calculateTdee(baseBmr, 'sedentary');

        expect(tdee, closeTo(baseBmr * 1.2, 10)); // 2160
      });

      test('should calculate TDEE for lightly active', () {
        final tdee =
            NutritionCalculator.calculateTdee(baseBmr, 'lightly_active');

        expect(tdee, closeTo(baseBmr * 1.375, 10)); // 2475
      });

      test('should calculate TDEE for moderately active', () {
        final tdee =
            NutritionCalculator.calculateTdee(baseBmr, 'moderately_active');

        expect(tdee, closeTo(baseBmr * 1.55, 10)); // 2790
      });

      test('should calculate TDEE for very active', () {
        final tdee = NutritionCalculator.calculateTdee(baseBmr, 'very_active');

        expect(tdee, closeTo(baseBmr * 1.725, 10)); // 3105
      });

      test('should calculate TDEE for extra active', () {
        final tdee = NutritionCalculator.calculateTdee(baseBmr, 'extra_active');

        expect(tdee, closeTo(baseBmr * 1.9, 10)); // 3420
      });

      test('should default to sedentary for unknown activity level', () {
        final tdee = NutritionCalculator.calculateTdee(baseBmr, 'unknown');

        expect(tdee, closeTo(baseBmr * 1.2, 10)); // Default multiplier
      });
    });

    group('calculateMacros', () {
      test('should calculate balanced macros correctly', () {
        final macros = NutritionCalculator.calculateMacros(
          calories: 2000,
          dietType: DietType.balanced,
        );

        // Balanced is 45/25/30 (carbs/protein/fat)
        final carbsCal = macros.carbs * 4;
        final proteinCal = macros.protein * 4;
        final fatCal = macros.fat * 9;

        final totalCal = carbsCal + proteinCal + fatCal;
        expect(totalCal, closeTo(2000, 50));

        // Check percentages
        expect(macros.protein, closeTo((2000 * 0.25) / 4, 5)); // 25% protein
        expect(macros.carbs, closeTo((2000 * 0.45) / 4, 5)); // 45% carbs
        expect(macros.fat, closeTo((2000 * 0.30) / 9, 5)); // 30% fat
      });

      test('should calculate keto macros with low carbs', () {
        final macros = NutritionCalculator.calculateMacros(
          calories: 2000,
          dietType: DietType.keto,
        );

        // Keto: 5% carbs, 25% protein, 70% fat
        expect(macros.carbs, lessThan(50)); // Very low carbs
        expect(macros.fat, greaterThan(140)); // High fat
      });

      test('should calculate low carb macros', () {
        final macros = NutritionCalculator.calculateMacros(
          calories: 2000,
          dietType: DietType.lowCarb,
        );

        // Low carb: 25% carbs
        expect(macros.carbs, lessThan(150));
        expect(macros.carbs, greaterThan(50));
      });

      test('should calculate high protein macros', () {
        final macros = NutritionCalculator.calculateMacros(
          calories: 2500,
          dietType: DietType.highProtein,
        );

        // High protein: 40% protein
        expect(macros.protein, greaterThanOrEqualTo(200)); // ~250g at 40%
      });

      test('should use custom percentages when diet type is custom', () {
        final macros = NutritionCalculator.calculateMacros(
          calories: 2000,
          dietType: DietType.custom,
          customCarbPercent: 40,
          customProteinPercent: 35,
          customFatPercent: 25,
        );

        // Custom: 40/35/25 (carbs/protein/fat)
        expect(macros.protein, closeTo((2000 * 0.35) / 4, 5)); // 35% protein
        expect(macros.carbs, closeTo((2000 * 0.40) / 4, 5)); // 40% carbs
        expect(macros.fat, closeTo((2000 * 0.25) / 9, 5)); // 25% fat
      });
    });

    group('calculateSafeTarget', () {
      const baseTdee = 2500;

      test('should return TDEE with no adjustment for maintenance', () {
        final result = NutritionCalculator.calculateSafeTarget(
          tdee: baseTdee,
          gender: 'male',
          goal: NutritionGoal.maintain,
          rate: RateOfChange.moderate,
        );

        expect(result.calories, baseTdee);
        expect(result.wasAdjusted, false);
        expect(result.adjustmentReason, isNull);
      });

      test('should create deficit for fat loss', () {
        final result = NutritionCalculator.calculateSafeTarget(
          tdee: baseTdee,
          gender: 'male',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.moderate,
        );

        expect(result.calories, lessThan(baseTdee));
        expect(result.calories, closeTo(baseTdee - 500, 100)); // ~500 cal deficit
      });

      test('should create surplus for muscle gain', () {
        final result = NutritionCalculator.calculateSafeTarget(
          tdee: baseTdee,
          gender: 'male',
          goal: NutritionGoal.buildMuscle,
          rate: RateOfChange.moderate,
        );

        expect(result.calories, greaterThan(baseTdee));
        // Surplus is rate.calorieAdjustment / 2 = 500 / 2 = 250
        expect(result.calories, closeTo(baseTdee + 250, 50));
      });

      test('should respect minimum calories for females', () {
        final result = NutritionCalculator.calculateSafeTarget(
          tdee: 1400, // Low TDEE
          gender: 'female',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.aggressive,
        );

        expect(result.calories, greaterThanOrEqualTo(1200)); // Never below 1200 for women
        expect(result.wasAdjusted, true);
        expect(result.adjustmentReason, isNotNull);
      });

      test('should respect minimum calories for males', () {
        final result = NutritionCalculator.calculateSafeTarget(
          tdee: 1800, // Low TDEE
          gender: 'male',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.aggressive,
        );

        expect(result.calories, greaterThanOrEqualTo(1500)); // Never below 1500 for men
      });

      test('should use slow rate of change correctly', () {
        final slowResult = NutritionCalculator.calculateSafeTarget(
          tdee: baseTdee,
          gender: 'male',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.slow,
        );

        final moderateResult = NutritionCalculator.calculateSafeTarget(
          tdee: baseTdee,
          gender: 'male',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.moderate,
        );

        // Slow rate should have smaller deficit (more calories)
        expect(slowResult.calories, greaterThan(moderateResult.calories));
      });
    });

    group('calculateTargets (integration)', () {
      test('should calculate complete nutrition preferences', () {
        final prefs = NutritionCalculator.calculateTargets(
          userId: 'test-user',
          weightKg: 75,
          heightCm: 175,
          age: 30,
          gender: 'male',
          activityLevel: 'moderately_active',
          goal: NutritionGoal.maintain,
          rate: RateOfChange.moderate,
          dietType: DietType.balanced,
        );

        expect(prefs.userId, 'test-user');
        expect(prefs.calculatedBmr, greaterThan(1500));
        expect(prefs.calculatedTdee, greaterThan(prefs.calculatedBmr!));
        expect(prefs.targetCalories, greaterThan(0));
        expect(prefs.targetProteinG, greaterThan(0));
        expect(prefs.targetCarbsG, greaterThan(0));
        expect(prefs.targetFatG, greaterThan(0));
      });

      test('should handle fat loss goal correctly', () {
        final prefs = NutritionCalculator.calculateTargets(
          userId: 'test-user',
          weightKg: 80,
          heightCm: 180,
          age: 35,
          gender: 'male',
          activityLevel: 'sedentary',
          goal: NutritionGoal.loseFat,
          rate: RateOfChange.moderate,
          dietType: DietType.highProtein,
        );

        // Should have calorie deficit
        expect(prefs.targetCalories, lessThan(prefs.calculatedTdee!));
        // High protein diet
        expect(prefs.dietType, 'high_protein');
      });
    });
  });

  group('NutritionGoal', () {
    test('should have correct values', () {
      expect(NutritionGoal.loseFat.value, 'lose_fat');
      expect(NutritionGoal.buildMuscle.value, 'build_muscle');
      expect(NutritionGoal.maintain.value, 'maintain');
      expect(NutritionGoal.improveEnergy.value, 'improve_energy');
      expect(NutritionGoal.eatHealthier.value, 'eat_healthier');
      expect(NutritionGoal.recomposition.value, 'recomposition');
    });

    test('should have correct calorie adjustments', () {
      expect(NutritionGoal.loseFat.calorieAdjustment, -500);
      expect(NutritionGoal.buildMuscle.calorieAdjustment, 300);
      expect(NutritionGoal.maintain.calorieAdjustment, 0);
      expect(NutritionGoal.recomposition.calorieAdjustment, -200);
    });

    test('should parse from string correctly', () {
      expect(NutritionGoal.fromString('lose_fat'), NutritionGoal.loseFat);
      expect(NutritionGoal.fromString('loseFat'), NutritionGoal.loseFat);
      expect(NutritionGoal.fromString('unknown'), NutritionGoal.maintain);
    });
  });

  group('DietType', () {
    test('should have correct values', () {
      expect(DietType.balanced.value, 'balanced');
      expect(DietType.lowCarb.value, 'low_carb');
      expect(DietType.keto.value, 'keto');
      expect(DietType.highProtein.value, 'high_protein');
      expect(DietType.vegetarian.value, 'vegetarian');
      expect(DietType.vegan.value, 'vegan');
      expect(DietType.mediterranean.value, 'mediterranean');
    });

    test('should have correct macro percentages', () {
      // Balanced: 45/25/30
      expect(DietType.balanced.carbPercent, 45);
      expect(DietType.balanced.proteinPercent, 25);
      expect(DietType.balanced.fatPercent, 30);

      // Keto: 5/25/70
      expect(DietType.keto.carbPercent, 5);
      expect(DietType.keto.proteinPercent, 25);
      expect(DietType.keto.fatPercent, 70);
    });
  });

  group('RateOfChange', () {
    test('should have correct values', () {
      expect(RateOfChange.slow.value, 'slow');
      expect(RateOfChange.moderate.value, 'moderate');
      expect(RateOfChange.aggressive.value, 'aggressive');
    });

    test('should have correct calorie adjustments', () {
      expect(RateOfChange.slow.calorieAdjustment, 250);
      expect(RateOfChange.moderate.calorieAdjustment, 500);
      expect(RateOfChange.aggressive.calorieAdjustment, 750);
    });

    test('should have correct kg per week targets', () {
      expect(RateOfChange.slow.kgPerWeek, 0.25);
      expect(RateOfChange.moderate.kgPerWeek, 0.5);
      expect(RateOfChange.aggressive.kgPerWeek, 0.75);
    });
  });
}
