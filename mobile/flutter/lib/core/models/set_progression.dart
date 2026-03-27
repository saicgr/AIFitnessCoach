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
