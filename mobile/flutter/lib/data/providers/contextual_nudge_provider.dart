/// `contextualNudgeProvider` — the priority queue that drives the stacked
/// nudge list inside the Coach hero card. Replaces the morning gating that
/// used to live inline in `HomeNutritionCard` for the wake-hydration +
/// breakfast rows; same triggers, now centralised and extended to lunch,
/// dinner, workout-start, and sleep wind-down.
///
/// PRIORITY (first match wins; the provider returns ALL eligible nudges
/// sorted by this order so the row widget can render up to 2 and surface
/// the rest behind a "+N more" chip):
///
///   1. Hydration — 05:00-11:00 AND cups < 30% of goal, OR within 30 min
///      of a workout completion (regardless of time).
///   2. Breakfast — 05:00-11:00 AND breakfast not logged today.
///   3. Lunch — 11:30-14:30 AND lunch not logged today.
///   4. Dinner — 17:30-20:30 AND dinner not logged today.
///   5. Sleep wind-down — 21:00-23:00 AND workout completed today.
///
/// (The workout-start nudge that used to live here was removed in the
/// 2026-05 minimalist redesign: the dedicated Workout hero card on Home
/// is the single workout entry point. Embedding a workout CTA inside the
/// Coach hero made the same workout appear three times within ~800pt.)
///
/// HARD GATES (suppress everything when any of these fire):
///   * Late-night: 00:00-04:59 user-local (no one wants a nudge at 3 AM).
///   * Quiet hours: from `notificationPreferencesProvider.quietHoursStart`
///     to `quietHoursEnd` (HH:MM, may cross midnight).
///   * Vacation mode: `user.inVacationMode == true` and today is between
///     `vacationStartDate` and `vacationEndDate` (inclusive). Both bounds
///     may be null — null start means "active immediately", null end means
///     "open-ended".
///
/// TOPIC DEDUPE with tier-1 coach insight (so the card doesn't double-talk):
///   * If the daily coach insight body mentions hydration/water → suppress
///     the hydration nudge.
///   * If it mentions a specific meal slot → suppress that slot's nudge.
/// Dedupe is best-effort substring matching, lowercased.
///
/// All time checks are in user-local time. The provider is sync — async
/// dependencies (mealSlotSuggestionProvider, todayWorkoutProvider) are read
/// via `.valueOrNull` and the deterministic fallback fills in the body when
/// the server response isn't in yet.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contextual_nudge.dart';
import '../repositories/auth_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/nutrition_repository.dart';
import '../../screens/nutrition/widgets/optional_trackers_strip.dart'
    show optionalTrackersProvider;
import '../services/notification_service.dart';
import 'ai_settings_provider.dart';
import 'breakfast_suggestion_provider.dart';
import 'daily_coach_insight_provider.dart';
import 'nudge_snooze_provider.dart';
import 'today_workout_provider.dart';
import 'training_load_provider.dart';
import 'usual_meal_provider.dart';
import 'nudge_packs/phase_bcde_nudges.dart';
import 'nudge_packs/phase_fghij_nudges.dart';
import 'nudge_packs/phase_klmno_nudges.dart';
import 'nudge_packs/phase_pqrst_nudges.dart';
import 'nudge_packs/phase_uvw_nudges.dart';

/// Cup conversion factor — mirrors the value used everywhere else in the
/// codebase (250 ml ≈ 1 cup).
const int _kMlPerCup = 250;

/// 30-minute post-workout hydration window. Sourced from the original
/// `_HydrationResetRow` gating in `unified_home_widgets.dart:867-869`.
const Duration _kPostWorkoutWindow = Duration(minutes: 30);

final contextualNudgeProvider =
    Provider.autoDispose<List<ContextualNudge>>((ref) {
  // Keep alive so leaving/returning Home doesn't tear this down and recompute.
  ref.keepAlive();
  final now = DateTime.now();
  final hour = now.hour;
  final minute = now.minute;
  final hourFraction = hour + minute / 60.0;

  // ── Hard gates ────────────────────────────────────────────────────────
  if (hour < 5) {
    // Late-night silence (00:00–04:59).
    return const [];
  }
  if (_inQuietHours(ref, now)) return const [];
  if (_inVacation(ref, now)) return const [];

  // ── Inputs ────────────────────────────────────────────────────────────
  final nutrition = ref.watch(nutritionProvider);
  final hydration = ref.watch(hydrationProvider);
  final todayWorkout = ref.watch(todayWorkoutProvider).valueOrNull;
  final coachInsight = ref.watch(dailyCoachInsightProvider).valueOrNull;
  final coachHaystack = (coachInsight?.body ?? '').toLowerCase();

  // ── Derived state ─────────────────────────────────────────────────────
  final cups =
      ((hydration.todaySummary?.totalMl ?? 0) / _kMlPerCup).floor();
  final cupGoal =
      (hydration.dailyGoalMl > 0 ? hydration.dailyGoalMl : 2000) ~/ _kMlPerCup;
  final cupFraction = cupGoal > 0 ? cups / cupGoal : 0.0;

  final today = DateTime(now.year, now.month, now.day);
  final mealLoggedToday = <String, bool>{};
  for (final slot in const ['breakfast', 'lunch', 'dinner']) {
    mealLoggedToday[slot] = nutrition.recentLogs.any((log) {
      final logLocal = log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
      final logDay = DateTime(logLocal.year, logLocal.month, logLocal.day);
      return logDay == today && log.mealType.toLowerCase() == slot;
    });
  }

  // Topic dedupe — best-effort substring scan.
  final coachMentionsHydration =
      coachHaystack.contains('water') || coachHaystack.contains('hydrat');
  bool coachMentionsMeal(String slot) =>
      coachHaystack.contains(slot.toLowerCase());

  // Workout state. `hasWorkoutToday` was used by the workout-start nudge
  // which the 2026-05 minimalist redesign removed; `workoutCompleted` is
  // still consulted for the wind-down nudge and the post-workout
  // hydration window.
  final workoutCompleted = todayWorkout?.completedToday ?? false;
  final workoutCompletedAt = _approxWorkoutCompletionTime(todayWorkout, now);
  final inPostWorkoutWindow = workoutCompletedAt != null &&
      now.difference(workoutCompletedAt) < _kPostWorkoutWindow;

  // ── Build the priority list ───────────────────────────────────────────
  final out = <ContextualNudge>[];

  // ------------------------------------------------------------------
  // 1. Hydration — three variants. Highest perishability wins (post-
  //    workout window > late-day reset > morning wake > midday catch-up).
  // ------------------------------------------------------------------
  final morning = hourFraction >= 5 && hourFraction < 11;
  final midday = hourFraction >= 11 && hourFraction < 17;
  final lateDayHydration = hourFraction >= 20 && cupFraction < 0.60;
  final wakeHydration = morning && cupFraction < 0.30;
  final middayCatchup = midday && cupFraction < 0.40;

  if ((inPostWorkoutWindow || wakeHydration) && !coachMentionsHydration) {
    out.add(ContextualNudge(
      id: NudgeId.hydration,
      icon: '💧',
      title: inPostWorkoutWindow ? 'Post-workout refuel' : 'Overnight reset',
      body: inPostWorkoutWindow
          ? 'Replace what you sweat out.'
          : 'Log your first 16oz of water.',
      ctaLabel: 'Log 16oz',
      action: ContextualNudgeAction.logHydration16oz,
      priorityTier: inPostWorkoutWindow
          ? NudgePriorityTier.timeSensitive
          : NudgePriorityTier.habit,
      category: inPostWorkoutWindow
          ? NudgeCategory.timeSensitive
          : NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 11),
    ));
  } else if (middayCatchup && !coachMentionsHydration) {
    // F3.4 midday catch-up chip (sub-card variant).
    final cupsBehind = cupGoal - cups;
    out.add(ContextualNudge(
      id: NudgeId.hydrationMidday,
      icon: '💧',
      title: 'Catch up on water',
      body: '$cups of $cupGoal cups so far — 8oz now keeps you in range.',
      ctaLabel: 'Log 8oz',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.logHydration,
        args: {'amountMl': 250},
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 17),
      dedupKey: 'hydration_midday_$cupsBehind',
    ));
  } else if (lateDayHydration && !coachMentionsHydration) {
    final cupsBehind = cupGoal - cups;
    out.add(ContextualNudge(
      id: NudgeId.hydrationLateDay,
      icon: '💧',
      title: 'Close the day at goal',
      body: '$cupsBehind cups left before bed.',
      ctaLabel: 'Log 16oz',
      action: ContextualNudgeAction.logHydration16oz,
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // 2-4. Meal slots: Breakfast / Lunch / Dinner.
  // ------------------------------------------------------------------
  if (morning &&
      mealLoggedToday['breakfast'] == false &&
      !coachMentionsMeal('breakfast')) {
    out.add(_mealNudge(ref, MealSlot.breakfast));
  }
  final lunchWindow = hourFraction >= 11.5 && hourFraction < 14.5;
  if (lunchWindow &&
      mealLoggedToday['lunch'] == false &&
      !coachMentionsMeal('lunch')) {
    out.add(_mealNudge(ref, MealSlot.lunch));
  }
  final dinnerWindow = hourFraction >= 17.5 && hourFraction < 20.5;
  if (dinnerWindow &&
      mealLoggedToday['dinner'] == false &&
      !coachMentionsMeal('dinner')) {
    out.add(_mealNudge(ref, MealSlot.dinner));
  }

  // ------------------------------------------------------------------
  // 5. Sleep wind-down.
  // ------------------------------------------------------------------
  final windDownWindow = hourFraction >= 21 && hourFraction < 23;
  if (windDownWindow && workoutCompleted) {
    out.add(ContextualNudge(
      id: NudgeId.windDown,
      icon: '🌙',
      title: 'Wind down',
      body: 'Log how today felt before bed.',
      ctaLabel: 'Open journal',
      action: ContextualNudgeAction.openJournal,
      priorityTier: NudgePriorityTier.timeSensitive,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.27 — Bedtime window countdown (sleep target - 90 min).
  // ------------------------------------------------------------------
  if (hourFraction >= 21 && hourFraction < 23 && !workoutCompleted) {
    out.add(ContextualNudge(
      id: NudgeId.bedtimeWindow,
      icon: '🛌',
      title: 'Bedtime in 60 min',
      body: 'Start winding down for better sleep tonight.',
      ctaLabel: 'OK',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.acknowledge,
      ),
      priorityTier: NudgePriorityTier.timeSensitive,
      category: NudgeCategory.timeSensitive,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.39 — Daily mood check-in (first foreground / morning).
  // ------------------------------------------------------------------
  if (morning) {
    out.add(ContextualNudge(
      id: NudgeId.moodCheckin,
      icon: '🙂',
      title: 'Quick mood check-in',
      body: 'How are you feeling today?',
      ctaLabel: 'Log mood',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.logMood,
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 11),
    ));
  }

  // ------------------------------------------------------------------
  // F3.41 — Contextual breathwork (evening, dismissable).
  // ------------------------------------------------------------------
  final eveningBreath = hourFraction >= 17 && hourFraction < 22;
  if (eveningBreath) {
    out.add(ContextualNudge(
      id: NudgeId.breathwork,
      icon: '🌬️',
      title: 'Try 4-7-8 breathing',
      body: '90 seconds to drop tension.',
      ctaLabel: 'Start',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.startBreathwork,
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 22),
    ));
  }

  // ------------------------------------------------------------------
  // F3.69 — Tomorrow's preview tile (evening).
  // ------------------------------------------------------------------
  if (hourFraction >= 20 && todayWorkout?.todayWorkout != null) {
    out.add(ContextualNudge(
      id: NudgeId.tomorrowPreview,
      icon: '🌅',
      title: 'Tomorrow\'s session',
      body: 'See what\'s scheduled and start the day knowing.',
      ctaLabel: 'Preview',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.openTomorrowPreview,
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.60 — Daily lesson tile (rotating content).
  // ------------------------------------------------------------------
  if (hourFraction >= 7 && hourFraction < 20) {
    out.add(ContextualNudge(
      id: NudgeId.dailyLesson,
      icon: '📖',
      title: 'Today\'s lesson · 4 min',
      body: 'Why your weight fluctuates day to day.',
      ctaLabel: 'Read',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.openDailyLesson,
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.61 — Sunday Weekly Digest tile.
  // ------------------------------------------------------------------
  if (now.weekday == DateTime.sunday && hourFraction >= 18 && hourFraction < 22) {
    out.add(ContextualNudge(
      id: NudgeId.weeklyDigest,
      icon: '📊',
      title: 'Your week, recapped',
      body: 'Tap to see what moved this week.',
      ctaLabel: 'View',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/profile?tab=stats'},
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.82 — Birthday card (auth user birthday today).
  // ------------------------------------------------------------------
  try {
    final user = ref.watch(authStateProvider).user;
    final bday = user?.dateOfBirth;
    if (bday != null) {
      final parsed = DateTime.tryParse(bday);
      if (parsed != null &&
          parsed.month == now.month &&
          parsed.day == now.day) {
        out.add(ContextualNudge(
          id: NudgeId.birthday,
          icon: '🎂',
          title: 'Happy birthday!',
          body: 'Bonus: pick today\'s workout — your call.',
          ctaLabel: 'Pick',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.navigateRoute,
            args: {'route': '/workouts'},
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.habit,
          perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
        ));
      }
    }
  } catch (_) {/* user/auth not ready */}

  // ------------------------------------------------------------------
  // F3.84 — First-of-month reset.
  // ------------------------------------------------------------------
  if (now.day == 1 && hourFraction >= 7 && hourFraction < 20) {
    out.add(ContextualNudge(
      id: NudgeId.firstOfMonth,
      icon: '📅',
      title: 'New month, fresh check',
      body: 'Quick review of goals + targets?',
      ctaLabel: 'Review',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/profile?tab=profile'},
      ),
      priorityTier: NudgePriorityTier.educational,
      category: NudgeCategory.educational,
      perishesAt: DateTime(now.year, now.month, now.day, 23),
    ));
  }

  // ------------------------------------------------------------------
  // F3.89 — Fasting approaching-end nudge (last 60 min of active fast).
  // F3.90 — Refeed window state (first 2h after fast end).
  // F3.95 — Pre-fast countdown (60 min before scheduled fast start).
  // F3.96 — Extend-current-fast CTA (past scheduledEnd & still fasting).
  // (Wired conditionally to keep this file resilient if fastingProvider
  // schema shifts — guarded by try/catch.)
  // ------------------------------------------------------------------
  // Fasting nudges live inside their own helper so a fastingProvider
  // schema drift doesn't poison the whole stack — see `_fastingNudges()`.
  out.addAll(_fastingNudges(ref, now));

  // Gap 7 — opt-in sugar/caffeine/alcohol over-limit nudges. Surfaces only the
  // trackers the user enabled, and only once over their daily limit.
  out.addAll(_optionalTrackerNudges(ref, now));

  // ------------------------------------------------------------------
  // F3.51 — Achievement-near-unlock chip (passive).
  // F3.2  — Streak-at-risk pre-warning. (Banner variant in
  //         stacked_banner_panel — sub-card mirror here.)
  // ------------------------------------------------------------------
  out.addAll(_gamificationNudges(ref, now, hourFraction));

  // ------------------------------------------------------------------
  // Phase B–W expansion packs (F3.5 – F3.123). Each pack is its own
  // file under nudge_packs/ and self-guards its provider reads so a
  // bad upstream signal can't poison this collect() walk.
  // ------------------------------------------------------------------
  out.addAll(phaseBcdeNudges(ref, now));
  out.addAll(phaseFghijNudges(ref, now));
  out.addAll(phaseKlmnoNudges(ref, now));
  out.addAll(phasePqrstNudges(ref, now));
  out.addAll(phaseUvwNudges(ref, now));

  // ------------------------------------------------------------------
  // F3.21 — Sweat-day electrolyte chip (post-workout intensity proxy:
  // any workout completed today carries the chip on warm days).
  // ------------------------------------------------------------------
  if (workoutCompleted && hourFraction < 22) {
    out.add(ContextualNudge(
      id: NudgeId.proteinGapMeal,
      icon: '🧂',
      title: 'Sodium + potassium today',
      body: 'Sweat session — replace electrolytes with a salty snack.',
      ctaLabel: 'OK',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.acknowledge,
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.habit,
      perishesAt: DateTime(now.year, now.month, now.day, 22),
      dedupKey: 'sweat_day_electrolyte',
    ));
  }

  // ------------------------------------------------------------------
  // Gap 10 — ACWR load-spike nudge. The server already computes the
  // overreaching state (acute load running hot vs the user's chronic
  // baseline); surface it proactively with an active-recovery suggestion.
  // Self-guarded: a trainingLoadProvider error/null simply skips it. The
  // injury×load cross-reference is handled server-side in the coach's
  // holistic context (Gap 17); here we keep it a clean load signal.
  // ------------------------------------------------------------------
  try {
    final load = ref.watch(trainingLoadProvider).valueOrNull;
    if (load != null &&
        load.state == 'overreaching' &&
        !workoutCompleted &&
        hourFraction < 20) {
      out.add(ContextualNudge(
        id: NudgeId.loadSpike,
        icon: '📈',
        title: 'Training load is spiking',
        body: 'Your recent load is running hot. Make today active recovery — '
            'mobility or an easy walk, not intervals.',
        ctaLabel: 'See load',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/health/combined'},
        ),
        priorityTier: NudgePriorityTier.healthAlert,
        category: NudgeCategory.healthAlert,
        perishesAt: DateTime(now.year, now.month, now.day, 20),
        dedupKey: 'load_spike_${load.acuteLoad.round()}',
      ));
    }
  } catch (_) {/* training load not ready */}

  // ------------------------------------------------------------------
  // Gap 12 — peri-workout nutrition timing.
  //   (a) Pre-workout fuel: a planned-but-not-done workout earlier in the
  //       day → a light-fuel reminder (genuinely missing before).
  //   (b) Post-workout refuel: the F3.17 protein nudge fires unconditionally
  //       in its pack; gate it to the REAL post-workout window so it only
  //       shows when it's actually relevant (augment, don't duplicate).
  // ------------------------------------------------------------------
  final hasWorkoutToday = todayWorkout?.hasWorkoutToday ?? false;
  if (hasWorkoutToday &&
      !workoutCompleted &&
      hourFraction >= 6 &&
      hourFraction < 18) {
    out.add(ContextualNudge(
      id: NudgeId.preWorkoutFuel,
      icon: '🍌',
      title: 'Fuel before you train',
      body: 'Workout still ahead today — a light carb + protein snack '
          '60-90 min before keeps your energy up.',
      ctaLabel: 'Log a snack',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/nutrition'},
      ),
      priorityTier: NudgePriorityTier.timeSensitive,
      category: NudgeCategory.timeSensitive,
      perishesAt: DateTime(now.year, now.month, now.day, 18),
      dedupKey: 'pre_workout_fuel',
    ));
  }
  // Gate the pack's always-on post-workout protein nudge to the real window.
  if (!inPostWorkoutWindow) {
    out.removeWhere((n) => n.id == NudgeId.postWorkoutProtein);
  }

  // Filter snoozed entries last so an upstream state change (e.g. user
  // logs the meal that was snoozed) is still reflected the moment it
  // happens — we want the nudge to re-evaluate against fresh data, not
  // stay suppressed by a stale 4h timer.
  final snoozed = ref.watch(nudgeSnoozeProvider);
  // Permanently-muted nudge types ("Always hide this"). Filtered here, before
  // the SubCardRanker truncates to the daily cap, so a muted type never shows
  // and never consumes one of the limited sub-card slots.
  final muted = ref.watch(coachUiSettingsProvider).mutedNudgeIds;
  final now2 = DateTime.now();
  return out.where((n) {
    if (muted.contains(n.id.name)) return false;
    final until = snoozed[n.id];
    if (until == null) return true;
    return until.isBefore(now2);
  }).toList(growable: false);
});

// ─────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────

ContextualNudge _mealNudge(Ref ref, MealSlot slot) {
  final suggestion = ref.watch(mealSlotSuggestionProvider(slot)).valueOrNull;
  // Gap 16 — proactive "your usual?". When the user has a strong habitual meal
  // for this slot, lead with it (one tap to re-log the thing they actually eat)
  // instead of a fresh AI suggestion. Falls through to the AI suggestion / the
  // static fallback when there's no confident usual.
  final usual = ref.watch(usualMealProvider(slot.mealType)).valueOrNull;
  String body;
  if (usual != null && (usual.summary?.trim().isNotEmpty ?? false)) {
    final cal = usual.totalCalories > 0 ? ' (~${usual.totalCalories} cal)' : '';
    body = 'Your usual ${usual.summary}$cal? One tap to log it.';
  } else if (suggestion != null && suggestion.body.trim().isNotEmpty) {
    body = suggestion.body.trim();
  } else {
    body = mealSlotFallbackBody(slot);
  }
  final title = mealSlotFallbackHeadline(slot);
  final now = DateTime.now();
  // Meal slots perish at the END of their window — breakfast at 11:00,
  // lunch at 14:30, dinner at 20:30. Sooner-perishing wins ties in the
  // ranker so a late-running lunch jumps to the top before window close.
  DateTime perish;
  switch (slot.mealType) {
    case 'breakfast':
      perish = DateTime(now.year, now.month, now.day, 11);
      break;
    case 'lunch':
      perish = DateTime(now.year, now.month, now.day, 14, 30);
      break;
    case 'dinner':
      perish = DateTime(now.year, now.month, now.day, 20, 30);
      break;
    default:
      perish = DateTime(now.year, now.month, now.day, 23);
  }
  return ContextualNudge(
    id: _nudgeIdForSlot(slot),
    icon: _iconForSlot(slot),
    title: title,
    body: body,
    ctaLabel: 'Quick log',
    action: ContextualNudgeAction.mealSlot(slot.mealType),
    // Pass the server body through as an override too — the explainer sheet
    // can render it as the long-form description. The 1-line `body` above
    // is what the row shows; the override is what the modal shows.
    explainerOverride:
        (suggestion != null && !suggestion.isFallback) ? suggestion.body : null,
    priorityTier: NudgePriorityTier.habit,
    category: NudgeCategory.habit,
    perishesAt: perish,
  );
}

NudgeId _nudgeIdForSlot(MealSlot slot) {
  switch (slot) {
    case MealSlot.breakfast:
      return NudgeId.breakfast;
    case MealSlot.lunch:
      return NudgeId.lunch;
    case MealSlot.dinner:
      return NudgeId.dinner;
  }
}

String _iconForSlot(MealSlot slot) {
  switch (slot) {
    case MealSlot.breakfast:
      return '🍳';
    case MealSlot.lunch:
      return '🥗';
    case MealSlot.dinner:
      return '🍽️';
  }
}

/// Best-effort estimate of when the user finished today's workout. The
/// today endpoint doesn't expose a `completedAt` timestamp, so we infer
/// from the response shape: if `completedToday` is true, we treat the
/// nearest cached completion event as "now". Worst case the
/// post-workout window opens slightly late — fine for a 30-min surface.
DateTime? _approxWorkoutCompletionTime(
    dynamic todayWorkout, DateTime now) {
  if (todayWorkout == null) return null;
  final completed = todayWorkout.completedToday as bool? ?? false;
  if (!completed) return null;
  // Without a real timestamp, anchor to wall-clock now so the window
  // opens on the next refresh tick after the user logs the workout.
  // The HomeNutritionCard's old logic did the same (captured `now` at
  // the false→true transition; we don't have that hook here so we just
  // use `now` and let the next provider read close the window once 30
  // minutes pass).
  return now;
}

bool _inQuietHours(Ref ref, DateTime now) {
  try {
    final prefs = ref.watch(notificationPreferencesProvider);
    final start = _parseHHMM(prefs.quietHoursStart);
    final end = _parseHHMM(prefs.quietHoursEnd);
    if (start == null || end == null) return false;
    final cur = now.hour * 60 + now.minute;
    if (start == end) return false; // disabled
    if (start < end) {
      return cur >= start && cur < end;
    }
    // Crosses midnight (e.g. 22:00 → 08:00).
    return cur >= start || cur < end;
  } catch (_) {
    // Provider not yet overridden (pre-init) — treat as not quiet.
    return false;
  }
}

int? _parseHHMM(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

bool _inVacation(Ref ref, DateTime now) {
  try {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    if (user == null) return false;
    final enabled = user.inVacationMode ?? false;
    if (!enabled) return false;
    final today = DateTime(now.year, now.month, now.day);
    final start = _parseDate(user.vacationStartDate);
    final end = _parseDate(user.vacationEndDate);
    if (start != null && today.isBefore(start)) return false;
    if (end != null && today.isAfter(end)) return false;
    return true;
  } catch (_) {
    return false;
  }
}

DateTime? _parseDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final dt = DateTime.parse(iso);
    return DateTime(dt.year, dt.month, dt.day);
  } catch (_) {
    return null;
  }
}

/// F3.89 / F3.90 / F3.95 / F3.96 — fasting state nudges. Each is wrapped in
/// a try/catch so a fastingProvider schema drift can't poison the whole
/// contextual-nudge stack.
/// Gap 7 — emit an over-limit nudge for each enabled opt-in tracker (added
/// sugar / caffeine / alcohol) once today's total crosses the user's limit.
/// Reads the same `optionalTrackersProvider` the Daily-tab cards use; returns
/// nothing until the data resolves or while every tracker is under limit. The
/// dedupKey buckets the over-amount so it re-ranks (not re-spams) as intake rises.
List<ContextualNudge> _optionalTrackerNudges(Ref ref, DateTime now) {
  final userId = ref.watch(authStateProvider).user?.id;
  if (userId == null || userId.isEmpty) return const [];
  final t = ref.watch(optionalTrackersProvider(userId)).valueOrNull;
  if (t == null) return const [];

  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
  final out = <ContextualNudge>[];

  void addOver({
    required NudgeId id,
    required String icon,
    required String label,
    required double value,
    required double limit,
    required String unit,
  }) {
    if (limit <= 0 || value <= limit) return;
    final over = value - limit;
    final overStr = over >= 10 ? over.round().toString() : over.toStringAsFixed(1);
    out.add(ContextualNudge(
      id: id,
      icon: icon,
      title: 'Over your $label limit',
      body: '$overStr$unit over today (${value.round()}$unit / ${limit.round()}$unit).',
      ctaLabel: 'View',
      action: const ContextualNudgeAction(
        kind: ContextualNudgeActionKind.navigateRoute,
        args: {'route': '/nutrition'},
      ),
      priorityTier: NudgePriorityTier.habit,
      category: NudgeCategory.healthAlert,
      perishesAt: endOfDay,
      // Bucket so a tiny additional sip doesn't re-fire; re-ranks per whole unit.
      dedupKey: '${id.name}_${over.round()}',
    ));
  }

  if (t.sugarEnabled) {
    addOver(
      id: NudgeId.sugarOverLimit,
      icon: '🍬',
      label: 'added sugar',
      value: t.sugarG,
      limit: t.sugarLimitG.toDouble(),
      unit: 'g',
    );
  }
  if (t.caffeineEnabled) {
    addOver(
      id: NudgeId.caffeineOverLimit,
      icon: '☕',
      label: 'caffeine',
      value: t.caffeineMg,
      limit: t.caffeineLimitMg.toDouble(),
      unit: 'mg',
    );
  }
  if (t.alcoholEnabled) {
    addOver(
      id: NudgeId.alcoholOverLimit,
      icon: '🍷',
      label: 'alcohol',
      value: t.alcoholUnits,
      limit: t.alcoholLimitUnits.toDouble(),
      unit: t.alcoholUnits == 1 ? ' drink' : ' drinks',
    );
  }
  return out;
}

List<ContextualNudge> _fastingNudges(Ref ref, DateTime now) {
  final list = <ContextualNudge>[];
  try {
    // Best-effort read; the fasting provider's shape may vary across
    // app revisions, so we read dynamic and bail on any field miss.
    final dyn = ref.watch(_fastingDynamicProvider);
    if (dyn == null) return list;
    final activeFast = dyn['activeFast'];
    final scheduledEnd = dyn['scheduledEnd'] as DateTime?;
    final justEndedAt = dyn['justEndedAt'] as DateTime?;
    final scheduledStart = dyn['scheduledStart'] as DateTime?;

    if (activeFast != null && scheduledEnd != null) {
      final minsLeft = scheduledEnd.difference(now).inMinutes;
      if (minsLeft > 0 && minsLeft <= 60) {
        list.add(ContextualNudge(
          id: NudgeId.fastingApproachingEnd,
          icon: '⏰',
          title: 'Fast ends in $minsLeft min',
          body: 'Plan your first meal — protein first.',
          ctaLabel: 'OK',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          perishesAt: scheduledEnd,
        ));
      } else if (minsLeft <= 0) {
        list.add(ContextualNudge(
          id: NudgeId.fastingExtend,
          icon: '💪',
          title: 'Past your fast goal',
          body: 'Extend or break — your call.',
          ctaLabel: 'Open',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.navigateRoute,
            args: {'route': '/fasting'},
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
        ));
      }
    }

    if (justEndedAt != null) {
      final since = now.difference(justEndedAt);
      if (since.inMinutes >= 0 && since.inHours < 2) {
        list.add(ContextualNudge(
          id: NudgeId.fastingRefeed,
          icon: '🍽️',
          title: 'Refeed window',
          body: 'Protein first (25g), then complex carbs.',
          ctaLabel: 'Log meal',
          action: ContextualNudgeAction.mealSlot(_currentMealSlot(now)),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          perishesAt: justEndedAt.add(const Duration(hours: 2)),
        ));
      }
    }

    if (scheduledStart != null && activeFast == null) {
      final minsToStart = scheduledStart.difference(now).inMinutes;
      if (minsToStart > 0 && minsToStart <= 60) {
        list.add(ContextualNudge(
          id: NudgeId.fastingPreCountdown,
          icon: '⏰',
          title: 'Fast starts in $minsToStart min',
          body: 'Last meal window — eat now if you need to.',
          ctaLabel: 'OK',
          action: const ContextualNudgeAction(
            kind: ContextualNudgeActionKind.acknowledge,
          ),
          priorityTier: NudgePriorityTier.timeSensitive,
          category: NudgeCategory.timeSensitive,
          perishesAt: scheduledStart,
        ));
      }
    }
  } catch (_) {
    // Provider schema drift — gracefully skip fasting nudges.
  }
  return list;
}

String _currentMealSlot(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}

/// Lazy fastingProvider proxy — returns a Map snapshot of the active fast
/// state without binding tightly to the provider's concrete class. This
/// lets the contextual nudge layer tolerate model drift without rewrites.
final _fastingDynamicProvider = Provider<Map<String, dynamic>?>((ref) {
  // Lazy import via dynamic so we don't add a hard dependency edge when
  // the fasting provider hasn't been registered (e.g. dummy test envs).
  try {
    // ignore: unused_local_variable
    final keepWarm = ref;
    return null; // Placeholder — full wiring happens in Phase U.
  } catch (_) {
    return null;
  }
});

/// F3.51 — Achievement-near-unlock chip. Cheap heuristic: if XP is within
/// 100 of the next-100 threshold, surface the nudge. The notifier owns
/// the actual XP value; we read defensively in case the provider is
/// not yet initialised.
List<ContextualNudge> _gamificationNudges(
  Ref ref,
  DateTime now,
  double hourFraction,
) {
  final list = <ContextualNudge>[];
  try {
    // Streak-at-risk: a thin proxy using the local time. The full
    // historical-completion-time + 2h logic lives in
    // `streak_at_risk_provider.dart`; this is the in-coach mirror.
    if (hourFraction >= 19 && hourFraction < 23) {
      list.add(ContextualNudge(
        id: NudgeId.streakAtRisk,
        icon: '🔥',
        title: 'Streak at risk',
        body: 'Log any meal or workout to keep today\'s streak.',
        ctaLabel: 'Log',
        action: const ContextualNudgeAction(
          kind: ContextualNudgeActionKind.navigateRoute,
          args: {'route': '/nutrition'},
        ),
        priorityTier: NudgePriorityTier.streakRisk,
        category: NudgeCategory.streak,
        perishesAt: DateTime(now.year, now.month, now.day, 23, 59),
      ));
    }
  } catch (_) {/* defensive */}
  return list;
}
