import 'package:flutter/material.dart';

part 'set_progression_part_set_progression_pattern.dart';


/// Rep range boundaries based on the user's primary training goal.
///
/// Sources: NSCA, ACSM, Schoenfeld et al. (2017)
class TrainingGoalRepRange {
  final int minReps;
  final int maxReps;
  const TrainingGoalRepRange(this.minReps, this.maxReps);

  /// Default rep target for this goal (midpoint of range).
  int get defaultReps => ((minReps + maxReps) / 2).round();

  /// Clamp a rep count to this goal's range.
  int clampReps(int reps) => reps.clamp(minReps, maxReps);

  static TrainingGoalRepRange forGoal(String? primaryGoal) {
    switch (primaryGoal) {
      case 'muscle_strength':
        return const TrainingGoalRepRange(1, 5);
      case 'muscle_hypertrophy':
        return const TrainingGoalRepRange(6, 12);
      case 'strength_hypertrophy':
        return const TrainingGoalRepRange(4, 8);
      case 'endurance':
        return const TrainingGoalRepRange(15, 30);
      default:
        return const TrainingGoalRepRange(6, 15); // General fitness
    }
  }
}

// ============================================================================
// ADAPTIVE PROGRESSION — Evidence-Based Autoregulation
//
// 3-Signal Decision Model:
//   Signal 1: RIR deviation (primary) — RP Hypertrophy / Israetel
//   Signal 2: Rep ratio fallback (when no RIR) — Alpha Progression / RTS
//   Signal 3: Cumulative fatigue override — Pareja-Blanco et al. 2017
//
// Pattern-specific:
//   Drop Sets: Fink et al. 2018 (20-25% drops, adaptive)
//   Myo-Reps: Borge Fagerli protocol (activation 12-20, mini-sets 3-5)
//   Rest-Pause: Prestes et al. 2019 (15-20s rest, terminate at <2 reps)
//   RPT: Berkhan / Leangains (10% drops, +2 reps per set)
// ============================================================================

/// Adaptive progression: recalculates remaining set targets based on actual
/// performance in completed sets.
List<ProgressionSetTarget> adaptTargets({
  required SetProgressionPattern pattern,
  required List<ProgressionSetTarget> originalTargets,
  required List<CompletedSetData> completedSets,
  required double increment,
  required int totalSets,
}) {
  if (completedSets.isEmpty || completedSets.length >= totalSets) {
    return originalTargets;
  }

  switch (pattern) {
    case SetProgressionPattern.dropSets:
      return _adaptDropSets(originalTargets, completedSets, increment);
    case SetProgressionPattern.myoReps:
      return _adaptMyoReps(originalTargets, completedSets, increment);
    case SetProgressionPattern.restPause:
      return _adaptRestPause(originalTargets, completedSets, increment);
    default:
      return _adaptWeightRepPattern(
        originalTargets, completedSets, increment,
      );
  }
}

/// Adapt weight/rep patterns: Pyramid Up, Reverse Pyramid, Top Set + Back-Off,
/// Straight Sets. Uses 3-signal decision model.
List<ProgressionSetTarget> _adaptWeightRepPattern(
  List<ProgressionSetTarget> originalTargets,
  List<CompletedSetData> completedSets,
  double increment,
) {
  final completedCount = completedSets.length;
  final lastCompleted = completedSets.last;
  final lastTarget = completedCount <= originalTargets.length
      ? originalTargets[completedCount - 1]
      : null;

  if (lastTarget == null || lastTarget.isAmrap) return originalTargets;

  final targetReps = lastTarget.reps;
  if (targetReps <= 0) return originalTargets;

  final rir = lastCompleted.rir;
  final repRatio = lastCompleted.reps / targetReps;

  // --- Step 1: Rep ratio catches extreme over/under (regardless of RIR) ---
  // This ensures cases like "RIR 3 but only 2/8 reps" always trigger a reduction.
  int incrementAdjust = 0;
  if (repRatio < 0.40) {
    incrementAdjust = -2; // Catastrophic miss (<40% of target)
  } else if (repRatio < 0.65) {
    incrementAdjust = -1; // Significant miss (<65% of target)
  } else if (repRatio > 1.30) {
    incrementAdjust = 2; // Way over target (>130%)
  }
  // --- Step 2: RIR fine-tunes within normal range (0.65-1.30 rep ratio) ---
  else if (rir != null) {
    if (rir >= 4 && repRatio >= 1.0) {
      incrementAdjust = 2; // Way too easy — lots in tank + hit target
    } else if (rir >= 3 && repRatio >= 1.0) {
      incrementAdjust = 1; // Too easy — 3+ reps in reserve at target
    } else if (rir == 0) {
      incrementAdjust = -1; // Had to go to failure — weight is too heavy
    } else if (rir <= 1 && repRatio < 0.85) {
      incrementAdjust = -1; // Near failure + under target
    }
  }
  // --- Step 3: No RIR data — rep ratio only (conservative) ---
  else {
    if (repRatio >= 1.20) {
      incrementAdjust = 1; // Exceeded by 20%+
    }
    // repRatio < 0.65 already caught in Step 1
  }

  // --- Signal 3: Cumulative fatigue override (Pareja-Blanco 2017) ---
  if (completedSets.length >= 2) {
    final set1Score = completedSets.first.performanceScore;
    final lastScore = lastCompleted.performanceScore;
    if (set1Score > 0) {
      final fatiguePct = (set1Score - lastScore) / set1Score;
      if (fatiguePct > 0.25 && incrementAdjust >= 0) {
        incrementAdjust = -1; // >25% performance drop overrides
      }
    }
  }

  debugPrint('⚙️ [Adapt] repRatio=${repRatio.toStringAsFixed(2)}, RIR=$rir → incrementAdjust=$incrementAdjust');

  if (incrementAdjust == 0) return originalTargets;

  // Apply adjustment to remaining sets
  final adjusted = List<ProgressionSetTarget>.from(originalTargets);
  for (int i = completedCount; i < adjusted.length; i++) {
    final original = adjusted[i];
    if (original.isAmrap) continue;

    final newWeight = _snapToIncrement(
      original.weight + incrementAdjust * increment, increment,
    ).clamp(increment, 9999.0);
    // Inverse: weight up → reps down, weight down → reps up
    // Min 6 reps for non-AMRAP (safety floor for non-failure training)
    final minReps = original.isAmrap ? 0 : 6;
    final newReps = (original.reps - incrementAdjust).clamp(minReps, 30);

    adjusted[i] = ProgressionSetTarget(
      setNumber: original.setNumber,
      weight: newWeight,
      reps: newReps,
      isAmrap: false,
    );
  }
  return adjusted;
}

/// Adapt Drop Sets (Fink et al. 2018).
/// <5 reps: 28% drop | 6-12 reps: 20% (standard) | >12 reps: 15% drop.
List<ProgressionSetTarget> _adaptDropSets(
  List<ProgressionSetTarget> originalTargets,
  List<CompletedSetData> completedSets,
  double increment,
) {
  final completedCount = completedSets.length;
  final lastCompleted = completedSets.last;

  double dropFactor;
  if (lastCompleted.reps < 5) {
    dropFactor = 0.72; // 28% drop — too heavy
  } else if (lastCompleted.reps > 12) {
    dropFactor = 0.85; // 15% drop — too light
  } else {
    return originalTargets; // 6-12: ideal, keep standard
  }

  final adjusted = List<ProgressionSetTarget>.from(originalTargets);
  for (int i = completedCount; i < adjusted.length; i++) {
    final baseWeight = i == completedCount
        ? lastCompleted.weight
        : adjusted[i - 1].weight;
    adjusted[i] = ProgressionSetTarget(
      setNumber: i + 1,
      weight: _snapToIncrement(baseWeight * dropFactor, increment),
      reps: 0,
      isAmrap: true,
    );
  }
  return adjusted;
}

/// Adapt Myo-Reps (Borge Fagerli protocol).
/// Activation: <9 reps = -15%, 9-11 = -5%, 12-20 = ideal, >25 = +15%.
/// Mini-sets: <3 reps = reduce weight 10%.
List<ProgressionSetTarget> _adaptMyoReps(
  List<ProgressionSetTarget> originalTargets,
  List<CompletedSetData> completedSets,
  double increment,
) {
  final completedCount = completedSets.length;
  final lastCompleted = completedSets.last;

  if (completedCount == 1) {
    // Just completed activation set
    final activationReps = lastCompleted.reps;
    double weightFactor;

    if (activationReps < 9) {
      weightFactor = 0.85; // Too heavy
    } else if (activationReps < 12) {
      weightFactor = 0.95; // Slightly heavy
    } else if (activationReps > 25) {
      weightFactor = 1.15; // Too light
    } else {
      return originalTargets; // 12-25: ideal
    }

    final newWeight = _snapToIncrement(
      lastCompleted.weight * weightFactor, increment,
    );
    final miniSetReps = activationReps >= 20 ? 3 : 5;

    final adjusted = List<ProgressionSetTarget>.from(originalTargets);
    for (int i = 1; i < adjusted.length; i++) {
      adjusted[i] = ProgressionSetTarget(
        setNumber: i + 1,
        weight: newWeight,
        reps: miniSetReps,
        isAmrap: false,
      );
    }
    return adjusted;
  }

  // Mini-set: <3 reps means weight is too heavy
  if (completedCount >= 2 && lastCompleted.reps < 3) {
    final newWeight = _snapToIncrement(
      lastCompleted.weight * 0.9, increment,
    );
    final adjusted = List<ProgressionSetTarget>.from(originalTargets);
    for (int i = completedCount; i < adjusted.length; i++) {
      adjusted[i] = ProgressionSetTarget(
        setNumber: i + 1,
        weight: newWeight,
        reps: 3,
        isAmrap: false,
      );
    }
    return adjusted;
  }

  return originalTargets;
}

/// Adapt Rest-Pause (Prestes et al. 2019).
/// Initial <6 reps: reduce weight 10% for remaining segments.
List<ProgressionSetTarget> _adaptRestPause(
  List<ProgressionSetTarget> originalTargets,
  List<CompletedSetData> completedSets,
  double increment,
) {
  final completedCount = completedSets.length;
  final lastCompleted = completedSets.last;

  if (completedCount == 1 && lastCompleted.reps < 6) {
    final newWeight = _snapToIncrement(
      lastCompleted.weight * 0.90, increment,
    );
    final adjusted = List<ProgressionSetTarget>.from(originalTargets);
    for (int i = 1; i < adjusted.length; i++) {
      adjusted[i] = ProgressionSetTarget(
        setNumber: i + 1,
        weight: newWeight,
        reps: 0,
        isAmrap: true,
      );
    }
    return adjusted;
  }

  return originalTargets;
}

double _snapToIncrement(double weight, double increment) {
  if (increment <= 0) return weight;
  return (weight / increment).round() * increment;
}
