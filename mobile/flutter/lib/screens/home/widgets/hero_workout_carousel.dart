import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_start_provider.dart';
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

  /// Optional key for app tour spotlight targeting
  final GlobalKey? carouselKey;

  /// Shared card height constant
  static const double cardHeight = 360;

  const HeroWorkoutCarousel({
    super.key,
    this.externalPageController,
    this.onCarouselItemsChanged,
    this.onPageChanged,
    this.carouselKey,
  });

  /// Reset auto-generation flag (call on pull-to-refresh, regeneration, or logout)
  static void resetAutoGeneration() {
    _HeroWorkoutCarouselState.resetAutoGeneration();
  }

  /// Get workout dates for this week (including past days for missed workout viewing).
  /// Uses [weekConfig] to respect the user's Sunday/Monday week-start preference.
  static List<DateTime> getWorkoutDatesForWeek(List<int> workoutDays, WeekDisplayConfig weekConfig) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = weekConfig.dateForDataIndex(weekStart, day);
      dates.add(thisWeekDate);
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
  bool _hasScrolledToInitial = false;
  int _lastCompletedCount = -1; // Track completed count to auto-scroll on new completions

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

  /// Pick the default-focused carousel card in priority order. Treats
  /// `isCompleted == null` as actionable (freshly-generated, never-attempted
  /// workouts have null state — the old `== false` check silently skipped them).
  /// Priority: today's real workout → today's placeholder → next future →
  /// any placeholder → index 0. A real workout on today (including rescheduled
  /// "Do this today" ones on non-preferred days) always wins over a preferred-day
  /// placeholder that sits on the same date.
  int _pickInitialIndex(List<CarouselItem> items, DateTime today) {
    int? todayWorkoutIdx, todayPlaceholderIdx, futureIdx, placeholderIdx;
    final todayKey = _dateKey(today);
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final actionable = item.isPlaceholder ||
          (item.isWorkout && item.workout!.isCompleted != true);
      if (!actionable) continue;
      final d = item.date;
      final isToday = d != null && _dateKey(d) == todayKey;
      if (isToday && item.isWorkout) {
        todayWorkoutIdx ??= i;
      } else if (isToday && item.isPlaceholder) {
        todayPlaceholderIdx ??= i;
      } else if (d != null && d.isAfter(today)) {
        futureIdx ??= i;
      } else if (item.isPlaceholder) {
        placeholderIdx ??= i;
      }
    }
    return todayWorkoutIdx ??
        todayPlaceholderIdx ??
        futureIdx ??
        placeholderIdx ??
        0;
  }

  /// Get workout dates for this week (including past days for missed workout viewing).
  /// Uses [weekConfig] to respect the user's Sunday/Monday week-start preference.
  /// Past dates are included so users can tap missed dates in the week strip
  /// and see the missed workout in the carousel.
  List<DateTime> _getWorkoutDatesForWeek(List<int> workoutDays, WeekDisplayConfig weekConfig) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    final dates = <DateTime>[];
    for (final day in workoutDays) {
      final thisWeekDate = weekConfig.dateForDataIndex(weekStart, day);
      dates.add(thisWeekDate);
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

    // Cache-first paint: if we have ANY cached user + today workout, paint
    // the card immediately and let background refresh update silently.
    // Only show the full skeleton when there's truly nothing to render.
    final cachedUser = userAsync.valueOrNull;
    final cachedToday = todayWorkoutAsync.valueOrNull;

    // Show skeleton only when we have no cached data at all AND are loading.
    if (cachedUser == null && userAsync.isLoading) {
      return KeyedSubtree(
        key: widget.carouselKey,
        child: _buildLoadingState(isDark, accentColor),
      );
    }
    if (userAsync.hasError && cachedUser == null) {
      return KeyedSubtree(
        key: widget.carouselKey,
        child: _buildErrorState(isDark),
      );
    }

    return KeyedSubtree(
      key: widget.carouselKey,
      child: Builder(builder: (context) {
        final user = cachedUser;
        if (user == null) {
          return _buildNoWorkoutDaysState(isDark, accentColor);
        }

        final workoutDays = user.workoutDays;

        // If today workout hasn't resolved yet AND we have no cached value,
        // show skeleton. Otherwise paint the card with whatever we have.
        if (todayWorkoutAsync.isLoading && cachedToday == null) {
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
        mergedWorkouts.removeWhere((w) => w.generationMethod == 'health_connect_import');

        // Safety net: deduplicate by scheduled_date — keep only the newest
        // non-quick workout per date. Quick workouts intentionally coexist.
        {
          final dateGroups = <String, List<Workout>>{};
          for (final w in mergedWorkouts) {
            if (w.scheduledDate == null) continue;
            final dateKey = w.scheduledDate!.length >= 10
                ? w.scheduledDate!.substring(0, 10)
                : w.scheduledDate!;
            dateGroups.putIfAbsent(dateKey, () => []).add(w);
          }
          final idsToRemove = <String>{};
          for (final entry in dateGroups.entries) {
            final workouts = entry.value;
            if (workouts.length <= 1) continue;
            // Separate quick workouts from scheduled ones
            final scheduled = workouts.where((w) => w.generationMethod != 'quick_workout').toList();
            if (scheduled.length <= 1) continue;
            // Keep the newest scheduled workout, remove the rest
            scheduled.sort((a, b) {
              final aDate = a.createdAt ?? '';
              final bDate = b.createdAt ?? '';
              return bDate.compareTo(aDate); // newest first
            });
            for (int i = 1; i < scheduled.length; i++) {
              if (scheduled[i].id != null) {
                idsToRemove.add(scheduled[i].id!);
              }
            }
          }
          if (idsToRemove.isNotEmpty) {
            mergedWorkouts.removeWhere((w) => w.id != null && idsToRemove.contains(w.id));
          }
        }

        // Build carousel items: one per workout day (workout card or pending card)
        // Multiple workouts on the same day each get their own carousel card.
        List<CarouselItem> carouselItems = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (workoutDays.isNotEmpty) {
          final weekConfig = ref.watch(weekDisplayConfigProvider);
          final workoutDates = _getWorkoutDatesForWeek(workoutDays, weekConfig);
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
            } else if (!date.isBefore(today)) {
              // Only show placeholders for today/future dates — can't generate for past dates
              final isGeneratingForDate = todayWorkoutResponse?.isGenerating == true;
              carouselItems.add(CarouselItem.placeholder(date, isAutoGenerating: isGeneratingForDate));
            }
            // Past dates with no workout are simply skipped (no card to show)
          }

          // Handle workouts on non-workout days (staple-only workouts, quick workouts)
          // Check all days this week for workouts that exist in DB but aren't workout days
          final workoutDateKeys = workoutDates.map(_dateKey).toSet();

          // Scan ONLY remaining days in the current display week for non-workout-day workouts
          final weekEnd = weekConfig.weekStart(today).add(const Duration(days: 6));
          for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
            final checkDate = today.add(Duration(days: dayOffset));
            if (checkDate.isAfter(weekEnd)) break; // Don't spill into next week
            final checkKey = _dateKey(checkDate);
            if (workoutDateKeys.contains(checkKey)) continue; // Already handled

            final restDayWorkouts = _findAllWorkoutsForDate(mergedWorkouts, checkDate);
            for (final workout in restDayWorkouts) {
              final wId = workout.id ?? '';
              if (wId.isNotEmpty && addedWorkoutIds.add(wId)) {
                // Insert in chronological order
                int insertIdx = carouselItems.length;
                for (int i = 0; i < carouselItems.length; i++) {
                  final itemDate = carouselItems[i].date;
                  if (itemDate != null && checkDate.isBefore(itemDate)) {
                    insertIdx = i;
                    break;
                  }
                }
                carouselItems.insert(insertIdx, CarouselItem.workout(workout));
              }
            }
          }
        }

        // Always surface the next scheduled workout — even when it's beyond
        // the current display week — so the carousel never dead-ends on a
        // "No workout yet" placeholder for users whose next session is in a
        // future week (e.g. 1 workout/week schedules). Mirrors the Workouts
        // tab's "NEXT WEEK'S WORKOUT" behavior.
        if (nextWorkout != null && nextWorkout.id != null) {
          final already = carouselItems.any(
            (i) => i.isWorkout && i.workout?.id == nextWorkout.id,
          );
          if (!already) {
            carouselItems.add(CarouselItem.workout(nextWorkout));
          }
        }

        // Pick the actionable target on first data load + auto-scroll to it.
        // Carousel starts at index 0 (earliest, usually the missed card if
        // present) so users see what they missed, then the animation reveals
        // today's / next workout. Feels intentional, not magic.
        if (!_hasScrolledToInitial && carouselItems.length > 1) {
          _hasScrolledToInitial = true;
          final targetIndex = _pickInitialIndex(carouselItems, today);
          _currentPage = 0;

          if (targetIndex != 0) {
            // Dwell briefly on the first (likely missed) card, then slide to
            // the actionable target. Reuses the same tween vocabulary as the
            // on-completion auto-scroll below.
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Future.delayed(const Duration(milliseconds: 800));
              if (!mounted || !_pageController.hasClients) return;
              await _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
              );
              if (mounted) widget.onPageChanged?.call(targetIndex);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onPageChanged?.call(0);
            });
          }
        }

        // Auto-scroll to next actionable (today/future) workout when a workout is newly completed
        final completedCount = carouselItems.where((item) => item.isWorkout && item.workout!.isCompleted == true).length;
        if (_hasScrolledToInitial && _lastCompletedCount >= 0 && completedCount > _lastCompletedCount && carouselItems.length > 1) {
          int targetIndex = 0;
          bool found = false;
          for (int i = 0; i < carouselItems.length; i++) {
            final item = carouselItems[i];
            if (item.isPlaceholder) {
              targetIndex = i;
              found = true;
              break;
            }
            if (item.isWorkout && item.workout!.isCompleted != true) {
              final itemDate = item.date;
              if (itemDate != null && !itemDate.isBefore(today)) {
                targetIndex = i;
                found = true;
                break;
              }
            }
          }
          if (!found) targetIndex = carouselItems.length - 1;
          if (targetIndex != _currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
        _lastCompletedCount = completedCount;

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
                  ? HeroWorkoutCard(workout: item.workout!, inCarousel: true)
                  : _buildPendingCard(item.placeholderDate!, isDark, accentColor, isAutoGenerating: item.isAutoGenerating),
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
                      : _buildPendingCard(item.placeholderDate!, isDark, accentColor, isAutoGenerating: item.isAutoGenerating),
                ),
              );
            },
          ),
        );
      },
    ),
    );
  }

  /// Minimal card for workout days that don't have a generated workout yet.
  Widget _buildPendingCard(DateTime date, bool isDark, Color accentColor, {bool isAutoGenerating = false}) {
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
            if (isAutoGenerating)
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
              )
            else
              Text(
                'No workout yet',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutDaysState(bool isDark, Color accentColor) {
    return GestureDetector(
      onTap: () {
        context.push('/settings/workout-settings');
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tap to set up in Settings', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black45)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
                ],
              ),
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
              color: accentColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Setting up your workout...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
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
