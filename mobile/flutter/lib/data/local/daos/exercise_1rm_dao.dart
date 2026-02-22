import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/exercise_1rm_table.dart';

part 'exercise_1rm_dao.g.dart';

@DriftAccessor(tables: [CachedExercise1rmHistory])
class Exercise1rmDao extends DatabaseAccessor<AppDatabase>
    with _$Exercise1rmDaoMixin {
  Exercise1rmDao(super.db);

  /// Get the current best 1RM for each exercise (max per exercise).
  Future<Map<String, double>> getAllCurrent1rms(String userId) async {
    final query = selectOnly(cachedExercise1rmHistory)
      ..addColumns([
        cachedExercise1rmHistory.exerciseName,
        cachedExercise1rmHistory.estimated1rm.max(),
      ])
      ..where(cachedExercise1rmHistory.userId.equals(userId))
      ..groupBy([cachedExercise1rmHistory.exerciseName]);

    final rows = await query.get();
    final result = <String, double>{};
    for (final row in rows) {
      final name = row.read(cachedExercise1rmHistory.exerciseName);
      final maxRm =
          row.read(cachedExercise1rmHistory.estimated1rm.max());
      if (name != null && maxRm != null) {
        result[name.toLowerCase()] = maxRm;
      }
    }
    return result;
  }

  /// Insert a new 1RM entry.
  Future<int> insert1rm(CachedExercise1rmHistoryCompanion entry) {
    return into(cachedExercise1rmHistory).insert(entry);
  }

  /// Get full 1RM history for a specific exercise.
  Future<List<CachedExercise1rmHistoryData>> get1rmHistory(
    String userId,
    String exerciseName,
  ) {
    return (select(cachedExercise1rmHistory)
          ..where((t) =>
              t.userId.equals(userId) &
              t.exerciseName.equals(exerciseName.toLowerCase()))
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]))
        .get();
  }

  /// Get all personal records for a user.
  Future<List<CachedExercise1rmHistoryData>> getPrs(String userId) {
    return (select(cachedExercise1rmHistory)
          ..where(
              (t) => t.userId.equals(userId) & t.isPr.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]))
        .get();
  }

  /// Get the latest 1RM entry for a specific exercise.
  Future<CachedExercise1rmHistoryData?> getLatest1rm(
    String userId,
    String exerciseName,
  ) async {
    final results = await (select(cachedExercise1rmHistory)
          ..where((t) =>
              t.userId.equals(userId) &
              t.exerciseName.equals(exerciseName.toLowerCase()))
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)])
          ..limit(1))
        .get();
    return results.isEmpty ? null : results.first;
  }
}
