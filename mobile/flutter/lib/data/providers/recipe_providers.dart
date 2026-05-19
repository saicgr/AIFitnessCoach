/// Riverpod providers for the Recipes Tab v1 feature set.
///
/// One file consolidating: recipes index, search, meal planner, scheduled
/// reminders, cook events (leftovers), grocery lists, coach reviews,
/// versions, sharing, public deep-link resolution, and import streams.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_first_mixin.dart';
import '../models/coach_review.dart';
import '../models/cook_event.dart';
import '../models/grocery_list.dart';
import '../models/ingredient_analysis.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/recipe_share.dart';
import '../models/recipe_version.dart';
import '../models/scheduled_recipe.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/recipe_repository.dart';

// ============================================================
// Search
// ============================================================

class RecipeSearchArgs {
  final String userId;
  final String query;
  final String scope;
  final String? category;
  final String? cuisine;
  final bool hasLeftovers;
  // New Discover/Favorites filters.
  final List<String>? sourceTypeIn;
  final bool? isFavorite;
  final String? sortBy;

  const RecipeSearchArgs({
    required this.userId,
    required this.query,
    this.scope = 'mine',
    this.category,
    this.cuisine,
    this.hasLeftovers = false,
    this.sourceTypeIn = const [],
    this.isFavorite,
    this.sortBy,
  });

  RecipeSearchArgs copyWith({
    String? userId,
    String? query,
    String? scope,
    String? category,
    String? cuisine,
    bool? hasLeftovers,
    List<String>? sourceTypeIn,
    bool? isFavorite,
    String? sortBy,
  }) {
    return RecipeSearchArgs(
      userId: userId ?? this.userId,
      query: query ?? this.query,
      scope: scope ?? this.scope,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      hasLeftovers: hasLeftovers ?? this.hasLeftovers,
      sourceTypeIn: sourceTypeIn ?? this.sourceTypeIn,
      isFavorite: isFavorite ?? this.isFavorite,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecipeSearchArgs &&
      other.userId == userId &&
      other.query == query &&
      other.scope == scope &&
      other.category == category &&
      other.cuisine == cuisine &&
      other.hasLeftovers == hasLeftovers &&
      _listEq(other.sourceTypeIn, sourceTypeIn) &&
      other.isFavorite == isFavorite &&
      other.sortBy == sortBy;

  @override
  int get hashCode => Object.hash(
        userId,
        query,
        scope,
        category,
        cuisine,
        hasLeftovers,
        sourceTypeIn?.join(','),
        isFavorite,
        sortBy,
      );

  static bool _listEq(List? a, List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final recipeSearchProvider =
    FutureProvider.autoDispose.family<RecipesResponse, RecipeSearchArgs>((ref, args) async {
  if (args.query.trim().length < 2) {
    return const RecipesResponse(items: [], totalCount: 0);
  }
  // Keep result cached after the widget un-watches so tab re-entry or re-
  // applying the same filter combo shows instantly. Without this every
  // return to the Recipes tab re-fetched and flashed a spinner.
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).search(
        args.userId,
        query: args.query,
        scope: args.scope,
        category: args.category,
        cuisine: args.cuisine,
        hasLeftovers: args.hasLeftovers,
        sourceTypeIn: args.sourceTypeIn,
        isFavorite: args.isFavorite,
        sortBy: args.sortBy,
      );
});

// ============================================================
// My Recipes list (fast-path — cheap /recipes endpoint, no search)
// ============================================================

/// Args for the plain list endpoint. Keyed on (userId, category) so the same
/// tab re-enter or filter-chip switch rehydrates from cache instead of
/// firing a fresh network round-trip.
class MyRecipesListArgs {
  final String userId;
  final String? category;
  const MyRecipesListArgs({required this.userId, this.category});

  @override
  bool operator ==(Object other) =>
      other is MyRecipesListArgs &&
      other.userId == userId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(userId, category);
}

/// Replaces the `FutureBuilder` that used to live inside `_MyRecipesGrid` —
/// that path rebuilt a new Future on every widget rebuild (typing in filters,
/// selecting pills, keyboard appearing), so the grid flashed a spinner on
/// every state change. Riverpod caches the response under the args key and
/// `ref.keepAlive()` keeps it warm between Nutrition-tab visits.
final myRecipesListProvider = FutureProvider.autoDispose
    .family<RecipesResponse, MyRecipesListArgs>((ref, args) {
  ref.keepAlive();
  return ref.watch(nutritionRepositoryProvider).getRecipes(
        userId: args.userId,
        category: args.category,
        limit: 100,
      );
});

// ============================================================
// Discover / Favorites (list providers)
// ============================================================

/// Args for the Discover feed (curated + public recipes).
class DiscoverArgs {
  final String? category;
  final String sort; // 'most_logged' | 'created_desc' | 'name_asc'
  const DiscoverArgs({this.category, this.sort = 'most_logged'});

  @override
  bool operator ==(Object other) =>
      other is DiscoverArgs && other.category == category && other.sort == sort;
  @override
  int get hashCode => Object.hash(category, sort);
}

final discoverRecipesProvider =
    FutureProvider.autoDispose.family<RecipesResponse, DiscoverArgs>((ref, args) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).listDiscover(
        category: args.category,
        sort: args.sort,
      );
});

/// Favorites list for a given user (server-backed).
final favoriteRecipesProvider =
    FutureProvider.autoDispose.family<RecipesResponse, String>((ref, userId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).listFavorites(userId);
});

// ============================================================
// Cache-first (instant-load) list notifiers — Part-2 instant-load standard.
//
// The `discoverRecipesProvider` / `favoriteRecipesProvider` FutureProviders
// above are kept untouched (other screens — saved_hub, fasting_saved_row —
// still consume them). The notifiers below are dedicated to the owned recipe
// screens: they persist their last good payload to disk via [CacheFirstMixin]
// so a cold app start renders the previous grid INSTANTLY, then silently
// revalidates against the network (stale-while-revalidate).
// ============================================================

/// A `StateNotifier<AsyncValue<RecipesResponse>>` that loads cache-first.
///
/// On construction it kicks off [load]: a valid disk blob is emitted first
/// (so the screen paints instantly with no spinner), then the network result
/// replaces it and is written through for the next cold start.
class RecipeListNotifier extends StateNotifier<AsyncValue<RecipesResponse>>
    with CacheFirstMixin {
  RecipeListNotifier({
    required this.cacheKey,
    required this.userId,
    required Future<RecipesResponse> Function() fetch,
  })  : _fetch = fetch,
        super(const AsyncLoading()) {
    load();
  }

  /// Base SharedPreferences slot name (user-scope + schema version appended by
  /// the mixin). Distinct per logical feed (discover args / favorites).
  final String cacheKey;

  /// Owning user — required so two accounts on one device never share a slot.
  final String userId;

  /// Produces the fresh value from the network.
  final Future<RecipesResponse> Function() _fetch;

  /// Run the cache-first load. Safe to call again for an explicit refresh.
  Future<void> load() => loadCacheFirst<RecipesResponse>(
        cacheKey: cacheKey,
        userId: userId,
        // 6h TTL: recipe feeds change slowly; a stale-but-recent grid is fine
        // to flash for one frame before the silent revalidate lands.
        ttl: const Duration(hours: 6),
        fetch: _fetch,
        decode: RecipesResponse.fromJson,
        encode: (r) => r.toJson(),
        emit: (data, {required bool fromCache}) {
          // Never downgrade fresh data back to a cached value: if the network
          // result already landed, ignore a late cache emit (can't happen with
          // the mixin's ordering, but defensive).
          if (!mounted) return;
          state = AsyncData(data);
        },
        onError: (e, st) {
          // Only surface a hard error when we have NOTHING cached to show —
          // otherwise the screen keeps the stale grid and silently retries
          // next open.
          if (!mounted) return;
          if (state.valueOrNull == null) {
            state = AsyncError(e, st);
          }
        },
      );

  /// Force a fresh network read (e.g. pull-to-refresh). Keeps the current grid
  /// on screen while revalidating.
  Future<void> refresh() => load();
}

/// Cache-first Discover feed, keyed by [DiscoverArgs]. Dedicated to
/// `DiscoverScreen`; renders the last grid instantly on cold start.
final discoverRecipesCacheFirstProvider = StateNotifierProvider.autoDispose
    .family<RecipeListNotifier, AsyncValue<RecipesResponse>, DiscoverArgs>(
  (ref, args) {
    ref.keepAlive();
    final repo = ref.watch(recipeRepositoryProvider);
    return RecipeListNotifier(
      // Slot name embeds the filter combo so each category/sort pair has its
      // own cached grid (switching chips still instant after the first visit).
      cacheKey: 'recipes_discover::${args.category ?? "all"}::${args.sort}',
      // Discover is not per-user; share one slot across accounts.
      userId: '_discover',
      fetch: () => repo.listDiscover(category: args.category, sort: args.sort),
    );
  },
);

/// Cache-first Favorites feed, keyed by userId. Dedicated to `FavoritesScreen`.
final favoriteRecipesCacheFirstProvider = StateNotifierProvider.autoDispose
    .family<RecipeListNotifier, AsyncValue<RecipesResponse>, String>(
  (ref, userId) {
    ref.keepAlive();
    final repo = ref.watch(recipeRepositoryProvider);
    return RecipeListNotifier(
      cacheKey: 'recipes_favorites',
      userId: userId,
      fetch: () => repo.listFavorites(userId),
    );
  },
);

// ============================================================
// Meal Planner
// ============================================================

class MealPlanArgs {
  final String userId;
  final DateTime date;
  const MealPlanArgs({required this.userId, required this.date});
  @override
  bool operator ==(Object other) =>
      other is MealPlanArgs && other.userId == userId && _sameDay(other.date, date);
  @override
  int get hashCode => Object.hash(userId, date.year, date.month, date.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Returns the FIRST plan for the date if any exists; null otherwise.
final mealPlanForDateProvider =
    FutureProvider.autoDispose.family<MealPlan?, MealPlanArgs>((ref, args) async {
  final plans = await ref
      .watch(recipeRepositoryProvider)
      .listMealPlans(args.userId, planDate: args.date);
  return plans.isNotEmpty ? plans.first : null;
});

final mealPlanByIdProvider =
    FutureProvider.autoDispose.family<MealPlan, String>((ref, planId) {
  return ref.watch(recipeRepositoryProvider).getMealPlan(planId);
});

final simulatePlanProvider =
    FutureProvider.autoDispose.family<SimulateResponse, String>((ref, planId) {
  return ref.watch(recipeRepositoryProvider).simulatePlan(planId);
});

// ============================================================
// Scheduled recipes / upcoming reminders
// ============================================================

final upcomingSchedulesProvider =
    FutureProvider.autoDispose.family<List<UpcomingScheduledFire>, String>((ref, userId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).upcomingSchedules(userId, days: 7);
});

final allSchedulesProvider =
    FutureProvider.autoDispose.family<List<ScheduledRecipeLog>, String>((ref, userId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).listSchedules(userId, enabledOnly: false);
});

// ============================================================
// Cook events / leftovers
// ============================================================

final activeCookEventsProvider =
    FutureProvider.autoDispose.family<List<ActiveCookEvent>, String>((ref, userId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).activeCookEvents(userId);
});

// ============================================================
// Grocery lists
// ============================================================

final groceryListsProvider =
    FutureProvider.autoDispose.family<List<GroceryListSummary>, String>((ref, userId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).listGroceryLists(userId);
});

final groceryListByIdProvider =
    FutureProvider.autoDispose.family<GroceryList, String>((ref, listId) {
  ref.keepAlive();
  return ref.watch(recipeRepositoryProvider).getGroceryList(listId);
});

// ============================================================
// Coach reviews
// ============================================================

class CoachReviewLookup {
  final CoachReviewSubject subjectType;
  final String subjectId;
  const CoachReviewLookup({required this.subjectType, required this.subjectId});
  @override
  bool operator ==(Object other) =>
      other is CoachReviewLookup &&
      other.subjectType == subjectType &&
      other.subjectId == subjectId;
  @override
  int get hashCode => Object.hash(subjectType, subjectId);
}

final coachReviewProvider =
    FutureProvider.autoDispose.family<CoachReview?, CoachReviewLookup>((ref, key) {
  return ref.watch(recipeRepositoryProvider).latestReview(key.subjectType, key.subjectId);
});

// ============================================================
// Versions
// ============================================================

final recipeVersionsProvider =
    FutureProvider.autoDispose.family<RecipeVersionsResponse, String>((ref, recipeId) {
  return ref.watch(recipeRepositoryProvider).listVersions(recipeId);
});

// ============================================================
// Sharing / public resolution
// ============================================================

final publicRecipeProvider =
    FutureProvider.autoDispose.family<PublicRecipeView, String>((ref, slug) {
  return ref.watch(recipeRepositoryProvider).resolveShare(slug);
});

// ============================================================
// Pantry suggestions
// ============================================================

class PantryRequest {
  final String userId;
  final List<String>? itemsText;
  final String? imageB64;
  final String? mealType;
  final int count;
  const PantryRequest({
    required this.userId,
    this.itemsText,
    this.imageB64,
    this.mealType,
    this.count = 3,
  });
  @override
  bool operator ==(Object other) =>
      other is PantryRequest &&
      other.userId == userId &&
      other.imageB64 == imageB64 &&
      other.mealType == mealType &&
      other.count == count &&
      _listEq(other.itemsText, itemsText);
  @override
  int get hashCode => Object.hash(userId, imageB64, mealType, count, itemsText?.join(','));
  static bool _listEq(List? a, List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final pantrySuggestionsProvider =
    FutureProvider.autoDispose.family<PantryAnalyzeResponse, PantryRequest>((ref, req) {
  return ref.watch(recipeRepositoryProvider).fromPantry(
        req.userId,
        itemsText: req.itemsText,
        imageB64: req.imageB64,
        mealType: req.mealType,
        count: req.count,
      );
});

// ============================================================
// Recent searches (in-memory; Drift-backed persistence is a follow-up)
// ============================================================

class RecipeSearchHistory extends StateNotifier<List<String>> {
  RecipeSearchHistory() : super(const []);

  static const _max = 5;

  void push(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    final next = [q, ...state.where((s) => s != q)].take(_max).toList();
    state = next;
  }

  void clear() => state = const [];
}

final recipeSearchHistoryProvider =
    StateNotifierProvider<RecipeSearchHistory, List<String>>(
        (ref) => RecipeSearchHistory());
