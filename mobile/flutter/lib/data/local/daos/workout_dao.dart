import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/workouts_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [CachedWorkouts])
class WorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Stream<CachedWorkout?> watchTodayWorkout(String userId, String dateStr) {
    return (select(cachedWorkouts)
          ..where((w) => w.userId.equals(userId))
          ..where((w) => w.scheduledDate.equals(dateStr))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<CachedWorkout>> getWorkoutsForDateRange(
    String userId,
    String startDate,
    String endDate,
  ) {
    return (select(cachedWorkouts)
          ..where((w) => w.userId.equals(userId))
          ..where(
            (w) =>
                w.scheduledDate.isBiggerOrEqualValue(startDate) &
                w.scheduledDate.isSmallerOrEqualValue(endDate),
          )
          ..orderBy([(w) => OrderingTerm.asc(w.scheduledDate)]))
        .get();
  }

  Future<void> upsertWorkout(CachedWorkoutsCompanion entry) {
    return into(cachedWorkouts).insertOnConflictUpdate(entry);
  }

  Future<void> upsertWorkouts(List<CachedWorkoutsCompanion> entries) {
    return batch((b) {
      for (final entry in entries) {
        b.insert(cachedWorkouts, entry, onConflict: DoUpdate((_) => entry));
      }
    });
  }

  Future<void> markWorkoutCompleted(String workoutId) {
    return (update(cachedWorkouts)..where((w) => w.id.equals(workoutId)))
        .write(
      const CachedWorkoutsCompanion(isCompleted: Value(true)),
    );
  }

  Future<int> deleteOldWorkouts(DateTime before) {
    return (delete(cachedWorkouts)
          ..where((w) => w.cachedAt.isSmallerThanValue(before)))
        .go();
  }

  Future<CachedWorkout?> getWorkoutById(String workoutId) {
    return (select(cachedWorkouts)..where((w) => w.id.equals(workoutId)))
        .getSingleOrNull();
  }
}
