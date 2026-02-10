import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../../core/constants/api_constants.dart';

/// State for pre-cache operations.
class PreCacheState {
  final bool isPreCaching;
  final int cachedDays;
  final DateTime? lastPreCacheAt;
  final String? error;

  const PreCacheState({
    this.isPreCaching = false,
    this.cachedDays = 0,
    this.lastPreCacheAt,
    this.error,
  });

  PreCacheState copyWith({
    bool? isPreCaching,
    int? cachedDays,
    DateTime? lastPreCacheAt,
    String? error,
  }) {
    return PreCacheState(
      isPreCaching: isPreCaching ?? this.isPreCaching,
      cachedDays: cachedDays ?? this.cachedDays,
      lastPreCacheAt: lastPreCacheAt ?? this.lastPreCacheAt,
      error: error ?? this.error,
    );
  }
}

/// Service that pre-caches upcoming workouts and exercise data for offline use.
///
/// Runs on app startup (after initial load) and periodically via workmanager.
/// Downloads upcoming 7 days of workouts → upserts into Drift workouts_table.
/// Extracts unique exercises → caches in exercise_library_table.
class PreCacheService extends StateNotifier<PreCacheState> {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final Ref _ref;

  PreCacheService(this._db, this._apiClient, this._ref)
      : super(const PreCacheState());

  /// Pre-cache upcoming workouts from the server.
  ///
  /// [days] Number of days to pre-cache (default 7).
  /// [userId] The authenticated user's ID.
  Future<void> preCacheUpcomingWorkouts({
    required String userId,
    int days = 7,
    String? gymProfileId,
  }) async {
    if (state.isPreCaching) {
      debugPrint('⚠️ [PreCache] Already pre-caching, skipping');
      return;
    }

    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      debugPrint('📡 [PreCache] Offline, skipping pre-cache');
      return;
    }

    state = state.copyWith(isPreCaching: true, error: null);
    debugPrint('🔍 [PreCache] Starting pre-cache for $days days...');

    try {
      // Fetch upcoming workouts from the batch endpoint
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'days': days,
      };
      if (gymProfileId != null) {
        queryParams['gym_profile_id'] = gymProfileId;
      }

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/api/v1/workouts/upcoming',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('⚠️ [PreCache] No data in response');
          state = state.copyWith(isPreCaching: false);
          return;
        }

        final workouts = (data['workouts'] as List<dynamic>?) ?? [];
        final availableDays = data['total_days_available'] as int? ?? 0;

        // Upsert workouts into local database
        final companions = <CachedWorkoutsCompanion>[];
        final exerciseIds = <String>{};

        for (final w in workouts) {
          final workout = w as Map<String, dynamic>;
          final exercisesJson = workout['exercises_json'];
          final exercisesStr = exercisesJson is String
              ? exercisesJson
              : jsonEncode(exercisesJson);

          companions.add(CachedWorkoutsCompanion(
            id: Value(workout['id'] as String),
            userId: Value(userId),
            name: Value(workout['name'] as String?),
            type: Value(workout['type'] as String?),
            difficulty: Value(workout['difficulty'] as String?),
            scheduledDate: Value(workout['scheduled_date'] as String?),
            isCompleted: Value(workout['is_completed'] as bool? ?? false),
            exercisesJson: Value(exercisesStr),
            durationMinutes: Value(workout['duration_minutes'] as int?),
            generationMethod: Value(workout['generation_method'] as String?),
            generationMetadata: Value(
              workout['generation_metadata'] is Map
                  ? jsonEncode(workout['generation_metadata'])
                  : workout['generation_metadata'] as String?,
            ),
            cachedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
          ));

          // Extract exercise IDs for library caching
          _extractExerciseIds(exercisesJson, exerciseIds);
        }

        // Batch upsert workouts
        if (companions.isNotEmpty) {
          await _db.workoutDao.upsertWorkouts(companions);
          debugPrint('✅ [PreCache] Cached ${companions.length} workouts');
        }

        // Cache exercise details from the workouts
        await _cacheExercisesFromWorkouts(workouts);

        state = state.copyWith(
          isPreCaching: false,
          cachedDays: availableDays,
          lastPreCacheAt: DateTime.now(),
        );

        debugPrint('✅ [PreCache] Pre-cache complete: $availableDays days cached');
      } else {
        throw Exception('Unexpected response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PreCache] Error: $e');
      state = state.copyWith(
        isPreCaching: false,
        error: e.toString(),
      );
    }
  }

  /// Extract exercise IDs from exercises_json for library caching.
  void _extractExerciseIds(dynamic exercisesJson, Set<String> ids) {
    try {
      List<dynamic> exercises;
      if (exercisesJson is String) {
        exercises = jsonDecode(exercisesJson) as List<dynamic>;
      } else if (exercisesJson is List) {
        exercises = exercisesJson;
      } else {
        return;
      }

      for (final ex in exercises) {
        if (ex is Map<String, dynamic>) {
          final id = ex['id'] as String?;
          if (id != null) ids.add(id);
        }
      }
    } catch (_) {
      // Silently ignore parse errors
    }
  }

  /// Cache exercise details extracted from upcoming workouts.
  Future<void> _cacheExercisesFromWorkouts(List<dynamic> workouts) async {
    final exerciseCompanions = <CachedExercisesCompanion>[];
    final seenIds = <String>{};

    for (final w in workouts) {
      final workout = w as Map<String, dynamic>;
      try {
        List<dynamic> exercises;
        final ej = workout['exercises_json'];
        if (ej is String) {
          exercises = jsonDecode(ej) as List<dynamic>;
        } else if (ej is List) {
          exercises = ej;
        } else {
          continue;
        }

        for (final ex in exercises) {
          if (ex is Map<String, dynamic>) {
            final id = (ex['id'] as String?) ?? (ex['exercise_id'] as String?);
            if (id == null || seenIds.contains(id)) continue;
            seenIds.add(id);

            exerciseCompanions.add(CachedExercisesCompanion(
              id: Value(id),
              name: Value((ex['name'] as String?) ?? ''),
              bodyPart: Value(ex['body_part'] as String?),
              equipment: Value(ex['equipment'] as String?),
              targetMuscle: Value(ex['target_muscle'] as String?),
              primaryMuscle: Value(ex['primary_muscle'] as String?),
              secondaryMuscles: Value(
                ex['secondary_muscles'] is List
                    ? jsonEncode(ex['secondary_muscles'])
                    : ex['secondary_muscles'] as String?,
              ),
              videoUrl: Value(ex['video_url'] as String?),
              imageS3Path: Value(ex['image_s3_path'] as String?),
              instructions: Value(ex['instructions'] as String?),
              difficulty: Value(ex['difficulty'] as String?),
              difficultyNum: Value(ex['difficulty_num'] as int?),
              cachedAt: Value(DateTime.now()),
            ));
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PreCache] Error parsing exercises from workout: $e');
      }
    }

    if (exerciseCompanions.isNotEmpty) {
      await _db.exerciseLibraryDao.upsertExercises(exerciseCompanions);
      debugPrint('✅ [PreCache] Cached ${exerciseCompanions.length} exercises');
    }
  }

  /// Cache user profile for offline access.
  Future<void> cacheUserProfile(
      String userId, Map<String, dynamic> profileJson) async {
    await _db.userProfileDao.upsertProfile(
      CachedUserProfilesCompanion(
        id: Value(userId),
        profileJson: Value(jsonEncode(profileJson)),
        cachedAt: Value(DateTime.now()),
        syncStatus: const Value('synced'),
      ),
    );
    debugPrint('✅ [PreCache] User profile cached');
  }

  /// Cache gym profiles for offline access.
  Future<void> cacheGymProfiles(
      String userId, List<Map<String, dynamic>> profiles) async {
    final companions = profiles.map((p) {
      return CachedGymProfilesCompanion(
        id: Value(p['id'] as String),
        userId: Value(userId),
        profileJson: Value(jsonEncode(p)),
        isActive: Value(p['is_active'] as bool? ?? false),
        cachedAt: Value(DateTime.now()),
      );
    }).toList();

    if (companions.isNotEmpty) {
      await _db.gymProfileDao.upsertProfiles(companions);
      debugPrint('✅ [PreCache] Cached ${companions.length} gym profiles');
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Pre-cache service state provider.
final preCacheServiceProvider =
    StateNotifierProvider<PreCacheService, PreCacheState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return PreCacheService(db, apiClient, ref);
});
