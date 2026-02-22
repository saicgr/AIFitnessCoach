import 'dart:math';

import '../data/local/database.dart';

/// Decision for how to adjust an exercise based on RPE history.
enum RpeDecision {
  /// RPE < 7.5 for 2+ sessions: increase weight
  progress,

  /// RPE < 8.5: keep same weight
  maintain,

  /// RPE < 9.5: same weight, reduce sets
  reduceVolume,

  /// RPE >= 9.5: reduce weight to 85%
  deload,
}

/// Summary of RPE/performance data for a single exercise.
class ExerciseRpeSummary {
  final String exerciseName;

  /// Exponentially-weighted mean RPE (recent sessions weigh more).
  final double avgRpe;

  /// Number of sessions with RPE data for this exercise.
  final int sessionCount;

  /// Last recorded weight in kg.
  final double? lastWeight;

  /// Last recorded reps.
  final int? lastReps;

  /// Estimated 1RM via Brzycki formula from best set (reps <= 12).
  final double? estimated1rm;

  /// When this exercise was last performed.
  final DateTime? lastPerformed;

  /// Recommended adjustment decision.
  final RpeDecision decision;

  const ExerciseRpeSummary({
    required this.exerciseName,
    required this.avgRpe,
    required this.sessionCount,
    this.lastWeight,
    this.lastReps,
    this.estimated1rm,
    this.lastPerformed,
    required this.decision,
  });
}

/// Service that reads local workout logs and computes per-exercise RPE
/// summaries with exponential recency weighting.
///
/// This enables the quick workout engine to:
/// - Auto-populate 1RM estimates from past performance
/// - Adjust intensity/volume based on RPE trends
/// - Make progress/maintain/reduce/deload decisions per exercise
class RpeFeedbackService {
  final AppDatabase _db;

  RpeFeedbackService(this._db);

  /// Compute RPE summaries for all exercises the user has logged.
  ///
  /// Reads up to [maxLogs] recent logs, groups by exercise, and computes:
  /// - Exponentially-weighted average RPE
  /// - Brzycki 1RM from best qualifying set
  /// - Decision thresholds matching backend progression_service.py
  Future<Map<String, ExerciseRpeSummary>> computeSummaries(
    String userId, {
    int maxLogs = 500,
  }) async {
    final logs = await _db.workoutLogDao.getRecentLogs(userId, limit: maxLogs);
    if (logs.isEmpty) return {};

    // Group logs by exercise name (lowercase)
    final grouped = <String, List<CachedWorkoutLog>>{};
    for (final log in logs) {
      final name = log.exerciseName.toLowerCase();
      (grouped[name] ??= []).add(log);
    }

    final summaries = <String, ExerciseRpeSummary>{};

    for (final entry in grouped.entries) {
      final name = entry.key;
      final exerciseLogs = entry.value;

      // Sort by completedAt descending (most recent first)
      exerciseLogs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      // Group into sessions by date
      final sessions = _groupIntoSessions(exerciseLogs);

      // Compute exponentially-weighted average RPE
      // Weight = 0.7^sessions_ago (most recent session = sessions_ago 0)
      double weightedRpeSum = 0;
      double weightSum = 0;
      int sessionsWithRpe = 0;

      for (int i = 0; i < sessions.length; i++) {
        final sessionLogs = sessions[i];
        final sessionRpes = sessionLogs
            .where((l) => l.rpe != null)
            .map((l) => l.rpe!.toDouble())
            .toList();
        if (sessionRpes.isEmpty) continue;

        final sessionAvgRpe =
            sessionRpes.reduce((a, b) => a + b) / sessionRpes.length;
        final w = pow(0.7, i).toDouble();
        weightedRpeSum += sessionAvgRpe * w;
        weightSum += w;
        sessionsWithRpe++;
      }

      final avgRpe =
          weightSum > 0 ? weightedRpeSum / weightSum : 0.0;

      // Find best set for Brzycki 1RM (reps <= 12, has weight > 0)
      double? best1rm;
      for (final log in exerciseLogs) {
        final weight = log.weightKg;
        final reps = log.repsCompleted;
        if (weight == null || weight <= 0) continue;
        if (reps == null || reps <= 0 || reps > 12) continue;

        final rm = _brzycki1rm(weight, reps);
        if (best1rm == null || rm > best1rm) {
          best1rm = rm;
        }
      }

      // Last performed data
      final latest = exerciseLogs.first;
      final lastWeight = latest.weightKg;
      final lastReps = latest.repsCompleted;
      final lastPerformed = latest.completedAt;

      // Decision thresholds (match backend progression_service.py)
      final decision = _computeDecision(avgRpe, sessionsWithRpe);

      summaries[name] = ExerciseRpeSummary(
        exerciseName: name,
        avgRpe: avgRpe,
        sessionCount: sessionsWithRpe,
        lastWeight: lastWeight,
        lastReps: lastReps,
        estimated1rm: best1rm,
        lastPerformed: lastPerformed,
        decision: decision,
      );
    }

    return summaries;
  }

  /// Compute global average RPE across all exercises.
  static double computeGlobalAvgRpe(Map<String, ExerciseRpeSummary> summaries) {
    if (summaries.isEmpty) return 0;
    final rpes = summaries.values
        .where((s) => s.sessionCount > 0)
        .map((s) => s.avgRpe)
        .toList();
    if (rpes.isEmpty) return 0;
    return rpes.reduce((a, b) => a + b) / rpes.length;
  }

  /// Extract 1RM estimates as a map of exercise name -> estimated 1RM.
  static Map<String, double> extract1rmEstimates(
    Map<String, ExerciseRpeSummary> summaries,
  ) {
    final result = <String, double>{};
    for (final entry in summaries.entries) {
      if (entry.value.estimated1rm != null) {
        result[entry.key] = entry.value.estimated1rm!;
      }
    }
    return result;
  }

  /// Group exercise logs into sessions based on date.
  ///
  /// Logs from the same calendar day are considered one session.
  List<List<CachedWorkoutLog>> _groupIntoSessions(
    List<CachedWorkoutLog> logs,
  ) {
    if (logs.isEmpty) return [];

    final sessions = <List<CachedWorkoutLog>>[];
    var currentSession = <CachedWorkoutLog>[logs.first];
    var currentDate = _dateOnly(logs.first.completedAt);

    for (int i = 1; i < logs.length; i++) {
      final logDate = _dateOnly(logs[i].completedAt);
      if (logDate == currentDate) {
        currentSession.add(logs[i]);
      } else {
        sessions.add(currentSession);
        currentSession = [logs[i]];
        currentDate = logDate;
      }
    }
    sessions.add(currentSession);

    return sessions;
  }

  /// Brzycki formula: 1RM = weight * (36 / (37 - reps))
  static double _brzycki1rm(double weight, int reps) {
    if (reps <= 0) return weight;
    if (reps == 1) return weight;
    return weight * (36.0 / (37.0 - reps));
  }

  /// Compute decision based on average RPE and session count.
  static RpeDecision _computeDecision(double avgRpe, int sessionCount) {
    if (sessionCount < 2) return RpeDecision.maintain;
    if (avgRpe >= 9.5) return RpeDecision.deload;
    if (avgRpe >= 8.5) return RpeDecision.reduceVolume;
    if (avgRpe >= 7.5) return RpeDecision.maintain;
    return RpeDecision.progress;
  }

  static String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
