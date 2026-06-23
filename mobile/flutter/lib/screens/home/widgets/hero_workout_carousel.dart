import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/providers/synced_workouts_provider.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../core/providers/synced_visibility_provider.dart';
import 'hero_workout_card.dart';
import 'synced_workouts_summary_card.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Represents either a workout, a placeholder date, or an aggregate of all
/// synced workouts for one day in the carousel.
class CarouselItem {
  final Workout? workout;
  final DateTime? placeholderDate;
  final bool isAutoGenerating;
  final bool isGenerationFailed;
  final List<Workout>? syncedAggregate;
  final DateTime? syncedAggregateDate;

  CarouselItem.workout(this.workout)
      : placeholderDate = null,
        isAutoGenerating = false,
        isGenerationFailed = false,
        syncedAggregate = null,
        syncedAggregateDate = null;
  CarouselItem.placeholder(this.placeholderDate,
      {this.isAutoGenerating = false, this.isGenerationFailed = false})
      : workout = null,
        syncedAggregate = null,
        syncedAggregateDate = null;
  CarouselItem.syncedAggregateFor(
      DateTime date, List<Workout> rows)
      : workout = null,
        placeholderDate = null,
        isAutoGenerating = false,
        isGenerationFailed = false,
        syncedAggregate = rows,
        syncedAggregateDate = date;

  bool get isWorkout => workout != null;
  bool get isPlaceholder => placeholderDate != null;
  bool get isSyncedAggregate => syncedAggregate != null;

  /// The date this carousel item represents (from workout, placeholder, or aggregate)
  DateTime? get date {
    if (placeholderDate != null) return placeholderDate;
    if (syncedAggregateDate != null) return syncedAggregateDate;
    if (workout?.scheduledDate != null) {
      try {
        final dateStr = workout!.scheduledDate!.split('T')[0];
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }
    return null;
  }
}

/// Carousel based on user's workout days from profile.
/// Each day shows either a workout card or a "Generate" placeholder.
class HeroWorkoutCarousel extends ConsumerStatefulWidget {
  /// Optional external page controller (parent manages lifecycle)
  final PageController? externalPageController;

  /// Fires when carousel items are rebuilt (for parent to read dates)
  final ValueChanged<List<CarouselItem>>? onCarouselItemsChanged;

  /// Fires when the visible page changes (swipe or programmatic)
  final ValueChanged<int>? onPageChanged;

  /// Optional key for app tour spotlight targeting
  final GlobalKey? carouselKey;

  /// Shared card height constant. Content-driven height that fits the title +
  /// the "Tomorrow · Upper Body · 60m · 7 exercises" meta line + the START
  /// button without overflow on an iPhone SE, while still peeking the next
  /// carousel card. Reduced from 360 (too tall per user feedback + screenshot).
  static const double cardHeight = 272;

  const HeroWorkoutCarousel({
    super.key,
    this.externalPageController,
    this.onCarouselItemsChanged,
    this.onPageChanged,
    this.carouselKey,
  });

  /// Reset auto-generation flag (call on pull-to-refresh, regeneration, or logout)
  static void resetAutoGeneration() {
    _HeroWorkoutCarouselState.resetAutoGeneration();
  }

  /// Get workout dates for this week (including past days for missed workout viewing).
  /// Uses [weekConfig] to respect the user's Sunday/Monday week-start preference.
  static List<DateTime> getWorkoutDatesForWeek(List<int> workoutDays, WeekDisplayConfig weekConfig) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = weekConfig.dateForDataIndex(weekStart, day);
      dates.add(thisWeekDate);
    }
    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  @override
  ConsumerState<HeroWorkoutCarousel> createState() =>
      _HeroWorkoutCarouselState();
}

class _HeroWorkoutCarouselState extends ConsumerState<HeroWorkoutCarousel> {
  PageController? _ownedPageController;
  int _currentPage = 0;
  bool _hasScrolledToInitial = false;
  int _lastCompletedCount = -1; // Track completed count to auto-scroll on new completions
  String? _lastItemsSignature; // Hash of carousel item ids — used to re-target after Add/Replace

  /// Whether we own (and should dispose) the page controller
  bool get _ownsController => widget.externalPageController == null;
  PageController get _pageController =>
      widget.externalPageController ?? _ownedPageController!;

  /// No-op: generation is handled by todayWorkoutProvider
  static void resetAutoGeneration() {}

  /// Locally generated workouts stored for immediate display (Fix: workout vanishes after generation)
  final List<Workout> _locallyGeneratedWorkouts = [];

  // ── A3: program-change wipe + rebuild ──────────────────────────────────────
  // After the user edits their program and taps "Apply now", the schedule
  // (workoutDays / per-day focus) changes and the backend regenerates each day
  // one-by-one. The carousel previously kept GHOST cards from the OLD plan:
  //   • the all-workouts cache still held the stale workouts (incl. days that
  //     are no longer scheduled, e.g. Thu/Fri), and the "rest-day workouts"
  //     scan rendered them as ghost cards on now-unscheduled days; and
  //   • `_locallyGeneratedWorkouts` held stale local copies.
  // We detect the program change by watching the schedule signature change
  // build-to-build, then WIPE the local merge sources and force the carousel to
  // rebuild its day slots from the LATEST workoutDays only — a day NOT in the
  // new workoutDays renders no card (no ghost). Each scheduled day with no real
  // workout yet shows the generating placeholder; the refill poll then swaps it
  // for the real card as the backend fills each day in ascending date order.
  String? _lastScheduleSignature;
  // True for the first build AFTER a detected program change — used to suppress
  // the non-scheduled-day (rest-day) ghost scan while the new plan fills in.
  bool _scheduleJustChanged = false;
  // When a schedule change is detected we open a short window during which the
  // rest-day ghost scan stays suppressed (the stale all-workouts cache can take
  // a couple of refetch cycles to drop the old days). Mirrors A4's window.
  DateTime? _scheduleChangedAt;
  static const Duration _scheduleChangeGhostSuppression = Duration(seconds: 90);

  bool get _inScheduleChangeWindow {
    final t = _scheduleChangedAt;
    return t != null &&
        DateTime.now().difference(t) < _scheduleChangeGhostSuppression;
  }

  /// Stable signature of the active schedule: sorted workout-day indices plus
  /// the active gym profile id (a profile switch is also a schedule change).
  /// A change here means the program/plan changed → wipe + rebuild.
  String _scheduleSignatureFor(List<int> workoutDays, String? gymProfileId) {
    final sorted = List<int>.from(workoutDays)..sort();
    return '${gymProfileId ?? ''}|${sorted.join(',')}';
  }

  // ── Auto-refill for scheduled days with no workout in the client list ──────
  // The server often ALREADY has the workout (generated in the background after
  // a program change), but the client cached the empty state and never refetched
  // → a scheduled day showed a permanent "No workout yet" until app restart.
  // While any scheduled day looks empty, poll workoutsProvider so background-
  // generated workouts appear without a restart; the placeholder shows the
  // engaging generating card meanwhile. Capped so a genuinely-missing day
  // eventually falls back to "No workout yet".
  Timer? _refillTimer;
  int _refillAttempts = 0;
  // ~20 × 4s ≈ 80s of polling. Sized to cover a full-week sequential fill after
  // a program change (the backend generates today+tomorrow eagerly, then the
  // rest of the visible week in the background); each scheduled day's real card
  // swaps in as its workout lands. Stays inside the A3 schedule-change window.
  static const int _kRefillMaxAttempts = 20;

  bool get _refillActive => _refillAttempts < _kRefillMaxAttempts;

  void _ensureRefill(bool hasMissingScheduled) {
    if (!hasMissingScheduled) {
      // All scheduled days populated — stop + reset for the next change.
      _refillTimer?.cancel();
      _refillTimer = null;
      if (_refillAttempts != 0) _refillAttempts = 0;
      return;
    }
    if (_refillTimer != null || _refillAttempts >= _kRefillMaxAttempts) return;
    // Fire one refetch immediately, then poll.
    ref.read(workoutsProvider.notifier).silentRefresh();
    _refillTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      _refillAttempts++;
      if (_refillAttempts >= _kRefillMaxAttempts) {
        t.cancel();
        _refillTimer = null;
        if (mounted) setState(() {}); // drop generating card → "No workout yet"
        return;
      }
      ref.read(workoutsProvider.notifier).silentRefresh();
    });
  }

  @override
  void initState() {
    super.initState();
    // Only create our own controller if no external one is provided
    if (_ownsController) {
      _ownedPageController = PageController(viewportFraction: 0.88);
    }
  }

  @override
  void dispose() {
    _refillTimer?.cancel();
    if (_ownsController) {
      _ownedPageController?.dispose();
    }
    super.dispose();
  }

  /// Date key for tracking (YYYY-MM-DD)
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Pick the default-focused carousel card in priority order. Treats
  /// `isCompleted == null` as actionable (freshly-generated, never-attempted
  /// workouts have null state — the old `== false` check silently skipped them).
  /// Priority: today's real workout → today's placeholder → next future →
  /// any placeholder → index 0. A real workout on today (including rescheduled
  /// "Do this today" ones on non-preferred days) always wins over a preferred-day
  /// placeholder that sits on the same date.
  int _pickInitialIndex(List<CarouselItem> items, DateTime today) {
    int? todayWorkoutIdx, todayPlaceholderIdx, futureIdx, placeholderIdx;
    final todayKey = _dateKey(today);
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final actionable = item.isPlaceholder ||
          (item.isWorkout && item.workout!.isCompleted != true);
      if (!actionable) continue;
      final d = item.date;
      final isToday = d != null && _dateKey(d) == todayKey;
      if (isToday && item.isWorkout) {
        todayWorkoutIdx ??= i;
      } else if (isToday && item.isPlaceholder) {
        todayPlaceholderIdx ??= i;
      } else if (d != null && d.isAfter(today)) {
        futureIdx ??= i;
      } else if (item.isPlaceholder) {
        placeholderIdx ??= i;
      }
    }
    return todayWorkoutIdx ??
        todayPlaceholderIdx ??
        futureIdx ??
        placeholderIdx ??
        0;
  }

  /// Get workout dates for this week (including past days for missed workout viewing).
  /// Uses [weekConfig] to respect the user's Sunday/Monday week-start preference.
  /// Past dates are included so users can tap missed dates in the week strip
  /// and see the missed workout in the carousel.
  List<DateTime> _getWorkoutDatesForWeek(List<int> workoutDays, WeekDisplayConfig weekConfig) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = weekConfig.dateForDataIndex(weekStart, day);
      dates.add(thisWeekDate);
    }
    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  /// Parse the YYYY-MM-DD prefix of a workout's scheduledDate as a local date.
  /// Returns null when the field is absent or unparseable. Used by the synced-
  /// workout merge so we can compare against today without re-implementing
  /// the substring/timezone dance everywhere.
  DateTime? _scheduledDate(Workout w) {
    final raw = w.scheduledDate;
    if (raw == null || raw.length < 10) return null;
    final parts = raw.substring(0, 10).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Find ALL workouts for a specific date using string comparison
  /// to avoid timezone shift issues (DateTime.parse on date-only strings
  /// creates UTC midnight, and .toLocal() can shift the date backward).
  /// Returns multiple workouts when quick workouts coexist with scheduled ones.
  List<Workout> _findAllWorkoutsForDate(List<Workout> workouts, DateTime date) {
    final targetKey = _dateKey(date); // "YYYY-MM-DD" from local DateTime
    final results = <Workout>[];
    for (final workout in workouts) {
      if (workout.scheduledDate == null) continue;
      // Extract YYYY-MM-DD: handles "YYYY-MM-DD", "YYYY-MM-DDT...", "YYYY-MM-DD ..."
      final raw = workout.scheduledDate!;
      final dateOnly = raw.length >= 10 ? raw.substring(0, 10) : raw;
      if (dateOnly == targetKey) {
        results.add(workout);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Get user from auth state (workout days are in User.preferences)
    final userAsync = ref.watch(currentUserProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    // Also watch todayWorkoutProvider as fallback to ensure today's workout shows
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider);

    // Cache-first paint: if we have ANY cached user + today workout, paint
    // the card immediately and let background refresh update silently.
    // Only show the full skeleton when there's truly nothing to render.
    final cachedUser = userAsync.valueOrNull;
    final cachedToday = todayWorkoutAsync.valueOrNull;

    // Show skeleton only when we have no cached data at all AND are loading.
    if (cachedUser == null && userAsync.isLoading) {
      return KeyedSubtree(
        key: widget.carouselKey,
        child: _buildLoadingState(isDark, accentColor),
      );
    }
    if (userAsync.hasError && cachedUser == null) {
      return KeyedSubtree(
        key: widget.carouselKey,
        child: _buildErrorState(isDark),
      );
    }

    return KeyedSubtree(
      key: widget.carouselKey,
      child: Builder(builder: (context) {
        final user = cachedUser;
        if (user == null) {
          return _buildNoWorkoutDaysState(isDark, accentColor);
        }

        // Per-profile schedule precedence: active gym profile's workoutDays
        // wins over the user's account-level workoutDays. Lets users have
        // different schedules per gym (Tue/Thu at the gym, Mon/Sat at home)
        // without mutating their global preferences. Mirrors the backend
        // resolver in today.py (_resolve_workout_days).
        final activeProfile = ref.watch(activeGymProfileProvider);
        final workoutDays = (activeProfile?.workoutDays.isNotEmpty ?? false)
            ? activeProfile!.workoutDays
            : user.workoutDays;

        // A3: detect a program/schedule change (Apply now, profile switch, or a
        // workout-days edit). The signature combines the resolved workout-day
        // indices + the active gym profile id; when it changes we WIPE the local
        // merge sources so no stale workout (incl. days no longer scheduled)
        // ghosts into the rebuilt carousel, reset the refill poll so it fills the
        // new days one-by-one, and open a window during which the rest-day ghost
        // scan stays suppressed until the stale all-workouts cache drains.
        final scheduleSignature =
            _scheduleSignatureFor(workoutDays, activeProfile?.id);
        if (_lastScheduleSignature != null &&
            _lastScheduleSignature != scheduleSignature) {
          // Wipe local merge sources NOW (build-safe: just a list mutation).
          _locallyGeneratedWorkouts.clear();
          _scheduleJustChanged = true;
          _scheduleChangedAt = DateTime.now();
          // Reset the refill poll so the new schedule's empty days drive a fresh
          // sequential fill from the earliest scheduled day onward.
          _refillAttempts = 0;
          _refillTimer?.cancel();
          _refillTimer = null;
          // Drop any prior carousel positioning so the rebuilt list re-targets
          // its actionable day cleanly instead of clinging to a stale page.
          _hasScrolledToInitial = false;
          _lastItemsSignature = null;
        } else {
          _scheduleJustChanged = false;
        }
        _lastScheduleSignature = scheduleSignature;

        // If today workout hasn't resolved yet AND we have no cached value AND
        // we don't even know the workout schedule yet — show skeleton.
        // If workoutDays is already known (profile switch case), skip the
        // global skeleton: render day-slot placeholders immediately so the
        // carousel reflects the new profile's schedule without a blank flash.
        if (todayWorkoutAsync.isLoading && cachedToday == null && workoutDays.isEmpty) {
          return _buildLoadingState(isDark, accentColor);
        }
        final isRefreshing = todayWorkoutAsync.isLoading && cachedToday == null;

        // Check todayWorkoutProvider first for today's/next workout
        final todayWorkoutResponse = todayWorkoutAsync.valueOrNull;
        final nextWorkout = todayWorkoutResponse?.nextWorkout?.toWorkout();

        // Trust the backend's resolved today workout. /workouts/today already
        // honours the active gym profile's schedule + tz-aware date window
        // + the "today must be a scheduled workout day" gate (today.py
        // _resolve_workout_days + the TODAY GATE safety net).
        //
        // Pin to today's calendar date ONLY when today is actually a
        // scheduled workout day for this user AND the row's scheduled_date
        // is close to today (within 1 day, to allow a "Do this today"
        // reschedule that kept the original date). The old unconditional
        // pin masked a backend bug where a midnight-UTC stored row for
        // tomorrow looked like today's row to the tz window query — the
        // hero then proudly relabeled tomorrow's workout as TODAY.
        var todayWorkout = todayWorkoutResponse?.todayWorkout?.toWorkout();
        if (todayWorkout != null) {
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          final todayKey = _dateKey(todayDate);
          final raw = todayWorkout.scheduledDate;

          final todayIsScheduled = workoutDays.contains(todayDate.weekday - 1);

          DateTime? rowDate;
          if (raw != null && raw.length >= 10) {
            try {
              final p = raw.substring(0, 10).split('-');
              if (p.length == 3) {
                rowDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
              }
            } catch (_) {}
          }
          final daysOff = rowDate == null
              ? 0
              : rowDate.difference(todayDate).inDays.abs();

          if (todayIsScheduled && daysOff <= 1) {
            // Safe to pin to today (covers "Do this today" reschedule case).
            if (raw == null || raw.length < 10 || raw.substring(0, 10) != todayKey) {
              todayWorkout = todayWorkout.copyWith(scheduledDate: todayKey);
            }
          } else {
            // Today isn't a scheduled day, or the row is too far off (legacy
            // midnight-UTC bug). Don't impersonate as TODAY — let it slot in
            // on its real date so the badge logic in hero_workout_card.dart
            // shows TOMORROW / day-name instead of TODAY.
            todayWorkout = null;
          }
        }

        // Use valueOrNull so we don't block on the slow all-workouts fetch
        final allWorkouts = workoutsAsync.valueOrNull ?? [];

        // Merge in today's workout. Replace any same-id entry from the
        // all-workouts list so the date-pinned copy above wins (the list
        // copy still carries the stale future/past scheduled_date).
        final mergedWorkouts = List<Workout>.from(allWorkouts);
        final tw = todayWorkout;
        if (tw != null) {
          mergedWorkouts.removeWhere((w) => w.id == tw.id);
          mergedWorkouts.add(tw);
        }
        if (nextWorkout != null && !mergedWorkouts.any((w) => w.id == nextWorkout.id)) {
          mergedWorkouts.add(nextWorkout);
        }
        // Merge extra today workouts (quick workouts coexisting with scheduled)
        final extraTodayWorkouts = todayWorkoutResponse?.extraTodayWorkouts ?? [];
        for (final extra in extraTodayWorkouts) {
          final extraWorkout = extra.toWorkout();
          if (!mergedWorkouts.any((w) => w.id == extraWorkout.id)) {
            mergedWorkouts.add(extraWorkout);
          }
        }
        // Merge today's completed workout. /today returns it as `completedWorkout`
        // (with todayWorkout=null) once the user finishes today's session. Without
        // this merge, the carousel falls back to the placeholder "No workout yet"
        // card whenever workoutsProvider is stale (e.g. after navigating back from
        // the summary screen, before the silent refresh propagates).
        final completedToday = todayWorkoutResponse?.completedWorkout?.toWorkout();
        if (completedToday != null && !mergedWorkouts.any((w) => w.id == completedToday.id)) {
          mergedWorkouts.add(completedToday);
        }
        // Merge locally generated workouts for immediate display
        for (final workout in _locallyGeneratedWorkouts) {
          if (!mergedWorkouts.any((w) => w.id == workout.id)) {
            mergedWorkouts.add(workout);
          }
        }
        // Clean up _locallyGeneratedWorkouts: remove entries already in provider data
        _locallyGeneratedWorkouts.removeWhere(
          (local) => allWorkouts.any((w) => w.id == local.id),
        );
        // Health-Connect / wearable-synced workouts: gated by the user's
        // "Show synced workouts" toggle in the home overflow menu (default
        // OFF — synced rows always live in the Synced Workouts history tab).
        // When ON, all synced rows for today/yesterday are aggregated into a
        // SINGLE summary card per day via the syncedAggregatesByDay map below;
        // we deliberately do NOT mergeWorkouts here, so they don't appear as
        // separate per-row cyan cards.
        final showSynced = ref.watch(showSyncedInCarouselProvider);
        final syncedAggregatesByDay = <String, List<Workout>>{};
        if (showSynced) {
          final syncedWorkouts = ref.watch(syncedWorkoutsProvider);
          final nowForSynced = DateTime.now();
          final todayForSynced = DateTime(
              nowForSynced.year, nowForSynced.month, nowForSynced.day);
          final keepSyncedAfter =
              todayForSynced.subtract(const Duration(days: 1));
          for (final w in syncedWorkouts) {
            final wDate = _scheduledDate(w);
            if (wDate == null) continue;
            if (wDate.isBefore(keepSyncedAfter)) continue;
            if (w.isCompleted != true) continue;
            final key = _dateKey(wDate);
            syncedAggregatesByDay.putIfAbsent(key, () => []).add(w);
          }
        }

        // NOTE: No date-based dedup here. Two non-quick workouts can legitimately
        // share a scheduled_date — the user picks "Add Workout" in the regenerate /
        // mood-picker flows, which un-supersedes the original so both are
        // is_current=True. The merge step above already dedupes by id; the backend
        // already filters is_current=True, so accidental dupes can't reach here.

        // Build carousel items: one per workout day (workout card or pending card)
        // Multiple workouts on the same day each get their own carousel card.
        List<CarouselItem> carouselItems = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // True when a scheduled today/future day has no workout in the client
        // list — drives the auto-refill poll (A2) so background-generated days
        // appear without an app restart.
        bool anyMissingScheduled = false;
        if (workoutDays.isNotEmpty) {
          final weekConfig = ref.watch(weekDisplayConfigProvider);
          final workoutDates = _getWorkoutDatesForWeek(workoutDays, weekConfig);
          // Track which workouts have been added to avoid duplicates
          final addedWorkoutIds = <String>{};

          for (final date in workoutDates) {
            final workoutsForDate = _findAllWorkoutsForDate(mergedWorkouts, date);
            if (workoutsForDate.isNotEmpty) {
              for (final workout in workoutsForDate) {
                final wId = workout.id ?? '';
                if (wId.isNotEmpty && addedWorkoutIds.add(wId)) {
                  carouselItems.add(CarouselItem.workout(workout));
                }
              }
            } else if (!date.isBefore(today)) {
              // Scheduled today/future day with no workout in the client list.
              // The server usually already has it — show the engaging generating
              // card while we poll workoutsProvider to pull it in (capped). Only
              // after the poll budget is exhausted does it fall back to the plain
              // "No workout yet". (Profile-switch refresh also forces generating.)
              anyMissingScheduled = true;
              final isGeneratingForDate = isRefreshing ||
                  todayWorkoutResponse?.isGenerating == true ||
                  _refillActive;
              carouselItems.add(CarouselItem.placeholder(date, isAutoGenerating: isGeneratingForDate));
            }
            // Past dates with no workout are simply skipped (no card to show)
          }
          // Drive the auto-refill poll after this frame (can't mutate state /
          // start timers during build).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ensureRefill(anyMissingScheduled);
          });

          // Handle workouts on non-workout days (staple-only workouts, quick workouts)
          // Check all days this week for workouts that exist in DB but aren't workout days
          final workoutDateKeys = workoutDates.map(_dateKey).toSet();

          // A3: while a program change is settling, SKIP this non-scheduled-day
          // scan entirely. It's the source of the GHOST cards — the stale
          // all-workouts cache still holds the OLD plan's workouts on days that
          // are no longer scheduled (e.g. Thu/Fri after switching to Tue/Wed),
          // and this loop would render them. Render-gating to the new workoutDays
          // only (the loop above) is exactly the desired "rebuild from the latest
          // preferences" behavior. Quick / staple workouts re-surface once the
          // window closes and the cache has dropped the old days.
          final suppressRestDayScan =
              _scheduleJustChanged || _inScheduleChangeWindow;

          // Scan ONLY remaining days in the current display week for non-workout-day workouts
          final weekEnd = weekConfig.weekStart(today).add(const Duration(days: 6));
          for (int dayOffset = 0; !suppressRestDayScan && dayOffset < 7; dayOffset++) {
            final checkDate = today.add(Duration(days: dayOffset));
            if (checkDate.isAfter(weekEnd)) break; // Don't spill into next week
            final checkKey = _dateKey(checkDate);
            if (workoutDateKeys.contains(checkKey)) continue; // Already handled

            final restDayWorkouts = _findAllWorkoutsForDate(mergedWorkouts, checkDate);
            for (final workout in restDayWorkouts) {
              final wId = workout.id ?? '';
              if (wId.isNotEmpty && addedWorkoutIds.add(wId)) {
                // Insert in chronological order
                int insertIdx = carouselItems.length;
                for (int i = 0; i < carouselItems.length; i++) {
                  final itemDate = carouselItems[i].date;
                  if (itemDate != null && checkDate.isBefore(itemDate)) {
                    insertIdx = i;
                    break;
                  }
                }
                carouselItems.insert(insertIdx, CarouselItem.workout(workout));
              }
            }
          }
        }

        // Synced aggregate slides: one card per day, inserted in chronological
        // order alongside scheduled workout cards. Skipped entirely when the
        // user keeps the "Show synced workouts" toggle OFF.
        for (final entry in syncedAggregatesByDay.entries) {
          final parts = entry.key.split('-');
          if (parts.length != 3) continue;
          final aggDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          int insertIdx = carouselItems.length;
          for (int i = 0; i < carouselItems.length; i++) {
            final itemDate = carouselItems[i].date;
            if (itemDate != null && aggDate.isBefore(itemDate)) {
              insertIdx = i;
              break;
            }
          }
          carouselItems.insert(
              insertIdx, CarouselItem.syncedAggregateFor(aggDate, entry.value));
        }

        // Always surface the next scheduled workout — even when it's beyond
        // the current display week — so the carousel never dead-ends on a
        // "No workout yet" placeholder for users whose next session is in a
        // future week (e.g. 1 workout/week schedules). Mirrors the Workouts
        // tab's "NEXT WEEK'S WORKOUT" behavior.
        if (nextWorkout != null && nextWorkout.id != null) {
          final already = carouselItems.any(
            (i) => i.isWorkout && i.workout?.id == nextWorkout.id,
          );
          if (!already) {
            carouselItems.add(CarouselItem.workout(nextWorkout));
          }
        }

        // Fix #1 (carousel duplication after Quick regenerate / dismiss):
        // Second-pass dedup specifically for QUICK workouts. The id-based
        // dedup above lets the OLD and NEW quick coexist for the brief
        // window between regenerate (new id) and the supersede DELETE
        // round-trip (old id removal). Without this filter, the user sees
        // two "Quick" cards momentarily.
        //
        // Strategy: keep at most ONE quick workout — the most recent by
        // created_at. Heuristic for `is_quick` mirrors hero_workout_card's
        // `_isQuickWorkout`: generation_method in (quick_rule_based,
        // ai_quick_workout) OR <=15min duration AND <=5 exercises.
        // Edge case (midnight rollover): a quick generated late last night
        // that happens to be flagged for today still gets compared on
        // created_at — last one wins regardless of scheduled date.
        {
          bool isQuick(Workout w) {
            final m = (w.generationMethod ?? '').toLowerCase();
            if (m == 'quick_rule_based' || m == 'ai_quick_workout') return true;
            final dur = w.durationMinutes ?? w.durationMinutesMax ?? 0;
            return dur > 0 && dur <= 15 && w.exerciseCount <= 5;
          }
          DateTime? parseCreated(String? s) {
            if (s == null || s.isEmpty) return null;
            try {
              return DateTime.parse(s).toLocal();
            } catch (_) {
              return null;
            }
          }
          int? mostRecentQuickIdx;
          DateTime? mostRecentTs;
          for (int i = 0; i < carouselItems.length; i++) {
            final it = carouselItems[i];
            if (!it.isWorkout) continue;
            final w = it.workout!;
            if (!isQuick(w)) continue;
            final ts = parseCreated(w.createdAt);
            if (mostRecentQuickIdx == null) {
              mostRecentQuickIdx = i;
              mostRecentTs = ts;
              continue;
            }
            // Treat null timestamps as oldest so a real timestamp always wins.
            final challengerNewer = (ts != null) &&
                (mostRecentTs == null || ts.isAfter(mostRecentTs));
            if (challengerNewer) {
              mostRecentQuickIdx = i;
              mostRecentTs = ts;
            }
          }
          if (mostRecentQuickIdx != null) {
            final keepId = carouselItems[mostRecentQuickIdx].workout!.id;
            carouselItems.removeWhere(
              (it) => it.isWorkout &&
                  isQuick(it.workout!) &&
                  it.workout!.id != keepId,
            );
          }
        }

        // Defensive (date-keyed) dedup. Returning users hit a race where the
        // placeholder for a future date and the actual workout for the same
        // date both end up in the list — produces a "two Tomorrow tiles" UI
        // a minute after login. Drop any placeholder whose date already has
        // a real workout. (Multiple real workouts on the same date are
        // legitimate — Add Workout / mood-picker — so we never dedup those.)
        {
          final realDateKeys = <String>{};
          for (final item in carouselItems) {
            if (item.isWorkout) {
              final d = item.date;
              if (d != null) realDateKeys.add(_dateKey(d));
            }
          }
          carouselItems.removeWhere((item) =>
              item.isPlaceholder &&
              item.placeholderDate != null &&
              realDateKeys.contains(_dateKey(item.placeholderDate!)));
        }

        // Pick the actionable target on first data load + position the carousel
        // on it. With the full week pre-warmed at bootstrap, the items are
        // already present on the first paint — so we JUMP straight to today's /
        // next workout (no 800ms dwell, no slide). The old dwell-then-animate
        // made the staged data fill visible ("next card → empty placeholder →
        // settle"); jumping lands on the right card instantly while the rest of
        // the week stays one swipe away.
        if (!_hasScrolledToInitial && carouselItems.length > 1) {
          _hasScrolledToInitial = true;
          final targetIndex = _pickInitialIndex(carouselItems, today);
          _currentPage = targetIndex;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (targetIndex != 0 && _pageController.hasClients) {
              _pageController.jumpToPage(targetIndex);
            }
            widget.onPageChanged?.call(targetIndex);
          });
        }

        // Re-target the carousel when the item list changes after the
        // initial scroll (e.g. user picked "Add Workout" and a new card
        // joined today). Without this, _hasScrolledToInitial=true blocks
        // any further auto-scroll and the user lands on the stale page.
        // Signature = ordered list of item identities; only fires when the
        // visible content actually changed, not on every Riverpod rebuild.
        final itemsSignature = carouselItems
            .map((i) {
              if (i.isWorkout) {
                return 'w:${i.workout?.id ?? ''}:${i.workout?.isCompleted == true ? 1 : 0}';
              }
              if (i.isSyncedAggregate) {
                return 's:${i.syncedAggregateDate != null ? _dateKey(i.syncedAggregateDate!) : ''}:${i.syncedAggregate?.length ?? 0}';
              }
              return 'p:${i.placeholderDate != null ? _dateKey(i.placeholderDate!) : ''}';
            })
            .join('|');
        if (_hasScrolledToInitial &&
            _lastItemsSignature != null &&
            _lastItemsSignature != itemsSignature &&
            carouselItems.length > 1) {
          final retargetIndex = _pickInitialIndex(carouselItems, today);
          if (retargetIndex != _currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.animateToPage(
                  retargetIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
        _lastItemsSignature = itemsSignature;

        // Auto-scroll to next actionable (today/future) workout when a workout is newly completed
        final completedCount = carouselItems.where((item) => item.isWorkout && item.workout!.isCompleted == true).length;
        if (_hasScrolledToInitial && _lastCompletedCount >= 0 && completedCount > _lastCompletedCount && carouselItems.length > 1) {
          int targetIndex = 0;
          bool found = false;
          for (int i = 0; i < carouselItems.length; i++) {
            final item = carouselItems[i];
            if (item.isPlaceholder) {
              targetIndex = i;
              found = true;
              break;
            }
            if (item.isWorkout && item.workout!.isCompleted != true) {
              final itemDate = item.date;
              if (itemDate != null && !itemDate.isBefore(today)) {
                targetIndex = i;
                found = true;
                break;
              }
            }
          }
          if (!found) targetIndex = carouselItems.length - 1;
          if (targetIndex != _currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
        _lastCompletedCount = completedCount;

        // Notify parent of carousel items (for week strip sync)
        if (widget.onCarouselItemsChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCarouselItemsChanged?.call(carouselItems);
          });
        }

        // If no workout items to display, show appropriate state
        if (carouselItems.isEmpty) {
          if (workoutDays.isEmpty) {
            return _buildNoWorkoutDaysState(isDark, accentColor);
          }
          return _buildAllDoneState(isDark, accentColor);
        }

        // Show single card if only one item (no carousel needed)
        if (carouselItems.length == 1) {
          final item = carouselItems.first;
          return SizedBox(
            height: HeroWorkoutCarousel.cardHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildItemContent(item, isDark, accentColor, today),
            ),
          );
        }

        // PageView carousel for multiple items
        return SizedBox(
          height: HeroWorkoutCarousel.cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselItems.length,
            onPageChanged: (index) {
              HapticService.selection();
              setState(() => _currentPage = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final item = carouselItems[index];

              // Scale down and slightly dim non-active cards
              final isActive = index == _currentPage;
              final scale = isActive ? 1.0 : 0.92;
              final opacity = isActive ? 1.0 : 0.8;

              // Stable key per item lets PageView reuse element trees across
              // page swipes instead of rebuilding every neighbor's subtree.
              // RepaintBoundary isolates each card's painting layer so a
              // neighbor's AnimatedScale / AnimatedOpacity tween doesn't
              // invalidate the active card's pixels.
              return KeyedSubtree(
                key: ValueKey(_keyForItem(item, index)),
                child: RepaintBoundary(
                  child: AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 200),
                      child:
                          _buildItemContent(item, isDark, accentColor, today),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
    );
  }

  /// Stable key for a carousel slot so PageView preserves widget state.
  /// Workouts key off id; placeholders + synced aggregates key off date so
  /// the same slot reuses its element when adjacent items shift.
  String _keyForItem(CarouselItem item, int index) {
    if (item.isWorkout && item.workout?.id != null) {
      return 'w_${item.workout!.id}';
    }
    if (item.isSyncedAggregate && item.syncedAggregateDate != null) {
      final d = item.syncedAggregateDate!;
      return 's_${d.year}_${d.month}_${d.day}';
    }
    if (item.placeholderDate != null) {
      final d = item.placeholderDate!;
      return 'p_${d.year}_${d.month}_${d.day}';
    }
    return 'i_$index';
  }

  /// Resolve carousel item → rendered widget. Centralised so the single-item
  /// fallback and the PageView builder stay in sync.
  Widget _buildItemContent(
      CarouselItem item, bool isDark, Color accentColor, DateTime today) {
    if (item.isWorkout) {
      return HeroWorkoutCard(workout: item.workout!, inCarousel: true);
    }
    if (item.isSyncedAggregate) {
      return SyncedWorkoutsSummaryCard(
        date: item.syncedAggregateDate!,
        workouts: item.syncedAggregate!,
        isToday: item.syncedAggregateDate == today,
      );
    }
    return _buildPendingCard(item.placeholderDate!, isDark, accentColor,
        isAutoGenerating: item.isAutoGenerating);
  }

  /// Minimal card for workout days that don't have a generated workout yet.
  Widget _buildPendingCard(DateTime date, bool isDark, Color accentColor, {bool isAutoGenerating = false}) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[date.weekday - 1];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    return Container(
      height: HeroWorkoutCarousel.cardHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isToday ? AppLocalizations.of(context).todayScoreCardToday : dayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (isAutoGenerating)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // A4: sequenced narrative instead of a single static line so a
                  // multi-second AI generation feels alive. Phase 0 reuses the
                  // existing localized "Generating workout…" string; the later
                  // honest sub-phases (building → personalizing → finishing)
                  // cycle while the real regen runs.
                  Flexible(
                    child: _GeneratingPhaseText(
                      baseLabel: AppLocalizations.of(context)
                          .heroWorkoutCarouselGeneratingWorkout,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              )
            else
              Text(
                AppLocalizations.of(context).heroWorkoutCarouselNoWorkoutYet,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutDaysState(bool isDark, Color accentColor) {
    return GestureDetector(
      onTap: () {
        context.push('/settings/workout-settings');
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: accentColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).heroWorkoutCarouselSetYourWorkoutDays, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context).heroWorkoutCarouselTapToSetUp, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoneState(bool isDark, Color accentColor) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: accentColor),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).heroWorkoutCarouselAllDoneForThis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).heroWorkoutCarouselRestUpForNext, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color accentColor) {
    return Container(
      height: HeroWorkoutCarousel.cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: accentColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).heroWorkoutCarouselSettingUpYourWorkout,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(AppLocalizations.of(context).heroWorkoutCarouselCouldNotLoadWorkouts, style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
      ),
    );
  }
}

/// A4: a small honest phase cycler for the carousel's "generating" pending card.
///
/// Replaces the single static "Generating workout…" line with a short rotating
/// narrative so a multi-second AI regen reads as progress rather than a frozen
/// spinner. Phase 0 is the caller's already-localized base label; the remaining
/// sub-phases are intentionally generic verbs (no fabricated completion — the
/// real generation finishes when the workout actually lands and the card swaps).
class _GeneratingPhaseText extends StatefulWidget {
  const _GeneratingPhaseText({required this.baseLabel, required this.color});

  final String baseLabel;
  final Color color;

  @override
  State<_GeneratingPhaseText> createState() => _GeneratingPhaseTextState();
}

class _GeneratingPhaseTextState extends State<_GeneratingPhaseText> {
  Timer? _timer;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      // Cap at the last phase so it never loops back to look "stuck restarting";
      // it holds on the final phase until the real workout swaps the card.
      setState(() => _phase = (_phase + 1).clamp(0, _phases.length - 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Phase 0 is the localized base label; the rest are creative-but-honest
  // beats that mirror what the coach actually does (read history → pick work →
  // personalize → finalize). Caps at the last phase (doesn't loop).
  List<String> get _phases => <String>[
        widget.baseLabel,
        'Reading your recent PRs…',
        'Referencing your training history…',
        'Checking your recovery…',
        'Picking your exercises…',
        'Personalizing for you…',
        'Almost ready…',
      ];

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Text(
        _phases[_phase],
        key: ValueKey<int>(_phase),
        style: TextStyle(fontSize: 14, color: widget.color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
