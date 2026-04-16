/// Recipe + planner + grocery + sharing + versioning + cook-events + search repository.
///
/// One repo to wrap the v1 nutrition Recipes endpoints. Streaming imports use
/// raw http for SSE; everything else goes through the shared Dio client.
library;

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_review.dart';
import '../models/cook_event.dart';
import '../models/grocery_list.dart';
import '../models/ingredient_analysis.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/recipe_share.dart';
import '../models/recipe_version.dart';
import '../models/scheduled_recipe.dart';
import '../services/api_client.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(apiClientProvider));
});

class RecipeRepository {
  final ApiClient _client;
  RecipeRepository(this._client);

  // ============================================================
  // INGREDIENT ANALYZER
  // ============================================================

  Future<IngredientAnalysis> analyzeIngredient(
    String userId, {
    required String text,
    String? brandHint,
    String? cookingMethodHint,
  }) async {
    final res = await _client.post(
      '/nutrition/recipes/analyze-ingredient',
      queryParameters: {'user_id': userId},
      data: {
        'text': text,
        if (brandHint != null) 'brand_hint': brandHint,
        if (cookingMethodHint != null) 'cooking_method_hint': cookingMethodHint,
      },
    );
    return IngredientAnalysis.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<IngredientAnalysis>> analyzeIngredientsBulk(
    String userId, {
    required List<String> texts,
  }) async {
    final res = await _client.post(
      '/nutrition/recipes/analyze-ingredients',
      queryParameters: {'user_id': userId},
      data: {
        'items': texts.map((t) => {'text': t}).toList(),
      },
    );
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => IngredientAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // IMPORT (SSE)
  // ============================================================

  /// Stream import progress events for URL/text/handwritten import.
  Stream<ImportProgressEvent> importStream({
    required String mode, // 'url' | 'text' | 'handwritten'
    required String userId,
    String? url,
    String? text,
    String? imageB64,
  }) async* {
    final endpoint = switch (mode) {
      'url' => '/nutrition/recipes/import-url',
      'text' => '/nutrition/recipes/import-text',
      'handwritten' => '/nutrition/recipes/import-handwritten',
      _ => throw ArgumentError('unknown import mode: $mode'),
    };

    final body = switch (mode) {
      'url' => {'url': url ?? ''},
      'text' => {'text': text ?? ''},
      'handwritten' => {'image_b64': imageB64 ?? ''},
      _ => const {},
    };

    final response = await _client.post(
      endpoint,
      queryParameters: {'user_id': userId},
      data: body,
      options: Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream'}),
    );

    final stream = (response.data as ResponseBody).stream;
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk, allowMalformed: true));
      String text = buffer.toString();
      while (text.contains('\n\n')) {
        final idx = text.indexOf('\n\n');
        final block = text.substring(0, idx);
        text = text.substring(idx + 2);
        for (final line in block.split('\n')) {
          if (line.startsWith('data:')) {
            final json = line.substring(5).trim();
            if (json.isEmpty) continue;
            try {
              yield ImportProgressEvent.fromJson(jsonDecode(json) as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) debugPrint('SSE parse error: $e');
            }
          }
        }
      }
      buffer
        ..clear()
        ..write(text);
    }
  }

  Future<PantryAnalyzeResponse> fromPantry(
    String userId, {
    List<String>? itemsText,
    String? imageB64,
    String? mealType,
    int count = 3,
    String? additionalRequirements,
  }) async {
    final res = await _client.post(
      '/nutrition/recipes/from-pantry',
      queryParameters: {'user_id': userId},
      data: {
        if (itemsText != null) 'items_text': itemsText,
        if (imageB64 != null) 'image_b64': imageB64,
        if (mealType != null) 'meal_type': mealType,
        'count': count,
        if (additionalRequirements != null) 'additional_requirements': additionalRequirements,
      },
    );
    return PantryAnalyzeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<RecipesResponse> search(
    String userId, {
    required String query,
    String scope = 'mine',
    String? category,
    String? cuisine,
    bool hasLeftovers = false,
    int limit = 30,
    // New Discover/Favorites filters — all optional to keep backward compat.
    List<String>? sourceTypeIn,
    bool? isFavorite,
    String? sortBy, // 'created_desc' | 'name_asc' | 'most_logged' | 'last_cooked'
  }) async {
    final res = await _client.get(
      '/nutrition/recipes-search',
      queryParameters: {
        'user_id': userId,
        'q': query,
        'scope': scope,
        if (category != null) 'category': category,
        if (cuisine != null) 'cuisine': cuisine,
        if (hasLeftovers) 'has_leftovers': true,
        if (sourceTypeIn != null && sourceTypeIn.isNotEmpty)
          'source_type_in': sourceTypeIn.join(','),
        if (isFavorite != null) 'is_favorite': isFavorite,
        if (sortBy != null) 'sort_by': sortBy,
        'limit': limit,
      },
    );
    return RecipesResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<ShareLink> enableShare(String userId, String recipeId) async {
    final res = await _client.post(
      '/nutrition/recipes/$recipeId/share',
      queryParameters: {'user_id': userId},
    );
    return ShareLink.fromJson(((res.data as Map)['link'] as Map).cast<String, dynamic>());
  }

  Future<void> disableShare(String userId, String recipeId) async {
    await _client.delete(
      '/nutrition/recipes/$recipeId/share',
      queryParameters: {'user_id': userId},
    );
  }

  Future<PublicRecipeView> resolveShare(String slug) async {
    final res = await _client.get('/r/$slug');
    return PublicRecipeView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CloneRecipeResponse> cloneShared(String slug) async {
    final res = await _client.post('/r/$slug/save');
    return CloneRecipeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // VERSIONS
  // ============================================================

  Future<RecipeVersionsResponse> listVersions(String recipeId, {int limit = 50}) async {
    final res = await _client.get(
      '/nutrition/recipes/$recipeId/versions',
      queryParameters: {'limit': limit},
    );
    return RecipeVersionsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecipeDiff> diffVersions(String recipeId, int fromV, int toV) async {
    final res = await _client.get(
      '/nutrition/recipes/$recipeId/versions-diff',
      queryParameters: {'from_version': fromV, 'to_version': toV},
    );
    return RecipeDiff.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RecipeRevertResponse> revert(String recipeId, int targetVersion, String userId) async {
    final res = await _client.post(
      '/nutrition/recipes/$recipeId/revert',
      queryParameters: {'user_id': userId},
      data: {'target_version': targetVersion},
    );
    return RecipeRevertResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // COACH REVIEWS
  // ============================================================

  Future<CoachReview> reviewRecipe(String userId, String recipeId) async {
    final res = await _client.post(
      '/nutrition/recipes/$recipeId/coach-review',
      queryParameters: {'user_id': userId},
    );
    return CoachReview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CoachReview> reviewMealPlan(String userId, String planId) async {
    final res = await _client.post(
      '/nutrition/meal-plans/$planId/coach-review',
      queryParameters: {'user_id': userId},
    );
    return CoachReview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CoachReview?> latestReview(CoachReviewSubject subjectType, String subjectId) async {
    final res = await _client.get(
      '/nutrition/coach-reviews/latest',
      queryParameters: {'subject_type': subjectType.value, 'subject_id': subjectId},
    );
    if (res.data == null) return null;
    return CoachReview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> requestHumanProReview(String reviewId) async {
    await _client.post('/nutrition/coach-reviews/$reviewId/request-human-pro');
  }

  // ============================================================
  // COOK EVENTS
  // ============================================================

  Future<CookEvent> createCookEvent(String userId, CookEventCreate req) async {
    final res = await _client.post(
      '/nutrition/cook-events',
      queryParameters: {'user_id': userId},
      data: req.toJson(),
    );
    return CookEvent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActiveCookEvent>> activeCookEvents(String userId) async {
    final res = await _client.get(
      '/nutrition/cook-events/active',
      queryParameters: {'user_id': userId},
    );
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => ActiveCookEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CookEvent> updateCookEvent(String eventId, Map<String, dynamic> patch) async {
    final res = await _client.patch('/nutrition/cook-events/$eventId', data: patch);
    return CookEvent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCookEvent(String eventId) async {
    await _client.delete('/nutrition/cook-events/$eventId');
  }

  // ============================================================
  // GROCERY LISTS
  // ============================================================

  Future<GroceryList> buildGroceryList(String userId, GroceryListCreate req) async {
    final res = await _client.post(
      '/nutrition/grocery-lists',
      queryParameters: {'user_id': userId},
      data: req.toJson(),
    );
    return GroceryList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GroceryListSummary>> listGroceryLists(String userId) async {
    final res = await _client.get(
      '/nutrition/grocery-lists',
      queryParameters: {'user_id': userId},
    );
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => GroceryListSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroceryList> getGroceryList(String listId) async {
    final res = await _client.get('/nutrition/grocery-lists/$listId');
    return GroceryList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroceryListItem> updateGroceryItem(
    String listId,
    String itemId,
    Map<String, dynamic> patch,
  ) async {
    final res = await _client.patch(
      '/nutrition/grocery-lists/$listId/items/$itemId',
      data: patch,
    );
    return GroceryListItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroceryListItem> addGroceryItem(String listId, Map<String, dynamic> item) async {
    final res = await _client.post('/nutrition/grocery-lists/$listId/items', data: item);
    return GroceryListItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteGroceryItem(String listId, String itemId) async {
    await _client.delete('/nutrition/grocery-lists/$listId/items/$itemId');
  }

  Future<String> exportGroceryList(String listId, {String format = 'text'}) async {
    final res = await _client.get(
      '/nutrition/grocery-lists/$listId/export',
      queryParameters: {'format': format},
    );
    return (res.data ?? '').toString();
  }

  // ============================================================
  // MEAL PLANS
  // ============================================================

  Future<MealPlan> createMealPlan(String userId, MealPlanCreate req) async {
    final res = await _client.post(
      '/nutrition/meal-plans',
      queryParameters: {'user_id': userId},
      data: req.toJson(),
    );
    return MealPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MealPlan>> listMealPlans(
    String userId, {
    DateTime? planDate,
    bool templatesOnly = false,
  }) async {
    final res = await _client.get(
      '/nutrition/meal-plans',
      queryParameters: {
        'user_id': userId,
        if (planDate != null)
          'plan_date': '${planDate.year.toString().padLeft(4, '0')}-'
              '${planDate.month.toString().padLeft(2, '0')}-'
              '${planDate.day.toString().padLeft(2, '0')}',
        if (templatesOnly) 'templates_only': true,
      },
    );
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealPlan> getMealPlan(String planId) async {
    final res = await _client.get('/nutrition/meal-plans/$planId');
    return MealPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MealPlan> updateMealPlan(String planId, Map<String, dynamic> patch) async {
    final res = await _client.patch('/nutrition/meal-plans/$planId', data: patch);
    return MealPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteMealPlan(String planId) async {
    await _client.delete('/nutrition/meal-plans/$planId');
  }

  Future<MealPlanItem> addPlanItem(String planId, MealPlanItemCreate item) async {
    final res = await _client.post(
      '/nutrition/meal-plans/$planId/items',
      data: item.toJson(),
    );
    return MealPlanItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> removePlanItem(String planId, String itemId) async {
    await _client.delete('/nutrition/meal-plans/$planId/items/$itemId');
  }

  Future<SimulateResponse> simulatePlan(String planId, {bool withSwaps = true}) async {
    final res = await _client.post(
      '/nutrition/meal-plans/$planId/simulate',
      queryParameters: {'with_swaps': withSwaps},
    );
    return SimulateResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ApplyResponse> applyPlan(String planId, DateTime targetDate) async {
    final dateStr = '${targetDate.year.toString().padLeft(4, '0')}-'
        '${targetDate.month.toString().padLeft(2, '0')}-'
        '${targetDate.day.toString().padLeft(2, '0')}';
    final res = await _client.post(
      '/nutrition/meal-plans/$planId/apply',
      queryParameters: {'target_date': dateStr},
    );
    return ApplyResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // SCHEDULED RECIPES
  // ============================================================

  Future<ScheduledRecipeLog> createSchedule(
    String userId,
    ScheduledRecipeLogCreate req,
  ) async {
    final res = await _client.post(
      '/nutrition/scheduled-recipes',
      queryParameters: {'user_id': userId},
      data: req.toJson(),
    );
    return ScheduledRecipeLog.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ScheduledRecipeLog>> listSchedules(String userId, {bool enabledOnly = true}) async {
    final res = await _client.get(
      '/nutrition/scheduled-recipes',
      queryParameters: {'user_id': userId, 'enabled_only': enabledOnly},
    );
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => ScheduledRecipeLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UpcomingScheduledFire>> upcomingSchedules(String userId, {int days = 7}) async {
    final res = await _client.get(
      '/nutrition/scheduled-recipes/upcoming',
      queryParameters: {'user_id': userId, 'days': days},
    );
    return (res.data as List)
        .map((e) => UpcomingScheduledFire.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduledRecipeLog> updateSchedule(
    String scheduleId,
    Map<String, dynamic> patch,
  ) async {
    final res = await _client.patch('/nutrition/scheduled-recipes/$scheduleId', data: patch);
    return ScheduledRecipeLog.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ScheduledRecipeLog> pauseSchedule(String scheduleId, {DateTime? until}) async {
    final res = await _client.post(
      '/nutrition/scheduled-recipes/$scheduleId/pause',
      queryParameters: {
        if (until != null)
          'until': '${until.year.toString().padLeft(4, '0')}-'
              '${until.month.toString().padLeft(2, '0')}-'
              '${until.day.toString().padLeft(2, '0')}',
      },
    );
    return ScheduledRecipeLog.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _client.delete('/nutrition/scheduled-recipes/$scheduleId');
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  /// Toggle a favorite on/off. Backend accepts POST to mark and DELETE to
  /// unmark; returns the new favorited state.
  Future<bool> toggleFavorite(String recipeId, {required bool favorite}) async {
    if (favorite) {
      await _client.post('/nutrition/recipes/$recipeId/favorite');
      return true;
    }
    await _client.delete('/nutrition/recipes/$recipeId/favorite');
    return false;
  }

  /// List the current user's favorite recipes.
  Future<RecipesResponse> listFavorites(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/nutrition/recipes/favorites',
      queryParameters: {
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      },
    );
    return RecipesResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // DISCOVER (curated + public)
  // ============================================================

  /// Browse the curated / discover feed. Does NOT require a user_id; the
  /// backend surfaces shared + public recipes with optional category filter
  /// and server-side sorting.
  Future<RecipesResponse> listDiscover({
    String? category,
    String sort = 'most_logged',
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/nutrition/recipes/discover',
      queryParameters: {
        if (category != null) 'category': category,
        'sort': sort,
        'limit': limit,
        'offset': offset,
      },
    );
    return RecipesResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================================
  // IMPROVIZE (clone + AI-variation)
  // ============================================================

  /// Clone a curated/shared recipe into the user's library with an
  /// AI-generated "improvized" variation. Returns the new Recipe.
  Future<Recipe> improvize(String recipeId) async {
    final res = await _client.post('/nutrition/recipes/$recipeId/improvize');
    return Recipe.fromJson(res.data as Map<String, dynamic>);
  }
}
