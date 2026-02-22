import 'dart:math';

import 'package:drift/drift.dart';

import '../data/local/database.dart';

/// Tracks progressive overload by computing 1RM estimates on workout
/// completion and detecting personal records.
///
/// On workout completion:
/// 1. Extract best set per exercise (highest Brzycki 1RM)
/// 2. Compare to stored max in Drift table
/// 3. If PR, mark `isPr = true`
/// 4. Insert into CachedExercise1rmHistory
class ProgressiveOverloadTracker {
  final AppDatabase _db;

  ProgressiveOverloadTracker(this._db);

  /// Process a completed workout's logs for 1RM tracking and PR detection.
  ///
  /// [logs] should be the workout logs from the just-completed workout.
  /// Returns a list of exercise names that achieved a new PR.
  Future<List<String>> processCompletedWorkout(
    String userId,
    List<CachedWorkoutLog> logs,
  ) async {
    if (logs.isEmpty) return [];

    // Group logs by exercise name
    final grouped = <String, List<CachedWorkoutLog>>{};
    for (final log in logs) {
      final name = log.exerciseName.toLowerCase();
      (grouped[name] ??= []).add(log);
    }

    // Get current best 1RMs for comparison
    final current1rms = await _db.exercise1rmDao.getAllCurrent1rms(userId);
    final newPrs = <String>[];

    for (final entry in grouped.entries) {
      final exerciseName = entry.key;
      final exerciseLogs = entry.value;

      // Find the best set (highest Brzycki 1RM) with reps <= 12
      double? bestEstimate;
      double? bestWeight;
      int? bestReps;
      int? bestRpe;

      for (final log in exerciseLogs) {
        final weight = log.weightKg;
        final reps = log.repsCompleted;
        if (weight == null || weight <= 0) continue;
        if (reps == null || reps <= 0 || reps > 12) continue;

        final estimate = _brzycki1rm(weight, reps);
        if (bestEstimate == null || estimate > bestEstimate) {
          bestEstimate = estimate;
          bestWeight = weight;
          bestReps = reps;
          bestRpe = log.rpe;
        }
      }

      if (bestEstimate == null || bestWeight == null || bestReps == null) {
        continue;
      }

      // Check if this is a PR
      final currentMax = current1rms[exerciseName];
      final isPr = currentMax == null || bestEstimate > currentMax;

      if (isPr) {
        newPrs.add(exerciseName);
      }

      // Insert 1RM entry
      await _db.exercise1rmDao.insert1rm(
        CachedExercise1rmHistoryCompanion(
          userId: Value(userId),
          exerciseName: Value(exerciseName),
          estimated1rm: Value(bestEstimate),
          weightKg: Value(bestWeight),
          reps: Value(bestReps),
          rpe: bestRpe != null ? Value(bestRpe) : const Value.absent(),
          isPr: Value(isPr),
          achievedAt: Value(DateTime.now()),
          source: const Value('local'),
        ),
      );
    }

    return newPrs;
  }

  /// Get persistent 1RM estimates merged with RPE-derived ones.
  ///
  /// Persistent (from Drift) wins on conflict since they come from
  /// actual tracked performance.
  Future<Map<String, double>> getMerged1rms(
    String userId,
    Map<String, double> rpeDerived1rms,
  ) async {
    final persistent = await _db.exercise1rmDao.getAllCurrent1rms(userId);

    // Start with RPE-derived, then override with persistent
    final merged = Map<String, double>.from(rpeDerived1rms);
    for (final entry in persistent.entries) {
      merged[entry.key] = entry.value; // persistent wins
    }

    return merged;
  }

  /// Brzycki formula: 1RM = weight * (36 / (37 - reps))
  static double _brzycki1rm(double weight, int reps) {
    if (reps <= 0) return weight;
    if (reps == 1) return weight;
    return weight * (36.0 / (37.0 - reps));
  }
}
