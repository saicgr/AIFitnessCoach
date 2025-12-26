// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredient _$RecipeIngredientFromJson(Map<String, dynamic> json) =>
    RecipeIngredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      ingredientOrder: (json['ingredient_order'] as num?)?.toInt() ?? 0,
      foodName: json['food_name'] as String,
      brand: json['brand'] as String?,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      amountGrams: (json['amount_grams'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      sugarG: (json['sugar_g'] as num?)?.toDouble(),
      vitaminDIu: (json['vitamin_d_iu'] as num?)?.toDouble(),
      calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
      ironMg: (json['iron_mg'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      omega3G: (json['omega3_g'] as num?)?.toDouble(),
      micronutrients: json['micronutrients'] == null
          ? null
          : MicronutrientData.fromJson(
              json['micronutrients'] as Map<String, dynamic>,
            ),
      notes: json['notes'] as String?,
      isOptional: json['is_optional'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RecipeIngredientToJson(RecipeIngredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipe_id': instance.recipeId,
      'ingredient_order': instance.ingredientOrder,
      'food_name': instance.foodName,
      'brand': instance.brand,
      'amount': instance.amount,
      'unit': instance.unit,
      'amount_grams': instance.amountGrams,
      'barcode': instance.barcode,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'sugar_g': instance.sugarG,
      'vitamin_d_iu': instance.vitaminDIu,
      'calcium_mg': instance.calciumMg,
      'iron_mg': instance.ironMg,
      'sodium_mg': instance.sodiumMg,
      'omega3_g': instance.omega3G,
      'micronutrients': instance.micronutrients,
      'notes': instance.notes,
      'is_optional': instance.isOptional,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

RecipeIngredientCreate _$RecipeIngredientCreateFromJson(
  Map<String, dynamic> json,
) => RecipeIngredientCreate(
  foodName: json['food_name'] as String,
  brand: json['brand'] as String?,
  amount: (json['amount'] as num).toDouble(),
  unit: json['unit'] as String,
  amountGrams: (json['amount_grams'] as num?)?.toDouble(),
  barcode: json['barcode'] as String?,
  calories: (json['calories'] as num?)?.toDouble(),
  proteinG: (json['protein_g'] as num?)?.toDouble(),
  carbsG: (json['carbs_g'] as num?)?.toDouble(),
  fatG: (json['fat_g'] as num?)?.toDouble(),
  fiberG: (json['fiber_g'] as num?)?.toDouble(),
  sugarG: (json['sugar_g'] as num?)?.toDouble(),
  vitaminDIu: (json['vitamin_d_iu'] as num?)?.toDouble(),
  calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
  ironMg: (json['iron_mg'] as num?)?.toDouble(),
  sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
  omega3G: (json['omega3_g'] as num?)?.toDouble(),
  micronutrients: json['micronutrients'] == null
      ? null
      : MicronutrientData.fromJson(
          json['micronutrients'] as Map<String, dynamic>,
        ),
  notes: json['notes'] as String?,
  isOptional: json['is_optional'] as bool? ?? false,
  ingredientOrder: (json['ingredient_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RecipeIngredientCreateToJson(
  RecipeIngredientCreate instance,
) => <String, dynamic>{
  'food_name': instance.foodName,
  'brand': instance.brand,
  'amount': instance.amount,
  'unit': instance.unit,
  'amount_grams': instance.amountGrams,
  'barcode': instance.barcode,
  'calories': instance.calories,
  'protein_g': instance.proteinG,
  'carbs_g': instance.carbsG,
  'fat_g': instance.fatG,
  'fiber_g': instance.fiberG,
  'sugar_g': instance.sugarG,
  'vitamin_d_iu': instance.vitaminDIu,
  'calcium_mg': instance.calciumMg,
  'iron_mg': instance.ironMg,
  'sodium_mg': instance.sodiumMg,
  'omega3_g': instance.omega3G,
  'micronutrients': instance.micronutrients,
  'notes': instance.notes,
  'is_optional': instance.isOptional,
  'ingredient_order': instance.ingredientOrder,
};

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  servings: (json['servings'] as num?)?.toInt() ?? 1,
  prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt(),
  instructions: json['instructions'] as String?,
  imageUrl: json['image_url'] as String?,
  category: json['category'] as String?,
  cuisine: json['cuisine'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  sourceUrl: json['source_url'] as String?,
  sourceType: json['source_type'] as String? ?? 'manual',
  isPublic: json['is_public'] as bool? ?? false,
  caloriesPerServing: (json['calories_per_serving'] as num?)?.toInt(),
  proteinPerServingG: (json['protein_per_serving_g'] as num?)?.toDouble(),
  carbsPerServingG: (json['carbs_per_serving_g'] as num?)?.toDouble(),
  fatPerServingG: (json['fat_per_serving_g'] as num?)?.toDouble(),
  fiberPerServingG: (json['fiber_per_serving_g'] as num?)?.toDouble(),
  sugarPerServingG: (json['sugar_per_serving_g'] as num?)?.toDouble(),
  vitaminDPerServingIu: (json['vitamin_d_per_serving_iu'] as num?)?.toDouble(),
  calciumPerServingMg: (json['calcium_per_serving_mg'] as num?)?.toDouble(),
  ironPerServingMg: (json['iron_per_serving_mg'] as num?)?.toDouble(),
  omega3PerServingG: (json['omega3_per_serving_g'] as num?)?.toDouble(),
  sodiumPerServingMg: (json['sodium_per_serving_mg'] as num?)?.toDouble(),
  micronutrientsPerServing:
      json['micronutrients_per_serving'] as Map<String, dynamic>?,
  timesLogged: (json['times_logged'] as num?)?.toInt() ?? 0,
  lastLoggedAt: json['last_logged_at'] == null
      ? null
      : DateTime.parse(json['last_logged_at'] as String),
  ingredients:
      (json['ingredients'] as List<dynamic>?)
          ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  ingredientCount: (json['ingredient_count'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'servings': instance.servings,
  'prep_time_minutes': instance.prepTimeMinutes,
  'cook_time_minutes': instance.cookTimeMinutes,
  'instructions': instance.instructions,
  'image_url': instance.imageUrl,
  'category': instance.category,
  'cuisine': instance.cuisine,
  'tags': instance.tags,
  'source_url': instance.sourceUrl,
  'source_type': instance.sourceType,
  'is_public': instance.isPublic,
  'calories_per_serving': instance.caloriesPerServing,
  'protein_per_serving_g': instance.proteinPerServingG,
  'carbs_per_serving_g': instance.carbsPerServingG,
  'fat_per_serving_g': instance.fatPerServingG,
  'fiber_per_serving_g': instance.fiberPerServingG,
  'sugar_per_serving_g': instance.sugarPerServingG,
  'vitamin_d_per_serving_iu': instance.vitaminDPerServingIu,
  'calcium_per_serving_mg': instance.calciumPerServingMg,
  'iron_per_serving_mg': instance.ironPerServingMg,
  'omega3_per_serving_g': instance.omega3PerServingG,
  'sodium_per_serving_mg': instance.sodiumPerServingMg,
  'micronutrients_per_serving': instance.micronutrientsPerServing,
  'times_logged': instance.timesLogged,
  'last_logged_at': instance.lastLoggedAt?.toIso8601String(),
  'ingredients': instance.ingredients,
  'ingredient_count': instance.ingredientCount,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
};

RecipeSummary _$RecipeSummaryFromJson(Map<String, dynamic> json) =>
    RecipeSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      caloriesPerServing: (json['calories_per_serving'] as num?)?.toInt(),
      proteinPerServingG: (json['protein_per_serving_g'] as num?)?.toDouble(),
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      ingredientCount: (json['ingredient_count'] as num?)?.toInt() ?? 0,
      timesLogged: (json['times_logged'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RecipeSummaryToJson(RecipeSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'calories_per_serving': instance.caloriesPerServing,
      'protein_per_serving_g': instance.proteinPerServingG,
      'servings': instance.servings,
      'ingredient_count': instance.ingredientCount,
      'times_logged': instance.timesLogged,
      'image_url': instance.imageUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };

RecipesResponse _$RecipesResponseFromJson(Map<String, dynamic> json) =>
    RecipesResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RecipesResponseToJson(RecipesResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
    };

RecipeCreate _$RecipeCreateFromJson(Map<String, dynamic> json) => RecipeCreate(
  name: json['name'] as String,
  description: json['description'] as String?,
  servings: (json['servings'] as num?)?.toInt() ?? 1,
  prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt(),
  instructions: json['instructions'] as String?,
  imageUrl: json['image_url'] as String?,
  category: json['category'] as String?,
  cuisine: json['cuisine'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  sourceUrl: json['source_url'] as String?,
  sourceType: json['source_type'] as String? ?? 'manual',
  isPublic: json['is_public'] as bool? ?? false,
  ingredients:
      (json['ingredients'] as List<dynamic>?)
          ?.map(
            (e) => RecipeIngredientCreate.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$RecipeCreateToJson(RecipeCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'servings': instance.servings,
      'prep_time_minutes': instance.prepTimeMinutes,
      'cook_time_minutes': instance.cookTimeMinutes,
      'instructions': instance.instructions,
      'image_url': instance.imageUrl,
      'category': instance.category,
      'cuisine': instance.cuisine,
      'tags': instance.tags,
      'source_url': instance.sourceUrl,
      'source_type': instance.sourceType,
      'is_public': instance.isPublic,
      'ingredients': instance.ingredients,
    };

RecipeUpdate _$RecipeUpdateFromJson(Map<String, dynamic> json) => RecipeUpdate(
  name: json['name'] as String?,
  description: json['description'] as String?,
  servings: (json['servings'] as num?)?.toInt(),
  prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt(),
  instructions: json['instructions'] as String?,
  imageUrl: json['image_url'] as String?,
  category: json['category'] as String?,
  cuisine: json['cuisine'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isPublic: json['is_public'] as bool?,
);

Map<String, dynamic> _$RecipeUpdateToJson(RecipeUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'servings': instance.servings,
      'prep_time_minutes': instance.prepTimeMinutes,
      'cook_time_minutes': instance.cookTimeMinutes,
      'instructions': instance.instructions,
      'image_url': instance.imageUrl,
      'category': instance.category,
      'cuisine': instance.cuisine,
      'tags': instance.tags,
      'is_public': instance.isPublic,
    };

LogRecipeRequest _$LogRecipeRequestFromJson(Map<String, dynamic> json) =>
    LogRecipeRequest(
      mealType: json['meal_type'] as String,
      servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$LogRecipeRequestToJson(LogRecipeRequest instance) =>
    <String, dynamic>{
      'meal_type': instance.mealType,
      'servings': instance.servings,
    };

LogRecipeResponse _$LogRecipeResponseFromJson(Map<String, dynamic> json) =>
    LogRecipeResponse(
      success: json['success'] as bool,
      foodLogId: json['food_log_id'] as String,
      recipeName: json['recipe_name'] as String,
      servings: (json['servings'] as num).toDouble(),
      totalCalories: (json['total_calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LogRecipeResponseToJson(LogRecipeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'food_log_id': instance.foodLogId,
      'recipe_name': instance.recipeName,
      'servings': instance.servings,
      'total_calories': instance.totalCalories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
    };

ImportRecipeRequest _$ImportRecipeRequestFromJson(Map<String, dynamic> json) =>
    ImportRecipeRequest(
      url: json['url'] as String,
      servingsOverride: (json['servings_override'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ImportRecipeRequestToJson(
  ImportRecipeRequest instance,
) => <String, dynamic>{
  'url': instance.url,
  'servings_override': instance.servingsOverride,
};

ImportRecipeResponse _$ImportRecipeResponseFromJson(
  Map<String, dynamic> json,
) => ImportRecipeResponse(
  success: json['success'] as bool,
  recipe: json['recipe'] == null
      ? null
      : Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
  error: json['error'] as String?,
  ingredientsFound: (json['ingredients_found'] as num?)?.toInt() ?? 0,
  ingredientsWithNutrition:
      (json['ingredients_with_nutrition'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ImportRecipeResponseToJson(
  ImportRecipeResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'recipe': instance.recipe,
  'error': instance.error,
  'ingredients_found': instance.ingredientsFound,
  'ingredients_with_nutrition': instance.ingredientsWithNutrition,
};
