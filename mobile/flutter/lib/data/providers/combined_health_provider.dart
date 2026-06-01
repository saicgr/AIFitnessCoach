import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import '../services/health_service.dart';

/// How far back the Combined Health hub loads daily-activity history.
///
/// 35 days covers the 7-day and 30-day per-metric views with margin; the
/// date strip is capped to this window so it never implies data older than
/// the backfill range (plan edge case 15).
const int kCombinedHealthDays = 35;

/// Aggregated daily-activity history for the Combined Health hub.
///
/// Reads the backend `/activity/history` endpoint (the synced
/// `daily_activity` rows) so a day the user did not open the app still
/// appears, and derives the activity streak.
class CombinedHealthHistory {
  /// Daily-activity rows, newest first.
  final List<DailyActivity> days;

  const CombinedHealthHistory({required this.days});

  static const CombinedHealthHistory empty =
      CombinedHealthHistory(days: []);

  bool get hasData => days.isNotEmpty;

  /// The row for [date] (local-midnight key), or null when that day has no
  /// synced data — drives the per-day section empty states (edge case 17).
  DailyActivity? dayFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final d in days) {
      final dk = DateTime(d.date.year, d.date.month, d.date.day);
      if (dk == key) return d;
    }
    return null;
  }

  /// `yyyy-MM-dd` keys of every day that has ANY metric — feeds the date
  /// strip's accent dots.
  Set<String> get trackedDateKeys => {
        for (final d in days)
          if (_hasAnyMetric(d))
            '${d.date.year.toString().padLeft(4, '0')}-'
                '${d.date.month.toString().padLeft(2, '0')}-'
                '${d.date.day.toString().padLeft(2, '0')}',
      };

  static bool _hasAnyMetric(DailyActivity d) =>
      d.steps > 0 ||
      d.caloriesBurned > 0 ||
      (d.sleepMinutes ?? 0) > 0 ||
      d.restingHeartRate != null ||
      d.avgHeartRate != null ||
      (d.waterMl ?? 0) > 0 ||
      (d.activeMinutes ?? 0) > 0;

  /// Current activity streak: consecutive days ending today (or yesterday,
  /// if today hasn't synced yet) where the step goal was met.
  ///
  /// A streak that would be broken only because today has not synced yet is
  /// kept alive by allowing the most recent day to be yesterday.
  int activityStreak(int stepGoal) {
    if (days.isEmpty || stepGoal <= 0) return 0;
    final byDate = <DateTime, DailyActivity>{};
    for (final d in days) {
      byDate[DateTime(d.date.year, d.date.month, d.date.day)] = d;
    }
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    // If today has no data yet, start the count from yesterday so a
    // pre-sync today doesn't zero a real streak.
    final todayRow = byDate[cursor];
    if (todayRow == null || todayRow.steps < stepGoal) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      final row = byDate[cursor];
      if (row == null || row.steps < stepGoal) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

/// Loads [kCombinedHealthDays] of daily-activity history from the backend.
///
/// Returns [CombinedHealthHistory.empty] when Health is not connected or no
/// user is resolved — the hub then shows honest empty sections rather than
/// fabricated rows.
final combinedHealthHistoryProvider =
    FutureProvider.autoDispose<CombinedHealthHistory>((ref) async {
  // Survive Home tab switches. Without this, the metric-deck tiles (steps
  // streak / zone minutes) dispose this provider when Home unmounts and it
  // re-hits `/activity/history` (a 35-day window) on EVERY tab return. A
  // change to `healthSyncProvider` (connect/disconnect) still re-runs it via
  // the watch below, so keepAlive doesn't freeze the connected-state.
  ref.keepAlive();

  // This provider already sources from the backend `/activity/history`
  // endpoint, so the disclosed reviewer demo needs no separate code path:
  // `healthSyncProvider` reports `isConnected: true` for the allowlisted
  // reviewer account (see `demoHealthModeProvider`), which lets this gate
  // through, and the seeded `daily_activity` rows are then loaded exactly
  // like a real account's synced rows. Behaviour is unchanged for real
  // accounts.
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return CombinedHealthHistory.empty;

  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return CombinedHealthHistory.empty;

  // Cache-first (fresh-only): paint a non-expired disk snapshot instantly so a
  // cold start shows the streak/zone tiles without a spinner. `returnExpiredOnMiss`
  // is false so we never freeze on a stale entry (the FutureProvider frozen-stale
  // trap); an expired/missing entry falls through to the network fetch below.
  // The 6h TTL + tz-rollover invalidation are enforced by DataCacheService for
  // `combinedHealthKey` (so an app left open past midnight refetches "today").
  final cachedList = await DataCacheService.instance.getCachedList(
    DataCacheService.combinedHealthKey,
    userId: userId,
  );
  if (cachedList != null && cachedList.isNotEmpty) {
    try {
      final days = cachedList.map((m) => DailyActivity.fromJson(m)).toList();
      if (days.isNotEmpty) return CombinedHealthHistory(days: days);
    } catch (e) {
      // Corrupt / schema-drifted envelope (e.g. after an app update) — drop it
      // and fall through to a fresh fetch rather than crashing the tile.
      debugPrint('⚠️ [CombinedHealth] Cache parse failed, refetching: $e');
    }
  }

  try {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: kCombinedHealthDays));
    final days = await ref.watch(activityServiceProvider).getActivityHistory(
          userId,
          limit: kCombinedHealthDays + 2,
          fromDate: from,
          toDate: now,
        );
    // Empty-guard (mirror today_workout `_saveToCache`): never write-through an
    // empty result. No-synced-days-yet or a transient failure must NOT poison
    // the cache and show "no data" instantly even after the user syncs.
    if (days.isNotEmpty) {
      await DataCacheService.instance.cacheList(
        DataCacheService.combinedHealthKey,
        days.map((d) => d.toJson()).toList(),
        userId: userId,
      );
    }
    return CombinedHealthHistory(days: days);
  } catch (e) {
    debugPrint('❌ [CombinedHealth] Error loading activity history: $e');
    return CombinedHealthHistory.empty;
  }
});
