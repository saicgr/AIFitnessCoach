import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'hero_workout_card.dart';

/// Represents either a workout or a placeholder date in the carousel
class CarouselItem {
  final Workout? workout;
  final DateTime? placeholderDate;
  final bool isAutoGenerating;
  final bool isGenerationFailed;

  CarouselItem.workout(this.workout) : placeholderDate = null, isAutoGenerating = false, isGenerationFailed = false;
  CarouselItem.placeholder(this.placeholderDate, {this.isAutoGenerating = false, this.isGenerationFailed = false}) : workout = null;

  bool get isWorkout => workout != null;
  bool get isPlaceholder => placeholderDate != null;

  /// The date this carousel item represents (from workout or placeholder)
  DateTime? get date {
    if (placeholderDate != null) return placeholderDate;
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

  /// Shared card height constant
  static const double cardHeight = 280;

  const HeroWorkoutCarousel({
    super.key,
    this.externalPageController,
    this.onCarouselItemsChanged,
    this.onPageChanged,
  });

  /// Reset auto-generation flag (call on pull-to-refresh, regeneration, or logout)
  static void resetAutoGeneration() {
    _HeroWorkoutCarouselState.resetAutoGeneration();
  }

  /// Get remaining workout dates for this week (today through Sunday).
  /// Past days are skipped — no wrapping to next week.
  static List<DateTime> getWorkoutDatesForWeek(List<int> workoutDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = monday.add(Duration(days: day));
      if (!thisWeekDate.isBefore(today)) {
        dates.add(thisWeekDate);
      }
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

  /// Whether we own (and should dispose) the page controller
  bool get _ownsController => widget.externalPageController == null;
  PageController get _pageController =>
      widget.externalPageController ?? _ownedPageController!;

  /// No-op: generation is handled by todayWorkoutProvider
  static void resetAutoGeneration() {}

  /// Locally generated workouts stored for immediate display (Fix: workout vanishes after generation)
  final List<Workout> _locallyGeneratedWorkouts = [];

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
    if (_ownsController) {
      _ownedPageController?.dispose();
    }
    super.dispose();
  }

  /// Date key for tracking (YYYY-MM-DD)
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Get remaining workout dates for this week (today through Sunday).
  /// Past days are skipped — no wrapping to next week.
  List<DateTime> _getWorkoutDatesForWeek(List<int> workoutDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = monday.add(Duration(days: day));
      // Only include today or future dates this week
      if (!thisWeekDate.isBefore(today)) {
        dates.add(thisWeekDate);
      }
    }
    dates.sort((a, b) => a.compareTo(b));
    return dates;
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

    return userAsync.when(
      loading: () => _buildLoadingState(isDark, accentColor),
      error: (_, __) => _buildErrorState(isDark),
      data: (user) {
        if (user == null) {
          return _buildNoWorkoutDaysState(isDark, accentColor);
        }

        final workoutDays = user.workoutDays;

        // Wait for todayWorkoutProvider to complete initial load
        // This prevents auto-triggering generation before we know if workouts exist
        if (todayWorkoutAsync.isLoading && !todayWorkoutAsync.hasValue) {
          return _buildLoadingState(isDark, accentColor);
        }

        // Check todayWorkoutProvider first for today's/next workout
        final todayWorkoutResponse = todayWorkoutAsync.valueOrNull;
        final todayWorkout = todayWorkoutResponse?.todayWorkout?.toWorkout();
        final nextWorkout = todayWorkoutResponse?.nextWorkout?.toWorkout();

        // Use valueOrNull so we don't block on the slow all-workouts fetch
        final allWorkouts = workoutsAsync.valueOrNull ?? [];

        // Merge in today's workout from todayWorkoutProvider if not already in list
        final mergedWorkouts = List<Workout>.from(allWorkouts);
        if (todayWorkout != null && !mergedWorkouts.any((w) => w.id == todayWorkout.id)) {
          mergedWorkouts.add(todayWorkout);
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

        // Build carousel items: one per workout day (workout card or pending card)
        // Multiple workouts on the same day each get their own carousel card.
        List<CarouselItem> carouselItems = [];

        if (workoutDays.isNotEmpty) {
          final workoutDates = _getWorkoutDatesForWeek(workoutDays);
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
            } else {
              carouselItems.add(CarouselItem.placeholder(date));
            }
          }

          // Handle quick workouts on rest days (today not in workoutDays)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final todayKey = _dateKey(today);
          final isTodayWorkoutDay = workoutDates.any((d) => _dateKey(d) == todayKey);
          if (!isTodayWorkoutDay) {
            final restDayWorkouts = _findAllWorkoutsForDate(mergedWorkouts, today);
            for (final workout in restDayWorkouts) {
              final wId = workout.id ?? '';
              if (wId.isNotEmpty && addedWorkoutIds.add(wId)) {
                // Insert at the start so today's quick workout is visible first
                carouselItems.insert(0, CarouselItem.workout(workout));
              }
            }
          }
        }

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
              child: item.isWorkout
                  ? HeroWorkoutCard(workout: item.workout!, inCarousel: false)
                  : _buildPendingCard(item.placeholderDate!, isDark, accentColor),
            ),
          );
        }

        // PageView carousel for multiple items
        return SizedBox(
          height: 360,
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

              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 200),
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 200),
                  child: item.isWorkout
                      ? HeroWorkoutCard(workout: item.workout!, inCarousel: true)
                      : _buildPendingCard(item.placeholderDate!, isDark, accentColor),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Minimal card for workout days that don't have a generated workout yet.
  Widget _buildPendingCard(DateTime date, bool isDark, Color accentColor) {
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
              isToday ? 'Today' : dayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
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
                Text(
                  'Generating workout...',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutDaysState(bool isDark, Color accentColor) {
    return GestureDetector(
      onTap: () {
        // Refresh user data in case workout days were set but cache is stale
        ref.read(authStateProvider.notifier).refreshUser();
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
              Text('Set your workout days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text('Tap to refresh or go to Settings', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
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
      height: HeroWorkoutCarousel.cardHeight,
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
