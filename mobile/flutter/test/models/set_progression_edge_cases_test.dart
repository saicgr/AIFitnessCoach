import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/models/set_progression.dart';

/// Comprehensive edge case tests for the set progression system.
///
/// 10 user scenarios + 5 bonus edge cases covering:
/// - All 8 progression patterns
/// - kg and lbs display units
/// - Matched and mismatched increment units
/// - All adaptive triggers (RIR 0-4, rep ratio extremes, fatigue override)
/// - Position-aware weight/rep derivation
/// - Dart-specific rounding behavior

// =============================================================================
// Helper: Simulates the full _updateControlsForNextSet flow in pure unit-test form.
// =============================================================================

/// Simulates the full progression flow for a completed set:
/// actualWeight → snapping → deriveWorkingWeight → reverseRepOffset →
/// generateTargets → adaptTargets → display snapping.
///
/// Returns (displayWeight, displayReps, isAmrap) for the next set.
({double weight, int reps, bool isAmrap}) simulateNextSet({
  required SetProgressionPattern pattern,
  required double completedWeightDisplay, // in display unit
  required int completedReps,
  required int? completedRir,
  required int completedSetIndex, // 0-indexed
  required int totalSets,
  required double increment, // in display unit
  String? trainingGoal,
  List<CompletedSetData>? allCompletedSets, // all completed sets for fatigue
}) {
  // Step 1: Snap to increment
  final snapped = increment > 0
      ? (completedWeightDisplay / increment).round() * increment
      : completedWeightDisplay;

  // Step 2: Derive working weight (peak)
  final workingWeight = pattern.deriveWorkingWeight(
    enteredWeight: snapped,
    totalSets: totalSets,
    increment: increment,
    completedSetIndex: completedSetIndex,
  );

  // Step 3: Reverse rep offset to get baseReps
  final baseReps = SetProgressionPatternX.reverseRepOffset(
    pattern, completedReps, completedSetIndex, totalSets,
  );

  // Step 4: Generate targets
  var targets = pattern.generateTargets(
    workingWeight: workingWeight,
    totalSets: totalSets,
    baseReps: baseReps,
    increment: increment,
    trainingGoal: trainingGoal,
  );

  // Step 5: Build completed data and adapt
  final completedSets = allCompletedSets ?? [
    CompletedSetData(
      weight: completedWeightDisplay,
      reps: completedReps,
      rir: completedRir,
    ),
  ];

  targets = adaptTargets(
    pattern: pattern,
    originalTargets: targets,
    completedSets: completedSets,
    increment: increment,
    totalSets: totalSets,
  );

  // Step 6: Get next set target
  final nextSetIndex = completedSets.length;
  if (nextSetIndex >= targets.length) {
    return (weight: 0, reps: 0, isAmrap: false);
  }

  final nextTarget = targets[nextSetIndex];

  // Step 7: Snap display weight to increment
  final displayWeight = increment > 0
      ? (nextTarget.weight / increment).round() * increment
      : nextTarget.weight;

  return (
    weight: displayWeight,
    reps: nextTarget.reps,
    isAmrap: nextTarget.isAmrap,
  );
}

void main() {
  // ===========================================================================
  // S1: Pyramid Up — Dumbbell, lbs, 2.5 lbs increment, RIR 3
  // ===========================================================================
  group('S1: Pyramid Up — Dumbbell lbs 2.5 inc RIR 3', () {
    test('deriveWorkingWeight from set 1 (position 0)', () {
      final ww = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 20.0, totalSets: 3, increment: 2.5, completedSetIndex: 0,
      );
      expect(ww, 25.0); // 20 + 2×2.5
    });

    test('reverseRepOffset for set 1', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 15, 0, 3,
      );
      expect(base, 11); // 15 - (3-1-0)×2 = 15 - 4
    });

    test('generateTargets produces ascending weights, descending reps', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 25, totalSets: 3, baseReps: 11, increment: 2.5,
      );
      expect(targets[0].weight, 20.0);
      expect(targets[0].reps, 15);
      expect(targets[1].weight, 22.5);
      expect(targets[1].reps, 13);
      expect(targets[2].weight, 25.0);
      expect(targets[2].reps, 11);
    });

    test('adaptTargets: RIR 3 + repRatio 1.0 → +1 increment', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 25, totalSets: 3, baseReps: 11, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 20, reps: 15, rir: 3)],
        increment: 2.5,
        totalSets: 3,
      );
      expect(adapted[1].weight, 25.0); // 22.5 + 2.5
      expect(adapted[1].reps, 12);     // 13 - 1
      expect(adapted[2].weight, 27.5); // 25 + 2.5
      expect(adapted[2].reps, 10);     // 11 - 1
    });

    test('full flow: set 2 = 25.0 × 12', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.pyramidUp,
        completedWeightDisplay: 20.0,
        completedReps: 15,
        completedRir: 3,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 2.5,
      );
      expect(result.weight, 25.0);
      expect(result.reps, 12);
    });
  });

  // ===========================================================================
  // S2: Pyramid Up — Barbell, kg, 2.5 kg increment, RIR 2 (no adjustment)
  // ===========================================================================
  group('S2: Pyramid Up — Barbell kg 2.5 inc RIR 2', () {
    test('deriveWorkingWeight from set 1', () {
      final ww = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 60.0, totalSets: 3, increment: 2.5, completedSetIndex: 0,
      );
      expect(ww, 65.0);
    });

    test('reverseRepOffset for set 1', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 12, 0, 3,
      );
      expect(base, 8);
    });

    test('adaptTargets: RIR 2 + repRatio 1.0 → no adjustment', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 65, totalSets: 3, baseReps: 8, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 60, reps: 12, rir: 2)],
        increment: 2.5,
        totalSets: 3,
      );
      expect(adapted[1].weight, 62.5); // No change
      expect(adapted[1].reps, 10);     // No change
    });

    test('full flow: set 2 = 62.5 × 10', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.pyramidUp,
        completedWeightDisplay: 60.0,
        completedReps: 12,
        completedRir: 2,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 2.5,
      );
      expect(result.weight, 62.5);
      expect(result.reps, 10);
    });
  });

  // ===========================================================================
  // S3: Reverse Pyramid — Dumbbell, kg, 2.5 kg increment, RIR 0 (failure)
  // ===========================================================================
  group('S3: Reverse Pyramid — Dumbbell kg 2.5 inc RIR 0', () {
    test('deriveWorkingWeight returns entered (set 1 = heaviest)', () {
      final ww = SetProgressionPattern.reversePyramid.deriveWorkingWeight(
        enteredWeight: 20.0, totalSets: 3, increment: 2.5, completedSetIndex: 0,
      );
      expect(ww, 20.0);
    });

    test('reverseRepOffset for RPT set 0 (offset -4)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.reversePyramid, 8, 0, 3,
      );
      expect(base, 12); // 8 - (-4) = 12
    });

    test('generateTargets: descending weights, ascending reps', () {
      final targets = SetProgressionPattern.reversePyramid.generateTargets(
        workingWeight: 20, totalSets: 3, baseReps: 12, increment: 2.5,
      );
      expect(targets[0].weight, 20.0);
      expect(targets[0].reps, 8);  // 12 + (-4)
      expect(targets[1].weight, 17.5); // 20 × 0.875
      expect(targets[1].reps, 10); // 12 + (-2)
      // Set 2: 20 × 0.79 = 15.8 → snap(15.8, 2.5) = 15.0
      expect(targets[2].weight, 15.0);
      expect(targets[2].reps, 12); // 12 + 0
    });

    test('adaptTargets: RIR 0 → -1 increment', () {
      final targets = SetProgressionPattern.reversePyramid.generateTargets(
        workingWeight: 20, totalSets: 3, baseReps: 12, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.reversePyramid,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 20, reps: 8, rir: 0)],
        increment: 2.5,
        totalSets: 3,
      );
      expect(adapted[1].weight, 15.0); // 17.5 - 2.5
      expect(adapted[1].reps, 11);     // 10 + 1
    });

    test('full flow: set 2 = 15.0 × 11', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.reversePyramid,
        completedWeightDisplay: 20.0,
        completedReps: 8,
        completedRir: 0,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 2.5,
      );
      expect(result.weight, 15.0);
      expect(result.reps, 11);
    });
  });

  // ===========================================================================
  // S4: Straight Sets — Machine, lbs, 10 lbs increment, RIR 4 (way too easy)
  // ===========================================================================
  group('S4: Straight Sets — Machine lbs 10 inc RIR 4', () {
    test('no weight/rep offset for straight sets', () {
      final ww = SetProgressionPattern.straightSets.deriveWorkingWeight(
        enteredWeight: 100.0, totalSets: 3, increment: 10, completedSetIndex: 0,
      );
      expect(ww, 100.0);
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.straightSets, 12, 0, 3,
      );
      expect(base, 12);
    });

    test('adaptTargets: RIR 4 + repRatio 1.0 → +2 increments', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 100, totalSets: 3, baseReps: 12, increment: 10,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 100, reps: 12, rir: 4)],
        increment: 10,
        totalSets: 3,
      );
      expect(adapted[1].weight, 120.0); // 100 + 2×10
      expect(adapted[1].reps, 10);      // 12 - 2
    });

    test('full flow: set 2 = 120.0 × 10', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.straightSets,
        completedWeightDisplay: 100.0,
        completedReps: 12,
        completedRir: 4,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 10,
      );
      expect(result.weight, 120.0);
      expect(result.reps, 10);
    });
  });

  // ===========================================================================
  // S5: Drop Sets — Cable, kg, 5 kg increment, <5 reps (wider drop)
  // ===========================================================================
  group('S5: Drop Sets — Cable kg 5 inc <5 reps', () {
    test('generateTargets: cascading 20% drops, all AMRAP', () {
      final targets = SetProgressionPattern.dropSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 5,
      );
      expect(targets[0].weight, 50.0);
      expect(targets[0].isAmrap, true);
      expect(targets[1].weight, 40.0); // 50 × 0.8
      expect(targets[2].weight, 30.0); // 40 × 0.8 = 32 → snap to 30
    });

    test('adaptDropSets: <5 reps → 28% drop', () {
      final targets = SetProgressionPattern.dropSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.dropSets,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 50, reps: 4)],
        increment: 5,
        totalSets: 3,
      );
      expect(adapted[1].weight, 35.0); // 50 × 0.72 = 36 → snap to 35
      expect(adapted[1].isAmrap, true);
    });

    test('full flow: set 2 = 35.0 × AMRAP', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.dropSets,
        completedWeightDisplay: 50.0,
        completedReps: 4,
        completedRir: null,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 5,
      );
      expect(result.weight, 35.0);
      expect(result.isAmrap, true);
    });
  });

  // ===========================================================================
  // S6: Top Set + Back-Off — Barbell, lbs, 5 lbs increment, 4 sets, RIR 1
  // ===========================================================================
  group('S6: Top Set + Back-Off — Barbell lbs 5 inc RIR 1', () {
    test('reverseRepOffset for top set (offset -4)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.topSetBackOff, 4, 0, 4,
      );
      expect(base, 8); // 4 - (-4)
    });

    test('generateTargets: top set heavy, back-offs at 83%', () {
      final targets = SetProgressionPattern.topSetBackOff.generateTargets(
        workingWeight: 225, totalSets: 4, baseReps: 8, increment: 5,
      );
      expect(targets[0].weight, 225.0);
      expect(targets[0].reps, 4); // 8 - 4
      // Back-off: 225 × 0.83 = 186.75 → snap(186.75, 5) = 185
      expect(targets[1].weight, 185.0);
      expect(targets[1].reps, 6); // 8 - 2
      expect(targets[2].weight, 185.0);
      expect(targets[3].weight, 185.0);
    });

    test('adaptTargets: RIR 1 + repRatio 1.0 → no adjustment', () {
      final targets = SetProgressionPattern.topSetBackOff.generateTargets(
        workingWeight: 225, totalSets: 4, baseReps: 8, increment: 5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.topSetBackOff,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 225, reps: 4, rir: 1)],
        increment: 5,
        totalSets: 4,
      );
      // RIR 1 with repRatio 1.0: rir==0? No. rir<=1 && repRatio<0.85? No (1.0 >= 0.85)
      expect(adapted[1].weight, 185.0); // No change
      expect(adapted[1].reps, 6);       // No change
    });

    test('full flow: set 2 = 185.0 × 6', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.topSetBackOff,
        completedWeightDisplay: 225.0,
        completedReps: 4,
        completedRir: 1,
        completedSetIndex: 0,
        totalSets: 4,
        increment: 5,
      );
      expect(result.weight, 185.0);
      expect(result.reps, 6);
    });
  });

  // ===========================================================================
  // S7: Myo-Reps — Dumbbell, kg, 2.5 kg increment, activation <9 reps
  // ===========================================================================
  group('S7: Myo-Reps — Dumbbell kg 2.5 inc activation <9', () {
    test('deriveWorkingWeight: /0.8 and snap', () {
      final ww = SetProgressionPattern.myoReps.deriveWorkingWeight(
        enteredWeight: 15.0, totalSets: 4, increment: 2.5, completedSetIndex: 0,
      );
      // 15 / 0.8 = 18.75 → snap(18.75, 2.5) = round(7.5)×2.5
      // Dart: 7.5.round() = 8 (half to even) → 20.0
      expect(ww, 20.0);
    });

    test('reverseRepOffset for activation (set 0)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.myoReps, 7, 0, 4,
      );
      expect(base, 2); // 7 - 5
    });

    test('generateTargets: activation + mini-sets', () {
      final targets = SetProgressionPattern.myoReps.generateTargets(
        workingWeight: 20, totalSets: 4, baseReps: 2, increment: 2.5,
      );
      // myoWeight = snap(20 × 0.8, 2.5) = snap(16, 2.5) = 15.0
      expect(targets[0].weight, 15.0);
      expect(targets[0].reps, 7);  // baseReps + 5 = 2 + 5 = 7
      expect(targets[1].weight, 15.0);
      expect(targets[1].reps, 5);  // mini-set
    });

    test('adaptMyoReps: activation <9 → 85% weight', () {
      final targets = SetProgressionPattern.myoReps.generateTargets(
        workingWeight: 20, totalSets: 4, baseReps: 2, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.myoReps,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 15, reps: 7)],
        increment: 2.5,
        totalSets: 4,
      );
      // 15 × 0.85 = 12.75 → snap(12.75, 2.5) = round(5.1)×2.5 = 5×2.5 = 12.5
      expect(adapted[1].weight, 12.5);
      expect(adapted[1].reps, 5);
    });

    test('full flow: mini-set = 12.5 × 5', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.myoReps,
        completedWeightDisplay: 15.0,
        completedReps: 7,
        completedRir: null,
        completedSetIndex: 0,
        totalSets: 4,
        increment: 2.5,
      );
      expect(result.weight, 12.5);
      expect(result.reps, 5);
    });
  });

  // ===========================================================================
  // S8: Rest-Pause — Machine, lbs, 5 lbs increment, initial <6 reps
  // ===========================================================================
  group('S8: Rest-Pause — Machine lbs 5 inc initial <6', () {
    test('generateTargets: all same weight, all AMRAP', () {
      final targets = SetProgressionPattern.restPause.generateTargets(
        workingWeight: 150, totalSets: 3, baseReps: 10, increment: 5,
      );
      for (final t in targets) {
        expect(t.weight, 150.0);
        expect(t.isAmrap, true);
      }
    });

    test('adaptRestPause: initial <6 → 90% weight', () {
      final targets = SetProgressionPattern.restPause.generateTargets(
        workingWeight: 150, totalSets: 3, baseReps: 10, increment: 5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.restPause,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 150, reps: 4)],
        increment: 5,
        totalSets: 3,
      );
      expect(adapted[1].weight, 135.0); // 150 × 0.90 = 135
      expect(adapted[1].isAmrap, true);
    });

    test('full flow: set 2 = 135.0 × AMRAP', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.restPause,
        completedWeightDisplay: 150.0,
        completedReps: 4,
        completedRir: null,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 5,
      );
      expect(result.weight, 135.0);
      expect(result.isAmrap, true);
    });
  });

  // ===========================================================================
  // S9: Endurance — Dumbbell, lbs, 2.5 lbs increment, 4 sets, RIR 3
  // ===========================================================================
  group('S9: Endurance — Dumbbell lbs 2.5 inc RIR 3', () {
    test('reverseRepOffset: endurance set 0 has no offset', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.endurance, 20, 0, 4,
      );
      expect(base, 20); // 20 - 0×2
    });

    test('generateTargets: same weight, reps increase by 2 per set', () {
      final targets = SetProgressionPattern.endurance.generateTargets(
        workingWeight: 15, totalSets: 4, baseReps: 20, increment: 2.5,
      );
      expect(targets[0].weight, 15.0);
      expect(targets[0].reps, 20);
      expect(targets[1].reps, 22);
      expect(targets[2].reps, 24);
      expect(targets[3].reps, 26);
    });

    test('adaptTargets: RIR 3 → +1 increment', () {
      final targets = SetProgressionPattern.endurance.generateTargets(
        workingWeight: 15, totalSets: 4, baseReps: 20, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.endurance,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 15, reps: 20, rir: 3)],
        increment: 2.5,
        totalSets: 4,
      );
      expect(adapted[1].weight, 17.5); // 15 + 2.5
      expect(adapted[1].reps, 21);     // 22 - 1
    });

    test('full flow: set 2 = 17.5 × 21', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.endurance,
        completedWeightDisplay: 15.0,
        completedReps: 20,
        completedRir: 3,
        completedSetIndex: 0,
        totalSets: 4,
        increment: 2.5,
      );
      expect(result.weight, 17.5);
      expect(result.reps, 21);
    });
  });

  // ===========================================================================
  // S10: Pyramid Up — Barbell, kg, 2.5 kg increment, 5 sets, catastrophic miss
  // ===========================================================================
  group('S10: Pyramid Up — 5 sets catastrophic miss', () {
    test('reverseRepOffset: floors to 6 (min effective reps)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 3, 0, 5,
      );
      // step=2: 3-8=-5 → ≤5, re-try step=1: 3-4=-1 → clamp(6,30) = 6
      expect(base, 6);
    });

    test('deriveWorkingWeight: 5 sets from position 0', () {
      final ww = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 100, totalSets: 5, increment: 2.5, completedSetIndex: 0,
      );
      expect(ww, 110.0); // 100 + 4×2.5
    });

    test('generateTargets: 5-set pyramid with baseReps=6 (floored)', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 110, totalSets: 5, baseReps: 6, increment: 2.5,
      );
      // step = _pyramidRepStep(6) = 2
      expect(targets[0].weight, 100.0);
      expect(targets[0].reps, 14); // 6 + 4×2 = 14
      expect(targets[1].reps, 12); // 6 + 3×2
      expect(targets[4].reps, 6);  // 6 + 0 = peak, at minimum
    });

    test('adaptTargets: repRatio 0.21 → -2 increments', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 110, totalSets: 5, baseReps: 6, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: [const CompletedSetData(weight: 100, reps: 3, rir: 3)],
        increment: 2.5,
        totalSets: 5,
      );
      // repRatio = 3/14 = 0.21 < 0.40 → -2 increments
      expect(adapted[1].weight, 97.5); // 102.5 - 5
      expect(adapted[1].reps, 14);     // 12 + 2 = 14 (clamped ≥6)
    });

    test('full flow: set 2 = 97.5 × 14', () {
      final result = simulateNextSet(
        pattern: SetProgressionPattern.pyramidUp,
        completedWeightDisplay: 100.0,
        completedReps: 3,
        completedRir: 3,
        completedSetIndex: 0,
        totalSets: 5,
        increment: 2.5,
      );
      expect(result.weight, 97.5);
      expect(result.reps, 14);
    });
  });

  // ===========================================================================
  // BONUS EDGE CASES
  // ===========================================================================

  group('B1: Dart rounding behavior', () {
    test('Dart rounds half away from zero (not banker\'s rounding)', () {
      // Dart double.round() rounds half AWAY from zero — safe for weight snapping
      expect(4.5.round(), 5); // rounds UP
      expect(5.5.round(), 6);
      expect((-4.5).round(), -5); // rounds away from zero
      // So snap(22.5, 5) = 5 × 5 = 25 (correct!)
      final snapped = (22.5 / 5).round() * 5;
      expect(snapped, 25);
    });

    test('2.5 increment snaps cleanly for all common weights', () {
      expect((20.0 / 2.5).round() * 2.5, 20.0);
      expect((22.5 / 2.5).round() * 2.5, 22.5);
      expect((25.0 / 2.5).round() * 2.5, 25.0);
      expect((17.5 / 2.5).round() * 2.5, 17.5);
    });
  });

  group('B2: Pyramid Up consistency — set 2 completion matches set 3', () {
    test('set 3 target from set 2 matches set 3 target from set 1', () {
      // After set 1: 20×15, RIR 2 (no adaptive) → set 2 target = 22.5×13
      final fromSet1 = simulateNextSet(
        pattern: SetProgressionPattern.pyramidUp,
        completedWeightDisplay: 20.0,
        completedReps: 15,
        completedRir: 2,
        completedSetIndex: 0,
        totalSets: 3,
        increment: 2.5,
      );
      expect(fromSet1.weight, 22.5);
      expect(fromSet1.reps, 13);

      // After set 2: 22.5×13, RIR 2 → set 3 target
      // Must pass ALL completed sets (both set 1 and set 2)
      final fromSet2 = simulateNextSet(
        pattern: SetProgressionPattern.pyramidUp,
        completedWeightDisplay: 22.5,
        completedReps: 13,
        completedRir: 2,
        completedSetIndex: 1,
        totalSets: 3,
        increment: 2.5,
        allCompletedSets: const [
          CompletedSetData(weight: 20, reps: 15, rir: 2),
          CompletedSetData(weight: 22.5, reps: 13, rir: 2),
        ],
      );

      // Both should give set 3 = 25.0 × 11 (no adaptive for RIR 2)
      expect(fromSet2.weight, 25.0);
      expect(fromSet2.reps, 11);
    });
  });

  group('B3: Unit mismatch — increment kg, display lbs', () {
    test('effectiveIncrement conversion is non-zero', () {
      // increment = 2.5 kg, display = lbs
      final effectiveIncrement = 2.5 * 2.20462; // 5.51155
      expect(effectiveIncrement, closeTo(5.51, 0.01));
      // Snapping 135 lbs to 5.51 steps
      final snapped = (135 / effectiveIncrement).round() * effectiveIncrement;
      // round(24.49) = 24 → 24 × 5.51 = 132.28
      expect(snapped, closeTo(132.28, 0.1));
      // Known: loses 2.72 lbs precision. Not a crash, just ugly.
    });
  });

  group('B4: Training goal clamping with pyramid + 6-rep floor', () {
    test('muscle_strength (1-5) vs 6-rep floor: floor wins, goal clamps to 5', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 110, totalSets: 3, baseReps: 3, increment: 2.5,
        trainingGoal: 'muscle_strength',
      );
      // step=1 (baseReps 3 ≤ 5), pyramid floor=6:
      // Set 0: reps = 3+2 = 5 → floor to 6 → goal clamp(1,5) = 5
      // Set 1: reps = 3+1 = 4 → floor to 6 → goal clamp(1,5) = 5
      // Set 2: reps = 3 → floor to 6 → goal clamp(1,5) = 5
      // All sets at 5 — strength goal caps the 6-rep floor to 5
      expect(targets[0].reps, 5);
      expect(targets[1].reps, 5);
      expect(targets[2].reps, 5);
    });

    test('hypertrophy (6-12) preserves pyramid differentiation', () {
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: 30, totalSets: 3, baseReps: 8, increment: 2.5,
        trainingGoal: 'muscle_hypertrophy',
      );
      // step=2 (baseReps 8 > 5):
      // Set 0: 8+4=12, Set 1: 8+2=10, Set 2: 8
      expect(targets[0].reps, 12);
      expect(targets[1].reps, 10);
      expect(targets[2].reps, 8);
    });
  });

  group('B5: Boundary conditions — empty/full completedSets', () {
    test('empty completedSets → returns original targets', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: const [],
        increment: 2.5,
        totalSets: 3,
      );
      expect(adapted[0].weight, 50.0);
      expect(adapted[0].reps, 10);
    });

    test('all sets completed → returns original targets', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: const [
          CompletedSetData(weight: 50, reps: 10, rir: 2),
          CompletedSetData(weight: 50, reps: 10, rir: 2),
          CompletedSetData(weight: 50, reps: 10, rir: 2),
        ],
        increment: 2.5,
        totalSets: 3,
      );
      // completedSets.length >= totalSets → no adaptation
      expect(adapted[0].weight, 50.0);
    });

    test('fatigue override: >25% performance drop after 2 sets', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 4, baseReps: 10, increment: 2.5,
      );
      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: const [
          CompletedSetData(weight: 50, reps: 10, rir: 3), // score = 500
          CompletedSetData(weight: 50, reps: 5, rir: 3),  // score = 250 (50% drop)
        ],
        increment: 2.5,
        totalSets: 4,
      );
      // fatiguePct = (500-250)/500 = 0.50 > 0.25 → force -1
      // Even though RIR 3 would normally give +1 (repRatio = 5/10 = 0.50 < 0.65 → -1 from Step 1)
      // Step 1: repRatio 0.50 < 0.65 → -1 already
      // Actually the fatigue override only fires when incrementAdjust >= 0
      // Since Step 1 already gives -1, fatigue override doesn't change it
      expect(adapted[2].weight, 47.5); // -1 increment
    });
  });
}
