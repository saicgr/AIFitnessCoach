import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/embedding_dao.dart';
import 'daos/exercise_1rm_dao.dart';
import 'daos/exercise_library_dao.dart';
import 'daos/volume_response_dao.dart';
import 'daos/food_dao.dart';
import 'daos/gym_profile_dao.dart';
import 'daos/media_cache_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/user_profile_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/workout_log_dao.dart';
import 'tables/embedding_cache_table.dart';
import 'tables/exercise_1rm_table.dart';
import 'tables/exercise_library_table.dart';
import 'tables/volume_response_table.dart';
import 'tables/exercise_media_cache_table.dart';
import 'tables/food_table.dart';
import 'tables/gym_profiles_table.dart';
import 'tables/pending_sync_queue_table.dart';
import 'tables/user_profile_table.dart';
import 'tables/workout_logs_table.dart';
import 'tables/workouts_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    CachedWorkouts,
    CachedExercises,
    CachedUserProfiles,
    CachedWorkoutLogs,
    PendingSyncQueue,
    CachedExerciseMedia,
    CachedGymProfiles,
    CachedFoods,
    EmbeddingCache,
    CachedExercise1rmHistory,
    CachedVolumeResponses,
  ],
  daos: [
    WorkoutDao,
    ExerciseLibraryDao,
    UserProfileDao,
    WorkoutLogDao,
    SyncQueueDao,
    MediaCacheDao,
    GymProfileDao,
    FoodDao,
    EmbeddingDao,
    Exercise1rmDao,
    VolumeResponseDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  WorkoutDao get workoutDao => WorkoutDao(this);
  ExerciseLibraryDao get exerciseLibraryDao => ExerciseLibraryDao(this);
  UserProfileDao get userProfileDao => UserProfileDao(this);
  WorkoutLogDao get workoutLogDao => WorkoutLogDao(this);
  SyncQueueDao get syncQueueDao => SyncQueueDao(this);
  MediaCacheDao get mediaCacheDao => MediaCacheDao(this);
  GymProfileDao get gymProfileDao => GymProfileDao(this);
  FoodDao get foodDao => FoodDao(this);
  EmbeddingDao get embeddingDao => EmbeddingDao(this);
  Exercise1rmDao get exercise1rmDao => Exercise1rmDao(this);
  VolumeResponseDao get volumeResponseDao => VolumeResponseDao(this);

  Future<void> clearAllUserData() {
    return transaction(() async {
      await delete(cachedWorkouts).go();
      await delete(cachedExercises).go();
      await delete(cachedUserProfiles).go();
      await delete(cachedWorkoutLogs).go();
      await delete(pendingSyncQueue).go();
      await delete(cachedExerciseMedia).go();
      await delete(cachedGymProfiles).go();
      await delete(cachedFoods).go();
      await delete(embeddingCache).go();
      await delete(cachedExercise1rmHistory).go();
      await delete(cachedVolumeResponses).go();
    });
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedFoods);
          }
          if (from < 3) {
            await m.createTable(embeddingCache);
          }
          if (from < 4) {
            await m.createTable(cachedExercise1rmHistory);
          }
          if (from < 5) {
            await m.createTable(cachedVolumeResponses);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitwiz_offline.db'));
    return NativeDatabase.createInBackground(file);
  });
}
