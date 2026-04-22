// Shared step-by-step setup instructions + form tips for an exercise.
//
// Extracted from `ExerciseInstructionsScreen` so other surfaces (the Easy
// tier's Instructions sheet, AI coach replies, exercise-card sheets) can
// reuse the same pattern-matched copy without instantiating the full
// video-player screen.
//
// Lookup is name-based. Everything is pure — no BuildContext, no Riverpod.

library;

/// Step-by-step setup instructions — "what to do first" for the exercise.
List<String> getSetupSteps(String exerciseName) {
  final name = exerciseName.toLowerCase();

  if (name.contains('bench') || name.contains('press')) {
    return [
      'Set up the bench at the appropriate angle (flat, incline, or decline).',
      'Grip the bar slightly wider than shoulder-width.',
      'Plant your feet firmly on the ground.',
      'Retract your shoulder blades and maintain a slight arch in your lower back.',
      'Unrack the weight and position it directly above your chest.',
    ];
  } else if (name.contains('squat')) {
    return [
      'Position the bar on your upper back (not your neck).',
      'Stand with feet shoulder-width apart, toes slightly pointed out.',
      'Brace your core before descending.',
      'Keep your knees tracking over your toes.',
      'Descend until thighs are at least parallel to the floor.',
    ];
  } else if (name.contains('deadlift')) {
    return [
      'Stand with feet hip-width apart, bar over mid-foot.',
      'Grip the bar just outside your legs.',
      'Keep your back flat and chest up.',
      'Take the slack out of the bar before pulling.',
      'Drive through your heels and push hips forward.',
    ];
  } else if (name.contains('row')) {
    return [
      'Hinge at the hips with a slight knee bend.',
      'Keep your back flat and core engaged.',
      'Grip the weight with arms extended.',
      'Pull the weight toward your lower chest/upper abs.',
      'Squeeze your shoulder blades together at the top.',
    ];
  } else if (name.contains('curl')) {
    return [
      'Stand with feet shoulder-width apart.',
      'Grip the weight with palms facing up.',
      'Keep your elbows close to your sides.',
      'Curl the weight toward your shoulders.',
      'Lower with control to full arm extension.',
    ];
  } else if (name.contains('pull') &&
      (name.contains('up') || name.contains('down'))) {
    return [
      'Grip the bar slightly wider than shoulder-width.',
      'Hang with arms fully extended.',
      'Engage your lats before pulling.',
      'Pull your elbows down and back.',
      'Lower with control to full arm extension.',
    ];
  } else if (name.contains('crossover') || name.contains('fly')) {
    return [
      'Stand between the cable stacks (or bench for flies) with a soft knee bend.',
      'Grab the handles with arms slightly bent — never locked.',
      'Step one foot forward for a stable base, chest up.',
      'Bring the handles together in front of your chest in a sweeping arc.',
      'Squeeze your chest at the midpoint, then reverse with control.',
    ];
  } else if (name.contains('lunge')) {
    return [
      'Stand tall with feet hip-width apart, core braced.',
      'Step forward (or back) into a long lunge stance.',
      'Lower until both knees form ~90° angles — rear knee just off the floor.',
      'Keep your front knee tracking over your toes, not collapsing inward.',
      'Drive through the front heel to return to standing.',
    ];
  } else if (name.contains('extension') || name.contains('kickback')) {
    return [
      'Anchor your upper arm — pin elbow to your side or brace on a bench.',
      'Start with your forearm bent at ~90°.',
      'Extend the weight back until your arm is straight.',
      'Squeeze the triceps at full extension.',
      'Return slowly — control the negative.',
    ];
  }

  // Default generic instructions.
  return [
    'Set up your equipment and check your form in a mirror if available.',
    'Warm up with lighter weight first.',
    'Position yourself in the starting position.',
    'Focus on controlled movements throughout.',
    'Breathe consistently — exhale on exertion.',
  ];
}

/// Breathing cues — inhale / exhale pattern for this exercise. Pattern
/// matched by name so every surface renders the same cues.
List<String> getBreathingCues(String exerciseName) {
  final name = exerciseName.toLowerCase();

  if (name.contains('bench') || name.contains('press')) {
    return [
      'Inhale as the bar lowers — fill your chest and brace.',
      'Exhale as you drive the bar back up through lockout.',
      'Reset the breath between reps; never hold under full load for multiple reps.',
    ];
  } else if (name.contains('squat')) {
    return [
      'Take a big belly-breath before you descend and brace your core.',
      'Hold the brace through the bottom of the rep.',
      'Exhale forcefully on the drive up.',
    ];
  } else if (name.contains('deadlift')) {
    return [
      'Take a big breath into your belly at the top before setting up.',
      'Hold the brace throughout the pull — do not exhale mid-rep.',
      'Exhale at lockout, reset the breath before the next rep.',
    ];
  } else if (name.contains('row')) {
    return [
      'Inhale at the stretched position with arms extended.',
      'Exhale as you pull the weight in and squeeze the back.',
      'Inhale again on the controlled return.',
    ];
  } else if (name.contains('curl')) {
    return [
      'Inhale at the bottom with arms fully extended.',
      'Exhale as you curl the weight up.',
      'Inhale on the slow eccentric back down.',
    ];
  } else if (name.contains('pull') &&
      (name.contains('up') || name.contains('down'))) {
    return [
      'Inhale at the hang / top of the stretch.',
      'Exhale as you drive your elbows down and pull through.',
      'Inhale on the controlled return.',
    ];
  } else if (name.contains('crossover') || name.contains('fly')) {
    return [
      'Inhale on the way out as your chest stretches.',
      'Exhale as you bring the handles together and squeeze.',
      'Keep the breath smooth — never hold it for multiple reps.',
    ];
  } else if (name.contains('lunge')) {
    return [
      'Inhale as you step out and descend.',
      'Exhale as you drive through the front heel and stand.',
    ];
  } else if (name.contains('extension') || name.contains('kickback')) {
    return [
      'Inhale at the bent-elbow starting position.',
      'Exhale as you extend the weight back.',
      'Inhale on the controlled return.',
    ];
  } else if (name.contains('plank') || name.contains('hold')) {
    return [
      'Breathe steadily through your nose — short, shallow breaths are fine.',
      'Do not hold your breath; holding spikes blood pressure and shortens the hold.',
      'Exhale a little more forcefully to keep the core braced.',
    ];
  } else if (name.contains('cardio') ||
      name.contains('run') ||
      name.contains('bike') ||
      name.contains('row') ||
      name.contains('stair')) {
    return [
      'Nose-in, mouth-out when possible — it regulates pace.',
      'Match breathing to rhythm: 2 steps inhale, 2 steps exhale as a starting pattern.',
      'If you can talk in short sentences you are at a sustainable zone-2 effort.',
    ];
  }

  // Generic default: exhale on the hard part, inhale on the easy part.
  return [
    'Inhale during the eccentric (easier) half of the rep.',
    'Exhale during the concentric (harder) half — pushing, pulling, or lifting.',
    'Never hold your breath for multiple reps in a row.',
  ];
}

/// Form tips — the things to watch for while executing the rep.
List<String> getFormTips(String exerciseName) {
  final name = exerciseName.toLowerCase();

  if (name.contains('bench') || name.contains('press')) {
    return [
      'Keep your wrists straight and stacked over your elbows.',
      'Lower the bar to your mid-chest with control.',
      'Press through your chest, not just your arms.',
      'Maintain tension at the bottom — no bouncing.',
      'Keep your feet planted and avoid lifting your hips.',
    ];
  } else if (name.contains('squat')) {
    return [
      'Keep your weight in your heels and mid-foot.',
      'Go as deep as your mobility allows with good form.',
      "Don't let your knees cave inward.",
      'Stand up by driving your hips forward.',
      'Keep your core braced throughout the movement.',
    ];
  } else if (name.contains('deadlift')) {
    return [
      'Never round your lower back.',
      'Keep the bar close to your body throughout.',
      'Lock out by squeezing your glutes, not hyperextending.',
      "Lower with control — don't drop the weight.",
      'Reset your position between each rep.',
    ];
  } else if (name.contains('row')) {
    return [
      'Initiate the pull with your back, not your arms.',
      'Keep your core tight to protect your lower back.',
      'Avoid jerky movements — stay controlled.',
      'Focus on the muscle contraction at the top.',
      'Keep your neck neutral — look at the floor.',
    ];
  } else if (name.contains('curl')) {
    return [
      'Keep your upper arms stationary.',
      "Don't swing the weight or use your back.",
      'Squeeze at the top of the movement.',
      'Lower slowly for maximum tension.',
      "Don't fully lock out at the bottom to maintain tension.",
    ];
  } else if (name.contains('crossover') || name.contains('fly')) {
    return [
      'Keep a soft bend in the elbows the whole time.',
      'Imagine hugging a tree — lead with the chest, not the arms.',
      'Do not crash the handles together; stop at a controlled midpoint.',
      'Resist the stretch on the way back — that is where the work is.',
    ];
  }

  // Default generic tips.
  return [
    'Focus on mind-muscle connection.',
    'Control the weight through the full range of motion.',
    'Avoid using momentum — let the target muscle do the work.',
    'If form breaks down, reduce the weight.',
    'Take your time and prioritize quality over quantity.',
  ];
}
