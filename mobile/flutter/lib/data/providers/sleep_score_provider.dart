/// `sleepScoreProvider` — last-night's [SleepScore] surfaced to the home tile
/// and the Today Score's Sleep contributor.
///
/// Reuses the existing `computeSleepScore` pure function (no new scoring
/// logic) and the existing `getSleepData` + `getNightlySleepHistory` Health
/// Connect / HealthKit aggregations. Returns `null` when the health service
/// is not connected OR last night returned no asleep minutes — the caller
/// renders a "Connect Health" / "No sleep recorded" empty state rather than
/// a fabricated zero.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_service.dart';
import '../services/health_goals_service.dart';
import '../../screens/health/widgets/sleep_score.dart';

/// A snapshot of last night's sleep with its computed score.
///
/// `score` may be null when there are no asleep minutes (the user did not
/// wear a tracker / forgot to log sleep). [summary] is always present (may be
/// empty) so the UI can show duration + bedtime even if scoring is impossible.
class SleepScoreSnapshot {
  final SleepSummary summary;
  final SleepScore? score;

  const SleepScoreSnapshot({required this.summary, required this.score});

  bool get hasData => (score?.total ?? 0) > 0 || summary.totalMinutes > 0;
}

/// Live last-night sleep + computed score. Null when Health Connect /
/// HealthKit is not linked at all — caller shows "Connect" CTA.
final sleepScoreProvider =
    FutureProvider.autoDispose<SleepScoreSnapshot?>((ref) async {
  ref.keepAlive();
  // Health Connect / HealthKit linkage is the precondition. If the user
  // hasn't connected at all, the home tile should show "Connect Health" and
  // the Today Score should treat Sleep as non-applicable (renormalize out).
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return null;

  final health = ref.read(healthServiceProvider);

  // Last night's summary (sums all sessions whose wake date is today).
  SleepSummary summary;
  try {
    summary = await health.getSleepData(days: 1);
  } catch (_) {
    return SleepScoreSnapshot(
      summary: SleepSummary(),
      score: null,
    );
  }

  // Mid-sleep history for the Consistency component. The 7-night window
  // matches what the Sleep detail screen uses; the helper bins by wake date
  // and we average the recent midpoints (excluding any night with no bed/wake
  // times). When there's not enough history `computeSleepScore` itself
  // gracefully renormalizes out the consistency component.
  int? avgMidSleepMin;
  try {
    final history = await health.getNightlySleepHistory(days: 7);
    final midpoints = <int>[];
    for (final night in history) {
      final main = night.mainSleep;
      final bt = main.bedTime;
      final wt = main.wakeTime;
      if (bt == null || wt == null) continue;
      final mid =
          bt.add(Duration(milliseconds: wt.difference(bt).inMilliseconds ~/ 2));
      midpoints.add(_minutesFromLocalMidnight(mid));
    }
    if (midpoints.isNotEmpty) {
      avgMidSleepMin = midpoints.reduce((a, b) => a + b) ~/ midpoints.length;
    }
  } catch (_) {
    // History errors are non-fatal — just skip the consistency component.
  }

  int? midSleepMin;
  final bt = summary.bedTime;
  final wt = summary.wakeTime;
  if (bt != null && wt != null) {
    final mid =
        bt.add(Duration(milliseconds: wt.difference(bt).inMilliseconds ~/ 2));
    midSleepMin = _minutesFromLocalMidnight(mid);
  }

  // User's sleep goal (default 8h = 480 min). Same source the Sleep detail
  // screen uses, so the home tile and detail screen never disagree.
  final goalAsync = ref.watch(healthGoalsProvider);
  final goalMinutes =
      goalAsync.valueOrNull?.sleepDurationGoalMinutes ?? 480;

  final score = computeSleepScore(
    asleepMinutes: summary.totalMinutes,
    goalMinutes: goalMinutes,
    efficiency: summary.efficiency,
    deepMinutes: summary.deepMinutes,
    remMinutes: summary.remMinutes,
    midSleepMinutesFromMidnight: midSleepMin,
    avgMidSleepMinutesFromMidnight: avgMidSleepMin,
  );

  return SleepScoreSnapshot(summary: summary, score: score);
});

int _minutesFromLocalMidnight(DateTime t) {
  final local = t.toLocal();
  return local.hour * 60 + local.minute;
}
