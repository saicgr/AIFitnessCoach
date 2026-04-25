import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../shareable_data.dart';

/// Builds a `Shareable` for the Stats & Scores screen — the global "MY STATS"
/// share. Refreshes streak / weekly progress on first call so the user never
/// sees a stale streak (Bug #5).
class StatsAdapter {
  /// Force-refresh providers and return the latest snapshot. Call this once
  /// on share-sheet mount.
  static Future<Shareable?> fromProviders(WidgetRef ref) async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null) return null;

    // Refresh consistency from API (kills stale 0-day-streak bug after a
    // newly completed workout).
    await ref
        .read(consistencyProvider.notifier)
        .loadInsights(userId: userId);
    // Reload workouts so weeklyProgress reflects today's completion.
    await ref.read(workoutsProvider.notifier).fetchWorkouts(userId);

    final consistency = ref.read(consistencyProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final weekly = workoutsNotifier.weeklyProgress;
    final allWorkouts =
        ref.read(workoutsProvider).asData?.value ?? const [];

    final totalWorkouts = consistency.insights?.monthWorkoutsCompleted ?? 0;
    final currentStreak = consistency.currentStreak;
    final longestStreak = consistency.longestStreak;
    final _ = ref.read(useKgProvider);

    final totalMinutes = _totalMinutesThisMonth(allWorkouts);

    if (totalWorkouts <= 0 && weekly.$1 <= 0 && currentStreak <= 0) {
      // Honest empty state — no stats yet.
      return null;
    }

    // Self-healing validation: if total workouts > 0 but streak is 0,
    // recompute streak locally from completed workout dates rather than
    // displaying the obviously-wrong server value.
    final validatedStreak = _validateStreak(
      ref: ref,
      reportedStreak: currentStreak,
      totalWorkouts: totalWorkouts,
    );

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'THIS WEEK',
        value: '${weekly.$1}/${weekly.$2}',
        icon: Icons.calendar_today_rounded,
        accent: AppColors.purple,
      ),
      ShareableMetric(
        label: 'TOTAL TIME',
        value: _fmtTotalTime(totalMinutes),
        icon: Icons.timer_outlined,
        accent: AppColors.success,
      ),
      ShareableMetric(
        label: 'STREAK',
        value: '$validatedStreak ${validatedStreak == 1 ? 'day' : 'days'}',
        icon: Icons.local_fire_department_rounded,
        accent: AppColors.orange,
      ),
      if (longestStreak > 0)
        ShareableMetric(
          label: 'LONGEST',
          value: '$longestStreak ${longestStreak == 1 ? 'day' : 'days'}',
          icon: Icons.emoji_events_rounded,
        ),
    ];

    final periodLabel = _periodLabel();

    return Shareable(
      kind: ShareableKind.statsOverview,
      title: 'My Stats',
      periodLabel: periodLabel,
      heroValue: totalWorkouts,
      heroUnitSingular: 'workout',
      highlights: highlights,
      accentColor: AppColors.orange,
    );
  }

  static int _validateStreak({
    required WidgetRef ref,
    required int reportedStreak,
    required int totalWorkouts,
  }) {
    if (reportedStreak > 0) return reportedStreak;
    if (totalWorkouts <= 0) return 0;

    // Server says 0 but the user has logged workouts this month — recompute
    // locally from completed workout dates.
    final workoutsAsync = ref.read(workoutsProvider);
    final list = workoutsAsync.asData?.value ?? const [];
    final completedDays = list
        .where((w) => w.isCompleted == true && w.completedAt != null)
        .map((w) {
          final raw = w.completedAt;
          if (raw == null) return null;
          final dt = DateTime.tryParse(raw);
          if (dt == null) return null;
          return DateTime(dt.year, dt.month, dt.day);
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completedDays.isEmpty) return 0;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    if (completedDays.first != todayKey &&
        completedDays.first !=
            todayKey.subtract(const Duration(days: 1))) {
      return 0;
    }
    int streak = 1;
    for (var i = 1; i < completedDays.length; i++) {
      final expected = completedDays[i - 1].subtract(const Duration(days: 1));
      if (completedDays[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int _totalMinutesThisMonth(Iterable workouts) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    int total = 0;
    for (final w in workouts) {
      try {
        final completed = (w.isCompleted as bool?) ?? false;
        if (!completed) continue;
        final dateStr = w.completedAt as String?;
        if (dateStr == null) continue;
        final dt = DateTime.tryParse(dateStr);
        if (dt == null || dt.isBefore(monthStart)) continue;
        final mins = (w.durationMinutes as int?) ?? 0;
        total += mins;
      } catch (_) {
        // skip malformed entries — never silently fall back to fake data
      }
    }
    return total;
  }

  static String _fmtTotalTime(int? minutes) {
    final m = minutes ?? 0;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }

  static String _periodLabel() {
    final now = DateTime.now();
    return DateFormat('MMM yyyy').format(now).toUpperCase();
  }
}
