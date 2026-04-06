part of 'set_progression.dart';


/// Set progression patterns for active workouts.
///
/// Determines how weight and reps change across sets within an exercise.
/// Each pattern has its own rest behavior, weight calculation, and display style.
///
/// Default is [pyramidUp] — weight increases and reps decrease each set.
enum SetProgressionPattern {
  pyramidUp,
  straightSets,
  reversePyramid,
  dropSets,
  topSetBackOff,
  restPause,
  myoReps,
  endurance,
}


extension SetProgressionPatternX on SetProgressionPattern {
  String get displayName {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Pyramid Up';
      case SetProgressionPattern.straightSets:
        return 'Straight Sets';
      case SetProgressionPattern.reversePyramid:
        return 'Reverse Pyramid';
      case SetProgressionPattern.dropSets:
        return 'Drop Sets';
      case SetProgressionPattern.topSetBackOff:
        return 'Top Set + Back-Off';
      case SetProgressionPattern.restPause:
        return 'Rest-Pause';
      case SetProgressionPattern.myoReps:
        return 'Myo-Reps';
      case SetProgressionPattern.endurance:
        return 'Endurance';
    }
  }

  /// Short name for the action chip (max ~10 chars).
  String get chipLabel {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Pyramid';
      case SetProgressionPattern.straightSets:
        return 'Straight';
      case SetProgressionPattern.reversePyramid:
        return 'Rev. Pyramid';
      case SetProgressionPattern.dropSets:
        return 'Drop Sets';
      case SetProgressionPattern.topSetBackOff:
        return 'Top+Back';
      case SetProgressionPattern.restPause:
        return 'Rest-Pause';
      case SetProgressionPattern.myoReps:
        return 'Myo-Reps';
      case SetProgressionPattern.endurance:
        return 'Endurance';
    }
  }

  String get description {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Weight builds up each set';
      case SetProgressionPattern.straightSets:
        return 'Same weight every set';
      case SetProgressionPattern.reversePyramid:
        return 'Heaviest first, then lighter';
      case SetProgressionPattern.dropSets:
        return 'Reduce weight, minimal rest';
      case SetProgressionPattern.topSetBackOff:
        return '1 heavy set, then lighter';
      case SetProgressionPattern.restPause:
        return 'Same weight, 15s micro-rests';
      case SetProgressionPattern.myoReps:
        return 'Activation set + mini-sets';
      case SetProgressionPattern.endurance:
        return 'Same weight, high reps';
    }
  }

  /// Detailed info explanation shown when user taps ⓘ.
  String get infoExplanation {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Each set gets heavier while reps decrease. '
            'You build up to your heaviest weight by the final set.\n\n'
            'Best for: Strength\n'
            '• Set 1: Light (warm-up feel)\n'
            '• Set 2: Moderate effort\n'
            '• Set 3: Heaviest (peak)\n\n'
            'Great for building confidence with heavier weights gradually.';
      case SetProgressionPattern.straightSets:
        return 'Keep the same weight and reps across all sets. '
            'Simple, effective, and proven.\n\n'
            'Best for: Hypertrophy\n'
            '• Every set at the same intensity\n'
            '• Maximizes effective reps\n\n'
            'Gold standard for muscle growth. Recommended by Renaissance Periodization.';
      case SetProgressionPattern.reversePyramid:
        return 'Start with your heaviest set when you\'re freshest, '
            'then reduce weight and increase reps.\n\n'
            'Best for: Strength + Hypertrophy\n'
            '• Set 1: Heaviest (peak effort)\n'
            '• Set 2: Moderate (-12%)\n'
            '• Set 3: Lighter (-10%)\n\n'
            'Most time-efficient model — every set taken close to failure.';
      case SetProgressionPattern.dropSets:
        return 'Complete a set, immediately reduce weight ~20% and continue '
            'with only 10 seconds to change the pin.\n\n'
            'Best for: Hypertrophy\n'
            '• All sets to failure (AMRAP)\n'
            '• ~20% weight reduction each drop\n'
            '• 10s rest to change weight\n\n'
            'Maximum muscle fatigue in minimal time. Best on machines/cables.';
      case SetProgressionPattern.topSetBackOff:
        return 'Work up to one heavy top set, then drop weight for '
            'volume back-off sets.\n\n'
            'Best for: Strength + Hypertrophy\n'
            '• Set 1: Heavy top set (RPE 9)\n'
            '• Sets 2-3: Lighter back-offs\n\n'
            'Top set drives strength. Back-offs build size.';
      case SetProgressionPattern.restPause:
        return 'Perform a set to failure, rest 15 seconds, then continue '
            'for more reps. Repeat 2-3 times.\n\n'
            'Best for: Hypertrophy\n'
            '• Same weight throughout\n'
            '• All segments to failure (AMRAP)\n'
            '• 15s micro-rests between segments\n\n'
            'Every rep is an effective rep. Extremely time-efficient.';
      case SetProgressionPattern.myoReps:
        return 'Perform a lighter activation set of 12-15 reps, then do '
            'mini-sets of 5 reps with only 5 seconds rest.\n\n'
            'Best for: Hypertrophy\n'
            '• Activation: ~80% of working weight × 15\n'
            '• Mini-sets: 5 reps each, 5s rest\n'
            '• Stop when you lose a rep\n\n'
            'One sequence replaces 3-4 straight sets. Ultra time-efficient.';
      case SetProgressionPattern.endurance:
        return 'Maintain the same weight across all sets while targeting high reps (15-30). '
            'Focus on muscular endurance and time under tension.\n\n'
            'Best for: Endurance\n'
            '• All sets at same weight\n'
            '• High reps (15-30)\n'
            '• Short rest (30-60s)\n\n'
            'Builds work capacity and muscular endurance. Great for conditioning.';
    }
  }

  /// Research citation for the progression model.
  String get researchSource {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Traditional strength training periodization. '
            'Supports gradual neural activation before peak loads.';
      case SetProgressionPattern.straightSets:
        return 'Schoenfeld et al. (2017) — Gold standard for hypertrophy. '
            'RP Hypertrophy uses this as default. Maximizes effective reps per set.';
      case SetProgressionPattern.reversePyramid:
        return 'Berkhan (Leangains) — 10% weight drop per set, +2 reps. '
            'Zourdos et al. (2016) — RPE-based load selection validates top-set-first approach.';
      case SetProgressionPattern.dropSets:
        return 'Fink et al. (2018) — Drop sets produce equivalent hypertrophy to 3 straight sets '
            'in roughly half the time. Optimal drop: 20-25% per reduction.';
      case SetProgressionPattern.topSetBackOff:
        return 'RTS / Tuchscherer — Top set at RPE 9, back-offs at -5% for volume. '
            'Combines strength stimulus (top set) with hypertrophy volume (back-offs).';
      case SetProgressionPattern.restPause:
        return 'Prestes et al. (2019) — Rest-pause produces similar hypertrophy to traditional sets '
            'with 15-20s inter-set rest. Marshall et al. (2012) confirmed efficacy.';
      case SetProgressionPattern.myoReps:
        return 'Borge Fagerli (creator, 2010) — Activation set of 12-20 reps followed by '
            'mini-sets of 3-5 reps with 10-15s rest. One sequence replaces 3-4 straight sets.';
      case SetProgressionPattern.endurance:
        return 'ACSM Guidelines — 15-25+ reps at 40-65% 1RM for muscular endurance. '
            'Short rest periods (30-60s) maximize metabolic stress and work capacity.';
    }
  }

  /// Practical guidance on when to use this pattern.
  String get whenToUse {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'Use when building to a heavy top set and you want to warm up progressively. '
            'Great for compound lifts (squat, bench, deadlift) when strength is the goal.';
      case SetProgressionPattern.straightSets:
        return 'Use for most exercises when hypertrophy is the goal. '
            'Best when you know a weight you can handle for all sets. Default recommendation.';
      case SetProgressionPattern.reversePyramid:
        return 'Use when you want to hit your heaviest weight first while fresh. '
            'Ideal for strength-focused trainees who also want hypertrophy volume.';
      case SetProgressionPattern.dropSets:
        return 'Use on machine or cable exercises at the end of a workout. '
            'Not ideal for barbells (changing plates takes too long). Best for isolation work.';
      case SetProgressionPattern.topSetBackOff:
        return 'Use for main compound lifts when you want both a strength PR attempt and volume. '
            'Popular in powerlifting-style training.';
      case SetProgressionPattern.restPause:
        return 'Use when short on time. Best for isolation exercises or machines. '
            'Not recommended for heavy compound lifts (safety concern at failure).';
      case SetProgressionPattern.myoReps:
        return 'Use for isolation exercises and accessories. '
            'Ideal when you want high-quality volume in minimal time. '
            'Not for compound lifts (fatigue impairs form).';
      case SetProgressionPattern.endurance:
        return 'Use for conditioning phases, endurance goals, or finishers. '
            'Great for isolation exercises at the end of a workout. '
            'Keep rest short (30-60s) to maximize metabolic stress.';
    }
  }

  /// How this pattern auto-adjusts based on performance.
  String get adaptiveDescription {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return 'If you exceed target reps by 20%+, remaining sets increase by 1 increment. '
            'If you fail to hit 70% of target reps at RIR 0-1, remaining sets decrease.';
      case SetProgressionPattern.straightSets:
        return 'If RIR is 4+ (way too easy), weight bumps up 2 increments. '
            'If RIR is 0 with <70% target reps, weight drops. Otherwise maintains.';
      case SetProgressionPattern.reversePyramid:
        return 'Same RIR-based autoregulation. Top set performance determines if back-off '
            'weights need adjusting. Fatigue >25% from set 1 forces a reduction.';
      case SetProgressionPattern.dropSets:
        return 'Based on reps achieved per drop (Fink et al. 2018):\n'
            '  < 5 reps: wider 28% drop (too heavy)\n'
            '  6-12 reps: standard 20% drop (ideal)\n'
            '  > 12 reps: tighter 15% drop (too light)';
      case SetProgressionPattern.topSetBackOff:
        return 'If top set is too easy (RIR 3+), back-off weights increase. '
            'If top set is a grind (RIR 0, <85% target reps), back-offs decrease.';
      case SetProgressionPattern.restPause:
        return 'If initial set yields < 6 reps, weight is reduced 10% for remaining segments. '
            'This ensures enough volume accumulation per Prestes et al. (2019).';
      case SetProgressionPattern.myoReps:
        return 'Activation set reps determine adjustment (Fagerli protocol):\n'
            '  < 9 reps: reduce weight 15%\n'
            '  9-11 reps: reduce 5%\n'
            '  12-20 reps: ideal, no change\n'
            '  > 25 reps: increase weight 15%\n'
            '  Mini-set < 3 reps: reduce 10%';
      case SetProgressionPattern.endurance:
        return 'Same weight all sets. If you hit 30+ reps, increase weight next session. '
            'If you cannot reach 15 reps, reduce weight.';
    }
  }

  IconData get icon {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return Icons.trending_up;
      case SetProgressionPattern.straightSets:
        return Icons.horizontal_rule;
      case SetProgressionPattern.reversePyramid:
        return Icons.trending_down;
      case SetProgressionPattern.dropSets:
        return Icons.local_fire_department;
      case SetProgressionPattern.topSetBackOff:
        return Icons.fitness_center;
      case SetProgressionPattern.restPause:
        return Icons.pause_circle_outline;
      case SetProgressionPattern.myoReps:
        return Icons.bolt;
      case SetProgressionPattern.endurance:
        return Icons.timer_outlined;
    }
  }

  List<String> get goalTags {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return ['Strength', 'Hypertrophy'];
      case SetProgressionPattern.straightSets:
        return ['Hypertrophy'];
      case SetProgressionPattern.reversePyramid:
        return ['Strength', 'Hypertrophy'];
      case SetProgressionPattern.dropSets:
        return ['Hypertrophy'];
      case SetProgressionPattern.topSetBackOff:
        return ['Strength', 'Hypertrophy'];
      case SetProgressionPattern.restPause:
        return ['Hypertrophy'];
      case SetProgressionPattern.myoReps:
        return ['Hypertrophy'];
      case SetProgressionPattern.endurance:
        return ['Endurance'];
    }
  }

  /// Rest duration override. null = use normal rest timer.
  Duration? get restDuration {
    switch (this) {
      case SetProgressionPattern.dropSets:
        return const Duration(seconds: 10);
      case SetProgressionPattern.restPause:
        return const Duration(seconds: 15);
      case SetProgressionPattern.myoReps:
        return const Duration(seconds: 5);
      case SetProgressionPattern.reversePyramid:
        return null; // Normal but UI suggests longer (120-180s)
      default:
        return null; // Normal rest timer
    }
  }

  /// Suggested default rest in seconds for display (not enforced).
  String get restDisplayHint {
    switch (this) {
      case SetProgressionPattern.dropSets:
        return '10s pin change';
      case SetProgressionPattern.restPause:
        return '15s rest';
      case SetProgressionPattern.myoReps:
        return '5s rest';
      case SetProgressionPattern.reversePyramid:
        return '120-180s rest';
      case SetProgressionPattern.topSetBackOff:
        return '120s / 60s rest';
      case SetProgressionPattern.endurance:
        return '30-60s rest';
      default:
        return '60-120s rest';
    }
  }

  /// Whether sets in this pattern should show "Drop X of Y" instead of "Set X of Y".
  bool get usesDropLabel => this == SetProgressionPattern.dropSets;

  /// Whether sets in this pattern use "AMRAP" (as many reps as possible).
  bool get isAmrapBased {
    switch (this) {
      case SetProgressionPattern.dropSets:
      case SetProgressionPattern.restPause:
        return true;
      default:
        return false;
    }
  }

  /// Whether to hide the RIR row (failure-based patterns).
  bool get hidesRir {
    switch (this) {
      case SetProgressionPattern.dropSets:
      case SetProgressionPattern.restPause:
        return true;
      default:
        return false;
    }
  }

  /// Whether this is an "advanced" pattern (shown under Advanced section).
  bool get isAdvanced {
    switch (this) {
      case SetProgressionPattern.restPause:
      case SetProgressionPattern.myoReps:
        return true;
      default:
        return false;
    }
  }

  /// Serialize to string for SharedPreferences storage.
  String get storageKey => name;

  /// Deserialize from storage string.
  static SetProgressionPattern fromStorageKey(String key) {
    return SetProgressionPattern.values.firstWhere(
      (p) => p.name == key,
      orElse: () => SetProgressionPattern.pyramidUp,
    );
  }

  /// Convert a completed set's weight into the working weight (peak/heaviest)
  /// that [generateTargets] expects.
  ///
  /// [completedSetIndex] is the 0-based position of the set that was completed.
  /// Each pattern reverses its position-specific weight offset:
  /// - Pyramid Up: set i weight = peak - (totalSets-1-i)×inc → reverse to get peak
  /// - Myo-Reps: activation/mini-set weight → working = weight / 0.8
  /// - Others: set 1 IS the heaviest (or same weight), so no offset needed
  double deriveWorkingWeight({
    required double enteredWeight,
    required int totalSets,
    required double increment,
    int completedSetIndex = 0,
  }) {
    double result;
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        // Set i weight = peak - (totalSets-1-i)*inc
        // → peak = enteredWeight + (totalSets-1-completedSetIndex)*inc
        final stepsFromTop = totalSets - 1 - completedSetIndex;
        result = _snap(enteredWeight + stepsFromTop * increment, increment);
      case SetProgressionPattern.myoReps:
        result = _snap(enteredWeight / 0.8, increment);
      default:
        result = enteredWeight;
    }
    debugPrint('⚙️ [Progression] deriveWorkingWeight: pattern=$this, entered=$enteredWeight, sets=$totalSets, inc=$increment, completedIdx=$completedSetIndex → working=$result');
    return result;
  }

  /// Reverse the pattern-specific rep offset for a completed set at [setIndex]
  /// to recover the base rep target (peak-set reps for pyramid, etc.)
  static int reverseRepOffset(SetProgressionPattern pattern, int actualReps, int setIndex, int totalSets) {
    int result;
    switch (pattern) {
      case SetProgressionPattern.pyramidUp:
        // Dynamic step: ±1 for strength (≤5 baseReps), ±2 for hypertrophy (6+)
        final stepsFromTop = totalSets - 1 - setIndex;
        // Try standard step (2) first
        var baseReps = actualReps - stepsFromTop * 2;
        // If result is in strength range, re-derive with smaller step (1)
        if (baseReps <= 5) {
          baseReps = actualReps - stepsFromTop * 1;
        }
        // Floor to 6: minimum effective rep range for non-failure training
        result = baseReps.clamp(6, 30);
      case SetProgressionPattern.reversePyramid:
        // repOffsets = [-4, -2, 0, 2, 4]
        const offsets = [-4, -2, 0, 2, 4];
        final offset = setIndex < offsets.length ? offsets[setIndex] : offsets.last;
        result = (actualReps - offset).clamp(1, 30);
      case SetProgressionPattern.topSetBackOff:
        // Set 0: baseReps - 4, Sets 1+: baseReps - 2
        final offset = setIndex == 0 ? -4 : -2;
        result = (actualReps - offset).clamp(1, 30);
      case SetProgressionPattern.endurance:
        // Set i reps = baseReps + i*2
        result = (actualReps - setIndex * 2).clamp(1, 30);
      case SetProgressionPattern.myoReps:
        // Set 0 (activation): baseReps + 5, Mini-sets: fixed at 5
        if (setIndex == 0) {
          result = (actualReps - 5).clamp(1, 30);
        } else {
          result = actualReps;
        }
      default:
        result = actualReps; // Straight Sets, Rest-Pause: no offset
    }
    debugPrint('⚙️ [Progression] reverseRepOffset: pattern=$pattern, actualReps=$actualReps, setIdx=$setIndex, totalSets=$totalSets → baseReps=$result');
    return result;
  }

  /// Generate per-set targets for this progression pattern.
  ///
  /// [workingWeight] is the exercise's working weight (heaviest intended weight).
  /// [totalSets] is the number of sets.
  /// [baseReps] is the target reps at working weight.
  /// [increment] is the equipment weight increment (in user's display unit).
  ///
  /// Returns a list of [ProgressionSetTarget] for each set.
  List<ProgressionSetTarget> generateTargets({
    required double workingWeight,
    required int totalSets,
    required int baseReps,
    required double increment,
    List<double>? ownedWeights,
    String? trainingGoal,
    int? maxReps,
    String? exerciseType,
    String? fitnessLevel,
    String? equipment,
  }) {
    // 1. Generate raw targets using pattern-specific logic
    List<ProgressionSetTarget> raw;
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        raw = _generatePyramidUp(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
      case SetProgressionPattern.straightSets:
        raw = _generateStraight(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
      case SetProgressionPattern.reversePyramid:
        raw = _generateReversePyramid(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
      case SetProgressionPattern.dropSets:
        raw = _generateDropSets(workingWeight, totalSets, increment);
      case SetProgressionPattern.topSetBackOff:
        raw = _generateTopSetBackOff(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
      case SetProgressionPattern.restPause:
        raw = _generateRestPause(workingWeight, totalSets);
      case SetProgressionPattern.myoReps:
        raw = _generateMyoReps(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
      case SetProgressionPattern.endurance:
        raw = _generateEndurance(workingWeight, totalSets, baseReps, increment,
            exerciseType: exerciseType, trainingGoal: trainingGoal,
            fitnessLevel: fitnessLevel, equipment: equipment);
    }

    // 1b. Apply exercise-type ceiling (compound=12, isolation=15, bodyweight=20)
    if (maxReps != null) {
      final ceiling = maxReps;
      raw = raw.map((t) {
        if (t.isAmrap || t.reps <= ceiling) return t;
        return ProgressionSetTarget(
          setNumber: t.setNumber, weight: t.weight,
          reps: ceiling, isAmrap: false, rir: t.rir,
        );
      }).toList();
    }

    // 2. If no inventory, clamp reps to goal range and return
    if (ownedWeights == null || ownedWeights.isEmpty) {
      if (trainingGoal != null) {
        final goalRange = TrainingGoalRepRange.forGoal(trainingGoal);
        return raw.map((t) {
          if (t.isAmrap) return t;
          final clamped = goalRange.clampReps(t.reps);
          if (clamped == t.reps) return t;
          return ProgressionSetTarget(
            setNumber: t.setNumber, weight: t.weight, reps: clamped, isAmrap: false, rir: t.rir,
          );
        }).toList();
      }
      return raw;
    }

    // 3. Snap to owned weights + adjust reps to maintain volume
    final sorted = [...ownedWeights]..sort();
    final isDropPattern = this == SetProgressionPattern.dropSets;

    final snapped = <ProgressionSetTarget>[];
    for (int i = 0; i < raw.length; i++) {
      final target = raw[i];

      if (target.isAmrap) {
        // AMRAP: snap weight, no rep adjustment
        double snappedWeight;
        if (isDropPattern && i > 0) {
          // Drop sets: always go to next LOWER owned weight
          final prevWeight = snapped[i - 1].weight;
          final lower = sorted.where((w) => w < prevWeight - 0.01).toList();
          snappedWeight = lower.isNotEmpty ? lower.last : sorted.first;
        } else {
          snappedWeight = _findClosestInList(target.weight, sorted);
        }
        snapped.add(ProgressionSetTarget(
          setNumber: target.setNumber,
          weight: snappedWeight,
          reps: target.reps,
          isAmrap: true,
          rir: target.rir,
        ));
        continue;
      }

      final snappedWeight = _findClosestInList(target.weight, sorted);
      if ((snappedWeight - target.weight).abs() < 0.01) {
        snapped.add(target); // Already on an owned weight
        continue;
      }

      // Adjust reps proportionally: volume = weight × reps stays ~constant
      final volume = target.weight * target.reps;
      final adjustedReps = snappedWeight > 0
          ? (volume / snappedWeight).round().clamp(1, 30)
          : target.reps;

      snapped.add(ProgressionSetTarget(
        setNumber: target.setNumber,
        weight: snappedWeight,
        reps: adjustedReps,
        isAmrap: false,
        rir: target.rir,
      ));
    }

    // 4. Clamp reps to goal range if training goal is specified
    if (trainingGoal != null) {
      final goalRange = TrainingGoalRepRange.forGoal(trainingGoal);
      return snapped.map((t) {
        if (t.isAmrap) return t;
        final clamped = goalRange.clampReps(t.reps);
        if (clamped == t.reps) return t;
        return ProgressionSetTarget(
          setNumber: t.setNumber,
          weight: t.weight,
          reps: clamped,
          isAmrap: false,
          rir: t.rir,
        );
      }).toList();
    }

    return snapped;
  }

  /// Find closest value in a sorted list.
  static double _findClosestInList(double target, List<double> sorted) {
    if (sorted.isEmpty) return target;
    double closest = sorted.first;
    double minDiff = (target - closest).abs();
    for (final w in sorted) {
      final diff = (target - w).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = w;
      }
    }
    return closest;
  }

  /// Pyramid Up: weight increases, reps decrease each set.
  /// Dynamic rep step: ±1 for strength (≤5 baseReps), ±2 for hypertrophy (6+).
  /// Minimum 6 reps per set (non-failure training safety floor).
  List<ProgressionSetTarget> _generatePyramidUp(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    debugPrint('⚙️ [Progression] pyramidUp: working=$w, sets=$sets, baseReps=$reps, inc=$inc, step=${_pyramidRepStep(reps)}');
    final step = _pyramidRepStep(reps);
    final targets = <ProgressionSetTarget>[];
    for (int i = 0; i < sets; i++) {
      final stepsFromTop = sets - 1 - i;
      final weight = _snap(w - (stepsFromTop * inc), inc);
      final setReps = reps + (stepsFromTop * step);
      final rir = computeSetRir(
        setIndex: i, totalSets: sets,
        exerciseType: exerciseType ?? 'compound',
        trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
        equipment: equipment,
      );
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: weight.clamp(inc, 9999),
        reps: setReps.clamp(6, 30),
        isAmrap: false,
        rir: rir,
      ));
    }
    return targets;
  }

  /// Rep delta per pyramid step. Smaller steps for strength rep ranges.
  static int _pyramidRepStep(int baseReps) => baseReps <= 5 ? 1 : 2;

  /// Straight Sets: same weight and reps every set.
  /// RIR-based weight: lower RIR (closer to failure) → +1 increment.
  /// Single set stays at base weight (no progression context).
  List<ProgressionSetTarget> _generateStraight(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    return List.generate(sets, (i) {
      final rir = computeSetRir(
        setIndex: i, totalSets: sets,
        exerciseType: exerciseType ?? 'compound',
        trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
        equipment: equipment,
      );
      // Lower RIR sets get +1 increment to reflect higher intensity
      final baseRir = computeSetRir(
        setIndex: 0, totalSets: sets,
        exerciseType: exerciseType ?? 'compound',
        trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
        equipment: equipment,
      );
      final setWeight = (rir < baseRir && inc > 0) ? _snap(w + inc, inc) : w;
      return ProgressionSetTarget(
        setNumber: i + 1,
        weight: setWeight,
        reps: reps,
        isAmrap: false,
        rir: rir,
      );
    });
  }

  /// Reverse Pyramid: heaviest first, then ~12% and ~10% drops.
  /// Set 1: W × R-4, Set 2: W×0.875 × R-2, Set 3: W×0.79 × R
  List<ProgressionSetTarget> _generateReversePyramid(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    final percentages = [1.0, 0.875, 0.79, 0.72, 0.65];
    final repOffsets = [-4, -2, 0, 2, 4]; // Reps increase as weight drops
    final targets = <ProgressionSetTarget>[];
    for (int i = 0; i < sets; i++) {
      final pct = i < percentages.length ? percentages[i] : percentages.last;
      final repOffset = i < repOffsets.length ? repOffsets[i] : repOffsets.last;
      // Reversed: heaviest first (i=0) gets floor RIR, lightest gets start RIR
      final rir = computeSetRir(
        setIndex: sets - 1 - i, totalSets: sets,
        exerciseType: exerciseType ?? 'compound',
        trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
        equipment: equipment,
      );
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: _snap(w * pct, inc),
        reps: (reps + repOffset).clamp(1, 30),
        isAmrap: false,
        rir: rir,
      ));
    }
    return targets;
  }

  /// Drop Sets: ~20% weight reduction each drop, all AMRAP.
  List<ProgressionSetTarget> _generateDropSets(
    double w, int sets, double inc,
  ) {
    final targets = <ProgressionSetTarget>[];
    double currentWeight = w;
    for (int i = 0; i < sets; i++) {
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: _snap(currentWeight, inc),
        reps: 0, // AMRAP
        isAmrap: true,
        rir: i == 0 ? 1 : 0, // First set RIR 1, drops to failure
      ));
      currentWeight *= 0.8; // 20% drop
    }
    return targets;
  }

  /// Top Set + Back-Off: 1 heavy set, then ~83% back-offs.
  List<ProgressionSetTarget> _generateTopSetBackOff(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    // Top set: floor RIR (most intense)
    final topRir = computeSetRir(
      setIndex: sets - 1, totalSets: sets,
      exerciseType: exerciseType ?? 'compound',
      trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
      equipment: equipment,
    );
    final targets = <ProgressionSetTarget>[
      ProgressionSetTarget(
        setNumber: 1,
        weight: w,
        reps: (reps - 4).clamp(1, 30),
        isAmrap: false,
        rir: topRir,
      ),
    ];
    final backOffWeight = _snap(w * 0.83, inc);
    // Back-offs: start RIR (more reserve)
    final backOffRir = computeSetRir(
      setIndex: 0, totalSets: sets,
      exerciseType: exerciseType ?? 'compound',
      trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
      equipment: equipment,
    );
    for (int i = 1; i < sets; i++) {
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: backOffWeight,
        reps: (reps - 2).clamp(1, 30),
        isAmrap: false,
        rir: backOffRir,
      ));
    }
    return targets;
  }

  /// Rest-Pause: same weight, all AMRAP with 15s rests.
  List<ProgressionSetTarget> _generateRestPause(double w, int sets) {
    return List.generate(sets, (i) => ProgressionSetTarget(
      setNumber: i + 1,
      weight: w,
      reps: 0,
      isAmrap: true,
      rir: 0, // All to failure
    ));
  }

  /// Myo-Reps: activation at ~80%, then mini-sets of 5.
  List<ProgressionSetTarget> _generateMyoReps(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    final myoWeight = _snap(w * 0.8, inc);
    // Activation set: dynamic RIR based on context
    final activationRir = computeSetRir(
      setIndex: 0, totalSets: sets,
      exerciseType: exerciseType ?? 'isolation',
      trainingGoal: trainingGoal, fitnessLevel: fitnessLevel,
      equipment: equipment,
    );
    final targets = <ProgressionSetTarget>[
      ProgressionSetTarget(
        setNumber: 1,
        weight: myoWeight,
        reps: reps + 5,
        isAmrap: false,
        rir: activationRir,
      ),
    ];
    for (int i = 1; i < sets; i++) {
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: myoWeight,
        reps: 5, // Mini-sets of 5
        isAmrap: false,
        rir: 0, // Mini-sets: to failure
      ));
    }
    return targets;
  }

  /// Endurance: Same weight, high reps (15-30), each set increases reps by 2-3.
  /// RIR-based weight: lower RIR (closer to failure) → +1 increment.
  /// Single set stays at base weight (no progression context).
  List<ProgressionSetTarget> _generateEndurance(
    double w, int sets, int reps, double inc, {
    String? exerciseType, String? trainingGoal,
    String? fitnessLevel, String? equipment,
  }) {
    final baseReps = reps < 15 ? 15 : reps; // Minimum 15 for endurance
    final targets = <ProgressionSetTarget>[];
    final startRir = computeSetRir(
      setIndex: 0, totalSets: sets,
      exerciseType: exerciseType ?? 'compound',
      trainingGoal: trainingGoal ?? 'endurance',
      fitnessLevel: fitnessLevel, equipment: equipment,
    );
    for (int i = 0; i < sets; i++) {
      final rir = computeSetRir(
        setIndex: i, totalSets: sets,
        exerciseType: exerciseType ?? 'compound',
        trainingGoal: trainingGoal ?? 'endurance',
        fitnessLevel: fitnessLevel, equipment: equipment,
      );
      // Lower RIR sets get +1 increment to reflect higher intensity
      final setWeight = (rir < startRir && inc > 0) ? _snap(w + inc, inc) : w;
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: setWeight,
        reps: (baseReps + i * 2).clamp(15, 30),
        isAmrap: false,
        rir: rir,
      ));
    }
    return targets;
  }

  /// Snap weight to nearest increment.
  double _snap(double weight, double increment) {
    if (increment <= 0) return weight;
    return (weight / increment).round() * increment;
  }

  /// Generate a preview string for the bottom sheet (e.g., "100 × 12 → 110 × 10 → 120 × 8").
  String previewString({
    required double workingWeight,
    int totalSets = 3,
    int baseReps = 10,
    required double increment,
    required String unit,
    String? trainingGoal,
    int? maxReps,
    String? exerciseType,
    String? fitnessLevel,
    String? equipment,
  }) {
    final targets = generateTargets(
      workingWeight: workingWeight,
      totalSets: totalSets,
      baseReps: baseReps,
      increment: increment,
      trainingGoal: trainingGoal,
      maxReps: maxReps,
      exerciseType: exerciseType,
      fitnessLevel: fitnessLevel,
      equipment: equipment,
    );
    return targets.map((t) {
      final w = t.weight % 1 == 0 ? t.weight.toInt().toString() : t.weight.toStringAsFixed(1);
      final r = t.isAmrap ? 'AMRAP' : '${t.reps}';
      return '$w × $r';
    }).join(' → ');
  }
}


/// A single set's target values generated by a progression pattern.
class ProgressionSetTarget {
  final int setNumber;
  final double weight;
  final int reps; // 0 if AMRAP
  final bool isAmrap;
  final int? rir; // Pattern-specific RIR (null = use backend default)

  const ProgressionSetTarget({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isAmrap,
    this.rir,
  });
}


/// Completed set data used for adaptive progression calculations.
class CompletedSetData {
  final double weight; // in kg (internal unit)
  final int reps;
  final int? rir;

  const CompletedSetData({
    required this.weight,
    required this.reps,
    this.rir,
  });

  /// Performance score: weight x reps (for fatigue tracking).
  double get performanceScore => weight * reps;
}

