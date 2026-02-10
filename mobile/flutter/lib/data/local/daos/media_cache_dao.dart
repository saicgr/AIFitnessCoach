import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/exercise_media_cache_table.dart';

part 'media_cache_dao.g.dart';

@DriftAccessor(tables: [CachedExerciseMedia])
class MediaCacheDao extends DatabaseAccessor<AppDatabase>
    with _$MediaCacheDaoMixin {
  MediaCacheDao(super.db);

  Future<CachedExerciseMediaData?> getMediaPath(
    String exerciseId,
    String mediaType,
  ) {
    return (select(cachedExerciseMedia)
          ..where(
            (m) =>
                m.exerciseId.equals(exerciseId) &
                m.mediaType.equals(mediaType),
          ))
        .getSingleOrNull();
  }

  Future<void> upsertMedia(CachedExerciseMediaCompanion entry) {
    return into(cachedExerciseMedia).insertOnConflictUpdate(entry);
  }

  Future<List<CachedExerciseMediaData>> deleteUnusedMedia(
    DateTime before,
  ) {
    return transaction(() async {
      final items = await (select(cachedExerciseMedia)
            ..where((m) => m.lastAccessedAt.isSmallerThanValue(before)))
          .get();
      await (delete(cachedExerciseMedia)
            ..where((m) => m.lastAccessedAt.isSmallerThanValue(before)))
          .go();
      return items;
    });
  }

  Future<int> getTotalCacheSize() async {
    final sumExpr = cachedExerciseMedia.fileSizeBytes.sum();
    final query = selectOnly(cachedExerciseMedia)..addColumns([sumExpr]);
    final result = await query.getSingle();
    return result.read(sumExpr) ?? 0;
  }
}
