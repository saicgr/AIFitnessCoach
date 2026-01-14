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
enum HomeFocus { forYou, workout, nutrition, fasting }

/// Provider to persist the user's home focus preference
final homeFocusProvider = StateProvider<HomeFocus>((ref) => HomeFocus.forYou);

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
  bool _isAnimating = false;

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
    if (!_isAnimating) {
      ref.read(homeFocusProvider.notifier).state = HomeFocus.values[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFocus = ref.watch(homeFocusProvider);

    // Sync PageController when provider changes (e.g., from pills)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != currentFocus.index) {
        _isAnimating = true;
        _pageController
            .animateToPage(
              currentFocus.index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
            .then((_) => _isAnimating = false);
      }
    });

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
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
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
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              // For You focus (same as workout)
              _buildWorkoutHero(),

              // Workout focus
              _buildWorkoutHero(),

              // Nutrition focus
              _buildNutritionHero(),

              // Fasting focus
              _buildFastingHero(),
            ],
          ),
        ),

        // Compact workout row (when in nutrition or fasting focus)
        if (currentFocus == HomeFocus.nutrition || currentFocus == HomeFocus.fasting)
          _buildCompactWorkoutRow(),
      ],
    );
  }

  Widget _buildWorkoutHero() {
    // Always show workout from todayWorkoutProvider - NEVER show rest day
    // This ensures consistency: either today's workout or next workout with date
    final todayWorkoutState = ref.watch(todayWorkoutProvider);

    // Debug logging
    debugPrint('🏠 [SwipeableHero] todayWorkoutState: ${todayWorkoutState.runtimeType}');
    todayWorkoutState.whenData((response) {
      debugPrint('🏠 [SwipeableHero] response: $response');
      debugPrint('🏠 [SwipeableHero] hasWorkoutToday: ${response?.hasWorkoutToday}');
      debugPrint('🏠 [SwipeableHero] todayWorkout: ${response?.todayWorkout}');
      debugPrint('🏠 [SwipeableHero] nextWorkout: ${response?.nextWorkout}');
      debugPrint('🏠 [SwipeableHero] isGenerating: ${response?.isGenerating}');
    });

    return todayWorkoutState.when(
      loading: () {
        debugPrint('🏠 [SwipeableHero] State: LOADING');
        return const GeneratingHeroCard(
          message: 'Loading workout...',
        );
      },
      error: (error, stack) {
        debugPrint('🏠 [SwipeableHero] State: ERROR - $error');
        // On error, try to use the passed workout as fallback
        if (widget.todayWorkout != null) {
          return HeroWorkoutCard(workout: widget.todayWorkout!);
        }
        // Show loading state instead of empty card on error
        return const GeneratingHeroCard(
          message: 'Loading workout...',
          subtitle: 'Please wait',
        );
      },
      data: (response) {
        debugPrint('🏠 [SwipeableHero] State: DATA');

        // Get workout: today's OR next (ALWAYS show a workout, never rest day)
        final workoutSummary = response?.todayWorkout ?? response?.nextWorkout;

        // Check if generating OR if no workouts exist (post-onboarding state)
        final hasNoWorkouts = workoutSummary == null && widget.todayWorkout == null;
        final isGeneratingWorkout = response?.isGenerating == true || widget.isGenerating;

        if (isGeneratingWorkout || hasNoWorkouts) {
          // If no workouts exist and not completed today, show generating card
          // This handles the post-onboarding gap when workouts are being generated
          if (response?.completedToday != true) {
            debugPrint('🏠 [SwipeableHero] Showing GeneratingHeroCard (isGenerating=$isGeneratingWorkout, hasNoWorkouts=$hasNoWorkouts)');
            return GeneratingHeroCard(
              message: response?.generationMessage ?? 'Preparing your workout...',
              subtitle: 'Your personalized workout plan is being created',
            );
          }
        }

        // Check if user completed today's workout - show next workout with completion banner
        if (response?.completedToday == true &&
            response?.completedWorkout != null &&
            response?.nextWorkout != null) {
          debugPrint('🏠 [SwipeableHero] Showing CompletedWorkoutHeroCard (completedToday)');
          return CompletedWorkoutHeroCard(
            completedWorkout: response!.completedWorkout!.toWorkout(),
            nextWorkout: response.nextWorkout!.toWorkout(),
            daysUntilNext: response.daysUntilNext ?? 1,
          );
        }

        debugPrint('🏠 [SwipeableHero] workoutSummary: $workoutSummary');

        if (workoutSummary != null) {
          debugPrint('🏠 [SwipeableHero] Showing HeroWorkoutCard with workout: ${workoutSummary.name}');
          return HeroWorkoutCard(workout: workoutSummary.toWorkout());
        }

        // Fallback to passed workout if provider returned null
        if (widget.todayWorkout != null) {
          debugPrint('🏠 [SwipeableHero] Using fallback widget.todayWorkout');
          return HeroWorkoutCard(workout: widget.todayWorkout!);
        }

        // Final fallback - show generating card (should rarely reach here)
        debugPrint('🏠 [SwipeableHero] Final fallback: showing GeneratingHeroCard');
        return const GeneratingHeroCard(
          message: 'Preparing your workout...',
          subtitle: 'This may take a moment',
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
      case HomeFocus.forYou:
        return AppColors.teal;
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
      case HomeFocus.forYou:
        return 'For You';
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
      case HomeFocus.forYou:
        return 340; // Same as workout
      case HomeFocus.workout:
        return 340;
      case HomeFocus.nutrition:
        return 380; // Reduced from 470 - more compact design
      case HomeFocus.fasting:
        return 420;
    }
  }
}
