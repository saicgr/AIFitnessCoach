import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/quick_preset_table.dart';

part 'quick_preset_dao.g.dart';

@DriftAccessor(tables: [CachedQuickPresets])
class QuickPresetDao extends DatabaseAccessor<AppDatabase>
    with _$QuickPresetDaoMixin {
  QuickPresetDao(super.db);

  /// Load all presets for user, sorted: favorites first, then useCount desc, then recent.
  Future<List<CachedQuickPreset>> getPresetsForUser(String userId) {
    return (select(cachedQuickPresets)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([
            (p) => OrderingTerm.desc(p.isFavorite),
            (p) => OrderingTerm.desc(p.useCount),
            (p) => OrderingTerm.desc(p.createdAt),
          ]))
        .get();
  }

  /// Insert or update a preset.
  Future<void> upsertPreset(CachedQuickPresetsCompanion entry) {
    return into(cachedQuickPresets).insertOnConflictUpdate(entry);
  }

  /// Delete by id.
  Future<void> deletePreset(String id) {
    return (delete(cachedQuickPresets)..where((p) => p.id.equals(id))).go();
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(String id) async {
    final preset = await (select(cachedQuickPresets)
          ..where((p) => p.id.equals(id)))
        .getSingle();
    await (update(cachedQuickPresets)..where((p) => p.id.equals(id))).write(
      CachedQuickPresetsCompanion(isFavorite: Value(!preset.isFavorite)),
    );
  }

  /// Bump use count by 1.
  Future<void> recordUsage(String id) async {
    final preset = await (select(cachedQuickPresets)
          ..where((p) => p.id.equals(id)))
        .getSingle();
    await (update(cachedQuickPresets)..where((p) => p.id.equals(id))).write(
      CachedQuickPresetsCompanion(useCount: Value(preset.useCount + 1)),
    );
  }

  /// Count non-favorite, non-AI presets for a user (candidates for eviction).
  Future<int> countEvictablePresets(String userId) async {
    final countExpr = cachedQuickPresets.id.count();
    final query = selectOnly(cachedQuickPresets)
      ..addColumns([countExpr])
      ..where(cachedQuickPresets.userId.equals(userId) &
          cachedQuickPresets.isFavorite.equals(false) &
          cachedQuickPresets.isAiGenerated.equals(false));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  /// Delete the oldest evictable preset (non-favorite, non-AI, lowest useCount, oldest).
  Future<void> evictOldest(String userId) async {
    final oldest = await (select(cachedQuickPresets)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isFavorite.equals(false) &
              p.isAiGenerated.equals(false))
          ..orderBy([
            (p) => OrderingTerm.asc(p.useCount),
            (p) => OrderingTerm.asc(p.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (oldest != null) {
      await (delete(cachedQuickPresets)
            ..where((p) => p.id.equals(oldest.id)))
          .go();
    }
  }

  /// Delete all presets for a user.
  Future<void> deleteAllForUser(String userId) {
    return (delete(cachedQuickPresets)
          ..where((p) => p.userId.equals(userId)))
        .go();
  }
}
