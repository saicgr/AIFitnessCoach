/// Pre-warms the post-workout completion screen so "tap last Log set →
/// completion screen visible with stats populated" feels instant instead
/// of the ~3-5s freeze + spinner combo it was.
///
/// What we CAN pre-fetch ahead of completion (data not dependent on the
/// final workout payload):
///   • Total workouts count (`GET /users/{id}/stats`) — drives milestone
///     detection ("Day N complete!" headline + the milestone overlay).
///   • Achievements list (`GET /users/{id}/achievements`) — drives the PR
///     detection + trophy celebration.
///
/// What we CANNOT pre-fetch (needs final workout volume/sets/reps that
/// aren't known until the user logs the actual last set):
///   • AI Coach feedback (`POST /workouts/{logId}/ai-coach-feedback`).
///     The completion screen handles this by rendering a deterministic
///     fallback summary immediately and replacing it silently when the
///     real feedback arrives in the background — no spinner.
///
/// Trigger points (mirrors `you_overview_prewarmer.dart`):
///   1. When the user logs the SECOND-TO-LAST set of the LAST exercise
///      (set_logging_mixin.dart) — heuristic, fires while user reads RPE
///      prompt for the upcoming last set.
///   2. From `finalizeWorkoutCompletion` (workout_flow_mixin.dart) — belt-
///      and-suspenders, in case the heuristic above didn't fire (e.g.
///      single-set workouts, edge cases in set detection).
///
/// Failure handling: every fetch is best-effort. Cache is only stamped if
/// at least one endpoint returned data. Concurrent calls share an in-flight
/// future via `_inFlight` Completer (same dedup pattern as YouOverview).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/workout_repository.dart';
import 'api_client.dart';

const String _kPersistKey = 'workout_completion_cache_v1';
const Duration _kDiskStaleAfter = Duration(hours: 6);

/// Module-level cache shared between the prewarmer and the completion screen.
class WorkoutCompletionCache {
  int? totalWorkoutCount;
  Map<String, dynamic>? achievements;
  DateTime? cachedAt;

  bool get hasData => cachedAt != null;

  Duration get age =>
      cachedAt == null ? Duration.zero : DateTime.now().difference(cachedAt!);

  void clear() {
    totalWorkoutCount = null;
    achievements = null;
    cachedAt = null;
  }

  Map<String, dynamic>? toJson() {
    if (cachedAt == null) return null;
    return {
      'totalWorkoutCount': totalWorkoutCount,
      'achievements': achievements,
      'cachedAt': cachedAt!.toIso8601String(),
    };
  }

  void hydrateFromJson(Map<String, dynamic> j) {
    try {
      totalWorkoutCount = (j['totalWorkoutCount'] as num?)?.toInt();
      final a = j['achievements'];
      achievements = a is Map ? a.cast<String, dynamic>() : null;
      final at = j['cachedAt'] as String?;
      cachedAt = at != null ? DateTime.tryParse(at) : null;
    } catch (e) {
      debugPrint('⚠️ [WorkoutCompletionCache] hydrate failed: $e');
      clear();
    }
  }
}

final WorkoutCompletionCache workoutCompletionCache = WorkoutCompletionCache();

Completer<void>? _inFlight;
DateTime? _lastWarmedAt;

const Duration _staleAfter = Duration(minutes: 5);

class WorkoutCompletionPrewarmer {
  /// SharedPreferences key — exposed so PrewarmerBoot can batch-read it.
  static const String persistKey = _kPersistKey;

  /// Apply a previously-decoded blob to the in-memory cache. Used by the
  /// boot orchestrator. Stale blobs are dropped — completion screen will
  /// then fall back to network fetch on first show.
  static void hydrateFromJsonStatic(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      workoutCompletionCache.hydrateFromJson(decoded.cast<String, dynamic>());
      if (workoutCompletionCache.cachedAt != null &&
          workoutCompletionCache.age > _kDiskStaleAfter) {
        workoutCompletionCache.clear();
      }
    } catch (e) {
      debugPrint(
        '⚠️ [WorkoutCompletionPrewarmer] hydrateFromJsonStatic failed: $e',
      );
    }
  }

  /// Single-tab fallback for boot hydration (kept for symmetry — prefer
  /// PrewarmerBoot.hydrateAll which batches the SharedPreferences open).
  static Future<void> hydrateFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hydrateFromJsonStatic(prefs.getString(_kPersistKey));
    } catch (e) {
      debugPrint('⚠️ [WorkoutCompletionPrewarmer] hydrateFromDisk failed: $e');
    }
  }

  /// Wipe in-memory + on-disk caches. Called on sign-out so the next user
  /// doesn't briefly see the prior account's totals/achievements.
  static Future<void> clearAll() async {
    workoutCompletionCache.clear();
    _lastWarmedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPersistKey);
    } catch (e) {
      debugPrint(
        '⚠️ [WorkoutCompletionPrewarmer] clearAll disk wipe failed: $e',
      );
    }
  }

  /// Pre-fetch the workout-stats and achievements endpoints in parallel.
  /// Fire-and-forget — never throws.
  ///
  /// Recently-warmed (within [_staleAfter]) → no-op unless [force].
  /// Concurrent callers share a single in-flight future.
  static Future<void> warm(dynamic ref, {bool force = false}) async {
    if (!force &&
        _lastWarmedAt != null &&
        DateTime.now().difference(_lastWarmedAt!) < _staleAfter) {
      return;
    }

    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _inFlight = completer;

    try {
      await _doWarm(ref);
    } catch (e, st) {
      debugPrint('⚠️ [WorkoutCompletionPrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  static Future<void> _doWarm(dynamic ref) async {
    final api = ref.read(apiClientProvider);
    final userId = await api.getUserId();
    if (userId == null) {
      debugPrint('🔍 [WorkoutCompletionPrewarmer] no userId yet — skipping');
      return;
    }

    debugPrint('🏁 [WorkoutCompletionPrewarmer] warming for $userId');

    // IMPORTANT: must be statically typed as WorkoutRepository so the
    // extension method getUserAchievements (defined in
    // workout_repository_performance.dart as part of the same library) is
    // resolvable. The outer `ref` parameter is intentionally typed `dynamic`
    // to accept both WidgetRef and Ref, but that makes
    // `ref.read(...)` itself dynamic — so we re-bind the result to the
    // concrete type to restore static dispatch. Otherwise the call falls
    // through noSuchMethod → NoSuchMethodError at runtime even though the
    // method clearly exists at compile time.
    final WorkoutRepository workoutRepo =
        ref.read(workoutRepositoryProvider) as WorkoutRepository;

    // Fire both fetches in parallel. Each per-call try/catch isolates
    // failures so one slow endpoint doesn't drag the other.
    Future<int?> fetchStats() async {
      try {
        final response = await api.dio.get('/users/$userId/stats');
        if (response.statusCode == 200 && response.data is Map) {
          final data = (response.data as Map).cast<String, dynamic>();
          return (data['total_workouts'] as int?) ?? 0;
        }
      } catch (e) {
        debugPrint('⚠️ [WorkoutCompletionPrewarmer] stats failed: $e');
      }
      return null;
    }

    Future<Map<String, dynamic>?> fetchAchievements() async {
      try {
        return await workoutRepo.getUserAchievements(userId: userId);
      } catch (e) {
        debugPrint('⚠️ [WorkoutCompletionPrewarmer] achievements failed: $e');
        return null;
      }
    }

    final results = await Future.wait<dynamic>(
      [fetchStats(), fetchAchievements()],
      eagerError: false,
    );

    final totalWorkouts = results[0] as int?;
    final achievements = results[1] as Map<String, dynamic>?;

    // Only stamp the cache if at least one fetch succeeded — preserves any
    // previously-warmed data when both are offline.
    if (totalWorkouts != null || achievements != null) {
      workoutCompletionCache
        ..totalWorkoutCount = totalWorkouts
        ..achievements = achievements
        ..cachedAt = DateTime.now();
      _lastWarmedAt = DateTime.now();
      unawaited(_persistToDisk());
      debugPrint(
        '✅ [WorkoutCompletionPrewarmer] cache populated '
        '(workouts=$totalWorkouts, achievements=${achievements != null ? "yes" : "no"})',
      );
    } else {
      debugPrint(
        '⚠️ [WorkoutCompletionPrewarmer] both endpoints failed — cache not stamped',
      );
    }
  }

  static Future<void> _persistToDisk() async {
    try {
      final snapshot = workoutCompletionCache.toJson();
      if (snapshot == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPersistKey, jsonEncode(snapshot));
    } catch (e) {
      debugPrint('⚠️ [WorkoutCompletionPrewarmer] persist failed: $e');
    }
  }
}
