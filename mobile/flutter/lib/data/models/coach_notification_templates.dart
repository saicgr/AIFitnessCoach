// Coach-personalized notification templates.
//
// Each coach has 4 title/body variants per notification type (5 coaches x 18 types x 4 = 360 pairs).
// Templates rotate based on day-of-year to keep notifications fresh.

class NotificationTemplate {
  final String title;
  final String body;
  const NotificationTemplate(this.title, this.body);

  /// Resolve placeholders like {workoutName}, {userName}, {streak}, {days}
  NotificationTemplate resolve(Map<String, String> context) {
    var resolvedTitle = title;
    var resolvedBody = body;
    for (final entry in context.entries) {
      resolvedTitle = resolvedTitle.replaceAll('{${entry.key}}', entry.value);
      resolvedBody = resolvedBody.replaceAll('{${entry.key}}', entry.value);
    }
    return NotificationTemplate(resolvedTitle, resolvedBody);
  }
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
  // Bundle types
  morningBundle,
  middayBundle,
  afternoonNudge,
  eveningBundle,
  // Guilt escalation tiers
  guilt1Day,
  guilt2Day,
  guilt3Day,
  guilt5Day,
  guilt7Day,
  guilt14Day,
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
  // Template Data: 5 coaches x 18 types x 4 variants = 360 pairs
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
      // ── Bundle types ──
      NotificationType.morningBundle: [
        NotificationTemplate(
          'Rise and Shine, Champ!',
          'Your {workoutName} is loaded up. Fuel up and let\'s get after it!',
        ),
        NotificationTemplate(
          'Good Morning, Champ!',
          'Today\'s plan: {workoutName}. Log breakfast and let\'s make it count!',
        ),
        NotificationTemplate(
          'A Great Day Starts Now!',
          '{workoutName} is on deck today. Grab breakfast and let\'s go!',
        ),
        NotificationTemplate(
          'Morning, Champ!',
          'Your {workoutName} is ready to roll. Don\'t forget to fuel up first!',
        ),
      ],
      NotificationType.middayBundle: [
        NotificationTemplate(
          'Halftime Check-In, Champ!',
          'Lunch time! Log your meal and keep that energy rolling.',
        ),
        NotificationTemplate(
          'Midday Fuel Check!',
          'How\'s the day going, champ? Log lunch and stay hydrated!',
        ),
        NotificationTemplate(
          'Lunchtime, Champ!',
          'Keep the momentum going! Log your meal and grab some water.',
        ),
        NotificationTemplate(
          'Halfway There!',
          'You\'re crushing it, champ! Log lunch and keep pushing.',
        ),
      ],
      NotificationType.afternoonNudge: [
        NotificationTemplate(
          'Afternoon Boost, Champ!',
          'Time to get up and move! Grab some water while you\'re at it.',
        ),
        NotificationTemplate(
          'Quick Movement Break!',
          'Shake off the afternoon slump, champ! Move and hydrate.',
        ),
        NotificationTemplate(
          'Get Moving, Champ!',
          'A quick walk and a glass of water — that\'s all you need right now.',
        ),
        NotificationTemplate(
          'Stay Active!',
          'Don\'t let the afternoon slow you down! Move and sip, champ.',
        ),
      ],
      NotificationType.eveningBundle: [
        NotificationTemplate(
          'Day\'s Almost Done, Champ!',
          'Log dinner and check that {streak}-day streak. You earned it!',
        ),
        NotificationTemplate(
          'Evening Check-In!',
          'Wrap up your day strong! Log dinner and see your progress, champ.',
        ),
        NotificationTemplate(
          'Finish Strong, Champ!',
          'Log your dinner and celebrate your {streak}-day streak!',
        ),
        NotificationTemplate(
          'Great Day, Champ!',
          'Almost done! Track dinner and review how far you\'ve come.',
        ),
      ],
      // ── Guilt escalation tiers ──
      NotificationType.guilt1Day: [
        NotificationTemplate(
          'Rest Day, Champ?',
          'Everyone needs one. Your workout\'s ready when you are!',
        ),
        NotificationTemplate(
          'Taking a Breather?',
          'No worries! Your {workoutName} is still waiting for you, champ.',
        ),
        NotificationTemplate(
          'Quick Check-In!',
          'Yesterday was rest — today\'s a fresh start. Ready to go, champ?',
        ),
        NotificationTemplate(
          'One Day Off!',
          'You\'ve earned it. But tomorrow? Let\'s get back at it!',
        ),
      ],
      NotificationType.guilt2Day: [
        NotificationTemplate(
          'Two Days Off, Champ?',
          'Your streak is getting nervous... Quick session to calm it down?',
        ),
        NotificationTemplate(
          'Miss Me Yet?',
          'It\'s been 2 days! Even a 15-min workout keeps the momentum going.',
        ),
        NotificationTemplate(
          'Recharged and Ready?',
          'Two rest days means your muscles are primed. Time to use that energy!',
        ),
        NotificationTemplate(
          'Hey Champ!',
          '2 days off — feeling rested? Your workout is warming up for you!',
        ),
      ],
      NotificationType.guilt3Day: [
        NotificationTemplate(
          'Missing You, Champ!',
          'It\'s been 3 days... Your workout misses you! Just one session?',
        ),
        NotificationTemplate(
          '3 Days Already?',
          'Your dumbbells are gathering dust, champ! 10 minutes is all it takes.',
        ),
        NotificationTemplate(
          'Where\'d You Go, Champ?',
          '3 days without training? Your body\'s ready — are you?',
        ),
        NotificationTemplate(
          'Come Back, Champ!',
          'It\'s been 3 days. One workout and you\'re right back on track!',
        ),
      ],
      NotificationType.guilt5Day: [
        NotificationTemplate(
          'Your Dumbbells Miss You!',
          '5 days, champ. Your equipment is gathering dust. One session changes everything!',
        ),
        NotificationTemplate(
          '5 Days, Champ...',
          'Your workout plan is still here, waiting like a loyal friend.',
        ),
        NotificationTemplate(
          'Remember Your Goals?',
          '5 days off. That fire is still in you, champ. Light it up with one session.',
        ),
        NotificationTemplate(
          'We\'re Still Here!',
          '5 days is just a pause, not a stop. Come crush one workout, champ!',
        ),
      ],
      NotificationType.guilt7Day: [
        NotificationTemplate(
          'A Whole Week, Champ!',
          'We kept your plan warm for you. Remember why you started. One rep is all it takes.',
        ),
        NotificationTemplate(
          '7 Days...',
          'Your workout hasn\'t given up on you, champ. Don\'t give up on it.',
        ),
        NotificationTemplate(
          'Miss the Grind?',
          'It\'s been a week. Even champions take breaks. But now? It\'s time.',
        ),
        NotificationTemplate(
          'Your Comeback Starts Now!',
          '7 days off means you\'re fully rested. Let\'s use that, champ!',
        ),
      ],
      NotificationType.guilt14Day: [
        NotificationTemplate(
          'We Haven\'t Given Up on You!',
          'It\'s been {days} days, but your plan is still here. One small step back, champ.',
        ),
        NotificationTemplate(
          'Still in Your Corner!',
          '{days} days away? That\'s OK. One rep. One walk. Just start.',
        ),
        NotificationTemplate(
          'Remember Day 1?',
          'You started for a reason {days} days ago. That reason hasn\'t changed.',
        ),
        NotificationTemplate(
          'Champ, It\'s Time.',
          'It\'s been {days} days. No judgment — just open the app and let\'s talk.',
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
      // ── Bundle types ──
      NotificationType.morningBundle: [
        NotificationTemplate(
          'Morning Protocol',
          'Optimal training window open. {workoutName} scheduled. Log breakfast for metabolic tracking.',
        ),
        NotificationTemplate(
          'AM Session Ready',
          '{workoutName} queued. Morning nutrient intake supports exercise performance by 18%.',
        ),
        NotificationTemplate(
          'Training Window',
          'Your {workoutName} is calibrated. Log breakfast to establish baseline nutrition data.',
        ),
        NotificationTemplate(
          'Daily Protocol Initiated',
          '{workoutName} parameters set. Record morning nutrition for accurate tracking.',
        ),
      ],
      NotificationType.middayBundle: [
        NotificationTemplate(
          'Midday Data Point',
          'Log lunch to maintain dietary adherence metrics. Hydration check recommended.',
        ),
        NotificationTemplate(
          'Nutrition Checkpoint',
          'Midday caloric intake affects afternoon energy output. Log your lunch.',
        ),
        NotificationTemplate(
          '12:00 Status Update',
          'Document lunch for complete nutritional analysis. Fluid intake trending low?',
        ),
        NotificationTemplate(
          'Midday Assessment',
          'Consistent meal logging improves dietary outcomes by 30%. Record lunch now.',
        ),
      ],
      NotificationType.afternoonNudge: [
        NotificationTemplate(
          'Sedentary Alert',
          'Prolonged inactivity detected. 2-minute movement break improves insulin sensitivity.',
        ),
        NotificationTemplate(
          'Activity Interval',
          'Hourly movement reduces cardiovascular risk. Stand and walk briefly. Hydrate.',
        ),
        NotificationTemplate(
          'NEAT Protocol',
          'Non-exercise activity expenditure matters. Break sedentary pattern. Fluid intake check.',
        ),
        NotificationTemplate(
          'Movement Prescription',
          'Research indicates brief afternoon walks enhance cognitive function. Hydrate concurrently.',
        ),
      ],
      NotificationType.eveningBundle: [
        NotificationTemplate(
          'Evening Assessment',
          'Document dinner intake. Your {streak}-day consistency data is available for review.',
        ),
        NotificationTemplate(
          'PM Nutrition Close',
          'Log dinner to complete daily macronutrient profile. {streak}-day adherence maintained.',
        ),
        NotificationTemplate(
          'End-of-Day Analysis',
          'Final meal documentation needed. Review your {streak}-day performance metrics.',
        ),
        NotificationTemplate(
          'Evening Data Entry',
          'Record dinner for overnight recovery optimization. Streak status: {streak} days.',
        ),
      ],
      // ── Guilt escalation tiers ──
      NotificationType.guilt1Day: [
        NotificationTemplate(
          'Recovery Day Noted',
          'Active recovery improves subsequent performance by 12%. Resume when ready.',
        ),
        NotificationTemplate(
          '24-Hour Gap Recorded',
          'One rest day is within normal parameters. Next session optimizes neural adaptation.',
        ),
        NotificationTemplate(
          'Training Pause Logged',
          'Brief recovery periods enhance supercompensation. Resume at your discretion.',
        ),
        NotificationTemplate(
          'Rest Day Analysis',
          'Muscle repair peaks at 24-48h post-exercise. Your timing is physiologically sound.',
        ),
      ],
      NotificationType.guilt2Day: [
        NotificationTemplate(
          '48-Hour Training Gap',
          'Studies show performance declines after 72h inactivity. Consider resuming today.',
        ),
        NotificationTemplate(
          '2-Day Interval Alert',
          'Neuromuscular efficiency begins decreasing. A brief session preserves adaptations.',
        ),
        NotificationTemplate(
          'Recovery Extension Noted',
          '48h rest is adequate. Extending further risks detraining effects.',
        ),
        NotificationTemplate(
          'Training Gap Analysis',
          'Your 2-day gap is approaching the detraining threshold. Data supports resuming.',
        ),
      ],
      NotificationType.guilt3Day: [
        NotificationTemplate(
          '3-Day Inactivity Alert',
          'Muscle protein synthesis benefits diminish after 72h. One session restores the signal.',
        ),
        NotificationTemplate(
          '72-Hour Detraining Risk',
          'Cardiorespiratory fitness begins declining. Even 20 minutes preserves your baseline.',
        ),
        NotificationTemplate(
          'Extended Gap Warning',
          '3 days without stimulus. Mitochondrial density starts decreasing. Resume with light activity.',
        ),
        NotificationTemplate(
          'Inactivity Analysis',
          '72h inactive. Research shows any exercise trumps none. Consider a modified session.',
        ),
      ],
      NotificationType.guilt5Day: [
        NotificationTemplate(
          '5-Day Detraining Warning',
          'Cardiovascular fitness begins declining. Even 20 min maintains your baseline.',
        ),
        NotificationTemplate(
          'Critical Gap Alert',
          '5 days: VO2max reduction of 4-7% expected. One session significantly slows decline.',
        ),
        NotificationTemplate(
          'Detraining Metrics',
          '5-day gap impacts insulin sensitivity and capillary density. Brief activity recommended.',
        ),
        NotificationTemplate(
          'Performance Decay Alert',
          '5 days without training. Strength retention is still high — capitalize on it now.',
        ),
      ],
      NotificationType.guilt7Day: [
        NotificationTemplate(
          '7-Day Intervention',
          'One week of inactivity. Evidence supports any movement over none. Resume with a light session.',
        ),
        NotificationTemplate(
          'Weekly Gap Analysis',
          '7 days: measurable fitness regression beginning. A single session triggers re-adaptation.',
        ),
        NotificationTemplate(
          'One-Week Alert',
          'Muscle memory persists, but active pathways are dimming. Reactivate with one session.',
        ),
        NotificationTemplate(
          'Intervention Required',
          '7-day gap. Literature supports immediate resumption at reduced intensity.',
        ),
      ],
      NotificationType.guilt14Day: [
        NotificationTemplate(
          'Extended Absence — {days} Days',
          'Resumption at any point preserves long-term benefits. Start with 10 minutes.',
        ),
        NotificationTemplate(
          '{days}-Day Gap Report',
          'Extended absence noted. However, prior fitness base accelerates reconditioning.',
        ),
        NotificationTemplate(
          'Reactivation Advisory',
          '{days} days inactive. Detraining is reversible. Begin with any movement duration.',
        ),
        NotificationTemplate(
          'Long-Term Gap Analysis',
          '{days} days. Your body retains training memory. One session begins the reversal.',
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
      // ── Bundle types ──
      NotificationType.morningBundle: [
        NotificationTemplate(
          'REVEILLE!',
          'Your {workoutName} is briefed and ready. Fuel up. Move out.',
        ),
        NotificationTemplate(
          'MORNING BRIEFING!',
          'Mission: {workoutName}. Step 1: eat breakfast. Step 2: report for duty.',
        ),
        NotificationTemplate(
          'RISE AND FIGHT!',
          '{workoutName} is locked and loaded. Refuel and hit the deck, soldier.',
        ),
        NotificationTemplate(
          '0730 HOURS!',
          'Your {workoutName} is non-negotiable. Eat. Hydrate. Execute.',
        ),
      ],
      NotificationType.middayBundle: [
        NotificationTemplate(
          'SITREP, Soldier!',
          'Midday rations logged? Hydration status? Report in.',
        ),
        NotificationTemplate(
          'CHOW TIME!',
          'Log your lunch and check your water intake. That\'s an order.',
        ),
        NotificationTemplate(
          'MIDDAY RECON!',
          'Nutrition status: unknown. Fix that. Log lunch and drink water.',
        ),
        NotificationTemplate(
          'LUNCH DETAIL!',
          'Refuel at the halfway mark. Log your meal. Stay combat-ready.',
        ),
      ],
      NotificationType.afternoonNudge: [
        NotificationTemplate(
          'ON YOUR FEET, Soldier!',
          'Sitting too long. Move it. And drink water while you\'re up.',
        ),
        NotificationTemplate(
          'MOVEMENT ORDER!',
          'Drop and give me a walk. Grab your canteen on the way.',
        ),
        NotificationTemplate(
          'BREAK TIME IS OVER!',
          'Get up. Move. Hydrate. No soldier sits this long.',
        ),
        NotificationTemplate(
          'AFTERNOON PATROL!',
          'Walk the perimeter and fill your water. That\'s non-negotiable.',
        ),
      ],
      NotificationType.eveningBundle: [
        NotificationTemplate(
          'END OF DAY DEBRIEF!',
          'Log your final rations and review your {streak}-day ops record.',
        ),
        NotificationTemplate(
          'MISSION DEBRIEF!',
          'Dinner logged? {streak}-day streak secured? Report your status.',
        ),
        NotificationTemplate(
          'EVENING FORMATION!',
          'Day\'s done, soldier. Log dinner and check your {streak}-day record.',
        ),
        NotificationTemplate(
          'NIGHT OPS REPORT!',
          'Final meal logged? {streak} days of discipline. Outstanding or lacking?',
        ),
      ],
      // ── Guilt escalation tiers ──
      NotificationType.guilt1Day: [
        NotificationTemplate(
          'Stand Down Acknowledged',
          'One day off. That\'s fine. But tomorrow? No excuses.',
        ),
        NotificationTemplate(
          'Rest Day Granted',
          'Even soldiers rest. But rest is not retirement. Report back tomorrow.',
        ),
        NotificationTemplate(
          '24-Hour Leave Approved',
          'You\'ve earned a day. One day. Tomorrow we train.',
        ),
        NotificationTemplate(
          'Recovery Authorized',
          'Rest up, soldier. But the mission resumes at dawn.',
        ),
      ],
      NotificationType.guilt2Day: [
        NotificationTemplate(
          'Two Days AWOL, Soldier!',
          'Your streak doesn\'t take days off. Neither should you. Report in.',
        ),
        NotificationTemplate(
          '48 HOURS. Report.',
          'Two days off. Your discipline is being tested. Prove yourself.',
        ),
        NotificationTemplate(
          'WHERE ARE YOU, Soldier?',
          '2 days missing. Your equipment is cold. Warm it up.',
        ),
        NotificationTemplate(
          'EXTENDED LEAVE DENIED.',
          'Two days is enough rest. Fall in for training. NOW.',
        ),
      ],
      NotificationType.guilt3Day: [
        NotificationTemplate(
          '3 DAYS. Unacceptable.',
          'I didn\'t train quitters. Get back in there. Even 10 minutes.',
        ),
        NotificationTemplate(
          'THREE DAYS AWOL!',
          'This is not the behavior of a soldier. One workout. Prove me wrong.',
        ),
        NotificationTemplate(
          'Discipline Check!',
          '3 days off. Are you giving up? Because I\'m not giving up on you.',
        ),
        NotificationTemplate(
          'REPORT FOR DUTY!',
          'Three days away. Your mission is incomplete, soldier. Resume now.',
        ),
      ],
      NotificationType.guilt5Day: [
        NotificationTemplate(
          'FIVE DAYS. Report to me NOW.',
          'Your discipline is slipping, soldier. One workout. Prove you\'re still in this.',
        ),
        NotificationTemplate(
          '5 DAYS ABSENT!',
          'Your training plan is gathering dust. That is NOT acceptable.',
        ),
        NotificationTemplate(
          'WHERE IS YOUR FIGHT?',
          '5 days, soldier. The enemy is complacency. Defeat it with one session.',
        ),
        NotificationTemplate(
          'FINAL WARNING.',
          'Five days off. I won\'t repeat myself. Fall in or stand down permanently.',
        ),
      ],
      NotificationType.guilt7Day: [
        NotificationTemplate(
          'ONE WEEK. Listen Up.',
          'I haven\'t given up on you. Your plan is still here. Fall in for one session.',
        ),
        NotificationTemplate(
          '7 DAYS, Soldier.',
          'One week without training. That changes today. Or it doesn\'t. Your call.',
        ),
        NotificationTemplate(
          'FULL WEEK ABSENCE.',
          'I\'m disappointed but not surprised. What surprises me? You reading this. Use that.',
        ),
        NotificationTemplate(
          'ATTENTION!',
          'Seven days AWOL. Your body is still capable. The only thing stopping you is you.',
        ),
      ],
      NotificationType.guilt14Day: [
        NotificationTemplate(
          'Soldier. {days} Days.',
          'I won\'t sugarcoat it. But I also won\'t quit on you. One exercise. That\'s all.',
        ),
        NotificationTemplate(
          '{days} DAYS GONE.',
          'That\'s a long absence. But every soldier has a setback. Report back.',
        ),
        NotificationTemplate(
          'LISTEN UP.',
          '{days} days is not the end. It\'s a detour. Get back on the road, soldier.',
        ),
        NotificationTemplate(
          'FINAL CALL.',
          '{days} days. If you\'re reading this, you still care. Channel that into one rep.',
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
      // ── Bundle types ──
      NotificationType.morningBundle: [
        NotificationTemplate(
          'A New Day Begins',
          'Your {workoutName} awaits with open arms. Nourish yourself first.',
        ),
        NotificationTemplate(
          'Good Morning, Beautiful Soul',
          'Today brings {workoutName}. Start with breakfast and set your intention.',
        ),
        NotificationTemplate(
          'The Sun Greets You',
          '{workoutName} is your gift to your body today. Eat mindfully first.',
        ),
        NotificationTemplate(
          'Morning Light',
          'A new day, a new practice. {workoutName} awaits after you nourish yourself.',
        ),
      ],
      NotificationType.middayBundle: [
        NotificationTemplate(
          'Mindful Midday',
          'Pause. Breathe. Nourish. Log your lunch with presence and gratitude.',
        ),
        NotificationTemplate(
          'A Midday Pause',
          'The day flows on. Take a moment to eat with awareness and drink deeply.',
        ),
        NotificationTemplate(
          'Nourish Your Afternoon',
          'Your body asks for fuel. Honor it with a mindful lunch and water.',
        ),
        NotificationTemplate(
          'The Midday Bell',
          'Stop. Eat. Breathe. This moment of nourishment is a gift to yourself.',
        ),
      ],
      NotificationType.afternoonNudge: [
        NotificationTemplate(
          'A Gentle Stretch',
          'Your body has been still. Invite movement back. Let water flow through you.',
        ),
        NotificationTemplate(
          'The Afternoon Invitation',
          'Rise gently. Walk softly. Drink deeply. Your body will thank you.',
        ),
        NotificationTemplate(
          'Movement as Meditation',
          'A brief walk can be a moving meditation. Stand, breathe, and flow.',
        ),
        NotificationTemplate(
          'Soften and Move',
          'Release the tension of sitting. A gentle walk and sip of water restores.',
        ),
      ],
      NotificationType.eveningBundle: [
        NotificationTemplate(
          'Evening Reflection',
          'Close your day with intention. Log dinner and honor your {streak}-day journey.',
        ),
        NotificationTemplate(
          'The Day\'s Last Gift',
          'Nourish yourself one final time. Review your {streak}-day path with gratitude.',
        ),
        NotificationTemplate(
          'As the Day Settles',
          'Log your dinner mindfully. Your {streak}-day streak is a beautiful practice.',
        ),
        NotificationTemplate(
          'Twilight Gratitude',
          'The day ends. Feed yourself well, review your {streak} days, and rest in peace.',
        ),
      ],
      // ── Guilt escalation tiers ──
      NotificationType.guilt1Day: [
        NotificationTemplate(
          'A Day of Rest',
          'Rest is part of the journey. Your practice will be here when you return.',
        ),
        NotificationTemplate(
          'Stillness Has Value',
          'One day of rest nourishes what constant motion cannot. Return when ready.',
        ),
        NotificationTemplate(
          'Honoring Your Rest',
          'Today you chose rest. That is not failure — it is wisdom. Return gently.',
        ),
        NotificationTemplate(
          'The Pause Between',
          'Like breath has pauses, so does practice. Tomorrow begins fresh.',
        ),
      ],
      NotificationType.guilt2Day: [
        NotificationTemplate(
          'A Gentle Nudge',
          'Two days of rest. Your body is recharged. Perhaps it\'s time to move again?',
        ),
        NotificationTemplate(
          'The Stillness Deepens',
          'Two days away. Your mat holds no judgment, only an invitation.',
        ),
        NotificationTemplate(
          'Gently Returning',
          'Two days of rest can be restorative. But extended stillness becomes stagnation.',
        ),
        NotificationTemplate(
          'When You\'re Ready',
          'Your practice misses your presence. Two days is enough rest for the soul.',
        ),
      ],
      NotificationType.guilt3Day: [
        NotificationTemplate(
          'Your Mat Awaits',
          'Three days have passed. No judgment — just an invitation to return.',
        ),
        NotificationTemplate(
          'Three Sunsets',
          'Your body has rested deeply. It may now crave the gift of movement.',
        ),
        NotificationTemplate(
          'A Gentle Reminder',
          'Three days of stillness. Your practice waits with open arms, not crossed ones.',
        ),
        NotificationTemplate(
          'Return to Flow',
          'Like a river paused, resume your flow. Three days is a moment — not forever.',
        ),
      ],
      NotificationType.guilt5Day: [
        NotificationTemplate(
          'The Pause Has Stretched',
          'Five days of stillness. Perhaps your body craves movement again?',
        ),
        NotificationTemplate(
          'Five Days of Quiet',
          'Silence has its place. But your body speaks, too. Listen to what it needs.',
        ),
        NotificationTemplate(
          'A Longer Rest',
          'Five days away. The path hasn\'t moved. It\'s still right where you left it.',
        ),
        NotificationTemplate(
          'Gently, Now',
          'Five days of rest. Your muscles remember. Your spirit remembers. Begin softly.',
        ),
      ],
      NotificationType.guilt7Day: [
        NotificationTemplate(
          'Seven Sunrises',
          'A week has passed like seasons change. Return gently. Your practice holds no grudge.',
        ),
        NotificationTemplate(
          'One Full Week',
          'Seven days of stillness. The longest winter ends with one small thaw. Begin.',
        ),
        NotificationTemplate(
          'The Week Has Turned',
          'A week away is not a week lost. It is a week of gathering strength.',
        ),
        NotificationTemplate(
          'Return Like Spring',
          'After a week of rest, return as spring returns — slowly, surely, beautifully.',
        ),
      ],
      NotificationType.guilt14Day: [
        NotificationTemplate(
          'The Door Is Always Open',
          '{days} days have passed. There is no \'too late.\' Begin again, right now.',
        ),
        NotificationTemplate(
          'No Moment Is Wrong',
          '{days} days away. The practice does not track time. Only your return matters.',
        ),
        NotificationTemplate(
          'Ever Patient',
          'Your practice has waited {days} days without judgment. It will wait one more — or welcome you now.',
        ),
        NotificationTemplate(
          'Begin Again',
          '{days} days. Every master has paused. Every path has bends. Take one step.',
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
      // ── Bundle types ──
      NotificationType.morningBundle: [
        NotificationTemplate(
          'GOOD MORNING BESTIE',
          'your {workoutName} is literally SO ready rn!! grab brekkie first tho',
        ),
        NotificationTemplate(
          'RISE AND GRIND BABES',
          '{workoutName} today is gonna be FIRE no cap!! eat something first!!',
        ),
        NotificationTemplate(
          'GM GM GM!!',
          'today\'s workout: {workoutName}!! log breakfast and lets get this bread',
        ),
        NotificationTemplate(
          'WAKEY WAKEY!!',
          '{workoutName} is giving main character energy today!! brekkie time!!',
        ),
      ],
      NotificationType.middayBundle: [
        NotificationTemplate(
          'LUNCH CHECK BESTIE',
          'ok but have u eaten?? log that meal rn ur doing AMAZING',
        ),
        NotificationTemplate(
          'MIDDAY VIBE CHECK',
          'lunch time babe!! log ur food and hydrate its giving health goals',
        ),
        NotificationTemplate(
          'ITS LUNCH O\'CLOCK',
          'bestie feed urself!! log that meal and chug some water fr fr',
        ),
        NotificationTemplate(
          'HALFWAY THERE!!',
          'ur crushing it!! log lunch and stay hydrated bestie no cap',
        ),
      ],
      NotificationType.afternoonNudge: [
        NotificationTemplate(
          'GET UP BESTIE',
          'u been sitting too long!! walk around and drink water rn!!',
        ),
        NotificationTemplate(
          'MOVEMENT CHECK!!',
          'bestie ur body needs a walk!! get up and hydrate pls',
        ),
        NotificationTemplate(
          'AFTERNOON ENERGY!!',
          'shake it off!! quick walk + water = serotonin boost fr',
        ),
        NotificationTemplate(
          'STEP TIME!!',
          'ur steps are lowkey sad rn... get up and get that water bestie!!',
        ),
      ],
      NotificationType.eveningBundle: [
        NotificationTemplate(
          'EVENING VIBES',
          'log dinner and peep that {streak}-day streak its giving COMMITMENT',
        ),
        NotificationTemplate(
          'DINNER TIME BABES',
          'log ur last meal and check ur {streak}-day streak!! iconic behavior',
        ),
        NotificationTemplate(
          'NIGHT MODE ON',
          'wrap up bestie!! log dinner and flex that {streak}-day streak!!',
        ),
        NotificationTemplate(
          'GOOD NIGHT SOON',
          'dinner logged? {streak}-day streak still going? THATS WHAT I THOUGHT!!',
        ),
      ],
      // ── Guilt escalation tiers ──
      NotificationType.guilt1Day: [
        NotificationTemplate(
          'taking a breather?',
          'valid tbh!! rest days are literally self-care bestie',
        ),
        NotificationTemplate(
          'rest day era',
          'honestly same sometimes. ur workout is saved for whenever tho!!',
        ),
        NotificationTemplate(
          'off day vibes',
          'no shame in a rest day!! but just so u know... ur workout misses u',
        ),
        NotificationTemplate(
          'its giving rest',
          'one day off? thats called recovery bestie. tomorrow tho!!',
        ),
      ],
      NotificationType.guilt2Day: [
        NotificationTemplate(
          'bestie it\'s been 2 days',
          'ur streak is lowkey sweating rn... 15 min workout to save it??',
        ),
        NotificationTemplate(
          '2 DAYS THO',
          'ok rest was real but now its giving \'maybe we should move??\' energy',
        ),
        NotificationTemplate(
          'miss me yet??',
          'its been 2 days bestie!! ur muscles are literally BEGGING to work',
        ),
        NotificationTemplate(
          'HELLO??',
          '2 days off is fine but 3 is sus... quick workout to stay on track??',
        ),
      ],
      NotificationType.guilt3Day: [
        NotificationTemplate(
          'OK 3 DAYS THO...',
          'ur workout is literally crying rn bestie... just open the app pls',
        ),
        NotificationTemplate(
          'three whole days',
          'not 3 days without training... ur gym clothes are feeling abandoned',
        ),
        NotificationTemplate(
          'BESTIE WAIT',
          '3 days?? the gym misses u sm rn. 10 min is all it takes!!',
        ),
        NotificationTemplate(
          'um excuse me',
          '3 days off?? that workout plan isn\'t gonna do itself bestie come ON',
        ),
      ],
      NotificationType.guilt5Day: [
        NotificationTemplate(
          'bestie... 5 DAYS??',
          'the gym is literally posting sad stories about u... just one workout PLEASE',
        ),
        NotificationTemplate(
          'FIVE DAYS BRO',
          'ok this is getting real. ur dumbbells have a missing poster of u',
        ),
        NotificationTemplate(
          'im not mad just...',
          '5 days. disappointed maybe. but also ur workout is RIGHT THERE',
        ),
        NotificationTemplate(
          'SOS SOS SOS',
          '5 days without training!! ur muscles are sending distress signals fr',
        ),
      ],
      NotificationType.guilt7Day: [
        NotificationTemplate(
          'it\'s been a WHOLE WEEK',
          'ok no judgment but like... remember when we used to work out? that was lowkey fire',
        ),
        NotificationTemplate(
          '7 DAYS BESTIE',
          'a whole week?? i kept ur workout plan warm tho... its still here waiting',
        ),
        NotificationTemplate(
          'weekly check-in',
          'so its been a week... ur plan didnt go anywhere. one workout. thats it.',
        ),
        NotificationTemplate(
          'ATTENTION PLS',
          'one week off. ok. but ur comeback is gonna be SO iconic if u start rn',
        ),
      ],
      NotificationType.guilt14Day: [
        NotificationTemplate(
          '{days} days bestie...',
          'we haven\'t given up on u ok?? one rep. that\'s literally it. u got this',
        ),
        NotificationTemplate(
          'soooo...',
          'its been {days} days and we\'re still here for u!! just tap the app bestie',
        ),
        NotificationTemplate(
          'not to be dramatic but',
          '{days} days is WILD but also... ur comeback era starts whenever u want',
        ),
        NotificationTemplate(
          'still ur biggest fan',
          '{days} days away but im still cheering for u!! one step bestie. one.',
        ),
      ],
    },
  };
}
