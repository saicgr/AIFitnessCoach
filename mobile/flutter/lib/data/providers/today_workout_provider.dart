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
  bool _isRefreshing = false;
  bool _disposed = false;

  /// STATIC: Tracks if auto-generation is in progress
  /// Static so it survives provider invalidation (prevents duplicate /generate-stream calls)
  static bool _isAutoGenerating = false;

  /// STATIC: Cooldown tracking for failed generation attempts
  /// Static so it survives provider invalidation (prevents 429 spam after failure)
  static DateTime? _lastGenerationFailure;
  static const Duration _generationCooldown = Duration(seconds: 30);

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

      // Handle generation polling
      if (response?.isGenerating == true) {
        _handleGenerationPolling();
      } else {
        _cancelPolling();
        if (_generationPollCount > 0) {
          debugPrint('✅ [Generation] Complete after $_generationPollCount polls');
        }
        _generationPollCount = 0;
      }

      // Handle auto-generation trigger
      if (response?.needsGeneration == true && response?.nextWorkoutDate != null) {
        debugPrint('🚀 [Auto-Gen] Backend signaled needs_generation=true, date=${response!.nextWorkoutDate}');
        _triggerAutoGeneration(response.nextWorkoutDate!);

        response = TodayWorkoutResponse(
          hasWorkoutToday: response.hasWorkoutToday,
          todayWorkout: response.todayWorkout,
          nextWorkout: response.nextWorkout,
          daysUntilNext: response.daysUntilNext,
          restDayMessage: response.restDayMessage,
          completedToday: response.completedToday,
          completedWorkout: response.completedWorkout,
          isGenerating: true,
          generationMessage: 'Generating your workout...',
          needsGeneration: false,
          nextWorkoutDate: response.nextWorkoutDate,
        );
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

  /// Public method to force refresh from API
  Future<void> refresh() async {
    await _fetchFromApi(showLoading: false);
  }

  /// Invalidate cache and refresh
  Future<void> invalidateAndRefresh() async {
    // Clear in-memory cache too
    _inMemoryCache = null;
    await DataCacheService.instance.invalidate(DataCacheService.todayWorkoutKey);
    await _fetchFromApi(showLoading: true);
  }

  /// Clear all caches (called on logout)
  static void clearCache() {
    _inMemoryCache = null;
    debugPrint('🧹 [TodayWorkout] In-memory cache cleared');
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPolling();
    super.dispose();
  }

  // =====================================================
  // Auto-generation and watch sync (same as before)
  // =====================================================

  void _triggerAutoGeneration(String scheduledDate) {
    if (_isAutoGenerating || _disposed) {
      debugPrint('⏳ [Auto-Gen] Already generating or disposed, skipping request');
      return;
    }

    // Check cooldown after failed generation (prevents 429 spam)
    if (_lastGenerationFailure != null) {
      final timeSinceFailure = DateTime.now().difference(_lastGenerationFailure!);
      if (timeSinceFailure < _generationCooldown) {
        final remaining = _generationCooldown - timeSinceFailure;
        debugPrint('⏳ [Auto-Gen] In cooldown after failure. Wait ${remaining.inSeconds}s before retry');
        return;
      }
    }

    _isAutoGenerating = true;
    debugPrint('🔄 [Auto-Gen] Starting generation for date: $scheduledDate');

    Future(() async {
      try {
        // Check if disposed before making API calls
        if (_disposed) return;

        final repository = _ref.read(workoutRepositoryProvider);
        final userId = await repository.getCurrentUserId();
        if (userId == null) {
          debugPrint('❌ [Auto-Gen] No user ID available');
          return;
        }

        // Check again after async gap
        if (_disposed) return;

        await for (final progress in repository.generateWorkoutStreaming(
          userId: userId,
          scheduledDate: scheduledDate,
        )) {
          // Check if disposed during streaming
          if (_disposed) {
            debugPrint('⚠️ [Auto-Gen] Notifier disposed during generation, stopping');
            break;
          }

          debugPrint('🔄 [Auto-Gen] Progress: ${progress.status} - ${progress.message}');

          if (progress.status == WorkoutGenerationStatus.completed) {
            debugPrint('✅ [Auto-Gen] Workout generated successfully!');
            _lastGenerationFailure = null; // Clear cooldown on success
            if (!_disposed) {
              refresh();
            }
            break;
          }

          if (progress.status == WorkoutGenerationStatus.error) {
            debugPrint('❌ [Auto-Gen] Generation failed: ${progress.message}');
            // Set cooldown to prevent rapid retries (especially on 429 rate limit)
            _lastGenerationFailure = DateTime.now();
            break;
          }
        }
      } catch (e) {
        debugPrint('❌ [Auto-Gen] Error: $e');
        // Set cooldown on error
        _lastGenerationFailure = DateTime.now();
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
            'thumbnailUrl': e.gifUrl ?? e.imageS3Path,
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
            'thumbnail_url': e.gifUrl ?? e.imageS3Path,
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
