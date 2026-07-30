/// Advanced-tier PROGRESSIVE set persistence (E2E #56).
///
/// Before this, an Advanced-tier session lived only in RAM plus the debounced
/// SharedPreferences checkpoint until the user tapped Finish — at which point
/// `workout_flow_mixin.finalizeWorkoutCompletion` created the workout_log and
/// bulk-POSTed every set at once. An OS kill (or a force-quit, or a crash)
/// mid-session therefore lost the ENTIRE workout from the database: nothing had
/// ever been written server-side.
///
/// The Easy tier already writes each set as it happens
/// (`easy_persistence_helpers.persistEasySet`). This is the same contract for
/// Advanced, deliberately built on the SAME two server guarantees so the two
/// tiers cannot diverge:
///
///   1. `POST /performance/workout-logs` is idempotent on
///      `idempotency_key = 'wklog_<workoutId>'` (migration 2247), and creates
///      the row as `status = 'in_progress'` while `sets_json` is empty — so
///      creating it on the first set does NOT mark the workout complete.
///   2. `POST /performance/logs` upserts on
///      `(workout_log_id, exercise_name, set_number)` — so the finish-time bulk
///      write overwrites exactly the rows written progressively instead of
///      duplicating them.
///
/// Because the log row now already exists when Finish runs, the finalize path
/// PATCHes it (`updateWorkoutLog`) with the full `sets_json` + metadata rather
/// than re-creating it — the idempotent create would return the existing row
/// and silently leave `sets_json` at `[]`.
///
/// Failures are non-fatal and never block the UI: the in-memory session and the
/// SharedPreferences checkpoint remain the client's source of truth, and the
/// finish-time write reconciles everything. What this buys is that a session
/// killed at set 9 of 12 still has 9 real sets in `performance_logs`.
library;

import 'package:flutter/foundation.dart';

import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../models/workout_state.dart';

/// Result of a progressive write — carries the workout-log id so the caller can
/// hold it for subsequent sets and for the finalize PATCH.
typedef ProgressiveLogId = String?;

/// Persist ONE Advanced-tier set immediately after it is finalized.
///
/// [cachedWorkoutLogId] is the id returned by a previous call (null on the
/// first set). Returns the id to cache — either the reused one, the newly
/// created one, or the cached one unchanged when the write could not run
/// (logged out / offline).
Future<ProgressiveLogId> persistAdvancedSet({
  required WorkoutRepository repo,
  required String workoutId,
  required WorkoutExercise exercise,
  required SetLog log,
  required int setNumber,
  required int totalTimeSeconds,
  required String progressionModel,
  double? targetWeightKg,
  int? targetReps,
  String? gymProfileId,
  String? cachedWorkoutLogId,
}) async {
  try {
    final userId = await repo.getCurrentUserId();
    if (userId == null) return cachedWorkoutLogId;

    var logId = cachedWorkoutLogId;
    if (logId == null) {
      final created = await repo.createWorkoutLog(
        workoutId: workoutId,
        userId: userId,
        // Empty on purpose: the server derives status 'in_progress' from an
        // empty set list, so a session abandoned after one set is NOT marked
        // completed. Finalize backfills the real sets_json via PATCH.
        setsJson: '[]',
        totalTimeSeconds: totalTimeSeconds,
        gymProfileId: gymProfileId,
      );
      logId = created?['id'] as String?;
    }
    if (logId == null) return cachedWorkoutLogId;

    // A set with a distance or an extra metric (sled, carry, box jump) is REAL
    // even with zero reps/weight — only truly empty padding rows are
    // placeholders. Mirrors the Easy tier's rule exactly.
    final isPlaceholder = log.reps <= 0 &&
        log.weight <= 0 &&
        (log.distanceMeters == null || log.distanceMeters! <= 0) &&
        log.extraMetrics.isEmpty;

    await repo.logSetPerformance(
      workoutLogId: logId,
      userId: userId,
      exerciseId:
          exercise.exerciseId ?? exercise.libraryId ?? exercise.id ?? exercise.name,
      exerciseName: exercise.name,
      setNumber: setNumber,
      repsCompleted: log.reps,
      weightKg: log.weight,
      setType: log.setType,
      rpe: log.rpe?.toDouble(),
      rir: log.rir,
      notes: log.notes.isEmpty ? null : log.notes,
      aiInputSource: log.aiInputSource,
      targetWeightKg: targetWeightKg,
      targetReps: targetReps,
      progressionModel: progressionModel,
      setDurationSeconds: log.durationSeconds,
      distanceMeters: log.distanceMeters,
      metrics: log.extraMetrics.isEmpty
          ? null
          : Map<String, num>.from(log.extraMetrics),
      restDurationSeconds: log.restDurationSeconds,
      loggingMode: 'advanced',
      gymProfileId: gymProfileId,
      isCompleted: !isPlaceholder,
    );
    return logId;
  } catch (e) {
    // Never surface to the user mid-set: the in-memory session + the
    // SharedPreferences checkpoint still hold the set, and the finish-time
    // bulk write reconciles it. Note media (audio/photos) is uploaded by the
    // finalize path, not here, so nothing is lost by this returning early.
    debugPrint('⚠️ [AdvancedWorkout] progressive set persist failed: $e');
    return cachedWorkoutLogId;
  }
}
