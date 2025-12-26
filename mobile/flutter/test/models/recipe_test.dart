import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/models/recipe.dart';
import 'package:ai_fitness_coach/data/models/micronutrients.dart';

void main() {
  group('RecipeCategory', () {
    test('should have correct values and labels', () {
      expect(RecipeCategory.breakfast.value, 'breakfast');
      expect(RecipeCategory.breakfast.label, 'Breakfast');
      expect(RecipeCategory.breakfast.emoji, '🌅');

      expect(RecipeCategory.lunch.value, 'lunch');
      expect(RecipeCategory.lunch.label, 'Lunch');
      expect(RecipeCategory.lunch.emoji, '☀️');

      expect(RecipeCategory.dinner.value, 'dinner');
      expect(RecipeCategory.dinner.label, 'Dinner');
      expect(RecipeCategory.dinner.emoji, '🌙');

      expect(RecipeCategory.snack.value, 'snack');
      expect(RecipeCategory.snack.label, 'Snack');
      expect(RecipeCategory.snack.emoji, '🍎');
    });

    test('fromValue should return correct enum', () {
      expect(RecipeCategory.fromValue('breakfast'), RecipeCategory.breakfast);
      expect(RecipeCategory.fromValue('lunch'), RecipeCategory.lunch);
      expect(RecipeCategory.fromValue('dinner'), RecipeCategory.dinner);
      expect(RecipeCategory.fromValue('snack'), RecipeCategory.snack);
      expect(RecipeCategory.fromValue('dessert'), RecipeCategory.dessert);
      expect(RecipeCategory.fromValue('drink'), RecipeCategory.drink);
      expect(RecipeCategory.fromValue('other'), RecipeCategory.other);
    });

    test('fromValue should return other for unknown values', () {
      expect(RecipeCategory.fromValue('unknown'), RecipeCategory.other);
      expect(RecipeCategory.fromValue(null), RecipeCategory.other);
    });
  });

  group('RecipeSourceType', () {
    test('should have correct values', () {
      expect(RecipeSourceType.manual.value, 'manual');
      expect(RecipeSourceType.imported.value, 'imported');
      expect(RecipeSourceType.aiGenerated.value, 'ai_generated');
    });

    test('fromValue should return correct enum', () {
      expect(RecipeSourceType.fromValue('manual'), RecipeSourceType.manual);
      expect(RecipeSourceType.fromValue('imported'), RecipeSourceType.imported);
      expect(RecipeSourceType.fromValue('ai_generated'), RecipeSourceType.aiGenerated);
    });

    test('fromValue should return manual for unknown values', () {
      expect(RecipeSourceType.fromValue('unknown'), RecipeSourceType.manual);
      expect(RecipeSourceType.fromValue(null), RecipeSourceType.manual);
    });
  });

  group('RecipeIngredient', () {
    test('should create with required values', () {
      final ingredient = RecipeIngredient(
        id: 'ing-123',
        recipeId: 'recipe-456',
        foodName: 'Chicken Breast',
        amount: 200,
        unit: 'g',
        createdAt: DateTime(2024, 12, 25),
        updatedAt: DateTime(2024, 12, 25),
      );

      expect(ingredient.id, 'ing-123');
      expect(ingredient.recipeId, 'recipe-456');
      expect(ingredient.foodName, 'Chicken Breast');
      expect(ingredient.amount, 200);
      expect(ingredient.unit, 'g');
    });

    test('formattedAmount should return correct format', () {
      final ingredient = RecipeIngredient(
        id: 'ing-123',
        recipeId: 'recipe-456',
        foodName: 'Chicken Breast',
        amount: 200,
        unit: 'g',
        createdAt: DateTime(2024, 12, 25),
        updatedAt: DateTime(2024, 12, 25),
      );

      expect(ingredient.formattedAmount, '200.0 g');
    });

    test('caloriesInt should return rounded calories', () {
      final ingredient = RecipeIngredient(
        id: 'ing-123',
        recipeId: 'recipe-456',
        foodName: 'Chicken Breast',
        amount: 200,
        unit: 'g',
        calories: 330.7,
        createdAt: DateTime(2024, 12, 25),
        updatedAt: DateTime(2024, 12, 25),
      );

      expect(ingredient.caloriesInt, 331);
    });

    test('caloriesInt should return 0 when calories is null', () {
      final ingredient = RecipeIngredient(
        id: 'ing-123',
        recipeId: 'recipe-456',
        foodName: 'Chicken Breast',
        amount: 200,
        unit: 'g',
        createdAt: DateTime(2024, 12, 25),
        updatedAt: DateTime(2024, 12, 25),
      );

      expect(ingredient.caloriesInt, 0);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 'ing-123',
        'recipe_id': 'recipe-456',
        'ingredient_order': 1,
        'food_name': 'Chicken Breast',
        'brand': 'Organic Farms',
        'amount': 200.0,
        'unit': 'g',
        'amount_grams': 200.0,
        'calories': 330.0,
        'protein_g': 62.0,
        'carbs_g': 0.0,
        'fat_g': 7.0,
        'fiber_g': 0.0,
        'is_optional': false,
        'created_at': '2024-12-25T00:00:00.000Z',
        'updated_at': '2024-12-25T00:00:00.000Z',
      };

      final ingredient = RecipeIngredient.fromJson(json);

      expect(ingredient.id, 'ing-123');
      expect(ingredient.recipeId, 'recipe-456');
      expect(ingredient.ingredientOrder, 1);
      expect(ingredient.foodName, 'Chicken Breast');
      expect(ingredient.brand, 'Organic Farms');
      expect(ingredient.calories, 330.0);
      expect(ingredient.proteinG, 62.0);
    });
  });

  group('RecipeIngredientCreate', () {
    test('should create with required values', () {
      const ingredient = RecipeIngredientCreate(
        foodName: 'Oats',
        amount: 80,
        unit: 'g',
      );

      expect(ingredient.foodName, 'Oats');
      expect(ingredient.amount, 80);
      expect(ingredient.unit, 'g');
      expect(ingredient.isOptional, false);
      expect(ingredient.ingredientOrder, 0);
    });

    test('should create with all optional values', () {
      const ingredient = RecipeIngredientCreate(
        foodName: 'Oats',
        amount: 80,
        unit: 'g',
        brand: 'Quaker',
        calories: 280,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        fiberG: 8,
        notes: 'Old fashioned oats',
        isOptional: true,
        ingredientOrder: 2,
      );

      expect(ingredient.brand, 'Quaker');
      expect(ingredient.calories, 280);
      expect(ingredient.proteinG, 10);
      expect(ingredient.notes, 'Old fashioned oats');
      expect(ingredient.isOptional, true);
      expect(ingredient.ingredientOrder, 2);
    });

    test('toJson should serialize correctly', () {
      const ingredient = RecipeIngredientCreate(
        foodName: 'Oats',
        amount: 80,
        unit: 'g',
        calories: 280,
        proteinG: 10,
      );

      final json = ingredient.toJson();

      expect(json['food_name'], 'Oats');
      expect(json['amount'], 80);
      expect(json['unit'], 'g');
      expect(json['calories'], 280);
      expect(json['protein_g'], 10);
    });
  });

  group('Recipe', () {
    final now = DateTime(2024, 12, 25);

    test('should create with required values', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Oatmeal with Berries',
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.id, 'recipe-123');
      expect(recipe.userId, 'user-456');
      expect(recipe.name, 'Oatmeal with Berries');
      expect(recipe.servings, 1);
      expect(recipe.sourceType, 'manual');
      expect(recipe.isPublic, false);
    });

    test('categoryEnum should return correct enum', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Oatmeal with Berries',
        category: 'breakfast',
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.categoryEnum, RecipeCategory.breakfast);
    });

    test('sourceTypeEnum should return correct enum', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Oatmeal with Berries',
        sourceType: 'ai_generated',
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.sourceTypeEnum, RecipeSourceType.aiGenerated);
    });

    test('totalTimeMinutes should sum prep and cook time', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Oatmeal with Berries',
        prepTimeMinutes: 5,
        cookTimeMinutes: 10,
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.totalTimeMinutes, 15);
    });

    test('totalTimeMinutes should handle null values', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Oatmeal with Berries',
        prepTimeMinutes: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.totalTimeMinutes, 5);
    });

    test('formattedTotalTime should format correctly', () {
      final shortRecipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Quick Snack',
        prepTimeMinutes: 5,
        createdAt: now,
        updatedAt: now,
      );
      expect(shortRecipe.formattedTotalTime, '5 min');

      final hourRecipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Slow Cook',
        cookTimeMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );
      expect(hourRecipe.formattedTotalTime, '1 hr');

      final mixedRecipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Mixed',
        prepTimeMinutes: 15,
        cookTimeMinutes: 75,
        createdAt: now,
        updatedAt: now,
      );
      expect(mixedRecipe.formattedTotalTime, '1 hr 30 min');

      final noTimeRecipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'No Time',
        createdAt: now,
        updatedAt: now,
      );
      expect(noTimeRecipe.formattedTotalTime, '-');
    });

    test('hasBeenLogged should return correct value', () {
      final notLogged = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Test',
        timesLogged: 0,
        createdAt: now,
        updatedAt: now,
      );
      expect(notLogged.hasBeenLogged, false);

      final logged = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Test',
        timesLogged: 5,
        createdAt: now,
        updatedAt: now,
      );
      expect(logged.hasBeenLogged, true);
    });

    test('macroSummary should format correctly', () {
      final recipe = Recipe(
        id: 'recipe-123',
        userId: 'user-456',
        name: 'Test',
        proteinPerServingG: 25.5,
        carbsPerServingG: 40.2,
        fatPerServingG: 12.8,
        createdAt: now,
        updatedAt: now,
      );

      expect(recipe.macroSummary, '26g P | 40g C | 13g F');
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 'recipe-123',
        'user_id': 'user-456',
        'name': 'Oatmeal with Berries',
        'description': 'A healthy breakfast',
        'servings': 2,
        'prep_time_minutes': 5,
        'cook_time_minutes': 10,
        'category': 'breakfast',
        'source_type': 'manual',
        'is_public': false,
        'calories_per_serving': 350,
        'protein_per_serving_g': 12.0,
        'carbs_per_serving_g': 55.0,
        'fat_per_serving_g': 8.0,
        'times_logged': 5,
        'ingredients': [],
        'created_at': '2024-12-25T00:00:00.000Z',
        'updated_at': '2024-12-25T00:00:00.000Z',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'recipe-123');
      expect(recipe.name, 'Oatmeal with Berries');
      expect(recipe.description, 'A healthy breakfast');
      expect(recipe.servings, 2);
      expect(recipe.caloriesPerServing, 350);
      expect(recipe.timesLogged, 5);
    });
  });

  group('RecipeSummary', () {
    test('should create with required values', () {
      final summary = RecipeSummary(
        id: 'recipe-123',
        name: 'Oatmeal',
        createdAt: DateTime(2024, 12, 25),
      );

      expect(summary.id, 'recipe-123');
      expect(summary.name, 'Oatmeal');
      expect(summary.servings, 1);
      expect(summary.ingredientCount, 0);
      expect(summary.timesLogged, 0);
    });

    test('categoryEnum should return correct enum', () {
      final summary = RecipeSummary(
        id: 'recipe-123',
        name: 'Oatmeal',
        category: 'breakfast',
        createdAt: DateTime(2024, 12, 25),
      );

      expect(summary.categoryEnum, RecipeCategory.breakfast);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 'recipe-123',
        'name': 'Oatmeal',
        'category': 'breakfast',
        'calories_per_serving': 350,
        'protein_per_serving_g': 12.0,
        'servings': 2,
        'ingredient_count': 4,
        'times_logged': 10,
        'image_url': 'https://example.com/image.jpg',
        'created_at': '2024-12-25T00:00:00.000Z',
      };

      final summary = RecipeSummary.fromJson(json);

      expect(summary.id, 'recipe-123');
      expect(summary.name, 'Oatmeal');
      expect(summary.caloriesPerServing, 350);
      expect(summary.ingredientCount, 4);
      expect(summary.timesLogged, 10);
      expect(summary.imageUrl, 'https://example.com/image.jpg');
    });
  });

  group('RecipesResponse', () {
    test('should create with default empty values', () {
      const response = RecipesResponse();

      expect(response.items, isEmpty);
      expect(response.totalCount, 0);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'items': [
          {
            'id': 'recipe-123',
            'name': 'Oatmeal',
            'servings': 1,
            'ingredient_count': 3,
            'times_logged': 5,
            'created_at': '2024-12-25T00:00:00.000Z',
          }
        ],
        'total_count': 1,
      };

      final response = RecipesResponse.fromJson(json);

      expect(response.items.length, 1);
      expect(response.items.first.name, 'Oatmeal');
      expect(response.totalCount, 1);
    });
  });

  group('RecipeCreate', () {
    test('should create with required values', () {
      const create = RecipeCreate(name: 'New Recipe');

      expect(create.name, 'New Recipe');
      expect(create.servings, 1);
      expect(create.sourceType, 'manual');
      expect(create.isPublic, false);
      expect(create.ingredients, isEmpty);
    });

    test('should create with all values', () {
      const ingredient = RecipeIngredientCreate(
        foodName: 'Oats',
        amount: 80,
        unit: 'g',
      );

      const create = RecipeCreate(
        name: 'Oatmeal',
        description: 'Healthy breakfast',
        servings: 2,
        prepTimeMinutes: 5,
        cookTimeMinutes: 10,
        category: 'breakfast',
        cuisine: 'American',
        tags: ['healthy', 'quick'],
        ingredients: [ingredient],
      );

      expect(create.name, 'Oatmeal');
      expect(create.description, 'Healthy breakfast');
      expect(create.servings, 2);
      expect(create.prepTimeMinutes, 5);
      expect(create.cookTimeMinutes, 10);
      expect(create.category, 'breakfast');
      expect(create.cuisine, 'American');
      expect(create.tags, contains('healthy'));
      expect(create.ingredients.length, 1);
    });

    test('toJson should serialize correctly', () {
      const create = RecipeCreate(
        name: 'Oatmeal',
        servings: 2,
        category: 'breakfast',
      );

      final json = create.toJson();

      expect(json['name'], 'Oatmeal');
      expect(json['servings'], 2);
      expect(json['category'], 'breakfast');
      expect(json['source_type'], 'manual');
    });
  });

  group('RecipeUpdate', () {
    test('should create with null values by default', () {
      const update = RecipeUpdate();

      expect(update.name, isNull);
      expect(update.servings, isNull);
      expect(update.category, isNull);
    });

    test('should create with specified values', () {
      const update = RecipeUpdate(
        name: 'Updated Recipe',
        servings: 4,
        category: 'dinner',
        isPublic: true,
      );

      expect(update.name, 'Updated Recipe');
      expect(update.servings, 4);
      expect(update.category, 'dinner');
      expect(update.isPublic, true);
    });

    test('toJson should only include non-null values', () {
      const update = RecipeUpdate(
        name: 'Updated Recipe',
        servings: 4,
      );

      final json = update.toJson();

      expect(json['name'], 'Updated Recipe');
      expect(json['servings'], 4);
      // null values should still be in JSON but as null
    });
  });

  group('LogRecipeRequest', () {
    test('should create with required values', () {
      const request = LogRecipeRequest(mealType: 'lunch');

      expect(request.mealType, 'lunch');
      expect(request.servings, 1.0);
    });

    test('should create with custom servings', () {
      const request = LogRecipeRequest(
        mealType: 'dinner',
        servings: 2.5,
      );

      expect(request.mealType, 'dinner');
      expect(request.servings, 2.5);
    });

    test('toJson should serialize correctly', () {
      const request = LogRecipeRequest(
        mealType: 'lunch',
        servings: 1.5,
      );

      final json = request.toJson();

      expect(json['meal_type'], 'lunch');
      expect(json['servings'], 1.5);
    });
  });

  group('LogRecipeResponse', () {
    test('should create with required values', () {
      const response = LogRecipeResponse(
        success: true,
        foodLogId: 'log-123',
        recipeName: 'Oatmeal',
        servings: 1.0,
        totalCalories: 350,
        proteinG: 12.0,
        carbsG: 55.0,
        fatG: 8.0,
      );

      expect(response.success, true);
      expect(response.foodLogId, 'log-123');
      expect(response.recipeName, 'Oatmeal');
      expect(response.totalCalories, 350);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'success': true,
        'food_log_id': 'log-123',
        'recipe_name': 'Oatmeal',
        'servings': 2.0,
        'total_calories': 700,
        'protein_g': 24.0,
        'carbs_g': 110.0,
        'fat_g': 16.0,
        'fiber_g': 8.0,
      };

      final response = LogRecipeResponse.fromJson(json);

      expect(response.success, true);
      expect(response.foodLogId, 'log-123');
      expect(response.servings, 2.0);
      expect(response.totalCalories, 700);
      expect(response.fiberG, 8.0);
    });
  });

  group('ImportRecipeRequest', () {
    test('should create with required url', () {
      const request = ImportRecipeRequest(url: 'https://example.com/recipe');

      expect(request.url, 'https://example.com/recipe');
      expect(request.servingsOverride, isNull);
    });

    test('should create with servings override', () {
      const request = ImportRecipeRequest(
        url: 'https://example.com/recipe',
        servingsOverride: 4,
      );

      expect(request.url, 'https://example.com/recipe');
      expect(request.servingsOverride, 4);
    });

    test('toJson should serialize correctly', () {
      const request = ImportRecipeRequest(
        url: 'https://example.com/recipe',
        servingsOverride: 4,
      );

      final json = request.toJson();

      expect(json['url'], 'https://example.com/recipe');
      expect(json['servings_override'], 4);
    });
  });

  group('ImportRecipeResponse', () {
    test('should create with success false', () {
      const response = ImportRecipeResponse(
        success: false,
        error: 'Failed to parse recipe',
      );

      expect(response.success, false);
      expect(response.error, 'Failed to parse recipe');
      expect(response.recipe, isNull);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'success': true,
        'recipe': {
          'id': 'recipe-123',
          'user_id': 'user-456',
          'name': 'Imported Recipe',
          'servings': 4,
          'source_type': 'imported',
          'ingredients': [],
          'created_at': '2024-12-25T00:00:00.000Z',
          'updated_at': '2024-12-25T00:00:00.000Z',
        },
        'ingredients_found': 5,
        'ingredients_with_nutrition': 4,
      };

      final response = ImportRecipeResponse.fromJson(json);

      expect(response.success, true);
      expect(response.recipe, isNotNull);
      expect(response.recipe!.name, 'Imported Recipe');
      expect(response.ingredientsFound, 5);
      expect(response.ingredientsWithNutrition, 4);
    });
  });
}
