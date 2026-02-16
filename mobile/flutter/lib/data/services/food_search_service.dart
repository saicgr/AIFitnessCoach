import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/nutrition_repository.dart';
import '../models/nutrition.dart';
import 'api_client.dart';

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
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  // Stream controller for real-time search updates
  final _searchController = StreamController<FoodSearchState>.broadcast();

  // Current query to prevent stale results
  String? _currentQuery;

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
    final entry = _cache[normalizedQuery];
    if (entry != null && !entry.isExpired) {
      return entry.results;
    }
    return null;
  }

  /// Search with debouncing
  void search(String query, String userId) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    final normalizedQuery = _normalizeQuery(query);
    _currentQuery = normalizedQuery;

    // Empty query - return to initial state
    if (normalizedQuery.isEmpty) {
      _searchController.add(const FoodSearchInitial());
      return;
    }

    // Check cache first for instant results
    final cachedEntry = _cache[normalizedQuery];
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

    // Show loading state immediately
    _searchController.add(FoodSearchLoading(normalizedQuery));

    // Debounce the actual API call
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(normalizedQuery, userId);
    });
  }

  /// Perform the actual search (after debounce)
  Future<void> _performSearch(String query, String userId) async {
    // Double-check this is still the current query
    if (_currentQuery != query) {
      debugPrint('FoodSearch: Skipping stale query "$query"');
      return;
    }

    debugPrint('FoodSearch: Searching for "$query"');
    final stopwatch = Stopwatch()..start();

    try {
      // Run searches in parallel for speed
      final results = await Future.wait([
        _searchSavedFoods(query, userId),
        _searchRecentFoods(query, userId),
        _searchSemanticDatabase(query, userId),
        _searchFoodDatabase(query, userId),
      ]);

      // Check if query is still current before emitting results
      if (_currentQuery != query) {
        debugPrint('FoodSearch: Query changed, discarding results for "$query"');
        return;
      }

      final savedResults = results[0];
      final recentResults = results[1];
      final databaseResults = results[2];
      final foodDatabaseResults = results[3];

      stopwatch.stop();
      debugPrint('FoodSearch: Found ${savedResults.length + recentResults.length + databaseResults.length + foodDatabaseResults.length} results in ${stopwatch.elapsedMilliseconds}ms');

      final searchResults = FoodSearchResults(
        query: query,
        saved: savedResults,
        recent: recentResults,
        database: databaseResults,
        foodDatabase: foodDatabaseResults,
      );

      // Cache the results
      _addToCache(query, searchResults);

      // Emit results
      _searchController.add(searchResults);
    } catch (e) {
      debugPrint('FoodSearch: Error searching for "$query": $e');
      if (_currentQuery == query) {
        _searchController.add(FoodSearchError(
          'Failed to search foods. Please try again.',
          query,
        ));
      }
    }
  }

  /// Search saved foods (favorites)
  Future<List<FoodSearchResult>> _searchSavedFoods(
      String query, String userId) async {
    try {
      // Use semantic search for saved foods
      final response = await _apiClient.post(
        '/nutrition/saved-foods/search',
        queryParameters: {'user_id': userId},
        data: {
          'query': query,
          'limit': 5,
        },
      );

      final List<dynamic> items = response.data['similar_foods'] ?? [];
      return items.map((item) {
        return FoodSearchResult(
          id: item['id'] as String,
          name: item['name'] as String? ?? 'Unknown',
          calories: (item['total_calories'] as num?)?.toInt() ?? 0,
          protein: (item['total_protein_g'] as num?)?.toDouble(),
          source: FoodSearchSource.saved,
          distance: (item['distance'] as num?)?.toDouble(),
          originalData: item as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      debugPrint('FoodSearch: Error searching saved foods: $e');
      return [];
    }
  }

  /// Search recent food logs
  Future<List<FoodSearchResult>> _searchRecentFoods(
      String query, String userId) async {
    try {
      // Get recent food logs
      final logs = await _nutritionRepository.getFoodLogs(
        userId,
        limit: 20,
      );

      // Filter logs that match the query
      final queryLower = query.toLowerCase();
      final matchingLogs = logs.where((log) {
        // Check meal type
        if (log.mealType.toLowerCase().contains(queryLower)) return true;

        // Check food items
        for (final item in log.foodItems) {
          if (item.name.toLowerCase().contains(queryLower)) return true;
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

  /// Search semantic database (ChromaDB via API)
  Future<List<FoodSearchResult>> _searchSemanticDatabase(
      String query, String userId) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/saved-foods/search',
        queryParameters: {'user_id': userId},
        data: {
          'query': query,
          'limit': 10,
        },
      );

      final List<dynamic> items = response.data['similar_foods'] ?? [];

      // Filter out items already in saved (to avoid duplicates)
      return items
          .skip(5) // Skip first 5 which are shown as "saved"
          .take(5)
          .map((item) => FoodSearchResult.fromSearchResult(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FoodSearch: Error searching database: $e');
      return [];
    }
  }

  /// Search the curated food database via backend API
  Future<List<FoodSearchResult>> _searchFoodDatabase(
      String query, String userId) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/food-search',
        queryParameters: {
          'query': query,
          'page_size': 10,
        },
      );

      // Backend returns USDASearchResponse format: {foods: [...], total_hits, ...}
      final List<dynamic> foods = response.data['foods'] ?? [];
      return foods.map((item) {
        final nutrients = item['nutrients'] as Map<String, dynamic>? ?? {};
        return FoodSearchResult(
          id: (item['fdc_id'] ?? 0).toString(),
          name: item['description'] as String? ?? 'Unknown',
          brand: item['brand_owner'] as String?,
          calories: (nutrients['calories_per_100g'] as num?)?.toInt() ?? 0,
          protein: (nutrients['protein_per_100g'] as num?)?.toDouble(),
          carbs: (nutrients['carbs_per_100g'] as num?)?.toDouble(),
          fat: (nutrients['fat_per_100g'] as num?)?.toDouble(),
          servingSize: '100g',
          source: FoodSearchSource.foodDatabase,
          originalData: item as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      debugPrint('FoodSearch: Error searching food database: $e');
      return [];
    }
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
