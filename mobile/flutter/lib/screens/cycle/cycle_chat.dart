/// Helpers to open the AI coach chat seeded with cycle context (Phase F).
///
/// Every "Ask coach about this" affordance across the Cycle feature funnels
/// through [openCycleChat] so the seeded prompt is consistent and the cycle
/// agent reliably picks up the conversation. The chat route accepts an
/// `initialMessage` via `extra` — see `app_router_main_shell_routes.dart`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/hormonal_health.dart';
import '../../data/services/haptic_service.dart';
import 'cycle_visuals.dart';

/// Push `/chat` with [seed] preloaded into the composer. The cycle agent is
/// routed to by the cycle keywords already present in any seeded prompt.
void openCycleChat(BuildContext context, String seed) {
  HapticService.light();
  context.push('/chat', extra: {'initialMessage': seed});
}

/// Seed text for the persistent app-bar coach icon — a broad cycle opener
/// carrying the current phase so the agent has immediate context.
String cycleOpenerSeed(CyclePrediction? prediction) {
  final phase = prediction?.currentPhase;
  final day = prediction?.currentCycleDay;
  if (phase == null || day == null) {
    return 'I have a question about my cycle.';
  }
  return 'I have a question about my cycle. '
      "I'm on day $day, in my ${phase.displayName.toLowerCase()} phase.";
}

/// Seed text for "Ask coach about this day" from a chart scrub callout or a
/// calendar day tap.
String cycleDaySeed(DateTime date, {CyclePhase? phase, int? cycleDay}) {
  final parts = <String>[
    'Tell me about ${CycleDates.medium(date)}',
  ];
  if (cycleDay != null) parts.add('cycle day $cycleDay');
  if (phase != null) parts.add('${phase.displayName.toLowerCase()} phase');
  return '${parts.join(', ')}. What was happening with my cycle then?';
}

/// Seed text for "Ask coach about this" on a chart / stats datum.
String cycleDatumSeed(String datumDescription) =>
    'About my cycle data: $datumDescription. Can you explain what this means '
    'for me?';

/// Phase- and mode-aware suggested-question chips. Always returns ≥3 so the
/// chip row never looks sparse.
List<String> cycleSuggestedQuestions({
  required CyclePhase? phase,
  required CycleTrackingMode mode,
}) {
  if (mode == CycleTrackingMode.pregnancy) {
    return const [
      'What changes should I expect this trimester?',
      'Is my workout plan still safe?',
      'What should I be eating right now?',
    ];
  }
  if (mode == CycleTrackingMode.ttc) {
    return const [
      'When am I most fertile this cycle?',
      'How can I read my fertility signs?',
      'What helps my chances of conceiving?',
      'Is my cycle regular enough?',
    ];
  }
  switch (phase) {
    case CyclePhase.menstrual:
      return const [
        'How can I ease cramps today?',
        'Should I work out during my period?',
        'What should I eat this week?',
        'Is my period length normal?',
      ];
    case CyclePhase.follicular:
      return const [
        'Why do I feel more energetic now?',
        'Is this a good week to push harder?',
        'What should I eat in this phase?',
      ];
    case CyclePhase.ovulation:
      return const [
        'What is happening in my body right now?',
        'How should I train this week?',
        'Am I in my fertile window?',
      ];
    case CyclePhase.luteal:
      return const [
        'Why am I tired this week?',
        'How do I handle PMS symptoms?',
        'Should I eat more before my period?',
        'What workout suits this phase?',
      ];
    case null:
      return const [
        'Is my cycle normal?',
        'How does cycle tracking work?',
        'What should I log each day?',
      ];
  }
}
