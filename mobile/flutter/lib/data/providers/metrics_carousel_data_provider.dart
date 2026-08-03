/// Real data sources for the Home metrics carousel. Every number here comes
/// from an existing provider/repository — nothing is fabricated (CLAUDE.md
/// "no mock data, no fallback data"; this file is what the 2000-kcal-default
/// trap looks like when it's NOT repeated).
///
///   * Training page  — sessions/streak from [workoutsProvider] +
///     [xpCurrentStreakProvider] (already loaded on Home), volume/time from
///     [volumeProgressionProvider] (new fetch — no Home-loaded source carries
///     weekly training volume), new-PRs from `prStatsProvider`.
///   * Volume trend page — same [volumeProgressionProvider], 8-week window.
///   * Recovery page — sleep from [combinedHealthHistoryProvider], readiness
///     from `todayReadinessScoreProvider`. Both already Health-gated at their
///     source, so this file just projects them.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/progress_charts.dart';
import '../models/scores.dart';
import '../providers/combined_health_provider.dart';
import '../providers/scores_provider.dart' show scoresProvider, prStatsProvider;
import '../providers/xp_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/progress_charts_repository.dart';
import '../repositories/readiness_repository.dart';
import '../repositories/workout_repository.dart' show workoutsProvider;
import '../services/health_service.dart';

/// The user's local calendar day for an ISO-ish timestamp/date string.
/// Handles both a bare `YYYY-MM-DD` and a full instant — mirrors
/// `screens/home/widgets/home_schedule_dates.dart`'s `scheduledLocalDay`
/// (duplicated narrowly here rather than importing screens/ code into data/,
/// which this repo's layering keeps one-directional).
DateTime? _localDay(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  if (s.length == 10) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Monday(or Sunday)-anchored local week start, duration-free (no
/// [weekDisplayConfigProvider] dependency needed — the carousel's "this
/// week" always means the ISO/ Mon-Sun week the app uses elsewhere for
/// workout scheduling; Sunday-start users still get a stable 7-day window,
/// just anchored differently, matching the existing week-glance behaviour).
DateTime _mondayWeekStart(DateTime today) =>
    today.subtract(Duration(days: today.weekday - 1));

/// Weekly training-volume history (8 weeks). Single fetch feeds BOTH the
/// Training page's volume/time stats (the most recent entry) and the Volume
/// Trend page's area chart + delta. `keepAlive` so switching Home tabs
/// doesn't re-hit the network every return, matching
/// `combinedHealthHistoryProvider`'s convention; `authStateProvider` changes
/// (login/logout) still invalidate it via the watch below.
final volumeProgressionProvider =
    FutureProvider.autoDispose<VolumeProgressionData?>((ref) async {
  ref.keepAlive();
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId == null) return null;
  try {
    final repo = ref.watch(progressChartsRepositoryProvider);
    return await repo.getVolumeOverTime(
      userId: userId,
      timeRange: ProgressTimeRange.eightWeeks,
    );
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Training page
// ---------------------------------------------------------------------------

class TrainingWeekStats {
  final int sessionsCompleted;
  final int sessionsScheduled;
  final int streakDays;
  final double volumeKg;
  final int totalMinutes;
  final int newPrsThisWeek;
  final int caloriesBurned;
  final int exercisesDone;

  const TrainingWeekStats({
    required this.sessionsCompleted,
    required this.sessionsScheduled,
    required this.streakDays,
    required this.volumeKg,
    required this.totalMinutes,
    required this.newPrsThisWeek,
    required this.caloriesBurned,
    required this.exercisesDone,
  });

  static const empty = TrainingWeekStats(
    sessionsCompleted: 0,
    sessionsScheduled: 0,
    streakDays: 0,
    volumeKg: 0,
    totalMinutes: 0,
    newPrsThisWeek: 0,
    caloriesBurned: 0,
    exercisesDone: 0,
  );
}

final trainingWeekStatsProvider = Provider<TrainingWeekStats>((ref) {
  final workouts = ref.watch(workoutsProvider).valueOrNull ?? const [];
  final streak = ref.watch(xpCurrentStreakProvider);
  final prStats = ref.watch(prStatsProvider);
  final volume = ref.watch(volumeProgressionProvider).valueOrNull;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = _mondayWeekStart(today);
  final weekEndExclusive = weekStart.add(const Duration(days: 7));

  int completed = 0;
  int scheduled = 0;
  int calories = 0;
  int exercises = 0;
  for (int i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final onDay = workouts.where((w) {
      final day = _localDay(w.scheduledDate);
      return day != null && _sameDay(day, date);
    });
    if (onDay.isEmpty) continue;
    scheduled += 1;
    final done =
        onDay.where((w) => w.isCompleted == true && !w.isSyncedFromHealthApp);
    if (done.isNotEmpty) {
      completed += 1;
      for (final w in done) {
        calories += w.estimatedCalories;
        exercises += w.exercises.length;
      }
    }
  }

  double volumeKg = 0;
  int totalMinutes = 0;
  if (volume != null) {
    for (final wk in volume.data) {
      final wkStart = wk.weekStartDate;
      if (wkStart != null && _sameDay(wkStart, weekStart)) {
        volumeKg = wk.totalVolumeKg;
        totalMinutes = wk.totalMinutes;
        break;
      }
    }
  }

  int newPrs = 0;
  final recentPrs = prStats?.recentPrs ?? const <PersonalRecordScore>[];
  for (final pr in recentPrs) {
    final day = _localDay(pr.achievedAt);
    if (day == null) continue;
    if (!day.isBefore(weekStart) && day.isBefore(weekEndExclusive)) {
      newPrs++;
    }
  }

  return TrainingWeekStats(
    sessionsCompleted: completed,
    sessionsScheduled: scheduled,
    streakDays: streak,
    volumeKg: volumeKg,
    totalMinutes: totalMinutes,
    newPrsThisWeek: newPrs,
    caloriesBurned: calories,
    exercisesDone: exercises,
  );
});

/// Kicks off the loads [trainingWeekStatsProvider] depends on but doesn't
/// itself trigger (`prStatsProvider` is a read-only selector over
/// `scoresProvider`, which needs an explicit `loadPersonalRecords` call).
/// Call once from the Training card's `initState`/first build — the
/// provider's own in-flight/freshness guards make repeat calls cheap no-ops.
void ensureTrainingWeekStatsLoaded(WidgetRef ref, String? userId) {
  if (userId == null) return;
  ref.read(scoresProvider.notifier).loadPersonalRecords(userId: userId, periodDays: 30);
}

// ---------------------------------------------------------------------------
// Volume trend page
// ---------------------------------------------------------------------------

class VolumeTrendSnapshot {
  /// Ascending by week, real rows only (never zero-filled/fabricated).
  final List<WeeklyVolumeData> weeks;

  const VolumeTrendSnapshot({required this.weeks});

  static const empty = VolumeTrendSnapshot(weeks: []);

  double get currentWeekKg => weeks.isEmpty ? 0 : weeks.last.totalVolumeKg;

  /// Null when fewer than 2 weeks of real history exist — the guard the
  /// build spec requires ("<2 weeks → '— —', never 0%").
  double? get deltaPercent {
    if (weeks.length < 2) return null;
    final prev = weeks[weeks.length - 2].totalVolumeKg;
    final curr = weeks.last.totalVolumeKg;
    if (prev <= 0) return null;
    return ((curr - prev) / prev) * 100;
  }
}

final volumeTrendSnapshotProvider = Provider<VolumeTrendSnapshot>((ref) {
  final volume = ref.watch(volumeProgressionProvider).valueOrNull;
  if (volume == null) return VolumeTrendSnapshot.empty;
  final weeks = List<WeeklyVolumeData>.from(volume.data)
    ..sort((a, b) {
      final ad = a.weekStartDate;
      final bd = b.weekStartDate;
      if (ad == null || bd == null) return 0;
      return ad.compareTo(bd);
    });
  // Keep at most the trailing 8 weeks even if the endpoint ever returns more.
  final trimmed =
      weeks.length > 8 ? weeks.sublist(weeks.length - 8) : weeks;
  return VolumeTrendSnapshot(weeks: trimmed);
});

// ---------------------------------------------------------------------------
// Recovery page
// ---------------------------------------------------------------------------

class RecoverySnapshot {
  final bool healthConnected;
  final ReadinessScore? readiness;

  /// Last 7 nights of sleep, oldest first, minutes (0 = no data that night —
  /// never fabricated).
  final List<int> sleepMinutesByNight;

  const RecoverySnapshot({
    required this.healthConnected,
    required this.readiness,
    required this.sleepMinutesByNight,
  });

  static const empty = RecoverySnapshot(
    healthConnected: false,
    readiness: null,
    sleepMinutesByNight: [],
  );

  /// The Recovery page's visibility guard: hidden entirely (not an empty
  /// card) unless Health is connected AND there's real readiness data.
  bool get isAvailable => healthConnected && readiness != null;
}

final recoverySnapshotProvider = Provider<RecoverySnapshot>((ref) {
  final syncState = ref.watch(healthSyncProvider);
  final readiness = ref.watch(todayReadinessScoreProvider);

  if (!syncState.isConnected) {
    return RecoverySnapshot(
      healthConnected: false,
      readiness: readiness,
      sleepMinutesByNight: const [],
    );
  }

  final history = ref.watch(combinedHealthHistoryProvider).valueOrNull;
  final days = history?.days ?? const [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final byDay = {
    for (final d in days) DateTime(d.date.year, d.date.month, d.date.day): d,
  };
  final nights = <int>[
    for (int i = 6; i >= 0; i--)
      byDay[today.subtract(Duration(days: i))]?.sleepMinutes ?? 0,
  ];

  return RecoverySnapshot(
    healthConnected: true,
    readiness: readiness,
    sleepMinutesByNight: nights,
  );
});
