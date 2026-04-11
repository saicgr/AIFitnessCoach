part of 'workout_repository.dart';

// ===========================================================================
// WorkoutsNotifier - State management for workout list
// ===========================================================================

/// Workouts state notifier
class WorkoutsNotifier extends StateNotifier<AsyncValue<List<Workout>>> {
  final WorkoutRepository _repository;
  final ApiClient _apiClient;
  final String? _userId;

  WorkoutsNotifier(this._repository, this._apiClient, this._userId)
      : super(
          // Start with in-memory cache if available (instant, no loading flash)
          _workoutsInMemoryCache != null
              ? AsyncValue.data(_workoutsInMemoryCache!)
              : const AsyncValue.loading(),
        ) {
    // If we have in-memory cache, fetch fresh data silently in background
    if (_workoutsInMemoryCache != null) {
      debugPrint('⚡ [Workouts] Using in-memory cache (instant)');
      _initSilent();
    } else {
      _init();
    }
  }

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _workoutsInMemoryCache = null;
    debugPrint('🧹 [Workouts] In-memory cache cleared');
  }

  /// Replace a superseded workout in the in-memory cache so that
  /// provider recreation (after invalidate) immediately shows the new version
  /// instead of stale data while the background fetch completes.
  static void replaceInCache(String oldWorkoutId, Workout newWorkout) {
    if (_workoutsInMemoryCache != null) {
      _workoutsInMemoryCache = _workoutsInMemoryCache!
          .where((w) => w.id != oldWorkoutId)
          .toList()
        ..add(newWorkout);
      debugPrint('⚡ [Workouts] Cache updated: replaced $oldWorkoutId with ${newWorkout.id}');
    }
  }

  /// Initialize silently (when we already have cached data)
  Future<void> _initSilent() async {
    final userId = _userId ?? await _apiClient.getUserId();
    if (!mounted || userId == null || userId.isEmpty) return;
    await _fetchWorkoutsSilent(userId);
  }

  /// Fetch workouts without showing loading state
  Future<void> _fetchWorkoutsSilent(String userId) async {
    try {
      final workouts = await _repository.getWorkouts(userId, allowMultiplePerDate: true);
      if (!mounted) return;
      workouts.sort((a, b) {
        final dateA = a.scheduledDate ?? '';
        final dateB = b.scheduledDate ?? '';
        return dateA.compareTo(dateB);
      });
      // Update in-memory cache
      _workoutsInMemoryCache = workouts;
      state = AsyncValue.data(workouts);
    } catch (e) {
      debugPrint('⚠️ [Workouts] Silent fetch error: $e');
      // Keep existing cached data on error
    }
  }

  Future<void> _init() async {
    // Use userId from authStateProvider (passed from provider)
    if (_userId != null && _userId.isNotEmpty) {
      debugPrint('🏋️ [Workouts] _init() with userId from authState: $_userId');
      await fetchWorkouts(_userId);
    } else {
      // Fallback to apiClient.getUserId() for backwards compatibility
      final userId = await _apiClient.getUserId();
      if (!mounted) return; // Check mounted after async
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🏋️ [Workouts] _init() with userId from apiClient: $userId');
        await fetchWorkouts(userId);
      } else {
        debugPrint('🏋️ [Workouts] _init() - no userId available');
        state = const AsyncValue.data([]);
      }
    }
  }

  /// Fetch workouts for user
  Future<void> fetchWorkouts(String userId) async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final workouts = await _repository.getWorkouts(userId, allowMultiplePerDate: true);
      if (!mounted) return; // Check mounted after async
      // Sort by scheduled date
      workouts.sort((a, b) {
        final dateA = a.scheduledDate ?? '';
        final dateB = b.scheduledDate ?? '';
        return dateA.compareTo(dateB);
      });
      // Update in-memory cache for instant access on provider recreation
      _workoutsInMemoryCache = workouts;
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      if (!mounted) return; // Check mounted after async
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh workouts
  Future<void> refresh() async {
    if (!mounted) return;
    debugPrint('🏋️ [Workouts] refresh() called');
    // Use userId from authStateProvider (passed from provider) first
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      // Fallback to apiClient.getUserId() for backwards compatibility
      userId = await _apiClient.getUserId();
    }
    if (!mounted) return; // Check mounted after async
    if (userId != null && userId.isNotEmpty) {
      debugPrint('🏋️ [Workouts] Fetching workouts for user: $userId');
      await fetchWorkouts(userId);
      if (!mounted) return; // Check mounted after async
      final currentWorkouts = state.valueOrNull ?? [];
      debugPrint('🏋️ [Workouts] After refresh: ${currentWorkouts.length} workouts');
      final nextWorkoutName = nextWorkout?.name;
      debugPrint('🏋️ [Workouts] Next workout: $nextWorkoutName');
    } else {
      debugPrint('🏋️ [Workouts] refresh() - no userId available');
    }
  }

  /// Check if user needs more workouts and trigger generation if needed
  /// This should be called on home screen load to ensure continuous workout availability
  /// Uses a 10-day threshold - will generate if user has less than 10 days of workouts
  Future<Map<String, dynamic>> checkAndRegenerateIfNeeded() async {
    // Use userId from authStateProvider (passed from provider) first
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      // Fallback to apiClient.getUserId() for backwards compatibility
      userId = await _apiClient.getUserId();
    }
    if (userId == null || userId.isEmpty) {
      return {'success': false, 'message': 'No user ID'};
    }

    // Use 10-day threshold so we proactively generate more workouts
    // This ensures users who onboard with 1 week get more workouts generated
    final result = await _repository.checkAndRegenerateWorkouts(userId, thresholdDays: 10);

    // If generation was triggered, set up a delayed refresh to fetch new workouts
    if (result['needs_generation'] == true && result['success'] == true) {
      // Refresh workouts after a delay to allow background generation to complete
      Future.delayed(const Duration(seconds: 30), () async {
        await refresh();
      });
    }

    return result;
  }

  /// Get next workout (closest upcoming incomplete)
  Workout? get nextWorkout {
    final workouts = state.valueOrNull ?? [];
    final today = Tz.localDate();

    final upcoming = workouts.where((w) {
      final date = w.scheduledDate?.split('T')[0] ?? '';
      return !w.isCompleted! && date.compareTo(today) >= 0;
    }).toList();

    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  /// Get upcoming workouts (excluding next)
  List<Workout> get upcomingWorkouts {
    final workouts = state.valueOrNull ?? [];
    final today = Tz.localDate();
    final next = nextWorkout;

    return workouts.where((w) {
      final date = w.scheduledDate?.split('T')[0] ?? '';
      return !w.isCompleted! && date.compareTo(today) >= 0 && w.id != next?.id;
    }).take(5).toList();
  }

  /// Get completed workouts count
  int get completedCount {
    final workouts = state.valueOrNull ?? [];
    return workouts.where((w) => w.isCompleted == true).length;
  }

  /// Get total workout duration formatted as a string
  String get totalDurationFormatted {
    final workouts = state.valueOrNull ?? [];
    final totalMinutes = workouts
        .where((w) => w.isCompleted == true)
        .fold<int>(0, (sum, w) => sum + (w.durationMinutes ?? 0));
    if (totalMinutes >= 60) {
      final hours = totalMinutes / 60;
      return '${hours.toStringAsFixed(1)}h';
    }
    return '${totalMinutes}m';
  }

  /// Get this week's progress
  (int completed, int total) get weeklyProgress {
    final workouts = state.valueOrNull ?? [];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final thisWeek = workouts.where((w) {
      final date = w.scheduledLocalDate;
      if (date == null) return false;
      return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          date.isBefore(weekEnd);
    }).toList();

    final completed = thisWeek.where((w) => w.isCompleted == true).length;
    return (completed, thisWeek.length);
  }

  /// Get current workout streak (consecutive days with completed workouts)
  int get currentStreak {
    final workouts = state.valueOrNull ?? [];
    if (workouts.isEmpty) return 0;

    // Get completed workouts sorted by date (most recent first)
    final completedWorkouts = workouts
        .where((w) => w.isCompleted == true && w.scheduledDate != null)
        .toList();

    if (completedWorkouts.isEmpty) return 0;

    // Sort by date descending
    completedWorkouts.sort((a, b) {
      final dateA = DateTime.tryParse(a.scheduledDate!) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.scheduledDate!) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    // Get unique dates of completed workouts
    final completedDates = <DateTime>{};
    for (final workout in completedWorkouts) {
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date != null) {
        completedDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;

    // Check if streak includes today or yesterday
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterdayNormalized = todayNormalized.subtract(const Duration(days: 1));

    // Streak must start from today or yesterday to be active
    if (sortedDates.first != todayNormalized && sortedDates.first != yesterdayNormalized) {
      return 0;
    }

    // Count consecutive days
    int streak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Log user-created supersets when workout completes (for analytics)
  ///
  /// [workoutId] The workout ID
  /// [userId] The user ID
  /// [exercises] List of workout exercises
  Future<void> logUserSupersets({
    required String workoutId,
    required String userId,
    required List<WorkoutExercise> exercises,
  }) async {
    try {
      // Find all superset pairs
      final supersetGroups = <int, List<WorkoutExercise>>{};
      for (final ex in exercises) {
        if (ex.isInSuperset) {
          supersetGroups.putIfAbsent(ex.supersetGroup!, () => []).add(ex);
        }
      }

      if (supersetGroups.isEmpty) {
        debugPrint('🔗 [Superset] No supersets to log for workout $workoutId');
        return;
      }

      debugPrint('🔗 [Superset] Logging ${supersetGroups.length} superset pairs');

      // Insert each pair to the analytics table
      for (final entry in supersetGroups.entries) {
        final pair = entry.value;
        if (pair.length == 2) {
          final first = pair.firstWhere((e) => e.isSupersetFirst, orElse: () => pair.first);
          final second = pair.firstWhere((e) => e.isSupersetSecond, orElse: () => pair.last);

          await _apiClient.post(
            '/supersets/logs',
            data: {
              'user_id': userId,
              'workout_id': workoutId,
              'exercise_1_name': first.name,
              'exercise_2_name': second.name,
              'exercise_1_muscle': first.primaryMuscle,
              'exercise_2_muscle': second.primaryMuscle,
              'superset_group': entry.key,
            },
          );
          debugPrint('✅ [Superset] Logged: ${first.name} + ${second.name}');
        }
      }
    } catch (e) {
      // Don't fail workout completion if logging fails
      debugPrint('⚠️ [Superset] Failed to log supersets: $e');
    }
  }

  /// Generate a workout for a specific date
  /// This is used when the user taps a placeholder card in the carousel
  Future<Workout?> generateWorkoutForDate(DateTime date, {bool? skipComeback}) async {
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      userId = await _apiClient.getUserId();
    }
    if (userId == null || userId.isEmpty) {
      debugPrint('❌ [Workouts] Cannot generate workout: no userId');
      return null;
    }

    final scheduledDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    debugPrint('🏋️ [Workouts] Generating workout for date: $scheduledDate');

    try {
      Workout? generatedWorkout;
      await for (final progress in _repository.generateWorkoutStreaming(
        userId: userId,
        scheduledDate: scheduledDate,
        skipComeback: skipComeback,
      )) {
        if (progress.status == WorkoutGenerationStatus.completed && progress.workout != null) {
          generatedWorkout = progress.workout;
          debugPrint('✅ [Workouts] Generated workout: ${generatedWorkout?.name}');
        } else if (progress.status == WorkoutGenerationStatus.error) {
          debugPrint('❌ [Workouts] Generation error: ${progress.message}');
        }
      }

      // Refresh workouts list to include the new workout
      if (generatedWorkout != null) {
        await refresh();
      }
      return generatedWorkout;
    } catch (e) {
      debugPrint('❌ [Workouts] Error generating workout for date: $e');
      return null;
    }
  }
}
