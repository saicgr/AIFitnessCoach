/// Movement pattern categories for exercise diversity.
///
/// Ensures workouts cover fundamental movement patterns for balanced
/// training stimulus and injury prevention.
enum MovementPattern {
  squat,
  hinge,
  pushHorizontal,
  pushVertical,
  pullHorizontal,
  pullVertical,
  carry,
}

/// Classify an exercise into a movement pattern based on its name.
///
/// Returns null if the exercise doesn't match a known pattern.
MovementPattern? classifyExercise(String exerciseName) {
  final name = exerciseName.toLowerCase();

  // Squat patterns
  if (name.contains('squat') || name.contains('leg press') ||
      name.contains('lunge') || name.contains('step up') ||
      name.contains('step-up') || name.contains('split squat') ||
      name.contains('pistol') || name.contains('wall sit') ||
      name.contains('hack squat') || name.contains('sissy squat') ||
      name.contains('goblet')) {
    return MovementPattern.squat;
  }

  // Hinge patterns
  if (name.contains('deadlift') || name.contains('rdl') ||
      name.contains('romanian') || name.contains('hip thrust') ||
      name.contains('good morning') || name.contains('glute bridge') ||
      name.contains('kettlebell swing') || name.contains('kb swing') ||
      name.contains('hyperextension') || name.contains('back extension') ||
      name.contains('pull through') || name.contains('hip hinge')) {
    return MovementPattern.hinge;
  }

  // Push vertical
  if (name.contains('overhead press') || name.contains('ohp') ||
      name.contains('military press') || name.contains('push press') ||
      name.contains('shoulder press') || name.contains('arnold press') ||
      name.contains('pike push') || name.contains('handstand')) {
    return MovementPattern.pushVertical;
  }

  // Push horizontal
  if (name.contains('bench press') || name.contains('push up') ||
      name.contains('push-up') || name.contains('pushup') ||
      name.contains('dip') || name.contains('chest press') ||
      name.contains('floor press') || name.contains('incline press') ||
      name.contains('decline press') || name.contains('fly') ||
      name.contains('flye') || name.contains('pec deck')) {
    return MovementPattern.pushHorizontal;
  }

  // Pull vertical
  if (name.contains('pull up') || name.contains('pull-up') ||
      name.contains('pullup') || name.contains('chin up') ||
      name.contains('chin-up') || name.contains('chinup') ||
      name.contains('lat pulldown') || name.contains('lat pull')) {
    return MovementPattern.pullVertical;
  }

  // Pull horizontal
  if (name.contains('row') || name.contains('face pull') ||
      name.contains('rear delt') || name.contains('reverse fly') ||
      name.contains('cable pull') || name.contains('inverted row') ||
      name.contains('pendlay') || name.contains('t-bar')) {
    return MovementPattern.pullHorizontal;
  }

  // Carry patterns
  if (name.contains('carry') || name.contains('walk') ||
      name.contains('farmer') || name.contains('suitcase')) {
    return MovementPattern.carry;
  }

  return null;
}

/// Get the minimum required number of distinct movement patterns
/// for a given workout duration.
int requiredPatternCount(int durationMinutes) {
  if (durationMinutes <= 5) return 2;
  if (durationMinutes <= 10) return 3;
  if (durationMinutes <= 15) return 4;
  if (durationMinutes <= 20) return 5;
  return 6; // 25-30 min
}

/// Check if a list of exercises covers enough movement patterns.
///
/// Returns the set of covered patterns.
Set<MovementPattern> getCoveredPatterns(List<String> exerciseNames) {
  final patterns = <MovementPattern>{};
  for (final name in exerciseNames) {
    final pattern = classifyExercise(name);
    if (pattern != null) {
      patterns.add(pattern);
    }
  }
  return patterns;
}

/// Find which movement patterns are missing from the current selection.
Set<MovementPattern> getMissingPatterns(
  List<String> exerciseNames,
  int durationMinutes,
) {
  final covered = getCoveredPatterns(exerciseNames);
  final required = requiredPatternCount(durationMinutes);

  if (covered.length >= required) return {};

  // Priority order of patterns to fill
  const priority = [
    MovementPattern.squat,
    MovementPattern.hinge,
    MovementPattern.pushHorizontal,
    MovementPattern.pullHorizontal,
    MovementPattern.pushVertical,
    MovementPattern.pullVertical,
    MovementPattern.carry,
  ];

  final missing = <MovementPattern>{};
  for (final p in priority) {
    if (!covered.contains(p)) {
      missing.add(p);
      if (covered.length + missing.length >= required) break;
    }
  }
  return missing;
}

/// Get the target muscle group most associated with a movement pattern.
///
/// Used to find replacement exercises when a pattern is missing.
String patternToMuscle(MovementPattern pattern) {
  switch (pattern) {
    case MovementPattern.squat: return 'quads';
    case MovementPattern.hinge: return 'hamstrings';
    case MovementPattern.pushHorizontal: return 'chest';
    case MovementPattern.pushVertical: return 'shoulders';
    case MovementPattern.pullHorizontal: return 'back';
    case MovementPattern.pullVertical: return 'back';
    case MovementPattern.carry: return 'full_body';
  }
}
