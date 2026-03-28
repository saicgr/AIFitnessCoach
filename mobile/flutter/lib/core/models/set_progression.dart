import 'package:flutter/material.dart';

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
    }
  }

  List<String> get goalTags {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return ['Strength'];
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

  /// Convert the user's entered weight (set 1 weight) into the working weight
  /// that [generateTargets] expects (peak/heaviest weight).
  ///
  /// Most patterns treat set 1 as the heaviest, so the entered weight IS the
  /// working weight. Exceptions:
  /// - Pyramid Up: set 1 is lightest → peak = entered + (sets-1) × increment
  /// - Myo-Reps: entered = activation weight → working = entered / 0.8
  double deriveWorkingWeight({
    required double enteredWeight,
    required int totalSets,
    required double increment,
  }) {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return _snap(enteredWeight + (totalSets - 1) * increment, increment);
      case SetProgressionPattern.myoReps:
        return _snap(enteredWeight / 0.8, increment);
      default:
        return enteredWeight;
    }
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
  }) {
    switch (this) {
      case SetProgressionPattern.pyramidUp:
        return _generatePyramidUp(workingWeight, totalSets, baseReps, increment);
      case SetProgressionPattern.straightSets:
        return _generateStraight(workingWeight, totalSets, baseReps);
      case SetProgressionPattern.reversePyramid:
        return _generateReversePyramid(workingWeight, totalSets, baseReps, increment);
      case SetProgressionPattern.dropSets:
        return _generateDropSets(workingWeight, totalSets, increment);
      case SetProgressionPattern.topSetBackOff:
        return _generateTopSetBackOff(workingWeight, totalSets, baseReps, increment);
      case SetProgressionPattern.restPause:
        return _generateRestPause(workingWeight, totalSets);
      case SetProgressionPattern.myoReps:
        return _generateMyoReps(workingWeight, totalSets, baseReps, increment);
    }
  }

  /// Pyramid Up: weight increases, reps decrease each set.
  /// Set 1: W-2I × R+2, Set 2: W-I × R, Set 3: W × R-2
  List<ProgressionSetTarget> _generatePyramidUp(
    double w, int sets, int reps, double inc,
  ) {
    final targets = <ProgressionSetTarget>[];
    for (int i = 0; i < sets; i++) {
      final stepsFromTop = sets - 1 - i;
      final weight = _snap(w - (stepsFromTop * inc), inc);
      // Reps decrease by 2 per step toward the top
      final setReps = reps + (stepsFromTop * 2);
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: weight.clamp(inc, 9999),
        reps: setReps.clamp(1, 30),
        isAmrap: false,
      ));
    }
    return targets;
  }

  /// Straight Sets: same weight and reps every set.
  List<ProgressionSetTarget> _generateStraight(
    double w, int sets, int reps,
  ) {
    return List.generate(sets, (i) => ProgressionSetTarget(
      setNumber: i + 1,
      weight: w,
      reps: reps,
      isAmrap: false,
    ));
  }

  /// Reverse Pyramid: heaviest first, then ~12% and ~10% drops.
  /// Set 1: W × R-4, Set 2: W×0.875 × R-2, Set 3: W×0.79 × R
  List<ProgressionSetTarget> _generateReversePyramid(
    double w, int sets, int reps, double inc,
  ) {
    final percentages = [1.0, 0.875, 0.79, 0.72, 0.65];
    final repOffsets = [-4, -2, 0, 2, 4]; // Reps increase as weight drops
    final targets = <ProgressionSetTarget>[];
    for (int i = 0; i < sets; i++) {
      final pct = i < percentages.length ? percentages[i] : percentages.last;
      final repOffset = i < repOffsets.length ? repOffsets[i] : repOffsets.last;
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: _snap(w * pct, inc),
        reps: (reps + repOffset).clamp(1, 30),
        isAmrap: false,
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
      ));
      currentWeight *= 0.8; // 20% drop
    }
    return targets;
  }

  /// Top Set + Back-Off: 1 heavy set, then ~83% back-offs.
  List<ProgressionSetTarget> _generateTopSetBackOff(
    double w, int sets, int reps, double inc,
  ) {
    final targets = <ProgressionSetTarget>[
      ProgressionSetTarget(
        setNumber: 1,
        weight: w,
        reps: (reps - 4).clamp(1, 30), // Fewer reps on heavy top set
        isAmrap: false,
      ),
    ];
    final backOffWeight = _snap(w * 0.83, inc);
    for (int i = 1; i < sets; i++) {
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: backOffWeight,
        reps: (reps - 2).clamp(1, 30),
        isAmrap: false,
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
    ));
  }

  /// Myo-Reps: activation at ~80%, then mini-sets of 5.
  List<ProgressionSetTarget> _generateMyoReps(
    double w, int sets, int reps, double inc,
  ) {
    final myoWeight = _snap(w * 0.8, inc);
    final targets = <ProgressionSetTarget>[
      ProgressionSetTarget(
        setNumber: 1,
        weight: myoWeight,
        reps: reps + 5, // Activation set: higher reps
        isAmrap: false,
      ),
    ];
    for (int i = 1; i < sets; i++) {
      targets.add(ProgressionSetTarget(
        setNumber: i + 1,
        weight: myoWeight,
        reps: 5, // Mini-sets of 5
        isAmrap: false,
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
  }) {
    final targets = generateTargets(
      workingWeight: workingWeight,
      totalSets: totalSets,
      baseReps: baseReps,
      increment: increment,
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

  const ProgressionSetTarget({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isAmrap,
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
    final newReps = (original.reps - incrementAdjust).clamp(1, 30);

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
