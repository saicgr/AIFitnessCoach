/// Intra-Workout Autoregulator
///
/// Evaluates each completed set during a workout and suggests real-time
/// adjustments based on RPE, rep completion, and set position.
///
/// This is a pure static utility with no database or state persistence.
library;

/// Actions the autoregulator can suggest during a workout.
enum AutoregAction { proceed, reduceWeight, reduceSets, swapExercise }

/// A suggestion from the autoregulator based on set performance.
class AutoregSuggestion {
  /// What action to take.
  final AutoregAction action;

  /// User-facing explanation.
  final String message;

  /// New weight if reducing (null otherwise).
  final double? adjustedWeight;

  /// New set count if reducing (null otherwise).
  final int? adjustedSets;

  const AutoregSuggestion({
    required this.action,
    required this.message,
    this.adjustedWeight,
    this.adjustedSets,
  });
}

/// Evaluates each completed set and suggests real-time adjustments.
///
/// Algorithm:
/// 1. Warm-up check: if warm-up RPE >= 8, reduce working weight
/// 2. Working set check: if RPE is too high, reduce remaining sets
/// 3. If RPE is very low, suggest weight increase
/// 4. If reps are far below target, suggest exercise swap
class IntraWorkoutAutoregulator {
  /// Evaluate a completed set and return a suggestion if adjustment needed.
  ///
  /// Returns null if no adjustment is needed (proceed as normal).
  static AutoregSuggestion? evaluateSet({
    required int setNumber,
    required int totalPlannedSets,
    required int completedReps,
    required int targetReps,
    required double reportedRpe,
    required double? targetRpe,
    required double? workingWeight,
    required bool isWarmup,
  }) {
    // 1. Warm-up set check
    if (isWarmup) {
      if (reportedRpe >= 9 && workingWeight != null) {
        final newWeight = _roundWeight(workingWeight * 0.85);
        return AutoregSuggestion(
          action: AutoregAction.reduceWeight,
          message: 'Warm-up RPE is very high (${reportedRpe.toStringAsFixed(1)}). '
              'Reducing working weight to ${newWeight.toStringAsFixed(1)}kg '
              'and removing 1 working set.',
          adjustedWeight: newWeight,
          adjustedSets: totalPlannedSets > 2 ? totalPlannedSets - 1 : null,
        );
      }
      if (reportedRpe >= 8 && workingWeight != null) {
        final newWeight = _roundWeight(workingWeight * 0.90);
        return AutoregSuggestion(
          action: AutoregAction.reduceWeight,
          message: 'Warm-up felt heavier than expected (RPE ${reportedRpe.toStringAsFixed(1)}). '
              'Consider reducing working weight to ${newWeight.toStringAsFixed(1)}kg.',
          adjustedWeight: newWeight,
        );
      }
      return null;
    }

    // 2. Working set - severe failure
    if (completedReps < (targetReps * 0.7).round() && setNumber >= 1) {
      return AutoregSuggestion(
        action: AutoregAction.swapExercise,
        message: 'Only completed $completedReps of $targetReps reps. '
            'This movement may not be working well today - consider swapping.',
      );
    }

    // 3. Working set - RPE 10 with significant rep miss
    if (reportedRpe >= 10 && completedReps < targetReps - 2) {
      return AutoregSuggestion(
        action: AutoregAction.reduceSets,
        message: 'Hit RPE 10 with ${targetReps - completedReps} reps short. '
            'Stopping here to preserve recovery.',
        adjustedSets: setNumber, // current set is the last
      );
    }

    // 4. Working set - RPE 9.5+ early in the exercise
    if (reportedRpe >= 9.5 && setNumber <= 2 && totalPlannedSets >= 4) {
      final suggestedTotal = setNumber + 1;
      return AutoregSuggestion(
        action: AutoregAction.reduceSets,
        message: 'RPE ${reportedRpe.toStringAsFixed(1)} on set $setNumber of $totalPlannedSets. '
            'Suggesting $suggestedTotal total sets to manage fatigue.',
        adjustedSets: suggestedTotal,
      );
    }

    // 5. Working set - RPE too low, suggest weight increase
    if (reportedRpe <= 6 &&
        completedReps >= targetReps &&
        workingWeight != null &&
        setNumber < totalPlannedSets) {
      final newWeight = _roundWeight(workingWeight * 1.05);
      return AutoregSuggestion(
        action: AutoregAction.reduceWeight, // reusing action for weight change
        message: 'RPE ${reportedRpe.toStringAsFixed(1)} - that was easy! '
            'Try ${newWeight.toStringAsFixed(1)}kg for the next set.',
        adjustedWeight: newWeight,
      );
    }

    return null;
  }

  /// Round weight to nearest 0.5kg.
  static double _roundWeight(double weight) {
    return (weight * 2).round() / 2;
  }
}
