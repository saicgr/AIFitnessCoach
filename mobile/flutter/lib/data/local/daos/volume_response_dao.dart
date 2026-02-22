import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/volume_response_table.dart';

part 'volume_response_dao.g.dart';

@DriftAccessor(tables: [CachedVolumeResponses])
class VolumeResponseDao extends DatabaseAccessor<AppDatabase>
    with _$VolumeResponseDaoMixin {
  VolumeResponseDao(super.db);

  /// Get recent volume responses for a specific muscle.
  Future<List<CachedVolumeResponse>> getResponsesForMuscle(
    String userId,
    String muscle, {
    int limit = 20,
  }) {
    return (select(cachedVolumeResponses)
          ..where((t) =>
              t.userId.equals(userId) &
              t.muscle.equals(muscle.toLowerCase()))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit))
        .get();
  }

  /// Insert a new volume response record.
  Future<int> insertResponse(CachedVolumeResponsesCompanion entry) {
    return into(cachedVolumeResponses).insert(entry);
  }

  /// Get the set count at which overreaching was first detected for a muscle.
  Future<int?> getOverreachingThreshold(String userId, String muscle) async {
    final overreachingWeeks = await (select(cachedVolumeResponses)
          ..where((t) =>
              t.userId.equals(userId) &
              t.muscle.equals(muscle.toLowerCase()) &
              t.wasOverreaching.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.totalSets)])
          ..limit(1))
        .get();

    if (overreachingWeeks.isEmpty) return null;
    return overreachingWeeks.first.totalSets;
  }

  /// Get all volume responses for a user (for analytics).
  Future<List<CachedVolumeResponse>> getAllResponses(String userId) {
    return (select(cachedVolumeResponses)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  /// Delete old responses (keep last 24 weeks).
  Future<int> pruneOldResponses(String userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 168)); // 24 weeks
    return (delete(cachedVolumeResponses)
          ..where((t) =>
              t.userId.equals(userId) & t.recordedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
