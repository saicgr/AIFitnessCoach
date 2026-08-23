import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/providers/synced_visibility_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/tooltips/tooltip_anchors.dart';
import '../../../widgets/date_strip.dart';
import '../../home/widgets/hero_workout_carousel.dart';
import '../../home/widgets/hero_workout_card.dart' show GeneratingHeroCard;
import '../../home/widgets/today_addons_row.dart';
import '../../workout/schedule_date_utils.dart';

import '../../../l10n/generated/app_localizations.dart';
/// The workout date strip + carousel, moved out of the home screen onto the
/// Workouts tab. Self-contained: owns its own `PageController`, the
/// strip-selected day, and the carousel↔strip two-way sync — so it can be
/// dropped into any scroll view without parent wiring.
///
/// Mirrors the workout branch of the old `SectionedHeroArea` (minus the
/// WORKOUTS/NUTRITION tab toggle, which the home redesign removes).
class WorkoutPlannerSection extends ConsumerStatefulWidget {
  const WorkoutPlannerSection({super.key});

  @override
  ConsumerState<WorkoutPlannerSection> createState() =>
      _WorkoutPlannerSectionState();
}

class _WorkoutPlannerSectionState
    extends ConsumerState<WorkoutPlannerSection> {
  late final PageController _carouselPageController;
  // Selected day driving the carousel, as a normalized local-midnight date so
  // the strip (now the nutrition-style DateStrip) and the carousel stay in
  // sync two-ways. Defaults to today.
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<CarouselItem> _carouselItems = [];
  // Order-independent "which day is the carousel focused on" resolver. The
  // carousel's index and its item list arrive in EITHER order (and in the
  // wrong one on first paint) — see CarouselDateFocus for the full story.
  final CarouselDateFocus _focus = CarouselDateFocus();

  @override
  void initState() {
    super.initState();
    // Must match HeroWorkoutCarousel's internal viewport fraction (0.88).
    _carouselPageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _carouselPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayWorkoutState = ref.watch(todayWorkoutProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The calendar tune-menu now lives inline on the gym-switcher row
        // (see workouts_screen.dart) — no standalone line here, so the week
        // strip sits directly under the switcher with no wasted gap.
        _buildDateStrip(),
        const SizedBox(height: 8),
        // `workouts_v1` tour step 1 ("Start a workout") anchors here — the
        // today/hero workout card only, NOT the date strip above. Keying
        // the whole section made the spotlight ring the strip + card as one
        // oversized block; this scopes it to the card the copy refers to.
        KeyedSubtree(
          key: TooltipAnchors.workoutsToday,
          child: SizedBox(
            height: HeroWorkoutCarousel.cardHeight,
            child: _buildContent(todayWorkoutState),
          ),
        ),
        // Row 269: today can carry more than one workout (a program session,
        // a Quick Generate, a Builder session) and the carousel only ever
        // shows the hero-picked one, with no indication the others exist.
        // Surface them as a stack/count beneath the card — but only while
        // the strip is actually focused on today; the carousel can also be
        // showing a past/future day here.
        if (_isSelectedDateToday) const TodayAddonsRow(),
      ],
    );
  }

  bool get _isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Widget _buildContent(AsyncValue<TodayWorkoutResponse?> todayWorkoutState) {
    // Initial load — no cached value yet.
    if (todayWorkoutState.isLoading && !todayWorkoutState.hasValue) {
      return const GeneratingHeroCard(message: 'Loading your workout...');
    }

    // Actively generating and nothing displayable to show.
    final value = todayWorkoutState.valueOrNull;
    if (value?.isGenerating == true &&
        value?.hasDisplayableContent != true) {
      return GeneratingHeroCard(
        message: value?.generationMessage ?? 'Generating your workout...',
      );
    }

    return HeroWorkoutCarousel(
      externalPageController: _carouselPageController,
      onCarouselItemsChanged: (items) {
        if (!mounted) return;
        final days = items.map((i) => i.date).toList();
        // Compare the FULL ordered day sequence, not just length + first date.
        // A placeholder turning into a real workout mid-week leaves both of
        // those untouched, and the stale copy then mis-resolves every
        // subsequent strip tap and page-change.
        if (_focus.sameDays(days)) return;
        _focus.onDaysChanged(days);
        setState(() => _carouselItems = items);
        // The carousel's initial auto-jump calls `onPageChanged` BEFORE it
        // publishes its items (both are post-frame callbacks, registered in
        // that order), so the index could not be resolved to a date then.
        // Re-resolve now that the items are in hand — this is what keeps the
        // date strip and the focused card asserting the SAME day.
        _syncSelectedDateToFocusedCard();
      },
      onPageChanged: _onCarouselPageChanged,
    );
  }

  /// Single resolution point for "which local day is this section showing".
  /// Reads the focused carousel card's date and moves the strip's selection
  /// onto it. Safe to call from either callback, in either order.
  void _syncSelectedDateToFocusedCard() {
    final resolved = _focus.resolvedDay;
    if (resolved == null || resolved == _selectedDate) return;
    if (!mounted) return;
    setState(() => _selectedDate = resolved);
  }

  /// Builds the nutrition-style [DateStrip] (date numbers + today pill +
  /// logged dots, swipeable across weeks). Unifies the Workouts week strip
  /// with the Nutrition tab's date navigator. `allowFuture` is on so upcoming
  /// scheduled training days in the current week can be tapped to preview them.
  ///
  /// Dot logic: a day gets an accent dot when it has a real (non-synced)
  /// scheduled workout, OR when it is one of this week's scheduled training
  /// days (so a training day reads as "active" even before its workout
  /// materialises).
  Widget _buildDateStrip() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final workoutDays = (activeGymProfile?.workoutDays.isNotEmpty == true)
        ? activeGymProfile!.workoutDays
        : user.workoutDays;

    final weekConfig = ref.watch(weekDisplayConfigProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    // Merge /today's response into the workouts list — /today reflects the
    // latest is_completed flips immediately, workoutsProvider lags behind.
    final todayResp = ref.watch(todayWorkoutProvider).valueOrNull;
    final mergedWorkouts = <Workout>[...(workoutsAsync.valueOrNull ?? [])];
    void mergeIfNew(Workout? w) {
      if (w == null) return;
      if (mergedWorkouts.any((existing) => existing.id == w.id)) return;
      mergedWorkouts.add(w);
    }
    mergeIfNew(todayResp?.todayWorkout?.toWorkout());
    mergeIfNew(todayResp?.completedWorkout?.toWorkout());
    for (final extra in todayResp?.extraTodayWorkouts ?? const []) {
      mergeIfNew(extra.toWorkout());
    }

    // Build the set of dotted day-keys.
    final loggedKeys = <String>{};
    for (final w in mergedWorkouts) {
      if (w.isSyncedFromHealthApp) continue;
      final raw = w.scheduledDate;
      if (raw == null || raw.length < 10) continue;
      loggedKeys.add(raw.substring(0, 10));
    }
    // This week's scheduled training days (even without a materialised workout).
    for (int displayIndex = 0; displayIndex < 7; displayIndex++) {
      final i = weekConfig.displayOrder[displayIndex];
      if (!workoutDays.contains(i)) continue;
      final d = weekStart.add(Duration(days: displayIndex));
      loggedKeys.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }

    return DateStrip(
      selectedDate: _selectedDate,
      loggedDateKeys: loggedKeys,
      allowFuture: true,
      onDaySelected: _onDateSelected,
    );
  }

  /// Strip day tapped — animate the carousel to that day's card, or open the
  /// workout directly if no card exists for it.
  void _onDateSelected(DateTime date) {
    final tappedDate = DateTime(date.year, date.month, date.day);
    setState(() => _selectedDate = tappedDate);

    final tappedKey =
        '${tappedDate.year}-${tappedDate.month.toString().padLeft(2, '0')}-${tappedDate.day.toString().padLeft(2, '0')}';

    int? exactIndex;
    int bestIndex = 0;
    int bestDiff = 999;
    for (int i = 0; i < _carouselItems.length; i++) {
      final itemDate = _carouselItems[i].date;
      if (itemDate == null) continue;
      if (itemDate.year == tappedDate.year &&
          itemDate.month == tappedDate.month &&
          itemDate.day == tappedDate.day) {
        exactIndex = i;
        break;
      }
      final diff = itemDate.difference(tappedDate).inDays.abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }

    if (exactIndex != null && _carouselPageController.hasClients) {
      _focus.onPageChanged(exactIndex);
      _carouselPageController.animateToPage(
        exactIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // No carousel card — but a workout may still exist (e.g. a missed
    // session filtered out of the carousel). Open it directly.
    final allWorkouts = ref.read(workoutsProvider).valueOrNull ?? [];
    Workout? matchedWorkout;
    for (final w in allWorkouts) {
      final raw = w.scheduledDate;
      if (raw == null || raw.length < 10) continue;
      if (raw.substring(0, 10) == tappedKey) {
        matchedWorkout = w;
        break;
      }
    }
    if (matchedWorkout != null && matchedWorkout.id != null) {
      context.push('/workout/${matchedWorkout.id}', extra: matchedWorkout);
      return;
    }

    // Fallback — animate to the nearest card.
    if (_carouselItems.isNotEmpty && _carouselPageController.hasClients) {
      _focus.onPageChanged(bestIndex);
      _carouselPageController.animateToPage(
        bestIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Carousel page changed — record the focused index and sync the strip
  /// highlight to that card's date so the DateStrip pages/highlights to match.
  ///
  /// The index is remembered even when the item list has not arrived yet: the
  /// carousel fires this once on its initial auto-jump (which lands on the next
  /// actionable session, NOT page 0) before it publishes its items. Dropping
  /// that call was the whole of E2E #21 — the strip stayed pinned to today
  /// ("Tuesday 28") while the card beneath it rendered the next scheduled day
  /// ("Wednesday — No workout yet").
  void _onCarouselPageChanged(int pageIndex) {
    if (pageIndex < 0) return;
    _focus.onPageChanged(pageIndex);
    _syncSelectedDateToFocusedCard();
  }
}

/// Calendar display options — week-start swap + synced-workout visibility.
/// Recreated here from the old `SectionedHeroArea._HeroOverflowMenu`.
class WorkoutTuneMenu extends ConsumerWidget {
  final Color tint;
  const WorkoutTuneMenu({super.key, required this.tint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startsSunday = ref.watch(weekStartsSundayProvider);
    final showSynced = ref.watch(showSyncedInCarouselProvider);
    return PopupMenuButton<_TuneAction>(
      tooltip: AppLocalizations.of(context).workoutPlannerCalendarDisplayOptions,
      icon: Icon(Icons.tune, size: 18, color: tint),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        HapticService.selection();
        switch (action) {
          case _TuneAction.toggleWeekStart:
            ref.read(weekStartsSundayProvider.notifier).toggle();
            break;
          case _TuneAction.toggleSynced:
            ref.read(showSyncedInCarouselProvider.notifier).toggle();
            break;
        }
      },
      itemBuilder: (_) => [
        // Row #290: this used to swap BOTH halves on tap — the label named
        // the destination day ("Start week on Monday") while the trailing
        // text named the CURRENT day ("Sun"), so a single row asserted two
        // contradictory days with nothing marking which was which. The
        // label is now fixed (states the setting, not an action) and the
        // switch is the only thing that changes — same stateful-control
        // pattern as the "Show synced workouts" row directly below.
        PopupMenuItem(
          value: _TuneAction.toggleWeekStart,
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).workoutPlannerStartWeekOnMonday,
                ),
              ),
              Switch.adaptive(
                value: !startsSunday,
                onChanged: (_) {
                  Navigator.of(context).pop(_TuneAction.toggleWeekStart);
                },
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _TuneAction.toggleSynced,
          child: Row(
            children: [
              Icon(
                showSynced
                    ? Icons.visibility
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(AppLocalizations.of(context).workoutPlannerShowSyncedWorkouts)),
              Switch.adaptive(
                value: showSynced,
                onChanged: (_) {
                  Navigator.of(context).pop(_TuneAction.toggleSynced);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TuneAction { toggleWeekStart, toggleSynced }
