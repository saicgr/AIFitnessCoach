/// Public recipe sharing models.
library;

class ShareLink {
  final String recipeId;
  final String slug;
  final String url;
  final int viewCount;
  final int saveCount;
  final DateTime createdAt;
  final bool isPublic;

  const ShareLink({
    required this.recipeId,
    required this.slug,
    required this.url,
    required this.createdAt,
    this.viewCount = 0,
    this.saveCount = 0,
    this.isPublic = true,
  });

  factory ShareLink.fromJson(Map<String, dynamic> j) => ShareLink(
        recipeId: j['recipe_id'] as String,
        slug: j['slug'] as String,
        url: j['url'] as String,
        viewCount: j['view_count'] as int? ?? 0,
        saveCount: j['save_count'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        isPublic: j['is_public'] as bool? ?? true,
      );
}

class PublicRecipeView {
  final String slug;
  final String name;
  final String? description;
  final String? imageUrl;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? instructions;
  final String? category;
  final String? cuisine;
  final List<String> tags;
  final String? cookingMethod;
  final double? cookedYieldGrams;
  final int? caloriesPerServing;
  final double? proteinPerServingG;
  final double? carbsPerServingG;
  final double? fatPerServingG;
  final double? fiberPerServingG;
  final List<Map<String, dynamic>> ingredients;
  final int timesLogged;
  final int viewCount;
  final int saveCount;
  final String? authorDisplayName;

  const PublicRecipeView({
    required this.slug,
    required this.name,
    required this.servings,
    required this.ingredients,
    required this.timesLogged,
    required this.viewCount,
    required this.saveCount,
    this.description,
    this.imageUrl,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
    this.category,
    this.cuisine,
    this.tags = const [],
    this.cookingMethod,
    this.cookedYieldGrams,
    this.caloriesPerServing,
    this.proteinPerServingG,
    this.carbsPerServingG,
    this.fatPerServingG,
    this.fiberPerServingG,
    this.authorDisplayName,
  });

  factory PublicRecipeView.fromJson(Map<String, dynamic> j) => PublicRecipeView(
        slug: j['slug'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        servings: j['servings'] as int? ?? 1,
        prepTimeMinutes: j['prep_time_minutes'] as int?,
        cookTimeMinutes: j['cook_time_minutes'] as int?,
        instructions: j['instructions'] as String?,
        category: j['category'] as String?,
        cuisine: j['cuisine'] as String?,
        tags: (j['tags'] as List? ?? []).map((e) => e as String).toList(),
        cookingMethod: j['cooking_method'] as String?,
        cookedYieldGrams: (j['cooked_yield_grams'] as num?)?.toDouble(),
        caloriesPerServing: j['calories_per_serving'] as int?,
        proteinPerServingG: (j['protein_per_serving_g'] as num?)?.toDouble(),
        carbsPerServingG: (j['carbs_per_serving_g'] as num?)?.toDouble(),
        fatPerServingG: (j['fat_per_serving_g'] as num?)?.toDouble(),
        fiberPerServingG: (j['fiber_per_serving_g'] as num?)?.toDouble(),
        ingredients: (j['ingredients'] as List? ?? []).cast<Map<String, dynamic>>(),
        timesLogged: j['times_logged'] as int? ?? 0,
        viewCount: j['view_count'] as int? ?? 0,
        saveCount: j['save_count'] as int? ?? 0,
        authorDisplayName: j['author_display_name'] as String?,
      );
}

class CloneRecipeResponse {
  final String newRecipeId;
  final bool alreadySaved;
  final String message;

  const CloneRecipeResponse({
    required this.newRecipeId,
    required this.message,
    this.alreadySaved = false,
  });

  factory CloneRecipeResponse.fromJson(Map<String, dynamic> j) => CloneRecipeResponse(
        newRecipeId: j['new_recipe_id'] as String,
        alreadySaved: j['already_saved'] as bool? ?? false,
        message: (j['message'] ?? '') as String,
      );
}
