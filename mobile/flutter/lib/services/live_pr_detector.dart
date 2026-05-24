/// Live mid-set PR detector.
///
/// Watches sets as the user logs them during an active workout, fires a
/// snackbar-worthy [PrDetectionResult] the moment a set surpasses the user's
/// previous all-time estimated 1RM (Brzycki). Maintains per-session state so
/// the same PR cannot re-fire twice for the same exercise — only a STRICTLY
/// higher estimated 1RM during the session re-fires.
///
/// Caller (the active workout screen / a composer) is responsible for:
///   1. Passing the previous all-time 1RM in kg for that exercise (server-fed).
///   2. Calling [resetSession] when a new workout starts.
///   3. Calling [retractIfBelow] when the user edits a previously-logged set
///      DOWNWARD (because the fired PR may now be invalid).
///
/// Bodyweight / cardio sets where weight is 0 do NOT fire (Brzycki on 0 is
/// meaningless for a strength PR).
library;

import 'dart:math' as math;

/// Result returned when a set qualifies as a new PR. The caller surfaces this
/// via [showLivePrSnackBar] (or any other UI surface).
class PrDetectionResult {
  /// Exercise that just hit a PR.
  final String exerciseId;

  /// Logged weight (kg) of the set that triggered the PR.
  final double weightKg;

  /// Logged reps of the set that triggered the PR.
  final int reps;

  /// Newly-estimated 1RM in kg (Brzycki formula).
  final double newEstimated1rmKg;

  /// User's previous all-time estimated 1RM in kg (pre-this-session).
  /// Null only when there was no prior history at all — in that case the
  /// detector suppresses, so a non-null value is guaranteed here.
  final double previousAllTime1rmKg;

  /// Improvement in kg (always positive when constructed).
  double get improvementKg => newEstimated1rmKg - previousAllTime1rmKg;

  /// Improvement as a percentage of the prior 1RM.
  double get improvementPercent =>
      previousAllTime1rmKg <= 0 ? 0 : (improvementKg / previousAllTime1rmKg) * 100;

  const PrDetectionResult({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.newEstimated1rmKg,
    required this.previousAllTime1rmKg,
  });
}

/// Stateful PR detector — instantiate once per workout session.
class LivePrDetector {
  /// exerciseId → highest fired estimated 1RM (kg) during this session.
  /// A new fire requires a STRICTLY higher 1RM than what's already in this map.
  final Map<String, double> _sessionFiredPrs = <String, double>{};

  /// Visible for inspection / debugging only — do not mutate from outside.
  Map<String, double> get sessionFiredPrs => Map.unmodifiable(_sessionFiredPrs);

  /// Brzycki 1RM estimate. Formula caps validity around ~10 reps but the
  /// caller decides whether to evaluate (we still compute for completeness).
  /// Returns 0 for non-positive weight or non-positive reps.
  static double brzycki1rm({required double weightKg, required int reps}) {
    if (weightKg <= 0 || reps <= 0) return 0;
    // Brzycki: 1RM = weight / (1.0278 - 0.0278 * reps).
    // At reps == 1 this returns weight exactly.
    final denom = 1.0278 - (0.0278 * reps);
    if (denom <= 0) return 0; // reps too high; formula degenerates (~37 reps).
    return weightKg / denom;
  }

  /// Evaluate a freshly-logged set. Returns a [PrDetectionResult] if (and
  /// only if) this set establishes a NEW session-best AND beats the user's
  /// all-time pre-session 1RM. Otherwise returns null.
  ///
  /// Suppression rules (return null):
  ///   * [previousAllTime1rmKg] is null → first set ever for this exercise;
  ///     no baseline to beat, so no PR snackbar.
  ///   * [weightKg] <= 0 or [reps] <= 0 → bodyweight / invalid input.
  ///   * Computed 1RM <= previousAllTime1rmKg → not a PR.
  ///   * Computed 1RM <= already-fired session-best for this exercise → an
  ///     earlier set in this session already replaced it.
  PrDetectionResult? evaluateSet({
    required String exerciseId,
    required double weightKg,
    required int reps,
    required double? previousAllTime1rmKg,
  }) {
    // First set ever — no baseline; don't fire (avoids "PR" on first log).
    if (previousAllTime1rmKg == null) return null;
    if (weightKg <= 0 || reps <= 0) return null;

    final est = brzycki1rm(weightKg: weightKg, reps: reps);
    if (est <= 0) return null;

    // Must beat the all-time baseline.
    if (est <= previousAllTime1rmKg) return null;

    // Must also beat anything already fired in THIS session for this exercise.
    final firedBest = _sessionFiredPrs[exerciseId];
    if (firedBest != null && est <= firedBest) return null;

    _sessionFiredPrs[exerciseId] = est;
    return PrDetectionResult(
      exerciseId: exerciseId,
      weightKg: weightKg,
      reps: reps,
      newEstimated1rmKg: est,
      previousAllTime1rmKg: previousAllTime1rmKg,
    );
  }

  /// Recompute the session-best for [exerciseId] from the full live list of
  /// sets the user has currently logged (after an edit). If no remaining set
  /// still beats [previousAllTime1rmKg], the prior fired PR is RETRACTED
  /// (removed from session memory) so that a later legitimately-better set
  /// can re-fire.
  ///
  /// Note: this retracts the *flag*; visual snackbars are transient and not
  /// rolled back. Callers can also call this with an empty [allLoggedSets]
  /// to simply drop the session memory for that exercise after a full delete.
  void retractIfBelow({
    required String exerciseId,
    required List<({double weightKg, int reps})> allLoggedSets,
    required double? previousAllTime1rmKg,
  }) {
    if (previousAllTime1rmKg == null) {
      _sessionFiredPrs.remove(exerciseId);
      return;
    }

    double bestBeating = 0;
    for (final s in allLoggedSets) {
      final est = brzycki1rm(weightKg: s.weightKg, reps: s.reps);
      if (est > previousAllTime1rmKg && est > bestBeating) {
        bestBeating = est;
      }
    }

    if (bestBeating <= 0) {
      // No remaining set beats the baseline → retract entirely.
      _sessionFiredPrs.remove(exerciseId);
    } else {
      // Pin the session-best down to the highest STILL-valid PR, so a future
      // set lower than this one won't spuriously re-fire.
      _sessionFiredPrs[exerciseId] = bestBeating;
    }
  }

  /// Reset all per-session state. Call when a new workout session begins.
  void resetSession() {
    _sessionFiredPrs.clear();
  }

  /// Round a kg value to the nearest pound when displaying — purely a helper
  /// for the snackbar widget; kept here to avoid duplicating the conversion.
  static double kgToLb(double kg) => kg * 2.2046226218;
  static double lbToKg(double lb) => lb / 2.2046226218;

  /// Pretty-rounded 1RM for display (nearest whole unit).
  static int roundedDisplay(double value) {
    final r = value.round();
    if (r < 0) return 0;
    return r;
  }

  /// Tiny epsilon exposed for tests / numerical comparisons.
  static double get epsilon => math.max(1e-9, 0);
}
