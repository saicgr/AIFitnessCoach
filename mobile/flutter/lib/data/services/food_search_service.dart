import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/nutrition_repository.dart';
import '../models/nutrition.dart';
import 'api_client.dart';

enum FoodModifierType {
  addon,
  removal,
  cookingMethod,
  doneness,
  sizePortion,
  qualityLabel,
  stateTemp;

  static FoodModifierType fromString(String value) {
    switch (value) {
      case 'addon': return FoodModifierType.addon;
      case 'removal': return FoodModifierType.removal;
      case 'cooking_method': return FoodModifierType.cookingMethod;
      case 'doneness': return FoodModifierType.doneness;
      case 'size_portion': return FoodModifierType.sizePortion;
      case 'quality_label': return FoodModifierType.qualityLabel;
      case 'state_temp': return FoodModifierType.stateTemp;
      default: return FoodModifierType.addon;
    }
  }
}

class ModifierGroupOption {
  final String phrase;
  final String label;
  final int calDelta;

  const ModifierGroupOption({required this.phrase, required this.label, required this.calDelta});

  factory ModifierGroupOption.fromJson(Map<String, dynamic> json) {
    return ModifierGroupOption(
      phrase: json['phrase'] as String? ?? '',
      label: json['label'] as String? ?? '',
      calDelta: (json['cal_delta'] as num?)?.toInt() ?? 0,
    );
  }
}

class NutrientPerGram {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const NutrientPerGram({
    required this.calories, required this.proteinG,
    required this.carbsG, required this.fatG, required this.fiberG,
  });

  factory NutrientPerGram.fromJson(Map<String, dynamic> json) {
    return NutrientPerGram(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FoodModifier {
  final String phrase;
  final FoodModifierType type;
  final String? displayLabel;
  final Map<String, double> delta;
  final double? defaultWeightG;
  final double? weightPerUnitG;
  final String? unitName;
  final NutrientPerGram? perGram;
  final String? group;
  final List<ModifierGroupOption> groupOptions;

  const FoodModifier({
    required this.phrase,
    required this.type,
    this.displayLabel,
    required this.delta,
    this.defaultWeightG,
    this.weightPerUnitG,
    this.unitName,
    this.perGram,
    this.group,
    this.groupOptions = const [],
  });

  factory FoodModifier.fromJson(Map<String, dynamic> json) {
    final deltaRaw = json['delta'] as Map<String, dynamic>? ?? {};
    final delta = <String, double>{};
    for (final entry in deltaRaw.entries) {
      delta[entry.key] = (entry.value as num?)?.toDouble() ?? 0;
    }

    return FoodModifier(
      phrase: json['phrase'] as String? ?? '',
      type: FoodModifierType.fromString(json['type'] as String? ?? 'addon'),
      displayLabel: json['display_label'] as String?,
      delta: delta,
      defaultWeightG: (json['default_weight_g'] as num?)?.toDouble(),
      weightPerUnitG: (json['weight_per_unit_g'] as num?)?.toDouble(),
      unitName: json['unit_name'] as String?,
      perGram: json['per_gram'] != null
          ? NutrientPerGram.fromJson(json['per_gram'] as Map<String, dynamic>)
          : null,
      group: json['group'] as String?,
      groupOptions: (json['group_options'] as List<dynamic>?)
          ?.map((e) => ModifierGroupOption.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// A single food item from NL analysis
class NLFoodItem {
  final String name;
  final String? amount;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? weightG;
  final String? weightSource;
  final String? unit;
  final Map<String, dynamic>? aiPerGram;
  final List<FoodModifier> modifiers;

  const NLFoodItem({
    required this.name,
    this.amount,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.weightG,
    this.weightSource,
    this.unit,
    this.aiPerGram,
    this.modifiers = const [],
  });

  factory NLFoodItem.fromJson(Map<String, dynamic> json) {
    return NLFoodItem(
      name: json['name'] as String? ?? 'Unknown',
      amount: json['amount'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      weightG: (json['weight_g'] as num?)?.toDouble(),
      weightSource: json['weight_source'] as String?,
      unit: json['unit'] as String?,
      aiPerGram: json['ai_per_gram'] as Map<String, dynamic>?,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.map((e) => FoodModifier.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (amount != null) 'amount': amount,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    if (fiberG != null) 'fiber_g': fiberG,
    if (weightG != null) 'weight_g': weightG,
    if (weightSource != null) 'weight_source': weightSource,
    if (unit != null) 'unit': unit,
    if (aiPerGram != null) 'ai_per_gram': aiPerGram,
    if (modifiers.isNotEmpty) 'modifiers': modifiers.map((m) => {'phrase': m.phrase, 'type': m.type.name}).toList(),
  };
}

/// AI review for a food item (from POST /nutrition/food-review)
class FoodReview {
  final List<String> encouragements;
  final List<String> warnings;
  final String? aiSuggestion;
  final String? recommendedSwap;
  final int? healthScore;

  const FoodReview({
    this.encouragements = const [],
    this.warnings = const [],
    this.aiSuggestion,
    this.recommendedSwap,
    this.healthScore,
  });

  factory FoodReview.fromJson(Map<String, dynamic> json) {
    return FoodReview(
      encouragements: (json['encouragements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      aiSuggestion: json['ai_suggestion'] as String?,
      recommendedSwap: json['recommended_swap'] as String?,
      healthScore: (json['health_score'] as num?)?.toInt(),
    );
  }
}

/// Wrapper for the NL analyze-text endpoint response
class FoodAnalysisResult {
  final List<NLFoodItem> foodItems;
  final int totalCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final String? dataSource;
  final bool cacheHit;
  final String? cacheSource;
  // AI review fields (parsed from NL response if present)
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? aiSuggestion;
  final String? recommendedSwap;
  final int? healthScore;

  const FoodAnalysisResult({
    required this.foodItems,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.dataSource,
    this.cacheHit = false,
    this.cacheSource,
    this.encouragements,
    this.warnings,
    this.aiSuggestion,
    this.recommendedSwap,
    this.healthScore,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final items = (json['food_items'] as List<dynamic>?)
        ?.map((e) => NLFoodItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    return FoodAnalysisResult(
      foodItems: items,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      dataSource: json['data_source'] as String?,
      cacheHit: json['cache_hit'] as bool? ?? false,
      cacheSource: json['cache_source'] as String?,
      encouragements: (json['encouragements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      aiSuggestion: json['ai_suggestion'] as String?,
      recommendedSwap: json['recommended_swap'] as String?,
      healthScore: (json['health_score'] as num?)?.toInt(),
    );
  }
}

/// Result model for food search
class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? servingSize;
  final FoodSearchSource source;
  final double? distance; // For similarity ranking (lower = more similar)
  final Map<String, dynamic>? originalData;
  final double? weightPerUnitG; // Weight of 1 piece (e.g. 1 burger = 219g)
  final int? defaultCount; // Default number of pieces (e.g. 10 for 10pc nuggets)
  final double? servingWeightG; // Standard serving weight in grams
  final String? matchedQuery; // Which sub-query matched (for multi-food queries)

  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.servingSize,
    required this.source,
    this.distance,
    this.originalData,
    this.weightPerUnitG,
    this.defaultCount,
    this.servingWeightG,
    this.matchedQuery,
  });

  /// Create from SavedFood model
  factory FoodSearchResult.fromSavedFood(SavedFood saved) {
    return FoodSearchResult(
      id: saved.id,
      name: saved.name,
      calories: saved.totalCalories ?? 0,
      protein: saved.totalProteinG,
      carbs: saved.totalCarbsG,
      fat: saved.totalFatG,
      source: FoodSearchSource.saved,
      originalData: saved.toJson(),
    );
  }

  /// Create from FoodLog model (recent)
  factory FoodSearchResult.fromFoodLog(FoodLog log) {
    // Get primary food name from items
    final primaryFood = log.foodItems.isNotEmpty
        ? log.foodItems.first.name
        : log.mealType;

    return FoodSearchResult(
      id: log.id,
      name: primaryFood,
      calories: log.totalCalories,
      protein: log.proteinG,
      carbs: log.carbsG,
      fat: log.fatG,
      source: FoodSearchSource.recent,
      originalData: log.toJson(),
    );
  }

  /// Create from barcode product
  factory FoodSearchResult.fromBarcodeProduct(BarcodeProduct product) {
    return FoodSearchResult(
      id: product.barcode,
      name: product.productName,
      brand: product.brand,
      calories: product.caloriesPer100g.round(),
      protein: product.proteinPer100g,
      carbs: product.carbsPer100g,
      fat: product.fatPer100g,
      servingSize: product.servingSizeG != null
          ? '${product.servingSizeG!.round()}g'
          : '100g',
      source: FoodSearchSource.barcode,
      originalData: product.toJson(),
    );
  }

  /// Create from semantic search result (RAG)
  factory FoodSearchResult.fromSearchResult(Map<String, dynamic> result) {
    return FoodSearchResult(
      id: result['id'] as String,
      name: result['name'] as String? ?? 'Unknown',
      calories: (result['total_calories'] as num?)?.toInt() ?? 0,
      protein: (result['total_protein_g'] as num?)?.toDouble(),
      source: FoodSearchSource.database,
      distance: (result['distance'] as num?)?.toDouble(),
      originalData: result,
    );
  }
}

/// Source of the food search result
enum FoodSearchSource {
  saved('Saved'),
  recent('Recent'),
  database('Database'),
  barcode('Barcode'),
  foodDatabase('Food DB');

  final String label;
  const FoodSearchSource(this.label);
}

/// Search state for UI
sealed class FoodSearchState {
  const FoodSearchState();
}

class FoodSearchInitial extends FoodSearchState {
  const FoodSearchInitial();
}

class FoodSearchLoading extends FoodSearchState {
  final String query;
  const FoodSearchLoading(this.query);
}

class FoodSearchResults extends FoodSearchState {
  final String query;
  final List<FoodSearchResult> saved;
  final List<FoodSearchResult> recent;
  final List<FoodSearchResult> database;
  final List<FoodSearchResult> foodDatabase;
  final bool fromCache;
  final int? searchTimeMs;

  const FoodSearchResults({
    required this.query,
    this.saved = const [],
    this.recent = const [],
    this.database = const [],
    this.foodDatabase = const [],
    this.fromCache = false,
    this.searchTimeMs,
  });

  bool get isEmpty =>
      saved.isEmpty &&
      recent.isEmpty &&
      database.isEmpty &&
      foodDatabase.isEmpty;

  int get totalCount =>
      saved.length + recent.length + database.length + foodDatabase.length;

  List<FoodSearchResult> get allResults =>
      [...saved, ...recent, ...database, ...foodDatabase];
}

class FoodSearchError extends FoodSearchState {
  final String message;
  final String query;
  const FoodSearchError(this.message, this.query);
}

/// State: NL analysis is loading
class FoodSearchNLLoading extends FoodSearchState {
  final String query;
  const FoodSearchNLLoading(this.query);
}

/// State: NL analysis returned results
class FoodSearchNLResults extends FoodSearchState {
  final String query;
  final FoodAnalysisResult result;
  const FoodSearchNLResults({required this.query, required this.result});
}

/// State: NL analysis errored
class FoodSearchNLError extends FoodSearchState {
  final String message;
  final String query;
  const FoodSearchNLError(this.message, this.query);
}

/// LRU Cache entry with timestamp
class _CacheEntry {
  final FoodSearchResults results;
  final DateTime timestamp;

  _CacheEntry(this.results) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

/// Food search service with debouncing and caching
class FoodSearchService {
  final NutritionRepository _nutritionRepository;
  final ApiClient _apiClient;

  // LRU cache for recent searches
  final Map<String, _CacheEntry> _cache = {};
  static const int _maxCacheSize = 50;

  // Debounce timer
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 600);

  // Stream controller for real-time search updates
  final _searchController = StreamController<FoodSearchState>.broadcast();

  // AI review stream + timer
  final _reviewController = StreamController<FoodReview?>.broadcast();
  Timer? _reviewTimer;

  // Current query to prevent stale results
  String? _currentQuery;

  // Last search timing from backend (ms)
  int? _lastSearchTimeMs;

  // Current database source filter
  String? _currentSource;

  FoodSearchService({
    required NutritionRepository nutritionRepository,
    required ApiClient apiClient,
  })  : _nutritionRepository = nutritionRepository,
        _apiClient = apiClient;

  /// Stream of search states for UI binding
  Stream<FoodSearchState> get searchStream => _searchController.stream;

  /// Stream of AI review states
  Stream<FoodReview?> get reviewStream => _reviewController.stream;

  /// Get cached results without triggering a search
  FoodSearchResults? getCachedResults(String query) {
    final normalizedQuery = _normalizeQuery(query);
    final entry = _cache[_cacheKey(normalizedQuery)];
    if (entry != null && !entry.isExpired) {
      return entry.results;
    }
    return null;
  }

  /// Set database source filter for food database search
  void setSource(String? source) {
    _currentSource = source;
  }

  /// Fetch dynamic food modifiers for a specific food from backend.
  Future<List<FoodModifier>> getFoodModifiers(String foodName) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/food-modifiers',
        queryParameters: {'food_name': foodName},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final mods = (data['modifiers'] as List<dynamic>?)
            ?.map((e) => FoodModifier.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        return mods;
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ getFoodModifiers error: $e');
      return [];
    }
  }

  /// Search for food modifiers (addons, cooking methods, etc.)
  Future<List<FoodModifier>> searchModifiers(String query, String userId) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/modifier-search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => FoodModifier.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Modifier search error: $e');
      return [];
    }
  }

  /// Cache key combining query and source filter
  String _cacheKey(String normalizedQuery) {
    if (_currentSource != null) {
      return '$normalizedQuery|$_currentSource';
    }
    return normalizedQuery;
  }

  /// Minimum query length to trigger a search — shorter queries produce
  /// too many generic/irrelevant results and waste network calls.
  static const int _minQueryLength = 3;

  /// Search with debouncing
  /// Pass [cachedLogs] from NutritionState.recentLogs to avoid an API call
  /// for recent foods filtering.
  void search(String query, String userId, {List<FoodLog>? cachedLogs}) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    final normalizedQuery = _normalizeQuery(query);
    _currentQuery = normalizedQuery;

    // Empty query - return to initial state
    if (normalizedQuery.isEmpty) {
      _searchController.add(const FoodSearchInitial());
      return;
    }

    // Too-short queries — stay idle, no local match, no API call
    if (normalizedQuery.length < _minQueryLength) {
      return;
    }

    // Check cache first for instant results
    final cacheKey = _cacheKey(normalizedQuery);
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      debugPrint('FoodSearch: Cache hit for "$normalizedQuery"');
      _searchController.add(FoodSearchResults(
        query: normalizedQuery,
        saved: cachedEntry.results.saved,
        recent: cachedEntry.results.recent,
        database: cachedEntry.results.database,
        foodDatabase: cachedEntry.results.foodDatabase,
        fromCache: true,
        searchTimeMs: cachedEntry.results.searchTimeMs,
      ));
      return;
    }

    // Show local recent matches instantly (no debounce, no network)
    if (cachedLogs != null && cachedLogs.isNotEmpty) {
      final instantRecent = _filterRecentFoodsSync(normalizedQuery, cachedLogs);
      if (instantRecent.isNotEmpty) {
        _searchController.add(FoodSearchResults(
          query: normalizedQuery,
          recent: instantRecent,
          saved: const [],
          foodDatabase: const [],
        ));
      } else {
        _searchController.add(FoodSearchLoading(normalizedQuery));
      }
    } else {
      _searchController.add(FoodSearchLoading(normalizedQuery));
    }

    // Debounce the backend API call
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(normalizedQuery, userId, cachedLogs: cachedLogs);
    });
  }

  /// Trigger search immediately (bypass debounce) — for manual search button.
  void searchImmediate(String query, String userId, {List<FoodLog>? cachedLogs}) {
    _debounceTimer?.cancel();
    final normalizedQuery = _normalizeQuery(query);
    _currentQuery = normalizedQuery;
    if (normalizedQuery.length < _minQueryLength) return;

    // Check cache first
    final cacheKey = _cacheKey(normalizedQuery);
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      _searchController.add(FoodSearchResults(
        query: normalizedQuery,
        saved: cachedEntry.results.saved,
        recent: cachedEntry.results.recent,
        database: cachedEntry.results.database,
        foodDatabase: cachedEntry.results.foodDatabase,
        fromCache: true,
        searchTimeMs: cachedEntry.results.searchTimeMs,
      ));
      return;
    }

    _searchController.add(FoodSearchLoading(normalizedQuery));
    _performSearch(normalizedQuery, userId, cachedLogs: cachedLogs);
  }

  /// Synchronous filter of cached food logs — runs instantly on the UI thread.
  /// Reuses [_fuzzyMatch] but does no async work or API calls.
  List<FoodSearchResult> _filterRecentFoodsSync(
      String query, List<FoodLog> logs) {
    final matching = <FoodSearchResult>[];
    for (final log in logs) {
      if (_fuzzyMatch(log.mealType, query) ||
          log.foodItems.any((item) => _fuzzyMatch(item.name, query))) {
        matching.add(FoodSearchResult.fromFoodLog(log));
        if (matching.length >= 5) break;
      }
    }
    return matching;
  }

  /// Per-source error isolation — one failing source doesn't kill all results
  Future<List<FoodSearchResult>> _safeSearch(
    Future<List<FoodSearchResult>> Function() search,
    String label,
  ) async {
    try {
      return await search();
    } catch (e) {
      debugPrint('FoodSearch: $label error: $e');
      return [];
    }
  }

  /// Perform the actual search (after debounce)
  /// Only 2 sources: local recent foods filter + fast pg_trgm backend RPC.
  /// No ChromaDB/Gemini embedding calls in the hot path.
  Future<void> _performSearch(String query, String userId, {List<FoodLog>? cachedLogs}) async {
    // Double-check this is still the current query
    if (_currentQuery != query) {
      debugPrint('FoodSearch: Skipping stale query "$query"');
      return;
    }

    debugPrint('FoodSearch: Searching for "$query"');
    final stopwatch = Stopwatch()..start();

    // Run 2 fast searches in parallel (no ChromaDB)
    final results = await Future.wait([
      _safeSearch(() => _searchRecentFoods(query, userId, cachedLogs: cachedLogs), 'recent'),
      _safeSearch(() => _searchFoodDatabase(query, userId), 'foodDb'),
    ]);

    // Check if query is still current before emitting results
    if (_currentQuery != query) {
      debugPrint('FoodSearch: Query changed, discarding results for "$query"');
      return;
    }

    final recentResults = results[0];
    final foodDatabaseResults = results[1];

    // Split food DB results: saved foods (source='saved'/'saved_item') vs curated DB
    final savedResults = <FoodSearchResult>[];
    final dbResults = <FoodSearchResult>[];
    for (final r in foodDatabaseResults) {
      final sourceStr = r.originalData?['source'] as String? ?? '';
      if (sourceStr == 'saved' || sourceStr == 'saved_item') {
        savedResults.add(FoodSearchResult(
          id: r.id,
          name: r.name,
          brand: r.brand,
          calories: r.calories,
          protein: r.protein,
          carbs: r.carbs,
          fat: r.fat,
          servingSize: r.servingSize,
          source: FoodSearchSource.saved,
          originalData: r.originalData,
        ));
      } else {
        dbResults.add(r);
      }
    }

    stopwatch.stop();
    final total = recentResults.length + savedResults.length + dbResults.length;
    debugPrint('FoodSearch: Found $total results in ${stopwatch.elapsedMilliseconds}ms');

    final searchResults = FoodSearchResults(
      query: query,
      saved: savedResults,
      recent: recentResults,
      foodDatabase: dbResults,
      searchTimeMs: _lastSearchTimeMs,
    );

    // Cache the results
    _addToCache(_cacheKey(query), searchResults);

    // Emit results (only emit error if ALL sources returned empty AND we know the DB call threw)
    _searchController.add(searchResults);
  }

  /// Bigram similarity for typo-tolerant matching (e.g. "aaple" → "apple")
  static Set<String> _bigrams(String s) =>
      {for (int i = 0; i < s.length - 1; i++) s.substring(i, i + 2)};

  static bool _fuzzyMatch(String text, String query) {
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    // Exact substring in either direction
    if (textLower.contains(queryLower) || queryLower.contains(textLower)) {
      return true;
    }
    if (queryLower.length < 3 || textLower.length < 3) return false;
    final tBigrams = _bigrams(textLower);
    final qBigrams = _bigrams(queryLower);
    if (qBigrams.isEmpty || tBigrams.isEmpty) return false;
    final common = qBigrams.intersection(tBigrams).length;
    // Check similarity in both directions — use the SMALLER set as denominator
    // so "apple" (4 bigrams) vs a long query still works: common/min(4, 80) >= 0.5
    final smaller = qBigrams.length < tBigrams.length ? qBigrams.length : tBigrams.length;
    return common / smaller >= 0.5;
  }

  /// Search recent food logs — local-only filter with fuzzy matching.
  /// Uses [cachedLogs] if provided (from NutritionState.recentLogs),
  /// otherwise falls back to API call.
  Future<List<FoodSearchResult>> _searchRecentFoods(
      String query, String userId, {List<FoodLog>? cachedLogs}) async {
    try {
      final logs = cachedLogs ?? await _nutritionRepository.getFoodLogs(
        userId,
        limit: 20,
      );

      // Filter logs that fuzzy-match the query
      final matchingLogs = logs.where((log) {
        if (_fuzzyMatch(log.mealType, query)) return true;
        for (final item in log.foodItems) {
          if (_fuzzyMatch(item.name, query)) return true;
        }
        return false;
      }).take(5).toList();

      return matchingLogs
          .map((log) => FoodSearchResult.fromFoodLog(log))
          .toList();
    } catch (e) {
      debugPrint('FoodSearch: Error searching recent foods: $e');
      return [];
    }
  }

  /// Search the curated food database via backend API (fast pg_trgm RPC).
  Future<List<FoodSearchResult>> _searchFoodDatabase(
      String query, String userId) async {
    try {
      final queryParams = <String, dynamic>{
        'query': query,
        'page_size': 15,
        'user_id': userId, // triggers search_food_database_unified() — includes saved foods
      };
      if (_currentSource != null) {
        queryParams['source'] = _currentSource!;
      }
      final response = await _apiClient.get(
        '/nutrition/food-search',
        queryParameters: queryParams,
      );

      // Backend returns USDASearchResponse format: {foods: [...], total_hits, search_time_ms, ...}
      _lastSearchTimeMs = (response.data['search_time_ms'] as num?)?.toInt();
      final List<dynamic> foods = response.data['foods'] ?? [];
      return foods.map((item) {
        final nutrients = item['nutrients'] as Map<String, dynamic>? ?? {};
        final sourceStr = item['source'] as String? ?? '';
        final isPersonal = sourceStr == 'saved' || sourceStr == 'saved_item';
        return FoodSearchResult(
          id: (item['fdc_id'] ?? item['id'] ?? 0).toString(),
          name: item['description'] as String? ?? item['name'] as String? ?? 'Unknown',
          brand: item['brand_owner'] as String?,
          calories: (nutrients['calories_per_100g'] as num?)?.toInt() ??
              (item['total_calories'] as num?)?.toInt() ?? 0,
          protein: (nutrients['protein_per_100g'] as num?)?.toDouble() ??
              (item['total_protein_g'] as num?)?.toDouble(),
          carbs: (nutrients['carbs_per_100g'] as num?)?.toDouble(),
          fat: (nutrients['fat_per_100g'] as num?)?.toDouble(),
          servingSize: isPersonal ? null : _formatServingSize(item),
          source: isPersonal ? FoodSearchSource.saved : FoodSearchSource.foodDatabase,
          originalData: item as Map<String, dynamic>,
          weightPerUnitG: (item['weight_per_unit_g'] as num?)?.toDouble(),
          defaultCount: (item['default_count'] as num?)?.toInt(),
          servingWeightG: (item['serving_weight_g'] as num?)?.toDouble(),
          matchedQuery: item['matched_query'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('FoodSearch: Error searching food database: $e');
      return [];
    }
  }

  /// Format serving size from API response for display.
  /// Shows "1 pc (219g)" for single items, "10 pc (162g)" for multi-piece, or "100g" fallback.
  String _formatServingSize(Map<String, dynamic> item) {
    final count = (item['default_count'] as num?)?.toInt();
    final servingG = (item['serving_weight_g'] as num?)?.toDouble();
    final weightPerUnit = (item['weight_per_unit_g'] as num?)?.toDouble();

    if (count != null && count > 0 && servingG != null && servingG > 0) {
      if (count > 1) {
        return '$count pc (${servingG.round()}g)';
      }
      return '1 serving (${servingG.round()}g)';
    }
    if (weightPerUnit != null && weightPerUnit > 0) {
      return '1 serving (${weightPerUnit.round()}g)';
    }
    return '100g';
  }

  /// Normalize query for consistent caching
  String _normalizeQuery(String query) {
    return query.trim().toLowerCase();
  }

  /// Add results to cache with LRU eviction
  void _addToCache(String query, FoodSearchResults results) {
    // Remove oldest entries if cache is full
    while (_cache.length >= _maxCacheSize) {
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _cache.entries) {
        if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
          oldestTime = entry.value.timestamp;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        _cache.remove(oldestKey);
      }
    }

    _cache[query] = _CacheEntry(results);
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Cancel any pending searches
  void cancel() {
    _debounceTimer?.cancel();
    _currentQuery = null;
  }

  // ─── Natural Language Detection & Analysis ──────────────────

  /// Compound food names containing "and", "with", or numbers that should
  /// NOT be split into multiple items. Checked before NL heuristics.
  static final _compoundFoods = <String>{
    // "and" compounds
    'mac and cheese', 'macaroni and cheese', 'fish and chips',
    'bread and butter', 'ham and cheese', 'salt and pepper',
    'peanut butter and jelly', 'pb and j', 'pbj',
    'surf and turf', 'rice and beans', 'chips and salsa',
    'steak and eggs', 'biscuits and gravy', 'franks and beans',
    'bangers and mash', 'bubble and squeak',
    'sweet and sour chicken', 'sweet and sour pork',
    'chips and dip', 'bread and butter pudding',
    'strawberries and cream', 'peaches and cream',
    'ham and egg', 'bacon and eggs', 'bacon and cheese',
    'pork and beans', 'meat and potatoes',
    'dal and rice', 'rice and dal', 'dal rice', 'dal chawal',
    'chole bhature', 'dal makhani', 'paneer butter masala',
    'rajma chawal', 'kadhi chawal', 'curd rice',
    // "with" compounds
    'coffee with milk', 'tea with honey', 'tea with milk',
    'bread with butter', 'rice with gravy', 'cereal with milk',
    'pasta with sauce', 'toast with jam', 'toast with butter',
    'oatmeal with milk', 'pancakes with syrup',
    // Number-in-name foods
    'chicken 65', 'chicken 555', '7 up', '7up', 'coke zero',
    'v8', '5 hour energy', '5-hour energy', 'heinz 57',
    'formula 1', 'g2', 'muscle milk', 'ensure plus',
    '5 star chocolate', '5star',
    // Multi-word single items
    'protein shake', 'peanut butter', 'sour cream',
    'cream cheese', 'ice cream', 'fried rice', 'brown rice',
    'black beans', 'green tea', 'hot dog', 'french fries',
    'onion rings', 'mashed potatoes', 'sweet potato',
    'baked beans', 'hash browns', 'grilled cheese',
    'tuna salad', 'chicken salad', 'egg salad',
    'fruit salad', 'caesar salad', 'greek salad',
  };

  /// Filler phrases that indicate natural-language food logging.
  static final _nlFillerPhrases = RegExp(
    r'\b('
    // ── Past tense ──
    // "I had / ate / just had / just ate / drank / consumed / took"
    // NOTE: "finished" is NOT here — handled as "finished off" in phrasal verbs below
    r'i\s+(?:had|ate|just\s+had|just\s+ate|drank|just\s+drank|consumed|took)'
    // "I've had / eaten / been eating / already ate / already had"
    r"|i'?ve\s+(?:had|eaten|been\s+eating|been\s+having|already\s+(?:had|ate|eaten))"
    r'|i\s+already\s+(?:had|ate|eaten)'

    // ── Present tense ──
    r"|i'?m\s+(?:eating|having|drinking|munching|snacking|chewing|finishing|consuming)"
    r'|(?:currently|right\s+now|just\s+now)\s+(?:eating|having|drinking|munching)'

    // ── Future / intent ──
    r"|i'?m\s+(?:gonna|about\s+to|going\s+to|planning\s+to)\s+(?:eat|have|grab|get|order)"
    r"|i\s+(?:wanna|want\s+to)\s+(?:eat|have|grab|get|order)"
    r'|i\s+feel\s+like\s+(?:eating|having)'
    r'|craving\s+'

    // ── Habitual ──
    r'|i\s+(?:usually|normally|always|often|sometimes|typically)\s+(?:eat|have|drink|get|grab|order)'

    // ── Phrasal verb fillers ──
    // "ended up eating / wound up having / went ahead and ate / decided to eat"
    r'|(?:ended\s+up|wound\s+up)\s+(?:eating|having|drinking|getting|ordering)'
    r"|(?:went\s+ahead\s+and|decided\s+to|managed\s+to|had\s+to|could\s+only|couldn't\s+help\s+but)\s+(?:eat|ate|have|had|drink|drank|grab|grabbed|get|got|order|ordered)"

    // ── Reward / guilt / indulgence ──
    // "treated myself to / indulged in / splurged on / cheated with / snuck in"
    r'|(?:treated\s+myself\s+to|indulged\s+in|splurged\s+on|cheated\s+with|snuck\s+in|sneaked\s+in|gave\s+in\s+to)'
    r'|(?:guilty\s+pleasure\s+(?:was|is)|cheat\s+meal\s+(?:was|is))'

    // ── Small quantity eating ──
    // "nibbled on / picked at / had a bite of / had a taste of / munched on / snacked on"
    r'|(?:nibbled\s+on|picked\s+at|munched\s+on|snacked\s+on|grazed\s+on|pecked\s+at)'
    r'|had\s+(?:a\s+)?(?:bite|taste|sip|piece|bit|morsel|sliver|nibble|lick|spoonful)\s+(?:of\s+)?'

    // ── Large quantity eating ──
    // "stuffed myself with / gorged on / pigged out on / feasted on / loaded up on"
    r'|(?:stuffed\s+myself\s+with|gorged\s+on|pigged\s+out\s+on|feasted\s+on|overindulged\s+in|loaded\s+up\s+on|overdid\s+it\s+(?:on|with))'

    // ── Delivery / source compound (MUST come before generic action verbs) ──
    r'|(?:ordered|got|picked\s+up|grabbed|delivered)\s+(?:from|via|through|off)\s+(?:swiggy|zomato|doordash|ubereats|uber\s+eats|grubhub|postmates|instacart|seamless|the\s+(?:restaurant|cafeteria|canteen|food\s+court|drive\s+thru|drive-?through))'
    // ── Action verbs ──
    // NOTE: "reheated/heated up/warmed up/microwaved/air fried" are food modifiers, not fillers
    // NOTE: "cooked" has lookahead (?!\s+through) to preserve "cooked through" modifier
    r'|(?:just\s+)?(?:grabbed|ordered|picked\s+up|got|went\s+with|chose|cooked(?!\s+through)|made|prepared|whipped\s+up|threw\s+together|fixed\s+myself|made\s+myself|cooked\s+myself)'
    r'|(?:just\s+)?(?:demolished|crushed|smashed|scarfed|wolfed\s+down|inhaled|devoured|polished\s+off|downed|chugged|sipped|tasted|tried|sampled|split|shared)'

    // ── Logging intent verbs ──
    // "log / add / track / record" — compound: "track my lunch:" / "log breakfast:"
    r'|(?:please\s+)?(?:log|add|track|record|put\s+down|note\s+down|enter|count|save|register)\s+(?:my\s+)?(?:(?:breakfast|lunch|dinner|brunch|snack|meal|food|intake)\s*[:=]\s*)?'
    r'|(?:can\s+you|could\s+you|please|help\s+me)\s+(?:log|add|track|record|enter|count|note)\s+(?:my\s+)?(?:(?:breakfast|lunch|dinner|brunch|snack|meal|food)\s*[:=]\s*)?'
    r'|(?:log(?:ging)?|track(?:ing)?|add(?:ing)?|record(?:ing)?|enter(?:ing)?|count(?:ing)?|not(?:ing)?)\s+(?:my\s+)?(?:food|meal|snack|breakfast|lunch|dinner|intake|macros|calories)\s*:?'

    // ── Meal context ──
    r'|for\s+(?:breakfast|lunch|dinner|brunch|snack|supper|dessert|a\s+snack|my\s+meal|pre-?workout|post-?workout|a\s+quick\s+bite|a\s+cheat\s+meal|a\s+treat|my\s+cheat\s+day|elevenses|tea\s+time|tiffin|second\s+breakfast|midnight\s+snack|a\s+late\s+night\s+snack)'
    // Bare meal labels: "breakfast:", "lunch:", "meal 1:", "3pm snack:"
    r'|(?:breakfast|lunch|dinner|brunch|snack|supper|meal\s*\d*|pre-?\s*workout|post-?\s*workout)\s*[:=]\s*'
    r'|\d{1,2}\s*(?:am|pm)\s+(?:breakfast|lunch|dinner|snack|meal)\s*[:=]?\s+'

    // ── Time context ──
    r'|(?:today|tonight|this\s+morning|this\s+afternoon|this\s+evening|last\s+night|yesterday|earlier\s+today|earlier|just\s+now|moments?\s+ago|a\s+while\s+ago|an\s+hour\s+ago|a\s+few\s+(?:minutes|hours)\s+ago)\s+i\s+(?:had|ate|drank|got|grabbed|consumed|finished)'
    // Possessive time
    r"|(?:today'?s|tonight'?s|this\s+morning'?s|yesterday'?s)\s+(?:breakfast|lunch|dinner|snack|meal|food)"

    // ── Possessive / diary style ──
    r'|my\s+(?:breakfast|lunch|dinner|brunch|snack|meal|food|intake)\s+(?:was|is|today|tonight|this\s+morning|consisted\s+of|included)'
    r'|what\s+i\s+(?:ate|had|eaten|ordered|grabbed)'
    r"|what\s+i'?m\s+(?:eating|having)"

    // ── Conversational ──
    r'|(?:ate|had|having|grabbed|got|ordered|tried|sampled)\s+(?:some|a|an)\b'
    // Limiting
    r'|all\s+i\s+(?:had|ate)\s+was'
    r'|(?:only|just)\s+(?:had|ate|eating|having)\b'
    r'|(?:nothing|all\s+i\s+ate)\s+(?:but|except)'

    // ── Sharing context ──
    r'|we\s+(?:had|ate|ordered|shared|split|grabbed|got|went\s+for|picked\s+up)'
    r'|(?:my\s+(?:friend|partner|wife|husband|bf|gf|kid|son|daughter)\s+and\s+i|me\s+and\s+my\s+\w+)\s+(?:had|ate|shared|split)'

    // ── Conjunction fillers ──
    r'|along\s+with|and\s+a\b|with\s+a\b|as\s+well\s+as|on\s+the\s+side|plus\s+a\b|also\s+(?:had|ate|a)\b'

    // ── Sequential eating ──
    // "followed by / and then had / topped off with / washed it down with"
    r'|(?:followed\s+by|and\s+then\s+(?:had|ate|a)|topped\s+(?:it\s+)?off\s+with|washed\s+(?:it\s+)?down\s+with)\b'

    // ── Query-style ──
    r'|how\s+many\s+(?:calories?|carbs?|protein|fat|macros?)\s+(?:in|for|does)'
    r"|(?:what(?:'?s| is| are)?\s+the\s+)?(?:nutrition|calories?|macros?|carbs?|protein|fat)\s+(?:in|of|for|info)\b"
    r'|(?:nutrition|calorie|macro)\s+(?:info|information|data|breakdown|count)\s+(?:for|of|in)'
    r'|(?:is|does)\s+.{2,30}\s+(?:healthy|good\s+for\s+(?:me|you|weight\s+loss|muscle)|bad\s+for\s+(?:me|you)|fattening|low\s+cal(?:orie)?|high\s+protein)\s*\??'

    // ── Restaurant / source context ──
    r'|(?:from|at|via|through|off\s+of)\s+(?:the\s+)?(?:restaurant|cafeteria|canteen|food\s+court|drive\s+thru|drive-?through)'
    r'|(?:ordered|got|delivered)\s+(?:from|via|through|off)\s+(?:swiggy|zomato|doordash|ubereats|uber\s+eats|grubhub|postmates|instacart|seamless)'
    r'|(?:home\s*made|home\s*cooked|store\s*bought|takeout|take-?out|take\s*away|dine-?in|delivery)'

    // ── Emphasis / descriptive noise ──
    r'|(?:the\s+)?(?:best|most\s+amazing|most\s+delicious|incredible|fantastic|amazing|delicious|terrible|disgusting|decent|mediocre|okay|mid)'
    r'|(?:really|very|super|incredibly|extremely|absolutely|totally|so)\s+(?:good|tasty|yummy|delicious|filling|satisfying|healthy|unhealthy)'
    r'|(?:honestly|basically|literally|actually|truly|seriously|lowkey|highkey|ngl|tbh|fr)\s+(?:(?:just|only)\s+)?'

    // ── Mid-sentence noise ──
    // NOTE: "well" must not match before "done" (well done steak)
    r'|(?:um|uh|hmm|well(?!\s+done)|okay|ok|so|yeah)'

    // ── Phrasal verb completions (must come AFTER simple past group) ──
    r'|i\s+(?:took|finished\s+off|wolfed|polished\s+off|binged\s+on)'

    // ── Approximations ──
    r'|(?:about|maybe|around|approximately|roughly|nearly|like|probably|i\s+think)'
    r')',
    caseSensitive: false,
  );

  /// Word-form numbers that precede food items.
  static final _wordNumbers = RegExp(
    r'\b(one|two|three|four|five|six|seven|eight|nine|ten|half|dozen|couple)\s+\w',
    caseSensitive: false,
  );

  /// Weight / volume units.
  static final _weightUnits = RegExp(
    r'\b(grams?|kg\b|ml\b|oz\b|ounces?|cups?|tbsp\b|tsp\b|liters?|litres?|lbs?|pounds?|slices?|pieces?|servings?|bowls?|plates?|handfuls?)\b',
    caseSensitive: false,
  );

  /// Digit immediately followed by a weight/volume unit (e.g., "300g", "2kg").
  static final _digitUnit = RegExp(
    r'\d+\s*(g|gm|gms|kg|ml|oz|l|lb)\b',
    caseSensitive: false,
  );

  /// Returns true if [query] looks like natural-language food logging
  /// rather than a simple keyword search (e.g. "chicken").
  static bool isNaturalLanguageInput(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();

    // ── Step 1: Compound food dictionary check (HIGHEST PRIORITY) ──
    // If the entire input matches a known compound food, it's a keyword search.
    if (_compoundFoods.contains(lower)) return false;
    // Also check after stripping a leading number: "2 mac and cheese" → "mac and cheese"
    final withoutLeadingNum = lower.replaceFirst(RegExp(r'^\d+\s+'), '');
    if (withoutLeadingNum != lower && _compoundFoods.contains(withoutLeadingNum)) {
      // "2 mac and cheese" → NL (quantity + compound food)
      return true;
    }

    // ── Step 2: Strong NL signals (always NL) ──
    // Multi-line input
    if (trimmed.contains('\n')) return true;

    // Comma-separated with 2+ segments
    if (trimmed.contains(',')) {
      final segments = trimmed.split(',').where((s) => s.trim().isNotEmpty).toList();
      if (segments.length >= 2) return true;
    }

    // Filler phrases ("I had", "I ate", "for breakfast")
    if (_nlFillerPhrases.hasMatch(trimmed)) return true;

    // ── Step 3: Moderate NL signals ──
    // Digit + weight/volume unit (e.g., "300g rice", "2kg chicken", "500ml milk")
    if (_digitUnit.hasMatch(trimmed)) return true;

    // Weight/volume unit words (e.g., "2 cups rice", "a bowl of soup")
    if (_weightUnits.hasMatch(trimmed)) return true;

    // Word numbers followed by food (e.g., "one apple", "half plate rice")
    if (_wordNumbers.hasMatch(trimmed)) return true;

    // Starts with digit + text, but NOT if it's just one food (e.g., "2 dosa" is NL)
    if (RegExp(r'^\d+\s+[a-zA-Z]').hasMatch(trimmed)) return true;

    // ── Step 4: "and" conjunction check (only if both sides look like distinct foods) ──
    if (RegExp(r'\s+and\s+', caseSensitive: false).hasMatch(trimmed)) {
      // If NOT in compound dictionary (checked above), and has "and" between
      // words, it's likely multi-item: "rice and dal", "dosa and chutney"
      // BUT only if there are at least 2 word-tokens on each side
      final andParts = lower.split(RegExp(r'\s+and\s+'));
      if (andParts.length >= 2 && andParts.every((p) => p.trim().isNotEmpty)) {
        return true;
      }
    }

    // ── Step 5: No NL signals → keyword search ──
    return false;
  }

  /// Call the NL analyze-text endpoint and emit results on the search stream.
  Future<void> analyzeNaturalLanguage(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    _debounceTimer?.cancel();
    _currentQuery = normalizedText;
    _searchController.add(FoodSearchNLLoading(normalizedText));

    try {
      final response = await _nutritionRepository.analyzeText(normalizedText);

      // Check the query hasn't changed while we were waiting
      if (_currentQuery != normalizedText) return;

      final result = FoodAnalysisResult.fromJson(response);
      _searchController.add(FoodSearchNLResults(query: normalizedText, result: result));
    } catch (e) {
      if (_currentQuery != normalizedText) return;
      debugPrint('FoodSearch: NL analysis error: $e');
      _searchController.add(FoodSearchNLError('Analysis failed. Please try again.', normalizedText));
    }
  }

  /// Search alternatives for a food item (direct call, no stream).
  /// Used by NL item sections for inline alternative picking.
  /// Returns food database results for the given query.
  Future<List<FoodSearchResult>> searchAlternatives(String query, String userId) async {
    final normalized = _normalizeQuery(query);
    if (normalized.length < _minQueryLength) return [];

    // Check cache
    final cacheKey = 'alt_$normalized';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.results.foodDatabase;
    }

    try {
      final results = await _searchFoodDatabase(normalized, userId);
      // Cache with alt_ prefix
      _addToCache(cacheKey, FoodSearchResults(
        query: normalized,
        foodDatabase: results,
      ));
      return results;
    } catch (e) {
      debugPrint('FoodSearch: searchAlternatives error: $e');
      return [];
    }
  }

  /// Call POST /nutrition/food-review to get AI review for a food.
  Future<FoodReview?> reviewFood(String foodName, int calories, double protein, double carbs, double fat) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/food-review',
        data: {
          'food_name': foodName,
          'calories': calories,
          'protein_g': protein,
          'carbs_g': carbs,
          'fat_g': fat,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;
      return FoodReview.fromJson(data);
    } catch (e) {
      debugPrint('FoodSearch: reviewFood error: $e');
      return null;
    }
  }

  /// Start a 2-second idle timer for AI review. Cancels any existing timer.
  void startReviewTimer(String foodName, int calories, double protein, double carbs, double fat) {
    _reviewTimer?.cancel();
    _reviewController.add(null); // reset to loading-like state
    _reviewTimer = Timer(const Duration(seconds: 2), () async {
      final review = await reviewFood(foodName, calories, protein, carbs, fat);
      _reviewController.add(review);
    });
  }

  /// Cancel any pending review timer and clear the review stream.
  void cancelReview() {
    _reviewTimer?.cancel();
    _reviewController.add(null);
  }

  /// Dispose of resources
  void dispose() {
    _debounceTimer?.cancel();
    _reviewTimer?.cancel();
    _searchController.close();
    _reviewController.close();
  }
}

/// Provider for FoodSearchService
final foodSearchServiceProvider = Provider<FoodSearchService>((ref) {
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);

  final service = FoodSearchService(
    nutritionRepository: nutritionRepo,
    apiClient: apiClient,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

/// Provider for current search state
final foodSearchStateProvider =
    StreamProvider.autoDispose<FoodSearchState>((ref) {
  final service = ref.watch(foodSearchServiceProvider);
  return service.searchStream;
});

/// Provider for AI food review stream
final foodReviewStreamProvider =
    StreamProvider.autoDispose<FoodReview?>((ref) {
  final service = ref.watch(foodSearchServiceProvider);
  return service.reviewStream;
});

/// Provider for recent searches (stored locally)
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

/// Notifier for managing recent searches
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  static const int _maxRecentSearches = 10;

  RecentSearchesNotifier() : super([]);

  void addSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    // Remove if already exists
    final updated = state.where((s) => s != normalized).toList();

    // Add to front
    updated.insert(0, normalized);

    // Trim to max size
    if (updated.length > _maxRecentSearches) {
      updated.removeLast();
    }

    state = updated;
  }

  void removeSearch(String query) {
    state = state.where((s) => s != query).toList();
  }

  void clearSearches() {
    state = [];
  }
}
