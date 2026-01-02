import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/nutrition.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('FoodItem', () {
    group('fromJson', () {
      test('should create FoodItem from valid JSON', () {
        final json = JsonFixtures.foodItemJson();
        final item = FoodItem.fromJson(json);

        expect(item.name, 'Chicken Breast');
        expect(item.amount, '200g');
        expect(item.calories, 330);
        expect(item.proteinG, 62.0);
        expect(item.carbsG, 0.0);
        expect(item.fatG, 7.0);
      });

      test('should handle minimal required fields', () {
        final json = {'name': 'Apple'};
        final item = FoodItem.fromJson(json);

        expect(item.name, 'Apple');
        expect(item.amount, isNull);
        expect(item.calories, isNull);
        expect(item.proteinG, isNull);
        expect(item.carbsG, isNull);
        expect(item.fatG, isNull);
      });
    });

    group('toJson', () {
      test('should serialize FoodItem to JSON', () {
        final item = TestFixtures.createFoodItem(
          name: 'Salmon',
          amount: '150g',
          calories: 280,
          proteinG: 30.0,
          carbsG: 0.0,
          fatG: 17.0,
        );
        final json = item.toJson();

        expect(json['name'], 'Salmon');
        expect(json['amount'], '150g');
        expect(json['calories'], 280);
        expect(json['protein_g'], 30.0);
        expect(json['carbs_g'], 0.0);
        expect(json['fat_g'], 17.0);
      });
    });
  });

  group('FoodLog', () {
    test('should create from JSON', () {
      final json = {
        'id': 'log-id',
        'user_id': 'user-id',
        'meal_type': 'lunch',
        'logged_at': '2025-01-15T12:30:00Z',
        'food_items': [
          {'name': 'Chicken', 'calories': 200},
          {'name': 'Rice', 'calories': 150},
        ],
        'total_calories': 350,
        'protein_g': 40.0,
        'carbs_g': 30.0,
        'fat_g': 8.0,
        'fiber_g': 2.0,
        'health_score': 75,
        'ai_feedback': 'Good protein intake!',
        'created_at': '2025-01-15T12:30:00Z',
      };
      final log = FoodLog.fromJson(json);

      expect(log.id, 'log-id');
      expect(log.userId, 'user-id');
      expect(log.mealType, 'lunch');
      expect(log.loggedAt.year, 2025);
      expect(log.foodItems.length, 2);
      expect(log.foodItems[0].name, 'Chicken');
      expect(log.foodItems[1].name, 'Rice');
      expect(log.totalCalories, 350);
      expect(log.proteinG, 40.0);
      expect(log.carbsG, 30.0);
      expect(log.fatG, 8.0);
      expect(log.fiberG, 2.0);
      expect(log.healthScore, 75);
      expect(log.aiFeedback, 'Good protein intake!');
    });

    test('should use default values for missing optional fields', () {
      final json = {
        'id': 'log-id',
        'user_id': 'user-id',
        'meal_type': 'breakfast',
        'logged_at': '2025-01-15T08:00:00Z',
        'created_at': '2025-01-15T08:00:00Z',
      };
      final log = FoodLog.fromJson(json);

      expect(log.foodItems, isEmpty);
      expect(log.totalCalories, 0);
      expect(log.proteinG, 0);
      expect(log.carbsG, 0);
      expect(log.fatG, 0);
      expect(log.fiberG, isNull);
      expect(log.healthScore, isNull);
      expect(log.aiFeedback, isNull);
    });

    test('should serialize to JSON', () {
      final log = FoodLog(
        id: 'log-id',
        userId: 'user-id',
        mealType: 'dinner',
        loggedAt: DateTime(2025, 1, 15, 19, 0),
        foodItems: [
          const FoodItem(name: 'Steak', calories: 400),
        ],
        totalCalories: 400,
        proteinG: 50.0,
        carbsG: 0.0,
        fatG: 20.0,
        createdAt: DateTime(2025, 1, 15, 19, 0),
      );
      final json = log.toJson();

      expect(json['id'], 'log-id');
      expect(json['user_id'], 'user-id');
      expect(json['meal_type'], 'dinner');
      expect(json['total_calories'], 400);
      expect(json['protein_g'], 50.0);
      expect(json['food_items'], isNotEmpty);
    });
  });

  group('DailyNutritionSummary', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = JsonFixtures.dailyNutritionSummaryJson();
        final summary = DailyNutritionSummary.fromJson(json);

        expect(summary.date, isNotNull);
        expect(summary.totalCalories, 2000);
        expect(summary.totalProteinG, 150.0);
        expect(summary.totalCarbsG, 200.0);
        expect(summary.totalFatG, 67.0);
        expect(summary.totalFiberG, 25.0);
        expect(summary.mealCount, 3);
        expect(summary.avgHealthScore, 75.0);
        expect(summary.meals, isEmpty);
      });

      test('should use default values for missing fields', () {
        final json = {'date': '2025-01-15'};
        final summary = DailyNutritionSummary.fromJson(json);

        expect(summary.date, '2025-01-15');
        expect(summary.totalCalories, 0);
        expect(summary.totalProteinG, 0);
        expect(summary.totalCarbsG, 0);
        expect(summary.totalFatG, 0);
        expect(summary.totalFiberG, 0);
        expect(summary.mealCount, 0);
        expect(summary.avgHealthScore, isNull);
        expect(summary.meals, isEmpty);
      });

      test('should parse nested meals', () {
        final json = {
          'date': '2025-01-15',
          'total_calories': 1000,
          'total_protein_g': 80.0,
          'total_carbs_g': 100.0,
          'total_fat_g': 40.0,
          'total_fiber_g': 15.0,
          'meal_count': 2,
          'meals': [
            {
              'id': 'meal-1',
              'user_id': 'u-1',
              'meal_type': 'breakfast',
              'logged_at': '2025-01-15T08:00:00Z',
              'created_at': '2025-01-15T08:00:00Z',
              'total_calories': 500,
              'protein_g': 40.0,
              'carbs_g': 50.0,
              'fat_g': 20.0,
            },
            {
              'id': 'meal-2',
              'user_id': 'u-1',
              'meal_type': 'lunch',
              'logged_at': '2025-01-15T12:00:00Z',
              'created_at': '2025-01-15T12:00:00Z',
              'total_calories': 500,
              'protein_g': 40.0,
              'carbs_g': 50.0,
              'fat_g': 20.0,
            },
          ],
        };
        final summary = DailyNutritionSummary.fromJson(json);

        expect(summary.meals.length, 2);
        expect(summary.meals[0].mealType, 'breakfast');
        expect(summary.meals[1].mealType, 'lunch');
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        const summary = DailyNutritionSummary(
          date: '2025-01-15',
          totalCalories: 2500,
          totalProteinG: 180.0,
          totalCarbsG: 250.0,
          totalFatG: 80.0,
          totalFiberG: 30.0,
          mealCount: 4,
          avgHealthScore: 80.0,
        );
        final json = summary.toJson();

        expect(json['date'], '2025-01-15');
        expect(json['total_calories'], 2500);
        expect(json['total_protein_g'], 180.0);
        expect(json['total_carbs_g'], 250.0);
        expect(json['total_fat_g'], 80.0);
        expect(json['total_fiber_g'], 30.0);
        expect(json['meal_count'], 4);
        expect(json['avg_health_score'], 80.0);
      });
    });
  });

  group('NutritionTargets', () {
    test('should create from JSON', () {
      final json = {
        'user_id': 'user-id',
        'daily_calorie_target': 2500,
        'daily_protein_target_g': 180.0,
        'daily_carbs_target_g': 250.0,
        'daily_fat_target_g': 80.0,
      };
      final targets = NutritionTargets.fromJson(json);

      expect(targets.userId, 'user-id');
      expect(targets.dailyCalorieTarget, 2500);
      expect(targets.dailyProteinTargetG, 180.0);
      expect(targets.dailyCarbsTargetG, 250.0);
      expect(targets.dailyFatTargetG, 80.0);
    });

    test('should handle null optional targets', () {
      final json = {'user_id': 'user-id'};
      final targets = NutritionTargets.fromJson(json);

      expect(targets.userId, 'user-id');
      expect(targets.dailyCalorieTarget, isNull);
      expect(targets.dailyProteinTargetG, isNull);
      expect(targets.dailyCarbsTargetG, isNull);
      expect(targets.dailyFatTargetG, isNull);
    });

    test('should serialize to JSON', () {
      const targets = NutritionTargets(
        userId: 'user-id',
        dailyCalorieTarget: 2000,
        dailyProteinTargetG: 150.0,
        dailyCarbsTargetG: 200.0,
        dailyFatTargetG: 65.0,
      );
      final json = targets.toJson();

      expect(json['user_id'], 'user-id');
      expect(json['daily_calorie_target'], 2000);
      expect(json['daily_protein_target_g'], 150.0);
      expect(json['daily_carbs_target_g'], 200.0);
      expect(json['daily_fat_target_g'], 65.0);
    });
  });

  group('MealType', () {
    test('should have all expected values', () {
      expect(MealType.values.length, 4);
      expect(MealType.values, contains(MealType.breakfast));
      expect(MealType.values, contains(MealType.lunch));
      expect(MealType.values, contains(MealType.dinner));
      expect(MealType.values, contains(MealType.snack));
    });

    test('should have correct values, labels, and emojis', () {
      expect(MealType.breakfast.value, 'breakfast');
      expect(MealType.breakfast.label, 'Breakfast');
      expect(MealType.breakfast.emoji, isNotEmpty);

      expect(MealType.lunch.value, 'lunch');
      expect(MealType.lunch.label, 'Lunch');

      expect(MealType.dinner.value, 'dinner');
      expect(MealType.dinner.label, 'Dinner');

      expect(MealType.snack.value, 'snack');
      expect(MealType.snack.label, 'Snack');
    });

    group('fromValue', () {
      test('should return correct MealType for valid values', () {
        expect(MealType.fromValue('breakfast'), MealType.breakfast);
        expect(MealType.fromValue('lunch'), MealType.lunch);
        expect(MealType.fromValue('dinner'), MealType.dinner);
        expect(MealType.fromValue('snack'), MealType.snack);
      });

      test('should return snack for unknown values', () {
        expect(MealType.fromValue('unknown'), MealType.snack);
        expect(MealType.fromValue('brunch'), MealType.snack);
        expect(MealType.fromValue(''), MealType.snack);
      });
    });
  });
}
