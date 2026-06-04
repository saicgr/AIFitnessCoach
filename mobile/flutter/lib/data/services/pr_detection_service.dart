/// Personal Record (PR) Detection Service
///
/// Client-side PR detection for real-time celebration during workouts.
/// Detects weight PRs, rep PRs, volume PRs, and estimated 1RM PRs.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/equipment_scope.dart';
import '../models/exercise.dart';
import '../repositories/workout_repository.dart';
import '../services/api_client.dart';
import 'haptic_service.dart';

/// Types of personal records
enum PRType {
  weight,   // Max weight lifted for a rep range
  reps,     // Max reps at a given weight
  volume,   // Max total volume (sets * reps * weight)
  oneRM,    // Estimated one rep max
}

extension PRTypeExtension on PRType {
  String get displayName {
    switch (this) {
      case PRType.weight:
        return 'Weight PR';
      case PRType.reps:
        return 'Rep PR';
      case PRType.volume:
        return 'Volume PR';
      case PRType.oneRM:
        return '1RM PR';
    }
  }

  String get shortName {
    switch (this) {
      case PRType.weight:
        return 'WEIGHT';
      case PRType.reps:
        return 'REPS';
      case PRType.volume:
        return 'VOLUME';
      case PRType.oneRM:
        return '1RM';
    }
  }

  IconData get icon {
    switch (this) {
      case PRType.weight:
        return Icons.fitness_center;
      case PRType.reps:
        return Icons.repeat;
      case PRType.volume:
        return Icons.bar_chart;
      case PRType.oneRM:
        return Icons.emoji_events;
    }
  }
}

/// A detected personal record
class DetectedPR {
  final PRType type;
  final String exerciseName;
  final double newValue;
  final double? previousValue;
  final double improvementPercent;
  final int reps;
  final double weight;
  final DateTime achievedAt;

  const DetectedPR({
    required this.type,
    required this.exerciseName,
    required this.newValue,
    this.previousValue,
    required this.improvementPercent,
    required this.reps,
    required this.weight,
    required this.achievedAt,
  });

  /// Get celebration level based on improvement
  CelebrationLevel get celebrationLevel {
    if (improvementPercent >= 10) {
      return CelebrationLevel.epic;
    } else if (improvementPercent >= 3) {
      return CelebrationLevel.normal;
    } else {
      return CelebrationLevel.subtle;
    }
  }

  /// Format the value for display
  String get formattedValue {
    switch (type) {
      case PRType.weight:
        return '${newValue.toStringAsFixed(1)}kg';
      case PRType.reps:
        return '${newValue.toInt()} reps';
      case PRType.volume:
        return '${newValue.toStringAsFixed(0)}kg';
      case PRType.oneRM:
        return '${newValue.toStringAsFixed(1)}kg';
    }
  }

  /// Format the improvement for display
  String get formattedImprovement {
    if (previousValue == null) return 'NEW!';
    final diff = newValue - previousValue!;
    if (type == PRType.reps) {
      return '+${diff.toInt()} reps';
    }
    return '+${diff.toStringAsFixed(1)}kg';
  }

  /// Get a motivating message based on the PR
  String get celebrationMessage {
    if (improvementPercent >= 10) {
      return 'MASSIVE PR! 💪🔥';
    } else if (improvementPercent >= 5) {
      return 'NEW PR! 🎉';
    } else if (improvementPercent >= 3) {
      return 'PR! Nice work! 💪';
    } else {
      return 'New Personal Best!';
    }
  }
}

/// Celebration intensity levels
enum CelebrationLevel {
  subtle,   // 1-2% improvement - badge only
  normal,   // 3-10% improvement - badge + short animation
  epic,     // 10%+ improvement - full celebration + confetti
}

/// Cached exercise history for PR comparison
class _ExerciseCache {
  final String exerciseName;
  final double maxWeight;
  final int maxRepsAtWeight;
  final double maxVolume;
  final double max1RM;
  final DateTime cachedAt;
  // FEATURE 3A: max reps ever logged at BODYWEIGHT (weight == 0) for this exercise,
  // used to detect bodyweight rep PRs (more reps with no added load).
  final int maxRepsAtBodyweight;

  _ExerciseCache({
    required this.exerciseName,
    required this.maxWeight,
    required this.maxRepsAtWeight,
    required this.maxVolume,
    required this.max1RM,
    required this.cachedAt,
    this.maxRepsAtBodyweight = 0,
  });

  /// Check if cache is still valid (15 minutes)
  bool get isValid => DateTime.now().difference(cachedAt).inMinutes < 15;
}

/// PR Detection Service
///
/// Provides real-time PR detection during workouts by caching
/// exercise history and comparing current performance.
class PRDetectionService {
  final Map<String, _ExerciseCache> _cache = {};

  // Frequency capping
  int _prCountThisWorkout = 0;
  DateTime? _lastCelebrationTime;
  static const int _maxPRsPerWorkout = 3;
  static const Duration _celebrationCooldown = Duration(seconds: 60);

  /// Reset service for new workout
  void startNewWorkout() {
    _prCountThisWorkout = 0;
    _lastCelebrationTime = null;
  }

  /// Load and cache exercise history for a list of exercises.
  ///
  /// [gymProfileId] (per-gym progress tracking): the gym this workout is being
  /// performed at (workout.gymProfileId ?? activeGymProfileIdProvider). For
  /// machine/cable exercises — whose load isn't comparable across gyms — the
  /// cache + the history fetch are scoped to this gym so a home-gym set can
  /// legitimately PR instead of being crushed by an incomparable other-gym
  /// machine record. Free-weight exercises stay combined (null scope), since
  /// the same barbell weight IS comparable everywhere. Null when unknown →
  /// every exercise behaves combined (legacy behavior, never crashes).
  Future<void> preloadExerciseHistory({
    required WidgetRef ref,
    required List<WorkoutExercise> exercises,
    String? gymProfileId,
  }) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) return;

    for (final exercise in exercises) {
      // Per-gym scope only applies to machine/cable/etc. exercises AND only
      // when we actually know which gym we're at. Free weights → null (combined).
      final scopedGym = (gymProfileId != null &&
              isPerGymExercise(exercise.equipment, exerciseName: exercise.name))
          ? gymProfileId
          : null;
      await _loadExerciseCache(
        exerciseName: exercise.name,
        workoutRepo: workoutRepo,
        userId: userId,
        gymProfileId: scopedGym,
      );
    }
  }

  /// Cache key for an exercise. For per-gym exercises the key is namespaced by
  /// gym so the same machine's history at two gyms never collides (and so the
  /// live "vs last time" / PR comparison reads only same-gym numbers). Free
  /// weights (gymProfileId == null) keep the plain name key — combined.
  String _cacheKey(String exerciseName, String? gymProfileId) {
    final base = exerciseName.toLowerCase();
    return gymProfileId == null ? base : '$base@@gym:$gymProfileId';
  }

  Future<void> _loadExerciseCache({
    required String exerciseName,
    required WorkoutRepository workoutRepo,
    required String userId,
    String? gymProfileId,
  }) async {
    try {
      final cacheKey = _cacheKey(exerciseName, gymProfileId);
      // Check if we already have valid cache
      final existing = _cache[cacheKey];
      if (existing != null && existing.isValid) return;

      // Fetch exercise history. For per-gym exercises this scopes the history
      // to the same gym (the flutter-ui agent adds the optional `gymProfileId`
      // named param on getExerciseProgress; null = combined). Resilient if the
      // param defaults — a null gym just returns combined history.
      final history = await workoutRepo.getExerciseProgress(
        userId: userId,
        exerciseName: exerciseName,
        gymProfileId: gymProfileId,
      );

      if (history.isEmpty) {
        // No history - any performance will be a PR. (For a per-gym exercise
        // with no same-gym history, this is the "first at this gym" case — a
        // legit PR rather than a regression vs another gym.)
        _cache[cacheKey] = _ExerciseCache(
          exerciseName: exerciseName,
          maxWeight: 0,
          maxRepsAtWeight: 0,
          maxVolume: 0,
          max1RM: 0,
          cachedAt: DateTime.now(),
          maxRepsAtBodyweight: 0,
        );
        return;
      }

      // Calculate max values from history
      double maxWeight = 0;
      int maxRepsAtWeight = 0;
      double maxVolume = 0;
      double max1RM = 0;
      // FEATURE 3A: track the best rep count at bodyweight (weight == 0).
      int maxRepsAtBodyweight = 0;

      for (final session in history) {
        final weight = (session['weight_kg'] ?? session['weight'] ?? 0.0).toDouble();
        final reps = (session['reps'] ?? 0) as int;
        final sets = (session['sets'] ?? 1) as int;
        final volume = weight * reps * sets;
        final estimated1RM = _calculate1RM(weight, reps);

        if (weight > maxWeight) {
          maxWeight = weight;
          maxRepsAtWeight = reps;
        }
        if (weight <= 0 && reps > maxRepsAtBodyweight) {
          maxRepsAtBodyweight = reps;
        }
        if (volume > maxVolume) {
          maxVolume = volume;
        }
        if (estimated1RM > max1RM) {
          max1RM = estimated1RM;
        }
      }

      _cache[cacheKey] = _ExerciseCache(
        exerciseName: exerciseName,
        maxWeight: maxWeight,
        maxRepsAtWeight: maxRepsAtWeight,
        maxVolume: maxVolume,
        max1RM: max1RM,
        cachedAt: DateTime.now(),
        maxRepsAtBodyweight: maxRepsAtBodyweight,
      );
    } catch (e) {
      debugPrint('Error loading exercise cache: $e');
    }
  }

  /// Resolve the cached history for an exercise, preferring the gym-scoped
  /// entry (machine/cable) and falling back to the combined entry. The
  /// fallback guards against a caller that preloaded combined but checks with
  /// a gym (or vice-versa) so PR detection never silently no-ops.
  _ExerciseCache? _resolveCache(String exerciseName, String? gymProfileId) {
    if (gymProfileId != null) {
      final scoped = _cache[_cacheKey(exerciseName, gymProfileId)];
      if (scoped != null) return scoped;
    }
    return _cache[exerciseName.toLowerCase()];
  }

  /// Check if a completed set is a PR
  ///
  /// Returns detected PRs (can be multiple types from one set).
  ///
  /// [gymProfileId] (per-gym progress tracking): pass the gym this set was
  /// performed at for machine/cable exercises so the comparison reads only
  /// same-gym history (matching the gym-scoped cache key written at preload).
  /// Null = combined (free weights, or unknown gym). If a gym-scoped cache
  /// entry is missing we fall back to the combined entry so detection never
  /// silently breaks when a caller hasn't been threaded for gym yet.
  List<DetectedPR> checkForPR({
    required String exerciseName,
    required double weight,
    required int reps,
    required int totalSets,
    required double totalVolume,
    String? gymProfileId,
  }) {
    final cache = _resolveCache(exerciseName, gymProfileId);
    if (cache == null) {
      // No cache - can't detect PR (but may still be one)
      return [];
    }

    final detectedPRs = <DetectedPR>[];
    final now = DateTime.now();

    // FEATURE 3A: bodyweight rep PR. With no external load, progress = more reps, so
    // we compare against the best bodyweight rep count rather than weight/1RM (which
    // would be 0 and never PR). A weight-PR/1RM-PR makes no sense for an unloaded set,
    // so we emit only the rep PR and return early.
    if (weight <= 0 && reps >= 1) {
      if (reps > cache.maxRepsAtBodyweight) {
        final improvement = cache.maxRepsAtBodyweight > 0
            ? ((reps - cache.maxRepsAtBodyweight) / cache.maxRepsAtBodyweight) * 100.0
            : 100.0;
        detectedPRs.add(DetectedPR(
          type: PRType.reps,
          exerciseName: exerciseName,
          newValue: reps.toDouble(),
          previousValue:
              cache.maxRepsAtBodyweight > 0 ? cache.maxRepsAtBodyweight.toDouble() : null,
          improvementPercent: improvement,
          reps: reps,
          weight: 0,
          achievedAt: now,
        ));
      }
      return detectedPRs;
    }

    // Check weight PR (must be at same or higher reps)
    if (weight > cache.maxWeight && reps >= 1) {
      final improvement = cache.maxWeight > 0
          ? ((weight - cache.maxWeight) / cache.maxWeight) * 100.0
          : 100.0;
      detectedPRs.add(DetectedPR(
        type: PRType.weight,
        exerciseName: exerciseName,
        newValue: weight,
        previousValue: cache.maxWeight > 0 ? cache.maxWeight : null,
        improvementPercent: improvement,
        reps: reps,
        weight: weight,
        achievedAt: now,
      ));
    }

    // Check estimated 1RM PR
    final current1RM = _calculate1RM(weight, reps);
    if (current1RM > cache.max1RM && reps >= 1) {
      final improvement = cache.max1RM > 0
          ? ((current1RM - cache.max1RM) / cache.max1RM) * 100.0
          : 100.0;
      // Only add 1RM PR if we didn't already add a weight PR
      // (to avoid double celebration for same achievement)
      if (!detectedPRs.any((pr) => pr.type == PRType.weight)) {
        detectedPRs.add(DetectedPR(
          type: PRType.oneRM,
          exerciseName: exerciseName,
          newValue: current1RM,
          previousValue: cache.max1RM > 0 ? cache.max1RM : null,
          improvementPercent: improvement,
          reps: reps,
          weight: weight,
          achievedAt: now,
        ));
      }
    }

    // Check volume PR (only at end of exercise)
    if (totalVolume > cache.maxVolume) {
      final improvement = cache.maxVolume > 0
          ? ((totalVolume - cache.maxVolume) / cache.maxVolume) * 100.0
          : 100.0;
      detectedPRs.add(DetectedPR(
        type: PRType.volume,
        exerciseName: exerciseName,
        newValue: totalVolume,
        previousValue: cache.maxVolume > 0 ? cache.maxVolume : null,
        improvementPercent: improvement,
        reps: reps,
        weight: weight,
        achievedAt: now,
      ));
    }

    return detectedPRs;
  }

  /// Determine if we should show celebration for a PR
  /// Returns true if celebration should be shown
  bool shouldShowCelebration(DetectedPR pr) {
    // Check frequency capping
    if (_prCountThisWorkout >= _maxPRsPerWorkout) {
      return false;
    }

    // Check cooldown
    if (_lastCelebrationTime != null) {
      final timeSinceLast = DateTime.now().difference(_lastCelebrationTime!);
      if (timeSinceLast < _celebrationCooldown) {
        return false;
      }
    }

    // Subtle PRs (< 3%) don't get celebration
    if (pr.celebrationLevel == CelebrationLevel.subtle) {
      return false;
    }

    return true;
  }

  /// Record that a celebration was shown
  void recordCelebration() {
    _prCountThisWorkout++;
    _lastCelebrationTime = DateTime.now();
  }

  /// Trigger appropriate haptic feedback for PR
  void triggerHaptics(List<DetectedPR> prs) {
    if (prs.isEmpty) return;

    if (prs.length > 1) {
      // Multiple PRs - use multi-PR haptic
      HapticService.multiPrAchievement();
    } else {
      // Single PR
      HapticService.prAchievement();
    }
  }

  /// Calculate estimated 1RM using Epley formula
  double _calculate1RM(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    // Epley formula: 1RM = weight × (1 + 0.0333 × reps)
    return weight * (1 + 0.0333 * reps);
  }

  /// Update cache after PR is achieved (to avoid re-triggering).
  ///
  /// [gymProfileId] must match the scope used in [checkForPR] so the updated
  /// ceiling lands on the same (gym-scoped or combined) cache entry. Null =
  /// combined. Falls back to the combined entry if no gym-scoped entry exists.
  void updateCacheAfterPR(DetectedPR pr, {String? gymProfileId}) {
    final scopedKey = (gymProfileId != null &&
            _cache.containsKey(_cacheKey(pr.exerciseName, gymProfileId)))
        ? _cacheKey(pr.exerciseName, gymProfileId)
        : pr.exerciseName.toLowerCase();
    final existing = _cache[scopedKey];
    if (existing == null) return;

    _cache[scopedKey] = _ExerciseCache(
      exerciseName: pr.exerciseName,
      maxWeight: pr.type == PRType.weight ? pr.newValue : existing.maxWeight,
      maxRepsAtWeight: existing.maxRepsAtWeight,
      maxVolume: pr.type == PRType.volume ? pr.newValue : existing.maxVolume,
      max1RM: pr.type == PRType.oneRM ? pr.newValue : existing.max1RM,
      cachedAt: existing.cachedAt,
      // FEATURE 3A: a rep PR raises the bodyweight rep ceiling so it doesn't re-fire.
      maxRepsAtBodyweight: pr.type == PRType.reps
          ? pr.newValue.toInt()
          : existing.maxRepsAtBodyweight,
    );
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }
}

/// Singleton provider for PR detection
final prDetectionServiceProvider = Provider<PRDetectionService>((ref) {
  return PRDetectionService();
});
