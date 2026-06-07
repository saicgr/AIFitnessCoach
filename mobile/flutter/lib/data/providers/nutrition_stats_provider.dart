import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_repository.dart';
import '../services/data_cache_service.dart';
import 'fueling_split_provider.dart';

// In-memory caches for nutrition aggregates. Mirrors the workouts cache pattern
// in `workout_repository.dart`: returns cached data instantly on screen entry
// and refreshes silently in the background, so tab switches feel instant.
//
// Backed by a SharedPreferences DISK layer (DataCacheService) so a COLD start
// (app killed → in-memory caches gone) still paints last-known REAL numbers
// instantly, then overwrites them with a fresh fetch. Disk keys use the
// `statsKeyPrefix` namespace (auto 12h TTL, per-user scoped).
WeeklySummaryData? _weeklySummaryCache;
DetailedTDEE? _detailedTDEECache;
AdherenceSummary? _adherenceSummaryCache;
WeeklyNutritionData? _weeklyNutritionCache;

/// Disk-cache keys (all share the stats prefix → 12h TTL).
const String _kWeeklySummaryKey =
    '${DataCacheService.statsKeyPrefix}nutrition_weekly_summary';
const String _kDetailedTDEEKey =
    '${DataCacheService.statsKeyPrefix}nutrition_detailed_tdee';
const String _kAdherenceSummaryKey =
    '${DataCacheService.statsKeyPrefix}nutrition_adherence_summary';
const String _kWeeklyNutritionKey =
    '${DataCacheService.statsKeyPrefix}nutrition_weekly_nutrition';

/// Drop nutrition aggregate caches (call on logout or user switch).
void clearNutritionStatsCache() {
  _weeklySummaryCache = null;
  _detailedTDEECache = null;
  _adherenceSummaryCache = null;
  _weeklyNutritionCache = null;
}

/// Live user id from the current Supabase session (never a cached field —
/// JWT-expiry rule). Used to scope disk-cache entries per user.
String? get _liveUserId =>
    Supabase.instance.client.auth.currentUser?.id;

/// Cache-first read with a TWO-tier cache (in-memory static + SharedPreferences
/// disk) and stale-while-revalidate semantics. Only ever stores REAL server
/// responses; never fabricates data.
///
/// Order of operations:
///   1. In-memory hit → return instantly, refresh in background, write-through.
///   2. Cold start (no in-memory) → seed from disk (incl. expired), return it,
///      refresh in background, write-through.
///   3. No cache anywhere → fetch synchronously, write-through to both tiers.
Future<T?> _cacheFirst<T>({
  required T? cached,
  required Future<T?> Function() fetch,
  required void Function(T?) writeMemory,
  required String label,
  required String diskKey,
  required Map<String, dynamic> Function(T) toJson,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  // Write-through helper: update both in-memory and disk with a REAL value.
  Future<void> persist(T value) async {
    writeMemory(value);
    try {
      await DataCacheService.instance
          .cache(diskKey, toJson(value), userId: _liveUserId);
    } catch (e) {
      debugPrint('⚠️ [$label] disk write failed: $e');
    }
  }

  // Background revalidation — refresh next paint silently, don't block this one.
  void revalidate() {
    Future.microtask(() async {
      try {
        final fresh = await fetch();
        if (fresh != null) await persist(fresh);
      } catch (e) {
        debugPrint('⚠️ [$label] background refresh failed: $e');
      }
    });
  }

  // 1. In-memory hit.
  if (cached != null) {
    revalidate();
    return cached;
  }

  // 2. Cold start — seed from disk (return expired so a kill→reopen still
  //    paints last-known REAL numbers instantly).
  try {
    final disk = await DataCacheService.instance
        .getCached(diskKey, userId: _liveUserId, returnExpiredOnMiss: true);
    if (disk != null) {
      final seeded = fromJson(disk);
      writeMemory(seeded);
      revalidate();
      return seeded;
    }
  } catch (e) {
    debugPrint('⚠️ [$label] disk seed failed: $e');
  }

  // 3. No cache anywhere — fetch and write-through.
  try {
    final fresh = await fetch();
    if (fresh != null) await persist(fresh);
    return fresh;
  } catch (e) {
    debugPrint('❌ [$label] fetch failed: $e');
    return null;
  }
}

/// Hand-rolled serializer for [WeeklyNutritionData] — the model has a
/// `fromJson` but no `toJson`, and it lives in a file we don't own. Mirrors the
/// exact wire shape `WeeklyNutritionData.fromJson` reads so the round-trip is
/// lossless.
Map<String, dynamic> _weeklyNutritionToJson(WeeklyNutritionData v) => {
      'start_date': v.startDate,
      'end_date': v.endDate,
      'total_calories': v.totalCalories,
      'average_daily_calories': v.averageDailyCalories,
      'total_meals': v.totalMeals,
      'daily_summaries': v.dailySummaries
          .map((d) => {
                'date': d.date,
                'total_calories': d.calories,
                'total_protein_g': d.proteinG,
                'total_carbs_g': d.carbsG,
                'total_fat_g': d.fatG,
                'meal_count': d.meals,
                'inflammation_score': d.inflammationScore,
              })
          .toList(),
    };

/// Provider for weekly summary data (days logged, avg calories/protein, weight change)
final weeklySummaryProvider =
    FutureProvider.autoDispose.family<WeeklySummaryData?, String>(
  (ref, userId) async {
    ref.keepAlive();
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<WeeklySummaryData>(
      cached: _weeklySummaryCache,
      fetch: () => repo.getWeeklySummary(userId),
      writeMemory: (v) => _weeklySummaryCache = v,
      label: 'WeeklySummary',
      diskKey: _kWeeklySummaryKey,
      toJson: (v) => v.toJson(),
      fromJson: WeeklySummaryData.fromJson,
    );
  },
);

/// Provider for detailed TDEE with confidence intervals
final detailedTDEEProvider =
    FutureProvider.autoDispose.family<DetailedTDEE?, String>(
  (ref, userId) async {
    ref.keepAlive();
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<DetailedTDEE>(
      cached: _detailedTDEECache,
      fetch: () => repo.getDetailedTDEE(userId),
      writeMemory: (v) => _detailedTDEECache = v,
      label: 'DetailedTDEE',
      diskKey: _kDetailedTDEEKey,
      toJson: (v) => v.toJson(),
      fromJson: DetailedTDEE.fromJson,
    );
  },
);

/// Provider for adherence summary with sustainability score
final adherenceSummaryProvider =
    FutureProvider.autoDispose.family<AdherenceSummary?, String>(
  (ref, userId) async {
    ref.keepAlive();
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<AdherenceSummary>(
      cached: _adherenceSummaryCache,
      fetch: () => repo.getAdherenceSummary(userId),
      writeMemory: (v) => _adherenceSummaryCache = v,
      label: 'AdherenceSummary',
      diskKey: _kAdherenceSummaryKey,
      toJson: (v) => v.toJson(),
      fromJson: AdherenceSummary.fromJson,
    );
  },
);

/// Provider for weekly nutrition data with daily breakdown (for charts)
final weeklyNutritionProvider =
    FutureProvider.autoDispose.family<WeeklyNutritionData?, String>(
  (ref, userId) async {
    ref.keepAlive();
    final repo = ref.watch(nutritionRepositoryProvider);
    return _cacheFirst<WeeklyNutritionData>(
      cached: _weeklyNutritionCache,
      fetch: () => repo.getWeeklyNutrition(userId),
      writeMemory: (v) => _weeklyNutritionCache = v,
      label: 'WeeklyNutrition',
      diskKey: _kWeeklyNutritionKey,
      toJson: _weeklyNutritionToJson,
      fromJson: WeeklyNutritionData.fromJson,
    );
  },
);

/// Per-day inflammation series for the past week, derived from the SAME weekly
/// payload the calorie trend uses — no extra network call. Each point is a
/// (date, score 0-10) pair; days with no scored log are omitted (null), so the
/// card can show an honest "log more to see your trend" state rather than a
/// fabricated flat line. The aggregate average is the mean of the present days.
typedef WeeklyInflammation = ({
  List<({String date, double? score})> series,
  double? weekAverage,
  int daysWithScore,
});

/// Lightweight selector over [weeklyNutritionProvider]; recomputes only when the
/// underlying weekly data changes. Returns null while the source is loading so
/// the card skeletons instead of flashing an empty state.
final weeklyInflammationProvider =
    Provider.autoDispose.family<AsyncValue<WeeklyInflammation?>, String>(
  (ref, userId) {
    final weekly = ref.watch(weeklyNutritionProvider(userId));
    return weekly.whenData((data) {
      if (data == null) return null;
      final series = data.dailySummaries
          .map((d) => (date: d.date, score: d.inflammationScore))
          .toList();
      final scored =
          series.where((p) => p.score != null).map((p) => p.score!).toList();
      final avg = scored.isEmpty
          ? null
          : scored.reduce((a, b) => a + b) / scored.length;
      return (
        series: series,
        weekAverage: avg,
        daysWithScore: scored.length,
      );
    });
  },
);

/// Hard-clear ALL nutrition-stats caches (static in-memory + SharedPreferences
/// disk) for every aggregate the NUTRITION STATS section reads. Plain
/// `ref.invalidate` is NOT enough on these providers: they use stale-while-
/// revalidate, so an invalidate re-serves the cached snapshot first and the
/// section shows last cycle's numbers (see the cache contract in this file +
/// DataCacheService's note). Callers must clear here, THEN invalidate, so the
/// provider re-run hits the synchronous fetch path and paints fresh data.
Future<void> clearNutritionStatsAndFuelingCaches() async {
  clearNutritionStatsCache();
  await clearFuelingSplitCache();
  final user = _liveUserId;
  final cache = DataCacheService.instance;
  await Future.wait<void>([
    cache.invalidate(_kWeeklySummaryKey, userId: user),
    cache.invalidate(_kDetailedTDEEKey, userId: user),
    cache.invalidate(_kAdherenceSummaryKey, userId: user),
    cache.invalidate(_kWeeklyNutritionKey, userId: user),
  ]);
}

/// Force the NUTRITION STATS section to refetch after a write (e.g. a meal
/// logged). Clears both cache tiers, then invalidates every stats provider so
/// the section paints fresh numbers WITHOUT a manual pull-to-refresh.
///
/// Takes the long-lived [Ref] from a notifier (which survives the log sheet's
/// dispose) rather than a widget's WidgetRef. The weekly inflammation trend
/// rides on [weeklyNutritionProvider], so invalidating that refreshes it too.
Future<void> invalidateNutritionStats(Ref ref, String userId) async {
  await clearNutritionStatsAndFuelingCaches();
  ref.invalidate(weeklySummaryProvider(userId));
  ref.invalidate(weeklyNutritionProvider(userId));
  ref.invalidate(detailedTDEEProvider(userId));
  ref.invalidate(adherenceSummaryProvider(userId));
  ref.invalidate(fuelingSplitProvider);
}
