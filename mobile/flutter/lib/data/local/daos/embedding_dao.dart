import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/embedding_cache_table.dart';

part 'embedding_dao.g.dart';

@DriftAccessor(tables: [EmbeddingCache])
class EmbeddingDao extends DatabaseAccessor<AppDatabase>
    with _$EmbeddingDaoMixin {
  EmbeddingDao(super.db);

  /// Get all embeddings for a given entity type.
  Future<List<EmbeddingCacheData>> getByType(String entityType) {
    return (select(embeddingCache)
          ..where((e) => e.entityType.equals(entityType)))
        .get();
  }

  /// Get embedding for a specific entity.
  Future<EmbeddingCacheData?> getByEntity(
      String entityType, String entityId) {
    return (select(embeddingCache)
          ..where((e) =>
              e.entityType.equals(entityType) &
              e.entityId.equals(entityId)))
        .getSingleOrNull();
  }

  /// Upsert a single embedding.
  Future<int> upsertEmbedding(EmbeddingCacheCompanion entry) {
    return into(embeddingCache).insertOnConflictUpdate(entry);
  }

  /// Batch insert embeddings (for bulk indexing).
  Future<void> batchInsert(List<EmbeddingCacheCompanion> entries) {
    return batch((b) {
      b.insertAll(embeddingCache, entries, mode: InsertMode.insertOrReplace);
    });
  }

  /// Get count of embeddings by entity type.
  Future<int> getCountByType(String entityType) async {
    final countExpr = embeddingCache.id.count();
    final query = selectOnly(embeddingCache)
      ..addColumns([countExpr])
      ..where(embeddingCache.entityType.equals(entityType));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  /// Get all entity IDs that have embeddings for a given type.
  Future<List<String>> getIndexedEntityIds(String entityType) async {
    final query = selectOnly(embeddingCache)
      ..addColumns([embeddingCache.entityId])
      ..where(embeddingCache.entityType.equals(entityType));
    final rows = await query.get();
    return rows.map((r) => r.read(embeddingCache.entityId)!).toList();
  }

  /// Delete embeddings for a specific model version (for re-indexing after model change).
  Future<int> deleteByModelVersion(String modelVersion) {
    return (delete(embeddingCache)
          ..where((e) => e.modelVersion.equals(modelVersion)))
        .go();
  }

  /// Delete all embeddings of a given entity type.
  Future<int> deleteByType(String entityType) {
    return (delete(embeddingCache)
          ..where((e) => e.entityType.equals(entityType)))
        .go();
  }

  /// Clear all embeddings.
  Future<int> clearAll() {
    return delete(embeddingCache).go();
  }

  /// Stream total embedding count (for settings UI).
  Stream<int> watchTotalCount() {
    final countExpr = embeddingCache.id.count();
    final query = selectOnly(embeddingCache)..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }
}
