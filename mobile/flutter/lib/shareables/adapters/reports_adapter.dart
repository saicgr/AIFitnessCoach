import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../shareable_data.dart';

/// Builds rich `Shareable` payloads for every Reports & Insights surface.
///
/// **The Reports Hub used to bypass each source-screen's own rich data
/// builder and ship a thin `{primary, secondary}` payload to the share
/// sheet — that's the bug behind the white placeholder bars on the
/// Personal Records share preview.** This adapter is the canonical source
/// of truth: both the source screens AND the hub call into it.
///
/// Returns `null` when there isn't enough data to populate the kind's
/// minimum highlights. Callers should show a snackbar instead of opening
/// an empty share sheet.
class ReportsAdapter {
  /// Build a Shareable for a Reports Hub route in a given month.
  static Future<Shareable?> forRoute({
    required WidgetRef ref,
    required BuildContext context,
    required String route,
    required DateTime month,
  }) async {
    final accent = AccentColorScope.of(context).getColor(true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final displayName =
        ref.read(authStateProvider).user?.displayName;
    final period = DateFormat('MMM yyyy').format(month).toUpperCase();

    if (userId == null) return null;

    switch (route) {
      case '/summaries':
        return _periodInsights(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/stats/personal-records':
        return _personalRecords(
            ref: ref,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/stats/exercise-history':
        return _exerciseHistory(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/stats/muscle-analytics':
        return _muscleAnalytics(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/settings/my-1rms':
        return _oneRm(
            userId: userId,
            period: period,
            displayName: displayName,
            accent: accent,
            ref: ref);
      case '/stats/milestones':
      case '/achievements':
        return _achievements(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent,
            kind: route == '/achievements'
                ? ShareableKind.achievements
                : ShareableKind.milestones);
      case '/progress-charts':
        return _progressCharts(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/measurements':
        return _bodyMeasurements(
            userId: userId,
            period: period,
            displayName: displayName,
            accent: accent);
      case '/nutrition':
        return _nutrition(
            userId: userId,
            month: month,
            period: period,
            displayName: displayName,
            accent: accent);
      default:
        return null;
    }
  }

  // ─── Period Insights ────────────────────────────────────────────────

  static Future<Shareable?> _periodInsights({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    // Pull two slices and merge:
    //   (a) workouts COMPLETED in this month (completed_at within bounds), AND
    //   (b) workouts SCHEDULED this month with is_completed=true but
    //       completed_at unset — Health Connect / Apple Health synced rows
    //       and some legacy "mark done" paths land here. Without (b) the
    //       hub card would say "3 workouts" while the share sheet returned
    //       null because none of the synced rows have completed_at set.
    final monthStartIso = monthStart.toIso8601String();
    final monthEndIso = monthEnd.toIso8601String();
    final scheduledStart =
        DateFormat('yyyy-MM-dd').format(monthStart);
    final scheduledEnd =
        DateFormat('yyyy-MM-dd').format(monthEnd);

    final results = await Future.wait([
      db
          .from('workouts')
          .select(
              'id, duration_minutes, estimated_calories, generation_metadata, completed_at, scheduled_date')
          .eq('user_id', userId)
          .gte('completed_at', monthStartIso)
          .lt('completed_at', monthEndIso)
          .eq('is_completed', true),
      db
          .from('workouts')
          .select(
              'id, duration_minutes, estimated_calories, generation_metadata, completed_at, scheduled_date')
          .eq('user_id', userId)
          .gte('scheduled_date', scheduledStart)
          .lt('scheduled_date', scheduledEnd)
          .eq('is_completed', true)
          .filter('completed_at', 'is', null),
    ]);

    final byId = <String, Map<String, dynamic>>{};
    for (final res in results) {
      for (final row in (res as List).cast<Map<String, dynamic>>()) {
        final id = row['id']?.toString();
        if (id != null) byId[id] = row;
      }
    }
    final list = byId.values.toList();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.periodInsights,
        title: 'Period Insights',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final totalMin = list.fold<int>(
        0, (s, w) => s + ((w['duration_minutes'] as num?)?.toInt() ?? 0));
    final totalCal = list.fold<int>(0, (s, w) {
      // Prefer the dedicated estimated_calories column; fall back to the
      // calories_burned/calories_active fields stashed in generation_metadata.
      final est = (w['estimated_calories'] as num?)?.toInt();
      if (est != null && est > 0) return s + est;
      final meta = (w['generation_metadata'] as Map?)?.cast<String, dynamic>();
      final c = (meta?['calories_active'] ?? meta?['calories_burned']) as num?;
      return s + (c?.toInt() ?? 0);
    });

    // Compute streak inline from completed_at days (consecutive day count
    // ending today or yesterday). Falls back to scheduled_date for synced
    // rows so streak doesn't silently drop them.
    final dayKeys = list
        .map((w) {
          final c = w['completed_at'] as String?;
          if (c != null && c.isNotEmpty) return DateTime.tryParse(c);
          final s = w['scheduled_date'] as String?;
          if (s != null && s.isNotEmpty) return DateTime.tryParse(s);
          return null;
        })
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final streak = _consecutiveDayStreak(dayKeys);

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'TOTAL TIME',
        value: _fmtMinutes(totalMin),
        icon: Icons.timer_outlined,
        accent: AppColors.success,
      ),
      if (totalCal > 0)
        ShareableMetric(
          label: 'CALORIES',
          value: '$totalCal kcal',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.orange,
        ),
      ShareableMetric(
        label: 'STREAK',
        value: '$streak ${streak == 1 ? 'day' : 'days'}',
        icon: Icons.bolt_rounded,
        accent: AppColors.purple,
      ),
    ];

    // Sub-metrics (per-day completion vector for Weekly Report template).
    final week = List<int>.filled(7, 0);
    for (final d in dayKeys) {
      final daysAgo = DateTime.now().difference(d).inDays;
      if (daysAgo >= 0 && daysAgo < 7) week[6 - daysAgo] = 1;
    }
    const dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final subMetrics = List.generate(
      7,
      (i) => ShareableMetric(label: dow[i], value: week[i].toString()),
    );

    return Shareable(
      kind: ShareableKind.periodInsights,
      title: 'Period Insights',
      periodLabel: period,
      heroValue: list.length,
      heroUnitSingular: 'workout',
      highlights: highlights,
      subMetrics: subMetrics,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Personal Records ──────────────────────────────────────────────

  static Future<Shareable?> _personalRecords({
    required WidgetRef ref,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final prStats = ref.read(prStatsProvider);
    final useKg = ref.read(useKgForWorkoutProvider);
    final unit = useKg ? 'kg' : 'lb';

    // Fast path — user has actual PRs.
    if (prStats != null && prStats.totalPrs > 0) {
      final byExercise = <String, double>{};
      for (final pr in prStats.recentPrs) {
        final key = pr.exerciseName.toLowerCase();
        final cur = byExercise[key] ?? 0;
        if (pr.estimated1rmKg > cur) byExercise[key] = pr.estimated1rmKg;
      }
      final top = prStats.recentPrs
          .where((pr) =>
              byExercise[pr.exerciseName.toLowerCase()] == pr.estimated1rmKg)
          .take(5)
          .toList();

      final highlights = top.map((lift) {
        final kg = lift.estimated1rmKg;
        final v = useKg ? kg : kg * 2.20462;
        return ShareableMetric(
          label: lift.exerciseDisplayName,
          value: '${v.round()} $unit',
          icon: Icons.emoji_events_rounded,
        );
      }).toList();

      return Shareable(
        kind: ShareableKind.personalRecords,
        title: 'Personal Records',
        periodLabel: period,
        heroValue: prStats.totalPrs,
        heroUnitSingular: 'PR',
        highlights: highlights,
        userDisplayName: displayName,
        accentColor: accent,
      );
    }

    // Fallback — no PRs yet (e.g., first workout where the system didn't
    // detect a "PR" but the user logged real lifts). Pull top weights from
    // strength_records as baselines so the user can still share their
    // first lifts instead of hitting a "not enough data" snackbar.
    final db = Supabase.instance.client;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await db
        .from('strength_records')
        .select('exercise_name, estimated_1rm')
        .eq('user_id', userId)
        .order('estimated_1rm', ascending: false)
        .limit(5);
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.personalRecords,
        title: 'Personal Records',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final highlights = list.map((r) {
      final kg = (r['estimated_1rm'] as num).toDouble();
      final v = useKg ? kg : kg * 2.20462;
      return ShareableMetric(
        label: r['exercise_name'] as String? ?? '—',
        value: '${v.round()} $unit',
        icon: Icons.fitness_center_rounded,
      );
    }).toList();

    return Shareable(
      kind: ShareableKind.personalRecords,
      title: 'Personal Records',
      periodLabel: period,
      heroValue: list.length,
      heroUnitSingular: 'baseline',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Exercise History ──────────────────────────────────────────────

  static Future<Shareable?> _exerciseHistory({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final res = await db
        .from('performance_logs')
        .select('exercise_name')
        .eq('user_id', userId)
        .gte('recorded_at', monthStart.toIso8601String())
        .lt('recorded_at', monthEnd.toIso8601String());
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.exerciseHistory,
        title: 'Exercise History',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final counts = <String, int>{};
    for (final r in list) {
      final n = (r['exercise_name'] as String?)?.trim();
      if (n == null || n.isEmpty) continue;
      counts[n] = (counts[n] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.exerciseHistory,
        title: 'Exercise History',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }
    final topFive = sorted.take(5).toList();

    final highlights = topFive
        .map((e) => ShareableMetric(label: e.key, value: '${e.value}×'))
        .toList();

    return Shareable(
      kind: ShareableKind.exerciseHistory,
      title: 'Exercise History',
      periodLabel: period,
      heroValue: counts.length,
      heroUnitSingular: 'exercise',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Muscle Analytics ──────────────────────────────────────────────

  static Future<Shareable?> _muscleAnalytics({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final res = await db
        .from('strength_scores')
        .select('muscle_group, strength_score')
        .eq('user_id', userId)
        .gte('period_start', monthStart.toIso8601String().substring(0, 10));
    final list = (res as List).cast<Map<String, dynamic>>();

    if (list.isNotEmpty) {
      final scores =
          list.map((r) => (r['strength_score'] as num).toInt()).toList();
      final avg = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) ~/ scores.length;
      list.sort((a, b) => (b['strength_score'] as num)
          .compareTo(a['strength_score'] as num));
      final top = list.take(3).toList();

      final highlights = [
        ShareableMetric(label: 'AVG SCORE', value: '$avg / 100'),
        for (final m in top)
          ShareableMetric(
            label: (m['muscle_group'] as String).toUpperCase(),
            value: '${(m['strength_score'] as num).toInt()}',
          ),
      ];

      return Shareable(
        kind: ShareableKind.muscleAnalytics,
        title: 'Muscle Strength',
        periodLabel: period,
        heroValue: avg,
        heroUnitSingular: '',
        heroSuffix: ' / 100',
        highlights: highlights,
        userDisplayName: displayName,
        accentColor: accent,
      );
    }

    // Fallback — strength_scores rollup hasn't run yet (first workout, or
    // backend roll-up cron hasn't fired). Derive per-muscle volume from
    // performance_logs so the share works on day 1 instead of bouncing
    // with "Not enough data".
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final perfRes = await db
        .from('performance_logs')
        .select('muscle_group, sets_completed, reps_completed, weight_used')
        .eq('user_id', userId)
        .gte('recorded_at', monthStart.toIso8601String())
        .lt('recorded_at', monthEnd.toIso8601String());
    final perfList = (perfRes as List).cast<Map<String, dynamic>>();
    if (perfList.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.muscleAnalytics,
        title: 'Muscle Strength',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final byMuscle = <String, int>{};
    for (final r in perfList) {
      final mg = (r['muscle_group'] as String?)?.trim();
      if (mg == null || mg.isEmpty) continue;
      final sets = (r['sets_completed'] as num?)?.toInt() ?? 0;
      byMuscle[mg] = (byMuscle[mg] ?? 0) + sets;
    }
    if (byMuscle.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.muscleAnalytics,
        title: 'Muscle Strength',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }
    final sorted = byMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSets = byMuscle.values.fold<int>(0, (s, v) => s + v);
    final top = sorted.take(3);

    return Shareable(
      kind: ShareableKind.muscleAnalytics,
      title: 'Muscle Strength',
      periodLabel: period,
      heroValue: byMuscle.length,
      heroUnitSingular: 'muscle',
      highlights: [
        ShareableMetric(label: 'TOTAL SETS', value: totalSets.toString()),
        for (final m in top)
          ShareableMetric(
            label: m.key.toUpperCase(),
            value: '${m.value} sets',
          ),
      ],
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── 1-Rep Maxes ───────────────────────────────────────────────────

  static Future<Shareable?> _oneRm({
    required String userId,
    required String period,
    required String? displayName,
    required Color accent,
    required WidgetRef ref,
  }) async {
    final db = Supabase.instance.client;
    final res = await db
        .from('strength_records')
        .select('exercise_name, estimated_1rm')
        .eq('user_id', userId)
        .order('estimated_1rm', ascending: false)
        .limit(8);
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.oneRm,
        title: '1-Rep Maxes',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final useKg = ref.read(useKgForWorkoutProvider);
    final unit = useKg ? 'kg' : 'lb';
    final top = list.first;
    final topKg = (top['estimated_1rm'] as num).toDouble();
    final topV = useKg ? topKg : topKg * 2.20462;

    // Map common big-3 lifts into highlights when present, fall back to
    // top 3 entries from the result.
    final byName = {
      for (final r in list)
        (r['exercise_name'] as String).toLowerCase():
            (r['estimated_1rm'] as num).toDouble(),
    };

    String fmt(double kg) {
      final v = useKg ? kg : kg * 2.20462;
      return '${v.round()} $unit';
    }

    final candidates = <ShareableMetric>[];
    final prefer = ['squat', 'bench', 'deadlift'];
    for (final p in prefer) {
      final match = byName.entries.firstWhere(
        (e) => e.key.contains(p),
        orElse: () => MapEntry('', 0),
      );
      if (match.key.isNotEmpty) {
        candidates.add(ShareableMetric(label: p.toUpperCase(), value: fmt(match.value)));
      }
    }
    if (candidates.length < 3) {
      for (final r in list) {
        if (candidates.length >= 5) break;
        final n = r['exercise_name'] as String;
        if (candidates.any((c) => c.label.toLowerCase() == n.toLowerCase())) continue;
        candidates.add(ShareableMetric(
          label: n,
          value: fmt((r['estimated_1rm'] as num).toDouble()),
        ));
      }
    }

    return Shareable(
      kind: ShareableKind.oneRm,
      title: '1-Rep Maxes',
      periodLabel: period,
      heroValue: topV.round(),
      heroUnitSingular: unit,
      highlights: candidates,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Milestones / Achievements ─────────────────────────────────────

  static Future<Shareable?> _achievements({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
    required ShareableKind kind,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    // Try this month first — but fall back to ALL-TIME if this month is
    // empty so the user with one workout (or one earned earlier) can still
    // share. Was returning null and showing "Not enough data" even when
    // the user had achievements from last month.
    final monthRes = await db
        .from('user_achievements')
        .select('xp_awarded, achievement_id, earned_at')
        .eq('user_id', userId)
        .gte('earned_at', monthStart.toIso8601String())
        .lt('earned_at', monthEnd.toIso8601String());
    var list = (monthRes as List).cast<Map<String, dynamic>>();
    var isAllTime = false;

    if (list.isEmpty) {
      final allRes = await db
          .from('user_achievements')
          .select('xp_awarded, achievement_id, earned_at')
          .eq('user_id', userId)
          .order('earned_at', ascending: false)
          .limit(20);
      list = (allRes as List).cast<Map<String, dynamic>>();
      isAllTime = true;
    }
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: kind,
        title: kind == ShareableKind.milestones ? 'Milestones' : 'Achievements',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final totalXp = list.fold<int>(
        0, (s, a) => s + ((a['xp_awarded'] as num?)?.toInt() ?? 0));

    final highlights = <ShareableMetric>[
      ShareableMetric(label: 'EARNED', value: list.length.toString()),
      ShareableMetric(
          label: isAllTime ? 'TOTAL XP' : 'XP THIS MONTH',
          value: totalXp.toString()),
      if (list.isNotEmpty)
        ShareableMetric(
          label: 'LATEST',
          value:
              (list.first['achievement_id'] as String? ?? 'Unknown').toString(),
        ),
    ];

    return Shareable(
      kind: kind,
      title:
          kind == ShareableKind.milestones ? 'Milestones' : 'Achievements',
      periodLabel: isAllTime ? 'ALL TIME' : period,
      heroValue: list.length,
      heroUnitSingular: kind == ShareableKind.milestones ? 'milestone' : 'badge',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Progress Charts ───────────────────────────────────────────────

  static Future<Shareable?> _progressCharts({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final res = await db
        .from('workouts')
        .select('id, duration_minutes, completed_at')
        .eq('user_id', userId)
        .eq('is_completed', true)
        .gte('completed_at', monthStart.toIso8601String())
        .lt('completed_at', monthEnd.toIso8601String());
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.progressCharts,
        title: 'Progress Charts',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final totalMin = list.fold<int>(
        0, (s, w) => s + ((w['duration_minutes'] as num?)?.toInt() ?? 0));
    final daySet = list
        .map((w) => DateTime.tryParse(w['completed_at'] as String))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    final highlights = [
      ShareableMetric(label: 'WORKOUTS', value: list.length.toString()),
      ShareableMetric(label: 'DAYS', value: daySet.length.toString()),
      ShareableMetric(label: 'TIME', value: _fmtMinutes(totalMin)),
    ];

    return Shareable(
      kind: ShareableKind.progressCharts,
      title: 'Progress Charts',
      periodLabel: period,
      heroValue: list.length,
      heroUnitSingular: 'workout',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Body Measurements ─────────────────────────────────────────────

  static Future<Shareable?> _bodyMeasurements({
    required String userId,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final res = await db
        .from('body_measurements')
        .select('weight_kg, body_fat_percent, measured_at')
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(30);
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.bodyMeasurements,
        title: 'Body Measurements',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    final last = (list.first['weight_kg'] as num?)?.toDouble() ?? 0;
    final earlier =
        list.length > 1 ? (list.last['weight_kg'] as num?)?.toDouble() ?? 0 : last;
    final delta = last - earlier;

    final highlights = [
      ShareableMetric(
        label: 'WEIGHT',
        value: '${last.toStringAsFixed(1)} kg',
      ),
      ShareableMetric(
        label: 'DELTA',
        value:
            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
      ),
      if (list.first['body_fat_percent'] != null)
        ShareableMetric(
          label: 'BODY FAT',
          value:
              '${(list.first['body_fat_percent'] as num).toStringAsFixed(1)}%',
        ),
    ];

    return Shareable(
      kind: ShareableKind.bodyMeasurements,
      title: 'Body Measurements',
      periodLabel: period,
      heroValue: last.round(),
      heroUnitSingular: 'kg',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── Nutrition ─────────────────────────────────────────────────────

  static Future<Shareable?> _nutrition({
    required String userId,
    required DateTime month,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final res = await db
        .from('food_logs')
        .select('total_calories, protein_g, carbs_g, fat_g, logged_at')
        .eq('user_id', userId)
        .gte('logged_at', monthStart.toIso8601String())
        .lt('logged_at', monthEnd.toIso8601String());
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return _starterFallback(
        userId: userId,
        kind: ShareableKind.nutrition,
        title: 'Nutrition',
        period: period,
        displayName: displayName,
        accent: accent,
      );
    }

    num total(String key) =>
        list.fold<num>(0, (s, r) => s + ((r[key] as num?) ?? 0));
    final cal = total('total_calories');
    final p = total('protein_g');
    final c = total('carbs_g');
    final f = total('fat_g');
    final daySet = list
        .map((r) => DateTime.tryParse(r['logged_at'] as String))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final avgCal = daySet.isEmpty ? 0 : cal ~/ daySet.length;

    final highlights = [
      ShareableMetric(label: 'PROTEIN', value: '${p.round()}g'),
      ShareableMetric(label: 'CARBS', value: '${c.round()}g'),
      ShareableMetric(label: 'FAT', value: '${f.round()}g'),
      ShareableMetric(label: 'DAYS LOGGED', value: daySet.length.toString()),
    ];

    return Shareable(
      kind: ShareableKind.nutrition,
      title: 'Nutrition',
      periodLabel: period,
      heroValue: avgCal,
      heroUnitSingular: 'kcal',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── unified starter fallback ─────────────────────────────────────
  //
  // Single fallback used by every adapter when its rich data path turns
  // up empty. Per user: "why would they use independent gates, it all
  // must be unified" — the share button must NEVER bounce the user with
  // "Not enough data". Worst case we return a minimal "starter" share
  // with whatever signal the user has (completed-workout count, earliest
  // workout date, app-join date), kind-tagged so each report still
  // renders its own template.
  //
  // Returns null only if Supabase auth is not present (caller already
  // handles that case before dispatching).
  static Future<Shareable?> _starterFallback({
    required String userId,
    required ShareableKind kind,
    required String title,
    required String period,
    required String? displayName,
    required Color accent,
  }) async {
    final db = Supabase.instance.client;

    // Pull a thin user signal: completed workouts count + first completion.
    // Two cheap queries; if both fail or return nothing, we still render
    // the share with a "Day 1" framing rather than bouncing the user.
    int workoutCount = 0;
    DateTime? firstCompleted;
    int totalMin = 0;
    try {
      final res = await db
          .from('workouts')
          .select('id, duration_minutes, completed_at, scheduled_date')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: true)
          .limit(50);
      final list = (res as List).cast<Map<String, dynamic>>();
      workoutCount = list.length;
      totalMin = list.fold<int>(
          0, (s, w) => s + ((w['duration_minutes'] as num?)?.toInt() ?? 0));
      for (final w in list) {
        final c = w['completed_at'] as String?;
        final s = w['scheduled_date'] as String?;
        final dt = (c != null && c.isNotEmpty)
            ? DateTime.tryParse(c)
            : (s != null && s.isNotEmpty ? DateTime.tryParse(s) : null);
        if (dt != null) {
          firstCompleted ??= dt;
          break;
        }
      }
    } catch (_) {
      // Network/permission failure → still render the share with zeros
      // rather than bouncing. The template handles count==0 gracefully.
    }

    final daysSinceStart = firstCompleted == null
        ? 0
        : DateTime.now().difference(firstCompleted).inDays + 1;

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'WORKOUTS',
        value: workoutCount.toString(),
        icon: Icons.fitness_center_rounded,
      ),
      if (totalMin > 0)
        ShareableMetric(
          label: 'TOTAL TIME',
          value: _fmtMinutes(totalMin),
          icon: Icons.timer_outlined,
          accent: AppColors.success,
        ),
      if (daysSinceStart > 0)
        ShareableMetric(
          label: daysSinceStart == 1 ? 'DAY' : 'DAYS IN',
          value: daysSinceStart.toString(),
          icon: Icons.calendar_today_rounded,
          accent: AppColors.purple,
        ),
    ];

    return Shareable(
      kind: kind,
      title: title,
      periodLabel: workoutCount > 0 ? 'JUST STARTED' : 'DAY 1',
      heroValue: workoutCount,
      heroUnitSingular: 'workout',
      highlights: highlights,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  // ─── helpers ───────────────────────────────────────────────────────

  static int _consecutiveDayStreak(List<DateTime> sortedDescDays) {
    if (sortedDescDays.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (sortedDescDays.first != today &&
        sortedDescDays.first != yesterday) {
      return 0;
    }
    int streak = 1;
    for (var i = 1; i < sortedDescDays.length; i++) {
      final expected =
          sortedDescDays[i - 1].subtract(const Duration(days: 1));
      if (sortedDescDays[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static String _fmtMinutes(int m) {
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }
}
