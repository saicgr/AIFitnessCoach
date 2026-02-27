import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'hero_workout_carousel.dart';
import 'hero_workout_card.dart';
import 'hero_nutrition_card.dart';
import 'hero_fasting_card.dart';
import 'week_calendar_strip.dart';
import 'swipeable_hero_section.dart' show HomeFocus, homeFocusProvider;
import '../../wrapped/widgets/wrapped_banner.dart';

/// Sectioned hero area with tab pills (Workouts | Nutrition | Fasting).
/// Calendar strip only shows for the Workouts tab.
class SectionedHeroArea extends ConsumerStatefulWidget {
  final PageController carouselPageController;
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
  static const _kContentHeight = 429.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFocus = ref.watch(homeFocusProvider);
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WrappedBanner(),
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
        SizedBox(
          height: _kContentHeight,
          child: Column(
            children: [
              if (currentFocus == HomeFocus.workout) ...[
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
      case HomeFocus.fasting:
        return const HeroFastingCard();
    }
  }

  Widget _buildWorkoutContent(bool isDark) {
    if (widget.isInitializing && !widget.todayWorkoutState.hasValue) {
      return const GeneratingHeroCard(
        message: 'Loading your workout...',
      );
    }

    if ((widget.isAIGenerating ||
            widget.todayWorkoutState.valueOrNull?.isGenerating == true) &&
        widget.todayWorkoutState.valueOrNull?.hasDisplayableContent != true) {
      return GeneratingHeroCard(
        message: widget.todayWorkoutState.valueOrNull?.generationMessage ??
            'Generating your workout...',
      );
    }

    return HeroWorkoutCarousel(
      externalPageController: widget.carouselPageController,
      onCarouselItemsChanged: widget.onCarouselItemsChanged,
      onPageChanged: widget.onPageChanged,
    );
  }

  Widget _buildWeekCalendarStrip(bool isDark) {
    final userAsync = ref.watch(currentUserProvider);
    final workoutsAsync = ref.watch(workoutsProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final workoutDays = user.workoutDays;
    if (workoutDays.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = today.weekday - 1;
    final monday = today.subtract(Duration(days: todayIndex));

    final allWorkouts = workoutsAsync.valueOrNull ?? [];
    final Map<int, bool?> statusMap = {};

    for (int i = 0; i < 7; i++) {
      if (!workoutDays.contains(i)) {
        statusMap[i] = null;
        continue;
      }
      final dayDate = monday.add(Duration(days: i));
      final dateKey =
          '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

      final workout = allWorkouts.where((w) {
        if (w.scheduledDate == null) return false;
        return w.scheduledDate!.split('T')[0] == dateKey;
      }).toList();

      if (workout.isNotEmpty && workout.any((w) => w.isCompleted == true)) {
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

/// Row of tab pills: Workouts | Nutrition | Fasting
class _HeroTabPills extends StatelessWidget {
  final HomeFocus currentFocus;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<HomeFocus> onTabSelected;

  static const _tabs = [HomeFocus.workout, HomeFocus.nutrition, HomeFocus.fasting];

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
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _tabs.map((focus) {
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
        }).toList(),
      ),
    );
  }
}
