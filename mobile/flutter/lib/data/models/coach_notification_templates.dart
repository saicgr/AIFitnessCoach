// Coach-personalized notification templates.
//
// Each coach has 4 title/body variants per notification type (5 coaches x 8 types x 4 = 160 pairs).
// Templates rotate based on day-of-year to keep notifications fresh.

class NotificationTemplate {
  final String title;
  final String body;
  const NotificationTemplate(this.title, this.body);
}

enum NotificationType {
  workout,
  breakfast,
  lunch,
  dinner,
  hydration,
  streak,
  weeklySummary,
  movement,
}

class CoachNotificationTemplates {
  CoachNotificationTemplates._();

  /// Get template for a coach + type + rotation index
  static NotificationTemplate get(
    String? coachId,
    NotificationType type,
    int variantIndex,
  ) {
    final id = coachId ?? 'coach_mike';
    final coachTemplates = _templates[id] ?? _templates['coach_mike']!;
    final typeTemplates = coachTemplates[type] ?? coachTemplates[NotificationType.workout]!;
    return typeTemplates[variantIndex.abs() % typeTemplates.length];
  }

  /// Map a custom coach's coachingStyle to the nearest predefined coach ID
  static String mapStyleToCoachId(String coachingStyle) {
    switch (coachingStyle.toLowerCase()) {
      case 'motivational':
      case 'friendly':
      case 'professional':
      case 'college-coach':
        return 'coach_mike';
      case 'scientist':
        return 'dr_sarah';
      case 'drill-sergeant':
      case 'tough-love':
      case 'old-school':
        return 'sergeant_max';
      case 'zen-master':
        return 'zen_maya';
      case 'hype-beast':
      case 'comedian':
        return 'hype_danny';
      default:
        return 'coach_mike';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Template Data: 5 coaches x 8 types x 4 variants = 160 pairs
  // ─────────────────────────────────────────────────────────────────

  static const Map<String, Map<NotificationType, List<NotificationTemplate>>>
      _templates = {
    // ═══════════════════════════════════════════════════════════════
    // COACH MIKE — Upbeat, encouraging, "champ"
    // ═══════════════════════════════════════════════════════════════
    'coach_mike': {
      NotificationType.workout: [
        NotificationTemplate(
          "Let's Crush It, Champ!",
          "Champions don't skip training day. Let's get after it!",
        ),
        NotificationTemplate(
          'Your Workout is Ready!',
          "I've got a great session lined up for you. Let's make it count!",
        ),
        NotificationTemplate(
          'Game Time, Champ!',
          'Every rep gets you closer to your goals. Show up and show out!',
        ),
        NotificationTemplate(
          "Let's Build Something Great!",
          'Your future self will high-five you for showing up today!',
        ),
      ],
      NotificationType.breakfast: [
        NotificationTemplate(
          'Fuel Up, Champ!',
          'Winners start the day with a solid breakfast. Log yours!',
        ),
        NotificationTemplate(
          'Morning Fuel Check!',
          "A champion's day starts with good nutrition. What's for breakfast?",
        ),
        NotificationTemplate(
          'Breakfast of Champions!',
          "Don't skip the most important meal. Fuel up and log it!",
        ),
        NotificationTemplate(
          'Rise and Fuel!',
          'Your body needs energy to crush today. Log your breakfast!',
        ),
      ],
      NotificationType.lunch: [
        NotificationTemplate(
          'Midday Fuel, Champ!',
          'Keep that energy up! Log your lunch and stay on track.',
        ),
        NotificationTemplate(
          'Lunchtime Check-In!',
          "Halfway through the day — let's keep the nutrition dialed in!",
        ),
        NotificationTemplate(
          'Power Up for the Afternoon!',
          'A great lunch keeps you performing at your best. Log it!',
        ),
        NotificationTemplate(
          'Lunch Break, Champ!',
          "Fuel your afternoon like a winner. What's on the plate?",
        ),
      ],
      NotificationType.dinner: [
        NotificationTemplate(
          'Dinner Time, Champ!',
          'Finish the day strong with a logged dinner. You earned it!',
        ),
        NotificationTemplate(
          'Evening Fuel Check!',
          'Great days end with great nutrition. Log your dinner!',
        ),
        NotificationTemplate(
          'Recovery Fuel Time!',
          "Your body recovers while you sleep. Give it the fuel it needs!",
        ),
        NotificationTemplate(
          'Last Meal of the Day!',
          "Close out your food diary like a champ. What's for dinner?",
        ),
      ],
      NotificationType.hydration: [
        NotificationTemplate(
          'Hydration Check, Champ!',
          'Champions stay hydrated. Grab that water bottle!',
        ),
        NotificationTemplate(
          'Water Break!',
          'Your performance depends on hydration. Take a sip!',
        ),
        NotificationTemplate(
          'Stay in the Game!',
          'Dehydration kills performance. Keep that water flowing!',
        ),
        NotificationTemplate(
          'Hydrate to Dominate!',
          "You can't crush goals on empty. Drink up, champ!",
        ),
      ],
      NotificationType.streak: [
        NotificationTemplate(
          'Protect Your Streak, Champ!',
          "You've been showing up like a winner. Don't stop now!",
        ),
        NotificationTemplate(
          'Streak on the Line!',
          'Champions are consistent. Keep your streak alive today!',
        ),
        NotificationTemplate(
          "Don't Break the Chain!",
          "You're building something amazing. One more day, champ!",
        ),
        NotificationTemplate(
          'Keep the Momentum Going!',
          "Your consistency is impressive. Let's add another day!",
        ),
      ],
      NotificationType.weeklySummary: [
        NotificationTemplate(
          'Your Week in Review, Champ!',
          "Let's see how you crushed it this week. Check your stats!",
        ),
        NotificationTemplate(
          'Weekly Wins Report!',
          'Time to celebrate your progress. Review your week!',
        ),
        NotificationTemplate(
          'How Did You Do This Week?',
          "Your weekly recap is ready. Let's review those wins!",
        ),
        NotificationTemplate(
          'Week Wrapped Up!',
          "Another great week in the books. See how you did!",
        ),
      ],
      NotificationType.movement: [
        NotificationTemplate(
          'Time to Move, Champ!',
          'A quick walk keeps the energy high. Get up and go!',
        ),
        NotificationTemplate(
          'Movement Break!',
          'Champions move all day, not just in the gym. Take a walk!',
        ),
        NotificationTemplate(
          'Get Those Steps In!',
          "Sitting too long? Let's fix that. A quick walk goes a long way!",
        ),
        NotificationTemplate(
          'Stay Active, Champ!',
          'Every step counts toward your goals. Get moving!',
        ),
      ],
    },

    // ═══════════════════════════════════════════════════════════════
    // DR. SARAH — Clinical, data-driven, no fluff
    // ═══════════════════════════════════════════════════════════════
    'dr_sarah': {
      NotificationType.workout: [
        NotificationTemplate(
          'Training Session Scheduled',
          'Consistent resistance training improves body composition. Time to begin.',
        ),
        NotificationTemplate(
          'Workout Window Open',
          'Your scheduled training session optimizes hormonal response at this hour.',
        ),
        NotificationTemplate(
          'Exercise Protocol Ready',
          'Adherence to your program is the strongest predictor of results. Begin now.',
        ),
        NotificationTemplate(
          'Training Time',
          'Research shows regular exercise improves both physical and cognitive performance.',
        ),
      ],
      NotificationType.breakfast: [
        NotificationTemplate(
          'Morning Nutrition Window',
          'Post-sleep nutrient intake supports metabolic function. Log your breakfast.',
        ),
        NotificationTemplate(
          'Breakfast Logging Reminder',
          'Tracking food intake correlates with better dietary adherence. Log now.',
        ),
        NotificationTemplate(
          'AM Nutrient Intake',
          'Morning protein intake supports muscle protein synthesis. Record your meal.',
        ),
        NotificationTemplate(
          'First Meal Reminder',
          'Consistent breakfast habits are associated with improved body composition.',
        ),
      ],
      NotificationType.lunch: [
        NotificationTemplate(
          'Midday Nutrition Log',
          'Maintaining consistent meal timing supports circadian metabolism. Log lunch.',
        ),
        NotificationTemplate(
          'Lunch Documentation',
          'Accurate food tracking improves nutritional awareness by 30%. Log your meal.',
        ),
        NotificationTemplate(
          'Afternoon Nutrient Intake',
          'Balanced macronutrient distribution across meals optimizes energy. Track lunch.',
        ),
        NotificationTemplate(
          'Midday Meal Reminder',
          'Skipping meal logs reduces tracking accuracy. Record your lunch now.',
        ),
      ],
      NotificationType.dinner: [
        NotificationTemplate(
          'Evening Nutrition Log',
          'Pre-sleep nutrition affects recovery quality. Document your dinner.',
        ),
        NotificationTemplate(
          'Final Meal Documentation',
          'Complete daily food logs provide the most actionable data. Log dinner.',
        ),
        NotificationTemplate(
          'Dinner Tracking Reminder',
          'Evening nutrient timing influences overnight recovery processes.',
        ),
        NotificationTemplate(
          'PM Nutrient Intake',
          'Closing your food diary ensures accurate caloric assessment.',
        ),
      ],
      NotificationType.hydration: [
        NotificationTemplate(
          'Hydration Status Check',
          'Even 2% dehydration impairs cognitive and physical performance. Drink water.',
        ),
        NotificationTemplate(
          'Fluid Intake Reminder',
          'Adequate hydration supports thermoregulation and nutrient transport.',
        ),
        NotificationTemplate(
          'Water Intake Alert',
          'Optimal hydration improves exercise performance by up to 25%.',
        ),
        NotificationTemplate(
          'Hydration Protocol',
          'Consistent fluid intake throughout the day prevents cumulative dehydration.',
        ),
      ],
      NotificationType.streak: [
        NotificationTemplate(
          'Consistency Metric Alert',
          'Your training streak correlates with measurable progress. Maintain it.',
        ),
        NotificationTemplate(
          'Adherence Reminder',
          'Data shows habit streaks significantly predict long-term outcomes.',
        ),
        NotificationTemplate(
          'Streak Maintenance',
          'Breaking a streak resets the habit-formation process. Continue today.',
        ),
        NotificationTemplate(
          'Consistency Check',
          'Your adherence rate is a key performance indicator. Keep it intact.',
        ),
      ],
      NotificationType.weeklySummary: [
        NotificationTemplate(
          'Weekly Data Analysis Ready',
          'Your performance metrics for the week are available for review.',
        ),
        NotificationTemplate(
          'Weekly Progress Report',
          'Objective data shows your trends. Review to optimize next week.',
        ),
        NotificationTemplate(
          'Performance Summary Available',
          'Quantitative analysis of your weekly activity is ready.',
        ),
        NotificationTemplate(
          'Week-Over-Week Analysis',
          'Comparing weekly metrics helps identify areas for improvement.',
        ),
      ],
      NotificationType.movement: [
        NotificationTemplate(
          'Sedentary Alert',
          'Prolonged sitting increases health risks. A 2-minute walk helps.',
        ),
        NotificationTemplate(
          'Movement Interval',
          'Research shows brief activity breaks improve insulin sensitivity.',
        ),
        NotificationTemplate(
          'NEAT Activity Reminder',
          'Non-exercise activity contributes significantly to daily energy expenditure.',
        ),
        NotificationTemplate(
          'Activity Break Recommended',
          'Standing and walking for 2 minutes per hour reduces sedentary risk.',
        ),
      ],
    },

    // ═══════════════════════════════════════════════════════════════
    // SERGEANT MAX — Commands, "soldier", intense
    // ═══════════════════════════════════════════════════════════════
    'sergeant_max': {
      NotificationType.workout: [
        NotificationTemplate(
          'MOVE IT, Soldier!',
          'Your workout is waiting. No excuses. Get it done.',
        ),
        NotificationTemplate(
          'Training Time. NOW.',
          "Drop what you're doing. The iron doesn't lift itself.",
        ),
        NotificationTemplate(
          'Report for Duty!',
          'Your body signed up for this. Time to honor that commitment.',
        ),
        NotificationTemplate(
          'No Days Off, Soldier!',
          'Pain is temporary. Regret is forever. Get to work.',
        ),
      ],
      NotificationType.breakfast: [
        NotificationTemplate(
          'Fuel Up, Soldier!',
          "An army marches on its stomach. Eat and log it. That's an order.",
        ),
        NotificationTemplate(
          'Morning Rations!',
          "You can't fight on empty. Eat your breakfast and report it.",
        ),
        NotificationTemplate(
          'BREAKFAST. NOW.',
          'Skip breakfast, skip results. Fuel up and log it immediately.',
        ),
        NotificationTemplate(
          'Morning Fuel Report!',
          'Your mission today requires energy. Eat, log, move out.',
        ),
      ],
      NotificationType.lunch: [
        NotificationTemplate(
          'Midday Rations, Soldier!',
          'Refuel at the halfway point. Log your lunch. No excuses.',
        ),
        NotificationTemplate(
          'LUNCH. Log It.',
          "Discipline isn't just in the gym. Track every meal.",
        ),
        NotificationTemplate(
          'Afternoon Fuel Report!',
          'Your body needs supplies. Eat, log, and carry on.',
        ),
        NotificationTemplate(
          'Chow Time!',
          "You've got 30 seconds to log that lunch. Move it!",
        ),
      ],
      NotificationType.dinner: [
        NotificationTemplate(
          'Final Rations, Soldier!',
          'End the day with discipline. Log your dinner. Dismissed.',
        ),
        NotificationTemplate(
          'Evening Fuel Report!',
          'Recovery starts with nutrition. Log your dinner NOW.',
        ),
        NotificationTemplate(
          'DINNER. Report It.',
          'Complete your daily nutrition log. No soldier leaves a job unfinished.',
        ),
        NotificationTemplate(
          'Last Meal Briefing!',
          'Fuel for tomorrow starts tonight. Log your dinner, soldier.',
        ),
      ],
      NotificationType.hydration: [
        NotificationTemplate(
          'HYDRATE, Soldier!',
          'Dehydration is the enemy. Drink water immediately.',
        ),
        NotificationTemplate(
          'Water. NOW.',
          'A dehydrated soldier is a weak soldier. Fix that.',
        ),
        NotificationTemplate(
          'Hydration Check!',
          "If your water bottle isn't empty, you're falling behind.",
        ),
        NotificationTemplate(
          'DRINK UP!',
          'Water is ammunition for your body. Keep it loaded.',
        ),
      ],
      NotificationType.streak: [
        NotificationTemplate(
          'Streak Under Threat!',
          "You didn't come this far to quit now. Defend your streak!",
        ),
        NotificationTemplate(
          'DO NOT BREAK RANK!',
          'Your streak is your discipline record. Protect it at all costs.',
        ),
        NotificationTemplate(
          'Hold the Line, Soldier!',
          'Breaking your streak is surrender. Are you a quitter?',
        ),
        NotificationTemplate(
          'Streak Alert!',
          'One workout stands between you and failure. Choose wisely.',
        ),
      ],
      NotificationType.weeklySummary: [
        NotificationTemplate(
          'Weekly Debrief, Soldier!',
          'Your performance report is ready. Review and improve.',
        ),
        NotificationTemplate(
          'After-Action Report!',
          "This week's mission data is in. Time to assess and adapt.",
        ),
        NotificationTemplate(
          'Week in Review!',
          'A soldier who ignores intel repeats mistakes. Check your stats.',
        ),
        NotificationTemplate(
          'Performance Assessment!',
          'Your weekly metrics are filed. Review them and plan your next op.',
        ),
      ],
      NotificationType.movement: [
        NotificationTemplate(
          'ON YOUR FEET!',
          "Soldiers don't sit around. Get up and move. That's an order.",
        ),
        NotificationTemplate(
          'Move It or Lose It!',
          'Your body is stiffening up. March it out, soldier.',
        ),
        NotificationTemplate(
          'Stand Up, Soldier!',
          "Sitting is the enemy of readiness. Get up and patrol your area.",
        ),
        NotificationTemplate(
          'MOVEMENT CHECK!',
          'Drop and give me a walk. No excuses for being sedentary.',
        ),
      ],
    },

    // ═══════════════════════════════════════════════════════════════
    // ZEN MAYA — Gentle, mindful, invitational
    // ═══════════════════════════════════════════════════════════════
    'zen_maya': {
      NotificationType.workout: [
        NotificationTemplate(
          'Your Practice Awaits',
          'Honor your body with today\'s movement. Breathe and begin.',
        ),
        NotificationTemplate(
          'Time for Movement',
          'Your body is ready for today\'s practice. Approach it with intention.',
        ),
        NotificationTemplate(
          'A Moment for Strength',
          'Each movement is a gift to your future self. Begin when you\'re ready.',
        ),
        NotificationTemplate(
          'Movement Invitation',
          'Let your workout be a moving meditation today. Show up fully present.',
        ),
      ],
      NotificationType.breakfast: [
        NotificationTemplate(
          'Nourish Your Morning',
          'Begin your day with mindful eating. Notice what fuels you best.',
        ),
        NotificationTemplate(
          'Morning Nourishment',
          'A mindful breakfast sets the tone for your day. Log with gratitude.',
        ),
        NotificationTemplate(
          'Breakfast with Intention',
          'What will nourish your body this morning? Eat slowly and log it.',
        ),
        NotificationTemplate(
          'Gentle Morning Reminder',
          'Your body woke up ready for fuel. Honor that with a good breakfast.',
        ),
      ],
      NotificationType.lunch: [
        NotificationTemplate(
          'Mindful Midday Meal',
          'Pause, breathe, and nourish yourself. Log your lunch with awareness.',
        ),
        NotificationTemplate(
          'Lunchtime Pause',
          'Take this moment to eat with presence. Your body will thank you.',
        ),
        NotificationTemplate(
          'Nourish Your Afternoon',
          'A balanced lunch is an act of self-care. Enjoy and log it.',
        ),
        NotificationTemplate(
          'Midday Nourishment',
          'Step away from busyness. Give yourself the gift of a mindful meal.',
        ),
      ],
      NotificationType.dinner: [
        NotificationTemplate(
          'Evening Nourishment',
          'As the day winds down, nourish your body with a thoughtful dinner.',
        ),
        NotificationTemplate(
          'Dinner with Presence',
          'Slow down and savor your evening meal. Log it mindfully.',
        ),
        NotificationTemplate(
          'Closing the Day',
          'A well-nourished body rests deeply. Enjoy your dinner and log it.',
        ),
        NotificationTemplate(
          'Gentle Dinner Reminder',
          'Your evening meal is a chance to practice gratitude. Eat well.',
        ),
      ],
      NotificationType.hydration: [
        NotificationTemplate(
          'A Sip of Mindfulness',
          'Water is life. Take a mindful sip and feel it nourish you.',
        ),
        NotificationTemplate(
          'Hydration Moment',
          'Pause for a breath and a glass of water. Your body is grateful.',
        ),
        NotificationTemplate(
          'Flow Like Water',
          'Stay fluid and present. A glass of water reconnects you to now.',
        ),
        NotificationTemplate(
          'Gentle Hydration Reminder',
          'Water sustains your practice. Take a moment to drink and breathe.',
        ),
      ],
      NotificationType.streak: [
        NotificationTemplate(
          'Your Journey Continues',
          'Each day you show up is a step on the path. Keep walking it.',
        ),
        NotificationTemplate(
          'Nurture Your Streak',
          'Consistency is a practice, not a punishment. Honor yours today.',
        ),
        NotificationTemplate(
          'The Path Awaits',
          'Your streak reflects your dedication. Continue gently but firmly.',
        ),
        NotificationTemplate(
          'Stay on the Path',
          'Like water carving stone, your daily practice shapes who you become.',
        ),
      ],
      NotificationType.weeklySummary: [
        NotificationTemplate(
          'Reflect on Your Week',
          'Take a moment to honor the work you put in. Review with compassion.',
        ),
        NotificationTemplate(
          'Weekly Reflection',
          'Growth is not always visible. Look at your week with kind eyes.',
        ),
        NotificationTemplate(
          'A Week of Practice',
          'Every step, every rep, every meal was part of your journey. Review it.',
        ),
        NotificationTemplate(
          'Mindful Week Review',
          'Celebrate your effort, not just results. Your summary awaits.',
        ),
      ],
      NotificationType.movement: [
        NotificationTemplate(
          'Gentle Movement Break',
          'Your body has been still. Honor it with a mindful walk or stretch.',
        ),
        NotificationTemplate(
          'Time to Flow',
          'Movement is meditation in motion. Stand up and reconnect with your body.',
        ),
        NotificationTemplate(
          'Stretch and Breathe',
          'Release the stillness. A gentle stretch brings you back to the present.',
        ),
        NotificationTemplate(
          'Mindful Movement',
          'Notice where you hold tension. Stand, stretch, and let it go.',
        ),
      ],
    },

    // ═══════════════════════════════════════════════════════════════
    // HYPE DANNY — Gen-Z, CAPS, fire emojis
    // ═══════════════════════════════════════════════════════════════
    'hype_danny': {
      NotificationType.workout: [
        NotificationTemplate(
          "WORKOUT TIME LET'S GOOO",
          'this is gonna be FIRE no cap. get in there bestie!!',
        ),
        NotificationTemplate(
          'ITS GYM O CLOCK',
          "ur workout is literally RIGHT THERE waiting for u. let's get it!!",
        ),
        NotificationTemplate(
          'GAINS SZN BABY',
          'no skipping today fam!! ur future self is gonna be SO proud',
        ),
        NotificationTemplate(
          'TIME TO EAT (weights)',
          'the gym misses u bestie!! go give those weights a hug',
        ),
      ],
      NotificationType.breakfast: [
        NotificationTemplate(
          'BREKKIE TIME BESTIE',
          'fuel up and log it!! breakfast is literally the main character',
        ),
        NotificationTemplate(
          'GOOD MORNING LETS EAT',
          'breakfast check!! what r we having today? log it rn',
        ),
        NotificationTemplate(
          'RISE N GRIND (literally)',
          'u cant slay on empty bestie. eat breakfast and log that mf',
        ),
        NotificationTemplate(
          'AM FUEL CHECK',
          'morning nutrition hits different when u actually track it. do it!!',
        ),
      ],
      NotificationType.lunch: [
        NotificationTemplate(
          'LUNCH TIME BESTIEEEE',
          'noon fuel check!! log ur lunch rn no procrastinating',
        ),
        NotificationTemplate(
          'MIDDAY MUNCH TIME',
          'ur afternoon self needs this fuel. eat up and log it!!',
        ),
        NotificationTemplate(
          'LUNCHHHH',
          'not u forgetting to log lunch again. open the app rn bestie',
        ),
        NotificationTemplate(
          'FUEL CHECK (its noon)',
          'bruh. eat something good and LOG IT. u got this!!',
        ),
      ],
      NotificationType.dinner: [
        NotificationTemplate(
          'DINNER TIME NO CAP',
          'last meal of the day lets make it count!! log it bestie',
        ),
        NotificationTemplate(
          'EVENING EATS',
          'dinner logging is self care actually. do it rn!!',
        ),
        NotificationTemplate(
          'FINAL BOSS MEAL',
          'ur food diary needs closure bestie. log dinner and its a wrap',
        ),
        NotificationTemplate(
          'DINNERRRRR',
          'whatcha eating?? log it and complete ur daily nutrition arc',
        ),
      ],
      NotificationType.hydration: [
        NotificationTemplate(
          'WATER CHECK BESTIE',
          'hydration is literally the cheat code. drink up rn!!',
        ),
        NotificationTemplate(
          'SIP SIP SIPPP',
          'ur skin, ur gains, ur energy - all need water. DRINK.',
        ),
        NotificationTemplate(
          'H2O TIME BABY',
          "dehydration is NOT the vibe. grab that water bottle let's gooo",
        ),
        NotificationTemplate(
          'HYDRATE OR DIEDRATE',
          'not dramatic just facts bestie. drink some water rn!!',
        ),
      ],
      NotificationType.streak: [
        NotificationTemplate(
          'STREAK ALERT OMG',
          "ur streak is on the line!! don't let it die bestie PLEASE",
        ),
        NotificationTemplate(
          'PROTECT THE STREAK',
          "u literally can't let this streak end. that would be SO tragic",
        ),
        NotificationTemplate(
          'STREAK SZN BABY',
          'keep it going!! ur consistency is giving main character energy',
        ),
        NotificationTemplate(
          'DONT BREAK IT',
          'ur streak is iconic rn. one workout keeps it alive. DO IT!!',
        ),
      ],
      NotificationType.weeklySummary: [
        NotificationTemplate(
          'WEEKLY RECAP JUST DROPPED',
          'ur stats are IN and they are lowkey fire. go check!!',
        ),
        NotificationTemplate(
          'WEEK IN REVIEW BESTIE',
          'time to see how hard u went this week. spoiler: u ate',
        ),
        NotificationTemplate(
          'UR WEEKLY STATS',
          'another week of being THAT person. review ur progress!!',
        ),
        NotificationTemplate(
          'WRAPPED BUT MAKE IT WEEKLY',
          'ur week just got summarized and its giving growth. check it!!',
        ),
      ],
      NotificationType.movement: [
        NotificationTemplate(
          'GET UP BESTIE',
          "sitting too long is NOT it. get up and do a lil walk!!",
        ),
        NotificationTemplate(
          'MOVEMENT CHECK',
          "ur body is literally begging u to move rn. stand up let's gooo",
        ),
        NotificationTemplate(
          'WALK BREAK TIME',
          'a quick walk is literally free dopamine. get those steps in!!',
        ),
        NotificationTemplate(
          'STAND UP RN',
          'no more chair jail bestie. take a walk and touch grass',
        ),
      ],
    },
  };
}
