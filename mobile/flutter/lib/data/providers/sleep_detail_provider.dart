import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_service.dart';

/// How far back the Sleep detail screen loads nightly history.
///
/// 35 nights covers the 7-night chart, the 30-day trend, the 14-night sleep
/// debt window, and the ≥14-night monthly-summary gate with a small margin.
/// The date strip is capped to this window so it never implies data the app
/// does not actually have (plan edge case 15).
const int kSleepHistoryDays = 35;

/// Aggregate sleep history + derived analytics for the Sleep detail screen.
///
/// All the cross-night math (debt, regularity, monthly averages) lives here
/// as pure derivations off [nights] so the screen stays presentational and
/// the numbers are computed once per load.
class SleepHistory {
  /// Per-night records, newest first, bucketed by wake date.
  final List<DailySleep> nights;

  const SleepHistory({required this.nights});

  static const SleepHistory empty = SleepHistory(nights: []);

  bool get hasData => nights.isNotEmpty;

  /// The most recent night, or null when there is no history.
  DailySleep? get latest => nights.isEmpty ? null : nights.first;

  /// Look up the night that woke on [date] (local-midnight key). Null when
  /// that day has no tracked sleep — drives the per-day empty state
  /// (edge case 12).
  DailySleep? nightFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final n in nights) {
      if (n.date == key) return n;
    }
    return null;
  }

  /// `yyyy-MM-dd` keys of every night that has data — feeds the date strip's
  /// accent dots.
  Set<String> get trackedDateKeys => {
        for (final n in nights)
          if (n.hasData)
            '${n.date.year.toString().padLeft(4, '0')}-'
                '${n.date.month.toString().padLeft(2, '0')}-'
                '${n.date.day.toString().padLeft(2, '0')}',
      };

  /// Rolling sleep debt: the total shortfall vs [goalMinutes] across the
  /// last [window] nights with data. Only nights with plausible data count;
  /// a surplus night reduces (but never makes negative beyond 0) the debt.
  /// Returns 0 when there is no usable history.
  int sleepDebtMinutes(int goalMinutes, {int window = 14}) {
    if (nights.isEmpty) return 0;
    var debt = 0;
    var counted = 0;
    for (final n in nights) {
      if (counted >= window) break;
      if (!n.hasData) continue;
      final asleep = n.totalAsleepMinutes;
      // Exclude implausible nights from the debt average (edge case 9).
      if (asleep < 30 || asleep > 16 * 60) continue;
      debt += (goalMinutes - asleep);
      counted++;
    }
    if (counted == 0) return 0;
    return debt > 0 ? debt : 0;
  }

  /// Sleep regularity 0-100: how consistent the main-sleep mid-points are
  /// across the recent window. 100 = identical bed/wake every night; lower
  /// as the schedule drifts. Needs at least 3 nights with a known window;
  /// returns null otherwise (honest "-" in the UI).
  int? regularityScore({int window = 14}) {
    final mids = <double>[];
    for (final n in nights) {
      if (mids.length >= window) break;
      final mid = _midSleepMinutes(n.mainSleep);
      if (mid != null) mids.add(mid.toDouble());
    }
    if (mids.length < 3) return null;
    // Standard deviation of mid-sleep minutes; map 0 min → 100, 120 min → 0.
    final mean = mids.reduce((a, b) => a + b) / mids.length;
    var variance = 0.0;
    for (final m in mids) {
      var d = m - mean;
      // Fold wrap-around drift across the midnight boundary.
      if (d > 720) d -= 1440;
      if (d < -720) d += 1440;
      variance += d * d;
    }
    final sd = math.sqrt(variance / mids.length);
    final score = (100 - (sd / 120) * 100).clamp(0.0, 100.0);
    return score.round();
  }

  /// Mid-sleep clock time of [s] as minutes from local midnight, or null
  /// when the bed/wake window is unknown.
  static int? _midSleepMinutes(SleepSummary s) {
    final bed = s.bedTime;
    final wake = s.wakeTime;
    if (bed == null || wake == null) return null;
    final mid = bed.add(Duration(
        minutes: wake.difference(bed).inMinutes ~/ 2));
    return mid.hour * 60 + mid.minute;
  }

  /// Average mid-sleep minutes-from-midnight across the recent window —
  /// the consistency baseline for [computeSleepScore]. Null with no history.
  int? avgMidSleepMinutes({int window = 14}) {
    final mids = <int>[];
    for (final n in nights) {
      if (mids.length >= window) break;
      final mid = _midSleepMinutes(n.mainSleep);
      if (mid != null) mids.add(mid);
    }
    if (mids.isEmpty) return null;
    // Average on the circular clock — convert to angles, average, convert
    // back, so a 23:50 / 00:10 pair averages to midnight, not noon.
    var sumSin = 0.0;
    var sumCos = 0.0;
    for (final m in mids) {
      final theta = (m / 1440) * 2 * math.pi;
      sumSin += math.sin(theta);
      sumCos += math.cos(theta);
    }
    var avgTheta = math.atan2(sumSin / mids.length, sumCos / mids.length);
    if (avgTheta < 0) avgTheta += 2 * math.pi;
    return ((avgTheta / (2 * math.pi)) * 1440).round() % 1440;
  }

  /// 30-day monthly summary — only meaningful with ≥14 nights of data
  /// (edge case 25 / the plan's monthly-summary gate). Null below that.
  SleepMonthlySummary? monthlySummary() {
    final usable = nights
        .where((n) =>
            n.hasData &&
            n.totalAsleepMinutes >= 30 &&
            n.totalAsleepMinutes <= 16 * 60)
        .take(30)
        .toList();
    if (usable.length < 14) return null;
    var totalAsleep = 0;
    var bestAsleep = 0;
    var worstAsleep = 1 << 30;
    var napNights = 0;
    for (final n in usable) {
      final a = n.totalAsleepMinutes;
      totalAsleep += a;
      if (a > bestAsleep) bestAsleep = a;
      if (a < worstAsleep) worstAsleep = a;
      if (n.naps.isNotEmpty) napNights++;
    }
    return SleepMonthlySummary(
      nightCount: usable.length,
      avgAsleepMinutes: (totalAsleep / usable.length).round(),
      bestAsleepMinutes: bestAsleep,
      worstAsleepMinutes: worstAsleep,
      napNightCount: napNights,
    );
  }
}

/// 30-day rollup shown on the Sleep detail screen.
class SleepMonthlySummary {
  final int nightCount;
  final int avgAsleepMinutes;
  final int bestAsleepMinutes;
  final int worstAsleepMinutes;
  final int napNightCount;

  const SleepMonthlySummary({
    required this.nightCount,
    required this.avgAsleepMinutes,
    required this.bestAsleepMinutes,
    required this.worstAsleepMinutes,
    required this.napNightCount,
  });
}

/// Loads [kSleepHistoryDays] of nightly sleep history from Health Connect /
/// HealthKit. Returns [SleepHistory.empty] when Health is not connected —
/// the screen then shows an honest "connect Health" empty state, never
/// fabricated nights.
final sleepHistoryProvider =
    FutureProvider.autoDispose<SleepHistory>((ref) async {
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return SleepHistory.empty;

  final healthService = ref.watch(healthServiceProvider);
  try {
    final nights =
        await healthService.getNightlySleepHistory(days: kSleepHistoryDays);
    return SleepHistory(nights: nights);
  } catch (e) {
    debugPrint('❌ [SleepHistory] Error loading nightly history: $e');
    return SleepHistory.empty;
  }
});
