import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/database.dart';

/// Current version of the bundled exercise library asset.
/// Bump this when re-exporting from Supabase to force a re-seed.
const int _kSeedVersion = 1;

const String _kSeedVersionKey = 'exercise_library_seed_version';

/// Loads the bundled exercise library JSON asset into the Drift database.
///
/// Mirrors the pattern used by [FoodDatabaseService] for food_seed_data.json.
class ExerciseLibraryLoader {
  ExerciseLibraryLoader._();

  /// Seed the exercise library if not already done (or if version bumped).
  ///
  /// 1. Check SharedPreferences for last seed version.
  /// 2. Check DB count >= 200 AND version matches → skip.
  /// 3. Otherwise load asset, parse, batch upsert.
  static Future<void> seedDatabaseIfNeeded(AppDatabase db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt(_kSeedVersionKey) ?? 0;

      if (storedVersion >= _kSeedVersion) {
        final count = await getSeededCount(db);
        if (count >= 200) {
          debugPrint(
              '✅ [ExerciseLibrary] Already seeded v$storedVersion ($count exercises)');
          return;
        }
      }

      debugPrint(
          '🔍 [ExerciseLibrary] Seeding from bundled asset (v$_kSeedVersion)...');

      final jsonString =
          await rootBundle.loadString('assets/data/exercise_library.json');
      final List<dynamic> exercises =
          jsonDecode(jsonString) as List<dynamic>;

      final companions = exercises.map((e) {
        final ex = e as Map<String, dynamic>;
        return _mapToCompanion(ex);
      }).toList();

      await db.exerciseLibraryDao.upsertExercises(companions);
      await prefs.setInt(_kSeedVersionKey, _kSeedVersion);

      debugPrint(
          '✅ [ExerciseLibrary] Seeded ${companions.length} exercises (v$_kSeedVersion)');
    } catch (e) {
      debugPrint('❌ [ExerciseLibrary] Seed error: $e');
    }
  }

  /// Return the number of cached exercises in the database.
  static Future<int> getSeededCount(AppDatabase db) async {
    final all = await db.exerciseLibraryDao.getAllCachedExercises();
    return all.length;
  }

  /// Map a JSON exercise object to a [CachedExercisesCompanion].
  static CachedExercisesCompanion _mapToCompanion(Map<String, dynamic> ex) {
    // secondary_muscles comes as a JSON array → store as comma-separated string
    String? secondaryMuscles;
    final sm = ex['secondary_muscles'];
    if (sm is List) {
      secondaryMuscles = sm.map((e) => e.toString()).join(', ');
    } else if (sm is String) {
      secondaryMuscles = sm;
    }

    // Parse difficulty_level to int
    int? difficultyNum;
    final dl = ex['difficulty_level'];
    if (dl is int) {
      difficultyNum = dl;
    } else if (dl is String) {
      difficultyNum = int.tryParse(dl);
    }

    return CachedExercisesCompanion(
      id: Value(ex['id'] as String),
      name: Value((ex['name'] as String?) ?? ''),
      bodyPart: Value(ex['body_part'] as String?),
      equipment: Value(ex['equipment'] as String?),
      targetMuscle: Value(ex['target_muscle'] as String?),
      primaryMuscle: Value(ex['target_muscle'] as String?),
      secondaryMuscles: Value(secondaryMuscles),
      videoUrl: Value(ex['video_url'] as String?),
      imageS3Path: Value(ex['image_url'] as String?),
      difficulty: Value(dl?.toString()),
      difficultyNum: Value(difficultyNum),
      cachedAt: Value(DateTime.now()),
    );
  }
}
