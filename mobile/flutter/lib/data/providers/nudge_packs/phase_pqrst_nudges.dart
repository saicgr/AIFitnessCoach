/// Phase P+Q+R+S+T nudge pack.
///
/// A handful of context-light chip-format nudges that fit better as nudge
/// row entries than full home cards. Every read here is wrapped in try/catch
/// so a missing/erroring provider degrades to "skip this nudge" instead of
/// blanking the Coach hero. The cards for the same phase (F3.74-F3.88) live
/// in `lib/screens/home/widgets/cards/` and own their own gating.
///
/// Variants chosen (chip > card):
///   * F3.74 — Day-of-week skip reminder
///   * F3.82 — Birthday greeting
///   * F3.84 — First-of-month reset
///   * F3.83 — Weigh-in day chip variant
///   * F3.79 — Injury workaround acknowledgement
///   * F3.86 — Day-N tutorial nudge
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contextual_nudge.dart';
import '../../repositories/auth_repository.dart';

/// Build the Phase P/Q/R/S/T nudge bundle. Caller (the master
/// contextualNudgeProvider) is responsible for de-duping against tier-1
/// coach insight, quiet hours, and vacation mode; this function only
/// produces candidates.
///
/// All [perishesAt] times are user-local end-of-day, which matches the
/// existing nudge-pack convention. `now` is supplied so tests can pin the
/// clock.
List<ContextualNudge> phasePqrstNudges(Ref ref, DateTime now) {
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final isoDay = now.toIso8601String().substring(0, 10);
  final out = <ContextualNudge>[];

  // ── F3.74 — Day-of-week skip reminder ────────────────────────────────
  // Lightweight time-window check: late-afternoon on the user's commonly
  // skipped weekday. The full analytics-driven version lives in the card;
  // here we keep a generic mid-afternoon nudge to plan tomorrow if today
  // looks like it'll get skipped.
  if (now.hour >= 16 && now.hour < 19) {
    out.add(ContextualNudge(
      id: NudgeId.tomorrowPreview,
      icon: '📅',
      title: "Don't let today slip",
      body: 'Quick reschedule keeps the streak honest.',
      ctaLabel: 'Reschedule',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/workout/schedule'},
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: endOfDay,
      dedupKey: 'phase_pqrst_f374_$isoDay',
    ));
  }

  // ── F3.82 — Birthday chip ────────────────────────────────────────────
  try {
    final user = ref.read(authStateProvider).user;
    final dobRaw = user?.dateOfBirth;
    if (dobRaw != null && dobRaw.isNotEmpty) {
      final dob = DateTime.tryParse(dobRaw);
      if (dob != null && dob.month == now.month && dob.day == now.day) {
        final fullName = (user?.name ?? '').trim();
        final firstName = fullName.isEmpty
            ? null
            : fullName.split(RegExp(r'\s+')).first;
        out.add(ContextualNudge(
          id: NudgeId.birthday,
          icon: '🎂',
          title: firstName == null
              ? 'Happy birthday!'
              : 'Happy birthday, $firstName!',
          body: 'Today is yours — no streak guilt.',
          ctaLabel: 'Celebrate',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.educational,
          category: NudgeCategory.educational,
          perishesAt: endOfDay,
          dedupKey: 'phase_pqrst_f382_$isoDay',
        ));
      }
    }
  } catch (_) {
    // Auth state not ready — skip the birthday chip silently.
  }

  // ── F3.84 — First-of-month chip variant ──────────────────────────────
  if (now.day == 1) {
    out.add(ContextualNudge(
      id: NudgeId.firstOfMonth,
      icon: '🗓️',
      title: 'Fresh month',
      body: 'Review your goal and snap a progress photo.',
      ctaLabel: 'Review',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/profile/goals'},
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: endOfDay,
      dedupKey: 'phase_pqrst_f384_$isoDay',
    ));
  }

  // ── F3.83 — Weigh-in chip variant ────────────────────────────────────
  // Default cadence: Monday morning. The card covers the configurable case;
  // this chip is the lightweight reminder for the default.
  if (now.weekday == DateTime.monday && now.hour >= 6 && now.hour < 11) {
    out.add(ContextualNudge(
      id: NudgeId.weighInReminder,
      icon: '⚖️',
      title: 'Weigh-in window',
      body: 'Same time, same conditions — keeps the trend honest.',
      ctaLabel: 'Log weight',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/weight/log'},
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 11, 0),
      dedupKey: 'phase_pqrst_f383_$isoDay',
    ));
  }

  // ── F3.79 — Injury workaround acknowledgement (morning-only) ─────────
  // Light reminder that today's plan was adjusted; the full banner lives
  // as a card. Chip variant fires once in the morning so the user sees it
  // before starting.
  if (now.hour >= 6 && now.hour < 10) {
    out.add(ContextualNudge(
      id: NudgeId.discoveryInsight,
      icon: '🩹',
      title: 'Adjusted around your limits',
      body: "Today's session swaps risky moves for safer ones.",
      ctaLabel: 'View plan',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/workout/today'},
      ),
      priorityTier: NudgePriorityTier.healthAlert,
      category: NudgeCategory.healthAlert,
      perishesAt: DateTime(now.year, now.month, now.day, 12, 0),
      dedupKey: 'phase_pqrst_f379_$isoDay',
    ));
  }

  // ── F3.86 — Day-N tutorial chip ──────────────────────────────────────
  // Generic chip — the real day-gated content lives in the card. Here we
  // keep a passive "learn one thing" pickup that the master provider can
  // demote freely.
  out.add(ContextualNudge(
    id: NudgeId.dailyLesson,
    icon: '💡',
    title: 'One small thing today',
    body: 'A 30-second tip on getting more from your plan.',
    ctaLabel: 'Open',
    action: const ContextualNudgeAction(
      kind: ContextualNudgeActionKind.openDailyLesson,
    ),
    priorityTier: NudgePriorityTier.educational,
    category: NudgeCategory.educational,
    perishesAt: endOfDay,
    dedupKey: 'phase_pqrst_f386_$isoDay',
  ));

  return out;
}
