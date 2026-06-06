/// `coachRefreshCoordinatorProvider` — keeps the Home coach card in sync with
/// freshly-logged data (meals, workouts, fasts, sleep) WITHOUT the user pulling
/// to refresh.
///
/// It listens to the four data sources and, on a change, refreshes the coach
/// insight at one of two speeds:
///
///   * NUMBERS (cheap) — every relevant change debounces a `fresh=true` fetch
///     that recomputes the grounded graph blocks from the DB but reuses the
///     CACHED AI text (no Gemini call). The graphs reflect the new data within
///     ~1s; the text is untouched.
///   * TEXT (expensive) — only completion-class transitions (workout finished,
///     fast ended, sleep logged, the first meal of the day) trigger a
///     `refresh=true` regenerate of the headline/body, throttled to a minimum
///     gap so the narrative doesn't churn and Gemini calls stay bounded.
///
/// Both paths write the fresh payload THROUGH the home disk cache (in the
/// refresh providers) and then invalidate [dailyCoachInsightProvider], so the
/// card swaps in place. The card renders the previous value during the reload
/// (no skeleton flash) and keeps the last-good insight if the fetch fails.
///
/// Mounted once, app-wide, from `main_shell.dart` (`ref.watch`), so it fires
/// regardless of which tab the log happened on — logging from the Nutrition /
/// Workout / Fasting tab still updates Home in the background.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coach_card_visibility_provider.dart';
import 'daily_coach_insight_provider.dart';
import 'fasting_provider.dart';
import 'recovery_provider.dart' show sleepProvider;
import 'today_workout_provider.dart';
import '../repositories/nutrition_repository.dart';

/// Coalescing window for cheap numbers refreshes — a burst of logs (e.g. three
/// foods added in quick succession) collapses into ONE network fetch.
const _kNumbersDebounce = Duration(milliseconds: 1200);

/// Debounce for the expensive text regenerate — slightly longer so a logging
/// session settles before we spend a Gemini call.
const _kTextDebounce = Duration(milliseconds: 2500);

/// Minimum gap between two AUTOMATIC text regenerates. Keeps the narrative from
/// rewriting on every completion within a short window (and bounds AI cost).
/// The manual long-press / ⋮ refresh has its own separate 30-min guard.
const _kTextMinGap = Duration(minutes: 10);

final coachRefreshCoordinatorProvider =
    Provider<CoachRefreshCoordinator>((ref) {
  final coord = CoachRefreshCoordinator(ref);
  coord._wire();
  ref.onDispose(coord._dispose);
  return coord;
});

class CoachRefreshCoordinator {
  CoachRefreshCoordinator(this._ref);

  final Ref _ref;

  Timer? _numbersTimer;
  Timer? _textTimer;
  DateTime? _lastTextRefreshAt;
  bool _textInFlight = false;

  // Last-seen signals. `null` = not seen yet → the first emission of each
  // source is the initial load, NOT a log, so it never triggers a refresh.
  int? _lastCalories;
  bool? _lastWorkoutCompleted;
  bool? _lastFastActive;
  int? _lastSleepMinutes;

  void _wire() {
    // Nutrition — any change to today's calories refreshes the numbers; the
    // FIRST meal of the day (0 → >0) is a completion-class event → regenerate
    // text so the body can acknowledge the day has started.
    _ref.listen(nutritionProvider, (prev, next) {
      final cal = next.todaySummary?.totalCalories ?? 0;
      final prevCal = _lastCalories;
      _lastCalories = cal;
      if (prevCal == null || cal == prevCal) return;
      if (prevCal == 0 && cal > 0) {
        bumpText();
      } else {
        bumpNumbers();
      }
    }, fireImmediately: true);

    // Workout — completion (a completedWorkout appears) regenerates text; any
    // other change (e.g. today's plan swapped) just refreshes numbers.
    _ref.listen(todayWorkoutProvider, (prev, next) {
      final completed = next.valueOrNull?.completedWorkout != null;
      final prevCompleted = _lastWorkoutCompleted;
      _lastWorkoutCompleted = completed;
      if (prevCompleted == null || completed == prevCompleted) return;
      if (!prevCompleted && completed) {
        bumpText();
      } else {
        bumpNumbers();
      }
    }, fireImmediately: true);

    // Fasting — a fast ending (active → inactive) regenerates text; starting a
    // fast refreshes numbers (the fasting context shifts).
    _ref.listen(fastingProvider, (prev, next) {
      final active = next.activeFast != null;
      final prevActive = _lastFastActive;
      _lastFastActive = active;
      if (prevActive == null || active == prevActive) return;
      if (prevActive && !active) {
        bumpText();
      } else {
        bumpNumbers();
      }
    }, fireImmediately: true);

    // Sleep — a new / updated night (total asleep minutes changes) is a
    // completion-class signal → regenerate text (and the fresh fetch pulls the
    // updated sleep graph too).
    _ref.listen(sleepProvider, (prev, next) {
      final mins = next.valueOrNull?.totalMinutes ?? 0;
      final prevMins = _lastSleepMinutes;
      _lastSleepMinutes = mins;
      if (prevMins == null || mins == prevMins) return;
      bumpText();
    }, fireImmediately: true);
  }

  bool get _dismissed =>
      _ref.read(coachCardVisibilityProvider) ==
      CoachCardVisibility.dismissedToday;

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Schedule a cheap, numbers-only refresh (debounced). Safe to call from
  /// anywhere (pull-to-refresh, app resume) — it no-ops when the card is hidden.
  void bumpNumbers() {
    if (_dismissed) return;
    _numbersTimer?.cancel();
    _numbersTimer = Timer(_kNumbersDebounce, _runNumbers);
  }

  /// Schedule a text regenerate (debounced + throttled). A pending numbers
  /// refresh is cancelled because the text refresh already pulls fresh blocks.
  void bumpText() {
    if (_dismissed) return;
    _numbersTimer?.cancel();
    _textTimer?.cancel();
    _textTimer = Timer(_kTextDebounce, _runText);
  }

  Future<void> _runNumbers() async {
    if (_dismissed) return;
    try {
      await _ref
          .read(dailyCoachInsightNumbersRefreshProvider(_today()).future);
      _ref.invalidate(dailyCoachInsightProvider);
    } catch (_) {
      // Keep the last-good insight; the next log / resume retries.
    }
  }

  Future<void> _runText() async {
    if (_dismissed) return;
    final now = DateTime.now();
    final throttled = _lastTextRefreshAt != null &&
        now.difference(_lastTextRefreshAt!) < _kTextMinGap;
    if (throttled) {
      // Within the throttle window — don't regenerate text, but DO refresh the
      // numbers so the graphs still reflect the new data.
      await _runNumbers();
      return;
    }
    if (_textInFlight) return;
    _textInFlight = true;
    _lastTextRefreshAt = now;
    try {
      await _ref.read(dailyCoachInsightRefreshProvider(_today()).future);
      _ref.invalidate(dailyCoachInsightProvider);
    } catch (_) {
      // Keep the last-good insight.
    } finally {
      _textInFlight = false;
    }
  }

  void _dispose() {
    _numbersTimer?.cancel();
    _textTimer?.cancel();
  }
}
