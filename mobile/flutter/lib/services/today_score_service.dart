/// Today Score — the deterministic scoring engine.
///
/// Pure Dart: takes a plain [TodayScoreInputs] snapshot and returns a
/// [TodayScore]. No Flutter, no providers, no I/O — so it is fully
/// unit-testable and behaves identically every run (per project rule:
/// no LLM / no randomness in scoring).
///
/// THE RULE
/// --------
/// The score is the percentage of *today's actual plan* you have completed.
/// Only the contributors that genuinely apply today are counted, and their
/// weights renormalize to 100% over whatever applies:
///
///   score = round( Σ( effectiveWeightᵢ × completionᵢ ) × 100 )
///   effectiveWeightᵢ = baseWeightᵢ / Σ(baseWeight of applicable contributors)
///
/// This one rule covers every edge case — rest day, no plan, no Health
/// Connect, and any combination — without faking a zero or a fake 100.
library;

import '../data/models/today_score.dart';

/// Immutable snapshot of everything the score is computed from.
///
/// The provider layer (Phase 2) assembles this from the live workout,
/// nutrition and health providers; the service never reaches for state itself.
class TodayScoreInputs {
  // ---- Workout (Train) -----------------------------------------------------

  /// Whether the user has a workout plan at all. `false` ⇒ brand-new user.
  final bool hasPlan;

  /// Whether a workout is actually scheduled for *today*. This is `false` both
  /// on a scheduled rest day and when there is no plan.
  final bool hasWorkoutScheduledToday;

  /// Whether today is an intentional rest day inside an existing plan.
  /// Only meaningful when [hasWorkoutScheduledToday] is `false`.
  final bool isRestDay;

  /// Whether today's scheduled workout has been completed.
  final bool workoutComplete;

  /// Exercises finished / total in today's workout (for partial credit while
  /// a session is in progress).
  final int exercisesDone;
  final int exercisesTotal;

  /// Display label for today's workout, e.g. "Leg day". May be null.
  final String? workoutLabel;

  // ---- Nutrition (Fuel) ----------------------------------------------------

  /// Whether the user has nutrition targets set (calorie + protein goals).
  final bool hasNutritionTargets;

  final int calorieTarget;
  final int caloriesLogged;
  final int proteinTargetG;
  final int proteinLoggedG;

  // ---- Activity (Move) -----------------------------------------------------

  /// Whether Health Connect / Apple Health is linked and providing steps.
  final bool healthConnected;

  final int steps;
  final int stepGoal;

  // ---- Sleep ---------------------------------------------------------------

  /// Whether last-night's sleep summary is available (Health Connect /
  /// HealthKit linked AND a sleep summary was logged). When false the Sleep
  /// contributor is `applicable: false` and renormalizes out — not zeroed.
  final bool sleepAvailable;

  /// Last night's sleep score (0-100) from [computeSleepScore]. Only
  /// meaningful when [sleepAvailable] is true.
  final int sleepScore;

  /// Minutes asleep last night — used only for the status text.
  final int sleepMinutes;

  const TodayScoreInputs({
    this.hasPlan = false,
    this.hasWorkoutScheduledToday = false,
    this.isRestDay = false,
    this.workoutComplete = false,
    this.exercisesDone = 0,
    this.exercisesTotal = 0,
    this.workoutLabel,
    this.hasNutritionTargets = false,
    this.calorieTarget = 0,
    this.caloriesLogged = 0,
    this.proteinTargetG = 0,
    this.proteinLoggedG = 0,
    this.healthConnected = false,
    this.steps = 0,
    this.stepGoal = 0,
    this.sleepAvailable = false,
    this.sleepScore = 0,
    this.sleepMinutes = 0,
  });
}

/// Compute the Today Score from an inputs snapshot. Pure and deterministic.
TodayScore computeTodayScore(TodayScoreInputs i, {DateTime? now}) {
  // --- Train --------------------------------------------------------------
  final trainApplicable = i.hasWorkoutScheduledToday;
  final double trainCompletion;
  if (i.workoutComplete) {
    trainCompletion = 1.0;
  } else if (i.exercisesTotal > 0) {
    trainCompletion = (i.exercisesDone / i.exercisesTotal).clamp(0.0, 1.0);
  } else {
    trainCompletion = 0.0;
  }

  // --- Fuel ---------------------------------------------------------------
  final fuelApplicable = i.hasNutritionTargets;
  final double proteinFrac = i.proteinTargetG > 0
      ? (i.proteinLoggedG / i.proteinTargetG).clamp(0.0, 1.0)
      : 0.0;
  final double calorieFrac = i.calorieTarget > 0
      ? (i.caloriesLogged / i.calorieTarget).clamp(0.0, 1.0)
      : 0.0;
  // Fuel = how much of your protein + calorie targets you've hit so far.
  // It fills naturally through the day as meals are logged.
  final double fuelCompletion = (proteinFrac + calorieFrac) / 2.0;

  // --- Move ---------------------------------------------------------------
  final moveApplicable = i.healthConnected;
  final double moveCompletion = i.stepGoal > 0
      ? (i.steps / i.stepGoal).clamp(0.0, 1.0)
      : 0.0;

  // --- Sleep --------------------------------------------------------------
  // Only applicable when last-night sleep data exists. Score / 100 = completion
  // — the underlying sleep score is itself a 0-100 fraction of "a healthy
  // night", so dividing here keeps the contributor on the same 0-1 scale as
  // the others.
  final sleepApplicable = i.sleepAvailable;
  final double sleepCompletion = sleepApplicable
      ? (i.sleepScore / 100.0).clamp(0.0, 1.0)
      : 0.0;

  // --- Renormalize --------------------------------------------------------
  double applicableWeightSum = 0.0;
  if (trainApplicable) applicableWeightSum += ContributorKind.train.baseWeight;
  if (fuelApplicable) applicableWeightSum += ContributorKind.fuel.baseWeight;
  if (moveApplicable) applicableWeightSum += ContributorKind.move.baseWeight;
  if (sleepApplicable) applicableWeightSum += ContributorKind.sleep.baseWeight;

  final bool isSetupState = applicableWeightSum <= 0.0;

  double effWeight(ContributorKind kind, bool applicable) {
    if (!applicable || isSetupState) return 0.0;
    return kind.baseWeight / applicableWeightSum;
  }

  final train = ScoreContributor(
    kind: ContributorKind.train,
    applicable: trainApplicable,
    completion: trainCompletion,
    effectiveWeight: effWeight(ContributorKind.train, trainApplicable),
    statusText: _trainStatus(i),
  );
  final fuel = ScoreContributor(
    kind: ContributorKind.fuel,
    applicable: fuelApplicable,
    completion: fuelCompletion,
    effectiveWeight: effWeight(ContributorKind.fuel, fuelApplicable),
    statusText: _fuelStatus(i),
  );
  final move = ScoreContributor(
    kind: ContributorKind.move,
    applicable: moveApplicable,
    completion: moveCompletion,
    effectiveWeight: effWeight(ContributorKind.move, moveApplicable),
    statusText: _moveStatus(i),
  );
  final sleep = ScoreContributor(
    kind: ContributorKind.sleep,
    applicable: sleepApplicable,
    completion: sleepCompletion,
    effectiveWeight: effWeight(ContributorKind.sleep, sleepApplicable),
    statusText: _sleepStatus(i),
  );

  final contributors = [train, fuel, move, sleep];
  final double raw =
      contributors.fold(0.0, (sum, c) => sum + c.points); // 0–100
  final int score = isSetupState ? 0 : raw.round().clamp(0, 100);

  return TodayScore(
    score: score,
    contributors: contributors,
    isSetupState: isSetupState,
    generatedAt: now ?? DateTime.now(),
  );
}

// ---- Status text -----------------------------------------------------------

String _trainStatus(TodayScoreInputs i) {
  if (!i.hasWorkoutScheduledToday) {
    if (i.isRestDay) return 'Rest day · recover well';
    return 'Add a plan to count training';
  }
  if (i.workoutComplete) return 'Workout complete';
  if (i.exercisesDone <= 0) {
    final label = i.workoutLabel?.trim();
    return (label != null && label.isNotEmpty)
        ? '$label · not started'
        : 'Not started';
  }
  return '${i.exercisesDone} of ${i.exercisesTotal} exercises';
}

String _fuelStatus(TodayScoreInputs i) {
  if (!i.hasNutritionTargets) return 'Set your nutrition targets';
  if (i.proteinTargetG > 0 && i.proteinLoggedG >= i.proteinTargetG) {
    return 'Protein goal hit';
  }
  // Qualitative, not a gram count — the exact protein number lives in the
  // Nutrition card, so the score card summarizes rather than repeating it.
  final ratio = i.proteinTargetG > 0
      ? i.proteinLoggedG / i.proteinTargetG
      : 0.0;
  return ratio < 0.5 ? 'Protein running low' : 'Almost at your protein goal';
}

String _moveStatus(TodayScoreInputs i) {
  if (!i.healthConnected) return 'Connect Health to count steps';
  final remaining = i.stepGoal - i.steps;
  if (remaining <= 0) return 'Step goal hit';
  return '${_thousands(remaining)} steps to go';
}

String _sleepStatus(TodayScoreInputs i) {
  if (!i.sleepAvailable) return 'Connect Health to count sleep';
  if (i.sleepScore >= 85) return 'Slept well';
  if (i.sleepScore >= 70) return 'Solid night';
  if (i.sleepMinutes > 0) {
    final h = i.sleepMinutes ~/ 60;
    final m = i.sleepMinutes % 60;
    return '${h}h ${m}m last night';
  }
  return 'No sleep recorded';
}

/// Format an int with thousands separators ("2588" → "2,588").
String _thousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (int idx = 0; idx < s.length; idx++) {
    if (idx > 0 && (s.length - idx) % 3 == 0) buf.write(',');
    buf.write(s[idx]);
  }
  return buf.toString();
}
