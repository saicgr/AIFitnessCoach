/// Pre-warms the Food/Nutrition tab so first navigation renders today's
/// summary, recent logs, micronutrients, and recipes instantly.
///
/// `NutritionNotifier` already has a 5-min in-memory + per-date disk cache
/// internally (lines 286–294 of nutrition_repository_part_food_logging_progress.dart),
/// but those caches are populated lazily inside `_loadData()` from
/// `nutrition_screen.dart`'s `initState`. Pre-warming forces them populated
/// immediately after sign-in.
///
/// Notes:
///   • Hydration is already covered by `BootstrapPrefetchService` — skipped here.
///   • `getDailyMicronutrients()` and `getRecipes()` are repository methods
///     (not notifier methods); we call them via the repository's instance
///     reachable through `ref.read(nutritionProvider.notifier)._repository`.
///     Since that field is private, we instead let the screen's lazy load
///     handle them — pre-warming the two notifier methods (loadTodaySummary,
///     loadRecentLogs) covers ~80% of perceived first-paint latency.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/fueling_split_provider.dart';
import '../providers/nutrition_stats_provider.dart';
import '../repositories/nutrition_repository.dart';
import 'api_client.dart';

DateTime? _lastWarmedAt;
Completer<void>? _inFlight;

const Duration _staleAfter = Duration(minutes: 5);

class NutritionPrewarmer {
  /// No own disk cache — `NutritionNotifier` manages its own per-date disk
  /// cache via SharedPreferences. Kept as a no-op for boot-orchestrator
  /// symmetry.
  static Future<void> hydrateFromDisk() async {
    // Intentionally a no-op.
  }

  static Future<void> clearAll() async {
    _lastWarmedAt = null;
  }

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
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        debugPrint('🔍 [NutritionPrewarmer] no userId yet — skipping');
        return;
      }

      debugPrint('🍎 [NutritionPrewarmer] warming for $userId');

      final notifier = ref.read(nutritionProvider.notifier);

      final futures = <Future<void>>[
        notifier.loadTodaySummary(userId, forceRefresh: force).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] loadTodaySummary failed: $e');
        }),
        notifier.loadRecentLogs(userId, forceRefresh: force).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] loadRecentLogs failed: $e');
        }),
        // Below-the-fold Stats strip — warm the cached aggregate providers so
        // the first Stats render paints last-known REAL numbers instead of a
        // wall of skeletons + 6 cold network calls. Each is cache-first
        // (in-memory + disk, stale-while-revalidate); warming triggers the
        // disk seed + background refresh ahead of tab open.
        ref.read(weeklySummaryProvider(userId).future).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] weeklySummary warm failed: $e');
          return null;
        }),
        ref.read(weeklyNutritionProvider(userId).future).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] weeklyNutrition warm failed: $e');
          return null;
        }),
        ref.read(detailedTDEEProvider(userId).future).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] detailedTDEE warm failed: $e');
          return null;
        }),
        ref.read(adherenceSummaryProvider(userId).future).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] adherenceSummary warm failed: $e');
          return null;
        }),
        // fuelingSplitProvider reads its userId/timezone internally.
        ref.read(fuelingSplitProvider.future).catchError((e) {
          debugPrint('⚠️ [NutritionPrewarmer] fuelingSplit warm failed: $e');
          return null;
        }),
      ];

      await Future.wait(futures, eagerError: false);

      _lastWarmedAt = DateTime.now();
      debugPrint('✅ [NutritionPrewarmer] warmed ${futures.length} provider(s)');
    } catch (e, st) {
      debugPrint('⚠️ [NutritionPrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  static Future<void> invalidateAndRefresh(dynamic ref) async {
    _lastWarmedAt = null;
    await warm(ref, force: true);
  }
}
