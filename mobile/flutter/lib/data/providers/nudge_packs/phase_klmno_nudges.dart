/// Phase K+L+M+N+O nudge pack — currently scoped to F3.71 (missed-meal
/// catch-up).
///
/// A missed-meal catch-up fires when a meal slot's main window has CLOSED
/// without a log for that slot. The trigger is one-window-late so the nudge
/// reads as "you missed it, here's how to recover," not "you're running
/// late." Each meal slot has its own dedup key so a missed breakfast +
/// missed lunch can both surface in the same afternoon.
///
/// Conventions (mirrors `contextual_nudge_provider.dart`):
///   * All time reasoning in user-local time.
///   * Wrap every fragile provider read in try/catch — a schema drift in
///     `nutritionProvider` must not poison the whole stack.
///   * Set `perishesAt` to end-of-day; the catch-up window stays open until
///     the user logs anything for that slot or the day rolls over.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contextual_nudge.dart';
import '../../repositories/nutrition_repository.dart';

/// Build the Phase K+L+M+N+O nudge list. Caller is responsible for
/// snooze-filtering — this pack just produces eligible candidates.
List<ContextualNudge> phaseKlmnoNudges(Ref ref, DateTime now) {
  final out = <ContextualNudge>[];
  final hour = now.hour;
  final minute = now.minute;
  final hourFraction = hour + minute / 60.0;
  final dateKey = now.toIso8601String().substring(0, 10);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

  // ── F3.71 — Missed-meal catch-up ───────────────────────────────────────
  //
  // Per-slot windows for "missed" — fires AFTER the normal logging window
  // has closed without a corresponding log.
  //   breakfast missed  : 11:00 ≤ now < 14:00
  //   lunch     missed  : 14:30 ≤ now < 17:00
  //   dinner    missed  : 20:30 ≤ now < 23:00
  try {
    final nutrition = ref.watch(nutritionProvider);
    final today = DateTime(now.year, now.month, now.day);

    bool loggedForSlot(String slot) {
      return nutrition.recentLogs.any((log) {
        final logLocal =
            log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
        final logDay =
            DateTime(logLocal.year, logLocal.month, logLocal.day);
        return logDay == today &&
            log.mealType.toLowerCase() == slot;
      });
    }

    final missedBreakfast = hourFraction >= 11.0 &&
        hourFraction < 14.0 &&
        !loggedForSlot('breakfast');
    final missedLunch = hourFraction >= 14.5 &&
        hourFraction < 17.0 &&
        !loggedForSlot('lunch');
    final missedDinner = hourFraction >= 20.5 &&
        hourFraction < 23.0 &&
        !loggedForSlot('dinner');

    void addMissed({
      required String slot,
      required String icon,
      required String title,
      required String body,
    }) {
      out.add(ContextualNudge(
        id: NudgeId.missedMealCatchup,
        icon: icon,
        title: title,
        body: body,
        ctaLabel: 'Log now',
        action: ContextualNudgeAction.mealSlot(slot),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.habit,
        perishesAt: endOfDay,
        dedupKey: 'phase_klmno_f71_${slot}_$dateKey',
      ));
    }

    if (missedBreakfast) {
      addMissed(
        slot: 'breakfast',
        icon: '🍳',
        title: 'Missed breakfast?',
        body: 'Log it now or roll it into a bigger lunch — your call.',
      );
    }
    if (missedLunch) {
      addMissed(
        slot: 'lunch',
        icon: '🥗',
        title: 'Lunch slipped past',
        body: 'A protein-forward snack now keeps the day on track.',
      );
    }
    if (missedDinner) {
      addMissed(
        slot: 'dinner',
        icon: '🍽️',
        title: 'Dinner not logged',
        body: 'Quick-log what you ate so tomorrow\'s targets stay honest.',
      );
    }
  } catch (_) {
    // nutritionProvider schema drift — skip this pack rather than crashing.
  }

  return out;
}
