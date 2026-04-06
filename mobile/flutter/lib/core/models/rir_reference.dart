// RIR (Reps In Reserve) reference data for dynamic set intensity.
//
// 3-layer computation:
//   1. Base table: (trainingGoal, exerciseType) → RirRange(start, floor)
//   2. Equipment safety modifier: shifts floor (machines safer, barbells riskier)
//   3. Fitness level adjustment: beginners +1 buffer, advanced −1 floor
//
// Sources:
//   - Helms et al. (MASS Research Review) — proximity to failure guidelines
//   - Israetel / Renaissance Periodization — SFR (Stimulus-to-Fatigue Ratio)
//   - Zourdos et al. (2016) — RIR-based RPE scale validation
//   - Refalo et al. (2022, Sports Medicine) — failure vs non-failure meta-analysis
//   - NSCA — equipment safety standards and injury epidemiology
//   - StrongFirst — kettlebell ballistic training: "Don't fail"

/// RIR range for a (goal, exerciseType) combination.
/// [start] = RIR for first working set, [floor] = RIR for last set.
/// RIR linearly interpolates from start to floor across sets.
class RirRange {
  final int start;
  final int floor;
  const RirRange(this.start, this.floor);

  @override
  String toString() => 'RirRange($start→$floor)';
}

// ─── Layer 1: Base table ─────────────────────────────────────────────────────

/// Base RIR ranges keyed by (trainingGoal, exerciseType).
///
/// Compound = multi-joint (squat, bench, row, press, deadlift)
/// Isolation = single-joint (curl, extension, fly, raise)
/// Bodyweight = push-up, dip, pull-up, etc.
const Map<String, Map<String, RirRange>> rirBaseTable = {
  // Strength: technique preservation — stay conservative
  'strength': {
    'compound': RirRange(3, 2),
    'isolation': RirRange(3, 1),
    'bodyweight': RirRange(3, 2),
  },
  // Hypertrophy: proximity to failure drives growth
  'hypertrophy': {
    'compound': RirRange(3, 1),
    'isolation': RirRange(2, 0),
    'bodyweight': RirRange(2, 1),
  },
  'muscle_hypertrophy': {
    'compound': RirRange(3, 1),
    'isolation': RirRange(2, 0),
    'bodyweight': RirRange(2, 1),
  },
  // Endurance: fatigue management over high-rep sets
  'endurance': {
    'compound': RirRange(3, 2),
    'isolation': RirRange(3, 1),
    'bodyweight': RirRange(3, 2),
  },
  'muscular_endurance': {
    'compound': RirRange(3, 2),
    'isolation': RirRange(3, 1),
    'bodyweight': RirRange(3, 2),
  },
  // Power: speed and technique paramount — never grind
  'power': {
    'compound': RirRange(4, 3),
    'isolation': RirRange(3, 2),
    'bodyweight': RirRange(4, 3),
  },
  // General fitness / catch-all: mirrors hypertrophy
  'general_fitness': {
    'compound': RirRange(3, 1),
    'isolation': RirRange(2, 0),
    'bodyweight': RirRange(2, 1),
  },
};

// ─── Layer 2: Equipment safety modifier ──────────────────────────────────────

/// Equipment floor delta — shifts the RIR floor only.
///
/// Negative = safer equipment, can push closer to failure.
/// Positive = riskier equipment, need more reserve.
///
/// Rationale:
///   Machines: guided path + safety stops → failure is contained
///   Cables: resistance drops on release → no pinning hazard
///   Barbells: pinning hazard + spinal load under fatigue → riskiest
///   Kettlebells: ballistic technique collapse → acute injury risk
const Map<String, int> equipmentFloorDelta = {
  'machine': -1,
  'cable': -1,
  'smith': -1,
  'dumbbell': 0,
  'ez_bar': 0,
  'trap_bar': 0,
  'barbell': 1,
  'kettlebell': 1,
  'bodyweight': 0,
};

// ─── Layer 3: Fitness level adjustment ───────────────────────────────────────

/// Fitness level deltas — applied to both start and floor.
///
/// Beginners: +1 everywhere (form learning, injury prevention)
/// Early intermediate: +1 start only (returning users, <6mo — knows basics but needs start buffer)
/// Advanced: −1 floor only (experienced enough to push closer to failure)
const Map<String, ({int startDelta, int floorDelta})> fitnessLevelAdjustments = {
  'beginner': (startDelta: 1, floorDelta: 1),
  'early_intermediate': (startDelta: 1, floorDelta: 0),
  'intermediate': (startDelta: 0, floorDelta: 0),
  'advanced': (startDelta: 0, floorDelta: -1),
};

// ─── Computation ─────────────────────────────────────────────────────────────

/// Compute RIR for a specific set within an exercise.
///
/// Linearly interpolates from adjusted [start] to adjusted [floor] across sets.
/// Returns a value clamped to 0–5.
///
/// Example: Barbell Squat, Hypertrophy, Intermediate, 3 sets
///   Base: compound+hypertrophy = RirRange(3, 1)
///   Equipment: barbell +1 floor → floor = 2
///   Level: intermediate ±0
///   Result: Set 0 = 3, Set 1 = 2, Set 2 = 2 (lerp 3→2 rounded)
int computeSetRir({
  required int setIndex,
  required int totalSets,
  required String exerciseType,
  String? trainingGoal,
  String? fitnessLevel,
  String? equipment,
}) {
  final goal = (trainingGoal ?? 'general_fitness').toLowerCase();
  final exType = exerciseType.toLowerCase();
  final level = (fitnessLevel ?? 'intermediate').toLowerCase();
  final eq = normalizeEquipment(equipment);

  // Layer 1: Base range from goal × exerciseType
  final goalMap = rirBaseTable[goal] ?? rirBaseTable['general_fitness']!;
  final range = goalMap[exType] ?? goalMap['compound']!;

  // Layer 2: Equipment safety modifier (floor only)
  final eqDelta = equipmentFloorDelta[eq] ?? 0;

  // Layer 3: Fitness level modifier
  final lvlAdj = fitnessLevelAdjustments[level] ??
      (startDelta: 0, floorDelta: 0);

  final start = (range.start + lvlAdj.startDelta).clamp(0, 5);
  final floor = (range.floor + eqDelta + lvlAdj.floorDelta).clamp(0, 5);

  // Single set: return start RIR
  if (totalSets <= 1) return start;

  // Linear interpolation from start to floor
  final rir = start - (setIndex * (start - floor) / (totalSets - 1));
  return rir.round().clamp(0, 5);
}

/// Normalize an equipment string to a lookup key for [equipmentFloorDelta].
String normalizeEquipment(String? equipment) {
  if (equipment == null || equipment.isEmpty) return 'barbell';
  final lower = equipment.toLowerCase();
  if (lower.contains('machine')) return 'machine';
  if (lower.contains('cable')) return 'cable';
  if (lower.contains('smith')) return 'smith';
  if (lower.contains('dumbbell')) return 'dumbbell';
  if (lower.contains('kettlebell')) return 'kettlebell';
  if (lower.contains('ez')) return 'ez_bar';
  if (lower.contains('trap') || lower.contains('hex')) return 'trap_bar';
  if (lower.contains('barbell')) return 'barbell';
  if (lower.contains('bodyweight') || lower.contains('body weight')) return 'bodyweight';
  return 'barbell';
}
