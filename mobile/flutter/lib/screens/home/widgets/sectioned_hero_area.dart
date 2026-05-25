import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/providers/synced_visibility_provider.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'hero_workout_carousel.dart';
import 'hero_workout_card.dart';
import 'recovery_pills_row.dart';
import 'hero_nutrition_card.dart';
// TODO: Re-enable when fasting feature launches
// import 'hero_fasting_card.dart';
import 'week_calendar_strip.dart';
import 'swipeable_hero_section.dart' show HomeFocus, homeFocusProvider;

import '../../../l10n/generated/app_localizations.dart';
/// Sectioned hero area with tab pills (Workouts | Nutrition | Fasting).
/// Calendar strip only shows for the Workouts tab.
class SectionedHeroArea extends ConsumerStatefulWidget {
  final PageController carouselPageController;
  final GlobalKey? carouselKey;
  final ValueChanged<List<CarouselItem>>? onCarouselItemsChanged;
  final ValueChanged<int>? onPageChanged;
  final AsyncValue<TodayWorkoutResponse?> todayWorkoutState;
  final bool isAIGenerating;
  final bool isInitializing;
  final int selectedWeekDay;
  final ValueChanged<int> onWeekDaySelected;

  const SectionedHeroArea({
    super.key,
    required this.carouselPageController,
    this.carouselKey,
    this.onCarouselItemsChanged,
    this.onPageChanged,
    required this.todayWorkoutState,
    required this.isAIGenerating,
    required this.isInitializing,
    required this.selectedWeekDay,
    required this.onWeekDaySelected,
  });

  @override
  ConsumerState<SectionedHeroArea> createState() => _SectionedHeroAreaState();
}

class _SectionedHeroAreaState extends ConsumerState<SectionedHeroArea> {
  // Fixed height: calendarStrip(61) + gap(8) + carousel(360) = 429
  static const _kContentHeightExpanded = 429.0;
  // Collapsed strip is shorter: collapsedStrip(30) + gap(8) + carousel(360) = 398
  static const _kContentHeightCollapsed = 398.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFocus = ref.watch(homeFocusProvider);
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);
    final isCalendarCollapsed = ref.watch(weekCalendarCollapsedProvider);
    final isCalendarHidden = ref.watch(weekCalendarHiddenProvider);

    // Hidden takes precedence — no strip rendered at all, content gets the
    // full height back.
    final contentHeight = (currentFocus == HomeFocus.workout &&
            (isCalendarCollapsed || isCalendarHidden))
        ? _kContentHeightCollapsed
        : _kContentHeightExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab pills
        _HeroTabPills(
          currentFocus: currentFocus,
          accentColor: accentColor,
          isDark: isDark,
          onTabSelected: (focus) {
            HapticService.selection();
            ref.read(homeFocusProvider.notifier).state = focus;
          },
        ),
        const SizedBox(height: 8),
        // Fixed height so all tabs occupy identical space — content
        // below never shifts. Cards stretch via Expanded to fill.
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: contentHeight,
          child: Column(
            children: [
              if (currentFocus == HomeFocus.workout && !isCalendarHidden) ...[
                _buildWeekCalendarStrip(isDark),
                const SizedBox(height: 8),
              ],
              Expanded(child: _buildContent(currentFocus, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(HomeFocus focus, bool isDark) {
    switch (focus) {
      case HomeFocus.workout:
      case HomeFocus.forYou:
        return _buildWorkoutContent(isDark);
      case HomeFocus.nutrition:
        return const HeroNutritionCard();
      // TODO: Re-enable when fasting feature launches
      case HomeFocus.fasting:
        return const SizedBox.shrink(); // was: HeroFastingCard()
    }
  }

  Widget _buildWorkoutContent(bool isDark) {
    if (widget.isInitializing && !widget.todayWorkoutState.hasValue) {
      // Wrap with carouselKey so the app tour spotlight can find this widget
      // even while workout data is still loading.
      return KeyedSubtree(
        key: widget.carouselKey,
        child: const GeneratingHeroCard(
          message: 'Loading your workout...',
        ),
      );
    }

    if ((widget.isAIGenerating ||
            widget.todayWorkoutState.valueOrNull?.isGenerating == true) &&
        widget.todayWorkoutState.valueOrNull?.hasDisplayableContent != true) {
      return KeyedSubtree(
        key: widget.carouselKey,
        child: GeneratingHeroCard(
          message: widget.todayWorkoutState.valueOrNull?.generationMessage ??
              'Generating your workout...',
        ),
      );
    }

    // Phase 4 — recovery pills sit directly above the hero so users see
    // per-muscle readiness at a glance before tapping Start.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RecoveryPillsRow(),
        HeroWorkoutCarousel(
          externalPageController: widget.carouselPageController,
          onCarouselItemsChanged: widget.onCarouselItemsChanged,
          onPageChanged: widget.onPageChanged,
          carouselKey: widget.carouselKey,
        ),
      ],
    );
  }

  Widget _buildWeekCalendarStrip(bool isDark) {
    final userAsync = ref.watch(currentUserProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final activeGymProfile = ref.watch(activeGymProfileProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    // Use the active gym profile's workout days (per-profile schedule).
    // Fall back to the global user field only when no gym profile is loaded yet.
    final workoutDays = (activeGymProfile?.workoutDays.isNotEmpty == true)
        ? activeGymProfile!.workoutDays
        : user.workoutDays;
    if (workoutDays.isEmpty) return const SizedBox.shrink();

    final weekConfig = ref.watch(weekDisplayConfigProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    // Merge today's response into the workouts list before computing status.
    // /today is the source of truth for "did the user finish today's workout?"
    // because it sees the latest is_completed flips immediately after the
    // backend cache invalidation. workoutsProvider lags behind (silent refresh,
    // disk-cache hydration on cold paint), so without this merge the day strip
    // drops back to "scheduled" the moment workoutsProvider rehydrates from
    // its in-memory or disk cache after navigating back from the summary screen.
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

      final workout = mergedWorkouts.where((w) {
        if (w.scheduledDate == null) return false;
        // Match both "YYYY-MM-DDT…" and "YYYY-MM-DD …" Postgres formats.
        final raw = w.scheduledDate!;
        final dateOnly = raw.length >= 10 ? raw.substring(0, 10) : raw;
        return dateOnly == dateKey;
      }).toList();

      // Only Zealova-authored workouts paint the green completion dot.
      // Synced Health-Connect / Apple-Health imports surface in their own
      // synced UI (cyan card on the carousel, Synced Workouts History tab)
      // — they shouldn't override the planned-day status.
      final zealovaCompleted = workout.any(
        (w) => w.isCompleted == true && !w.isSyncedFromHealthApp,
      );
      if (workout.isNotEmpty && zealovaCompleted) {
        statusMap[i] = true;
      } else {
        statusMap[i] = false;
      }
    }

    return WeekCalendarStrip(
      workoutDays: workoutDays,
      workoutStatusMap: statusMap,
      selectedDayIndex: widget.selectedWeekDay,
      onDaySelected: widget.onWeekDaySelected,
    );
  }
}

/// Row of tab pills: Workouts | Nutrition | Fasting  +  Mon/Sun toggle on the right
class _HeroTabPills extends ConsumerWidget {
  final HomeFocus currentFocus;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<HomeFocus> onTabSelected;

  // COMING SOON: Add HomeFocus.fasting back when fasting feature launches
  static const _tabs = [HomeFocus.workout, HomeFocus.nutrition];

  const _HeroTabPills({
    required this.currentFocus,
    required this.accentColor,
    required this.isDark,
    required this.onTabSelected,
  });

  String _label(HomeFocus focus) {
    switch (focus) {
      case HomeFocus.workout:
        return 'Workouts';
      case HomeFocus.nutrition:
        return 'Nutrition';
      case HomeFocus.fasting:
        return 'Fasting';
      case HomeFocus.forYou:
        return 'For You';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final startsSunday = ref.watch(weekStartsSundayProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ..._tabs.map((focus) {
            final isActive = focus == currentFocus;
            return Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabSelected(focus),
                child: Semantics(
                  selected: isActive,
                  label: '${_label(focus)} tab',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          _label(focus).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                            color: isActive ? accentColor : textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Overflow menu: holds the week-start swap and the synced-workout
          // visibility toggle. Replaces the previous always-visible "Mon/Sun"
          // pill — these are infrequent toggles, so a 3-dot menu keeps the
          // header strip cleaner while still keeping them one tap away.
          if (currentFocus == HomeFocus.workout)
            _HeroOverflowMenu(
              startsSunday: startsSunday,
              isDark: isDark,
              tint: textMuted,
            ),
        ],
      ),
    );
  }
}

class _HeroOverflowMenu extends ConsumerWidget {
  final bool startsSunday;
  final bool isDark;
  final Color tint;

  const _HeroOverflowMenu({
    required this.startsSunday,
    required this.isDark,
    required this.tint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSynced = ref.watch(showSyncedInCarouselProvider);
    return PopupMenuButton<_HeroOverflowAction>(
      tooltip: AppLocalizations.of(context).workoutPlannerCalendarDisplayOptions,
      icon: Icon(Icons.tune, size: 18, color: tint),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        HapticService.selection();
        switch (action) {
          case _HeroOverflowAction.toggleWeekStart:
            ref.read(weekStartsSundayProvider.notifier).toggle();
            break;
          case _HeroOverflowAction.toggleSynced:
            ref.read(showSyncedInCarouselProvider.notifier).toggle();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _HeroOverflowAction.toggleWeekStart,
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  startsSunday ? AppLocalizations.of(context).workoutPlannerStartWeekOnMonday : AppLocalizations.of(context).sectionedHeroAreaStartWeekOnSunday,
                ),
              ),
              Text(
                startsSunday ? AppLocalizations.of(context).workoutPlannerSun : AppLocalizations.of(context).workoutPlannerMon,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _HeroOverflowAction.toggleSynced,
          child: Row(
            children: [
              Icon(
                showSynced ? Icons.visibility : Icons.visibility_off_outlined,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(AppLocalizations.of(context).workoutPlannerShowSyncedWorkouts)),
              Switch.adaptive(
                value: showSynced,
                onChanged: (_) {
                  Navigator.of(context).pop(_HeroOverflowAction.toggleSynced);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _HeroOverflowAction { toggleWeekStart, toggleSynced }
