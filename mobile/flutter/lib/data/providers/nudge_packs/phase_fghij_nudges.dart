/// Phase F/G/H/I/J nudge pack.
///
/// Each helper returns zero or more [ContextualNudge]s for a single F-spec
/// row. Every provider read is wrapped in a try/catch so a downstream
/// schema drift (hormonalProfileProvider, socialProvider, etc.) can't
/// poison the whole contextual-nudge stack.
///
/// Covered specs:
///   * F3.35 — ovulation strength window (high-intent training cue)
///   * F3.37 — pregnancy mode guard (intensity cap reminder)
///   * F3.38 — perimenopause cue (sleep + protein lean)
///   * F3.41 — contextual breathwork CTA (afternoon stress window — the
///             evening variant is already handled in `contextual_nudge_provider`,
///             this adds the 14:00–17:00 slice)
///   * F3.43 — gratitude prompt (evening reflection)
///   * F3.45 — weather/heat hydration cue (heuristic: late spring–summer
///             months in northern-hemisphere zones, midday/afternoon)
///   * F3.46 — electrolyte tile (after long sweat-day; coexists with the
///             existing sweat-day electrolyte chip but uses a distinct
///             dedupKey so the ranker can elect either)
///   * F3.51 — achievement near-unlock dedupe (the gamification helper in
///             `contextual_nudge_provider` already emits the streak-at-risk
///             variant; this pack stays out of the way and just no-ops)
///   * F3.53 — kudos badge (acknowledges friend cheers)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contextual_nudge.dart';
import '../../models/hormonal_health.dart';
import '../hormonal_health_provider.dart';
import '../social_provider.dart';
import '../../../core/providers/user_provider.dart';

/// Public entry: returns every nudge eligible for this pack at [now]. The
/// caller (sub-card ranker / contextual nudge provider) is expected to
/// dedup against snoozed ids and apply category re-weighting.
List<ContextualNudge> phaseFghijNudges(Ref ref, DateTime now) {
  final out = <ContextualNudge>[];
  final today = DateTime(now.year, now.month, now.day);
  String dayKey() => today.toIso8601String().substring(0, 10);

  // ── F3.35 — ovulation strength window ──────────────────────────────
  try {
    final tracks = ref.watch(hasHormonalTrackingProvider);
    if (tracks) {
      final pred = ref.watch(cyclePredictionProvider).valueOrNull;
      if (pred != null &&
          pred.predictionsAvailable &&
          pred.currentPhase == CyclePhase.ovulation) {
        out.add(ContextualNudge(
          id: NudgeId.ovulationStrengthWindow,
          icon: '💪',
          title: 'Strength window',
          body: 'Ovulation phase — push intensity if you feel up to it.',
          ctaLabel: 'OK',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.educational,
          category: NudgeCategory.educational,
          perishesAt: DateTime(now.year, now.month, now.day, 22),
          dedupKey: 'phase_fghij_f335_${dayKey()}',
        ));
      }
    }
  } catch (_) {/* hormonal provider not ready */}

  // ── F3.37 — pregnancy mode guard ───────────────────────────────────
  try {
    final mode = ref.watch(cycleTrackingModeProvider);
    final pregnant = mode == CycleTrackingMode.pregnancy;
    if (pregnant) {
      out.add(ContextualNudge(
        id: NudgeId.pregnancyModeGuard,
        icon: '🤰',
        title: 'Pregnancy-safe intensity',
        body: 'Keep RPE moderate. Hydrate often, no breath-holding.',
        ctaLabel: 'OK',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.acknowledge,
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        perishesAt: DateTime(now.year, now.month, now.day, 23),
        dedupKey: 'phase_fghij_f337_${dayKey()}',
      ));
    }
  } catch (_) {/* profile not ready */}

  // ── F3.38 — perimenopause cue ──────────────────────────────────────
  try {
    final profile = ref.watch(hormonalProfileProvider).valueOrNull;
    if (profile != null && profile.menopauseStatus == MenopauseStatus.peri) {
      out.add(ContextualNudge(
        id: NudgeId.perimenopauseCue,
        icon: '🌗',
        title: 'Perimenopause check',
        body: 'Lean protein + sleep priority — they pay double right now.',
        ctaLabel: 'OK',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.acknowledge,
        ),
        priorityTier: NudgePriorityTier.educational,
        category: NudgeCategory.educational,
        perishesAt: DateTime(now.year, now.month, now.day, 22),
        dedupKey: 'phase_fghij_f338_${dayKey()}',
      ));
    }
  } catch (_) {/* profile not ready */}

  // ── F3.41 — contextual breathwork CTA (afternoon slice) ────────────
  // The evening 17:00-22:00 breathwork nudge already lives in
  // `contextual_nudge_provider._gamificationNudges`-adjacent code; this
  // covers the 14:00-17:00 mid-afternoon stress slot.
  final hourFraction = now.hour + now.minute / 60.0;
  if (hourFraction >= 14 && hourFraction < 17) {
    out.add(ContextualNudge(
      id: NudgeId.breathwork,
      icon: '🌬️',
      title: 'Afternoon reset · 90s',
      body: 'Box-breathing now, sharper second half of the day.',
      ctaLabel: 'Start',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.startBreathwork,
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 17),
      dedupKey: 'phase_fghij_f341_${dayKey()}',
    ));
  }

  // ── F3.43 — evening gratitude prompt ───────────────────────────────
  if (hourFraction >= 20 && hourFraction < 23) {
    out.add(ContextualNudge(
      id: NudgeId.gratitudePrompt,
      icon: '🙏',
      title: 'One good thing today',
      body: 'Jot one win before bed — sleep starts here.',
      ctaLabel: 'Open',
      action: ContextualNudgeAction.openJournal,
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
      dedupKey: 'phase_fghij_f343_${dayKey()}',
    ));
  }

  // ── F3.45 — heat-day hydration cue ─────────────────────────────────
  // Heuristic only — no live weather feed wired yet. We surface during
  // the warm-months / warm-hours window so the nudge is at least
  // seasonally plausible. Replace with a real wx provider when one ships.
  final warmMonth = now.month >= 5 && now.month <= 9;
  if (warmMonth && hourFraction >= 11 && hourFraction < 18) {
    out.add(ContextualNudge(
      id: NudgeId.hydrationHeat,
      icon: '🌡️',
      title: 'Heat-day hydration',
      body: 'Add +500 ml today — humidity is sneaky.',
      ctaLabel: 'Log 16oz',
      action: ContextualNudgeAction.logHydration16oz,
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 18),
      dedupKey: 'phase_fghij_f345_${dayKey()}',
    ));
  }

  // ── F3.46 — electrolyte tile ───────────────────────────────────────
  // Coexists with the existing sweat-day electrolyte chip via a distinct
  // dedupKey; ranker picks the higher-priority one if both fire.
  if (hourFraction >= 11 && hourFraction < 21) {
    out.add(ContextualNudge(
      id: NudgeId.electrolyteTile,
      icon: '🧂',
      title: 'Electrolytes today',
      body: 'A pinch of salt + citrus in water covers most of it.',
      ctaLabel: 'OK',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.acknowledge,
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 21),
      dedupKey: 'phase_fghij_f346_${dayKey()}',
    ));
  }

  // ── F3.51 — achievement near-unlock (dedup-only stub) ──────────────
  // The streak-at-risk variant already ships from
  // `_gamificationNudges` in the main provider. Intentionally no-op here
  // so this pack doesn't fire a duplicate row at the user.

  // ── F3.53 — kudos badge ────────────────────────────────────────────
  try {
    final userId = ref.watch(currentUserProvider).valueOrNull?.id;
    if (userId != null) {
      final feed = ref.watch(activityFeedProvider(userId)).valueOrNull;
      int kudos = 0;
      if (feed != null) {
        final raw = feed['kudos_today'] ?? feed['new_kudos'];
        if (raw is num) kudos = raw.toInt();
      }
      if (kudos > 0) {
        out.add(ContextualNudge(
          id: NudgeId.kudosBadge,
          icon: '🎉',
          title: '$kudos new kudos',
          body: 'Friends cheered your activity — say thanks.',
          ctaLabel: 'View',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.navigateRoute,
            args: {'route': '/social'},
          ),
          priorityTier: NudgePriorityTier.social,
          category: NudgeCategory.social,
          perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
          dedupKey: 'phase_fghij_f353_${dayKey()}',
        ));
      }
    }
  } catch (_) {/* social feed unavailable */}

  return out;
}
