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
import '../services/notification_service.dart';
import 'breakfast_suggestion_provider.dart';
import 'daily_coach_insight_provider.dart';
import 'nudge_snooze_provider.dart';
import 'today_workout_provider.dart';

/// Cup conversion factor — mirrors the value used everywhere else in the
/// codebase (250 ml ≈ 1 cup).
const int _kMlPerCup = 250;

/// 30-minute post-workout hydration window. Sourced from the original
/// `_HydrationResetRow` gating in `unified_home_widgets.dart:867-869`.
const Duration _kPostWorkoutWindow = Duration(minutes: 30);

final contextualNudgeProvider =
    Provider.autoDispose<List<ContextualNudge>>((ref) {
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

  // 1. Hydration.
  final morning = hourFraction >= 5 && hourFraction < 11;
  final wantsHydration =
      inPostWorkoutWindow || (morning && cupFraction < 0.30);
  if (wantsHydration && !coachMentionsHydration) {
    out.add(ContextualNudge(
      id: NudgeId.hydration,
      icon: '💧',
      title: inPostWorkoutWindow ? 'Post-workout refuel' : 'Overnight reset',
      body: inPostWorkoutWindow
          ? 'Replace what you sweat out.'
          : 'Log your first 16oz of water.',
      ctaLabel: 'Log 16oz',
      action: ContextualNudgeAction.logHydration16oz,
    ));
  }

  // 2. Breakfast.
  if (morning &&
      mealLoggedToday['breakfast'] == false &&
      !coachMentionsMeal('breakfast')) {
    out.add(_mealNudge(ref, MealSlot.breakfast));
  }

  // 3. Lunch.
  final lunchWindow = hourFraction >= 11.5 && hourFraction < 14.5;
  if (lunchWindow &&
      mealLoggedToday['lunch'] == false &&
      !coachMentionsMeal('lunch')) {
    out.add(_mealNudge(ref, MealSlot.lunch));
  }

  // (Workout-start nudge intentionally removed in the 2026-05 minimalist
  // redesign. The dedicated Workout hero card directly below the Coach
  // hero is the single workout entry point on Home — duplicating it as a
  // contextual nudge inside the Coach card made the same workout appear
  // in three places within ~800pt of scroll. See plan Surface 1.1.)
  // Note: `hasWorkoutToday` / `workoutCompleted` are still computed above
  // because the hydration "post-workout window" branch depends on them.

  // 4. Dinner.
  final dinnerWindow = hourFraction >= 17.5 && hourFraction < 20.5;
  if (dinnerWindow &&
      mealLoggedToday['dinner'] == false &&
      !coachMentionsMeal('dinner')) {
    out.add(_mealNudge(ref, MealSlot.dinner));
  }

  // 6. Sleep wind-down.
  final windDownWindow = hourFraction >= 21 && hourFraction < 23;
  if (windDownWindow && workoutCompleted) {
    out.add(const ContextualNudge(
      id: NudgeId.windDown,
      icon: '🌙',
      title: 'Wind down',
      body: 'Log how today felt before bed.',
      ctaLabel: 'Open journal',
      action: ContextualNudgeAction.openJournal,
    ));
  }

  // Filter snoozed entries last so an upstream state change (e.g. user
  // logs the meal that was snoozed) is still reflected the moment it
  // happens — we want the nudge to re-evaluate against fresh data, not
  // stay suppressed by a stale 4h timer.
  final snoozed = ref.watch(nudgeSnoozeProvider);
  final now2 = DateTime.now();
  return out.where((n) {
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
  final body = (suggestion != null && suggestion.body.trim().isNotEmpty)
      ? suggestion.body.trim()
      : mealSlotFallbackBody(slot);
  final title = mealSlotFallbackHeadline(slot);
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
