import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/food_table.dart';

part 'food_dao.g.dart';

@DriftAccessor(tables: [CachedFoods])
class FoodDao extends DatabaseAccessor<AppDatabase> with _$FoodDaoMixin {
  FoodDao(super.db);

  /// Search foods by text query (SQL LIKE on description, category, brand).
  Future<List<CachedFood>> searchFoods(String query, {int limit = 20}) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(cachedFoods)
          ..where((f) =>
              f.description.lower().like(pattern) |
              f.foodCategory.lower().like(pattern) |
              f.brandName.lower().like(pattern))
          ..orderBy([
            // Favorites first, then recent, then alphabetical
            (f) => OrderingTerm.desc(f.isFavorite),
            (f) => OrderingTerm.desc(f.lastUsedAt),
            (f) => OrderingTerm.asc(f.description),
          ])
          ..limit(limit))
        .get();
  }

  /// Get food by barcode.
  Future<CachedFood?> getByBarcode(String barcode) {
    return (select(cachedFoods)..where((f) => f.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Get food by external ID and source.
  Future<CachedFood?> getByExternalId(String externalId, String source) {
    return (select(cachedFoods)
          ..where((f) =>
              f.externalId.equals(externalId) & f.source.equals(source)))
        .getSingleOrNull();
  }

  /// Get favorite foods.
  Future<List<CachedFood>> getFavorites({int limit = 50}) {
    return (select(cachedFoods)
          ..where((f) => f.isFavorite.equals(true))
          ..orderBy([(f) => OrderingTerm.asc(f.description)])
          ..limit(limit))
        .get();
  }

  /// Get recently used foods.
  Future<List<CachedFood>> getRecentFoods({int limit = 20}) {
    return (select(cachedFoods)
          ..where((f) => f.lastUsedAt.isNotNull())
          ..orderBy([(f) => OrderingTerm.desc(f.lastUsedAt)])
          ..limit(limit))
        .get();
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(int id) async {
    final food =
        await (select(cachedFoods)..where((f) => f.id.equals(id))).getSingle();
    await (update(cachedFoods)..where((f) => f.id.equals(id)))
        .write(CachedFoodsCompanion(isFavorite: Value(!food.isFavorite)));
  }

  /// Mark food as recently used.
  Future<void> markUsed(int id) {
    return (update(cachedFoods)..where((f) => f.id.equals(id)))
        .write(CachedFoodsCompanion(lastUsedAt: Value(DateTime.now())));
  }

  /// Insert or update a food item (upsert by externalId + source).
  Future<int> upsertFood(CachedFoodsCompanion food) {
    return into(cachedFoods).insertOnConflictUpdate(food);
  }

  /// Batch insert foods (for importing USDA database).
  Future<void> batchInsertFoods(List<CachedFoodsCompanion> foods) {
    return batch((b) {
      b.insertAll(cachedFoods, foods, mode: InsertMode.insertOrReplace);
    });
  }

  /// Get total food count.
  Future<int> getFoodCount() async {
    final countExpr = cachedFoods.id.count();
    final query = selectOnly(cachedFoods)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  /// Stream food count (for UI).
  Stream<int> watchFoodCount() {
    final countExpr = cachedFoods.id.count();
    final query = selectOnly(cachedFoods)..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  /// Clear all cached foods from a specific source.
  Future<int> clearBySource(String source) {
    return (delete(cachedFoods)..where((f) => f.source.equals(source))).go();
  }

  /// Clear non-favorite, non-recent Open Food Facts cached foods older than 30 days.
  Future<int> clearStaleCache() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return (delete(cachedFoods)
          ..where((f) =>
              f.isFavorite.equals(false) &
              (f.lastUsedAt.isNull() |
                  f.lastUsedAt.isSmallerThanValue(cutoff)) &
              f.source.equals('openfoodfacts')))
        .go();
  }
}
