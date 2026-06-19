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
      ],
    );
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
        final changed = items.length != _carouselItems.length ||
            (items.isNotEmpty &&
                _carouselItems.isNotEmpty &&
                items.first.date != _carouselItems.first.date);
        if (mounted && changed) {
          setState(() => _carouselItems = items);
        }
      },
      onPageChanged: _onCarouselPageChanged,
    );
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
      _carouselPageController.animateToPage(
        bestIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Carousel page changed — sync the strip highlight to the focused card's
  /// date so the DateStrip pages/highlights to match.
  void _onCarouselPageChanged(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _carouselItems.length) return;
    final itemDate = _carouselItems[pageIndex].date;
    if (itemDate == null) return;
    final normalized = DateTime(itemDate.year, itemDate.month, itemDate.day);
    if (normalized != _selectedDate) {
      setState(() => _selectedDate = normalized);
    }
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
        PopupMenuItem(
          value: _TuneAction.toggleWeekStart,
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  startsSunday
                      ? AppLocalizations.of(context).workoutPlannerStartWeekOnMonday
                      : AppLocalizations.of(context).sectionedHeroAreaStartWeekOnSunday,
                ),
              ),
              Text(
                startsSunday ? AppLocalizations.of(context).workoutPlannerSun : AppLocalizations.of(context).workoutPlannerMon,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
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
