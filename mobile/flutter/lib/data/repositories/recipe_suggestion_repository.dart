import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_suggestion.dart';
import '../services/api_client.dart';

/// Recipe suggestion repository provider
final recipeSuggestionRepositoryProvider = Provider<RecipeSuggestionRepository>((ref) {
  return RecipeSuggestionRepository(ref.watch(apiClientProvider));
});

/// Repository for AI-powered recipe suggestions based on body type, culture, and diet
class RecipeSuggestionRepository {
  final ApiClient _apiClient;

  RecipeSuggestionRepository(this._apiClient);

  /// Generate AI recipe suggestions based on user preferences
  Future<SuggestRecipesResponse> suggestRecipes({
    required String userId,
    String mealType = 'any',
    int count = 3,
    String? additionalRequirements,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$userId/suggest',
        data: {
          'meal_type': mealType,
          'count': count,
          if (additionalRequirements != null)
            'additional_requirements': additionalRequirements,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return SuggestRecipesResponse.fromJson(response.data);
      }

      return SuggestRecipesResponse(
        success: false,
        recipes: [],
        error: 'Failed to generate recipes',
      );
    } catch (e) {
      debugPrint('Error generating recipe suggestions: $e');
      return SuggestRecipesResponse(
        success: false,
        recipes: [],
        error: e.toString(),
      );
    }
  }

  /// Get user's saved/suggested recipes history
  Future<List<RecipeSuggestion>> getSuggestions({
    required String userId,
    bool savedOnly = false,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/recipes/$userId/suggestions',
        queryParameters: {
          'saved_only': savedOnly,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['suggestions'] ?? [];
        return data.map((json) => RecipeSuggestion.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching recipe suggestions: $e');
      return [];
    }
  }

  /// Rate a recipe suggestion (1-5 stars)
  Future<bool> rateRecipe({
    required String userId,
    required String suggestionId,
    required int rating,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$userId/suggestions/$suggestionId/rate',
        data: {'rating': rating},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error rating recipe: $e');
      return false;
    }
  }

  /// Save or unsave a recipe suggestion
  Future<bool> saveRecipe({
    required String userId,
    required String suggestionId,
    bool save = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$userId/suggestions/$suggestionId/save',
        data: {'save': save},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      return false;
    }
  }

  /// Mark a recipe as cooked
  Future<bool> markAsCooked({
    required String userId,
    required String suggestionId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$userId/suggestions/$suggestionId/cooked',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking recipe as cooked: $e');
      return false;
    }
  }

  /// Convert a suggestion to a user recipe
  Future<String?> convertToUserRecipe({
    required String userId,
    required String suggestionId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$userId/suggestions/$suggestionId/convert',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['recipe_id'];
      }

      return null;
    } catch (e) {
      debugPrint('Error converting suggestion to recipe: $e');
      return null;
    }
  }

  /// Get available cuisines list
  Future<List<CuisineInfo>> getCuisines() async {
    try {
      final response = await _apiClient.get('/nutrition/recipes/cuisines');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((json) => CuisineInfo.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching cuisines: $e');
      return [];
    }
  }

  /// Get body types with descriptions
  Future<List<BodyTypeInfo>> getBodyTypes() async {
    try {
      final response = await _apiClient.get('/nutrition/recipes/body-types');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((json) => BodyTypeInfo.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching body types: $e');
      return [];
    }
  }

  /// Update user's recipe preferences (body type, cuisines, spice tolerance)
  Future<bool> updateRecipePreferences({
    required String userId,
    String? bodyType,
    List<String>? favoriteCuisines,
    String? culturalBackground,
    String? spiceTolerance,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (bodyType != null) data['body_type'] = bodyType;
      if (favoriteCuisines != null) data['favorite_cuisines'] = favoriteCuisines;
      if (culturalBackground != null) data['cultural_background'] = culturalBackground;
      if (spiceTolerance != null) data['spice_tolerance'] = spiceTolerance;

      if (data.isEmpty) return true;

      final response = await _apiClient.put(
        '/nutrition/recipes/$userId/preferences',
        data: data,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating recipe preferences: $e');
      return false;
    }
  }
}
