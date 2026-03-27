import 'dart:async';
import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'dart:math' show min, pow;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/wearable_provider.dart';
import '../repositories/workout_repository.dart';
import '../services/data_cache_service.dart';
import '../services/wearable_service.dart';

/// Tracks poll count for exponential backoff
/// Prevents excessive API calls when generation is failing
int _generationPollCount = 0;

/// Maximum number of polls before giving up
/// ~2 minutes with exponential backoff: 2s, 4s, 8s, 16s, 30s, 30s...
const int _maxGenerationPolls = 30;

/// Calculate backoff seconds with exponential growth, capped at 30s
int _getBackoffSeconds() {
  // 2s, 4s, 8s, 16s, 30s (capped)
  return min(30, 2 * pow(2, min(_generationPollCount, 4)).toInt());
}

/// In-memory cache for instant display on provider recreation
/// This survives provider invalidation and prevents loading flash
TodayWorkoutResponse? _inMemoryCache;

/// Provider for today's workout data with cache-first pattern
///
/// Features:
/// - Cache-first: Shows cached data instantly, fetches fresh in background
/// - In-memory cache: Survives provider invalidation, prevents loading flash
/// - Silent updates: UI updates automatically when fresh data arrives
/// - Auto-polls when is_generating is true (JIT generation in progress)
/// - Exponential backoff to prevent excessive API calls
/// - Auto-syncs to WearOS watch when workout is available (Android only)
final todayWorkoutProvider =
    StateNotifierProvider<TodayWorkoutNotifier, AsyncValue<TodayWorkoutResponse?>>((ref) {
  return TodayWorkoutNotifier(ref);
});

/// State notifier for today's workout with cache-first pattern
class TodayWorkoutNotifier extends StateNotifier<AsyncValue<TodayWorkoutResponse?>> {
  final Ref _ref;
  Timer? _pollingTimer;
  Timer? _backgroundGenPollTimer;
  Timer? _backgroundGenTimeout;
  bool _isRefreshing = false;
  bool _disposed = false;

  /// STATIC: Tracks if auto-generation is in progress
  /// Static so it survives provider invalidation (prevents duplicate /generate-stream calls)
  static bool _isAutoGenerating = false;

  /// STATIC: Tracks if generation has already been triggered for current cycle
  /// Prevents poll-triggered re-generation (every 15s poll re-calling /generate-stream)
  static bool _hasTriggeredGeneration = false;

  /// STATIC: Cooldown tracking for failed generation attempts
  /// Static so it survives provider invalidation (prevents 429 spam after failure)
  static DateTime? _lastGenerationFailure;
  static const Duration _generationCooldown = Duration(seconds: 30);

  /// STATIC: Tracks if generation timed out — prevents auto-re-trigger loop
  /// When true, the "Generate Workout" button is shown instead of auto-triggering
  static bool _generationTimedOut = false;

  TodayWorkoutNotifier(this._ref)
      : super(
          // Start with in-memory cache if available (instant, no loading flash)
          // Otherwise start with loading state
          _inMemoryCache != null
              ? AsyncValue.data(_inMemoryCache)
              : const AsyncValue.loading(),
        ) {
    // Only load if we don't have in-memory cache
    // This prevents unnecessary loading state when provider is invalidated
    if (_inMemoryCache != null) {
      debugPrint('⚡ [TodayWorkout] Using in-memory cache (instant)');
      // Still fetch fresh data in background silently
      _fetchFromApi(showLoading: false);
    } else {
      // No in-memory cache — try persistent cache first (shows stale data instantly
      // instead of a loading spinner, then silently refreshes from API).
      // This is especially important after cold app start (e.g. opening app in morning)
      // where the Render backend may take 10-30s to warm up.
      _loadWithCacheFirst();
    }
  }

  /// Safely update state only if not disposed
  void _safeSetState(AsyncValue<TodayWorkoutResponse?> newState) {
    if (!_disposed && mounted) {
      state = newState;
    }
  }

  /// Load data with cache-first pattern:
  /// 1. Load from cache instantly (no loading state)
  /// 2. Fetch from API in background
  /// 3. Update state silently when API returns
  Future<void> _loadWithCacheFirst() async {
    // Step 1: Try to load from cache first
    final cachedData = await _loadFromCache();
    if (cachedData != null) {
      debugPrint('⚡ [TodayWorkout] Loaded from cache instantly');
      _safeSetState(AsyncValue.data(cachedData));
    }

    // Step 2: Fetch fresh data from API in background
    await _fetchFromApi(showLoading: cachedData == null);
  }

  /// Load cached workout data from persistent storage
  /// Also updates in-memory cache for future instant access
  Future<TodayWorkoutResponse?> _loadFromCache() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.todayWorkoutKey,
      );
      if (cached != null) {
        final response = TodayWorkoutResponse.fromJson(cached);
        // Update in-memory cache for instant access on provider recreation
        _inMemoryCache = response;
        return response;
      }
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] Cache parse error: $e');
    }
    return null;
  }

  /// Save workout data to cache (both in-memory and persistent)
  Future<void> _saveToCache(TodayWorkoutResponse response) async {
    // Don't cache if workout is generating (transient state)
    if (response.isGenerating) return;

    // Update in-memory cache FIRST (instant for next provider recreation)
    _inMemoryCache = response;

    try {
      await DataCacheService.instance.cache(
        DataCacheService.todayWorkoutKey,
        response.toJson(),
      );
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] Cache save error: $e');
    }
  }

  /// Fetch fresh data from API
  Future<void> _fetchFromApi({bool showLoading = false}) async {
    if (_isRefreshing || _disposed) return;
    _isRefreshing = true;

    try {
      if (showLoading) {
        _safeSetState(const AsyncValue.loading());
      }

      // Early exit if disposed during async gap
      if (_disposed) return;

      final repository = _ref.read(workoutRepositoryProvider);
      var response = await repository.getTodayWorkout();

      // Handle generation polling (skip if background gen poll is already active to avoid dual timers)
      if (response?.isGenerating == true && _backgroundGenPollTimer == null) {
        _handleGenerationPolling();
      } else if (response?.isGenerating != true) {
        _cancelPolling();
        if (_generationPollCount > 0) {
          debugPrint('✅ [Generation] Complete after $_generationPollCount polls');
        }
        _generationPollCount = 0;
      }

      // Handle auto-generation trigger
      if (response?.needsGeneration == true && response?.nextWorkoutDate != null) {
        final hasAnyWorkout = response!.todayWorkout != null || response.nextWorkout != null;

        if (!hasAnyWorkout && !_hasTriggeredGeneration && !_generationTimedOut) {
          // No workouts at all - show generating UI and trigger streaming gen
          // Only trigger ONCE per cycle to prevent poll-triggered re-generation spam
          debugPrint('🚀 [Auto-Gen] No workouts exist, triggering generation for date=${response.nextWorkoutDate} (profile=${response.gymProfileId})');
          _hasTriggeredGeneration = true;
          _triggerAutoGeneration(response.nextWorkoutDate!, gymProfileId: response.gymProfileId);
          _startBackgroundGenerationPolling();

          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: true,
            generationMessage: 'Generating your workout...',
            needsGeneration: false,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else if (!hasAnyWorkout && _hasTriggeredGeneration && !_generationTimedOut) {
          // Already triggered generation - just show generating UI without re-triggering
          debugPrint('⏳ [Auto-Gen] Generation already triggered, waiting for completion');
          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: true,
            generationMessage: 'Generating your workout...',
            needsGeneration: false,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else if (!hasAnyWorkout && _generationTimedOut) {
          // Generation timed out — don't auto-trigger, let user see Generate button
          debugPrint('⏰ [Auto-Gen] Generation timed out previously, showing manual generate button');
          // Let the response pass through as-is (needsGeneration=true, isGenerating=false)
          // The UI will show the GenerateWorkoutPlaceholder with "GENERATE WORKOUT" button
        } else {
          // Workouts exist - backend background tasks handle remaining dates silently
          debugPrint('✅ [Auto-Gen] Workouts already exist, letting backend handle remaining generation silently');
        }
      }

      // Normalize: guarantee isGenerating=false when displayable content exists.
      // This is the canonical fix — all UI code can trust isGenerating without
      // also needing to check for existing workouts. Fixes the caching bug too
      // (_saveToCache skips when isGenerating=true, losing valid workout data).
      //
      // Safety: if the workout is a generation placeholder (name="Generating...",
      // 0 exercises), do NOT treat it as real content — let isGenerating stay true
      // so polling continues until the real workout is ready.
      if (response != null && response.hasDisplayableContent && response.isGenerating) {
        final isPlaceholder = response.todayWorkout?.name == 'Generating...' &&
            (response.todayWorkout?.exerciseCount ?? 0) == 0;
        if (!isPlaceholder) {
          debugPrint('🔄 [TodayWorkout] Normalized: cleared isGenerating (real content exists)');
          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: false,
            generationMessage: null,
            needsGeneration: response.needsGeneration,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else {
          debugPrint('⚠️ [TodayWorkout] Placeholder workout detected, keeping isGenerating=true');
        }
      }

      // Handle empty state polling
      if (response?.todayWorkout == null &&
          response?.nextWorkout == null &&
          response?.completedToday != true &&
          response?.isGenerating != true &&
          response?.needsGeneration != true) {
        _scheduleEmptyStateRefresh();
      }

      // Sync to watch (Android only)
      if (Platform.isAndroid && response?.todayWorkout != null && !response!.isGenerating) {
        _syncWorkoutToWatch(response.todayWorkout!);
      }

      // Update state with fresh data (only if not disposed)
      if (!_disposed) {
        _safeSetState(AsyncValue.data(response));
      }

      // Save to cache for next app open
      if (response != null) {
        await _saveToCache(response);
      }
    } catch (e, stack) {
      debugPrint('❌ [TodayWorkout] API error: $e');
      // Only set error state if we don't have cached data and not disposed
      if (!_disposed && !state.hasValue) {
        _safeSetState(AsyncValue.error(e, stack));
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle generation polling with exponential backoff
  void _handleGenerationPolling() {
    if (_disposed) return;

    if (_generationPollCount < _maxGenerationPolls) {
      _generationPollCount++;
      final backoffSeconds = _getBackoffSeconds();
      debugPrint('🔄 [Generation] Poll #$_generationPollCount, next in ${backoffSeconds}s');

      _pollingTimer?.cancel();
      _pollingTimer = Timer(Duration(seconds: backoffSeconds), () {
        if (!_disposed) {
          _fetchFromApi();
        }
      });
    } else {
      debugPrint('❌ [Generation] Max polls ($_maxGenerationPolls) reached. Stopping auto-refresh.');
      _generationPollCount = 0;
    }
  }

  /// Cancel any active polling
  void _cancelPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Schedule refresh for empty state
  void _scheduleEmptyStateRefresh() {
    if (_disposed) return;

    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) {
        _fetchFromApi();
      }
    });
  }

  /// Start polling for background-generated workout (Fix 2)
  ///
  /// When the backend signals needs_generation=true, it also starts generating
  /// the workout in a background task. This method polls every 5 seconds until
  /// the workout appears, with a 2-minute safety timeout.
  void _startBackgroundGenerationPolling() {
    if (_disposed) return;

    // Cancel any existing poll timers (including generation polling to avoid dual timers)
    _backgroundGenPollTimer?.cancel();
    _backgroundGenTimeout?.cancel();
    _cancelPolling();

    debugPrint('[TodayWorkout] Starting background generation polling (every 15s, 3min timeout)');

    _backgroundGenPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_disposed) {
        _backgroundGenPollTimer?.cancel();
        return;
      }

      debugPrint('[TodayWorkout] Background gen poll: checking for generated workout...');

      // Directly fetch from the API (bypass the auto-generation logic by checking result)
      try {
        final repository = _ref.read(workoutRepositoryProvider);
        final response = await repository.getTodayWorkout();

        if (response != null && !_disposed) {
          final hasWorkout = response.todayWorkout != null || response.nextWorkout != null;
          if (hasWorkout) {
            // Backend generated the workout! Show it immediately.
            debugPrint('✅ [TodayWorkout] Backend generated workout, displaying');
            _stopBackgroundGenerationPolling();
            _hasTriggeredGeneration = false;
            _generationTimedOut = false;
            _safeSetState(AsyncValue.data(response));
            await _saveToCache(response);
          }
          // If no workout yet, the streaming auto-retry is still running — just wait
        }
      } catch (e) {
        debugPrint('⚠️ [TodayWorkout] Poll error: $e');
      }
    });

    // Safety timeout: 3 minutes gives auto-retry (3 attempts with backoff) time to complete.
    // If STILL no workout after 3 min, clear the spinner so the user isn't stuck.
    _backgroundGenTimeout = Timer(const Duration(minutes: 3), () {
      if (!_disposed) {
        debugPrint('⏰ [TodayWorkout] Background generation timed out (3min), recovering');
        _stopBackgroundGenerationPolling();

        _generationTimedOut = true;
        _hasTriggeredGeneration = false;
        _isAutoGenerating = false;

        // Clear the stuck isGenerating state so the user sees Generate button
        final current = state.valueOrNull;
        if (current != null && current.isGenerating) {
          _safeSetState(AsyncValue.data(TodayWorkoutResponse(
            hasWorkoutToday: current.hasWorkoutToday,
            todayWorkout: current.todayWorkout,
            nextWorkout: current.nextWorkout,
            daysUntilNext: current.daysUntilNext,
            restDayMessage: current.restDayMessage,
            completedToday: current.completedToday,
            completedWorkout: current.completedWorkout,
            extraTodayWorkouts: current.extraTodayWorkouts,
            isGenerating: false,
            generationMessage: null,
            needsGeneration: true,
            nextWorkoutDate: current.nextWorkoutDate,
            gymProfileId: current.gymProfileId,
          )));
        }
      }
    });
  }

  /// Stop background generation polling
  void _stopBackgroundGenerationPolling() {
    _backgroundGenPollTimer?.cancel();
    _backgroundGenPollTimer = null;
    _backgroundGenTimeout?.cancel();
    _backgroundGenTimeout = null;
  }

  /// Public method to force refresh from API
  Future<void> refresh() async {
    await _fetchFromApi(showLoading: false);
  }

  /// Invalidate cache and refresh
  Future<void> invalidateAndRefresh() async {
    // Clear in-memory cache too
    _inMemoryCache = null;
    _hasTriggeredGeneration = false; // Reset so new profile can trigger generation
    _generationTimedOut = false; // Allow auto-generation on fresh start
    await DataCacheService.instance.invalidate(DataCacheService.todayWorkoutKey);
    await _fetchFromApi(showLoading: true);
  }

  /// Reset generation state (called on gym profile switch)
  /// Must be called BEFORE invalidating the provider so the new instance
  /// can trigger generation for the new profile without being blocked by stale flags.
  static void resetGenerationState() {
    _isAutoGenerating = false;
    _hasTriggeredGeneration = false;
    _lastGenerationFailure = null;
    _generationTimedOut = false;
    _inMemoryCache = null;
    debugPrint('🔄 [TodayWorkout] Generation state reset (profile switch)');
  }

  /// Clear all caches (called on logout)
  static void clearCache() {
    _inMemoryCache = null;
    _hasTriggeredGeneration = false;
    _isAutoGenerating = false;
    _generationTimedOut = false;
    debugPrint('🧹 [TodayWorkout] In-memory cache cleared');
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPolling();
    _stopBackgroundGenerationPolling();
    super.dispose();
  }

  // =====================================================
  // Auto-generation and watch sync (same as before)
  // =====================================================

  /// Maximum auto-retry attempts for generation before giving up
  static const int _maxAutoRetries = 3;

  void _triggerAutoGeneration(String scheduledDate, {String? gymProfileId, int attempt = 1}) {
    if (_isAutoGenerating || _disposed) {
      debugPrint('⏳ [Auto-Gen] Already generating or disposed, skipping request');
      return;
    }

    if (attempt > _maxAutoRetries) {
      debugPrint('❌ [Auto-Gen] Max retries ($_maxAutoRetries) exhausted');
      _generationTimedOut = true;
      _hasTriggeredGeneration = false;
      // Clear stuck isGenerating state so user sees Generate button
      final current = state.valueOrNull;
      if (current != null && current.isGenerating) {
        _safeSetState(AsyncValue.data(TodayWorkoutResponse(
          hasWorkoutToday: current.hasWorkoutToday,
          todayWorkout: current.todayWorkout,
          nextWorkout: current.nextWorkout,
          daysUntilNext: current.daysUntilNext,
          restDayMessage: current.restDayMessage,
          completedToday: current.completedToday,
          completedWorkout: current.completedWorkout,
          extraTodayWorkouts: current.extraTodayWorkouts,
          isGenerating: false,
          generationMessage: null,
          needsGeneration: true,
          nextWorkoutDate: current.nextWorkoutDate,
          gymProfileId: current.gymProfileId,
        )));
      }
      return;
    }

    _isAutoGenerating = true;
    _generationTimedOut = false;
    debugPrint('🔄 [Auto-Gen] Attempt $attempt/$_maxAutoRetries for date: $scheduledDate');

    Future(() async {
      try {
        if (_disposed) return;

        final repository = _ref.read(workoutRepositoryProvider);
        final userId = await repository.getCurrentUserId();
        if (userId == null) {
          debugPrint('❌ [Auto-Gen] No user ID available');
          return;
        }

        if (_disposed) return;

        bool completed = false;
        await for (final progress in repository.generateWorkoutStreaming(
          userId: userId,
          scheduledDate: scheduledDate,
          gymProfileId: gymProfileId,
        ).timeout(const Duration(seconds: 120), onTimeout: (sink) {
          debugPrint('⏰ [Auto-Gen] Streaming timed out after 120s (attempt $attempt)');
          sink.close();
        })) {
          if (_disposed) {
            debugPrint('⚠️ [Auto-Gen] Disposed during generation, stopping');
            break;
          }

          debugPrint('🔄 [Auto-Gen] Progress: ${progress.status} - ${progress.message}');

          if (progress.status == WorkoutGenerationStatus.completed) {
            debugPrint('✅ [Auto-Gen] Workout generated successfully!');
            completed = true;
            _lastGenerationFailure = null;
            _hasTriggeredGeneration = false;
            _generationTimedOut = false;
            _stopBackgroundGenerationPolling();
            if (!_disposed) refresh();
            break;
          }

          if (progress.status == WorkoutGenerationStatus.error) {
            debugPrint('❌ [Auto-Gen] Generation error (attempt $attempt): ${progress.message}');
            _lastGenerationFailure = DateTime.now();
            break;
          }
        }

        // If failed, auto-retry after backoff
        if (!completed && !_disposed) {
          debugPrint('⚠️ [Auto-Gen] Attempt $attempt failed, scheduling retry');
          _isAutoGenerating = false;
          // Backoff: 10s, 20s, 30s
          final delaySec = min(30, 10 * attempt);
          Timer(Duration(seconds: delaySec), () {
            if (!_disposed) {
              _triggerAutoGeneration(scheduledDate,
                  gymProfileId: gymProfileId, attempt: attempt + 1);
            }
          });
          return; // Skip the finally _isAutoGenerating=false (already reset above)
        }
      } catch (e) {
        debugPrint('❌ [Auto-Gen] Error (attempt $attempt): $e');
        _lastGenerationFailure = DateTime.now();
        // Auto-retry after backoff
        if (!_disposed && attempt < _maxAutoRetries) {
          _isAutoGenerating = false;
          final delaySec = min(30, 10 * attempt);
          debugPrint('🔄 [Auto-Gen] Retrying in ${delaySec}s...');
          Timer(Duration(seconds: delaySec), () {
            if (!_disposed) {
              _triggerAutoGeneration(scheduledDate,
                  gymProfileId: gymProfileId, attempt: attempt + 1);
            }
          });
          return;
        }
      } finally {
        _isAutoGenerating = false;
      }
    });
  }

  void _syncWorkoutToWatch(TodayWorkoutSummary workout) {
    Future(() async {
      try {
        await _cacheWorkoutForWatch(workout);

        final wearableSync = _ref.read(wearableSyncProvider);
        await wearableSync.refreshConnection();
        if (!wearableSync.isConnected) {
          debugPrint('⌚ [Watch] Not connected, workout cached for later');
          return;
        }

        final watchWorkout = WearableService.instance.createWorkoutForWatch(
          id: workout.id,
          name: workout.name,
          type: workout.type,
          exercises: workout.exercises.map((e) => {
            'id': e.id,
            'name': e.name,
            'targetSets': e.sets,
            'targetReps': e.reps.toString(),
            'targetWeightKg': e.weight,
            'restSeconds': e.restSeconds ?? 60,
            'videoUrl': e.videoUrl,
            'thumbnailUrl': e.gifUrl,
          }).toList(),
          estimatedDuration: workout.durationMinutes,
          targetMuscleGroups: workout.primaryMuscles,
          scheduledDate: workout.scheduledDate,
        );

        await wearableSync.syncWorkoutToWatch(watchWorkout);
      } catch (e) {
        debugPrint('⚠️ [Watch] Error syncing workout: $e');
      }
    });
  }

  Future<void> _cacheWorkoutForWatch(TodayWorkoutSummary workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutData = {
        'workout': {
          'id': workout.id,
          'name': workout.name,
          'type': workout.type,
          'estimated_duration': workout.durationMinutes,
          'target_muscles': workout.primaryMuscles,
          'exercises': workout.exercises.map((e) => {
            'id': e.id,
            'name': e.name,
            'sets': e.sets,
            'reps': e.reps,
            'weight_kg': e.weight,
            'rest_seconds': e.restSeconds ?? 60,
            'video_url': e.videoUrl,
            'thumbnail_url': e.gifUrl,
          }).toList(),
        },
        'date': workout.scheduledDate,
      };

      await prefs.setString('today_workout_cache', jsonEncode(workoutData));
      debugPrint('💾 [Watch] Workout cached for watch sync');
    } catch (e) {
      debugPrint('⚠️ [Watch] Error caching workout: $e');
    }
  }
}

/// Provider to track if the quick start was used
/// This helps with analytics and can be used to show different UI states
final quickStartUsedProvider = StateProvider<bool>((ref) => false);

/// Provider to force refresh of today's workout data
/// Call ref.invalidate(todayWorkoutRefreshProvider) to trigger a refresh
final todayWorkoutRefreshProvider = Provider<void>((ref) {
  // Watching this will trigger refresh
  ref.watch(todayWorkoutProvider);
});
