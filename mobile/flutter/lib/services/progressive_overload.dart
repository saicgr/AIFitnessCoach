import 'dart:math';

import '../data/models/exercise.dart';
import 'equipment_context.dart';

/// Progressive overload logic for offline workout generation.
///
/// Ported from backend/api/v1/workouts/utils.py:
/// - calculate_working_weight_from_1rm
/// - apply_1rm_weights_to_exercises
///
/// Generates SetTarget lists with warmup sets, working sets, and
/// appropriate RPE/RIR progressions.

/// Equipment-based weight increment for rounding.
const Map<String, double> _weightIncrements = {
  'barbell': 2.5,
  'dumbbell': 2.0,
  'machine': 5.0,
  'cable': 2.5,
  'kettlebell': 4.0,
  'bodyweight': 0,
};

/// Calculate working weight from a 1RM and intensity percentage.
///
/// Rounds to the nearest equipment increment for practical gym use.
double calculateWorkingWeight(
  double oneRepMax,
  double intensityPercent, {
  String equipmentType = 'barbell',
}) {
  final clamped = intensityPercent.clamp(50.0, 100.0);
  final raw = oneRepMax * (clamped / 100.0);

  final increment = _weightIncrements[equipmentType] ?? 2.5;
  if (increment > 0) {
    return ((raw / increment).round() * increment).roundToDouble();
  }
  return raw.roundToDouble();
}

/// Get the training intensity percentage based on goal and fitness level.
///
/// Returns a percentage of 1RM to use as working weight.
double getIntensityPercent({
  required String goal,
  required String fitnessLevel,
}) {
  // Base intensity by goal
  double base;
  switch (goal.toLowerCase()) {
    case 'strength':
      base = 85.0;
    case 'muscle_hypertrophy':
    case 'hypertrophy':
      base = 72.5;
    case 'power':
      base = 90.0;
    case 'endurance':
    case 'muscular_endurance':
      base = 60.0;
    default:
      base = 72.5; // Default to hypertrophy
  }

  // Adjust by fitness level
  switch (fitnessLevel.toLowerCase()) {
    case 'beginner':
      return base - 5.0;
    case 'advanced':
      return base + 5.0;
    default: // intermediate
      return base;
  }
}

/// Detect equipment type from an equipment string.
String detectEquipmentType(String? equipment) {
  if (equipment == null || equipment.isEmpty) return 'barbell';
  final lower = equipment.toLowerCase();
  if (lower.contains('dumbbell')) return 'dumbbell';
  if (lower.contains('cable')) return 'cable';
  if (lower.contains('machine') || lower.contains('smith')) return 'machine';
  if (lower.contains('kettlebell')) return 'kettlebell';
  if (lower.contains('bodyweight') ||
      lower.contains('body weight') ||
      lower.contains('none')) {
    return 'bodyweight';
  }
  return 'barbell';
}

/// Generate SetTarget list for an exercise.
///
/// Produces warmup sets (for compounds with known 1RM), working sets with
/// progressive RPE/RIR, and appropriate rep ranges for the training goal.
List<SetTarget> generateSetTargets({
  required String exerciseName,
  double? oneRepMax,
  required String fitnessLevel,
  required String goal,
  required bool isCompound,
  String? equipment,
}) {
  final targets = <SetTarget>[];
  final equipType = detectEquipmentType(equipment);
  final intensity = getIntensityPercent(goal: goal, fitnessLevel: fitnessLevel);

  // Determine rep range based on goal
  int minReps;
  int maxReps;
  int workingSets;
  switch (goal.toLowerCase()) {
    case 'strength':
      minReps = 3;
      maxReps = 6;
      workingSets = isCompound ? 5 : 4;
    case 'power':
      minReps = 1;
      maxReps = 5;
      workingSets = isCompound ? 5 : 3;
    case 'endurance':
    case 'muscular_endurance':
      minReps = 15;
      maxReps = 20;
      workingSets = 3;
    default: // hypertrophy
      minReps = 8;
      maxReps = 12;
      workingSets = isCompound ? 4 : 3;
  }

  // Calculate working weight if 1RM is known
  double? workingWeight;
  if (oneRepMax != null && oneRepMax > 0) {
    workingWeight = calculateWorkingWeight(oneRepMax, intensity,
        equipmentType: equipType);
  }

  int setNumber = 1;

  // Add warmup set for compound exercises with known weights
  if (isCompound && workingWeight != null && workingWeight > 0) {
    targets.add(SetTarget(
      setNumber: setNumber++,
      setType: 'warmup',
      targetReps: maxReps + 2, // More reps at lighter weight
      targetWeightKg: _roundWeight(workingWeight * 0.5, equipType),
      targetRpe: 5,
      targetRir: 5,
    ));
  }

  // Working sets with progressive RPE/RIR
  for (int i = 0; i < workingSets; i++) {
    // RPE increases across sets: 7 -> 8 -> 9
    final rpe = (7 + i).clamp(7, 9);
    // RIR decreases: 3 -> 2 -> 1
    final rir = (3 - i).clamp(1, 3);

    // Rep target decreases slightly across sets for strength
    final reps = goal.toLowerCase() == 'strength'
        ? (maxReps - i).clamp(minReps, maxReps)
        : ((minReps + maxReps) ~/ 2); // Middle of range for hypertrophy

    targets.add(SetTarget(
      setNumber: setNumber++,
      setType: 'working',
      targetReps: reps,
      targetWeightKg: workingWeight,
      targetRpe: rpe,
      targetRir: rir,
    ));
  }

  return targets;
}

/// Get rest period in seconds based on goal and exercise type.
int _getRestSeconds({required String goal, required bool isCompound}) {
  switch (goal.toLowerCase()) {
    case 'strength':
      return isCompound ? 180 : 120;
    case 'power':
      return isCompound ? 240 : 150;
    case 'endurance':
    case 'muscular_endurance':
      return isCompound ? 60 : 45;
    default: // hypertrophy
      return isCompound ? 120 : 75;
  }
}

/// Get the number of total sets (including warmup) for an exercise.
int getTotalSets({
  required String goal,
  required bool isCompound,
  bool hasWarmup = false,
}) {
  int working;
  switch (goal.toLowerCase()) {
    case 'strength':
      working = isCompound ? 5 : 4;
    case 'power':
      working = isCompound ? 5 : 3;
    case 'endurance':
    case 'muscular_endurance':
      working = 3;
    default:
      working = isCompound ? 4 : 3;
  }
  return working + (hasWarmup ? 1 : 0);
}

/// Get the default rep count for display (middle of range).
int getDefaultReps({required String goal}) {
  switch (goal.toLowerCase()) {
    case 'strength':
      return 5;
    case 'power':
      return 3;
    case 'endurance':
    case 'muscular_endurance':
      return 17;
    default:
      return 10;
  }
}

/// Get rest seconds for a specific exercise context.
int getRestSeconds({required String goal, required bool isCompound}) {
  return max(30, _getRestSeconds(goal: goal, isCompound: isCompound));
}

/// Round weight to nearest equipment increment.
double _roundWeight(double weight, String equipType) {
  final increment = _weightIncrements[equipType] ?? 2.5;
  if (increment <= 0) return weight.roundToDouble();
  return ((weight / increment).round() * increment).roundToDouble();
}

// ==========================================================================
// Equipment-aware weight snapping
// ==========================================================================

/// Result of rep/rest adjustment after weight snapping.
class RepAdjustment {
  final int adjustedReps;
  final int adjustedRestSeconds;
  final int? adjustedRpe;
  final int? adjustedRir;
  final String? note;
  final bool useTempo;

  const RepAdjustment({
    required this.adjustedReps,
    required this.adjustedRestSeconds,
    this.adjustedRpe,
    this.adjustedRir,
    this.note,
    this.useTempo = false,
  });
}

/// Snap a target weight to the nearest available in [inventory].
///
/// Delegates to [EquipmentInventory.snap] which uses binary search.
WeightSnapResult snapToAvailable(
  double targetWeight,
  EquipmentInventory inventory,
) {
  return inventory.snap(targetWeight);
}

/// Calculate rep and rest adjustments based on the snap ratio.
///
/// [ratio] = targetWeight / snappedWeight:
/// - 1.0: no change
/// - 1.01-1.20: +1-2 reps
/// - >1.20: +30% reps, -15% rest, suggest tempo
/// - <1.0 (heavier): reduce reps proportionally
RepAdjustment calculateRepAdjustment(
  int baseReps,
  int baseRestSeconds,
  double ratio,
  String goal,
) {
  if ((ratio - 1.0).abs() < 0.01) {
    return RepAdjustment(
      adjustedReps: baseReps,
      adjustedRestSeconds: baseRestSeconds,
    );
  }

  int adjustedReps = baseReps;
  int adjustedRest = baseRestSeconds;
  int? adjustedRpe;
  int? adjustedRir;
  String? note;
  bool useTempo = false;

  if (ratio > 1.20) {
    // Inverse Epley: targetReps = 30 * (targetWeight / snappedWeight - 1)
    // This is more accurate than flat +30% when weight changes significantly
    final epleyReps = (30 * (ratio - 1)).round();
    adjustedReps = epleyReps > 0 ? max(baseReps, epleyReps + baseReps ~/ 2) : (baseReps * 1.3).round();
    adjustedRest = (baseRestSeconds * 0.85).round();
    useTempo = true;
    adjustedRpe = null;
    adjustedRir = null;
    note = 'Epley-adjusted reps for equivalent stimulus (lighter available weight)';
  } else if (ratio > 1.0) {
    // Slightly lighter — small bump
    final extra = ratio <= 1.10 ? 1 : 2;
    adjustedReps = baseReps + extra;
    note = 'Slight rep increase (nearest available weight)';
  } else if (ratio < 1.0) {
    // Heavier than target — reduce reps
    adjustedReps = max(1, (baseReps * ratio).round());
    note = 'Reduced reps (heavier available weight)';
  }

  return RepAdjustment(
    adjustedReps: adjustedReps,
    adjustedRestSeconds: adjustedRest,
    adjustedRpe: adjustedRpe,
    adjustedRir: adjustedRir,
    note: note,
    useTempo: useTempo,
  );
}

/// Apply snap adjustments to the full set target list.
///
/// - Working sets: update weight, reps, RPE/RIR
/// - Warmup sets: 50% of snapped weight
List<SetTarget> adjustSetTargetsForSnap(
  List<SetTarget> setTargets,
  WeightSnapResult snapResult,
  String goal,
) {
  if (!snapResult.wasSnapped || snapResult.snappedWeight == null) {
    return setTargets;
  }

  final snappedWeight = snapResult.snappedWeight!;
  final ratio = snapResult.ratio;

  return setTargets.map((st) {
    if (st.isWarmup) {
      // Warmup: 50% of snapped working weight
      return SetTarget(
        setNumber: st.setNumber,
        setType: st.setType,
        targetReps: st.targetReps,
        targetWeightKg: _roundWeight(snappedWeight * 0.5,
            'dumbbell'), // Use smallest increment for warmup
        targetRpe: st.targetRpe,
        targetRir: st.targetRir,
      );
    }

    // Working set adjustments
    final repAdj = calculateRepAdjustment(
      st.targetReps,
      0, // rest is handled at exercise level
      ratio,
      goal,
    );

    // RPE/RIR shift based on ratio
    int? newRpe = st.targetRpe;
    int? newRir = st.targetRir;

    if (ratio > 1.30) {
      // Significantly lighter → more reps in reserve
      if (newRir != null) newRir = min(5, newRir + 1);
      if (newRpe != null) newRpe = max(5, newRpe - 1);
    } else if (ratio < 1.0) {
      // Heavier → fewer reps in reserve
      if (newRir != null) newRir = max(0, newRir - 1);
      if (newRpe != null) newRpe = min(10, newRpe + 1);
    }

    return SetTarget(
      setNumber: st.setNumber,
      setType: st.setType,
      targetReps: repAdj.adjustedReps,
      targetWeightKg: snappedWeight,
      targetRpe: newRpe,
      targetRir: newRir,
    );
  }).toList();
}
