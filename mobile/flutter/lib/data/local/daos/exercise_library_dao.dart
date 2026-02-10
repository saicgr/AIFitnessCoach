import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/exercise_library_table.dart';

part 'exercise_library_dao.g.dart';

@DriftAccessor(tables: [CachedExercises])
class ExerciseLibraryDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseLibraryDaoMixin {
  ExerciseLibraryDao(super.db);

  Future<CachedExercise?> getExerciseById(String id) {
    return (select(cachedExercises)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CachedExercise>> searchExercises(
    String query, {
    String? bodyPart,
    String? equipment,
  }) {
    return (select(cachedExercises)
          ..where((e) {
            Expression<bool> condition = e.name.like('%$query%');
            if (bodyPart != null) {
              condition = condition & e.bodyPart.equals(bodyPart);
            }
            if (equipment != null) {
              condition = condition & e.equipment.equals(equipment);
            }
            return condition;
          }))
        .get();
  }

  Future<void> upsertExercises(List<CachedExercisesCompanion> entries) {
    return batch((b) {
      for (final entry in entries) {
        b.insert(cachedExercises, entry, onConflict: DoUpdate((_) => entry));
      }
    });
  }

  Future<List<CachedExercise>> getFavoriteExercises() {
    return (select(cachedExercises)
          ..where((e) => e.isFavorite.equals(true)))
        .get();
  }

  Future<List<CachedExercise>> getAllCachedExercises() {
    return select(cachedExercises).get();
  }
}
