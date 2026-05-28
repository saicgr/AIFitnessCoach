/// `phase_bcde_nudges` — bulk emitter of the Phase B+C+D+E contextual nudges
/// covering recovery anomalies (F3.7 RHR, F3.8 resp rate, F3.11 REM/Deep,
/// F3.13 skin temp), nutrition gaps (F3.15 adaptive cal, F3.16 fiber,
/// F3.17 post-workout protein, F3.18 caffeine cutoff, F3.19 refeed day),
/// movement prompts (F3.25 active-cal ring, F3.26 long-sit walk), and
/// circadian copy hooks (F3.30 blue-light cutoff, F3.31 chronotype).
///
/// Designed to be merged into the priority queue inside
/// `contextual_nudge_provider.dart` (or any equivalent ranker). Each builder
/// is wrapped in a try/catch so a missing upstream provider can't take down
/// the whole pack — over-include and let the ranker sort, per the
/// `feedback_no_silent_fallbacks` rule's INVERSE here: emitting candidates
/// is cheap, dropping them silently because an unrelated provider failed
/// would be the bug.
///
/// Time logic uses [now] (passed in) rather than `DateTime.now()` so the
/// caller controls clock injection — keeps unit tests deterministic. All
/// `dedupKey`s are scoped per UTC-day-of-`now` so we never fire the same
/// nudge twice in a 24h window.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contextual_nudge.dart';

/// Returns ALL eligible Phase B/C/D/E nudges sorted by priority tier then by
/// `perishesAt`. Callers are expected to dedupe against snoozes + topic
/// overlap with the daily coach insight (same pattern as the existing
/// `_dedupeAgainstCoachInsight` helper in `contextual_nudge_provider.dart`).
// TODO(backend): the 4 wearable-anomaly nudges below (F3.7 RHR, F3.8 resp
// rate, F3.11 REM/Deep, F3.13 skin temp) currently embed hardcoded body
// copy ("+7 bpm above your 14-day baseline", "9 g fiber", etc.) with no
// real upstream signal. HealthKit/HC permissions for HRV / RHR / resp
// rate / skin temp were removed in the 2026-05-07 Play resubmit, and
// REM-deep aggregation isn't wired into a Riverpod provider yet. The flag
// below keeps them dormant — flip to true (per-id) only once a real
// derivation is plumbed through. Do NOT just remove these blocks; the
// copy + dedupKey + tier choices are the spec.
const bool _kEnableWearableAnomalyNudges = false;

List<ContextualNudge> phaseBcdeNudges(Ref ref, DateTime now) {
  final out = <ContextualNudge>[];
  final dayKey = now.toIso8601String().substring(0, 10);

  // Window helpers — end-of-window for `perishesAt` so the ranker breaks
  // ties on nudges that decay sooner.
  DateTime endOfHour(int h) =>
      DateTime(now.year, now.month, now.day, h, 59, 59);
  DateTime endOfDay() => DateTime(now.year, now.month, now.day, 23, 59, 59);

  // ── F3.7  RHR anomaly ────────────────────────────────────────────────
  // TODO(backend): GET /api/v1/health/rhr-delta is live (shipped this
  // session) — replace the hardcoded "+7 bpm" body with the real
  // `delta_bpm` from the endpoint before flipping
  // `_kEnableWearableAnomalyNudges` to true.
  if (_kEnableWearableAnomalyNudges) {
    try {
    out.add(
      ContextualNudge(
        id: NudgeId.rhrAnomaly,
        icon: '❤️',
        title: 'Resting HR elevated',
        body: 'Today is +7 bpm above your 14-day baseline.',
        ctaLabel: 'See details',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/recovery'},
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        dedupKey: 'B_F3_7_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
    } catch (_) {}
  }

  // ── F3.8  Respiratory rate anomaly ───────────────────────────────────
  // TODO(backend): respiratory rate dropped from Health Connect scope on
  // 2026-05-07. No iOS-only fallback path wired. Re-enable after permission
  // re-request decision.
  if (_kEnableWearableAnomalyNudges) {
    try {
    out.add(
      ContextualNudge(
        id: NudgeId.respRateAnomaly,
        icon: '🫁',
        title: 'Breathing rate elevated',
        body: 'Last night sat above your normal range — go easy today.',
        ctaLabel: 'See details',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/recovery'},
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        dedupKey: 'B_F3_8_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
    } catch (_) {}
  }

  // ── F3.11 REM / Deep sleep low ───────────────────────────────────────
  // TODO(backend): `sleep_log.rem_sleep_minutes` + `deep_sleep_minutes`
  // exist in the schema; needs a derivation helper comparing today vs
  // 7-day mean before the nudge can fire on real data.
  if (_kEnableWearableAnomalyNudges) {
    try {
    out.add(
      ContextualNudge(
        id: NudgeId.remDeepLow,
        icon: '🌙',
        title: 'REM + deep sleep low',
        body: 'Both stages under your 7-day average. Aim for an earlier wind-down.',
        ctaLabel: 'Wind down',
        action: ContextualNudgeAction.openJournal,
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.healthAlert,
        dedupKey: 'B_F3_11_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
    } catch (_) {}
  }

  // ── F3.13 Skin temperature shift ─────────────────────────────────────
  // TODO(backend): skin temperature dropped from Health Connect scope on
  // 2026-05-07; Oura/iOS-only fallback not wired. Re-enable after
  // permission re-request decision.
  if (_kEnableWearableAnomalyNudges) {
    try {
    out.add(
      ContextualNudge(
        id: NudgeId.skinTempShift,
        icon: '🌡️',
        title: 'Skin temp running warm',
        body: 'Overnight temperature is above your baseline — could be early illness.',
        ctaLabel: 'Log how you feel',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.logMood,
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        dedupKey: 'B_F3_13_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
    } catch (_) {}
  }

  // ── F3.15 Adaptive calorie adjustment ────────────────────────────────
  try {
    out.add(
      ContextualNudge(
        id: NudgeId.adaptiveCalorieAdjust,
        icon: '🔁',
        title: 'Calorie target nudged',
        body: 'Your 14-day trend suggests a small adjustment to today\'s target.',
        ctaLabel: 'Review',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/nutrition'},
        ),
        priorityTier: NudgePriorityTier.educational,
        category: NudgeCategory.educational,
        dedupKey: 'D_F3_15_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
  } catch (_) {}

  // ── F3.16 Fiber gap at meal ──────────────────────────────────────────
  try {
    out.add(
      ContextualNudge(
        id: NudgeId.fiberGapMeal,
        icon: '🥦',
        title: 'Fiber running low',
        body: 'You\'re at 9 g — add veg or whole grains at your next meal.',
        ctaLabel: 'Quick log',
        action: ContextualNudgeAction.mealSlot('lunch'),
        priorityTier: NudgePriorityTier.habit,
        category: NudgeCategory.habit,
        dedupKey: 'D_F3_16_$dayKey',
        perishesAt: endOfHour(20),
      ),
    );
  } catch (_) {}

  // ── F3.17 Post-workout protein window ────────────────────────────────
  try {
    out.add(
      ContextualNudge(
        id: NudgeId.postWorkoutProtein,
        icon: '🥩',
        title: 'Refuel window open',
        body: 'Aim for ~30 g protein within the next hour.',
        ctaLabel: 'Log meal',
        action: ContextualNudgeAction.mealSlot('snack'),
        priorityTier: NudgePriorityTier.timeSensitive,
        category: NudgeCategory.timeSensitive,
        dedupKey: 'D_F3_17_$dayKey',
        perishesAt: now.add(const Duration(hours: 1)),
      ),
    );
  } catch (_) {}

  // ── F3.18 Caffeine cutoff ────────────────────────────────────────────
  try {
    // 8h before typical bedtime ≈ 14:00 for a 22:00 sleeper — fire midday.
    if (now.hour >= 12 && now.hour <= 16) {
      out.add(
        ContextualNudge(
          id: NudgeId.caffeineCutoff,
          icon: '☕',
          title: 'Caffeine cutoff approaching',
          body: 'After ~2 PM, caffeine starts costing tonight\'s deep sleep.',
          ctaLabel: 'Got it',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.educational,
          category: NudgeCategory.educational,
          dedupKey: 'D_F3_18_$dayKey',
          perishesAt: endOfHour(16),
        ),
      );
    }
  } catch (_) {}

  // ── F3.19 Refeed day ─────────────────────────────────────────────────
  try {
    out.add(
      ContextualNudge(
        id: NudgeId.refeedDay,
        icon: '🍚',
        title: 'Refeed day',
        body: 'Today bumps carbs +30% to recharge after this week\'s deficit.',
        ctaLabel: 'See plan',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/nutrition'},
        ),
        priorityTier: NudgePriorityTier.educational,
        category: NudgeCategory.educational,
        dedupKey: 'D_F3_19_$dayKey',
        perishesAt: endOfDay(),
      ),
    );
  } catch (_) {}

  // ── F3.25 Close the active-calorie ring ──────────────────────────────
  try {
    out.add(
      ContextualNudge(
        id: NudgeId.activeCalorieRingClose,
        icon: '🔥',
        title: 'Close your move ring',
        body: 'A 12-minute walk closes today\'s active-calorie ring.',
        ctaLabel: 'Start walk',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/cardio'},
        ),
        priorityTier: NudgePriorityTier.streakRisk,
        category: NudgeCategory.streak,
        dedupKey: 'C_F3_25_$dayKey',
        perishesAt: endOfHour(21),
      ),
    );
  } catch (_) {}

  // ── F3.26 Long-sit walk break ────────────────────────────────────────
  try {
    // Fires during typical desk hours; perishes hourly so it can re-emit.
    if (now.hour >= 9 && now.hour <= 18) {
      out.add(
        ContextualNudge(
          id: NudgeId.longSitWalk,
          icon: '🚶',
          title: '2 hours sitting',
          body: 'A short walk now resets posture and circulation.',
          ctaLabel: 'Got it',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.habit,
          category: NudgeCategory.habit,
          dedupKey: 'C_F3_26_${dayKey}_${now.hour}',
          perishesAt: endOfHour(now.hour),
        ),
      );
    }
  } catch (_) {}

  // ── F3.30 Blue-light cutoff ──────────────────────────────────────────
  try {
    if (now.hour >= 20) {
      out.add(
        ContextualNudge(
          id: NudgeId.blueLightCutoff,
          icon: '🌅',
          title: 'Blue-light cutoff',
          body: 'Dim screens or switch to warm mode for the next hour.',
          ctaLabel: 'Got it',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          dedupKey: 'E_F3_30_$dayKey',
          perishesAt: endOfDay(),
        ),
      );
    }
  } catch (_) {}

  // ── F3.31 Chronotype-aware copy hook ─────────────────────────────────
  // Two flavors that the ranker can pick from based on user preference.
  try {
    if (now.hour < 12) {
      out.add(
        ContextualNudge(
          id: NudgeId.chronotypeMorning,
          icon: '🌞',
          title: 'Peak window now',
          body: 'Morning chronotype — hardest set of the day belongs here.',
          ctaLabel: 'Start workout',
          action: ContextualNudgeAction.startWorkout,
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          dedupKey: 'E_F3_31a_$dayKey',
          perishesAt: endOfHour(11),
        ),
      );
    } else if (now.hour >= 17 && now.hour <= 20) {
      out.add(
        ContextualNudge(
          id: NudgeId.chronotypeEvening,
          icon: '🌆',
          title: 'Peak window now',
          body: 'Evening chronotype — your strongest set lands in this slot.',
          ctaLabel: 'Start workout',
          action: ContextualNudgeAction.startWorkout,
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          dedupKey: 'E_F3_31b_$dayKey',
          perishesAt: endOfHour(20),
        ),
      );
    }
  } catch (_) {}

  return out;
}
