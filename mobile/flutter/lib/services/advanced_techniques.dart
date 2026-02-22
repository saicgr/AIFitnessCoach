import 'dart:math';

import '../data/models/exercise.dart';

/// Advanced training techniques for time-efficient workouts.
enum AdvancedTechnique {
  dropSet,
  myoRep,
  restPause,
  none,
}

/// Result of applying an advanced technique to an exercise.
class TechniqueResult {
  final AdvancedTechnique technique;
  final List<SetTarget> modifiedSets;
  final String description;
  final int additionalTimeSeconds;

  const TechniqueResult({
    required this.technique,
    required this.modifiedSets,
    required this.description,
    this.additionalTimeSeconds = 0,
  });
}

/// Select the best technique for the given goal.
AdvancedTechnique selectTechnique(String goal) {
  switch (goal.toLowerCase()) {
    case 'hypertrophy': return AdvancedTechnique.dropSet;
    case 'strength': return AdvancedTechnique.restPause;
    case 'endurance': return AdvancedTechnique.myoRep;
    case 'power': return AdvancedTechnique.none;
    default: return AdvancedTechnique.dropSet;
  }
}

/// Apply a drop set to the last working set.
///
/// 2-3 drops at 20-25% weight reduction each.
/// Research: Schoenfeld & Grgic 2018 -- drop sets produce similar
/// hypertrophy to traditional sets in less time.
TechniqueResult applyDropSet(List<SetTarget> originalSets, {double? workingWeight}) {
  if (originalSets.isEmpty) {
    return TechniqueResult(
      technique: AdvancedTechnique.none,
      modifiedSets: originalSets,
      description: '',
    );
  }

  final lastWorking = originalSets.lastWhere(
    (s) => !s.isWarmup,
    orElse: () => originalSets.last,
  );

  final baseWeight = workingWeight ?? lastWorking.targetWeightKg;
  final baseReps = lastWorking.targetReps;

  // Generate 2-3 drop sets
  final drops = <SetTarget>[];
  final numDrops = baseWeight != null && baseWeight > 20 ? 3 : 2;
  int setNum = originalSets.length + 1;

  for (int i = 1; i <= numDrops; i++) {
    final dropMultiplier = 1.0 - (0.225 * i); // ~22.5% reduction per drop
    final dropWeight = baseWeight != null ? (baseWeight * dropMultiplier).roundToDouble() : null;
    final dropReps = (baseReps * (1.0 + 0.15 * i)).round(); // More reps at lighter weight

    drops.add(SetTarget(
      setNumber: setNum++,
      setType: 'drop_set',
      targetReps: dropReps,
      targetWeightKg: dropWeight,
      targetRpe: 9,
      targetRir: 1,
    ));
  }

  return TechniqueResult(
    technique: AdvancedTechnique.dropSet,
    modifiedSets: [...originalSets, ...drops],
    description: 'Drop set: $numDrops drops at ~22% weight reduction, no rest between drops',
    additionalTimeSeconds: numDrops * 20, // ~20s per drop
  );
}

/// Apply myo-rep technique.
///
/// Activation set (12-20 reps) + 3-5 mini-sets of 3-5 reps with 10-15s rest.
/// Research: Mystad et al. 2024 -- myo-reps match traditional volume in ~40% less time.
TechniqueResult applyMyoRep(List<SetTarget> originalSets, {double? workingWeight}) {
  if (originalSets.isEmpty) {
    return TechniqueResult(
      technique: AdvancedTechnique.none,
      modifiedSets: originalSets,
      description: '',
    );
  }

  // Keep warmup sets, replace working sets with myo-rep protocol
  final warmups = originalSets.where((s) => s.isWarmup).toList();
  int setNum = warmups.length + 1;

  // Activation set: 15 reps to near failure
  final activationSet = SetTarget(
    setNumber: setNum++,
    setType: 'working',
    targetReps: 15,
    targetWeightKg: workingWeight,
    targetRpe: 9,
    targetRir: 1,
  );

  // Mini-sets: 4 sets of 4 reps with minimal rest
  final miniSets = List.generate(4, (i) => SetTarget(
    setNumber: setNum++,
    setType: 'myo_rep',
    targetReps: 4,
    targetWeightKg: workingWeight,
    targetRpe: min(8 + i, 10),
    targetRir: max(0, 2 - i),
  ));

  return TechniqueResult(
    technique: AdvancedTechnique.myoRep,
    modifiedSets: [...warmups, activationSet, ...miniSets],
    description: 'Myo-reps: 1 activation set (15 reps) + 4 mini-sets (4 reps), 12s rest between mini-sets',
    additionalTimeSeconds: 4 * 15, // 4 mini-sets x ~15s each
  );
}

/// Apply rest-pause technique.
///
/// Near-failure initial set + 2 mini-sets at 15-20s rest.
/// Research: Prestes et al. 2019 -- rest-pause produces superior strength gains.
TechniqueResult applyRestPause(List<SetTarget> originalSets, {double? workingWeight}) {
  if (originalSets.isEmpty) {
    return TechniqueResult(
      technique: AdvancedTechnique.none,
      modifiedSets: originalSets,
      description: '',
    );
  }

  final warmups = originalSets.where((s) => s.isWarmup).toList();
  final lastWorking = originalSets.lastWhere(
    (s) => !s.isWarmup,
    orElse: () => originalSets.last,
  );

  int setNum = warmups.length + 1;

  // Main set to near failure
  final mainSet = SetTarget(
    setNumber: setNum++,
    setType: 'working',
    targetReps: lastWorking.targetReps,
    targetWeightKg: workingWeight ?? lastWorking.targetWeightKg,
    targetRpe: 9,
    targetRir: 1,
  );

  // 2 rest-pause mini-sets: same weight, reduced reps
  final rpSets = List.generate(2, (i) => SetTarget(
    setNumber: setNum++,
    setType: 'rest_pause',
    targetReps: max(1, (lastWorking.targetReps * 0.5).round() - i),
    targetWeightKg: workingWeight ?? lastWorking.targetWeightKg,
    targetRpe: 10,
    targetRir: 0,
  ));

  return TechniqueResult(
    technique: AdvancedTechnique.restPause,
    modifiedSets: [...warmups, mainSet, ...rpSets],
    description: 'Rest-pause: main set to near failure + 2 mini-sets (15-20s rest between)',
    additionalTimeSeconds: 2 * 20, // 2 mini-sets x ~20s each
  );
}

/// Apply the appropriate technique based on goal.
///
/// Returns null if no technique should be applied (e.g., power goal).
TechniqueResult? applyTechniqueForGoal(
  String goal,
  List<SetTarget> originalSets, {
  double? workingWeight,
}) {
  final technique = selectTechnique(goal);
  switch (technique) {
    case AdvancedTechnique.dropSet:
      return applyDropSet(originalSets, workingWeight: workingWeight);
    case AdvancedTechnique.myoRep:
      return applyMyoRep(originalSets, workingWeight: workingWeight);
    case AdvancedTechnique.restPause:
      return applyRestPause(originalSets, workingWeight: workingWeight);
    case AdvancedTechnique.none:
      return null;
  }
}
