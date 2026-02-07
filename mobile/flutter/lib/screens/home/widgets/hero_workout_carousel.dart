import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'hero_workout_card.dart';
import 'generate_workout_placeholder.dart';

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
}

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
  DateTime? _generatingForDate;
  bool _autoGenerationTriggered = false;

  /// Tracks generation failure counts per date for retry logic (Fix 4)
  final Map<String, int> _generationFailures = {};

  /// Max retries before showing permanent error state
  static const int _maxRetries = 3;

  /// Retry delay schedule: 5s, 15s, 30s
  static const List<int> _retryDelaySeconds = [5, 15, 30];

  /// Active retry timers per date
  final Map<String, Timer> _retryTimers = {};

  /// Dates that have permanently failed (exceeded max retries)
  final Set<String> _permanentlyFailed = {};

  @override
  void initState() {
    super.initState();
    // 0.88 = 88% card width, shows more peek of next card
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Cancel all retry timers (Fix 4)
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    super.dispose();
  }

  /// Date key for tracking (YYYY-MM-DD)
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _handleGenerateWorkout(DateTime date) async {
    final key = _dateKey(date);

    // Clear permanent failure state if user manually taps retry
    _permanentlyFailed.remove(key);

    setState(() => _generatingForDate = date);
    try {
      // Trigger workout generation for this date
      await ref.read(workoutsProvider.notifier).generateWorkoutForDate(date);
      // Refresh the workouts list
      ref.invalidate(workoutsProvider);
      ref.invalidate(todayWorkoutProvider);

      // Success: clear failure tracking for this date
      _generationFailures.remove(key);
      _retryTimers[key]?.cancel();
      _retryTimers.remove(key);
    } catch (e) {
      debugPrint('[HeroCarousel] Generation failed for $key: $e');
      _handleGenerationFailure(date);
    } finally {
      if (mounted) {
        setState(() => _generatingForDate = null);
      }
    }
  }

  /// Handle a generation failure: track count and schedule retry (Fix 4)
  void _handleGenerationFailure(DateTime date) {
    final key = _dateKey(date);
    final currentFailures = (_generationFailures[key] ?? 0) + 1;
    _generationFailures[key] = currentFailures;

    debugPrint('[HeroCarousel] Generation failure #$currentFailures for $key');

    if (currentFailures >= _maxRetries) {
      // Max retries exceeded: show permanent error state
      debugPrint('[HeroCarousel] Max retries ($currentFailures) reached for $key, showing error state');
      if (mounted) {
        setState(() => _permanentlyFailed.add(key));
      }
      return;
    }

    // Schedule retry with increasing delay
    final delayIndex = currentFailures - 1;
    final delaySec = delayIndex < _retryDelaySeconds.length
        ? _retryDelaySeconds[delayIndex]
        : _retryDelaySeconds.last;

    debugPrint('[HeroCarousel] Scheduling retry #${currentFailures + 1} for $key in ${delaySec}s');

    _retryTimers[key]?.cancel();
    _retryTimers[key] = Timer(Duration(seconds: delaySec), () {
      if (mounted && !_permanentlyFailed.contains(key)) {
        debugPrint('[HeroCarousel] Auto-retrying generation for $key');
        _handleGenerateWorkout(date);
      }
    });
  }

  /// Whether a date has permanently failed generation
  bool _isGenerationFailed(DateTime date) => _permanentlyFailed.contains(_dateKey(date));

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
        final workoutDate = DateTime.parse(workout.scheduledDate!).toLocal();
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

        // Detect if auto-generation is in progress from todayWorkoutProvider
        final isAutoGenerating = todayWorkoutResponse?.isGenerating == true;
        final autoGeneratingDateStr = todayWorkoutResponse?.nextWorkoutDate;

        // Parse the auto-generating date for comparison with carousel dates
        DateTime? autoGeneratingDate;
        if (autoGeneratingDateStr != null) {
          try {
            autoGeneratingDate = DateTime.parse(autoGeneratingDateStr);
            autoGeneratingDate = DateTime(autoGeneratingDate.year, autoGeneratingDate.month, autoGeneratingDate.day);
          } catch (_) {}
        }

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

            // Build the list of carousel items (workouts + placeholders for workout days)
            List<CarouselItem> carouselItems = [];

            if (workoutDays.isNotEmpty) {
              // Use workoutDays to determine which dates to show
              final workoutDates = _getWorkoutDatesForWeek(workoutDays);
              for (final date in workoutDates) {
                final workout = _findWorkoutForDate(mergedWorkouts, date);
                if (workout != null) {
                  carouselItems.add(CarouselItem.workout(workout));
                } else {
                  // Check if this date is being auto-generated by todayWorkoutProvider
                  final isThisDateAutoGenerating = isAutoGenerating && autoGeneratingDate != null && date == autoGeneratingDate;
                  final isThisDateFailed = _isGenerationFailed(date);
                  carouselItems.add(CarouselItem.placeholder(
                    date,
                    isAutoGenerating: isThisDateAutoGenerating,
                    isGenerationFailed: isThisDateFailed,
                  ));
                }
              }
            }

            // Auto-trigger generation for the first placeholder date on a non-workout day
            // This ensures the user doesn't have to manually tap "Generate" when they
            // open the app on a rest day and the next workout hasn't been generated yet
            if (!_autoGenerationTriggered && carouselItems.isNotEmpty) {
              final firstItem = carouselItems.first;
              if (firstItem.isPlaceholder && !firstItem.isAutoGenerating && _generatingForDate == null) {
                // Only auto-trigger if todayWorkoutProvider isn't already handling it
                if (!isAutoGenerating) {
                  _autoGenerationTriggered = true;
                  debugPrint('🚀 [HeroCarousel] Auto-triggering generation for first placeholder: ${firstItem.placeholderDate}');
                  // Use post-frame callback to avoid triggering during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _handleGenerateWorkout(firstItem.placeholderDate!);
                    }
                  });
                }
              }
            }

            // If no workout days configured, fall back to showing available workouts
            if (carouselItems.isEmpty) {
              // Filter to only show incomplete workouts scheduled for today or future
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final filteredWorkouts = mergedWorkouts.where((w) {
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
              filteredWorkouts.sort((a, b) {
                final dateA = a.scheduledDate ?? '';
                final dateB = b.scheduledDate ?? '';
                return dateA.compareTo(dateB);
              });

              carouselItems = filteredWorkouts.map((w) => CarouselItem.workout(w)).toList();
            }

            // If still no items, show appropriate state
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
                height: 440,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: item.isWorkout
                      ? HeroWorkoutCard(
                          workout: item.workout!,
                          inCarousel: false,
                        )
                      : GenerateWorkoutPlaceholder(
                          date: item.placeholderDate!,
                          onGenerate: () => _handleGenerateWorkout(item.placeholderDate!),
                          isGenerating: _generatingForDate == item.placeholderDate || item.isAutoGenerating,
                          isGenerationFailed: item.isGenerationFailed,
                        ),
                ),
              );
            }

            // PageView carousel for multiple items
            return SizedBox(
              height: 440,
              child: PageView.builder(
                controller: _pageController,
                itemCount: carouselItems.length,
                onPageChanged: (index) {
                  HapticService.selection();
                  setState(() => _currentPage = index);
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
                          ? HeroWorkoutCard(
                              workout: item.workout!,
                              inCarousel: true,
                            )
                          : GenerateWorkoutPlaceholder(
                              date: item.placeholderDate!,
                              onGenerate: () => _handleGenerateWorkout(item.placeholderDate!),
                              isGenerating: _generatingForDate == item.placeholderDate || item.isAutoGenerating,
                              isGenerationFailed: item.isGenerationFailed,
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
