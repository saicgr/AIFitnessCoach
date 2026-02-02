import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'hero_workout_card.dart';

/// Carousel based on user's workout days from profile.
/// Each day shows either a workout card or a "Generate" placeholder.
class HeroWorkoutCarousel extends ConsumerStatefulWidget {
  const HeroWorkoutCarousel({super.key});

  @override
  ConsumerState<HeroWorkoutCarousel> createState() =>
      _HeroWorkoutCarouselState();
}

class _HeroWorkoutCarouselState extends ConsumerState<HeroWorkoutCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // 0.88 = 88% card width, shows more peek of next card
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Get dates for this week based on profile workout days (0=Mon, 6=Sun)
  List<DateTime> _getWorkoutDatesForWeek(List<int> workoutDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final date = monday.add(Duration(days: day));
      // Include today and future dates only
      if (!date.isBefore(today)) {
        dates.add(date);
      }
    }
    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  /// Find workout for a specific date
  Workout? _findWorkoutForDate(List<Workout> workouts, DateTime date) {
    for (final workout in workouts) {
      if (workout.scheduledDate == null) continue;
      try {
        final workoutDate = DateTime.parse(workout.scheduledDate!);
        final workoutDateOnly = DateTime(
          workoutDate.year,
          workoutDate.month,
          workoutDate.day,
        );
        if (workoutDateOnly == date) {
          return workout;
        }
      } catch (_) {}
    }
    return null;
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

    return userAsync.when(
      loading: () => _buildLoadingState(isDark, accentColor),
      error: (_, __) => _buildErrorState(isDark),
      data: (user) {
        if (user == null) {
          return _buildNoWorkoutDaysState(isDark, accentColor);
        }

        final workoutDays = user.workoutDays;

        // Check todayWorkoutProvider first for today's/next workout
        final todayWorkoutResponse = todayWorkoutAsync.valueOrNull;
        final todayWorkout = todayWorkoutResponse?.todayWorkout?.toWorkout();
        final nextWorkout = todayWorkoutResponse?.nextWorkout?.toWorkout();

        return workoutsAsync.when(
          loading: () => _buildLoadingState(isDark, accentColor),
          error: (_, __) => _buildErrorState(isDark),
          data: (workouts) {
            // Merge in today's workout from todayWorkoutProvider if not already in list
            final mergedWorkouts = List<Workout>.from(workouts);
            if (todayWorkout != null && !mergedWorkouts.any((w) => w.id == todayWorkout.id)) {
              mergedWorkouts.add(todayWorkout);
            }
            if (nextWorkout != null && !mergedWorkouts.any((w) => w.id == nextWorkout.id)) {
              mergedWorkouts.add(nextWorkout);
            }

            // Build the list of workouts to show in carousel
            // Priority: use workoutDays-based dates if available, otherwise use workout scheduled dates
            List<Workout> carouselWorkouts = [];

            if (workoutDays.isNotEmpty) {
              // Use workoutDays to determine which dates to show
              final workoutDates = _getWorkoutDatesForWeek(workoutDays);
              for (final date in workoutDates) {
                final workout = _findWorkoutForDate(mergedWorkouts, date);
                if (workout != null) {
                  carouselWorkouts.add(workout);
                }
              }
            }

            // If no workouts from workoutDays, use workouts from providers directly
            if (carouselWorkouts.isEmpty) {
              // Filter to only show incomplete workouts scheduled for today or future
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              carouselWorkouts = mergedWorkouts.where((w) {
                if (w.isCompleted == true) return false;
                if (w.scheduledDate == null) return false;
                try {
                  final date = DateTime.parse(w.scheduledDate!);
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  return !dateOnly.isBefore(today);
                } catch (_) {
                  return false;
                }
              }).toList();

              // Sort by scheduled date
              carouselWorkouts.sort((a, b) {
                final dateA = a.scheduledDate ?? '';
                final dateB = b.scheduledDate ?? '';
                return dateA.compareTo(dateB);
              });
            }

            // If still no workouts, show appropriate state
            if (carouselWorkouts.isEmpty) {
              if (workoutDays.isEmpty) {
                return _buildNoWorkoutDaysState(isDark, accentColor);
              }
              return _buildAllDoneState(isDark, accentColor);
            }

            // Show single card if only one workout (no carousel needed)
            if (carouselWorkouts.length == 1) {
              return SizedBox(
                height: 440,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HeroWorkoutCard(
                    workout: carouselWorkouts.first,
                    inCarousel: false,
                  ),
                ),
              );
            }

            // PageView carousel for multiple workouts
            return SizedBox(
              height: 440,
              child: PageView.builder(
                controller: _pageController,
                itemCount: carouselWorkouts.length,
                onPageChanged: (index) {
                  HapticService.selection();
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final workout = carouselWorkouts[index];

                  // Scale down and slightly dim non-active cards
                  final isActive = index == _currentPage;
                  final scale = isActive ? 1.0 : 0.92;
                  final opacity = isActive ? 1.0 : 0.8;

                  return AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 200),
                      child: HeroWorkoutCard(
                        workout: workout,
                        inCarousel: true,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoWorkoutDaysState(bool isDark, Color accentColor) {
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
            Icon(Icons.calendar_today_outlined, size: 48, color: accentColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Set your workout days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Go to Settings to configure', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
          ],
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
            Text('All done for this week!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Rest up for next week', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color accentColor) {
    return Container(
      height: 440,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(child: CircularProgressIndicator(color: accentColor)),
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
        child: Text('Could not load workouts', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
      ),
    );
  }
}
