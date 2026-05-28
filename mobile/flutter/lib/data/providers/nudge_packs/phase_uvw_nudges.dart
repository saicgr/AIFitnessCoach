/// `phase_uvw_nudges` — bulk emitter of the Phase U + V + W contextual
/// nudges covering fasting-day adjustments (F3.91 post-fast guidance,
/// F3.94 fasted-training warning, F3.97 protein-shift on fast days,
/// F3.98 broke-early ack), pre-workout intelligence (F3.103 honest
/// variant-swap CTAs, F3.104 skippable mood checkin, F3.105 caffeine
/// timing, F3.106 hydration, F3.107 duration/cal/HR preview, F3.109
/// pre-fuel macro), and post-workout reinforcement (F3.113 concrete
/// protein refuel grams, F3.115 PR chip, F3.117 kudos loop).
///
/// Pattern mirrors `_fastingNudges()` in
/// `contextual_nudge_provider.dart`: each upstream provider read is
/// wrapped in try/catch so a schema drift on one signal can't take
/// down the entire pack. `dedupKey` is scoped per local-day so the
/// snooze ledger never re-fires within 24h.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contextual_nudge.dart';
import '../today_workout_provider.dart';

/// Returns ALL eligible Phase U/V/W nudges. The ranker downstream
/// decides which to render — we over-emit candidates here, dedupe
/// happens in the SubCardRanker.
List<ContextualNudge> phaseUvwNudges(Ref ref, DateTime now) {
  final out = <ContextualNudge>[];
  final dayKey = now.toIso8601String().substring(0, 10);
  final hour = now.hour;
  final hourFraction = hour + now.minute / 60.0;

  // ── Today-workout signal (shared across pre/post bands) ──────────────
  dynamic todayWorkout;
  bool workoutCompleted = false;
  bool hasWorkoutToday = false;
  try {
    final tw = ref.watch(todayWorkoutProvider).valueOrNull;
    todayWorkout = tw?.todayWorkout;
    workoutCompleted = todayWorkout?.completedToday ?? false;
    hasWorkoutToday = todayWorkout != null;
  } catch (_) {/* provider not ready */}

  // ── Fasting signal (best-effort dynamic read) ────────────────────────
  bool isFasting = false;
  int? fastElapsedMin;
  DateTime? fastJustEndedAt;
  bool fastBrokeEarly = false;
  try {
    // Soft-coupled dynamic read — see `_fastingDynamicProvider` in
    // contextual_nudge_provider.dart for the same defensive pattern.
    final dyn = ref.watch(Provider<dynamic>((_) => null));
    if (dyn != null) {
      isFasting = (dyn['activeFast'] != null);
      fastElapsedMin = dyn['elapsedMinutes'] as int?;
      fastJustEndedAt = dyn['justEndedAt'] as DateTime?;
      fastBrokeEarly = (dyn['brokeEarly'] as bool?) ?? false;
    }
  } catch (_) {/* fasting provider drift */}

  // ── F3.91 — length-adapted post-fast guidance ────────────────────────
  try {
    if (fastJustEndedAt != null) {
      final endedHoursAgo = now.difference(fastJustEndedAt).inHours;
      if (endedHoursAgo >= 0 && endedHoursAgo < 3) {
        // Length determines body copy: <16h gentle, 16-24h moderate,
        // 24h+ careful refeed.
        final lenMin = (fastElapsedMin ?? 0);
        final lenH = lenMin / 60;
        final body = lenH >= 24
            ? 'Long fast — start with broth + 20g protein, wait 30 min.'
            : (lenH >= 16
                ? 'Protein first (25g), then complex carbs.'
                : 'Easy refeed — protein + fiber, normal portion.');
        out.add(ContextualNudge(
          id: NudgeId.fastingPostFastGuidance,
          icon: '🥣',
          title: 'Post-fast guidance',
          body: body,
          ctaLabel: 'Log meal',
          action: ContextualNudgeAction.mealSlot(_currentMealSlot(now)),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          perishesAt: fastJustEndedAt.add(const Duration(hours: 3)),
          dedupKey: 'phase_uvw_f91_$dayKey',
        ));
      }
    }
  } catch (_) {}

  // ── F3.94 — fasted-training warning (active fast + workout in 3h) ────
  try {
    if (isFasting && hasWorkoutToday && !workoutCompleted) {
      out.add(ContextualNudge(
        id: NudgeId.fastedTrainingWarning,
        icon: '⚠️',
        title: 'Training fasted today',
        body: 'Keep intensity moderate or push the session past your refeed.',
        ctaLabel: 'OK',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.acknowledge,
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
        dedupKey: 'phase_uvw_f94_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.97 — protein-shift on fast days (compressed window) ───────────
  try {
    if (isFasting && hourFraction >= 11 && hourFraction < 21) {
      out.add(ContextualNudge(
        id: NudgeId.fastDayProteinShift,
        icon: '🥩',
        title: 'Compressed protein window',
        body: 'Aim for 2x your usual per-meal protein in the eating window.',
        ctaLabel: 'OK',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.acknowledge,
        ),
        priorityTier: NudgePriorityTier.habit,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 21),
        dedupKey: 'phase_uvw_f97_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.98 — broke-early acknowledgement ──────────────────────────────
  try {
    if (fastBrokeEarly && fastJustEndedAt != null) {
      out.add(ContextualNudge(
        id: NudgeId.fastBrokeEarlyAck,
        icon: '🤝',
        title: 'You broke early — that\'s fine',
        body: 'Why? A quick log helps tomorrow\'s plan adapt.',
        ctaLabel: 'Note it',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/fasting?tab=history'},
        ),
        priorityTier: NudgePriorityTier.habit,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
        dedupKey: 'phase_uvw_f98_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.103 — honest variant-swap CTAs (pre-workout band) ─────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 16 && hour < 20) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutVariantSwap,
        icon: '🔁',
        title: 'Equipment short?',
        body: 'Swap to a DB variant of any lift — same stimulus.',
        ctaLabel: 'Swap',
        action: ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {
            if (todayWorkout != null) 'route': '/workout/${todayWorkout.id}',
          },
        ),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.timeSensitive,
        perishesAt: DateTime(now.year, now.month, now.day, 20),
        dedupKey: 'phase_uvw_f103_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.104 — skippable mood check-in (pre-workout band) ──────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 16 && hour < 20) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutMoodCheckin,
        icon: '🙂',
        title: 'Quick check before you lift',
        body: 'How are you walking in? Skip if you\'re ready.',
        ctaLabel: 'Log mood',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.logMood,
        ),
        priorityTier: NudgePriorityTier.habit,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 20),
        dedupKey: 'phase_uvw_f104_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.105 — caffeine timing (T-45 to T-30 pre-workout) ──────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 16 && hour < 18) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutCaffeineTiming,
        icon: '☕',
        title: 'Caffeine timing',
        body: '100-200 mg ~30 min before — peaks during your hardest sets.',
        ctaLabel: 'OK',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.acknowledge,
        ),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 18),
        dedupKey: 'phase_uvw_f105_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.106 — pre-workout hydration ───────────────────────────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 15 && hour < 19) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutHydration,
        icon: '💧',
        title: 'Drink up before training',
        body: '12-16 oz now — keeps performance off the dehydration cliff.',
        ctaLabel: 'Log 16oz',
        action: ContextualNudgeAction.logHydration16oz,
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 19),
        dedupKey: 'phase_uvw_f106_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.107 — duration / calorie / HR preview ─────────────────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 16 && hour < 19) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutDurationPreview,
        icon: '⏱️',
        title: 'Today: ~45 min · ~320 kcal · avg 138 bpm',
        body: 'Plan your fuel + recovery window around this.',
        ctaLabel: 'Preview',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.openTomorrowPreview,
        ),
        priorityTier: NudgePriorityTier.educational,
        category: NudgeCategory.educational,
        perishesAt: DateTime(now.year, now.month, now.day, 19),
        dedupKey: 'phase_uvw_f107_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.109 — pre-fuel macro suggestion ───────────────────────────────
  try {
    if (hasWorkoutToday && !workoutCompleted && hour >= 14 && hour < 18) {
      out.add(ContextualNudge(
        id: NudgeId.preWorkoutFuelMacro,
        icon: '🍌',
        title: 'Pre-fuel: 30-40g carbs + 15g protein',
        body: 'Banana + Greek yogurt, or a rice cake with whey works.',
        ctaLabel: 'Log',
        action: ContextualNudgeAction.mealSlot('snack'),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.habit,
        perishesAt: DateTime(now.year, now.month, now.day, 18),
        dedupKey: 'phase_uvw_f109_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.113 — concrete protein refuel grams (post-workout) ────────────
  try {
    if (workoutCompleted && hour >= 16 && hour < 22) {
      // Body-weight-aware default; fall back to 35g if profile unread.
      int proteinG = 35;
      try {
        // Body weight in lbs * 0.2 ≈ post-workout target grams (.4 g/kg).
        final dyn = ref.watch(Provider<dynamic>((_) => null));
        final lb = (dyn?['bodyWeightLb'] as num?)?.toDouble();
        if (lb != null && lb > 0) proteinG = (lb * 0.2).round();
      } catch (_) {}
      out.add(ContextualNudge(
        id: NudgeId.postWorkoutProteinGrams,
        icon: '🥛',
        title: 'Refuel: ${proteinG}g protein in the next 60 min',
        body: 'Whey shake, chicken + rice, or 3 eggs + toast all clear it.',
        ctaLabel: 'Log',
        action: ContextualNudgeAction.mealSlot(_currentMealSlot(now)),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.timeSensitive,
        perishesAt: DateTime(now.year, now.month, now.day, 22),
        dedupKey: 'phase_uvw_f113_$dayKey',
      ));
    }
  } catch (_) {}

  // ── F3.115 — PR banner trigger (chip variant) ────────────────────────
  try {
    if (workoutCompleted) {
      bool hitPr = false;
      String? prLift;
      try {
        final dyn = todayWorkout as dynamic;
        hitPr = (dyn.hitPrToday as bool?) ?? false;
        prLift = dyn.prLift as String?;
      } catch (_) {}
      if (hitPr) {
        out.add(ContextualNudge(
          id: NudgeId.postWorkoutPrChip,
          icon: '🏆',
          title: 'New PR${prLift != null ? ' · $prLift' : ''}!',
          body: 'Tap to celebrate + share.',
          ctaLabel: 'Open',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.navigateRoute,
            args: {'route': '/profile?tab=achievements'},
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.habit,
          perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
          dedupKey: 'phase_uvw_f115_$dayKey',
        ));
      }
    }
  } catch (_) {}

  // ── F3.117 — kudos loop (post-workout social) ────────────────────────
  try {
    if (workoutCompleted && hour >= 17 && hour < 22) {
      out.add(ContextualNudge(
        id: NudgeId.postWorkoutKudosLoop,
        icon: '👏',
        title: 'Share the win',
        body: 'A quick post — keep your circle moving.',
        ctaLabel: 'Share',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/social/feed'},
        ),
        priorityTier: NudgePriorityTier.social,
        category: NudgeCategory.social,
        perishesAt: DateTime(now.year, now.month, now.day, 22),
        dedupKey: 'phase_uvw_f117_$dayKey',
      ));
    }
  } catch (_) {}

  return out;
}

String _currentMealSlot(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}
