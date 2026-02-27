import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'daos/embedding_dao.dart';
import 'daos/exercise_1rm_dao.dart';
import 'daos/exercise_library_dao.dart';
import 'daos/volume_response_dao.dart';
import 'daos/food_dao.dart';
import 'daos/gym_profile_dao.dart';
import 'daos/media_cache_dao.dart';
import 'daos/quick_preset_dao.dart';
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
import 'tables/quick_preset_table.dart';
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
    CachedQuickPresets,
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
    QuickPresetDao,
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
  QuickPresetDao get quickPresetDao => QuickPresetDao(this);

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
      await delete(cachedQuickPresets).go();
    });
  }

  @override
  int get schemaVersion => 6;

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
          if (from < 6) {
            await m.createTable(cachedQuickPresets);
          }
        },
      );
}

Future<String> _getOrCreateDbKey() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  var key = await storage.read(key: 'db_encryption_key');
  if (key == null) {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    key = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: 'db_encryption_key', value: key);
  }
  return key;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Configure sqlite3 to use SQLCipher native library on Android
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitwiz_offline.db'));
    final encryptionKey = await _getOrCreateDbKey();
    // Use NativeDatabase (not createInBackground) because
    // open.overrideFor() only applies to the current isolate.
    // createInBackground spawns a new isolate where the SQLCipher
    // override isn't set, causing "libsqlite3.so not found" errors
    // (especially in WorkManager background isolates).
    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$encryptionKey'");
      },
    );
  });
}
