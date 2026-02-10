/// Mapping from injury body parts to muscle groups that should be avoided.
///
/// Ported from backend/api/v1/workouts/utils.py INJURY_TO_AVOIDED_MUSCLES.
/// Used by the offline workout generator to exclude exercises that could
/// aggravate a user's injuries.
const Map<String, List<String>> injuryToAvoidedMuscles = {
  'shoulder': [
    'shoulders',
    'chest',
    'triceps',
    'delts',
    'anterior_delts',
    'lateral_delts',
    'rear_delts',
  ],
  'back': [
    'back',
    'lats',
    'lower_back',
    'traps',
    'rhomboids',
    'erector_spinae',
  ],
  'lower_back': [
    'lower_back',
    'back',
    'erector_spinae',
    'glutes',
    'hamstrings',
  ],
  'knee': [
    'quads',
    'hamstrings',
    'calves',
    'legs',
    'quadriceps',
    'glutes',
  ],
  'wrist': [
    'forearms',
    'biceps',
    'triceps',
    'grip',
  ],
  'ankle': [
    'calves',
    'legs',
    'tibialis',
    'soleus',
    'gastrocnemius',
  ],
  'hip': [
    'glutes',
    'hip_flexors',
    'legs',
    'quads',
    'hamstrings',
    'adductors',
    'abductors',
  ],
  'elbow': [
    'biceps',
    'triceps',
    'forearms',
    'brachialis',
  ],
  'neck': [
    'traps',
    'shoulders',
    'neck',
    'upper_back',
  ],
  'chest': [
    'chest',
    'pectorals',
    'shoulders',
    'triceps',
  ],
  'groin': [
    'adductors',
    'hip_flexors',
    'legs',
    'quads',
  ],
  'hamstring': [
    'hamstrings',
    'glutes',
    'legs',
  ],
  'quad': [
    'quads',
    'quadriceps',
    'legs',
    'knee',
  ],
  'calf': [
    'calves',
    'legs',
    'ankle',
  ],
  'rotator_cuff': [
    'shoulders',
    'chest',
    'delts',
    'rotator_cuff',
  ],
};

/// Expand a list of injury names into a flat set of muscle groups to avoid.
Set<String> expandInjuriesToMuscles(List<String> injuries) {
  final avoided = <String>{};
  for (final injury in injuries) {
    final key = injury.toLowerCase().replaceAll(' ', '_');
    final muscles = injuryToAvoidedMuscles[key];
    if (muscles != null) {
      avoided.addAll(muscles);
    }
  }
  return avoided;
}
