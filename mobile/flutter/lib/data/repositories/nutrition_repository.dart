import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/nutrition.dart';
import '../models/micronutrients.dart';
import '../models/recipe.dart';
import '../services/api_client.dart';

/// Nutrition repository provider
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider));
});

/// Nutrition state
class NutritionState {
  final bool isLoading;
  final String? error;
  final DailyNutritionSummary? todaySummary;
  final NutritionTargets? targets;
  final List<FoodLog> recentLogs;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.targets,
    this.recentLogs = const [],
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    DailyNutritionSummary? todaySummary,
    NutritionTargets? targets,
    List<FoodLog>? recentLogs,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      targets: targets ?? this.targets,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}

/// Nutrition state provider
final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref.watch(nutritionRepositoryProvider));
});

/// Nutrition state notifier
class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;

  NutritionNotifier(this._repository) : super(const NutritionState());

  /// Load today's nutrition summary
  Future<void> loadTodaySummary(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _repository.getDailySummary(userId);
      state = state.copyWith(isLoading: false, todaySummary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load nutrition targets
  Future<void> loadTargets(String userId) async {
    try {
      final targets = await _repository.getTargets(userId);
      state = state.copyWith(targets: targets);
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  /// Load recent food logs
  Future<void> loadRecentLogs(String userId, {int limit = 50}) async {
    try {
      final logs = await _repository.getFoodLogs(userId, limit: limit);
      state = state.copyWith(recentLogs: logs);
    } catch (e) {
      debugPrint('Error loading recent food logs: $e');
    }
  }

  /// Delete a food log
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteFoodLog(logId);
      await loadTodaySummary(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _repository.updateTargets(
        userId,
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
      );
      await loadTargets(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Nutrition repository
class NutritionRepository {
  final ApiClient _client;

  NutritionRepository(this._client);

  /// Get food logs for a user
  Future<List<FoodLog>> getFoodLogs(
    String userId, {
    int limit = 50,
    String? fromDate,
    String? toDate,
    String? mealType,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      if (mealType != null) queryParams['meal_type'] = mealType;

      final response = await _client.get(
        '/nutrition/food-logs/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => FoodLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting food logs: $e');
      rethrow;
    }
  }

  /// Get daily nutrition summary
  Future<DailyNutritionSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/summary/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyNutritionSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily nutrition summary: $e');
      rethrow;
    }
  }

  /// Delete a food log
  Future<void> deleteFoodLog(String logId) async {
    try {
      await _client.delete('/nutrition/food-logs/$logId');
    } catch (e) {
      debugPrint('Error deleting food log: $e');
      rethrow;
    }
  }

  /// Get nutrition targets
  Future<NutritionTargets> getTargets(String userId) async {
    try {
      final response = await _client.get('/nutrition/targets/$userId');
      return NutritionTargets.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting nutrition targets: $e');
      rethrow;
    }
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _client.put(
        '/nutrition/targets/$userId',
        data: {
          'user_id': userId,
          if (calorieTarget != null) 'daily_calorie_target': calorieTarget,
          if (proteinTarget != null) 'daily_protein_target_g': proteinTarget,
          if (carbsTarget != null) 'daily_carbs_target_g': carbsTarget,
          if (fatTarget != null) 'daily_fat_target_g': fatTarget,
        },
      );
    } catch (e) {
      debugPrint('Error updating nutrition targets: $e');
      rethrow;
    }
  }

  // ============================================
  // Barcode & AI Food Logging Methods
  // ============================================

  /// Lookup a product by barcode
  Future<BarcodeProduct> lookupBarcode(String barcode) async {
    try {
      final response = await _client.get('/nutrition/barcode/$barcode');
      return BarcodeProduct.fromJson(response.data);
    } catch (e) {
      debugPrint('Error looking up barcode: $e');
      rethrow;
    }
  }

  /// Log food from barcode scan
  Future<LogBarcodeResponse> logFoodFromBarcode({
    required String userId,
    required String barcode,
    required String mealType,
    double servings = 1.0,
    double? servingSizeG,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/log-barcode',
        data: {
          'user_id': userId,
          'barcode': barcode,
          'meal_type': mealType,
          'servings': servings,
          if (servingSizeG != null) 'serving_size_g': servingSizeG,
        },
      );
      return LogBarcodeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from barcode: $e');
      rethrow;
    }
  }

  /// Log food from image using Gemini Vision
  Future<LogFoodResponse> logFoodFromImage({
    required String userId,
    required String mealType,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'food_image.jpg',
        ),
      });

      final response = await _client.post(
        '/nutrition/log-image',
        data: formData,
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from image: $e');
      rethrow;
    }
  }

  /// Log food from text description using Gemini
  Future<LogFoodResponse> logFoodFromText({
    required String userId,
    required String description,
    required String mealType,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/log-text',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
        },
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from text: $e');
      rethrow;
    }
  }

  // ============================================
  // Saved Foods (Favorite Recipes) Methods
  // ============================================

  /// Save a food as favorite
  Future<SavedFood> saveFood({
    required String userId,
    required SaveFoodRequest request,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/saved-foods/save',
        queryParameters: {'user_id': userId},
        data: request.toJson(),
      );
      return SavedFood.fromJson(response.data);
    } catch (e) {
      debugPrint('Error saving food: $e');
      rethrow;
    }
  }

  /// Get list of saved foods
  Future<SavedFoodsResponse> getSavedFoods({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? sourceType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      };
      if (sourceType != null) queryParams['source_type'] = sourceType;

      final response = await _client.get(
        '/nutrition/saved-foods',
        queryParameters: queryParams,
      );
      return SavedFoodsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting saved foods: $e');
      rethrow;
    }
  }

  /// Get a specific saved food
  Future<SavedFood> getSavedFood({
    required String userId,
    required String savedFoodId,
  }) async {
    try {
      final response = await _client.get(
        '/nutrition/saved-foods/$savedFoodId',
        queryParameters: {'user_id': userId},
      );
      return SavedFood.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting saved food: $e');
      rethrow;
    }
  }

  /// Delete a saved food
  Future<void> deleteSavedFood({
    required String userId,
    required String savedFoodId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/saved-foods/$savedFoodId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error deleting saved food: $e');
      rethrow;
    }
  }

  /// Re-log a saved food
  Future<LogFoodResponse> relogSavedFood({
    required String userId,
    required String savedFoodId,
    required String mealType,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/saved-foods/$savedFoodId/log',
        queryParameters: {'user_id': userId},
        data: {'meal_type': mealType},
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error re-logging saved food: $e');
      rethrow;
    }
  }

  // ============================================
  // Recipe Methods
  // ============================================

  /// Create a new recipe
  Future<Recipe> createRecipe({
    required String userId,
    required RecipeCreate request,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes',
        queryParameters: {'user_id': userId},
        data: request.toJson(),
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error creating recipe: $e');
      rethrow;
    }
  }

  /// Get list of user's recipes
  Future<RecipesResponse> getRecipes({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? category,
    String? search,
    String sortBy = 'created_at',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
        'sort_by': sortBy,
      };
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      final response = await _client.get(
        '/nutrition/recipes',
        queryParameters: queryParams,
      );
      return RecipesResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      rethrow;
    }
  }

  /// Get a specific recipe with ingredients
  Future<Recipe> getRecipe({
    required String userId,
    required String recipeId,
  }) async {
    try {
      final response = await _client.get(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting recipe: $e');
      rethrow;
    }
  }

  /// Update a recipe
  Future<Recipe> updateRecipe({
    required String userId,
    required String recipeId,
    required RecipeUpdate request,
  }) async {
    try {
      final response = await _client.put(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
        data: request.toJson(),
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      rethrow;
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      rethrow;
    }
  }

  /// Log a recipe as a meal
  Future<LogRecipeResponse> logRecipe({
    required String userId,
    required String recipeId,
    required String mealType,
    double servings = 1.0,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes/$recipeId/log',
        queryParameters: {'user_id': userId},
        data: {
          'meal_type': mealType,
          'servings': servings,
        },
      );
      return LogRecipeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging recipe: $e');
      rethrow;
    }
  }

  /// Add ingredient to a recipe
  Future<RecipeIngredient> addIngredient({
    required String userId,
    required String recipeId,
    required RecipeIngredientCreate ingredient,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes/$recipeId/ingredients',
        queryParameters: {'user_id': userId},
        data: ingredient.toJson(),
      );
      return RecipeIngredient.fromJson(response.data);
    } catch (e) {
      debugPrint('Error adding ingredient: $e');
      rethrow;
    }
  }

  /// Remove ingredient from a recipe
  Future<void> removeIngredient({
    required String userId,
    required String recipeId,
    required String ingredientId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/recipes/$recipeId/ingredients/$ingredientId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error removing ingredient: $e');
      rethrow;
    }
  }

  // ============================================
  // Micronutrient Methods
  // ============================================

  /// Get daily micronutrient summary
  Future<DailyMicronutrientSummary> getDailyMicronutrients({
    required String userId,
    String? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/micronutrients/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyMicronutrientSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily micronutrients: $e');
      rethrow;
    }
  }

  /// Get top contributors for a specific nutrient
  Future<NutrientContributorsResponse> getNutrientContributors({
    required String userId,
    required String nutrientKey,
    String? date,
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/micronutrients/$userId/contributors/$nutrientKey',
        queryParameters: queryParams,
      );
      return NutrientContributorsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting nutrient contributors: $e');
      rethrow;
    }
  }

  /// Get all RDA (Reference Daily Allowance) values
  Future<List<NutrientRDA>> getAllRDAs() async {
    try {
      final response = await _client.get('/nutrition/rdas');
      final data = response.data as List;
      return data.map((json) => NutrientRDA.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting RDAs: $e');
      rethrow;
    }
  }

  /// Update user's pinned nutrients
  Future<void> updatePinnedNutrients({
    required String userId,
    required List<String> pinnedNutrients,
  }) async {
    try {
      await _client.put(
        '/nutrition/pinned-nutrients/$userId',
        data: {'pinned_nutrients': pinnedNutrients},
      );
    } catch (e) {
      debugPrint('Error updating pinned nutrients: $e');
      rethrow;
    }
  }
}
