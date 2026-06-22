import 'dart:math' as math;

/// Curated, **media-verified** preview exercises.
///
/// Each entry's [id] is the real `exercise_library` UUID. Its illustration is
/// baked at `assets/preview_exercises/<id>.jpg` (instant, offline) and the same
/// id resolves the full illustration + vertical demo video by `?exercise_id=`.
/// Every one of these was visually vetted against its S3 illustration — no
/// blind name-matching, so the plan preview never shows a wrong movement.
class _PEx {
  final String name; // display label
  final String id; // exercise_library UUID (image + video key)
  final String category; // chest/back/legs/shoulders/biceps/triceps/core/cardio
  final String muscle;
  const _PEx(this.name, this.id, this.category, this.muscle);

  static const _compoundKw = [
    'Squat',
    'Deadlift',
    'Bench',
    'Press',
    'Row',
    'Pulldown',
    'Dip',
    'Pull',
    'Lunge',
    'Thruster',
  ];
  bool get _isCompound => _compoundKw.any(name.contains);

  /// Steady-state machines hold a duration; explosive moves use timed rounds.
  bool get _isSteadyCardio =>
      name == 'Treadmill Run' || name == 'Elliptical' || name == 'Rowing';

  String setsRepsFor(String goal) {
    if (category == 'cardio') return _isSteadyCardio ? '15 min' : '45s x 3';
    if (category == 'core') return '3 x 15';
    if (_isCompound) return goal == 'increase_strength' ? '5 x 5' : '4 x 8';
    return '3 x 12';
  }
}

const List<_PEx> _catalog = [
  _PEx(
    'Barbell Bench Press',
    'c0c3a2ea-a32a-4009-ba2a-f7e525efcd0a',
    'chest',
    'Chest',
  ),
  _PEx(
    'Dumbbell Flyes',
    '46d54630-54c2-4931-b9be-cf98f674a32c',
    'chest',
    'Chest',
  ),
  _PEx('Chest Dips', 'c7291dff-122b-4ffc-a328-83afcf17e5c4', 'chest', 'Chest'),
  _PEx(
    'Cable Crossovers',
    '2d5e8e30-c95f-4374-b028-1cfab5ad145b',
    'chest',
    'Chest',
  ),
  _PEx('Push-Ups', 'df96c033-2fca-4ea7-9b53-1f2032b37193', 'chest', 'Chest'),
  _PEx('Lat Pulldowns', '6b830263-650c-4fe6-890f-9b1054de5aa5', 'back', 'Lats'),
  _PEx(
    'Seated Cable Rows',
    'e84a6b7e-ae65-44e1-bfa2-acba2306c08a',
    'back',
    'Back',
  ),
  _PEx(
    'Face Pulls',
    '3f0ab7b4-5a5e-49d3-91df-ac3256dedb2a',
    'back',
    'Rear Delts',
  ),
  _PEx('Deadlift', '690e3098-8242-443e-a23d-d054c0d5b8b5', 'back', 'Back'),
  _PEx('Dumbbell Rows', 'f3eee79f-f7c3-4157-8be0-070976687397', 'back', 'Back'),
  _PEx('Back Squats', '8ded0c32-26e2-40fd-b691-8b24f2f25497', 'legs', 'Quads'),
  _PEx('Front Squats', 'c311314f-fbc3-47e6-ba3d-9a161738c429', 'legs', 'Quads'),
  _PEx('Leg Press', '2678f51c-be2d-4b52-82bd-b86bdcb99ecf', 'legs', 'Quads'),
  _PEx(
    'Romanian Deadlift',
    '6e264908-0c60-43b1-b174-faece9537f59',
    'legs',
    'Hamstrings',
  ),
  _PEx(
    'Walking Lunges',
    '13960b56-5a88-4b9d-a14c-86b372a81d9c',
    'legs',
    'Quads',
  ),
  _PEx(
    'Leg Extensions',
    '1e9c7040-1fe2-4edc-84e0-ae3ad61283c1',
    'legs',
    'Quads',
  ),
  _PEx(
    'Leg Curls',
    '17704a26-6918-4233-8185-7bab7461e602',
    'legs',
    'Hamstrings',
  ),
  _PEx('Calf Raises', 'c88303b6-f900-481b-a769-bee0642599ad', 'legs', 'Calves'),
  _PEx(
    'Bulgarian Split Squats',
    '184ebc96-f304-416c-8506-95cc1d8d307f',
    'legs',
    'Quads',
  ),
  _PEx(
    'Overhead Press',
    '548be319-47a3-4b7f-830b-e64cbf0ed604',
    'shoulders',
    'Shoulders',
  ),
  _PEx(
    'Dumbbell Shoulder Press',
    '6e8e4f82-12d5-46f0-b929-9657ebd7e1e4',
    'shoulders',
    'Shoulders',
  ),
  _PEx(
    'Lateral Raises',
    'a06effca-ef7b-4c50-993f-795e0e8fb00a',
    'shoulders',
    'Side Delts',
  ),
  _PEx(
    'Front Raises',
    '568c24a1-97ec-4e52-b0a7-0fbd09f1496c',
    'shoulders',
    'Front Delts',
  ),
  _PEx(
    'Rear Delt Flyes',
    '46b3ff87-b820-49e5-b7b5-0b6f9a2503b0',
    'shoulders',
    'Rear Delts',
  ),
  _PEx(
    'Arnold Press',
    '45a02e57-47ee-4c27-924f-21df1575c5cb',
    'shoulders',
    'Shoulders',
  ),
  _PEx(
    'Barbell Curls',
    '0256738b-b6eb-46c5-b7b4-88a11d51b5cd',
    'biceps',
    'Biceps',
  ),
  _PEx(
    'Dumbbell Curls',
    '49bb960f-1486-46ea-82ae-c96e99d443c4',
    'biceps',
    'Biceps',
  ),
  _PEx(
    'Hammer Curls',
    '468e9fee-63fc-495e-b28e-b8803a4f428d',
    'biceps',
    'Biceps',
  ),
  _PEx(
    'Preacher Curls',
    '6a311f23-7dfe-4e7a-ab60-ff4f02c29b3f',
    'biceps',
    'Biceps',
  ),
  _PEx(
    'Tricep Pushdowns',
    '5efc82a2-11a6-49e3-bf44-4f882cd88668',
    'triceps',
    'Triceps',
  ),
  _PEx('Plank', '224d012e-6c66-4b03-876c-8ab461fce31b', 'core', 'Core'),
  _PEx('Crunches', '0d8fa338-e996-4c68-bf5d-3f0c9d91fb66', 'core', 'Abs'),
  _PEx(
    'Russian Twists',
    'c02b6692-b563-447e-ad76-e961db3a22fe',
    'core',
    'Obliques',
  ),
  _PEx(
    'Leg Raises',
    '085b711d-4268-445b-af27-de5d1be3b1f7',
    'core',
    'Lower Abs',
  ),
  _PEx(
    'Hanging Leg Raises',
    '6934878b-bcec-48dd-a711-1eddd7b203eb',
    'core',
    'Abs',
  ),
  _PEx('Dead Bug', '6bb66fde-e0ac-4792-86e0-1c261ae8fe45', 'core', 'Core'),
  _PEx(
    'Mountain Climbers',
    '3284b7dd-367d-471e-a1ff-ec34fcb633f9',
    'core',
    'Core',
  ),
  _PEx(
    'Burpees',
    'c4d421fe-3e28-471b-8a95-293f0733d161',
    'cardio',
    'Full Body',
  ),
  _PEx(
    'Jumping Jacks',
    'fa1778bc-774d-4a50-b770-d77d03acbd4c',
    'cardio',
    'Full Body',
  ),
  _PEx(
    'High Knees',
    'd9e75684-4be9-4071-9f40-3eec7c9fa7f4',
    'cardio',
    'Cardio',
  ),
  _PEx(
    'Kettlebell Swings',
    '4044ee27-2cb7-4c21-9b60-91c14d0731d2',
    'cardio',
    'Full Body',
  ),
  _PEx('Box Jumps', 'e6e076cb-deea-487d-ac20-d827ab3ced9e', 'cardio', 'Legs'),
  _PEx(
    'Thrusters',
    '06ad8449-8a47-4ced-9e97-784775e28cf9',
    'cardio',
    'Full Body',
  ),
  _PEx(
    'Treadmill Run',
    '4d1a878c-7f98-4b18-9615-c2d852563419',
    'cardio',
    'Cardio',
  ),
  _PEx(
    'Elliptical',
    '0350f1da-0008-4a34-ade0-ce7204a3405c',
    'cardio',
    'Cardio',
  ),
  _PEx('Rowing', '35094e6a-e38b-4f3b-a835-62c1b905ed45', 'cardio', 'Full Body'),
];

final Map<String, List<_PEx>> _byCat = () {
  final m = <String, List<_PEx>>{};
  for (final e in _catalog) {
    (m[e.category] ??= <_PEx>[]).add(e);
  }
  return m;
}();

/// The baked-asset path for a catalog exercise id (or null if not baked).
String? previewAssetForId(String? id) {
  if (id == null) return null;
  final ok = _catalog.any((e) => e.id == id);
  return ok ? 'assets/preview_exercises/$id.jpg' : null;
}

/// Muscle-group buckets a workout-type id maps to.
List<String> _catsForType(String typeId) {
  final t = typeId.toLowerCase();
  bool has(String s) => t.contains(s);
  if (has('push')) return ['chest', 'shoulders', 'triceps'];
  if (has('pull')) return ['back', 'biceps'];
  if (has('upper')) return ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
  if (has('lower')) return ['legs', 'core'];
  if (has('leg')) return ['legs', 'core'];
  if (has('arm')) return ['biceps', 'triceps'];
  if (has('chest')) return ['chest'];
  if (has('back')) return ['back'];
  if (has('shoulder')) return ['shoulders'];
  if (has('core') || has('ab')) return ['core'];
  if (has('full')) return ['chest', 'back', 'legs', 'shoulders'];
  if (has('strength')) return ['legs', 'back', 'chest', 'shoulders'];
  // Cardio / conditioning / recovery / mobility families.
  if (has('hiit') ||
      has('cardio') ||
      has('endurance') ||
      has('interval') ||
      has('tempo') ||
      has('run') ||
      has('cross') ||
      has('conditioning') ||
      has('active') ||
      has('recovery') ||
      has('flex') ||
      has('mobility') ||
      has('long')) {
    return ['cardio', 'core'];
  }
  return ['chest', 'back', 'legs'];
}

bool _isCardioType(String typeId) {
  final cats = _catsForType(typeId);
  return cats.length == 2 && cats.first == 'cardio';
}

/// Deterministically pick curated exercises for a workout-type id. Returns the
/// same `{name, id, muscle, setsReps}` shape the preview day-card consumes, so
/// the rows render the baked illustration + tappable video by id.
List<Map<String, dynamic>> curatedExercisesForType(
  String typeId, {
  required int seed,
  String goal = 'build_muscle',
}) {
  final cats = _catsForType(typeId);
  final count = _isCardioType(typeId) ? 3 : 5;
  final rng = math.Random(seed * 31 + typeId.hashCode);

  // A shuffled queue per category so picks vary per day yet stay stable.
  final queues = <String, List<_PEx>>{
    for (final c in cats)
      c: (List<_PEx>.from(_byCat[c] ?? const <_PEx>[])..shuffle(rng)),
  };

  final picks = <_PEx>[];
  final used = <String>{};
  var ci = 0;
  var guard = 0;
  while (picks.length < count &&
      queues.values.any((q) => q.isNotEmpty) &&
      guard++ < 200) {
    final c = cats[ci++ % cats.length];
    final q = queues[c];
    if (q == null || q.isEmpty) continue;
    final e = q.removeLast();
    if (used.add(e.id)) picks.add(e);
  }

  return [
    for (final e in picks)
      {
        'name': e.name,
        'id': e.id,
        'muscle': e.muscle,
        'setsReps': e.setsRepsFor(goal),
      },
  ];
}
