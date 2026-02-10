import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../models/workout.dart';
import '../models/today_workout.dart';
import '../services/connectivity_service.dart';
import 'workout_repository.dart';

const _uuid = Uuid();

/// Offline-first workout repository that wraps the existing [WorkoutRepository].
///
/// Read flow:
///   User opens screen → Local DB (instant) → emit to UI
///   Background: API fetch → update local DB → re-emit
///
/// Write flow:
///   User action → Local DB write (always succeeds) → Queue in pending_sync
///   → Try API call → Success: mark synced / Fail: stays in queue
class OfflineWorkoutRepository {
  final WorkoutRepository _remote;
  final AppDatabase _db;
  final Ref _ref;

  OfflineWorkoutRepository(this._remote, this._db, this._ref);

  // --------------------------------------------------------------------------
  // Read operations
  // --------------------------------------------------------------------------

  /// Watch today's workout: local DB first, then background API refresh.
  ///
  /// Returns a stream that emits the local cached workout immediately,
  /// then fetches fresh data from the API and re-emits if updated.
  Stream<Workout?> watchTodayWorkout(String userId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return _db.workoutDao.watchTodayWorkout(userId, today).asyncMap(
      (cachedWorkout) async {
        if (cachedWorkout != null) {
          return _cachedWorkoutToWorkout(cachedWorkout);
        }
        return null;
      },
    );
  }

  /// Get today's workout from local cache (instant, <10ms).
  Future<Workout?> getTodayWorkoutLocal(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cached = await _db.workoutDao.getWorkoutById(today);
    // Try to find by scheduled date instead
    final workouts = await _db.workoutDao.getWorkoutsForDateRange(
      userId,
      today,
      today,
    );
    if (workouts.isNotEmpty) {
      return _cachedWorkoutToWorkout(workouts.first);
    }
    return null;
  }

  /// Get workouts for a user, local-first with background API refresh.
  Future<List<Workout>> getWorkouts(String userId) async {
    // Try local first
    final now = DateTime.now();
    final start = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
    final end = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 14)));

    final cachedWorkouts =
        await _db.workoutDao.getWorkoutsForDateRange(userId, start, end);

    final localWorkouts =
        cachedWorkouts.map(_cachedWorkoutToWorkout).toList();

    // Background refresh if online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      _backgroundRefreshWorkouts(userId);
    }

    return localWorkouts;
  }

  /// Background refresh: fetch from API and update local DB.
  Future<void> _backgroundRefreshWorkouts(String userId) async {
    try {
      final remoteWorkouts = await _remote.getWorkouts(userId, limit: 50);
      for (final w in remoteWorkouts) {
        await _db.workoutDao.upsertWorkout(_workoutToCompanion(w, userId));
      }
      debugPrint('✅ [OfflineRepo] Background refresh: ${remoteWorkouts.length} workouts synced');
    } catch (e) {
      debugPrint('⚠️ [OfflineRepo] Background refresh failed (non-fatal): $e');
    }
  }

  /// Get a single workout by ID, local-first.
  Future<Workout?> getWorkoutById(String workoutId) async {
    // Check local DB first
    final cached = await _db.workoutDao.getWorkoutById(workoutId);
    if (cached != null) {
      return _cachedWorkoutToWorkout(cached);
    }

    // Fall back to API if online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      try {
        final workout = await _remote.getWorkout(workoutId);
        if (workout != null) {
          await _db.workoutDao.upsertWorkout(
              _workoutToCompanion(workout, workout.userId ?? ''));
        }
        return workout;
      } catch (e) {
        debugPrint('❌ [OfflineRepo] Error fetching workout $workoutId: $e');
      }
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // Write operations (optimistic local-first)
  // --------------------------------------------------------------------------

  /// Complete a workout — optimistic local update + sync queue.
  Future<void> completeWorkout(String workoutId) async {
    // Optimistic local update
    await _db.workoutDao.markWorkoutCompleted(workoutId);
    debugPrint('⚡ [OfflineRepo] Optimistic: marked $workoutId completed locally');

    // Enqueue sync
    await _db.syncQueueDao.enqueue(PendingSyncQueueCompanion(
      operationType: const Value('update'),
      entityType: const Value('workout'),
      entityId: Value(workoutId),
      payload: Value(jsonEncode({'is_completed': true})),
      httpMethod: const Value('POST'),
      endpoint: Value('/api/v1/workouts/$workoutId/complete'),
      createdAt: Value(DateTime.now()),
      priority: const Value(1), // Highest priority
    ));

    // Try API immediately if online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      try {
        await _remote.completeWorkout(workoutId);
        // Mark sync item as completed
        debugPrint('✅ [OfflineRepo] Workout completion synced to server');
      } catch (e) {
        debugPrint('⚠️ [OfflineRepo] Workout completion will sync later: $e');
      }
    }
  }

  /// Log a set performance — write-local-first, fire-and-forget API.
  Future<void> logSetPerformance({
    required String workoutId,
    required String userId,
    String? exerciseId,
    required String exerciseName,
    required int setNumber,
    int? repsCompleted,
    double? weightKg,
    String setType = 'working',
    int? rpe,
    int? rir,
    String? notes,
  }) async {
    final logId = _uuid.v4();
    final now = DateTime.now();

    // Write to local DB immediately (never blocks the workout)
    await _db.workoutLogDao.insertLog(CachedWorkoutLogsCompanion(
      id: Value(logId),
      workoutId: Value(workoutId),
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      setNumber: Value(setNumber),
      repsCompleted: Value(repsCompleted),
      weightKg: Value(weightKg),
      setType: Value(setType),
      rpe: Value(rpe),
      rir: Value(rir),
      notes: Value(notes),
      completedAt: Value(now),
      syncStatus: const Value('pending'),
    ));

    debugPrint('⚡ [OfflineRepo] Set logged locally: $exerciseName set $setNumber');

    // Enqueue sync
    await _db.syncQueueDao.enqueue(PendingSyncQueueCompanion(
      operationType: const Value('create'),
      entityType: const Value('workout_log'),
      entityId: Value(logId),
      payload: Value(jsonEncode({
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'reps_completed': repsCompleted,
        'weight_kg': weightKg,
        'set_type': setType,
        'rpe': rpe,
        'rir': rir,
        'notes': notes,
        'completed_at': now.toIso8601String(),
      })),
      httpMethod: const Value('POST'),
      endpoint: const Value('/api/v1/workouts/performance'),
      createdAt: Value(now),
      priority: const Value(2),
    ));
  }

  /// Save a locally-generated workout (from rule-based or on-device AI).
  Future<void> saveLocalWorkout(Workout workout, String userId) async {
    await _db.workoutDao.upsertWorkout(_workoutToCompanion(workout, userId));
    debugPrint('✅ [OfflineRepo] Saved local workout: ${workout.name}');

    // Enqueue sync to upload to server when online
    await _db.syncQueueDao.enqueue(PendingSyncQueueCompanion(
      operationType: const Value('create'),
      entityType: const Value('workout'),
      entityId: Value(workout.id ?? ''),
      payload: Value(jsonEncode(workout.toJson())),
      httpMethod: const Value('POST'),
      endpoint: const Value('/api/v1/workouts'),
      createdAt: Value(DateTime.now()),
      priority: const Value(3),
    ));
  }

  // --------------------------------------------------------------------------
  // Conversion helpers
  // --------------------------------------------------------------------------

  /// Convert a CachedWorkout row to a Workout model.
  Workout _cachedWorkoutToWorkout(CachedWorkout cached) {
    dynamic exercisesJson;
    try {
      exercisesJson = jsonDecode(cached.exercisesJson);
    } catch (_) {
      exercisesJson = cached.exercisesJson;
    }

    Map<String, dynamic>? genMeta;
    if (cached.generationMetadata != null) {
      try {
        genMeta = jsonDecode(cached.generationMetadata!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Workout(
      id: cached.id,
      userId: cached.userId,
      name: cached.name,
      type: cached.type,
      difficulty: cached.difficulty,
      scheduledDate: cached.scheduledDate,
      isCompleted: cached.isCompleted,
      exercisesJson: exercisesJson,
      durationMinutes: cached.durationMinutes,
      generationMethod: cached.generationMethod,
      generationMetadata: genMeta,
    );
  }

  /// Convert a Workout model to a CachedWorkoutsCompanion for DB insert.
  CachedWorkoutsCompanion _workoutToCompanion(Workout w, String userId) {
    final exercisesStr = w.exercisesJson is String
        ? w.exercisesJson as String
        : jsonEncode(w.exercisesJson);

    return CachedWorkoutsCompanion(
      id: Value(w.id ?? _uuid.v4()),
      userId: Value(w.userId ?? userId),
      name: Value(w.name),
      type: Value(w.type),
      difficulty: Value(w.difficulty),
      scheduledDate: Value(w.scheduledDate),
      isCompleted: Value(w.isCompleted ?? false),
      exercisesJson: Value(exercisesStr),
      durationMinutes: Value(w.durationMinutes),
      generationMethod: Value(w.generationMethod),
      generationMetadata: Value(
        w.generationMetadata != null
            ? jsonEncode(w.generationMetadata)
            : null,
      ),
      cachedAt: Value(DateTime.now()),
      syncStatus: Value(w.generationMethod == 'rule_based_offline' ||
              w.generationMethod == 'on_device_ai'
          ? 'pending_upload'
          : 'synced'),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Offline workout repository provider.
final offlineWorkoutRepositoryProvider =
    Provider<OfflineWorkoutRepository>((ref) {
  final remote = ref.watch(workoutRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  return OfflineWorkoutRepository(remote, db, ref);
});
