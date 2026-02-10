import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/workout_logs_table.dart';

part 'workout_log_dao.g.dart';

@DriftAccessor(tables: [CachedWorkoutLogs])
class WorkoutLogDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutLogDaoMixin {
  WorkoutLogDao(super.db);

  Future<void> insertLog(CachedWorkoutLogsCompanion entry) {
    return into(cachedWorkoutLogs).insert(entry);
  }

  Future<List<CachedWorkoutLog>> getLogsForWorkout(String workoutId) {
    return (select(cachedWorkoutLogs)
          ..where((l) => l.workoutId.equals(workoutId))
          ..orderBy([
            (l) => OrderingTerm.asc(l.exerciseName),
            (l) => OrderingTerm.asc(l.setNumber),
          ]))
        .get();
  }

  Future<List<CachedWorkoutLog>> getPendingLogs() {
    return (select(cachedWorkoutLogs)
          ..where((l) => l.syncStatus.equals('pending'))
          ..orderBy([(l) => OrderingTerm.asc(l.completedAt)]))
        .get();
  }

  Future<void> markLogSynced(String logId) {
    return (update(cachedWorkoutLogs)..where((l) => l.id.equals(logId)))
        .write(
      const CachedWorkoutLogsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markLogFailed(String logId, int retryCount) {
    return (update(cachedWorkoutLogs)..where((l) => l.id.equals(logId)))
        .write(
      CachedWorkoutLogsCompanion(
        syncStatus: const Value('failed'),
        syncRetryCount: Value(retryCount),
      ),
    );
  }

  Future<List<CachedWorkoutLog>> getRecentLogs(
    String userId, {
    int limit = 100,
  }) {
    return (select(cachedWorkoutLogs)
          ..where((l) => l.userId.equals(userId))
          ..orderBy([(l) => OrderingTerm.desc(l.completedAt)])
          ..limit(limit))
        .get();
  }
}
