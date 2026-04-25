// Shared step-by-step setup instructions, breathing cues, and form tips for
// an exercise.
//
// Used by Easy tier instructions sheet, Advanced tier inline info card,
// foldable left pane, AI coach replies, and the in-app exercise card sheet.
//
// Lookup is name + equipment based. Everything is pure — no BuildContext, no
// Riverpod. Hoisted classifiers (`_classify`) so all three functions agree
// on what counts as "bodyweight", "plyometric", "machine", "cardio", etc.

library;

/// Split a server-provided `exercise.instructions` blob into discrete steps.
///
/// Instructions from the backend are often a single paragraph. Splitting on
/// sentence punctuation gives the rendered list a real step-by-step feel.
/// If the splitter can't produce at least two parts, return the original
/// text as a single-element list so the caller can still show it.
List<String> splitInstructionsIntoSteps(String text) {
  final parts = text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return parts.length >= 2 ? parts : [text];
}

/// Whether `exercise.instructions` is substantial enough to prefer over the
/// pattern-matched defaults. Threshold mirrors the Easy tier's heuristic.
bool serverInstructionsAreSubstantial(String? text) {
  if (text == null) return false;
  return text.trim().length > 40;
}

/// Tags derived from `name` + `equipment` so all three lookup functions
/// agree on how to route an exercise.
class _ExClass {
  final String name;
  final String equip;
  final bool bodyweight;
  final bool plyo;
  final bool machine;
  final bool cable;
  final bool dumbbell;
  final bool kettlebell;
  final bool resistanceBand;
  final bool cardio;
  final bool stretch;
  final bool olympic;
  final bool isometric;

  const _ExClass({
    required this.name,
    required this.equip,
    required this.bodyweight,
    required this.plyo,
    required this.machine,
    required this.cable,
    required this.dumbbell,
    required this.kettlebell,
    required this.resistanceBand,
    required this.cardio,
    required this.stretch,
    required this.olympic,
    required this.isometric,
  });
}

_ExClass _classify(String exerciseName, String? equipment) {
  final name = exerciseName.toLowerCase();
  final equip = (equipment ?? '').toLowerCase();

  // --- Bodyweight detection ---------------------------------------------
  // Treat empty string as "unknown" rather than letting `''.contains('body')`
  // false-match.
  final equipSignalsBodyweight = equip.isNotEmpty &&
      (equip.contains('body') ||
          equip == 'none' ||
          equip == 'self' ||
          equip == 'no equipment');
  final nameSignalsBodyweight = name.contains('air squat') ||
      name.contains('bodyweight') ||
      name.contains('body weight') ||
      name.contains('body-weight') ||
      name.contains('kabaddi') ||
      name.contains('pistol') ||
      name.contains('sissy') ||
      name.contains('cossack') ||
      // Push-up family: every variant is bodyweight
      name.contains('push-up') ||
      name.contains('pushup') ||
      name.contains('push up') ||
      // Calisthenic skills
      name.contains('handstand') ||
      name.contains('headstand') ||
      name.contains('l-sit') ||
      name.contains('l sit') ||
      name.contains('planche') ||
      name.contains('lever') ||
      name.contains('muscle-up') ||
      name.contains('muscle up') ||
      // Pull-ups, chin-ups, dips, rope climbs are bodyweight even though
      // they need an apparatus
      name.contains('pull-up') ||
      name.contains('pullup') ||
      name.contains('pull up') ||
      name.contains('chin-up') ||
      name.contains('chinup') ||
      name.contains('chin up') ||
      // Plank/abs/holds
      name.contains('plank') ||
      name.contains('hollow body') ||
      name.contains('dead bug') ||
      name.contains('bird dog') ||
      name.contains('bird-dog') ||
      // Burpees, mountain climbers, bear crawls
      name.contains('burpee') ||
      name.contains('mountain climber') ||
      name.contains('bear crawl') ||
      name.contains('crab walk') ||
      // Inverted/TRX rows are bodyweight
      name.contains('inverted row') ||
      name.contains('trx row') ||
      name.contains('australian pull') ||
      // Crunch/sit-up family
      name.contains('crunch') ||
      name.contains('sit-up') ||
      name.contains('situp') ||
      name.contains('sit up') ||
      name.contains('v-up') ||
      name.contains('vup') ||
      // Bridges/glute bridges (without weight)
      (name.contains('bridge') &&
          !name.contains('barbell') &&
          !name.contains('weighted')) ||
      // Frog/skater/broad/box plyos with no load
      name.contains('skater') ||
      name.contains('frog jump') ||
      name.contains('broad jump') ||
      name.contains('depth jump') ||
      name.contains('tuck jump') ||
      name.contains('box jump') ||
      name.contains('bound');
  final bodyweight = equipSignalsBodyweight || nameSignalsBodyweight;

  // --- Plyometric detection ---------------------------------------------
  final plyo = name.contains('jump') ||
      name.contains('jumping') ||
      name.contains('plyo') ||
      name.contains('plyometric') ||
      name.contains('hop') ||
      name.contains('bound') ||
      name.contains('skater') ||
      name.contains('clap push') ||
      name.contains('explosive');

  // --- Machine vs barbell vs cable -------------------------------------
  final machine = equip.contains('machine') ||
      name.contains('leg press') ||
      name.contains('hack squat') ||
      name.contains('hack-squat') ||
      name.contains('calf press') ||
      name.contains('chest press machine') ||
      name.contains('shoulder press machine') ||
      name.contains('seated press') ||
      name.contains('pec deck') ||
      name.contains('pec-deck') ||
      name.contains('leg extension') ||
      name.contains('leg curl') ||
      name.contains('smith machine') ||
      name.contains('hammer strength') ||
      name.contains('glute drive') ||
      name.contains('ab crunch machine') ||
      name.contains('abdominal machine') ||
      name.contains('back extension machine');
  final cable = equip.contains('cable') ||
      name.contains('cable') ||
      name.contains('crossover') ||
      name.contains('lat pulldown') ||
      name.contains('lat-pulldown') ||
      name.contains('seated row') ||
      name.contains('face pull') ||
      name.contains('tricep pushdown') ||
      name.contains('woodchop');
  final dumbbell = equip == 'dumbbell' ||
      equip.contains('dumbbell') ||
      name.startsWith('db ') ||
      name.contains('dumbbell');
  final kettlebell = equip.contains('kettlebell') ||
      equip.contains('kb') ||
      name.contains('kettlebell') ||
      name.startsWith('kb ');
  final resistanceBand = equip.contains('band') ||
      equip.contains('resistance band') ||
      name.contains('resistance band') ||
      (name.contains('band') && !name.contains('headband'));

  // --- Cardio / conditioning -------------------------------------------
  final cardio = name.contains('cardio') ||
      name.contains('running') ||
      name == 'run' ||
      name.startsWith('run ') ||
      name.endsWith(' run') ||
      name.contains('jog') ||
      name.contains('sprint') ||
      name.contains('cycling') ||
      name.contains('cycle ') ||
      name.contains('biking') ||
      name.contains(' bike') ||
      name.contains('elliptical') ||
      name.contains('stair') ||
      name.contains('stepper') ||
      name.contains('rowing machine') ||
      name.contains('rower') ||
      name.contains('concept2') ||
      name.contains('jump rope') ||
      name.contains('jumprope') ||
      name.contains('jumping rope') ||
      name.contains('battle rope') ||
      name.contains('sled push') ||
      name.contains('sled pull') ||
      name.contains('hiit') ||
      name.contains('treadmill') ||
      name.contains('swimming');

  // --- Stretch / mobility / yoga ---------------------------------------
  final stretch = name.contains('stretch') ||
      name.contains('mobility') ||
      name.contains('foam roll') ||
      name.contains('lacrosse ball') ||
      name.contains('downward dog') ||
      name.contains('child\'s pose') ||
      name.contains('childs pose') ||
      name.contains("warrior") ||
      name.contains('cobra pose') ||
      name.contains('pigeon') ||
      name.contains('cat-cow') ||
      name.contains('cat cow') ||
      name.contains('worlds greatest stretch') ||
      name.contains("world's greatest");

  // --- Olympic / strongman ---------------------------------------------
  final olympic = name.contains('snatch') ||
      (name.contains('clean') &&
          (name.contains('jerk') ||
              name.contains('clean &') ||
              name.contains('hang clean') ||
              name.contains('power clean'))) ||
      name.contains('jerk') ||
      name.contains('atlas stone') ||
      name.contains('farmer\'s carry') ||
      name.contains('farmers carry') ||
      name.contains('farmer carry') ||
      name.contains('yoke') ||
      name.contains('tire flip') ||
      name.contains('log press') ||
      name.contains('turkish get-up') ||
      name.contains('turkish getup');

  // --- Static holds / isometrics ---------------------------------------
  final isometric = name.contains('plank') ||
      name.contains('wall sit') ||
      name.contains('dead hang') ||
      name.contains('l-sit') ||
      name.contains('l sit') ||
      name.contains('iron cross') ||
      name.contains('hold') ||
      name.contains('iso ');

  return _ExClass(
    name: name,
    equip: equip,
    bodyweight: bodyweight,
    plyo: plyo,
    machine: machine,
    cable: cable,
    dumbbell: dumbbell,
    kettlebell: kettlebell,
    resistanceBand: resistanceBand,
    cardio: cardio,
    stretch: stretch,
    olympic: olympic,
    isometric: isometric,
  );
}

/// True when the name has "press" but NOT in a barbell-bench-press sense.
/// "Leg press", "calf press", "hip press", "z press", "push press",
/// "landmine press", "shoulder press machine", etc. should NOT inherit
/// barbell-bench cues.
bool _isNonBenchPress(String name) {
  return name.contains('leg press') ||
      name.contains('calf press') ||
      name.contains('hip press') ||
      name.contains('z press') ||
      name.contains('z-press') ||
      name.contains('push press') ||
      name.contains('push-press') ||
      name.contains('landmine press') ||
      name.contains('shoulder press') ||
      name.contains('overhead press') ||
      name.contains('military press') ||
      name.contains('arnold press') ||
      name.contains('seated press') ||
      name.contains('pin press');
}

/// Step-by-step setup instructions — "what to do first" for the exercise.
///
/// Optional [equipment] lets us differentiate barbell-loaded variants from
/// bodyweight, plyometric, machine, cable, and cardio variants whose setup
/// is fundamentally different.
List<String> getSetupSteps(String exerciseName, {String? equipment}) {
  final c = _classify(exerciseName, equipment);
  final name = c.name;

  // -------- Olympic lifts (highest priority — heavy technique) --------
  if (c.olympic) {
    if (name.contains('snatch')) {
      return [
        'Set up over the bar with feet hip-width, bar over mid-foot.',
        'Take a wide (snatch) grip with the bar pulled tight to your hips.',
        'Brace, lock the lats, and start the pull from the floor with the chest up.',
        'Drive through the legs, then pull yourself UNDER the bar in one motion.',
        'Catch in a deep overhead squat with the bar locked out, then stand.',
      ];
    }
    if (name.contains('clean')) {
      return [
        'Set up over the bar with feet hip-width, bar over mid-foot.',
        'Take a clean grip (just outside the legs), tight back, chest up.',
        'Drive through the floor, then aggressively shrug and pull the bar high.',
        'Pull yourself under and rotate the elbows around to a front-rack.',
        'Catch in a front squat, stand up, and reset.',
      ];
    }
    if (name.contains('jerk')) {
      return [
        'Start with the bar in a solid front-rack position.',
        'Brace the core and dip slightly straight down (no forward lean).',
        'Drive vertically through the legs to launch the bar.',
        'Punch yourself under the bar — split or power stance.',
        'Stabilize overhead with locked elbows, then bring feet together.',
      ];
    }
    if (name.contains('turkish get-up') || name.contains('turkish getup')) {
      return [
        'Start lying on your back, weight pressed up over the working shoulder.',
        'Bend the same-side knee; opposite arm and leg extend out at 45°.',
        'Roll up onto the forearm, then the hand — eyes on the weight.',
        'Bridge your hips and sweep your back leg through to a half-kneeling stance.',
        'Stand up tall, then reverse every step back to the floor with control.',
      ];
    }
    if (name.contains('farmer')) {
      return [
        'Stand between the implements (handles, dumbbells, or trap bar).',
        'Hinge at the hips, grip with neutral wrists, brace the core.',
        'Stand up tall — chest proud, shoulders pulled down and back.',
        'Take short, controlled steps with a neutral spine.',
        'Set the load down with a controlled hinge, never a drop.',
      ];
    }
  }

  // -------- Cardio / conditioning -------------------------------------
  if (c.cardio) {
    if (name.contains('jump rope') ||
        name.contains('jumping rope') ||
        name.contains('jumprope')) {
      return [
        'Pick a rope — handles should reach armpit height when you stand on the middle.',
        'Elbows close to the ribs, wrists do the work — not the shoulders.',
        'Stay on the balls of your feet, jumping just 1–2 inches off the floor.',
        'Keep a soft knee bend; land quietly to spare your joints.',
        'Build rhythm before you chase speed.',
      ];
    }
    if (name.contains('rowing') ||
        name.contains('rower') ||
        name.contains('concept2')) {
      return [
        'Sit tall, strap your feet in so the strap crosses the ball of your foot.',
        'Catch position: shins vertical, arms extended, shoulders relaxed.',
        'Drive: legs first, then hinge open, then pull the handle to your sternum.',
        'Recovery: arms away, hinge forward, slide knees up — slow is smooth.',
        'Aim for a 1:2 drive-to-recovery ratio for steady-state work.',
      ];
    }
    if (name.contains('treadmill') ||
        name.contains('running') ||
        name.contains('jog') ||
        name.contains('sprint') ||
        name == 'run' ||
        name.startsWith('run ')) {
      return [
        'Warm up with 3–5 minutes of brisk walking before picking up the pace.',
        'Run tall — head up, shoulders relaxed, slight forward lean from the ankles.',
        'Aim for a midfoot strike under your hips, not heel-striking out front.',
        'Keep your cadence around 170–180 steps per minute when possible.',
        'Cool down with 3–5 minutes of easy walking, then stretch.',
      ];
    }
    return [
      'Warm up first — get your heart rate elevated before the working sets.',
      'Pick a starting pace you can sustain conversationally.',
      'Maintain steady form throughout — no cheating with momentum.',
      'Breathe in a sustainable rhythm; do not hold your breath.',
      'Cool down for at least 3 minutes at low intensity.',
    ];
  }

  // -------- Stretch / mobility / yoga ---------------------------------
  if (c.stretch) {
    return [
      'Move into the position slowly — stop at the first point of mild tension.',
      'Hold without bouncing; static stretches respond to time, not force.',
      'Breathe into the stretch — inhale deeply, exhale and ease a touch deeper.',
      'Aim for 30–60 seconds per side; never push into sharp pain.',
      'Come out as deliberately as you went in.',
    ];
  }

  // -------- Bench / press FAMILY (with non-bench-press guard) ---------
  if (name.contains('bench') ||
      (name.contains('press') && !_isNonBenchPress(name))) {
    return [
      'Set up the bench at the appropriate angle (flat, incline, or decline).',
      'Grip the bar slightly wider than shoulder-width.',
      'Plant your feet firmly on the ground.',
      'Retract your shoulder blades and maintain a slight arch in your lower back.',
      'Unrack the weight and position it directly above your chest.',
    ];
  }

  // -------- Push press / overhead press / Z-press / Arnold ------------
  if (_isNonBenchPress(name) && !name.contains('leg press') &&
      !name.contains('calf press') && !name.contains('hip press')) {
    return [
      'Stand with feet hip-to-shoulder width, bar in the front rack on your shoulders.',
      'Brace your core and squeeze your glutes — ribs stacked over hips.',
      'Press the bar overhead in a vertical line, moving your head through.',
      'Lock out with biceps near the ears and the bar over mid-foot.',
      'Lower with control back to the front rack, reset, repeat.',
    ];
  }

  // -------- Leg press / calf press / hack squat (machine lower) -------
  if (name.contains('leg press') || name.contains('hack squat') ||
      name.contains('hack-squat')) {
    return [
      'Set the seat / sled depth so your knees can hit ~90° without pinching.',
      'Place feet shoulder-width on the platform, slightly toed out.',
      'Press the safety latches off, control the negative.',
      'Lower until thighs are parallel — do NOT let your lower back round off the pad.',
      'Drive through the whole foot, locking out without slamming the knees.',
    ];
  }
  if (name.contains('calf press') ||
      (name.contains('calf') && (name.contains('raise') || name.contains('press')))) {
    return [
      'Place the balls of your feet on the platform / step, heels hanging.',
      'Lock your knees (standing) or set them at 90° (seated calf raise).',
      'Drop the heels below the platform for a deep stretch.',
      'Drive up onto the toes as high as possible — pause at the top.',
      'Lower under control through the full range — no bouncing.',
    ];
  }

  // -------- Squat family (jump > bodyweight > pistol > goblet > loaded)
  if (name.contains('squat')) {
    if (c.plyo) {
      return [
        'Stand with feet shoulder-width apart, arms relaxed at your sides.',
        'Brace your core and look straight ahead.',
        'Drop into a controlled squat — thighs roughly parallel to the floor.',
        'Explode upward, driving through the balls of your feet.',
        'Land softly on the mid-foot, absorb the impact, and reset.',
      ];
    }
    if (name.contains('pistol') ||
        (name.contains('single') && name.contains('leg'))) {
      return [
        'Stand on one foot with the other leg extended out in front of you.',
        'Hold your arms forward as a counterbalance.',
        'Push your hips back and lower with the working leg only.',
        'Keep the working knee tracking over the toes — heel stays planted.',
        'Drive up through the heel back to standing, then switch sides.',
      ];
    }
    if (name.contains('goblet')) {
      return [
        'Hold a kettlebell or dumbbell at chest level — elbows tucked under.',
        'Stand with feet shoulder-width, toes slightly out.',
        'Brace and descend between your knees with an upright torso.',
        'Drop until your elbows graze the inside of your knees.',
        'Drive through your heels back to standing, ribs over hips.',
      ];
    }
    if (name.contains('split squat') || name.contains('bulgarian')) {
      return [
        'Set up in a long lunge stance, rear foot elevated on a bench.',
        'Square the hips, brace the core, eyes forward.',
        'Lower the back knee straight down toward the floor.',
        'Front shin should stay roughly vertical at the bottom.',
        'Drive through the front heel back to the start.',
      ];
    }
    if (c.bodyweight) {
      return [
        'Stand with feet shoulder-width apart, toes slightly pointed out.',
        'Hold your arms out in front for balance (or hands behind your head).',
        'Brace your core and look straight ahead.',
        'Push your hips back and bend your knees to descend.',
        'Drive through your heels to stand back up.',
      ];
    }
    return [
      'Position the bar on your upper back (not your neck).',
      'Stand with feet shoulder-width apart, toes slightly pointed out.',
      'Brace your core before descending.',
      'Keep your knees tracking over your toes.',
      'Descend until thighs are at least parallel to the floor.',
    ];
  }

  // -------- Deadlift variants ------------------------------------------
  if (name.contains('deadlift') || name.contains('rdl')) {
    if (name.contains('single') ||
        (name.contains('one') && name.contains('leg'))) {
      return [
        'Stand on one leg with a soft knee bend, weight in front of the working hip.',
        'Hinge at the working hip, letting the back leg rise behind you.',
        'Keep the back flat — chest, hip, and back leg form one straight line.',
        'Lower the weight to mid-shin, then return by squeezing the working glute.',
        'Reset on the floor between reps if balance is unstable.',
      ];
    }
    if (name.contains('romanian') ||
        name.contains('rdl') ||
        name.contains('stiff-leg') ||
        name.contains('stiff leg')) {
      return [
        'Stand tall, bar at hip height, feet hip-width.',
        'Maintain a slight, fixed knee bend — do not turn this into a squat.',
        'Hinge at the hips, pushing them BACK as the bar slides down the thighs.',
        'Stop just below the knee or where your hamstring stretch peaks.',
        'Drive hips forward to stand — finish with glutes squeezed, not lower-back arched.',
      ];
    }
    if (name.contains('sumo')) {
      return [
        'Set up with a wide stance, toes pointed out 30–45°.',
        'Bar over mid-foot, hands gripping inside the legs.',
        'Push the knees out and over the laces — chest tall.',
        'Drive the floor away — hips and shoulders rise together.',
        'Lock out by squeezing glutes; lower with the same control.',
      ];
    }
    if (name.contains('trap-bar') || name.contains('hex bar')) {
      return [
        'Stand inside the trap bar, feet hip-width, mid-foot under the handles.',
        'Hinge to grip the handles — keep the chest up and back flat.',
        'Drive through the floor like a leg press — hips and chest rise together.',
        'Lock out tall with shoulders pulled back.',
        'Lower with the same hinge pattern, never round the back.',
      ];
    }
    return [
      'Stand with feet hip-width apart, bar over mid-foot.',
      'Grip the bar just outside your legs.',
      'Keep your back flat and chest up.',
      'Take the slack out of the bar before pulling.',
      'Drive through your heels and push hips forward.',
    ];
  }

  // -------- Push-up family ---------------------------------------------
  if (name.contains('push-up') ||
      name.contains('pushup') ||
      name.contains('push up')) {
    if (c.plyo || name.contains('clap')) {
      return [
        'Set up in a standard push-up plank — shoulders over wrists.',
        'Lower under control until the chest is just off the floor.',
        'Press EXPLOSIVELY so your hands leave the floor (clap if cued).',
        'Re-catch with bent elbows — never slam onto locked-out arms.',
        'Reset the brace before the next rep.',
      ];
    }
    if (name.contains('decline')) {
      return [
        'Place your feet on a bench/box, hands shoulder-width on the floor.',
        'Form one straight line from heels to head — squeeze the glutes.',
        'Lower the chest toward the floor with elbows at ~45°.',
        'Press straight back up without flaring the elbows or sagging hips.',
        'Reset before the next rep.',
      ];
    }
    if (name.contains('incline') || name.contains('knee')) {
      return [
        'Place hands on an elevated surface (bench, wall) or drop to your knees.',
        'Brace the core — line from knees/feet to head should be straight.',
        'Lower the chest under control toward the surface.',
        'Press through the palms back to a long arm position.',
        'Squeeze the chest at the top.',
      ];
    }
    return [
      'Set up in a plank — hands slightly wider than shoulders, fingers spread.',
      'Squeeze glutes and brace the core so hips stay level (no sag, no pike).',
      'Lower the chest to the floor with elbows tucked at ~45°.',
      'Drive the floor away to push back up — long arms at the top.',
      'Reset, breathe, and repeat.',
    ];
  }

  // -------- Dips -------------------------------------------------------
  if (name.contains('dip') && !name.contains('bicep')) {
    return [
      'Mount the bars/bench with arms locked out, shoulders pulled down.',
      'Lean slightly forward for chest dips, stay vertical for triceps.',
      'Lower until your shoulders are just below the elbows.',
      'Drive back up by pushing through the palms — lock out at the top.',
      'Avoid swinging; let the chest/triceps do the work.',
    ];
  }

  // -------- Pull-ups / chin-ups ---------------------------------------
  if ((name.contains('pull-up') ||
          name.contains('pullup') ||
          name.contains('pull up') ||
          name.contains('chin-up') ||
          name.contains('chinup') ||
          name.contains('chin up')) &&
      !name.contains('lat')) {
    return [
      'Hang from the bar with a controlled grip — overhand for pull-ups, under for chin-ups.',
      'Start with shoulders pulled DOWN away from your ears.',
      'Drive elbows down toward the ribs — pull your chest to the bar.',
      'Pause briefly with the chin over the bar.',
      'Lower with control to a fully extended hang.',
    ];
  }

  // -------- Inverted / TRX rows (bodyweight) --------------------------
  if (name.contains('inverted row') ||
      name.contains('trx row') ||
      name.contains('australian pull')) {
    return [
      'Set the bar / TRX handles roughly waist height.',
      'Hang underneath with arms straight, body in a straight line.',
      'Brace the core and squeeze the glutes — no hip sag.',
      'Pull your chest to the bar/handles, elbows trace the ribs.',
      'Lower with control to a full hang and repeat.',
    ];
  }

  // -------- Lunges -----------------------------------------------------
  if (name.contains('lunge')) {
    if (c.plyo || name.contains('jumping lunge')) {
      return [
        'Start in a tall lunge — front knee at 90°, back knee just off the floor.',
        'Brace and explode straight up, switching legs in mid-air.',
        'Land softly into the opposite lunge — knees soft, chest tall.',
        'Reset balance for a beat before the next rep.',
        'Stop the set before form deteriorates — quality over speed.',
      ];
    }
    if (name.contains('cossack')) {
      return [
        'Stand with feet wide, toes slightly out.',
        'Shift your weight onto one foot, bending that knee deeply.',
        'Keep the opposite leg straight, toes pointing up if mobility allows.',
        'Sit your hips back and down on the bent side.',
        'Drive back through the heel to center, then switch sides.',
      ];
    }
    if (name.contains('walking')) {
      return [
        'Stand tall with feet hip-width apart, weights at the sides if used.',
        'Step forward into a long lunge — front knee tracks over the toes.',
        'Drive off the back foot and step THROUGH into the next lunge.',
        'Maintain an upright torso the whole way.',
        'Cover the prescribed distance, then turn around or reset.',
      ];
    }
    return [
      'Stand tall with feet hip-width apart, core braced.',
      'Step forward (or back) into a long lunge stance.',
      'Lower until both knees form ~90° angles — rear knee just off the floor.',
      'Keep your front knee tracking over your toes, not collapsing inward.',
      'Drive through the front heel to return to standing.',
    ];
  }

  // -------- Hip thrust / glute bridge ---------------------------------
  if (name.contains('hip thrust') || name.contains('hip-thrust')) {
    return [
      'Sit with your upper back against a bench, bar across your hips (use a pad).',
      'Plant feet hip-to-shoulder width, knees ~90° at the top.',
      'Tuck the chin, brace the core, and drive through your heels.',
      'Lock out with hips fully extended — squeeze the glutes hard.',
      'Lower with control to just above the floor, then repeat.',
    ];
  }
  if (name.contains('glute bridge') || (name.contains('bridge') && c.bodyweight)) {
    return [
      'Lie on your back, knees bent, feet flat near your glutes.',
      'Tuck the pelvis and brace the core.',
      'Drive through the heels to lift the hips.',
      'Squeeze the glutes hard at the top — ribs stacked over hips.',
      'Lower under control to just above the floor.',
    ];
  }

  // -------- Plank / hold isometrics -----------------------------------
  if (name.contains('plank') || name.contains('wall sit') ||
      name.contains('hollow body') || name.contains('dead hang') ||
      name.contains('l-sit') || name.contains('l sit')) {
    if (name.contains('side plank')) {
      return [
        'Lie on your side, forearm on the floor, elbow under the shoulder.',
        'Stack the feet (or stagger for balance).',
        'Lift the hips so the body is one straight line from feet to head.',
        'Brace the obliques — no hip sag, no rotation.',
        'Hold for the prescribed time, then switch sides.',
      ];
    }
    if (name.contains('plank')) {
      return [
        'Set up on forearms (or palms) with elbows under the shoulders.',
        'Squeeze the glutes and tuck the pelvis — straight line head to heels.',
        'Press the floor away to lift the upper back slightly.',
        'Brace the core like you are bracing for a punch.',
        'Hold for the prescribed time without sagging or piking.',
      ];
    }
    if (name.contains('wall sit')) {
      return [
        'Place your back flat against a wall, feet about 2 feet out.',
        'Slide down until thighs are parallel to the floor (or your prescribed depth).',
        'Knees should track over the toes — about 90° each.',
        'Press your back into the wall and brace the core.',
        'Hold without leaning hands on the thighs.',
      ];
    }
    return [
      'Move slowly into the hold position — quality over time.',
      'Engage the working muscle group BEFORE starting the clock.',
      'Breathe steadily throughout — no breath holding.',
      'Stop when the position breaks down, not when it gets uncomfortable.',
      'Track the hold time and progress gradually.',
    ];
  }

  // -------- Burpees / mountain climber / bear crawl -------------------
  if (name.contains('burpee')) {
    return [
      'Stand tall, then drop your hands to the floor and kick the feet back.',
      'Drop into a push-up (full chest-to-floor or chest-tap variant).',
      'Pop the feet back to your hands — keep the back flat.',
      'Stand up explosively; jump and clap overhead if cued.',
      'Land soft and reset for the next rep.',
    ];
  }
  if (name.contains('mountain climber')) {
    return [
      'Set up in a high plank — wrists under shoulders, glutes tight.',
      'Drive one knee toward the chest without letting the hips rise.',
      'Quickly switch legs as if running in plank position.',
      'Keep the upper body rock-solid; the legs do the work.',
      'Set a steady cadence — speed is the last priority.',
    ];
  }
  if (name.contains('bear crawl') || name.contains('crab walk')) {
    return [
      'Set up on hands and feet, knees hovering an inch off the floor.',
      'Brace the core — back flat, hips low.',
      'Move opposite hand and opposite foot together.',
      'Keep the steps small and the hips quiet.',
      'Stop the set when form breaks down.',
    ];
  }

  // -------- Crunch / sit-up / ab work --------------------------------
  if (name.contains('crunch') ||
      name.contains('sit-up') ||
      name.contains('situp') ||
      name.contains('sit up') ||
      name.contains('v-up') ||
      name.contains('vup') ||
      name.contains('toe touch') ||
      name.contains('leg raise') ||
      name.contains('flutter kick')) {
    return [
      'Lie on your back; tuck the pelvis so the lower back contacts the floor.',
      'Place hands lightly behind the head — do NOT pull on the neck.',
      'Brace the abs and curl the chest toward the hips.',
      'Squeeze the abs hard at the top, exhale fully.',
      'Lower under control — keep tension on the abs the whole way.',
    ];
  }
  if (name.contains('russian twist')) {
    return [
      'Sit with knees bent, lean back to ~45°.',
      'Hold a weight (or hands together) at chest level.',
      'Lift the feet (advanced) or keep them planted (beginner).',
      'Rotate from the trunk — twist the weight side to side.',
      'Pause briefly each side; do not let the lower back round.',
    ];
  }

  // -------- Rows (with bodyweight + machine guards) -------------------
  if (name.contains('row')) {
    if (name.contains('cable') || name.contains('seated row')) {
      return [
        'Sit tall with feet braced, knees soft, chest up.',
        'Grip the handle with arms extended, shoulders pulled down.',
        'Pull the handle to your sternum — drive the elbows back.',
        'Squeeze the shoulder blades together at the end range.',
        'Return slowly to a full stretch with the lats engaged.',
      ];
    }
    if (name.contains('renegade')) {
      return [
        'Set up in a high plank with one dumbbell in each hand.',
        'Brace the core — keep the hips square to the floor.',
        'Row one dumbbell to the ribs without rotating the torso.',
        'Lower under control, then row the opposite arm.',
        'Push-up between rows is optional based on the prescription.',
      ];
    }
    return [
      'Hinge at the hips with a slight knee bend.',
      'Keep your back flat and core engaged.',
      'Grip the weight with arms extended.',
      'Pull the weight toward your lower chest/upper abs.',
      'Squeeze your shoulder blades together at the top.',
    ];
  }

  // -------- Curls (with hammer / preacher / reverse guards) -----------
  if (name.contains('curl') &&
      !name.contains('leg curl') &&
      !name.contains('crunch') &&
      !name.contains('ab curl')) {
    if (name.contains('hammer')) {
      return [
        'Stand tall, dumbbells at your sides with palms facing the body (neutral grip).',
        'Keep elbows tucked at the ribs.',
        'Curl the weights up while keeping the wrists neutral — thumbs to shoulders.',
        'Squeeze briefly at the top.',
        'Lower slowly under tension to a full extension.',
      ];
    }
    if (name.contains('reverse')) {
      return [
        'Stand with feet shoulder-width apart, palms facing DOWN.',
        'Take a slightly narrower than shoulder-width grip.',
        'Keep elbows pinned at the sides.',
        'Curl the weight up using your forearms and biceps brachialis.',
        'Lower with control — forearms will fatigue fast.',
      ];
    }
    if (name.contains('preacher')) {
      return [
        'Settle into the preacher bench — armpits sit at the top of the pad.',
        'Grip the bar with palms up, slightly narrower than shoulders.',
        'Curl the bar up under tension — do NOT bounce off the pad.',
        'Squeeze the biceps at the top.',
        'Lower fully but stop just before complete elbow lockout.',
      ];
    }
    if (name.contains('concentration')) {
      return [
        'Sit on a bench, lean forward, brace the working elbow on the inside of your thigh.',
        'Let the dumbbell hang with palm up.',
        'Curl up while the upper arm stays glued to the leg.',
        'Squeeze hard at the top.',
        'Lower with full control to a long arm.',
      ];
    }
    return [
      'Stand with feet shoulder-width apart.',
      'Grip the weight with palms facing up.',
      'Keep your elbows close to your sides.',
      'Curl the weight toward your shoulders.',
      'Lower with control to full arm extension.',
    ];
  }

  // -------- Lat pulldown / pull-down ---------------------------------
  if (name.contains('lat pulldown') || name.contains('pulldown') ||
      (name.contains('pull') && name.contains('down'))) {
    return [
      'Set the thigh pad snug; sit tall with feet planted.',
      'Grip the bar slightly wider than shoulder-width, palms forward.',
      'Pull shoulders down and back BEFORE the rep starts.',
      'Drive elbows down to the ribs — bring the bar to upper chest.',
      'Return slowly to a full overhead stretch.',
    ];
  }

  // -------- Calf raise (already covered for calf press) --------------
  if (name.contains('calf') && name.contains('raise')) {
    return [
      'Place balls of your feet on a step or platform — heels hanging.',
      'Stand tall, soft knee bend (or set the seated pad on your thighs).',
      'Drop the heels below the platform for a deep stretch.',
      'Drive up onto the toes; pause and squeeze at the top.',
      'Lower under control through a full range.',
    ];
  }

  // -------- Kettlebell swing / snatch / clean ------------------------
  if (c.kettlebell && (name.contains('swing') || name.contains('snatch') ||
      name.contains('clean'))) {
    return [
      'Stand tall with the bell in front of you, feet just outside shoulder-width.',
      'Hinge at the hips, hike the bell back between your legs.',
      'Snap the hips forward — the bell floats up under its own momentum.',
      'Hands are passive: let the hips do the work, never lift with the arms.',
      'Catch the hinge softly and reload for the next rep.',
    ];
  }

  // -------- Crossover / fly ------------------------------------------
  if (name.contains('crossover') || name.contains('fly') || name.contains('flye') ||
      name.contains('pec deck') || name.contains('pec-deck')) {
    return [
      'Stand between the cable stacks (or set up in the pec-deck/bench).',
      'Soft bend in the elbows — never lock them out.',
      'Step one foot forward (cable) for a stable base, chest up.',
      'Bring the handles together in front of your chest in a sweeping arc.',
      'Squeeze your chest at the midpoint, then reverse with control.',
    ];
  }

  // -------- Tricep extension / kickback ------------------------------
  if (name.contains('extension') || name.contains('kickback') ||
      name.contains('skull crusher') || name.contains('overhead tricep')) {
    return [
      'Anchor your upper arm — pin elbow to your side or brace on a bench.',
      'Start with your forearm bent at ~90°.',
      'Extend the weight back until your arm is straight.',
      'Squeeze the triceps at full extension.',
      'Return slowly — control the negative.',
    ];
  }

  // -------- Face pull / band pull-apart ------------------------------
  if (name.contains('face pull') || name.contains('band pull-apart') ||
      name.contains('pull apart')) {
    return [
      'Set the cable / band roughly at face height (rope or straight band).',
      'Step back to create tension, arms long.',
      'Pull the rope/band toward your face — elbows up and out.',
      'Externally rotate at the top: knuckles point back behind the ears.',
      'Return slowly under control.',
    ];
  }

  // -------- Default generic instructions -----------------------------
  return [
    'Set up your equipment and check your form in a mirror if available.',
    'Warm up with lighter weight first.',
    'Position yourself in the starting position.',
    'Focus on controlled movements throughout.',
    'Breathe consistently — exhale on exertion.',
  ];
}

/// Breathing cues — inhale / exhale pattern for this exercise.
List<String> getBreathingCues(String exerciseName, {String? equipment}) {
  final c = _classify(exerciseName, equipment);
  final name = c.name;

  // Plyometric / explosive — rhythmic, never Valsalva for multi-rep sets.
  if (c.plyo) {
    return [
      'Inhale through the eccentric / loading phase.',
      'Exhale forcefully on the explosive concentric (the jump or push).',
      'Reset the breath between reps — do not hold under repeated impact.',
    ];
  }

  // Cardio / steady-state conditioning
  if (c.cardio) {
    return [
      'Nose-in, mouth-out when pace allows — it regulates effort.',
      'Match breathing to rhythm: 2 in / 2 out is a good starting cadence.',
      'If you can talk in short sentences, you are at a sustainable zone-2 effort.',
    ];
  }

  // Stretch / mobility — slow diaphragmatic
  if (c.stretch) {
    return [
      'Inhale deeply through the nose into the belly.',
      'Exhale slowly through the mouth and ease a fraction deeper into the stretch.',
      'Never hold your breath — breathing is what allows tissue to release.',
    ];
  }

  // Plank / wall sit / dead hang / static holds
  if (c.isometric) {
    return [
      'Breathe steadily — short, shallow breaths are fine.',
      'Do not hold your breath; that spikes blood pressure and shortens the hold.',
      'Exhale a touch more forcefully on each breath to keep the core braced.',
    ];
  }

  // Squat — split jump/bodyweight/loaded
  if (name.contains('squat')) {
    if (c.bodyweight && !c.plyo) {
      return [
        'Inhale through the descent — fill the belly, not the chest.',
        'Exhale on the drive up.',
        'Keep the breath natural — no forced Valsalva needed without a load.',
      ];
    }
    return [
      'Take a big belly-breath before you descend and brace your core.',
      'Hold the brace through the bottom of the rep.',
      'Exhale forcefully on the drive up.',
    ];
  }

  // Bench / press family (with non-bench-press guard)
  if (name.contains('bench') ||
      (name.contains('press') && !_isNonBenchPress(name))) {
    return [
      'Inhale as the bar lowers — fill your chest and brace.',
      'Exhale as you drive the bar back up through lockout.',
      'Reset the breath between reps; never hold under full load for multiple reps.',
    ];
  }

  // Overhead press / push press
  if (_isNonBenchPress(name) &&
      !name.contains('leg press') &&
      !name.contains('calf press') &&
      !name.contains('hip press')) {
    return [
      'Inhale and brace the core BEFORE the press starts.',
      'Hold the brace through the push.',
      'Exhale at lockout, reset the breath, then lower.',
    ];
  }

  // Leg press / hack squat / machine lower
  if (name.contains('leg press') || name.contains('hack squat')) {
    return [
      'Inhale on the descent — fill the belly and brace.',
      'Exhale on the press — never let the lower back round off the pad.',
      'Reset the breath between reps.',
    ];
  }

  // Deadlift family
  if (name.contains('deadlift') || name.contains('rdl')) {
    return [
      'Take a big breath into your belly at the top before setting up.',
      'Hold the brace throughout the pull — do not exhale mid-rep.',
      'Exhale at lockout, reset the breath before the next rep.',
    ];
  }

  // Pull-ups / chin-ups
  if ((name.contains('pull-up') ||
          name.contains('pullup') ||
          name.contains('pull up') ||
          name.contains('chin-up') ||
          name.contains('chinup') ||
          name.contains('chin up')) &&
      !name.contains('lat')) {
    return [
      'Inhale at the bottom of the hang.',
      'Exhale as you pull yourself up to the bar.',
      'Inhale on the controlled descent.',
    ];
  }

  // Push-up family
  if (name.contains('push-up') ||
      name.contains('pushup') ||
      name.contains('push up')) {
    return [
      'Inhale on the descent — keep the core braced.',
      'Exhale forcefully as you press back up.',
      'Reset the breath between reps if your tempo allows.',
    ];
  }

  // Burpees / mountain climbers — high-rep conditioning
  if (name.contains('burpee') || name.contains('mountain climber') ||
      name.contains('bear crawl')) {
    return [
      'Settle into a steady breath rhythm — 1 in / 1 out per movement.',
      'Do not hold your breath; intensity is high enough that breath holding will gas you out.',
      'If breath outpaces rhythm, slow the work to match the breath.',
    ];
  }

  // Row family (with rower-cardio guard)
  if (name.contains('row') &&
      !name.contains('rowing machine') &&
      !name.contains('rower') &&
      !name.contains('concept2')) {
    return [
      'Inhale at the stretched position with arms extended.',
      'Exhale as you pull the weight in and squeeze the back.',
      'Inhale again on the controlled return.',
    ];
  }

  // Curl family (with leg-curl guard)
  if (name.contains('curl') && !name.contains('leg curl')) {
    return [
      'Inhale at the bottom with arms fully extended.',
      'Exhale as you curl the weight up.',
      'Inhale on the slow eccentric back down.',
    ];
  }

  // Leg curl (machine)
  if (name.contains('leg curl')) {
    return [
      'Inhale at the start with the legs extended.',
      'Exhale as you curl the heels toward the glutes.',
      'Inhale on the controlled return — never fully relax.',
    ];
  }

  // Lat pulldown / pull-down
  if (name.contains('pulldown') || name.contains('pull down')) {
    return [
      'Inhale at the top of the stretch.',
      'Exhale as you drive the elbows down and the bar to your chest.',
      'Inhale on the controlled release back overhead.',
    ];
  }

  // Crossover / fly / pec deck
  if (name.contains('crossover') || name.contains('fly') ||
      name.contains('flye') || name.contains('pec deck')) {
    return [
      'Inhale on the way out as your chest stretches.',
      'Exhale as you bring the handles together and squeeze.',
      'Keep the breath smooth — never hold it for multiple reps.',
    ];
  }

  // Lunges
  if (name.contains('lunge')) {
    return [
      'Inhale as you step out and descend.',
      'Exhale as you drive through the front heel and stand.',
    ];
  }

  // Hip thrust / glute bridge
  if (name.contains('hip thrust') || name.contains('glute bridge') ||
      (name.contains('bridge') && !name.contains('cable'))) {
    return [
      'Inhale at the bottom — pelvis tucked, ribs down.',
      'Exhale as you drive the hips up and squeeze the glutes.',
      'Inhale at the top before lowering with control.',
    ];
  }

  // Crunch / ab work
  if (name.contains('crunch') || name.contains('sit-up') ||
      name.contains('situp') || name.contains('sit up') ||
      name.contains('v-up') || name.contains('toe touch') ||
      name.contains('leg raise') || name.contains('russian twist')) {
    return [
      'Inhale on the eccentric / lengthening phase.',
      'Exhale forcefully as you contract the abs at the top.',
      'Empty the lungs at the peak contraction for maximum recruitment.',
    ];
  }

  // Tricep extension / kickback / skull crusher
  if (name.contains('extension') || name.contains('kickback') ||
      name.contains('skull crusher') || name.contains('overhead tricep')) {
    return [
      'Inhale at the bent-elbow starting position.',
      'Exhale as you extend the weight back / overhead.',
      'Inhale on the controlled return.',
    ];
  }

  // Face pull / band pull-apart
  if (name.contains('face pull') || name.contains('pull-apart') ||
      name.contains('pull apart')) {
    return [
      'Inhale as you set up with arms extended.',
      'Exhale through the pull — squeeze the rear delts.',
      'Inhale on the controlled return.',
    ];
  }

  // Kettlebell swing / snatch / clean
  if (c.kettlebell && (name.contains('swing') || name.contains('snatch') ||
      name.contains('clean'))) {
    return [
      'Inhale as the bell hikes back between the legs.',
      'Exhale forcefully as the hips snap and the bell floats up.',
      'Reset the breath between reps; high-rep ballistics live or die on breath rhythm.',
    ];
  }

  // Olympic lifts
  if (c.olympic) {
    return [
      'Inhale and brace at the start of the lift.',
      'Hold the brace through the pull — let the breath out at lockout.',
      'Reset the breath fully between every single rep — these are max-effort attempts.',
    ];
  }

  // Calf raise
  if (name.contains('calf') && (name.contains('raise') || name.contains('press'))) {
    return [
      'Inhale at the stretched bottom position.',
      'Exhale as you push up onto the toes.',
      'Keep the breath rhythmic — calves respond to long sets.',
    ];
  }

  // Generic default
  return [
    'Inhale during the eccentric (easier) half of the rep.',
    'Exhale during the concentric (harder) half — pushing, pulling, or lifting.',
    'Never hold your breath for multiple reps in a row.',
  ];
}

/// Form tips — the things to watch for while executing the rep.
List<String> getFormTips(String exerciseName, {String? equipment}) {
  final c = _classify(exerciseName, equipment);
  final name = c.name;

  // Olympic lifts — top priority because of injury risk
  if (c.olympic) {
    if (name.contains('snatch') || name.contains('clean')) {
      return [
        'Keep the bar PATH straight up — no arching out and back.',
        'Lock the lats and keep the bar close to the body throughout the pull.',
        'Drop UNDER the bar in the third pull — do not muscle it up.',
        'Catch with locked, stable joints — never bail forward.',
        'When in doubt, dump the bar safely; never twist out of a missed lift.',
      ];
    }
    if (name.contains('jerk')) {
      return [
        'Dip straight down — knees track over toes, no forward lean.',
        'Drive vertically — the legs launch the bar, not the arms.',
        'Punch under fast — the bar moves up because YOU drop down.',
        'Lock the elbows hard before you stand up out of the catch.',
        'Stand back up with the bar over the mid-foot.',
      ];
    }
    if (name.contains('farmer') || name.contains('yoke')) {
      return [
        'Keep the chest tall and shoulders pulled down throughout.',
        'Take quick, short steps — long strides break posture.',
        'Brace harder than feels necessary — your spine is the chain weak link.',
        'Eyes forward, never down at the load.',
        'Set the load down with intent, never drop.',
      ];
    }
  }

  // Cardio — generic form cues
  if (c.cardio) {
    if (name.contains('jump rope')) {
      return [
        'Keep the elbows close to the ribs — let the wrists do the work.',
        'Stay on the balls of the feet, jumping just 1–2 inches.',
        'Land softly — hard landings stress the knees.',
        'Keep the core engaged so the body bounces as one unit.',
        'Rest as soon as form decays; better to break the set than trip.',
      ];
    }
    if (name.contains('rowing') || name.contains('rower')) {
      return [
        'LEGS first, then back, then arms — never reverse.',
        'On recovery: arms away, hinge, knees up — slow is smooth.',
        'Hands track in a straight line on every drive.',
        'Brace the core; do not yank with the lower back.',
        'Watch the split / pace, not just the time.',
      ];
    }
    if (name.contains('treadmill') || name.contains('running') ||
        name.contains('jog') || name.contains('sprint')) {
      return [
        'Land under your hips, not out in front — avoid heavy heel strikes.',
        'Slight forward lean from the ankles, not the waist.',
        'Cadence target: 170–180 steps per minute when possible.',
        'Relax the shoulders and unclench the hands.',
        'Match breathing to pace; if you cannot talk, slow down.',
      ];
    }
    return [
      'Maintain steady form throughout — quality beats raw speed.',
      'Avoid choppy posture changes; let the work breathe.',
      'Keep the breath even; ragged breath means the pace is too high.',
      'Stop or slow down as soon as form deteriorates.',
      'Cool down for at least 3 minutes at low intensity.',
    ];
  }

  // Stretches
  if (c.stretch) {
    return [
      'Move slowly into the position; never bounce.',
      'Breathe deeply — exhalations let the tissue lengthen.',
      'Stop at "mild tension" — sharp pain means back off.',
      'Aim for 30–60 seconds per side for static stretches.',
      'Keep tension off the joint capsule; target the muscle belly.',
    ];
  }

  // Squat with jump / bodyweight / loaded split
  if (name.contains('squat')) {
    if (c.plyo) {
      return [
        'Land softly — bend the knees on impact, do not lock them out.',
        'Knees track over the toes on every landing.',
        'Reset between reps so you launch from a solid base.',
        'Land flat, not on the toes, to absorb force through the whole foot.',
        'Chest up — do not let the torso fold forward in the air.',
      ];
    }
    if (name.contains('pistol') ||
        (name.contains('single') && name.contains('leg'))) {
      return [
        'Plant the working heel — never let it lift.',
        'Counterbalance with the arms forward to stay upright.',
        'Knee tracks over the toes; do NOT let it cave in.',
        'Sit back rather than dropping straight down.',
        'Use a TRX or doorway for assisted reps if you cannot hit full depth yet.',
      ];
    }
    if (c.bodyweight) {
      return [
        'Weight in the heels and mid-foot.',
        'Go as deep as your mobility allows with good form.',
        "Don't let your knees cave inward.",
        'Drive through the heels to stand up.',
        'Keep the chest up and core braced throughout.',
      ];
    }
    return [
      'Weight in your heels and mid-foot.',
      'Go as deep as your mobility allows with good form.',
      "Don't let your knees cave inward.",
      'Stand up by driving your hips forward.',
      'Keep your core braced throughout the movement.',
    ];
  }

  // Bench / press (with non-bench guard)
  if (name.contains('bench') ||
      (name.contains('press') && !_isNonBenchPress(name))) {
    return [
      'Wrists straight, stacked over the elbows.',
      'Lower the bar to your mid-chest with control.',
      'Press through the chest, not just the arms.',
      'Maintain tension at the bottom — no bouncing.',
      'Feet planted; do not lift the hips.',
    ];
  }

  // Overhead press / push press
  if (_isNonBenchPress(name) &&
      !name.contains('leg press') &&
      !name.contains('calf press') &&
      !name.contains('hip press')) {
    return [
      'Squeeze the glutes — they protect the lower back.',
      'Press the bar in a vertical line — head moves through at lockout.',
      'Lock out with biceps near the ears, not flared forward.',
      'Brace before the press, not during.',
      'Lower with control to the front rack — never crash it.',
    ];
  }

  // Leg press / hack squat / calf press
  if (name.contains('leg press') || name.contains('hack squat')) {
    return [
      'Lower until thighs are parallel — do NOT round the lower back off the pad.',
      'Knees track over the toes; do NOT let them collapse inward.',
      'Drive through the whole foot, not just the toes.',
      'Lock out without slamming — soft knees at the top.',
      'Use the safety latches; engage them whenever you re-rack.',
    ];
  }
  if (name.contains('calf press') ||
      (name.contains('calf') && name.contains('raise'))) {
    return [
      'Drop the heel below the platform for the full stretch.',
      'Drive up onto the BIG TOE side, not just the outer foot.',
      'Pause at the top — calves respond to peak contraction.',
      'Slow eccentric — calves can take 3–4 seconds down.',
      'Keep the knees fixed (standing) or thighs braced (seated).',
    ];
  }

  // Deadlift family
  if (name.contains('deadlift') || name.contains('rdl')) {
    if (name.contains('romanian') || name.contains('rdl') ||
        name.contains('stiff-leg') || name.contains('stiff leg')) {
      return [
        'Hips back, NOT a squat — knee bend stays fixed.',
        'Bar slides down the thighs; never drift away from the body.',
        'Stop where your hamstring stretch peaks, not at the floor.',
        'Lock out by squeezing the glutes — do not hyperextend the back.',
        'Keep the spine neutral; chin tucked, not craning up.',
      ];
    }
    return [
      'Never round the lower back.',
      'Keep the bar close to the body throughout.',
      'Lock out by squeezing the glutes, not by hyperextending.',
      'Lower with control — do not drop the weight.',
      'Reset position between every rep.',
    ];
  }

  // Push-up family
  if (name.contains('push-up') ||
      name.contains('pushup') ||
      name.contains('push up')) {
    return [
      'Squeeze the glutes — keep the body in one straight line.',
      'Elbows tucked at ~45°, not flared out at 90°.',
      'Chest leads on the descent, not the head.',
      'Lower until the chest grazes the floor for full ROM.',
      'Drive the floor away on the press — long arms at the top.',
    ];
  }

  // Pull-ups / chin-ups
  if ((name.contains('pull-up') ||
          name.contains('pullup') ||
          name.contains('pull up') ||
          name.contains('chin-up') ||
          name.contains('chinup') ||
          name.contains('chin up')) &&
      !name.contains('lat')) {
    return [
      'Start every rep from a dead hang; no half reps.',
      'Pull shoulders DOWN before pulling up.',
      'Drive elbows toward the ribs.',
      'Get the chin clearly over the bar — do not crane the neck.',
      'Lower under control to a full hang.',
    ];
  }

  // Inverted / TRX rows
  if (name.contains('inverted row') || name.contains('trx row') ||
      name.contains('australian pull')) {
    return [
      'Glutes and core braced — no hip sag at any point.',
      'Pull until the bar/handles touch your chest.',
      'Squeeze the shoulder blades together at the top.',
      'Lower with control to a full arm extension.',
      'Adjust foot height to scale difficulty.',
    ];
  }

  // Lunges
  if (name.contains('lunge')) {
    if (c.plyo || name.contains('jumping lunge')) {
      return [
        'Land softly — knees soft, never locked.',
        'Switch legs in the air; do not rotate the torso.',
        'Front knee tracks over the toes — never collapses inward.',
        'Reset balance for a beat between reps.',
        'Stop the set when form breaks down, not when reps are "done".',
      ];
    }
    return [
      'Front knee tracks over the toes — never caves inward.',
      'Step long enough that the rear knee can comfortably reach the floor.',
      'Keep the torso upright; do not lean over the front knee.',
      'Drive through the FRONT heel to stand.',
      'Equal reps per side, even if one feels stronger.',
    ];
  }

  // Hip thrust / glute bridge
  if (name.contains('hip thrust') || name.contains('glute bridge') ||
      (name.contains('bridge') && !name.contains('cable'))) {
    return [
      'Tuck the chin and the pelvis — ribs down, not flared.',
      'Drive through the heels, not the toes.',
      'Lock out fully — hips in a straight line with knees and shoulders.',
      'Squeeze the glutes hard at the top, hold a beat.',
      'Do not hyperextend the lower back to chase more height.',
    ];
  }

  // Plank / wall sit / dead hang / static holds
  if (c.isometric) {
    if (name.contains('plank')) {
      return [
        'Squeeze glutes; tuck the pelvis — no sag, no pike.',
        'Press the floor away — pack the shoulders.',
        'Keep the head neutral; eyes look down at the floor.',
        'Breathe steadily — break the set if you start holding breath.',
        'Quality over time — 30 strict seconds beat 60 sloppy.',
      ];
    }
    if (name.contains('wall sit')) {
      return [
        'Thighs parallel to the floor — knees over ankles, not over toes.',
        'Whole back flat against the wall — including lower back.',
        'No hands on the thighs; arms at the sides or crossed at chest.',
        'Drive the heels into the floor; do not let them lift.',
        'Stop the second the depth breaks down.',
      ];
    }
    return [
      'Engage the working muscle BEFORE starting the timer.',
      'Breathe steadily; never hold the breath.',
      'Hold position quality over duration.',
      'Stop when form breaks down, not when it gets uncomfortable.',
      'Track time and progress gradually.',
    ];
  }

  // Burpees / mountain climber / bear crawl
  if (name.contains('burpee')) {
    return [
      'Hands flat on the floor before the feet kick back.',
      'Drop with control — do not slam the hips into the floor.',
      'Pop the feet back to the hands close enough to stand cleanly.',
      'Land soft on the jump, knees soft and tracking forward.',
      'When the breath ragged, slow the pace before form decays.',
    ];
  }
  if (name.contains('mountain climber')) {
    return [
      'Wrists stay under the shoulders — do not creep forward.',
      'Hips stay LOW — no piking.',
      'Move from the legs; keep the core rock-solid.',
      'Set a steady cadence; slow > sloppy.',
      'Pause and reset if the lower back starts arching.',
    ];
  }

  // Dips
  if (name.contains('dip') && !name.contains('bicep')) {
    return [
      'Shoulders pulled down and back at the top — never shrug into the bars.',
      'Lower until shoulders are JUST below the elbows; no further.',
      'Lean forward for chest emphasis; stay vertical for triceps.',
      'Lock out fully without rolling the shoulders forward.',
      'No swinging — the chest/triceps do all the work.',
    ];
  }

  // Crunch / ab work
  if (name.contains('crunch') || name.contains('sit-up') ||
      name.contains('situp') || name.contains('sit up') ||
      name.contains('v-up') || name.contains('toe touch') ||
      name.contains('leg raise')) {
    return [
      'Tuck the pelvis so the lower back stays in contact with the floor.',
      'Hands light on the head — never pull the neck forward.',
      'Curl the chest toward the hips; do not just lift the head.',
      'Exhale fully at the top to maximize ab recruitment.',
      'Lower under control — keep tension on the abs the whole way.',
    ];
  }
  if (name.contains('russian twist')) {
    return [
      'Rotate from the trunk, NOT the arms.',
      'Keep the lower back flat — do not let it round.',
      'Pause briefly at each side.',
      'Lift the feet only after you can hold form with feet down.',
      'Stop the set when the lower back rounds or jerks.',
    ];
  }

  // Row family (with cable / renegade special cases)
  if (name.contains('row') &&
      !name.contains('rowing machine') &&
      !name.contains('rower') &&
      !name.contains('concept2')) {
    if (name.contains('renegade')) {
      return [
        'Brace the core — hips MUST stay square to the floor.',
        'Plant the dumbbells wider for more stability.',
        'Row to the ribs without rotating the torso.',
        'Hold the plank between every row.',
        'Stop the set the second the hips rotate.',
      ];
    }
    return [
      'Initiate the pull with the back, not the arms.',
      'Core tight — do not let the lower back arch.',
      'No jerky reps — control beats weight.',
      'Hold a peak contraction at the top.',
      'Keep the neck neutral; eyes on the floor.',
    ];
  }

  // Curl family (with leg-curl and ab-curl guards)
  if (name.contains('curl') &&
      !name.contains('leg curl') &&
      !name.contains('crunch') &&
      !name.contains('ab curl')) {
    return [
      'Upper arms stay stationary — do not let elbows drift forward.',
      'No swinging the weight or rocking the torso.',
      'Squeeze hard at the top of the movement.',
      'Lower slowly for maximum tension.',
      'Stop just shy of full extension to keep tension on the biceps.',
    ];
  }
  if (name.contains('leg curl')) {
    return [
      'Pad sits just above the heels, not on the calves.',
      'Hips pinned to the bench — do not let them rise.',
      'Squeeze the hamstrings hard at the top.',
      'Lower over a slow 2–3 second eccentric.',
      'Stop the set before form breaks down.',
    ];
  }

  // Lat pulldown
  if (name.contains('pulldown') || (name.contains('pull') && name.contains('down'))) {
    return [
      'Start with shoulders pulled DOWN, not shrugged into the ears.',
      'Drive the elbows down to the ribs — bar to upper chest.',
      'Do not lean the torso back to muscle the weight.',
      'Stretch all the way back overhead between reps.',
      'Keep the wrists neutral; do not curl them.',
    ];
  }

  // Crossover / fly / pec deck
  if (name.contains('crossover') || name.contains('fly') ||
      name.contains('flye') || name.contains('pec deck')) {
    return [
      'Soft bend in the elbows the whole time — never lock them.',
      'Hug a tree — chest leads, not the arms.',
      'Do not crash the handles together; stop at a controlled midpoint.',
      'Resist the stretch on the way back; that is where the work is.',
      'Keep the shoulders pinned down, not shrugged.',
    ];
  }

  // Tricep extension / kickback / skull crusher
  if (name.contains('extension') || name.contains('kickback') ||
      name.contains('skull crusher') || name.contains('overhead tricep')) {
    return [
      'Pin the elbow — the upper arm does NOT move.',
      'Full extension at the top, but do not lock out hard.',
      'Slow eccentric — triceps respond to negatives.',
      'Keep the wrists neutral; do not curl them at lockout.',
      'Stop reps as soon as the elbow drifts forward.',
    ];
  }

  // Face pull / band pull-apart
  if (name.contains('face pull') || name.contains('pull-apart') ||
      name.contains('pull apart')) {
    return [
      'Lead with the elbows — they move up and out.',
      'Externally rotate at the top — knuckles point back.',
      'Keep the shoulders pulled down, not shrugged into the ears.',
      'No leaning back to muscle the weight up.',
      'Squeeze briefly at the top — slow eccentric.',
    ];
  }

  // Kettlebell swing / snatch / clean
  if (c.kettlebell && (name.contains('swing') || name.contains('snatch') ||
      name.contains('clean'))) {
    return [
      'Hinge, do not squat — knees soft, hips back.',
      'Snap the hips — the bell floats up, never gets lifted with the arms.',
      'Wrists are passive; the bell rests, not punches.',
      'Glute squeeze locks the hips at the top.',
      'Stop the set the moment hip drive falters.',
    ];
  }

  // Default generic tips
  return [
    'Focus on mind-muscle connection.',
    'Control the weight through the full range of motion.',
    'Avoid using momentum — let the target muscle do the work.',
    'If form breaks down, reduce the weight.',
    'Take your time and prioritize quality over quantity.',
  ];
}
