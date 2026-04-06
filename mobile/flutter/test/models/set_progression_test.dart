import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/models/set_progression.dart';
import 'package:fitwiz/core/models/rir_reference.dart';

void main() {
  group('deriveWorkingWeight', () {
    test('Pyramid Up: peak = entered + (sets-1) × increment', () {
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 20, totalSets: 3, increment: 2.5,
      );
      expect(peak, 25.0); // 20 + 2×2.5
    });

    test('Pyramid Up: 5 sets', () {
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 20, totalSets: 5, increment: 2.5,
      );
      expect(peak, 30.0); // 20 + 4×2.5
    });

    test('Reverse Pyramid: entered = peak (no change)', () {
      final peak = SetProgressionPattern.reversePyramid.deriveWorkingWeight(
        enteredWeight: 50, totalSets: 3, increment: 2.5,
      );
      expect(peak, 50.0);
    });

    test('Myo-Reps: working = entered / 0.8', () {
      final peak = SetProgressionPattern.myoReps.deriveWorkingWeight(
        enteredWeight: 40, totalSets: 4, increment: 2.5,
      );
      expect(peak, 50.0); // 40 / 0.8
    });

    test('Straight Sets: no change', () {
      final peak = SetProgressionPattern.straightSets.deriveWorkingWeight(
        enteredWeight: 50, totalSets: 3, increment: 2.5,
      );
      expect(peak, 50.0);
    });

    test('Drop Sets: no change', () {
      final peak = SetProgressionPattern.dropSets.deriveWorkingWeight(
        enteredWeight: 50, totalSets: 3, increment: 5,
      );
      expect(peak, 50.0);
    });

    test('Top Set + Back-Off: no change', () {
      final peak = SetProgressionPattern.topSetBackOff.deriveWorkingWeight(
        enteredWeight: 50, totalSets: 3, increment: 2.5,
      );
      expect(peak, 50.0);
    });

    test('Rest-Pause: no change', () {
      final peak = SetProgressionPattern.restPause.deriveWorkingWeight(
        enteredWeight: 50, totalSets: 3, increment: 2.5,
      );
      expect(peak, 50.0);
    });

    test('Pyramid Up: deriving from set 2 (completedSetIndex=1)', () {
      // Set 2 weight = peak - 1*inc. If set 2 = 22.5, peak = 22.5 + 1*2.5 = 25
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 22.5, totalSets: 3, increment: 2.5, completedSetIndex: 1,
      );
      expect(peak, 25.0);
    });

    test('Pyramid Up: deriving from set 3 (completedSetIndex=2, peak set)', () {
      // Set 3 IS the peak. stepsFromTop = 0, so peak = entered weight
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 25, totalSets: 3, increment: 2.5, completedSetIndex: 2,
      );
      expect(peak, 25.0);
    });
  });

  group('reverseRepOffset', () {
    test('Pyramid Up: set 0 (3 sets) → subtract 4', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 15, 0, 3,
      );
      expect(base, 11); // 15 - (3-1-0)*2 = 15 - 4
    });

    test('Pyramid Up: set 1 (3 sets) → subtract 2', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 13, 1, 3,
      );
      expect(base, 11); // 13 - (3-1-1)*2 = 13 - 2
    });

    test('Pyramid Up: set 2 (3 sets, peak) → no offset', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.pyramidUp, 11, 2, 3,
      );
      expect(base, 11); // 11 - 0
    });

    test('Reverse Pyramid: set 0 → subtract -4 (add 4)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.reversePyramid, 8, 0, 3,
      );
      expect(base, 12); // 8 - (-4) = 12
    });

    test('Top Set + Back-Off: set 0 → subtract -4 (add 4)', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.topSetBackOff, 6, 0, 3,
      );
      expect(base, 10); // 6 - (-4) = 10
    });

    test('Endurance: set 2 → subtract 4', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.endurance, 19, 2, 3,
      );
      expect(base, 15); // 19 - 2*2 = 15
    });

    test('Straight Sets: no offset at any position', () {
      final base = SetProgressionPatternX.reverseRepOffset(
        SetProgressionPattern.straightSets, 15, 1, 3,
      );
      expect(base, 15);
    });
  });

  group('generateTargets - set 1 matches entered weight', () {
    test('Pyramid Up: set 1 = entered weight, ascending', () {
      // User enters 20 kg, 3 sets, reps 8, inc 2.5
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 20, totalSets: 3, increment: 2.5,
      );
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: peak, totalSets: 3, baseReps: 8, increment: 2.5,
      );
      expect(targets.length, 3);
      expect(targets[0].weight, 20.0);  // Set 1 = entered
      expect(targets[1].weight, 22.5);  // Set 2 = higher
      expect(targets[2].weight, 25.0);  // Set 3 = peak
      // Reps decrease
      expect(targets[0].reps, greaterThan(targets[1].reps));
      expect(targets[1].reps, greaterThan(targets[2].reps));
    });

    test('Reverse Pyramid: set 1 = entered (heaviest), descending', () {
      final targets = SetProgressionPattern.reversePyramid.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      expect(targets[0].weight, 50.0);  // Set 1 = peak
      expect(targets[1].weight, lessThan(50.0));  // Set 2 = lighter
      expect(targets[2].weight, lessThan(targets[1].weight));  // Set 3 = lightest
      // Reps increase
      expect(targets[0].reps, lessThan(targets[2].reps));
    });

    test('Straight Sets: lower RIR sets get +1 increment (hypertrophy, dumbbell)', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
        exerciseType: 'compound', trainingGoal: 'hypertrophy',
        fitnessLevel: 'intermediate', equipment: 'dumbbell',
      );
      expect(targets.length, 3);
      // Hypertrophy + compound + dumbbell + intermediate: RirRange(3,1), eq=0, lvl=0 → 3→2→1
      expect(targets[0].rir, 3);
      expect(targets[0].weight, 50.0); // Start RIR = base weight
      expect(targets[1].rir, 2);
      expect(targets[1].weight, 52.5); // Lower than start → +1 increment
      expect(targets[2].rir, 1);
      expect(targets[2].weight, 52.5);
    });

    test('Straight Sets: single set stays at base weight', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 1, baseReps: 10, increment: 2.5,
      );
      expect(targets.length, 1);
      expect(targets[0].weight, 50.0);
    });

    test('Straight Sets: 4 sets (hypertrophy, dumbbell)', () {
      final targets = SetProgressionPattern.straightSets.generateTargets(
        workingWeight: 50, totalSets: 4, baseReps: 10, increment: 2.5,
        exerciseType: 'compound', trainingGoal: 'hypertrophy',
        fitnessLevel: 'intermediate', equipment: 'dumbbell',
      );
      // RirRange(3,1) → 3, 2, 2, 1 across 4 sets
      expect(targets[0].weight, 50.0);  // RIR 3: base
      expect(targets[1].weight, 52.5);  // RIR 2: lower than start → +inc
      expect(targets[2].weight, 52.5);  // RIR 2
      expect(targets[3].weight, 52.5);  // RIR 1
    });

    test('Drop Sets: descending weight, all AMRAP', () {
      final targets = SetProgressionPattern.dropSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      expect(targets[0].weight, 50.0);
      expect(targets[1].weight, lessThan(50.0));
      for (final t in targets) {
        expect(t.isAmrap, true);
      }
    });

    test('Top Set + Back-Off: set 1 heaviest, back-offs lighter', () {
      final targets = SetProgressionPattern.topSetBackOff.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      expect(targets[0].weight, 50.0);
      expect(targets[1].weight, lessThan(50.0));
      expect(targets[1].weight, targets[2].weight);  // Back-offs equal
    });

    test('Myo-Reps: activation ≈ entered weight', () {
      final peak = SetProgressionPattern.myoReps.deriveWorkingWeight(
        enteredWeight: 40, totalSets: 4, increment: 2.5,
      );
      final targets = SetProgressionPattern.myoReps.generateTargets(
        workingWeight: peak, totalSets: 4, baseReps: 10, increment: 2.5,
      );
      expect(targets[0].weight, 40.0);  // Activation = entered
      expect(targets[0].reps, greaterThan(10));  // Higher reps for activation
      expect(targets[1].reps, 5);  // Mini-set reps
    });

    test('Rest-Pause: all same weight, all AMRAP', () {
      final targets = SetProgressionPattern.restPause.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      for (final t in targets) {
        expect(t.weight, 50.0);
        expect(t.isAmrap, true);
      }
    });

    test('Endurance: lower RIR sets get +1 increment (dumbbell)', () {
      final targets = SetProgressionPattern.endurance.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 15, increment: 2.5,
        exerciseType: 'compound', equipment: 'dumbbell',
      );
      expect(targets.length, 3);
      // Endurance + compound + dumbbell + intermediate: RirRange(3,2), eq=0 → 3→3→2
      // (lerp midpoint 2.5 rounds to 3)
      expect(targets[0].rir, 3);
      expect(targets[0].weight, 50.0);
      expect(targets[1].rir, 3);
      expect(targets[1].weight, 50.0); // Same RIR as start → base weight
      expect(targets[2].rir, 2);
      expect(targets[2].weight, 52.5); // Lower than start → +inc
      // Reps increase
      expect(targets[0].reps, lessThan(targets[2].reps));
    });

    test('Endurance: single set stays at base weight', () {
      final targets = SetProgressionPattern.endurance.generateTargets(
        workingWeight: 50, totalSets: 1, baseReps: 15, increment: 2.5,
      );
      expect(targets.length, 1);
      expect(targets[0].weight, 50.0);
    });

    test('Pyramid Up: RIR decreases (hypertrophy, dumbbell, intermediate)', () {
      final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
        enteredWeight: 20, totalSets: 3, increment: 2.5,
      );
      final targets = SetProgressionPattern.pyramidUp.generateTargets(
        workingWeight: peak, totalSets: 3, baseReps: 8, increment: 2.5,
        exerciseType: 'compound', trainingGoal: 'hypertrophy',
        fitnessLevel: 'intermediate', equipment: 'dumbbell',
      );
      // Hypertrophy + compound + dumbbell: RirRange(3,1), eq=0 → 3→2→1
      expect(targets[0].rir, 3);
      expect(targets[1].rir, 2);
      expect(targets[2].rir, 1);
    });

    test('Reverse Pyramid: RIR reversed (heaviest first gets floor RIR)', () {
      final targets = SetProgressionPattern.reversePyramid.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
        exerciseType: 'compound', trainingGoal: 'hypertrophy',
        fitnessLevel: 'intermediate', equipment: 'dumbbell',
      );
      // Reversed: i=0 gets computeSetRir(2,...) = floor, i=2 gets computeSetRir(0,...) = start
      expect(targets[0].rir, 1); // Heaviest = floor RIR
      expect(targets[1].rir, 2);
      expect(targets[2].rir, 3); // Lightest = start RIR
    });

    test('Top Set + Back-Off: top set gets floor RIR, back-offs get start RIR', () {
      final targets = SetProgressionPattern.topSetBackOff.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
        exerciseType: 'compound', trainingGoal: 'hypertrophy',
        fitnessLevel: 'intermediate', equipment: 'dumbbell',
      );
      // Top set = floor RIR, back-offs = start RIR
      expect(targets[0].rir, 1); // Top set = floor
      expect(targets[1].rir, 3); // Back-off = start
      expect(targets[2].rir, 3); // Back-off = start
    });

    test('Drop Sets: RIR 1 then 0 (inherent failure, ignores context)', () {
      final targets = SetProgressionPattern.dropSets.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      expect(targets[0].rir, 1);
      expect(targets[1].rir, 0);
      expect(targets[2].rir, 0);
    });

    test('Myo-Reps: activation uses dynamic RIR, mini-sets RIR 0', () {
      final peak = SetProgressionPattern.myoReps.deriveWorkingWeight(
        enteredWeight: 40, totalSets: 4, increment: 2.5,
      );
      final targets = SetProgressionPattern.myoReps.generateTargets(
        workingWeight: peak, totalSets: 4, baseReps: 10, increment: 2.5,
        exerciseType: 'isolation', trainingGoal: 'hypertrophy',
        equipment: 'cable',
      );
      // Activation RIR from computeSetRir: isolation+hypertrophy+cable → RirRange(2,0), eq=-1 → start=2
      expect(targets[0].rir, 2); // Activation = start RIR
      expect(targets[1].rir, 0); // Mini-set = failure
      expect(targets[2].rir, 0);
      expect(targets[3].rir, 0);
    });

    test('Rest-Pause: all RIR 0 (inherent failure)', () {
      final targets = SetProgressionPattern.restPause.generateTargets(
        workingWeight: 50, totalSets: 3, baseReps: 10, increment: 2.5,
      );
      for (final t in targets) {
        expect(t.rir, 0);
      }
    });

    // ── Dynamic RIR tests ──

    test('computeSetRir: barbell compound hypertrophy intermediate → 3,3,2', () {
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'intermediate', equipment: 'barbell');
      final r1 = computeSetRir(setIndex: 1, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'intermediate', equipment: 'barbell');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'intermediate', equipment: 'barbell');
      // RirRange(3,1) + barbell(+1 floor) → start=3, floor=2 → 3, 2.5→3, 2
      expect(r0, 3); expect(r1, 3); expect(r2, 2);
    });

    test('computeSetRir: machine compound hypertrophy intermediate → 3,2,0', () {
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'intermediate', equipment: 'machine');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'intermediate', equipment: 'machine');
      expect(r0, 3); expect(r2, 0); // Machine floor = 1-1 = 0
    });

    test('computeSetRir: cable isolation hypertrophy advanced → 2,1,0', () {
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'isolation',
          trainingGoal: 'hypertrophy', fitnessLevel: 'advanced', equipment: 'cable');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'isolation',
          trainingGoal: 'hypertrophy', fitnessLevel: 'advanced', equipment: 'cable');
      expect(r0, 2); expect(r2, 0); // isolation(2,0) + cable(-1) + advanced(-1) → floor clamped to 0
    });

    test('computeSetRir: barbell compound strength beginner → 4,4,4', () {
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'strength', fitnessLevel: 'beginner', equipment: 'barbell');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'strength', fitnessLevel: 'beginner', equipment: 'barbell');
      // strength compound(3,2) + barbell(+1) + beginner(+1,+1) → start=4, floor=4
      expect(r0, 4); expect(r2, 4);
    });

    test('computeSetRir: kettlebell compound power intermediate → 4,4,4', () {
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'power', fitnessLevel: 'intermediate', equipment: 'kettlebell');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'power', fitnessLevel: 'intermediate', equipment: 'kettlebell');
      // power compound(4,3) + kettlebell(+1) → start=4, floor=4
      expect(r0, 4); expect(r2, 4);
    });

    test('computeSetRir: barbell compound hypertrophy early_intermediate → 4,3,2', () {
      // early_intermediate: startDelta=1, floorDelta=0
      // base hypertrophy compound: (3,1) + barbell +1 floor → (3,2)
      // + early_intermediate: start=4, floor=2
      final r0 = computeSetRir(setIndex: 0, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'early_intermediate', equipment: 'barbell');
      final r1 = computeSetRir(setIndex: 1, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'early_intermediate', equipment: 'barbell');
      final r2 = computeSetRir(setIndex: 2, totalSets: 3, exerciseType: 'compound',
          trainingGoal: 'hypertrophy', fitnessLevel: 'early_intermediate', equipment: 'barbell');
      expect(r0, 4); expect(r1, 3); expect(r2, 2);
    });
  });

  group('adaptTargets', () {
    test('Pyramid: exceed target (RIR 3, 125% reps) → +1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 20, reps: 12, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 22.5, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 3, weight: 25, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 20, reps: 15, rir: 3)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 3,
      );

      expect(adapted[1].weight, 25.0);  // 22.5 + 2.5
      expect(adapted[1].reps, 9);  // 10 - 1
      expect(adapted[2].weight, 27.5);  // 25 + 2.5
    });

    test('Pyramid: underperform (RIR 0, 50% reps) → -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 20, reps: 12, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 22.5, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 3, weight: 25, reps: 8, isAmrap: false),
      ];
      // 6/12 = 0.50 ratio → Step 1: < 0.65 → -1 increment
      final completed = [const CompletedSetData(weight: 20, reps: 6, rir: 0)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 3,
      );

      expect(adapted[1].weight, 20.0);  // 22.5 - 2.5
      expect(adapted[1].reps, 11);  // 10 + 1
    });

    test('Pyramid: on target (RIR 2) → no change', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 20, reps: 12, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 22.5, reps: 10, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 20, reps: 13, rir: 2)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 22.5);  // No change
      expect(adapted[1].reps, 10);
    });

    test('Drop Sets: <5 reps → 28% drop', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 0, isAmrap: true),
        const ProgressionSetTarget(setNumber: 2, weight: 40, reps: 0, isAmrap: true),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 4)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.dropSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      // 50 × 0.72 = 36 → snapped to 35.0 (round(36/2.5)=14, 14×2.5=35)
      expect(adapted[1].weight, 35.0);
    });

    test('Drop Sets: >12 reps → 15% drop', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 0, isAmrap: true),
        const ProgressionSetTarget(setNumber: 2, weight: 40, reps: 0, isAmrap: true),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 15)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.dropSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      // 50 × 0.85 = 42.5
      expect(adapted[1].weight, 42.5);
    });

    test('Myo-Reps: activation <9 → reduce weight 15%', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 40, reps: 15, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 40, reps: 5, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 40, reps: 7)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.myoReps,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      // 40 × 0.85 = 34 → snapped to 35
      expect(adapted[1].weight, closeTo(35, 1.0));
    });

    test('Rest-Pause: initial <6 → reduce weight 10%', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 0, isAmrap: true),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 0, isAmrap: true),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 4)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.restPause,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      // 50 × 0.90 = 45
      expect(adapted[1].weight, 45.0);
    });

    test('Fatigue override: >25% performance drop → force -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 3, weight: 50, reps: 10, isAmrap: false),
      ];
      // Set 1: 50×10=500, Set 2: 50×6=300 → 40% drop
      final completed = [
        const CompletedSetData(weight: 50, reps: 10, rir: 3),
        const CompletedSetData(weight: 50, reps: 6, rir: 2),
      ];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 3,
      );

      expect(adapted[2].weight, 47.5);  // 50 - 2.5
      expect(adapted[2].reps, 11);  // 10 + 1
    });

    test('No RIR data: reps 20%+ over → +1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 10, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 13)]; // No RIR

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 52.5);  // +1 increment
      expect(adapted[1].reps, 9);  // -1 rep
    });

    test('No RIR data: reps 30%+ under → -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 10, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 6)]; // No RIR

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 47.5);  // -1 increment
    });

    // === New scenario coverage tests ===

    test('Catastrophic miss with high RIR (RIR 3, 25% reps) → -2 increments', () {
      // User's exact bug: did 2 reps out of 8 target, RIR 3
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 60, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 62.5, reps: 6, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 60, reps: 2, rir: 3)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.pyramidUp,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 57.5);  // 62.5 - 5 (two increments down)
      expect(adapted[1].reps, 8);  // 6 + 2
    });

    test('Significant miss with high RIR (RIR 3, 63% reps) → -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 5, rir: 3)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 47.5);  // -1 increment
    });

    test('Hit target with RIR 3 (too easy) → +1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 8, rir: 3)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 52.5);  // +1 increment
    });

    test('Catastrophic miss with RIR 2 → -2 increments', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 10, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 2, rir: 2)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 45.0);  // -2 increments
    });

    test('Hit target at failure (RIR 0, 100% reps) → -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 8, rir: 0)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 47.5);  // -1 inc (had to go to failure = too heavy)
    });

    test('Under target at failure (RIR 0, 75% reps) → -1 increment', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 6, rir: 0)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 47.5);  // -1 inc
    });

    test('Way over target (any RIR, 150% reps) → +2 increments', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 8, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 8, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 12, rir: 2)];

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 55.0);  // +2 increments (ratio 1.50 > 1.30)
    });

    test('Catastrophic miss with no RIR → -2 increments', () {
      final targets = [
        const ProgressionSetTarget(setNumber: 1, weight: 50, reps: 10, isAmrap: false),
        const ProgressionSetTarget(setNumber: 2, weight: 50, reps: 10, isAmrap: false),
      ];
      final completed = [const CompletedSetData(weight: 50, reps: 2)]; // No RIR

      final adapted = adaptTargets(
        pattern: SetProgressionPattern.straightSets,
        originalTargets: targets,
        completedSets: completed,
        increment: 2.5,
        totalSets: 2,
      );

      expect(adapted[1].weight, 45.0);  // -2 increments (ratio 0.20 < 0.40)
    });
  });
}
