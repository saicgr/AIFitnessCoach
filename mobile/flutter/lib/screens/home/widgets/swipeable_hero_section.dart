import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/today_workout_provider.dart';
import 'hero_workout_card.dart';
import 'hero_nutrition_card.dart';
import 'hero_fasting_card.dart';
import 'compact_workout_row.dart';

/// Focus type for the home screen
enum HomeFocus { workout, nutrition, fasting }

/// Provider to persist the user's home focus preference
final homeFocusProvider = StateProvider<HomeFocus>((ref) => HomeFocus.workout);

/// Swipeable hero section allowing users to switch between workout, nutrition, and fasting focus
/// Each focus shows a hero card with the compact workout row below (if not workout focus)
class SwipeableHeroSection extends ConsumerStatefulWidget {
  final Workout? todayWorkout;
  final bool isGenerating;

  const SwipeableHeroSection({
    super.key,
    this.todayWorkout,
    this.isGenerating = false,
  });

  @override
  ConsumerState<SwipeableHeroSection> createState() => _SwipeableHeroSectionState();
}

class _SwipeableHeroSectionState extends ConsumerState<SwipeableHeroSection> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialFocus = ref.read(homeFocusProvider);
    _pageController = PageController(
      initialPage: initialFocus.index,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(homeFocusProvider.notifier).state = HomeFocus.values[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFocus = ref.watch(homeFocusProvider);

    return Column(
      children: [
        // Page indicator dots
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: HomeFocus.values.map((focus) {
              final isActive = focus == currentFocus;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? _getFocusColor(focus)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Focus labels
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: HomeFocus.values.map((focus) {
              final isActive = focus == currentFocus;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _getFocusLabel(focus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? _getFocusColor(focus)
                          : (isDark
                              ? AppColors.textMuted
                              : AppColorsLight.textMuted),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Swipeable hero cards
        SizedBox(
          height: _getHeroHeight(currentFocus),
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Workout focus
              _buildWorkoutHero(),

              // Nutrition focus
              _buildNutritionHero(),

              // Fasting focus
              _buildFastingHero(),
            ],
          ),
        ),

        // Compact workout row (when not in workout focus)
        if (currentFocus != HomeFocus.workout)
          _buildCompactWorkoutRow(),
      ],
    );
  }

  Widget _buildWorkoutHero() {
    // Always show workout from todayWorkoutProvider - NEVER show rest day
    // This ensures consistency: either today's workout or next workout with date
    final todayWorkoutState = ref.watch(todayWorkoutProvider);

    return todayWorkoutState.when(
      loading: () => const GeneratingHeroCard(
        message: 'Loading workout...',
      ),
      error: (_, __) {
        // On error, try to use the passed workout as fallback
        if (widget.todayWorkout != null) {
          return HeroWorkoutCard(workout: widget.todayWorkout!);
        }
        return const GeneratingHeroCard(
          message: 'Loading workout...',
        );
      },
      data: (response) {
        // Check if generating
        if (response?.isGenerating == true || widget.isGenerating) {
          return GeneratingHeroCard(
            message: response?.generationMessage ?? 'Generating workout...',
          );
        }

        // Get workout: today's OR next (ALWAYS show a workout, never rest day)
        final workoutSummary = response?.todayWorkout ?? response?.nextWorkout;

        if (workoutSummary != null) {
          return HeroWorkoutCard(workout: workoutSummary.toWorkout());
        }

        // Fallback to passed workout if provider returned null
        if (widget.todayWorkout != null) {
          return HeroWorkoutCard(workout: widget.todayWorkout!);
        }

        // Last resort: show generating card (backend should auto-generate)
        return const GeneratingHeroCard(
          message: 'Preparing your workout...',
        );
      },
    );
  }

  Widget _buildCompactWorkoutRow() {
    final todayWorkoutState = ref.watch(todayWorkoutProvider);

    return todayWorkoutState.maybeWhen(
      data: (response) {
        final workoutSummary = response?.todayWorkout ?? response?.nextWorkout;
        if (workoutSummary != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CompactWorkoutRow(workout: workoutSummary.toWorkout()),
          );
        }
        // Fallback to passed workout
        if (widget.todayWorkout != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CompactWorkoutRow(workout: widget.todayWorkout!),
          );
        }
        return const SizedBox.shrink();
      },
      orElse: () {
        // While loading or on error, use passed workout if available
        if (widget.todayWorkout != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CompactWorkoutRow(workout: widget.todayWorkout!),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNutritionHero() {
    return const HeroNutritionCard();
  }

  Widget _buildFastingHero() {
    return const HeroFastingCard();
  }

  Color _getFocusColor(HomeFocus focus) {
    switch (focus) {
      case HomeFocus.workout:
        return AppColors.cyan;
      case HomeFocus.nutrition:
        return const Color(0xFF34C759);
      case HomeFocus.fasting:
        return AppColors.orange;
    }
  }

  String _getFocusLabel(HomeFocus focus) {
    switch (focus) {
      case HomeFocus.workout:
        return 'Workout';
      case HomeFocus.nutrition:
        return 'Nutrition';
      case HomeFocus.fasting:
        return 'Fasting';
    }
  }

  double _getHeroHeight(HomeFocus focus) {
    // Different hero cards have different heights
    switch (focus) {
      case HomeFocus.workout:
        return 340;
      case HomeFocus.nutrition:
        return 380; // Reduced from 470 - more compact design
      case HomeFocus.fasting:
        return 420;
    }
  }
}
