// Rest period encouragement messages organized by coaching style
// These messages are shown during rest periods between sets

import 'dart:math';

/// Context for generating appropriate rest messages
class RestContext {
  final String? exerciseName;
  final String? muscleGroup; // 'chest', 'back', 'legs', 'arms', 'shoulders', 'core'
  final bool isPR; // Personal record achieved
  final bool isLastSet; // Last set of exercise
  final bool isLastExercise; // Last exercise in workout
  final double? weightLifted;
  final double? previousWeight; // For comparison
  final int? reps;
  final Duration? setDuration; // How long the set took
  final bool wasFast; // Set completed unusually fast (possible bad form)

  const RestContext({
    this.exerciseName,
    this.muscleGroup,
    this.isPR = false,
    this.isLastSet = false,
    this.isLastExercise = false,
    this.weightLifted,
    this.previousWeight,
    this.reps,
    this.setDuration,
    this.wasFast = false,
  });
}

class RestMessages {
  /// Get a context-aware message based on coaching style, encouragement level, and workout context
  static String getMessage(
    String coachingStyle,
    double encouragementLevel, {
    RestContext? context,
  }) {
    final style = coachingStyle.toLowerCase();

    // Priority 1: PR/Achievement messages
    if (context?.isPR == true) {
      return _getPRMessage(style, context!);
    }

    // Priority 2: Fast completion warning (possible form issue)
    if (context?.wasFast == true) {
      return _getFastCompletionMessage(style);
    }

    // Priority 3: Weight increase celebration
    if (context != null &&
        context.weightLifted != null &&
        context.previousWeight != null &&
        context.weightLifted! > context.previousWeight!) {
      return _getWeightIncreaseMessage(style, context);
    }

    // Priority 4: Last set/exercise celebration
    if (context?.isLastSet == true && context?.isLastExercise != true) {
      return _getLastSetMessage(style);
    }

    // Priority 5: Exercise-specific message (occasionally)
    if (context?.muscleGroup != null && _random.nextInt(3) == 0) {
      final muscleMessage = _getMuscleGroupMessage(style, context!.muscleGroup!);
      if (muscleMessage != null) return muscleMessage;
    }

    // Default: Standard encouragement message
    return _getStandardMessage(style, encouragementLevel);
  }

  static final _random = Random();

  /// Get a PR celebration message
  static String _getPRMessage(String style, RestContext context) {
    final messages = _prMessagesByStyle[style] ?? _prMessagesByStyle['motivational']!;
    messages.shuffle();
    var message = messages.first;

    // Replace placeholders if weight info available
    if (context.weightLifted != null) {
      message = message.replaceAll('{weight}', '${context.weightLifted!.toStringAsFixed(1)}kg');
    }
    return message;
  }

  /// Get a message for fast set completion (form warning)
  static String _getFastCompletionMessage(String style) {
    final messages = _fastCompletionMessagesByStyle[style] ??
        _fastCompletionMessagesByStyle['motivational']!;
    messages.shuffle();
    return messages.first;
  }

  /// Get a weight increase celebration message
  static String _getWeightIncreaseMessage(String style, RestContext context) {
    final messages = _weightIncreaseMessagesByStyle[style] ??
        _weightIncreaseMessagesByStyle['motivational']!;
    messages.shuffle();
    var message = messages.first;

    final increase = context.weightLifted! - context.previousWeight!;
    message = message.replaceAll('{increase}', '${increase.toStringAsFixed(1)}kg');
    return message;
  }

  /// Get a last set celebration message
  static String _getLastSetMessage(String style) {
    final messages = _lastSetMessagesByStyle[style] ?? _lastSetMessagesByStyle['motivational']!;
    messages.shuffle();
    return messages.first;
  }

  /// Get a muscle-group specific message
  static String? _getMuscleGroupMessage(String style, String muscleGroup) {
    final muscleMessages = _muscleGroupMessages[muscleGroup.toLowerCase()];
    if (muscleMessages == null) return null;

    final styleMessages = muscleMessages[style] ?? muscleMessages['motivational'];
    if (styleMessages == null || styleMessages.isEmpty) return null;

    styleMessages.shuffle();
    return styleMessages.first;
  }

  /// Get standard encouragement message (original behavior)
  static String _getStandardMessage(String style, double encouragementLevel) {
    final messages = _messagesByStyle[style] ?? _messagesByStyle['motivational']!;

    List<String> filteredMessages;
    if (encouragementLevel < 0.3) {
      filteredMessages = messages['minimal'] ?? messages['standard']!;
    } else if (encouragementLevel < 0.6) {
      filteredMessages = messages['standard']!;
    } else if (encouragementLevel < 0.8) {
      filteredMessages = messages['high']!;
    } else {
      filteredMessages = messages['maximum']!;
    }

    filteredMessages.shuffle();
    return filteredMessages.first;
  }

  /// Get a tip message (shown occasionally)
  static String getTip(String coachingStyle) {
    final tips = _tipsByStyle[coachingStyle.toLowerCase()] ??
                 _tipsByStyle['motivational']!;
    tips.shuffle();
    return tips.first;
  }

  // ============================================================
  // PR/ACHIEVEMENT MESSAGES
  // ============================================================
  static final Map<String, List<String>> _prMessagesByStyle = {
    'motivational': [
      'NEW PERSONAL RECORD! You just made history!',
      'PR ALERT! You\'re getting STRONGER!',
      'INCREDIBLE! That\'s a new personal best!',
      'You just CRUSHED your previous record!',
    ],
    'professional': [
      'Personal record achieved. Excellent progression.',
      'New PR logged. Your training is paying off.',
      'Record broken. Strength gains confirmed.',
    ],
    'friendly': [
      'OH MY GOSH! That\'s a PR! I\'m so proud of you!',
      'You just beat your record! This is amazing!',
      'NEW PR! Look at you go, superstar!',
    ],
    'tough-love': [
      'Finally broke that PR. Took you long enough.',
      'NEW RECORD. See what happens when you push?',
      'PR achieved. Now make it your new baseline.',
    ],
    'drill-sergeant': [
      'NEW PR! THAT\'S WHAT I\'M TALKING ABOUT, SOLDIER!',
      'RECORD SMASHED! NOW THAT\'S WARRIOR SPIRIT!',
      'PR ACHIEVED! YOU JUST LEVELED UP!',
    ],
    'college-coach': [
      'THAT\'S A PR! NOW we\'re playing like champions!',
      'NEW RECORD! That\'s scholarship-worthy right there!',
      'PR! See what happens when you ACTUALLY try?!',
    ],
    'zen-master': [
      'A new peak reached. Your journey continues upward.',
      'Personal record achieved. Growth manifests.',
      'You have transcended your former limits.',
    ],
    'hype-beast': [
      'YOOOOO PR!!! YOU\'RE LITERALLY INSANE!!!',
      'NEW RECORD!!! THIS IS LEGENDARY!!!',
      'PR ALERT!!! YOU\'RE BUILT DIFFERENT!!!',
    ],
    'scientist': [
      'Personal record: +{weight} achieved. Muscle adaptation confirmed.',
      'PR logged. Your progressive overload protocol is working.',
      'New maximum recorded. Strength curve trending upward.',
    ],
    'comedian': [
      'PR! The weights are officially scared of you now!',
      'New record! Quick, someone call Guinness!',
      'PR achieved! Your muscles just got a promotion!',
    ],
    'old-school': [
      'NEW PR! That\'s old school strength right there!',
      'Record broken! Arnold would give you a thumbs up!',
      'PR! You\'re building a championship physique!',
    ],
  };

  // ============================================================
  // FAST COMPLETION MESSAGES (Form warnings)
  // ============================================================
  static final Map<String, List<String>> _fastCompletionMessagesByStyle = {
    'motivational': [
      'Great energy! Try slowing down for better muscle activation.',
      'Love the enthusiasm! Focus on controlled movements.',
      'You\'re fired up! Remember: slow and controlled wins.',
    ],
    'professional': [
      'Set completed quickly. Consider slower tempo for optimal results.',
      'Fast execution noted. Time under tension improves gains.',
      'Reduce tempo for better muscle fiber recruitment.',
    ],
    'friendly': [
      'Whoa, speedy! Try slowing down a bit for better results!',
      'That was quick! Slower reps = stronger muscles!',
      'Easy there, champ! Quality over speed!',
    ],
    'tough-love': [
      'Too fast. Slow it down or you\'re wasting your time.',
      'Speed doesn\'t equal strength. Control the weight.',
      'That was rushed. Do it RIGHT next time.',
    ],
    'drill-sergeant': [
      'TOO FAST! SLOW DOWN AND FEEL THE BURN!',
      'THAT WAS SLOPPY! CONTROLLED MOVEMENTS, SOLDIER!',
      'RUSHING WON\'T BUILD MUSCLE! DISCIPLINE!',
    ],
    'college-coach': [
      'SLOW DOWN! You\'re not racing anyone!',
      'Too fast! That\'s how you get injured, rookie!',
      'Control the weight! This isn\'t a speedrun!',
    ],
    'zen-master': [
      'The river does not rush. Slow your movements.',
      'Speed creates chaos. Find your steady flow.',
      'Patience in motion builds true strength.',
    ],
    'hype-beast': [
      'Yo that was FAST! Slow it down for MAX gains!',
      'Speed demon! But slower = MORE muscle!',
      'Easy there! Control that energy!',
    ],
    'scientist': [
      'Tempo too fast. Studies show 3-4 second eccentrics optimize hypertrophy.',
      'Reduce velocity. Time under tension correlates with muscle growth.',
      'Fast reps reduce mechanical tension. Slow down.',
    ],
    'comedian': [
      'Whoa, Flash! Weights aren\'t going anywhere!',
      'That was faster than my dating life. Slow down!',
      'Speed dating the weights? Take your time!',
    ],
    'old-school': [
      'Slow it down! Feel the muscle work!',
      'Too fast! No mind-muscle connection there.',
      'Control the weight, don\'t let it control you!',
    ],
  };

  // ============================================================
  // WEIGHT INCREASE MESSAGES
  // ============================================================
  static final Map<String, List<String>> _weightIncreaseMessagesByStyle = {
    'motivational': [
      'You just lifted MORE than before! Progress!',
      '+{increase} more than last time! You\'re growing!',
      'Heavier weight, STRONGER you!',
    ],
    'professional': [
      'Weight increase of {increase} noted. Progressive overload successful.',
      'Lifted more than previous session. Adaptation occurring.',
    ],
    'friendly': [
      'You lifted more! I\'m so proud of your progress!',
      'Look at you getting stronger! +{increase}!',
    ],
    'tough-love': [
      'Good. You finally added weight. Keep progressing.',
      '+{increase} more. That\'s how you improve.',
    ],
    'drill-sergeant': [
      'MORE WEIGHT! THAT\'S THE SPIRIT, SOLDIER!',
      '+{increase} ADDED! NOW WE\'RE MAKING PROGRESS!',
    ],
    'college-coach': [
      'More weight! NOW you\'re training like an athlete!',
      '+{increase}! That\'s what improvement looks like!',
    ],
    'zen-master': [
      'You carry more than before. Growth is happening.',
      'The weight increases as your spirit strengthens.',
    ],
    'hype-beast': [
      'MORE WEIGHT! YOU\'RE LEVELING UP!!!',
      '+{increase}! THE GAINS ARE REAL!!!',
    ],
    'scientist': [
      'Load increased by {increase}. Strength adaptation measurable.',
      'Progressive overload achieved: +{increase}.',
    ],
    'comedian': [
      'Heavier! The weights are now officially impressed!',
      '+{increase}! Your muscles got an upgrade!',
    ],
    'old-school': [
      'More iron! That\'s how champions train!',
      '+{increase}! Building real strength!',
    ],
  };

  // ============================================================
  // LAST SET MESSAGES
  // ============================================================
  static final Map<String, List<String>> _lastSetMessagesByStyle = {
    'motivational': [
      'Last set DONE! You conquered that exercise!',
      'Exercise complete! You\'re crushing this workout!',
      'That\'s a wrap on that one! Onward!',
    ],
    'professional': [
      'Exercise completed. Moving to next movement.',
      'Final set logged. Transition to next exercise.',
    ],
    'friendly': [
      'You finished that exercise! Great job!',
      'Done with that one! You\'re doing amazing!',
    ],
    'tough-love': [
      'Exercise done. Don\'t celebrate yet.',
      'One down. Stay focused on what\'s next.',
    ],
    'drill-sergeant': [
      'EXERCISE COMPLETE! ON TO THE NEXT BATTLE!',
      'THAT\'S DONE! NO TIME TO REST ON LAURELS!',
    ],
    'college-coach': [
      'Exercise finished! Don\'t get comfortable!',
      'Done! But we\'re not finished yet!',
    ],
    'zen-master': [
      'One chapter closes, another begins.',
      'The exercise ends. The journey continues.',
    ],
    'hype-beast': [
      'EXERCISE DONE! LET\'S GOOO!!!',
      'CRUSHED IT! NEXT ONE!!!',
    ],
    'scientist': [
      'Exercise completed. Muscle group stimulus achieved.',
      'Target muscle fatigued. Transitioning.',
    ],
    'comedian': [
      'That exercise is DONE! It didn\'t stand a chance!',
      'Exercise defeated! Next victim, please!',
    ],
    'old-school': [
      'Exercise done! Feel that pump!',
      'Finished! Chase the next pump!',
    ],
  };

  // ============================================================
  // MUSCLE GROUP SPECIFIC MESSAGES
  // ============================================================
  static final Map<String, Map<String, List<String>>> _muscleGroupMessages = {
    'chest': {
      'motivational': ['Chest is getting PUMPED!', 'Building that powerful chest!'],
      'drill-sergeant': ['CHEST DAY! BUILD THAT ARMOR!'],
      'college-coach': ['Get that chest BIGGER!'],
      'old-school': ['Feel that chest pump!'],
    },
    'back': {
      'motivational': ['Building a strong back!', 'Back is getting WIDE!'],
      'drill-sergeant': ['BACK WORKOUT! BUILD THAT V-TAPER!'],
      'college-coach': ['Strong back, strong athlete!'],
      'old-school': ['Width is coming! Feel it!'],
    },
    'legs': {
      'motivational': ['Leg day champion!', 'Building powerful legs!'],
      'drill-sergeant': ['LEG DAY! NO SKIPPING!'],
      'college-coach': ['Legs win championships!'],
      'old-school': ['Squats build champions!'],
      'comedian': ['Leg day: Making stairs your enemy since forever!'],
    },
    'arms': {
      'motivational': ['Arms are getting pumped!', 'Building those guns!'],
      'drill-sergeant': ['ARM DAY! BUILD THOSE WEAPONS!'],
      'college-coach': ['Get those arms BIGGER!'],
      'old-school': ['Feel that arm pump!'],
    },
    'shoulders': {
      'motivational': ['Boulder shoulders incoming!', 'Shoulders getting capped!'],
      'drill-sergeant': ['SHOULDER WORKOUT! BUILD THAT WIDTH!'],
      'college-coach': ['Wide shoulders, winning look!'],
      'old-school': ['Building those cannonball delts!'],
    },
    'core': {
      'motivational': ['Core getting stronger!', 'Abs are working!'],
      'drill-sergeant': ['CORE WORK! FOUNDATION OF STRENGTH!'],
      'college-coach': ['Strong core, strong athlete!'],
      'scientist': ['Core stability improving. Reduced injury risk.'],
    },
  };

  /// Messages organized by coaching style and intensity level
  static final Map<String, Map<String, List<String>>> _messagesByStyle = {
    // MOTIVATIONAL - Highly encouraging, celebrates wins
    'motivational': {
      'minimal': [
        'Good set.',
        'Keep going.',
        'Nice work.',
      ],
      'standard': [
        'Great job! Keep it up!',
        'You\'re doing amazing!',
        'That\'s the way!',
        'Solid effort!',
        'You\'ve got this!',
        'Strong set!',
      ],
      'high': [
        'Incredible work! You\'re on fire!',
        'That was AMAZING! Keep pushing!',
        'You\'re crushing it today!',
        'Nothing can stop you now!',
        'Your strength is showing!',
        'Beast mode activated!',
      ],
      'maximum': [
        'UNBELIEVABLE! You\'re a MACHINE!',
        'ABSOLUTELY CRUSHING IT! You\'re unstoppable!',
        'LEGENDARY performance! Keep that energy!',
        'You\'re DOMINATING this workout!',
        'PHENOMENAL! This is YOUR moment!',
        'Pure EXCELLENCE! Nothing can hold you back!',
      ],
    },

    // PROFESSIONAL - Efficient, straightforward, fact-focused
    'professional': {
      'minimal': [
        'Set complete.',
        'Rest and recover.',
        'Prepare for next set.',
      ],
      'standard': [
        'Good form on that set.',
        'Rest period initiated.',
        'Maintain your breathing.',
        'Recovery in progress.',
        'Excellent execution.',
        'Set logged successfully.',
      ],
      'high': [
        'Outstanding technique. Stay focused.',
        'Excellent performance metrics.',
        'Your form was textbook perfect.',
        'Impressive work capacity today.',
        'Strong neural recruitment pattern.',
        'Optimal muscle engagement observed.',
      ],
      'maximum': [
        'Exceptional performance. Top percentile.',
        'Your output exceeds baseline significantly.',
        'Peak performance achieved. Maintain intensity.',
        'Remarkable consistency in your execution.',
        'Elite-level work capacity demonstrated.',
        'Your training metrics are impressive.',
      ],
    },

    // FRIENDLY - Warm, conversational, caring
    'friendly': {
      'minimal': [
        'Nice one!',
        'Take a breather.',
        'You did it!',
      ],
      'standard': [
        'Hey, that was really good!',
        'Awesome job, friend!',
        'You\'re doing so well!',
        'I\'m proud of you!',
        'Keep being amazing!',
        'Look at you go!',
      ],
      'high': [
        'Wow, you\'re really bringing it today!',
        'I love seeing you work this hard!',
        'You should be SO proud of yourself!',
        'This is what dedication looks like!',
        'You\'re inspiring me right now!',
        'Your effort is truly wonderful!',
      ],
      'maximum': [
        'I\'m literally cheering for you right now!',
        'You are absolutely AMAZING, you know that?',
        'My heart is so full watching you crush this!',
        'You\'re the definition of determination!',
        'I couldn\'t be more proud of you!',
        'You\'re a total superstar!',
      ],
    },

    // TOUGH-LOVE - Direct, challenging, honest
    'tough-love': {
      'minimal': [
        'Done.',
        'Next.',
        'Move on.',
      ],
      'standard': [
        'Acceptable. You can do better.',
        'That was fine. Push harder next set.',
        'I\'ve seen what you\'re capable of.',
        'Don\'t coast. Stay hungry.',
        'Good, but not your best.',
        'Results require more effort.',
      ],
      'high': [
        'NOW that\'s more like it!',
        'There\'s the fighter I know!',
        'That\'s what I expect from you!',
        'See what happens when you try?',
        'THAT\'S the intensity you need!',
        'You proved me right. Keep it up.',
      ],
      'maximum': [
        'FINALLY! That\'s what I\'m talking about!',
        'THAT is your true potential!',
        'You just proved you\'re a warrior!',
        'I knew you had it in you!',
        'THAT\'S the champion mentality!',
        'Now THAT deserves respect!',
      ],
    },

    // DRILL-SERGEANT - Intense, demanding, ALL CAPS
    'drill-sergeant': {
      'minimal': [
        'REST!',
        'RECOVER!',
        'BREATHE!',
      ],
      'standard': [
        'REST UP, SOLDIER!',
        'CATCH YOUR BREATH!',
        'HYDRATE AND PREPARE!',
        'DON\'T GET COMFORTABLE!',
        'STAY SHARP!',
        'REST IS EARNED!',
      ],
      'high': [
        'OUTSTANDING EFFORT, RECRUIT!',
        'THAT\'S HOW IT\'S DONE!',
        'NOW THAT\'S DISCIPLINE!',
        'PAIN IS WEAKNESS LEAVING!',
        'YOU\'RE SHOWING REAL GRIT!',
        'I\'M SEEING A WARRIOR!',
      ],
      'maximum': [
        'THAT WAS ABSOLUTELY SAVAGE!',
        'YOU JUST EARNED MY RESPECT!',
        'LEGENDARY PERFORMANCE, SOLDIER!',
        'THAT\'S WARRIOR MENTALITY!',
        'NO EXCUSES, JUST RESULTS!',
        'YOU\'RE BUILT DIFFERENT!',
      ],
    },

    // ZEN-MASTER - Calm, peaceful, philosophical
    'zen-master': {
      'minimal': [
        'Breathe.',
        'Be present.',
        'Find stillness.',
      ],
      'standard': [
        'Like water, find your flow.',
        'The mountain stands patient.',
        'Strength grows from within.',
        'Each breath brings renewal.',
        'Progress is a journey, not a race.',
        'Honor your body\'s wisdom.',
      ],
      'high': [
        'Your spirit shines through your effort.',
        'The river does not force, yet it shapes stone.',
        'In stillness, we find our greatest power.',
        'Your dedication speaks to your inner strength.',
        'The bamboo bends but does not break.',
        'You are becoming who you were meant to be.',
      ],
      'maximum': [
        'The universe celebrates your commitment.',
        'You have touched something profound within.',
        'Your energy radiates transformation.',
        'This is the moment of your becoming.',
        'The master within you has awakened.',
        'You are one with your highest self.',
      ],
    },

    // HYPE-BEAST - HYPED! Everything is AMAZING
    'hype-beast': {
      'minimal': [
        'Nice!',
        'Cool!',
        'Solid!',
      ],
      'standard': [
        'YO that was FIRE!',
        'LET\'S GOOO!',
        'VIBES are immaculate!',
        'You\'re KILLING IT!',
        'This energy is EVERYTHING!',
        'SO HYPE right now!',
      ],
      'high': [
        'BROOOO that was INSANE!',
        'I\'M SO HYPE FOR YOU RN!',
        'THIS IS YOUR MOMENT!',
        'THE ENERGY IS UNMATCHED!',
        'YOU\'RE ABSOLUTELY GOATED!',
        'MAIN CHARACTER ENERGY!',
      ],
      'maximum': [
        'YOOOOOO THAT WAS LEGENDARY!!!',
        'I LITERALLY CAN\'T EVEN RN!!!',
        'YOU ARE ON ANOTHER LEVEL!!!',
        'THIS IS PEAK PERFORMANCE!!!',
        'GREATEST OF ALL TIME VIBES!!!',
        'ABSOLUTELY ICONIC!!!',
      ],
    },

    // SCIENTIST - Analytical, data-driven
    'scientist': {
      'minimal': [
        'Set recorded.',
        'Data logged.',
        'Rest initiated.',
      ],
      'standard': [
        'Optimal recovery period starting.',
        'Studies show rest improves next set by 15%.',
        'Muscle protein synthesis activated.',
        'ATP regeneration in progress.',
        'Cardiovascular recovery underway.',
        'Neural pathways consolidating.',
      ],
      'high': [
        'Impressive force output recorded.',
        'Your performance metrics are above baseline.',
        'Research indicates you\'re in the growth zone.',
        'Excellent mind-muscle connection observed.',
        'Your cortisol-to-testosterone ratio is optimal.',
        'Neuromuscular efficiency at 94th percentile.',
      ],
      'maximum': [
        'Remarkable: You\'ve exceeded predicted max output.',
        'Your performance data is statistically exceptional.',
        'Analysis shows elite-level muscle recruitment.',
        'Peak hypertrophic stimulus achieved.',
        'Your training response is in the top 1%.',
        'Extraordinary adaptation potential demonstrated.',
      ],
    },

    // COMEDIAN - Funny, fitness puns
    'comedian': {
      'minimal': [
        'Not bad!',
        'Nice lift!',
        'Keep it up!',
      ],
      'standard': [
        'That set really lifted my spirits!',
        'You\'re reps-olutionary!',
        'Are you a magician? That set disappeared!',
        'That was un-FLEX-pected!',
        'You\'re on a roll... unlike your foam roller.',
        'Muscle memory? More like muscle AMAZING!',
      ],
      'high': [
        'Holy swoly, that was impressive!',
        'You\'re absolutely SHREDDING it!',
        'That set was no joke... unlike me!',
        'You\'ve got more gains than my stock portfolio!',
        'Dumbbell? More like SMART-bell after that!',
        'You\'re benching expectations!',
      ],
      'maximum': [
        'Someone call the gym police, that set was CRIMINAL!',
        'Are those muscles or are you smuggling boulders?!',
        'That was so good, even the weights are impressed!',
        'You didn\'t just crush it, you OBLITERATED it!',
        'Breaking news: Local hero destroys workout!',
        'Scientists are baffled by your incredible performance!',
      ],
    },

    // OLD-SCHOOL - Classic bodybuilding vibes
    'old-school': {
      'minimal': [
        'Good pump.',
        'Keep lifting.',
        'Stay strong.',
      ],
      'standard': [
        'Solid set, bro!',
        'That\'s how you get swole!',
        'Feel that pump!',
        'Classic iron work!',
        'Building that mass!',
        'Real gym work right there!',
      ],
      'high': [
        'Now THAT\'S old school iron!',
        'Arnold would be proud!',
        'You\'re chasing that pump!',
        'Building championship physique!',
        'That\'s hardcore dedication!',
        'Golden era intensity!',
      ],
      'maximum': [
        'LEGENDARY lift, my friend!',
        'You\'re in the ZONE!',
        'That\'s CHAMPION mentality!',
        'Hall of fame performance!',
        'You\'re built for greatness!',
        'True iron warrior!',
      ],
    },

    // COLLEGE-COACH - Intense college athletics coach that scolds
    'college-coach': {
      'minimal': [
        'Adequate.',
        'Next.',
        'Move it.',
      ],
      'standard': [
        'Is that ALL you got?!',
        'My grandmother lifts more than that!',
        'You call that a set?!',
        'Did you come here to work or chat?!',
        'I\'ve seen better effort in junior varsity!',
        'You want a scholarship with THAT?!',
      ],
      'high': [
        'NOW you\'re showing some heart!',
        'THAT\'S what I recruited you for!',
        'See what happens when you actually TRY?!',
        'Keep that up or you\'re running laps!',
        'FINALLY showing some championship effort!',
        'That\'s more like it! Don\'t get comfortable!',
      ],
      'maximum': [
        'THAT\'S MY ATHLETE RIGHT THERE!',
        'NOW you\'re playing like you WANT it!',
        'Championship performance! Keep that ENERGY!',
        'THAT\'S why you\'re on this team!',
        'National championship effort! DOMINATE!',
        'You just earned your spot! NOW KEEP IT!',
      ],
    },
  };

  /// Tips organized by coaching style
  static final Map<String, List<String>> _tipsByStyle = {
    'motivational': [
      'Remember to breathe deeply during rest!',
      'Visualize your next set being perfect!',
      'You\'re one set closer to your goals!',
      'Stay hydrated for peak performance!',
      'Your body is getting stronger with every rep!',
    ],
    'professional': [
      'Maintain proper hydration for optimal performance.',
      'Focus on controlled breathing during recovery.',
      'Mental preparation improves the next set.',
      'Proper form prevents injury and maximizes gains.',
      'Rest periods optimize muscle recovery.',
    ],
    'friendly': [
      'Don\'t forget to drink some water!',
      'Take nice deep breaths, you\'ve earned it!',
      'Think about how great you\'ll feel after!',
      'You\'re doing something amazing for yourself!',
      'Every workout counts, including this one!',
    ],
    'tough-love': [
      'Use this rest to get your head right.',
      'Don\'t let your focus drop now.',
      'Prepare mentally for the next challenge.',
      'Champions are made in moments like these.',
      'Rest is strategy, not weakness.',
    ],
    'drill-sergeant': [
      'HYDRATE! A DEHYDRATED SOLDIER IS A WEAK SOLDIER!',
      'USE THIS TIME WISELY!',
      'MENTAL PREPARATION IS KEY!',
      'FOCUS ON THE MISSION AHEAD!',
      'DISCIPLINE STARTS WITH RECOVERY!',
    ],
    'zen-master': [
      'Let your breath guide your recovery.',
      'In rest, we find preparation.',
      'The body heals when the mind is still.',
      'Each moment of rest is a gift.',
      'Honor this time of renewal.',
    ],
    'hype-beast': [
      'Stay LOCKED IN!',
      'The grind never stops!',
      'We\'re just getting STARTED!',
      'Next set is gonna be FIRE!',
      'Keep that energy UP!',
    ],
    'scientist': [
      'Studies show 90-120 seconds optimizes hypertrophy.',
      'Hydration improves performance by up to 25%.',
      'Mental rehearsal activates motor cortex.',
      'Deep breathing accelerates ATP regeneration.',
      'Proper rest reduces injury risk by 40%.',
    ],
    'comedian': [
      'Why did the dumbbell go to therapy? Too much pressure!',
      'Rest day: When your muscles file a complaint!',
      'My favorite machine at the gym? The vending machine!',
      'I don\'t sweat, I sparkle aggressively!',
      'Leg day: The reason we have elevators!',
    ],
    'old-school': [
      'Squeeze the muscle at the top!',
      'Feel the pump, chase the pump!',
      'Mind-muscle connection is everything!',
      'No shortcuts to greatness!',
      'Leave nothing in the tank!',
    ],
    'college-coach': [
      'You better be ready for the next set!',
      'Don\'t just stand there - FOCUS!',
      'Champions prepare during rest, not rest during rest!',
      'I didn\'t bring you here to take breaks!',
      'Next set better be your BEST set!',
    ],
  };
}
