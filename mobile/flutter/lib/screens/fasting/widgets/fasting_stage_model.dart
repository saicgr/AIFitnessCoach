import 'package:flutter/material.dart';

/// A key within-stage moment of a fast — a finer-grained event than a full
/// metabolic stage. `hourOffset` is hours from the start of the fast.
typedef FastingMilestone = ({int hourOffset, String text});

/// A multi-day educational mark used by the Fasting Guide's long-form
/// timeline. Covers the extended-fast territory (24h → 30 days) that is
/// beyond the 7 live metabolic stages, with an explicit safety note.
///
/// Each mark owns its own [color] so the Guide's segmented progress track
/// reads as a continuous run of distinct hues — the six marks deepen
/// progressively through indigo → violet → magenta as the fast extends.
typedef FastingEducationalMilestone = ({
  int hourOffset,
  String label,
  String effect,
  String safety,
  Color color,
});

/// Metabolic stages of intermittent fasting, with sourced hour boundaries.
///
/// Stage boundaries are drawn from intermittent-fasting literature:
///  - Perfect Keto "The 5 Stages of Fasting"
///  - mimiohealth "Autophagy Fasting Chart"
///  - lasta.app "Fasting Timeline"
///  - Liv Hospital "Hours of Fasting for Cell Repair"
///  - BeKeto "Stages of Fasting"
///
/// Each stage owns its own accent color and icon so the central timer
/// visual can swap as the fast progresses.
enum FastingStage {
  /// 0–4h — Fed / anabolic state. Insulin elevated, body digesting and
  /// absorbing nutrients; energy from recently eaten carbohydrates.
  fed(
    name: 'Fed',
    tagline: 'Digesting & absorbing',
    startHour: 0,
    endHour: 4,
    color: Color(0xFF7C8B9E),
    icon: Icons.restaurant_rounded,
    description:
        'Your body is digesting food. Insulin is elevated and energy comes '
        'from the carbohydrates in your last meal.',
    milestones: [
      (hourOffset: 0, text: 'Last meal logged — digestion begins.'),
      (hourOffset: 1, text: 'Insulin peaks as blood sugar rises from your meal.'),
      (hourOffset: 3, text: 'Most nutrients are absorbed; blood sugar settles.'),
    ],
  ),

  /// 4–8h — Post-absorptive / blood sugar drops. Digestion finishing,
  /// insulin falling, body begins drawing on stored glycogen.
  bloodSugarDrop(
    name: 'Blood Sugar Drops',
    tagline: 'Insulin falling',
    startHour: 4,
    endHour: 8,
    color: Color(0xFF4D9BE0),
    icon: Icons.water_drop_rounded,
    description:
        'Digestion is complete and blood sugar is normalizing. Insulin '
        'levels fall as your body taps stored glycogen for fuel.',
    milestones: [
      (hourOffset: 4, text: 'Digestion finishes — the post-absorptive state begins.'),
      (hourOffset: 6, text: 'Insulin drops further; liver glycogen becomes the main fuel.'),
    ],
  ),

  /// 8–12h — Fat-burning begins. Glycogen depleting, the metabolic switch
  /// toward fat as fuel starts.
  fatBurningBegins(
    name: 'Fat Burning Begins',
    tagline: 'Glycogen depleting',
    startHour: 8,
    endHour: 12,
    color: Color(0xFF2BB0A4),
    icon: Icons.local_fire_department_outlined,
    description:
        'Glycogen stores are running low. Your body starts the metabolic '
        'switch toward burning stored fat for energy.',
    milestones: [
      (hourOffset: 8, text: 'Liver glycogen runs low — lipolysis ramps up.'),
      (hourOffset: 10, text: 'Fat cells break down into free fatty acids for fuel.'),
      (hourOffset: 12, text: 'First ketones appear as the fat switch flips on.'),
    ],
  ),

  /// 12–16h — Ketosis ramps up. Liver converts fat into ketones; fat is
  /// becoming the primary fuel source.
  ketosisRamp(
    name: 'Ketosis Ramping',
    tagline: 'Ketones rising',
    startHour: 12,
    endHour: 16,
    color: Color(0xFF4CAF50),
    icon: Icons.local_fire_department_rounded,
    description:
        'Fat is now a primary fuel. Your liver is converting fat stores '
        'into ketone bodies and ketosis is ramping up.',
    milestones: [
      (hourOffset: 13, text: 'Ketone production accelerates in the liver.'),
      (hourOffset: 14, text: 'Fat becomes the dominant energy source.'),
      (hourOffset: 16, text: 'Blood ketones reach light nutritional ketosis.'),
    ],
  ),

  /// 16–18h — Ketosis. Full fat-adapted state; ketones power muscles,
  /// heart and brain.
  ketosis(
    name: 'Ketosis',
    tagline: 'Fat-adapted fuel',
    startHour: 16,
    endHour: 18,
    color: Color(0xFFFF9800),
    icon: Icons.bolt_rounded,
    description:
        'You are in full ketosis. Ketone bodies are powering your muscles, '
        'heart and brain, and fat loss is well underway.',
    milestones: [
      (hourOffset: 16, text: 'Full fat-adaptation — ketones fuel the brain.'),
      (hourOffset: 17, text: 'Many people report steadier energy and focus.'),
    ],
  ),

  /// 18–24h — Autophagy. Cellular cleanup intensifies as the body recycles
  /// damaged proteins and organelles.
  autophagy(
    name: 'Autophagy',
    tagline: 'Cellular cleanup',
    startHour: 18,
    endHour: 24,
    color: Color(0xFFE0518A),
    icon: Icons.auto_awesome_rounded,
    description:
        'Autophagy is intensifying — your cells are recycling damaged '
        'proteins and organelles in a deep self-repair process.',
    milestones: [
      (hourOffset: 18, text: 'Autophagy steps up — cells clear damaged components.'),
      (hourOffset: 20, text: 'Insulin near its lowest; deep fat-burning continues.'),
      (hourOffset: 24, text: 'Glycogen fully depleted; autophagy accelerates further.'),
    ],
  ),

  /// 24h+ — Deep autophagy / growth hormone. Autophagy at high efficiency,
  /// growth hormone can rise 300–500% above baseline.
  growthHormone(
    name: 'Deep Autophagy',
    tagline: 'Growth hormone surge',
    startHour: 24,
    endHour: 72,
    color: Color(0xFF9B59E0),
    icon: Icons.spa_rounded,
    description:
        'Deep autophagy. Cellular cleanup is at high efficiency and growth '
        'hormone can climb 300–500% above baseline. Consult a clinician '
        'before fasting this long.',
    milestones: [
      (hourOffset: 24, text: 'Gluconeogenesis supplies glucose from amino acids.'),
      (hourOffset: 36, text: 'Growth hormone rises sharply to protect lean muscle.'),
      (hourOffset: 48, text: 'Insulin bottoms out; ketones (BHB) climb steadily.'),
      (hourOffset: 72, text: 'Immune-cell renewal and stem-cell signalling reported.'),
    ],
  );

  const FastingStage({
    required this.name,
    required this.tagline,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.icon,
    required this.description,
    this.milestones = const [],
  });

  final String name;
  final String tagline;
  final int startHour;
  final int endHour;
  final Color color;
  final IconData icon;
  final String description;

  /// Key within-stage moments, ordered by `hourOffset`. Sourced from
  /// intermittent-fasting literature (Healthline, Simple, BetterMe, BodySpec).
  final List<FastingMilestone> milestones;

  /// Multi-day educational marks for the Fasting Guide's long-form timeline.
  /// These cover the extended-fast territory (24h → 30 days) that lies
  /// beyond the 7 live metabolic stages. Each carries an effect summary and
  /// an explicit safety note — extended fasts need medical supervision.
  ///
  /// Attached to `growthHormone` because it is the open-ended final stage;
  /// access via [FastingStage.educationalMilestones] regardless of stage.
  static const List<FastingEducationalMilestone> educationalMilestones = [
    (
      hourOffset: 24,
      label: '24 hours',
      effect:
          'Glycogen is fully depleted. Autophagy accelerates and your body '
          'shifts to making glucose from amino acids (gluconeogenesis).',
      safety:
          'Generally safe for healthy adults. Expect hunger waves and lower '
          'energy — drink water and add a pinch of salt for electrolytes.',
      // Deep periwinkle indigo — first step past the live stages.
      color: Color(0xFF7C6FE8),
    ),
    (
      hourOffset: 48,
      label: '48 hours',
      effect:
          'Deep ketosis sets in and growth hormone climbs to preserve lean '
          'muscle. Insulin reaches its lowest point and inflammation drops.',
      safety:
          'Only for experienced fasters. Electrolytes (sodium, potassium, '
          'magnesium) become important. Stop if dizzy or unwell.',
      // Royal indigo.
      color: Color(0xFF6A4FD4),
    ),
    (
      hourOffset: 72,
      label: '72 hours',
      effect:
          'Immune-cell renewal and stem-cell signalling are reported. '
          'Autophagy and cellular repair are at high efficiency.',
      safety:
          'Do this only under medical supervision. Not for anyone who is '
          'pregnant, underweight, or managing a chronic condition.',
      // Deep violet.
      color: Color(0xFF8B47C9),
    ),
    (
      hourOffset: 168,
      label: '7 days',
      effect:
          'Sustained deep ketosis. The body runs almost entirely on fat and '
          'ketones; appetite often fades and mental clarity is commonly noted.',
      safety:
          'Medically supervised fasts only. Refeeding must be slow and '
          'careful to avoid refeeding syndrome.',
      // Mulberry / plum.
      color: Color(0xFFA63CB8),
    ),
    (
      hourOffset: 336,
      label: '14 days',
      effect:
          'Prolonged therapeutic fasting territory — used clinically in '
          'specific, monitored settings for metabolic resets.',
      safety:
          'Never attempt without a clinician. Risk of muscle loss, nutrient '
          'depletion and electrolyte imbalance is significant.',
      // Deep magenta.
      color: Color(0xFFB52F8C),
    ),
    (
      hourOffset: 720,
      label: '30 days',
      effect:
          'Extreme extended fasting — historically documented only in '
          'closely monitored medical or research environments.',
      safety:
          'Not a self-directed protocol under any circumstances. Shown here '
          'for education only — Zealova does not recommend fasts this long.',
      // Deepest crimson-magenta — the far end of the journey.
      color: Color(0xFFC0285E),
    ),
  ];

  /// Resolve the current stage from elapsed hours (as a double for precision).
  static FastingStage forElapsedHours(double hours) {
    for (final stage in values) {
      if (hours < stage.endHour) return stage;
    }
    return growthHormone;
  }

  /// The stage that follows this one, or null if this is the last.
  FastingStage? get next {
    final i = index;
    if (i >= values.length - 1) return null;
    return values[i + 1];
  }

  /// Progress within this stage (0.0 → 1.0) for the given elapsed hours.
  double progressWithin(double elapsedHours) {
    final span = (endHour - startHour).toDouble();
    if (span <= 0) return 1.0;
    return ((elapsedHours - startHour) / span).clamp(0.0, 1.0);
  }
}
