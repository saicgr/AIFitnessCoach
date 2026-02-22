/// Goal-specific training parameters decoupled from difficulty.
///
/// This separates "what you're training for" (goal) from "how hard"
/// (difficulty), allowing combinations like "easy strength" or "hard endurance".
class GoalParameters {
  final int repsMin;
  final int repsMax;
  final double intensityPercent; // % of 1RM
  final int baseRestCompound;   // seconds
  final int baseRestIsolation;  // seconds
  final int workingSetsCompound;
  final int workingSetsIsolation;

  const GoalParameters({
    required this.repsMin,
    required this.repsMax,
    required this.intensityPercent,
    required this.baseRestCompound,
    required this.baseRestIsolation,
    required this.workingSetsCompound,
    required this.workingSetsIsolation,
  });
}

/// Research-backed goal parameters.
const Map<String, GoalParameters> goalParametersTable = {
  'strength': GoalParameters(
    repsMin: 3, repsMax: 6,
    intensityPercent: 85.0,
    baseRestCompound: 180, baseRestIsolation: 120,
    workingSetsCompound: 5, workingSetsIsolation: 4,
  ),
  'hypertrophy': GoalParameters(
    repsMin: 8, repsMax: 12,
    intensityPercent: 72.5,
    baseRestCompound: 120, baseRestIsolation: 75,
    workingSetsCompound: 4, workingSetsIsolation: 3,
  ),
  'endurance': GoalParameters(
    repsMin: 15, repsMax: 20,
    intensityPercent: 60.0,
    baseRestCompound: 60, baseRestIsolation: 45,
    workingSetsCompound: 3, workingSetsIsolation: 3,
  ),
  'power': GoalParameters(
    repsMin: 1, repsMax: 5,
    intensityPercent: 90.0,
    baseRestCompound: 240, baseRestIsolation: 150,
    workingSetsCompound: 5, workingSetsIsolation: 3,
  ),
};
