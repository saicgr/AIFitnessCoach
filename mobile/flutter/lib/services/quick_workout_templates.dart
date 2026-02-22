import 'quick_workout_constants.dart';

/// A single muscle slot in a quick workout template.
///
/// Defines which muscle to target, whether to prefer compound exercises,
/// and an optional superset partner muscle.
class QuickMuscleSlot {
  final String muscle;
  final bool preferCompound;
  final String? supersetPartner;

  const QuickMuscleSlot(
    this.muscle, {
    this.preferCompound = false,
    this.supersetPartner,
  });
}

// ============================================
// Focus Strategy Pattern
// ============================================

/// Abstract strategy for a workout focus mode.
///
/// Each focus (strength, cardio, stretch, etc.) is a strategy that
/// provides its own muscle slot ordering, format selection, and
/// time cost calculation. The engine dispatches to the right strategy
/// via a map lookup — no if/else branching.
abstract class FocusStrategy {
  /// Get the ordered list of muscle slots for this focus.
  /// The engine takes slots from this list until the time budget is full.
  List<QuickMuscleSlot> getSlots(int durationMinutes);

  /// Get the workout format ('supersets', 'straight', 'circuit', 'hiit', 'tabata', 'flow').
  String getFormat(bool useSupersets, int durationMinutes);

  /// Get the time cost per exercise in seconds for time budget calculation.
  int timeCostPerExercise(String difficulty, bool useSupersets);

  /// Whether this strategy uses timed exercises (cardio intervals, stretch holds).
  bool get usesTimed => false;

  /// Whether exercises from this strategy should have hold_seconds set.
  bool get usesHolds => false;

  /// Whether exercises from this strategy should have duration_seconds set.
  bool get usesDuration => false;
}

// ============================================
// Muscle-Targeted Strategy (shared base)
// ============================================

/// Base for strength-style focus modes (Strength, FullBody, Upper, Lower, Core).
///
/// Handles exercise selection via ExerciseSelector, set target generation
/// via ProgressiveOverload, and superset pairing. Subclasses only need
/// to provide their specific muscle slot list.
abstract class MuscleTargetedStrategy extends FocusStrategy {
  @override
  String getFormat(bool useSupersets, int durationMinutes) {
    return useSupersets ? 'supersets' : 'straight';
  }

  @override
  int timeCostPerExercise(String difficulty, bool useSupersets) {
    final restMult = QuickWorkoutConstants.difficultyMultipliers[difficulty]?.rest ?? 1.0;
    if (useSupersets) {
      // Superset pair: two exercises back-to-back with short intra-rest
      // Cost is for ONE side of the pair (engine processes pairs together)
      return (QuickWorkoutConstants.supersetPairTimeCost * restMult).round();
    } else {
      return (QuickWorkoutConstants.straightSetTimeCost * restMult).round();
    }
  }
}

// ============================================
// Concrete Focus Strategies
// ============================================

class StrengthStrategy extends MuscleTargetedStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    return const [
      QuickMuscleSlot('chest', preferCompound: true, supersetPartner: 'back'),
      QuickMuscleSlot('back', preferCompound: true, supersetPartner: 'chest'),
      QuickMuscleSlot('quads', preferCompound: true, supersetPartner: 'hamstrings'),
      QuickMuscleSlot('hamstrings', preferCompound: true, supersetPartner: 'quads'),
      QuickMuscleSlot('shoulders', preferCompound: true, supersetPartner: 'biceps'),
      QuickMuscleSlot('biceps', preferCompound: false, supersetPartner: 'triceps'),
      QuickMuscleSlot('triceps', preferCompound: false, supersetPartner: 'biceps'),
      QuickMuscleSlot('abs', preferCompound: false),
      QuickMuscleSlot('chest', preferCompound: false),
      QuickMuscleSlot('back', preferCompound: false),
      QuickMuscleSlot('shoulders', preferCompound: false),
      QuickMuscleSlot('calves', preferCompound: false),
    ];
  }
}

class FullBodyStrategy extends MuscleTargetedStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    return const [
      QuickMuscleSlot('chest', preferCompound: true, supersetPartner: 'back'),
      QuickMuscleSlot('back', preferCompound: true, supersetPartner: 'chest'),
      QuickMuscleSlot('quads', preferCompound: true, supersetPartner: 'hamstrings'),
      QuickMuscleSlot('hamstrings', preferCompound: false, supersetPartner: 'quads'),
      QuickMuscleSlot('glutes', preferCompound: true),
      QuickMuscleSlot('shoulders', preferCompound: true),
      QuickMuscleSlot('abs', preferCompound: false),
      QuickMuscleSlot('biceps', preferCompound: false, supersetPartner: 'triceps'),
      QuickMuscleSlot('triceps', preferCompound: false, supersetPartner: 'biceps'),
    ];
  }
}

class UpperBodyStrategy extends MuscleTargetedStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    return const [
      QuickMuscleSlot('chest', preferCompound: true, supersetPartner: 'back'),
      QuickMuscleSlot('back', preferCompound: true, supersetPartner: 'chest'),
      QuickMuscleSlot('shoulders', preferCompound: true),
      QuickMuscleSlot('biceps', preferCompound: false, supersetPartner: 'triceps'),
      QuickMuscleSlot('triceps', preferCompound: false, supersetPartner: 'biceps'),
      QuickMuscleSlot('chest', preferCompound: false),
      QuickMuscleSlot('back', preferCompound: false),
    ];
  }
}

class LowerBodyStrategy extends MuscleTargetedStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    return const [
      QuickMuscleSlot('quads', preferCompound: true, supersetPartner: 'hamstrings'),
      QuickMuscleSlot('hamstrings', preferCompound: true, supersetPartner: 'quads'),
      QuickMuscleSlot('glutes', preferCompound: true, supersetPartner: 'calves'),
      QuickMuscleSlot('calves', preferCompound: false, supersetPartner: 'glutes'),
      QuickMuscleSlot('quads', preferCompound: false),
      QuickMuscleSlot('hamstrings', preferCompound: false),
    ];
  }
}

class CoreStrategy extends MuscleTargetedStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    return const [
      QuickMuscleSlot('abs', preferCompound: false, supersetPartner: 'lower_back'),
      QuickMuscleSlot('lower_back', preferCompound: false, supersetPartner: 'abs'),
      QuickMuscleSlot('obliques', preferCompound: false),
      QuickMuscleSlot('abs', preferCompound: false),
      QuickMuscleSlot('obliques', preferCompound: false),
      QuickMuscleSlot('abs', preferCompound: false),
    ];
  }

  @override
  String getFormat(bool useSupersets, int durationMinutes) {
    return useSupersets ? 'supersets' : 'circuit';
  }
}

class CardioHiitStrategy extends FocusStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    // Cardio uses full_body slots — the engine fills from the cardio pool
    final count = _cardioExerciseCount(durationMinutes);
    return List.generate(
      count,
      (_) => const QuickMuscleSlot('full_body'),
    );
  }

  @override
  String getFormat(bool useSupersets, int durationMinutes) {
    return durationMinutes <= 5 ? 'tabata' : 'hiit';
  }

  @override
  int timeCostPerExercise(String difficulty, bool useSupersets) {
    final restMult = QuickWorkoutConstants.difficultyMultipliers[difficulty]?.rest ?? 1.0;
    return (QuickWorkoutConstants.hiitIntervalTimeCost * restMult).round();
  }

  @override
  bool get usesTimed => true;

  @override
  bool get usesDuration => true;

  int _cardioExerciseCount(int duration) {
    switch (duration) {
      case 5: return 4;
      case 10: return 6;
      case 15: return 7;
      case 20: return 8;
      case 25: return 9;
      case 30: return 10;
      default: return 8;
    }
  }
}

class StretchStrategy extends FocusStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    // Anatomical flow: lower → upper → full body
    return const [
      QuickMuscleSlot('hamstrings'),
      QuickMuscleSlot('hip_flexors'),
      QuickMuscleSlot('quads'),
      QuickMuscleSlot('glutes'),
      QuickMuscleSlot('calves'),
      QuickMuscleSlot('chest'),
      QuickMuscleSlot('shoulders'),
      QuickMuscleSlot('back'),
      QuickMuscleSlot('neck'),
      QuickMuscleSlot('abs'),
      QuickMuscleSlot('full_body'),
      QuickMuscleSlot('hip_flexors'),
    ];
  }

  @override
  String getFormat(bool useSupersets, int durationMinutes) {
    return 'flow';
  }

  @override
  int timeCostPerExercise(String difficulty, bool useSupersets) {
    return QuickWorkoutConstants.stretchHoldTimeCost;
  }

  @override
  bool get usesTimed => true;

  @override
  bool get usesHolds => true;
}

class EMOMStrategy extends FocusStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    // 3-5 mixed compound/isolation for EMOM
    final count = durationMinutes <= 10 ? 3 : (durationMinutes <= 20 ? 4 : 5);
    const baseSlots = [
      QuickMuscleSlot('quads', preferCompound: true),
      QuickMuscleSlot('chest', preferCompound: true),
      QuickMuscleSlot('back', preferCompound: true),
      QuickMuscleSlot('shoulders', preferCompound: false),
      QuickMuscleSlot('abs', preferCompound: false),
    ];
    return baseSlots.take(count).toList();
  }

  @override
  String getFormat(bool useSupersets, int durationMinutes) => 'emom';

  @override
  int timeCostPerExercise(String difficulty, bool useSupersets) {
    return QuickWorkoutConstants.emomTimeCost;
  }

  @override
  bool get usesTimed => true;

  @override
  bool get usesDuration => true;
}

class AMRAPStrategy extends FocusStrategy {
  @override
  List<QuickMuscleSlot> getSlots(int durationMinutes) {
    // 3-5 exercises per AMRAP round
    final count = durationMinutes <= 10 ? 3 : (durationMinutes <= 20 ? 4 : 5);
    const baseSlots = [
      QuickMuscleSlot('quads', preferCompound: true),
      QuickMuscleSlot('chest', preferCompound: true),
      QuickMuscleSlot('back', preferCompound: true),
      QuickMuscleSlot('shoulders', preferCompound: true),
      QuickMuscleSlot('abs', preferCompound: false),
    ];
    return baseSlots.take(count).toList();
  }

  @override
  String getFormat(bool useSupersets, int durationMinutes) => 'amrap';

  @override
  int timeCostPerExercise(String difficulty, bool useSupersets) {
    return QuickWorkoutConstants.amrapTimeCost;
  }

  @override
  bool get usesTimed => true;
}

// ============================================
// Strategy Registry
// ============================================

/// Map-based strategy dispatch — one-liner, no switch statement.
final Map<String, FocusStrategy> focusStrategies = {
  'strength': StrengthStrategy(),
  'cardio': CardioHiitStrategy(),
  'stretch': StretchStrategy(),
  'full_body': FullBodyStrategy(),
  'upper_body': UpperBodyStrategy(),
  'lower_body': LowerBodyStrategy(),
  'core': CoreStrategy(),
  'emom': EMOMStrategy(),
  'amrap': AMRAPStrategy(),
};
