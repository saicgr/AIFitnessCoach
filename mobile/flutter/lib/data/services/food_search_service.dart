import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/nutrition_repository.dart';
import '../models/nutrition.dart';
import 'api_client.dart';

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
  };
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

  const FoodSearchResults({
    required this.query,
    this.saved = const [],
    this.recent = const [],
    this.database = const [],
    this.foodDatabase = const [],
    this.fromCache = false,
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

  // Current query to prevent stale results
  String? _currentQuery;

  // Current database source filter
  String? _currentSource;

  FoodSearchService({
    required NutritionRepository nutritionRepository,
    required ApiClient apiClient,
  })  : _nutritionRepository = nutritionRepository,
        _apiClient = apiClient;

  /// Stream of search states for UI binding
  Stream<FoodSearchState> get searchStream => _searchController.stream;

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

      // Backend returns USDASearchResponse format: {foods: [...], total_hits, ...}
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

  /// Filler phrases that indicate natural-language food logging.
  static final _nlFillerPhrases = RegExp(
    r'\b(i\s+had|i\s+ate|i\s+just\s+had|i\s+just\s+ate|for\s+breakfast|for\s+lunch|for\s+dinner|along\s+with|and\s+a\b|with\s+a\b)\b',
    caseSensitive: false,
  );

  /// Word-form numbers that precede food items.
  static final _wordNumbers = RegExp(
    r'\b(one|two|three|four|five|six|seven|eight|nine|ten|half|dozen|couple)\b',
    caseSensitive: false,
  );

  /// Weight / volume units.
  static final _weightUnits = RegExp(
    r'\b(grams?|g\b|kg\b|ml\b|oz\b|ounces?|cups?|tbsp\b|tsp\b|liters?|litres?|lbs?|pounds?|slices?|pieces?|servings?|bowls?|plates?|handfuls?)\b',
    caseSensitive: false,
  );

  /// Returns true if [query] looks like natural-language food logging
  /// rather than a simple keyword search (e.g. "chicken").
  static bool isNaturalLanguageInput(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;

    // Multi-line input is always NL
    if (trimmed.contains('\n')) return true;

    // Comma-separated with 2+ segments that aren't a single word each
    if (trimmed.contains(',')) {
      final segments = trimmed.split(',').where((s) => s.trim().isNotEmpty).toList();
      if (segments.length >= 2) return true;
    }

    // Starts with digit(s) followed by text (e.g. "2 dosa", "300g rice")
    if (RegExp(r'^\d+\s*[a-zA-Z]').hasMatch(trimmed)) return true;

    // Filler phrases
    if (_nlFillerPhrases.hasMatch(trimmed)) return true;

    // Word numbers before food
    if (_wordNumbers.hasMatch(trimmed)) return true;

    // Weight/volume units
    if (_weightUnits.hasMatch(trimmed)) return true;

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

  /// Dispose of resources
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.close();
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
