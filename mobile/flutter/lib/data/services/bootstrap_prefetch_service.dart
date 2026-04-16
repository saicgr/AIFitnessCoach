import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/today_workout.dart';
import '../providers/today_workout_provider.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/hydration_repository.dart';
import 'api_client.dart';

/// Pre-fetches all home screen data via the /home/bootstrap endpoint
/// during the splash → home transition so the home screen renders instantly.
///
/// Call [prefetch] as a fire-and-forget from the router redirect.
/// It populates in-memory caches so providers start with data, not loading.
class BootstrapPrefetchService {
  static bool _hasPrefetched = false;
  static Future<void>? _activePrefetch;

  /// Fire-and-forget prefetch. Safe to call multiple times (deduped).
  static void prefetch(Ref ref) {
    if (_hasPrefetched || _activePrefetch != null) return;
    _activePrefetch = _doPrefetch(ref).whenComplete(() {
      _activePrefetch = null;
    });
  }

  /// Wait for prefetch to complete (with timeout).
  /// Returns true if data was loaded, false if timed out or failed.
  static Future<bool> waitForPrefetch({Duration timeout = const Duration(seconds: 2)}) async {
    if (_hasPrefetched) return true;
    if (_activePrefetch == null) return false;
    try {
      await _activePrefetch!.timeout(timeout, onTimeout: () {});
      return _hasPrefetched;
    } catch (_) {
      return false;
    }
  }

  /// Reset on logout so next login prefetches fresh data.
  static void reset() {
    _hasPrefetched = false;
    _activePrefetch = null;
  }

  static Future<void> _doPrefetch(Ref ref) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      debugPrint('⚡ [Bootstrap] Prefetching home data...');
      final stopwatch = Stopwatch()..start();

      // Single API call for all home screen data
      // Uses apiClient.get() which handles auth headers and base URL correctly
      final response = await apiClient.get(
        '/home/bootstrap',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode != 200 || response.data == null) return;

      final data = response.data as Map<String, dynamic>;

      // Pre-seed today workout cache
      _preSeedWorkout(data['today_workout']);

      // Pre-seed nutrition data
      _preSeedNutrition(ref, data['nutrition_summary']);

      // Pre-seed hydration data
      _preSeedHydration(ref, data['hydration']);

      _hasPrefetched = true;
      stopwatch.stop();
      debugPrint('⚡ [Bootstrap] Prefetch complete in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Prefetch failed: $e');
    }
  }

  /// Pre-seed today workout from bootstrap workout summary.
  /// The bootstrap WorkoutSummary fields match TodayWorkoutSummary.fromJson() keys.
  static void _preSeedWorkout(dynamic workoutData) {
    try {
      if (workoutData != null) {
        final workoutMap = workoutData as Map<String, dynamic>;
        final isToday = workoutMap['is_today'] == true;
        final summary = TodayWorkoutSummary(
          id: workoutMap['id'] as String? ?? '',
          name: workoutMap['name'] as String? ?? 'Workout',
          type: workoutMap['type'] as String? ?? 'strength',
          difficulty: workoutMap['difficulty'] as String? ?? 'medium',
          durationMinutes: workoutMap['duration_minutes'] as int? ?? 45,
          exerciseCount: workoutMap['exercise_count'] as int? ?? 0,
          primaryMuscles: (workoutMap['primary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
          scheduledDate: workoutMap['scheduled_date'] as String? ?? '',
          isToday: isToday,
          isCompleted: workoutMap['is_completed'] as bool? ?? false,
          generationMethod: workoutMap['generation_method'] as String?,
        );
        final todayWorkoutResponse = TodayWorkoutResponse(
          hasWorkoutToday: isToday,
          todayWorkout: isToday ? summary : null,
          nextWorkout: !isToday ? summary : null,
        );
        TodayWorkoutNotifier.preSeedCache(todayWorkoutResponse);
      } else {
        // No workout — pre-seed empty response so provider doesn't show loading
        TodayWorkoutNotifier.preSeedCache(const TodayWorkoutResponse(
          hasWorkoutToday: false,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Workout pre-seed failed: $e');
    }
  }

  /// Pre-seed nutrition summary from bootstrap data.
  static void _preSeedNutrition(Ref ref, dynamic nutritionData) {
    if (nutritionData == null) return;
    try {
      final m = nutritionData as Map<String, dynamic>;
      ref.read(nutritionProvider.notifier).preSeedFromBootstrap(
        calories: (m['calories'] as num?)?.toInt() ?? 0,
        targetCalories: (m['target_calories'] as num?)?.toInt(),
        protein: (m['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0.0,
        targetProtein: (m['target_protein'] as num?)?.toDouble(),
        targetCarbs: (m['target_carbs'] as num?)?.toDouble(),
        targetFat: (m['target_fat'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Nutrition pre-seed failed: $e');
    }
  }

  /// Pre-seed hydration data from bootstrap data.
  static void _preSeedHydration(Ref ref, dynamic hydrationData) {
    if (hydrationData == null) return;
    try {
      final m = hydrationData as Map<String, dynamic>;
      ref.read(hydrationProvider.notifier).preSeedFromBootstrap(
        currentMl: (m['current_ml'] as num?)?.toInt() ?? 0,
        targetMl: (m['target_ml'] as num?)?.toInt() ?? 2500,
      );
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Hydration pre-seed failed: $e');
    }
  }
}
