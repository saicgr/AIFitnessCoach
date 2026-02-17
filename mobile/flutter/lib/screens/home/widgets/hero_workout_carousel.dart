import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/comeback_mode_sheet.dart';
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
  static const double cardHeight = 340;

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

  /// Get workout dates for the current week given workout day indices.
  /// Returns dates from today forward, wrapping to next week for past days.
  static List<DateTime> getWorkoutDatesForWeek(List<int> workoutDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = monday.add(Duration(days: day));
      if (!thisWeekDate.isBefore(today)) {
        dates.add(thisWeekDate);
      } else {
        dates.add(nextMonday.add(Duration(days: day)));
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

  /// Static so it survives widget disposal on tab switch (ShellRoute recreates HomeScreen)
  static DateTime? _generatingForDate;
  static bool _autoGenerationTriggered = false;

  /// Reset auto-generation flag (call on pull-to-refresh, regeneration, or logout)
  static void resetAutoGeneration() {
    _autoGenerationTriggered = false;
    _generatingForDate = null;
  }

  /// Generation step tracking for numbered progress UI
  int _generationStep = 0;
  int _generationTotalSteps = 4;
  String _generationMessage = '';

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

  /// Minimum days since last completed workout to trigger comeback mode prompt.
  static const int _comebackThresholdDays = 14;

  /// Computes days since the most recent completed workout.
  /// Returns null if no completed workouts are found.
  int? _daysSinceLastCompletedWorkout() {
    final workouts = ref.read(workoutsProvider).valueOrNull ?? [];
    DateTime? latestCompleted;
    for (final w in workouts) {
      if (w.isCompleted != true) continue;
      final dateKey = w.scheduledDateKey;
      if (dateKey == null) continue;
      try {
        final parts = dateKey.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (latestCompleted == null || d.isAfter(latestCompleted)) {
          latestCompleted = d;
        }
      } catch (_) {}
    }
    if (latestCompleted == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(latestCompleted).inDays;
  }

  Future<void> _handleGenerateWorkout(DateTime date) async {
    final key = _dateKey(date);

    // Clear permanent failure state if user manually taps retry
    _permanentlyFailed.remove(key);

    // --- Comeback mode check ---
    bool? skipComeback = ref.read(comebackChoiceProvider);
    if (skipComeback == null) {
      final daysSince = _daysSinceLastCompletedWorkout();
      if (daysSince != null && daysSince >= _comebackThresholdDays && mounted) {
        final choice = await showComebackModeSheet(context, daysSinceLastWorkout: daysSince);
        if (!mounted) return;
        if (choice == null) {
          // User dismissed without choosing - don't generate
          return;
        }
        // choice: true = skip comeback (full workout), false = use comeback mode
        skipComeback = choice;
        ref.read(comebackChoiceProvider.notifier).state = choice;
      }
    }

    setState(() {
      _generatingForDate = date;
      _generationStep = 1;
      _generationTotalSteps = 4;
      _generationMessage = 'Analyzing your profile...';
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      String? userId = await apiClient.getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ [HeroCarousel] Cannot generate workout: no userId');
        _handleGenerationFailure(date);
        return;
      }

      final scheduledDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('🏋️ [HeroCarousel] Streaming generation for $scheduledDate');

      int chunkCount = 0;
      Workout? generatedWorkout;

      await for (final progress in repository.generateWorkoutStreaming(
        userId: userId,
        scheduledDate: scheduledDate,
        skipComeback: skipComeback,
      )) {
        if (!mounted) break;

        if (progress.status == WorkoutGenerationStatus.started) {
          setState(() {
            _generationStep = 1;
            _generationMessage = 'Analyzing your profile...';
          });
        } else if (progress.status == WorkoutGenerationStatus.progress) {
          chunkCount++;
          if (chunkCount == 1) {
            setState(() {
              _generationStep = 2;
              _generationMessage = 'Selecting exercises...';
            });
          } else if (chunkCount >= 3) {
            setState(() {
              _generationStep = 3;
              _generationMessage = 'Building your workout...';
            });
          }
        } else if (progress.status == WorkoutGenerationStatus.completed) {
          setState(() {
            _generationStep = 4;
            _generationMessage = 'Finalizing workout...';
          });
          generatedWorkout = progress.workout;
        } else if (progress.status == WorkoutGenerationStatus.error) {
          debugPrint('❌ [HeroCarousel] Stream error: ${progress.message}');
          _handleGenerationFailure(date);
          return;
        }
      }

      if (generatedWorkout != null) {
        // Store locally for immediate display (prevents vanishing after generation)
        _locallyGeneratedWorkouts.add(generatedWorkout);
        // Refresh providers to pick up the new workout
        ref.invalidate(workoutsProvider);
        ref.invalidate(todayWorkoutProvider);
        // Success: clear failure tracking
        _generationFailures.remove(key);
        _retryTimers[key]?.cancel();
        _retryTimers.remove(key);
      } else {
        _handleGenerationFailure(date);
      }
    } catch (e) {
      debugPrint('❌ [HeroCarousel] Generation failed for $key: $e');
      _handleGenerationFailure(date);
    } finally {
      if (mounted) {
        setState(() {
          _generatingForDate = null;
          _generationStep = 0;
          _generationMessage = '';
        });
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

  /// Get the next N workout dates starting from today, wrapping to next week.
  /// Always returns exactly workoutDays.length dates.
  List<DateTime> _getWorkoutDatesForWeek(List<int> workoutDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = monday.add(Duration(days: day));
      // If this week's date is today or future, use it; otherwise wrap to next week
      if (!thisWeekDate.isBefore(today)) {
        dates.add(thisWeekDate);
      } else {
        dates.add(nextMonday.add(Duration(days: day)));
      }
    }
    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  /// Find workout for a specific date using string comparison
  /// to avoid timezone shift issues (DateTime.parse on date-only strings
  /// creates UTC midnight, and .toLocal() can shift the date backward).
  Workout? _findWorkoutForDate(List<Workout> workouts, DateTime date) {
    final targetKey = _dateKey(date); // "YYYY-MM-DD" from local DateTime
    for (final workout in workouts) {
      if (workout.scheduledDate == null) continue;
      // Compare date strings directly — scheduledDate is "YYYY-MM-DD" or "YYYY-MM-DDT..."
      final workoutDateStr = workout.scheduledDate!.split('T')[0];
      if (workoutDateStr == targetKey) {
        return workout;
      }
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

        // Wait for todayWorkoutProvider to complete initial load
        // This prevents auto-triggering generation before we know if workouts exist
        if (todayWorkoutAsync.isLoading && !todayWorkoutAsync.hasValue) {
          return _buildLoadingState(isDark, accentColor);
        }

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

        // Build carousel items: one slide per workout day, wrapping to next week
        List<CarouselItem> carouselItems = [];

        if (workoutDays.isNotEmpty) {
          final workoutDates = _getWorkoutDatesForWeek(workoutDays);
          for (final date in workoutDates) {
            final workout = _findWorkoutForDate(mergedWorkouts, date);
            if (workout != null) {
              carouselItems.add(CarouselItem.workout(workout));
            } else {
              final isThisDateAutoGenerating = isAutoGenerating &&
                  autoGeneratingDate != null && date == autoGeneratingDate;
              final isThisDateFailed = _isGenerationFailed(date);
              carouselItems.add(CarouselItem.placeholder(
                date,
                isAutoGenerating: isThisDateAutoGenerating,
                isGenerationFailed: isThisDateFailed,
              ));
            }
          }
        }

        // Notify parent of carousel items (for week strip sync)
        if (widget.onCarouselItemsChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCarouselItemsChanged?.call(carouselItems);
          });
        }

        // Auto-trigger generation for the first placeholder
        // Skip if todayWorkoutProvider already shows isGenerating (prevents duplicate calls)
        // Also skip if todayWorkoutProvider already has a cached workout (prevents re-trigger on tab switch)
        if (!_autoGenerationTriggered && carouselItems.isNotEmpty) {
          final firstItem = carouselItems.first;
          final hasCachedWorkout = todayWorkoutResponse?.todayWorkout != null ||
                                   todayWorkoutResponse?.nextWorkout != null;
          if (firstItem.isPlaceholder && !firstItem.isAutoGenerating &&
              _generatingForDate == null && !isAutoGenerating && !hasCachedWorkout) {
            _autoGenerationTriggered = true;
            debugPrint('🚀 [HeroCarousel] Auto-triggering generation for first placeholder: ${firstItem.placeholderDate}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleGenerateWorkout(firstItem.placeholderDate!);
              }
            });
          }
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
          final isItemGenerating = _generatingForDate == item.placeholderDate || item.isAutoGenerating;
          return SizedBox(
            height: HeroWorkoutCarousel.cardHeight,
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
                      isGenerating: isItemGenerating,
                      isGenerationFailed: item.isGenerationFailed,
                      generationStep: isItemGenerating ? _generationStep : 0,
                      generationTotalSteps: _generationTotalSteps,
                      generationMessage: isItemGenerating ? _generationMessage : null,
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
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final item = carouselItems[index];

              // Scale down and slightly dim non-active cards
              final isActive = index == _currentPage;
              final scale = isActive ? 1.0 : 0.92;
              final opacity = isActive ? 1.0 : 0.8;
              final isItemGenerating = _generatingForDate == item.placeholderDate || item.isAutoGenerating;

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
                          isGenerating: isItemGenerating,
                          isGenerationFailed: item.isGenerationFailed,
                          generationStep: isItemGenerating ? _generationStep : 0,
                          generationTotalSteps: _generationTotalSteps,
                          generationMessage: isItemGenerating ? _generationMessage : null,
                        ),
                ),
              );
            },
          ),
        );
      },
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
