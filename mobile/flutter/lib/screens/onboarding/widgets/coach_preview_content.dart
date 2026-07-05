/// Curated per-persona content for the coach-selection preview chat.
///
/// Every path a user can take stays in the coach's voice: the opener, the
/// four suggestion-chip answers, the smalltalk greeting, and the visible
/// failure label. Live answers come from /onboarding/coach-preview; this
/// file is the zero-cost, zero-latency floor the live turn stands on.
library;

/// One suggested question + the coach's curated answer.
class PreviewChip {
  final String question;
  final String answer;
  final bool personalized;

  const PreviewChip(this.question, this.answer, {this.personalized = false});
}

/// Human phrase for a quiz limitation id (knees / shoulders / lower_back).
String? limitationPhrase(List<String>? limitations) {
  if (limitations == null) return null;
  for (final l in limitations) {
    switch (l) {
      case 'knees':
        return 'knee';
      case 'shoulders':
        return 'shoulder';
      case 'lower_back':
        return 'lower back';
    }
  }
  return null;
}

/// Smalltalk detector — greetings and acks get an instant local reply and
/// never consume a live turn (or an API call).
final RegExp kPreviewGreeting = RegExp(
  r"^(hi+|hello+|hey+|yo+|sup|hi there|hey there|hello there|"
  r"good (morning|afternoon|evening)|what'?s up|thanks?( you)?|thank you|"
  r"ok(ay)?|cool|nice)[\s!.?]*$",
  caseSensitive: false,
);

class CoachPreviewContent {
  final String opener;
  final String greeting;
  final String fallbackLabel;

  /// Answer to the personalized injury chip; `{part}` is replaced with the
  /// user's limitation phrase ("knee", "shoulder", "lower back").
  final String injuryQuestion;
  final String injuryAnswer;

  /// Generic injury chip used when the quiz reported no limitation.
  final String genericInjuryQuestion;
  final String genericInjuryAnswer;

  final List<PreviewChip> chips;

  const CoachPreviewContent({
    required this.opener,
    required this.greeting,
    required this.fallbackLabel,
    required this.injuryQuestion,
    required this.injuryAnswer,
    required this.genericInjuryQuestion,
    required this.genericInjuryAnswer,
    required this.chips,
  });

  /// Full chip list with the injury chip resolved against quiz data.
  List<PreviewChip> chipsFor(List<String>? limitations) {
    final part = limitationPhrase(limitations);
    final first = part != null
        ? PreviewChip(
            injuryQuestion.replaceAll('{part}', part),
            injuryAnswer.replaceAll('{part}', part),
            personalized: true,
          )
        : PreviewChip(genericInjuryQuestion, genericInjuryAnswer);
    return [first, ...chips];
  }
}

/// Keyed by [CoachPersona.id]. Custom coaches fall back to `coach_mike`'s
/// structure with their own name spoken by the live endpoint.
const Map<String, CoachPreviewContent> kCoachPreviewContent = {
  'coach_mike': CoachPreviewContent(
    opener: "Hey, I'm Mike! 👊 Ask me anything before you pick — or tap a "
        "question below.",
    greeting: "Hey hey! 👊 What's on your mind — training, nerves, anything?",
    fallbackLabel: "Coach Mike's mid-set — here's how he answers that:",
    injuryQuestion: 'Will my {part} be a problem?',
    injuryAnswer:
        "Not on my watch. Your plan already works around that {part} — we "
        "build around it, not through it. {part}-friendly training is my "
        "specialty, champ.",
    genericInjuryQuestion: "I've had injuries before — can we work around them?",
    genericInjuryAnswer:
        "Absolutely. Tell the app what's tender and the plan builds around "
        "it automatically — we train what's ready and protect what's not.",
    chips: [
      PreviewChip(
        "I'm nervous about my first workout",
        "Totally normal! We start light and nail your form first — small "
        "wins, big confidence. By week 3 you'll be chasing the workout, "
        "not fearing it.",
      ),
      PreviewChip(
        'How fast will I see results?',
        "Strength jumps in 2–3 weeks — that's your nervous system waking "
        "up. Visible changes around week 6–8 if you keep showing up. And "
        "I'll make sure you keep showing up.",
      ),
      PreviewChip(
        'What if I miss a week?',
        "Life happens! The plan auto-adjusts — we ease the load, rebuild "
        "momentum, zero guilt. Consistency beats perfection. Every time.",
      ),
    ],
  ),
  'dr_sarah': CoachPreviewContent(
    opener: "Hello — I'm Dr. Sarah. Ask me anything about your training; "
        "I'll give you the evidence, not the hype.",
    greeting: "Hello! Ask me anything about your plan — I'll keep it "
        "evidence-based.",
    fallbackLabel: 'Dr. Sarah is with a client — here\'s her take:',
    injuryQuestion: 'Will my {part} be a problem?',
    injuryAnswer:
        "No — and we won't guess. Your plan limits {part} loading to your "
        "pain-free range and rebuilds capacity progressively. Research "
        "favors controlled loading over rest for most {part} issues.",
    genericInjuryQuestion: "I've had injuries before — can we work around them?",
    genericInjuryAnswer:
        "Yes. Log any limitation and the plan excludes aggravating patterns "
        "while loading what tolerates it — graded exposure is the "
        "evidence-based path back.",
    chips: [
      PreviewChip(
        "I'm nervous about my first workout",
        "That's a healthy signal, not a red flag. We begin near 60% effort "
        "to groove the patterns. Confidence follows competence — usually "
        "within two sessions.",
      ),
      PreviewChip(
        'How fast will I see results?',
        "Neural strength gains: 2–3 weeks. Measurable hypertrophy: 6–8 "
        "weeks. Habit consolidation: about 10. I'll show you each marker "
        "in your data as it arrives.",
      ),
      PreviewChip(
        'What if I miss a week?',
        "Detraining is slower than people fear — meaningful loss takes 2–3 "
        "weeks. The plan recalibrates your loads on return. One missed "
        "week is a data point, not a verdict.",
      ),
    ],
  ),
  'sergeant_max': CoachPreviewContent(
    opener: "Sergeant Max. You've got questions? Ask them now, recruit. "
        "Make them count.",
    greeting: "Recruit. We don't do small talk. Ask me something that "
        "builds muscle.",
    fallbackLabel: 'Sergeant Max is drilling a recruit — here\'s his answer:',
    injuryQuestion: 'Will my {part} be a problem?',
    injuryAnswer:
        "A bad {part} is intel, not an excuse. The plan already benched "
        "the risky {part} work until you earn it back. We train around it "
        "— smart AND hard.",
    genericInjuryQuestion: "I've had injuries before — can we work around them?",
    genericInjuryAnswer:
        "Everyone's carrying something. Report it, the plan routes around "
        "it, and we attack everything else. No excuses left. Clear?",
    chips: [
      PreviewChip(
        "I'm nervous about my first workout",
        "Nervous? Good. Means you respect the work. We drill the basics "
        "light until they're boring. Then we load. That's the system.",
      ),
      PreviewChip(
        'How fast will I see results?',
        "You'll FEEL it in 2 weeks. You'll SEE it in 6 — IF you show up. "
        "Showing up is your only job. I handle the rest.",
      ),
      PreviewChip(
        'What if I miss a week?',
        "Then you come back and we go again. No sob stories. The plan "
        "recalibrates; you re-engage. Clear?",
      ),
    ],
  ),
  'zen_maya': CoachPreviewContent(
    opener: "Hi, I'm Maya 🌿 No rush — ask whatever's on your mind.",
    greeting: "Hi 🌿 Take your time — what's on your mind?",
    fallbackLabel: "Maya's in a session — here's how she answers that:",
    injuryQuestion: 'Will my {part} be a problem?',
    injuryAnswer:
        "We'll listen to it, not fight it. Your plan avoids loading that "
        "{part} harshly and rebuilds gently — movement should feel like "
        "care, not punishment.",
    genericInjuryQuestion: "I've had injuries before — can we work around them?",
    genericInjuryAnswer:
        "Of course. Tell the app where you're tender and your sessions "
        "flow around it. Healing and progress can share the same week.",
    chips: [
      PreviewChip(
        "I'm nervous about my first workout",
        "Nerves are just energy without a plan. We'll move slowly, "
        "breathe, and let the patterns settle. It becomes a ritual you "
        "look forward to.",
      ),
      PreviewChip(
        'How fast will I see results?',
        "Strength arrives quietly in 2–3 weeks; visible change closer to "
        "8. But notice your sleep and mood first — they shift within days.",
      ),
      PreviewChip(
        'What if I miss a week?',
        "A missed week is rest, not failure. The plan softens your return, "
        "and we simply begin again. Balance includes pauses.",
      ),
    ],
  ),
  'hype_danny': CoachPreviewContent(
    opener: "YOOO it's Danny!! 🎉 Ask me ANYTHING, let's gooo",
    greeting: "YOOO 🔥 ok ok, what do you wanna know? I'm HYPED.",
    fallbackLabel: "Danny's filming a hype reel — here's his answer:",
    injuryQuestion: 'Will my {part} be a problem?',
    injuryAnswer:
        "We got you — the plan skips the spicy {part} stuff till it's "
        "ready. Training still goes CRAZY, just smarter. 😤",
    genericInjuryQuestion: "I've had injuries before — can we work around them?",
    genericInjuryAnswer:
        "SAY LESS — log it and the plan dodges it automatically. We work "
        "with your body, not against it. Still gonna cook though 🔥",
    chips: [
      PreviewChip(
        "I'm nervous about my first workout",
        "FIRST SESSION?? That's a core memory loading. We start light, "
        "clean reps — by week 3 you're gonna be POSTING about it, fr.",
      ),
      PreviewChip(
        'How fast will I see results?',
        "2–3 weeks: strength buff unlocked. 6–8: the mirror starts "
        "agreeing with you. Just don't ghost me 💀",
      ),
      PreviewChip(
        'What if I miss a week?',
        "Bro, life happens 😭 The plan auto-adjusts, we run it back, ZERO "
        "guilt. Consistency > perfection, always.",
      ),
    ],
  ),
};

CoachPreviewContent previewContentFor(String coachId) =>
    kCoachPreviewContent[coachId] ?? kCoachPreviewContent['coach_mike']!;
