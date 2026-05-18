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
import '../../home/widgets/hero_workout_carousel.dart';
import '../../home/widgets/hero_workout_card.dart' show GeneratingHeroCard;
import '../../home/widgets/week_calendar_strip.dart';

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
  int _selectedWeekDay = DateTime.now().weekday - 1; // 0 = Mon
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
        _buildWeekCalendarStrip(),
        const SizedBox(height: 8),
        SizedBox(
          height: HeroWorkoutCarousel.cardHeight,
          child: _buildContent(todayWorkoutState),
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

  /// Builds the week calendar strip with per-day workout status.
  /// Status: true = completed, false = scheduled, null = not a workout day.
  Widget _buildWeekCalendarStrip() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final workoutDays = (activeGymProfile?.workoutDays.isNotEmpty == true)
        ? activeGymProfile!.workoutDays
        : user.workoutDays;
    if (workoutDays.isEmpty) return const SizedBox.shrink();

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

    final Map<int, bool?> statusMap = {};
    for (int displayIndex = 0; displayIndex < 7; displayIndex++) {
      final i = weekConfig.displayOrder[displayIndex];
      if (!workoutDays.contains(i)) {
        statusMap[i] = null;
        continue;
      }
      final dayDate = weekStart.add(Duration(days: displayIndex));
      final dateKey =
          '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

      final dayWorkouts = mergedWorkouts.where((w) {
        if (w.scheduledDate == null) return false;
        final raw = w.scheduledDate!;
        final dateOnly = raw.length >= 10 ? raw.substring(0, 10) : raw;
        return dateOnly == dateKey;
      }).toList();

      // Only Zealova-authored workouts paint the completion dot — synced
      // Health-Connect imports surface in their own UI.
      final zealovaCompleted = dayWorkouts.any(
        (w) => w.isCompleted == true && !w.isSyncedFromHealthApp,
      );
      statusMap[i] =
          (dayWorkouts.isNotEmpty && zealovaCompleted) ? true : false;
    }

    return WeekCalendarStrip(
      workoutDays: workoutDays,
      workoutStatusMap: statusMap,
      selectedDayIndex: _selectedWeekDay,
      onDaySelected: _onWeekDaySelected,
    );
  }

  /// Strip day tapped — animate the carousel to that day's card, or open the
  /// workout directly if no card exists for it.
  void _onWeekDaySelected(int dayIndex) {
    setState(() => _selectedWeekDay = dayIndex);

    final weekConfig = ref.read(weekDisplayConfigProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);
    final tappedDate = weekConfig.dateForDataIndex(weekStart, dayIndex);
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

  /// Carousel page changed — sync the strip highlight.
  void _onCarouselPageChanged(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _carouselItems.length) return;
    final itemDate = _carouselItems[pageIndex].date;
    if (itemDate == null) return;
    final weekdayIndex = itemDate.weekday - 1; // 0 = Mon
    if (weekdayIndex != _selectedWeekDay) {
      setState(() => _selectedWeekDay = weekdayIndex);
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
      tooltip: 'Calendar display options',
      icon: Icon(Icons.tune, size: 18, color: tint),
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
                      ? 'Start week on Monday'
                      : 'Start week on Sunday',
                ),
              ),
              Text(
                startsSunday ? 'Sun' : 'Mon',
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
              const Expanded(child: Text('Show synced workouts')),
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
