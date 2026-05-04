/// Single boot-time orchestrator for all tab prewarmers.
///
/// Replaces five separate `XxxPrewarmer.hydrateFromDisk()` calls in `main.dart`
/// with one [PrewarmerBoot.hydrateAll] call. Why: each `hydrateFromDisk` opens
/// `SharedPreferences.getInstance()` and reads its own key, hopping over the
/// platform channel each time. On a slow Android device that's 5×30ms = 150ms
/// of cold-start latency. Batching to one open + 5 reads cuts it to ~30ms.
///
/// Each prewarmer exposes:
///   • `static const String persistKey` — its SharedPreferences key (or null
///     if it doesn't persist)
///   • `static void hydrateFromJsonStatic(String? raw)` — apply a blob to the
///     in-memory cache
///
/// Currently only YouOverviewPrewarmer persists to disk; the other four use
/// Riverpod's container or DataCacheService as their cache backend, so their
/// boot hydration is a no-op and just calls `hydrateFromDisk()` which returns
/// immediately. Future prewarmers that add their own disk persistence should
/// add their key to [_persistKeys] so the batch read picks them up.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_prewarmer.dart';
import 'nutrition_prewarmer.dart';
import 'social_prewarmer.dart';
import 'workout_completion_prewarmer.dart';
import 'workouts_prewarmer.dart';
import 'you_overview_prewarmer.dart';

class PrewarmerBoot {
  static Completer<void>? _hydration;

  /// Single SharedPreferences open + batch read of all prewarmer disk blobs,
  /// then dispatch to each prewarmer's `hydrateFromJsonStatic`.
  ///
  /// Idempotent — second call awaits the first's future.
  static Future<void> hydrateAll() async {
    final existing = _hydration;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _hydration = completer;

    try {
      // One platform-channel hop instead of five.
      final prefs = await SharedPreferences.getInstance();

      // Batch-read every prewarmer's disk key. Add new keys here when a new
      // prewarmer adds its own disk persistence.
      final youBlob = prefs.getString(YouOverviewPrewarmer.persistKey);
      final completionBlob = prefs.getString(WorkoutCompletionPrewarmer.persistKey);

      // Dispatch synchronously to each prewarmer's static hydrator. None of
      // these touch IO, so they're all microseconds.
      YouOverviewPrewarmer.hydrateFromJsonStatic(youBlob);
      WorkoutCompletionPrewarmer.hydrateFromJsonStatic(completionBlob);

      // Other prewarmers don't persist to disk yet — call their no-op
      // hydrateFromDisk() so any future implementation gets picked up
      // automatically (defense in depth, no perf cost).
      await Future.wait([
        HomePrewarmer.hydrateFromDisk(),
        NutritionPrewarmer.hydrateFromDisk(),
        WorkoutsPrewarmer.hydrateFromDisk(),
        SocialPrewarmer.hydrateFromDisk(),
      ]);

      debugPrint('⚡ [PrewarmerBoot] hydrateAll completed');
    } catch (e, st) {
      debugPrint('⚠️ [PrewarmerBoot] hydrateAll failed: $e\n$st');
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }
}
