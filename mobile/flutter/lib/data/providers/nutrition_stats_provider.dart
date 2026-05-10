import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_repository.dart';

// In-memory caches for nutrition aggregates. Mirrors the workouts cache pattern
// in `workout_repository.dart`: returns cached data instantly on screen entry
// and refreshes silently in the background, so tab switches feel instant.
WeeklySummaryData? _weeklySummaryCache;
DetailedTDEE? _detailedTDEECache;
AdherenceSummary? _adherenceSummaryCache;
WeeklyNutritionData? _weeklyNutritionCache;

/// Drop nutrition aggregate caches (call on logout or user switch).
void clearNutritionStatsCache() {
  _weeklySummaryCache = null;
  _detailedTDEECache = null;
  _adherenceSummaryCache = null;
  _weeklyNutritionCache = null;
}

Future<T?> _cacheFirst<T>({
  required T? cached,
  required Future<T?> Function() fetch,
  required void Function(T?) writeCache,
  required String label,
}) async {
  if (cached != null) {
    // Hydrate next paint silently — don't block this one.
    Future.microtask(() async {
      try {
        final fresh = await fetch();
        if (fresh != null) writeCache(fresh);
      } catch (e) {
        debugPrint('⚠️ [$label] background refresh failed: $e');
      }
    });
    return cached;
  }
  try {
    final fresh = await fetch();
    if (fresh != null) writeCache(fresh);
    return fresh;
  } catch (e) {
    debugPrint('❌ [$label] fetch failed: $e');
    return null;
  }
}

/// Provider for weekly summary data (days logged, avg calories/protein, weight change)
final weeklySummaryProvider =
    FutureProvider.autoDispose.family<WeeklySummaryData?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<WeeklySummaryData>(
      cached: _weeklySummaryCache,
      fetch: () => repo.getWeeklySummary(userId),
      writeCache: (v) => _weeklySummaryCache = v,
      label: 'WeeklySummary',
    );
  },
);

/// Provider for detailed TDEE with confidence intervals
final detailedTDEEProvider =
    FutureProvider.autoDispose.family<DetailedTDEE?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<DetailedTDEE>(
      cached: _detailedTDEECache,
      fetch: () => repo.getDetailedTDEE(userId),
      writeCache: (v) => _detailedTDEECache = v,
      label: 'DetailedTDEE',
    );
  },
);

/// Provider for adherence summary with sustainability score
final adherenceSummaryProvider =
    FutureProvider.autoDispose.family<AdherenceSummary?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<AdherenceSummary>(
      cached: _adherenceSummaryCache,
      fetch: () => repo.getAdherenceSummary(userId),
      writeCache: (v) => _adherenceSummaryCache = v,
      label: 'AdherenceSummary',
    );
  },
);

/// Provider for weekly nutrition data with daily breakdown (for charts)
final weeklyNutritionProvider =
    FutureProvider.autoDispose.family<WeeklyNutritionData?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<WeeklyNutritionData>(
      cached: _weeklyNutritionCache,
      fetch: () => repo.getWeeklyNutrition(userId),
      writeCache: (v) => _weeklyNutritionCache = v,
      label: 'WeeklyNutrition',
    );
  },
);
