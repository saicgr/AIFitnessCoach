// Workout templates for each split type.
//
// Ported from backend/services/split_descriptions.py.
// Defines muscle group targets, exercise counts, and ordering
// for rule-based offline workout generation.

/// A single muscle group slot within a workout template.
class MuscleSlot {
  final String muscle;
  final int count;
  final bool compoundFirst;

  const MuscleSlot({
    required this.muscle,
    required this.count,
    this.compoundFirst = false,
  });
}

/// Template for a workout split type.
class WorkoutTemplate {
  final String splitType;
  final String displayName;
  final List<MuscleSlot> slots;

  const WorkoutTemplate({
    required this.splitType,
    required this.displayName,
    required this.slots,
  });

  int get totalExercises => slots.fold(0, (sum, s) => sum + s.count);
}

/// All workout templates keyed by split type.
///
/// Each template defines the muscle groups to target, how many exercises
/// per group, and whether compounds should come first.
const Map<String, WorkoutTemplate> workoutTemplates = {
  // === PUSH ===
  'push': WorkoutTemplate(
    splitType: 'push',
    displayName: 'Push',
    slots: [
      MuscleSlot(muscle: 'chest', count: 3, compoundFirst: true),
      MuscleSlot(muscle: 'shoulders', count: 2),
      MuscleSlot(muscle: 'triceps', count: 2),
    ],
  ),

  // === PULL ===
  'pull': WorkoutTemplate(
    splitType: 'pull',
    displayName: 'Pull',
    slots: [
      MuscleSlot(muscle: 'back', count: 3, compoundFirst: true),
      MuscleSlot(muscle: 'biceps', count: 2),
      MuscleSlot(muscle: 'forearms', count: 1),
    ],
  ),

  // === LEGS ===
  'legs': WorkoutTemplate(
    splitType: 'legs',
    displayName: 'Legs',
    slots: [
      MuscleSlot(muscle: 'quads', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'hamstrings', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'glutes', count: 1),
      MuscleSlot(muscle: 'calves', count: 1),
    ],
  ),

  // === UPPER ===
  'upper': WorkoutTemplate(
    splitType: 'upper',
    displayName: 'Upper Body',
    slots: [
      MuscleSlot(muscle: 'chest', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'back', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'shoulders', count: 1),
      MuscleSlot(muscle: 'biceps', count: 1),
      MuscleSlot(muscle: 'triceps', count: 1),
    ],
  ),

  // === LOWER ===
  'lower': WorkoutTemplate(
    splitType: 'lower',
    displayName: 'Lower Body',
    slots: [
      MuscleSlot(muscle: 'quads', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'hamstrings', count: 2, compoundFirst: true),
      MuscleSlot(muscle: 'glutes', count: 1),
      MuscleSlot(muscle: 'calves', count: 1),
    ],
  ),

  // === FULL BODY ===
  'full_body': WorkoutTemplate(
    splitType: 'full_body',
    displayName: 'Full Body',
    slots: [
      MuscleSlot(muscle: 'chest', count: 1, compoundFirst: true),
      MuscleSlot(muscle: 'back', count: 1, compoundFirst: true),
      MuscleSlot(muscle: 'shoulders', count: 1),
      MuscleSlot(muscle: 'quads', count: 1, compoundFirst: true),
      MuscleSlot(muscle: 'hamstrings', count: 1),
      MuscleSlot(muscle: 'biceps', count: 1),
      MuscleSlot(muscle: 'triceps', count: 1),
    ],
  ),

  // === CHEST + BACK (Arnold Split Day 1) ===
  'chest_back': WorkoutTemplate(
    splitType: 'chest_back',
    displayName: 'Chest & Back',
    slots: [
      MuscleSlot(muscle: 'chest', count: 3, compoundFirst: true),
      MuscleSlot(muscle: 'back', count: 3, compoundFirst: true),
    ],
  ),

  // === SHOULDERS + ARMS (Arnold Split Day 2) ===
  'shoulders_arms': WorkoutTemplate(
    splitType: 'shoulders_arms',
    displayName: 'Shoulders & Arms',
    slots: [
      MuscleSlot(muscle: 'shoulders', count: 3, compoundFirst: true),
      MuscleSlot(muscle: 'biceps', count: 2),
      MuscleSlot(muscle: 'triceps', count: 2),
    ],
  ),
};

/// Muscle groups that are considered "target muscle" synonyms.
/// Used to match exercises whose targetMuscle may differ from the slot name.
const Map<String, List<String>> muscleAliases = {
  'chest': ['chest', 'pectorals', 'pecs'],
  'back': ['back', 'lats', 'upper back', 'middle back', 'traps', 'rhomboids'],
  'shoulders': ['shoulders', 'delts', 'anterior delts', 'lateral delts', 'rear delts'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'forearms': ['forearms', 'grip'],
  'quads': ['quads', 'quadriceps'],
  'hamstrings': ['hamstrings'],
  'glutes': ['glutes'],
  'calves': ['calves', 'gastrocnemius', 'soleus'],
  'abs': ['abs', 'abdominals', 'core'],
};

/// Get the template for a given split type.
/// Falls back to full_body if the split type is unknown.
WorkoutTemplate getTemplate(String splitType) {
  return workoutTemplates[splitType.toLowerCase()] ??
      workoutTemplates['full_body']!;
}

/// Get a human-readable workout name from split type and date.
String workoutNameFromSplit(String splitType, String scheduledDate) {
  final template = getTemplate(splitType);
  return '${template.displayName} Workout';
}
