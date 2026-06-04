/// Deterministic equipment -> per-gym-progress-scope classifier (client mirror of
/// `backend/services/equipment_scope.py` — keep the keyword lists in sync).
///
/// Why: the SAME selected weight on a cable/stack/plate-loaded machine is mechanically
/// different across gyms (1:1 vs 2:1 pulleys, different stack graduations/brands), so pooling
/// those numbers makes per-exercise progress meaningless. Free weights (barbell/dumbbell/
/// kettlebell) are the same load anywhere, so their history IS comparable across gyms and
/// should NOT be fragmented by gym.
///
/// Each exercise gets a DEFAULT progress scope decided purely from its `equipment` string
/// (no LLM): `perGym` for machines/cables/etc., `combined` for free weights + everything else.
/// The user can override per exercise; this only decides the default chart/PR scope and which
/// history feeds the live weight suggestion + PR-celebration during a workout.
library;

enum GymProgressScope { perGym, combined }

/// Substrings marking gear whose effective load varies by gym/machine.
/// Matched case-insensitively against the equipment string (and, as a fallback, the name).
const List<String> _perGymKeywords = <String>[
  'machine',
  'cable',
  'smith',
  'pulldown',
  'pull-down',
  'pec deck',
  'pec fly',
  'hack squat',
  'hammer strength',
  'iso-lateral',
  'iso lateral',
  'plate-loaded',
  'plate loaded',
  'selectorized',
  'crossover',
  'leg press',
  'leg extension',
  'leg curl',
  'lat pull',
];

/// Tighter name-only hints used when the equipment string is blank/unknown.
const List<String> _perGymNameHints = <String>[
  'cable',
  'machine',
  'pulldown',
  'pull-down',
  'pec deck',
  'pec fly',
  'leg press',
  'leg extension',
  'leg curl',
  'smith machine',
  'hack squat',
  'lat pulldown',
];

/// Returns the default [GymProgressScope] for an exercise.
///
/// Conservative: an unknown/blank equipment with no machine/cable hint in the name defaults to
/// [GymProgressScope.combined] so a genuinely-comparable lift is never fragmented by gym.
GymProgressScope defaultGymProgressScope(String? equipment, {String? exerciseName}) {
  final eq = (equipment ?? '').trim().toLowerCase();
  if (eq.isNotEmpty && _perGymKeywords.any(eq.contains)) {
    return GymProgressScope.perGym;
  }
  if (eq.isEmpty) {
    final name = (exerciseName ?? '').trim().toLowerCase();
    if (name.isNotEmpty && _perGymNameHints.any(name.contains)) {
      return GymProgressScope.perGym;
    }
  }
  return GymProgressScope.combined;
}

/// True when this exercise's progress should default to per-gym segmentation.
bool isPerGymExercise(String? equipment, {String? exerciseName}) =>
    defaultGymProgressScope(equipment, exerciseName: exerciseName) == GymProgressScope.perGym;
