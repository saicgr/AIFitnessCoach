import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../local/database_provider.dart';

/// Service for managing the offline food database.
///
/// On first launch, loads embedded USDA food data from assets.
/// As the user searches online, API results are cached locally.
class FoodDatabaseService {
  final AppDatabase _db;
  bool _isInitialized = false;

  FoodDatabaseService(this._db);

  /// Initialize the food database with embedded USDA data.
  /// Only runs once -- checks if data already exists.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final existingCount = await _db.foodDao.getFoodCount();
    if (existingCount > 0) {
      debugPrint('✅ [FoodDB] Already initialized with $existingCount foods');
      _isInitialized = true;
      return;
    }

    debugPrint('🔍 [FoodDB] Initializing food database with seed data...');

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/food_seed_data.json');
      final List<dynamic> foods = jsonDecode(jsonString) as List<dynamic>;

      final companions = foods.map((food) {
        final f = food as Map<String, dynamic>;
        return CachedFoodsCompanion.insert(
          externalId: f['fdc_id'].toString(),
          description: f['description'] as String,
          foodCategory: Value(f['food_category'] as String?),
          source: const Value('usda'),
          servingSizeG:
              Value((f['serving_size_g'] as num?)?.toDouble() ?? 100.0),
          householdServing: Value(f['household_serving'] as String?),
          calories: Value((f['calories'] as num?)?.toDouble() ?? 0),
          proteinG: Value((f['protein_g'] as num?)?.toDouble() ?? 0),
          fatG: Value((f['fat_g'] as num?)?.toDouble() ?? 0),
          carbsG: Value((f['carbs_g'] as num?)?.toDouble() ?? 0),
          fiberG: Value((f['fiber_g'] as num?)?.toDouble() ?? 0),
          sugarG: Value((f['sugar_g'] as num?)?.toDouble() ?? 0),
          sodiumMg: Value((f['sodium_mg'] as num?)?.toDouble() ?? 0),
          cachedAt: DateTime.now(),
        );
      }).toList();

      await _db.foodDao.batchInsertFoods(companions);
      _isInitialized = true;
      debugPrint('✅ [FoodDB] Loaded ${companions.length} seed foods');
    } catch (e) {
      debugPrint('❌ [FoodDB] Error initializing: $e');
    }
  }

  /// Search for foods (local database).
  Future<List<CachedFood>> search(String query, {int limit = 20}) {
    return _db.foodDao.searchFoods(query, limit: limit);
  }

  /// Get food by barcode.
  Future<CachedFood?> getByBarcode(String barcode) {
    return _db.foodDao.getByBarcode(barcode);
  }

  /// Get favorites.
  Future<List<CachedFood>> getFavorites() {
    return _db.foodDao.getFavorites();
  }

  /// Get recent foods.
  Future<List<CachedFood>> getRecent() {
    return _db.foodDao.getRecentFoods();
  }

  /// Toggle favorite.
  Future<void> toggleFavorite(int id) {
    return _db.foodDao.toggleFavorite(id);
  }

  /// Mark food as used.
  Future<void> markUsed(int id) {
    return _db.foodDao.markUsed(id);
  }

  /// Cache a food from API results.
  Future<void> cacheFood(CachedFoodsCompanion food) {
    return _db.foodDao.upsertFood(food);
  }

  /// Get total food count.
  Stream<int> watchFoodCount() {
    return _db.foodDao.watchFoodCount();
  }

  /// Clear stale cached foods.
  Future<int> clearStaleCache() {
    return _db.foodDao.clearStaleCache();
  }
}

final foodDatabaseServiceProvider = Provider<FoodDatabaseService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = FoodDatabaseService(db);
  service.initialize();
  return service;
});
