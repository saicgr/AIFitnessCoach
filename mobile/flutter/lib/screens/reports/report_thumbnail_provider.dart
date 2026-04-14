import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/user_provider.dart';

/// Thumbnail summary shown on a report's hub card.
///
/// Keep payloads tiny — these render inside ~300×400 cards. Two strings is
/// the right shape: a hero number/label, plus a one-liner caption.
class ReportThumbnailData {
  final String primary;
  final String? secondary;

  const ReportThumbnailData({required this.primary, this.secondary});
}

/// Key for the thumbnail family. Equality is by route + (year, month) so the
/// provider cache survives day-to-day rebuilds within the same month.
class ReportThumbnailKey {
  final String route;
  final DateTime month;

  const ReportThumbnailKey({required this.route, required this.month});

  @override
  bool operator ==(Object other) =>
      other is ReportThumbnailKey &&
      other.route == route &&
      other.month.year == month.year &&
      other.month.month == month.month;

  @override
  int get hashCode => Object.hash(route, month.year, month.month);
}

/// Returns a tiny stat summary for one (report, month) pair, or `null` when
/// there's no data for that bucket — which the card uses to fall back to the
/// generic "View report" placeholder. Errors silently return null so a slow
/// or failing query never blocks the UI from rendering the placeholder.
final reportThumbnailProvider =
    FutureProvider.family<ReportThumbnailData?, ReportThumbnailKey>(
        (ref, key) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final monthStart = DateTime(key.month.year, key.month.month, 1);
  final monthEnd = DateTime(key.month.year, key.month.month + 1, 1);
  final monthStartIso = monthStart.toIso8601String();
  final monthEndIso = monthEnd.toIso8601String();
  final monthStartDate = monthStartIso.substring(0, 10);
  final monthEndDate = monthEndIso.substring(0, 10);
  final db = Supabase.instance.client;

  try {
    switch (key.route) {
      case '/summaries':
        final res = await db
            .from('workouts')
            .select('duration_minutes')
            .eq('user_id', userId)
            .gte('completed_at', monthStartIso)
            .lt('completed_at', monthEndIso)
            .eq('is_completed', true);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final totalMin = list.fold<int>(
            0, (s, w) => s + ((w['duration_minutes'] as num?)?.toInt() ?? 0));
        final h = totalMin ~/ 60;
        final m = totalMin % 60;
        return ReportThumbnailData(
          primary: '${list.length} workouts',
          secondary: 'Logged ${h}h ${m}m',
        );

      case '/stats/personal-records':
        final res = await db
            .from('personal_records')
            .select('exercise_name')
            .eq('user_id', userId)
            .gte('achieved_at', monthStartIso)
            .lt('achieved_at', monthEndIso);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final lifts = list.map((r) => r['exercise_name']).toSet().length;
        return ReportThumbnailData(
          primary: '${list.length} PRs',
          secondary: 'Across $lifts lifts',
        );

      case '/stats/muscle-analytics':
        final res = await db
            .from('strength_scores')
            .select('strength_score')
            .eq('user_id', userId)
            .gte('period_start', monthStartDate)
            .lt('period_start', monthEndDate);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final scores =
            list.map((r) => (r['strength_score'] as num).toInt()).toList();
        final avg = scores.reduce((a, b) => a + b) ~/ scores.length;
        return ReportThumbnailData(
          primary: '$avg / 100',
          secondary: '${scores.length} muscle groups',
        );

      case '/settings/my-1rms':
        final res = await db
            .from('strength_records')
            .select('exercise_name, estimated_1rm')
            .eq('user_id', userId)
            .order('estimated_1rm', ascending: false)
            .limit(1);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final top = list.first;
        return ReportThumbnailData(
          primary: '${(top['estimated_1rm'] as num).toStringAsFixed(0)} kg',
          secondary: 'Best: ${top['exercise_name']}',
        );

      case '/stats/exercise-history':
        final res = await db
            .from('performance_logs')
            .select('exercise_id')
            .eq('user_id', userId)
            .gte('recorded_at', monthStartIso)
            .lt('recorded_at', monthEndIso);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final exercises = list.map((r) => r['exercise_id']).toSet().length;
        return ReportThumbnailData(
          primary: '$exercises exercises',
          secondary: '${list.length} sets logged',
        );

      case '/stats/milestones':
      case '/achievements':
        final res = await db
            .from('user_achievements')
            .select('xp_awarded')
            .eq('user_id', userId)
            .gte('earned_at', monthStartIso)
            .lt('earned_at', monthEndIso);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final xp = list.fold<int>(
            0, (s, a) => s + ((a['xp_awarded'] as num?)?.toInt() ?? 0));
        return ReportThumbnailData(
          primary: '${list.length} earned',
          secondary: '$xp XP this month',
        );

      case '/progress-charts':
        // weekly_volumes don't carry a date; filter by year + ISO week range
        // that overlaps the month. Cheap upper-bound: fetch all weeks for the
        // year and filter client-side by week number derived from monthStart.
        final res = await db
            .from('weekly_volumes')
            .select('total_volume_kg, week_number')
            .eq('user_id', userId)
            .eq('year', key.month.year);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        // Approximate ISO week range for the month (good enough for a card).
        final firstWeek = _weekOfYear(monthStart);
        final lastWeek = _weekOfYear(
            DateTime(monthEnd.year, monthEnd.month, monthEnd.day - 1));
        final inMonth = list.where((r) {
          final w = (r['week_number'] as num?)?.toInt() ?? -1;
          return w >= firstWeek && w <= lastWeek;
        }).toList();
        if (inMonth.isEmpty) return null;
        final volume = inMonth.fold<double>(
            0,
            (s, w) =>
                s + ((w['total_volume_kg'] as num?)?.toDouble() ?? 0));
        return ReportThumbnailData(
          primary: '${(volume / 1000).toStringAsFixed(1)}t',
          secondary: 'Total volume',
        );

      case '/measurements':
        final res = await db
            .from('body_measurements')
            .select('weight_kg, measured_at')
            .eq('user_id', userId)
            .gte('measured_at', monthStartIso)
            .lt('measured_at', monthEndIso)
            .not('weight_kg', 'is', null)
            .order('measured_at', ascending: true);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final first = (list.first['weight_kg'] as num).toDouble();
        final last = (list.last['weight_kg'] as num).toDouble();
        final delta = last - first;
        final sign = delta >= 0 ? '+' : '';
        return ReportThumbnailData(
          primary: '${last.toStringAsFixed(1)} kg',
          secondary: '$sign${delta.toStringAsFixed(1)} kg this month',
        );

      case '/stats/readiness':
        final res = await db
            .from('readiness_scores')
            .select('readiness_score')
            .eq('user_id', userId)
            .gte('score_date', monthStartDate)
            .lt('score_date', monthEndDate);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final scores =
            list.map((r) => (r['readiness_score'] as num).toInt()).toList();
        final avg = scores.reduce((a, b) => a + b) ~/ scores.length;
        return ReportThumbnailData(
          primary: '$avg / 100',
          secondary: '${scores.length} days tracked',
        );

      case '/nutrition':
        final res = await db
            .from('nutrition_scores')
            .select('adherence_percent, days_logged')
            .eq('user_id', userId)
            .gte('week_start', monthStartDate)
            .lt('week_start', monthEndDate);
        final list = (res as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return null;
        final adh = (list
                    .map((r) => (r['adherence_percent'] as num).toDouble())
                    .reduce((a, b) => a + b) /
                list.length)
            .round();
        final days = list.fold<int>(
            0, (s, r) => s + ((r['days_logged'] as num?)?.toInt() ?? 0));
        return ReportThumbnailData(
          primary: '$adh% adherence',
          secondary: '$days days logged',
        );
    }
  } catch (_) {
    // Soft-fail — card falls back to placeholder. Keeps the hub usable
    // when one report's table is misconfigured / RLS-blocked.
    return null;
  }
  return null;
});

/// ISO week-of-year. Used as an approximation to map weekly_volumes rows
/// (keyed by year + week_number) to a calendar month.
int _weekOfYear(DateTime d) {
  final thursday = d.add(Duration(days: 4 - (d.weekday)));
  final firstThursday =
      DateTime(thursday.year, 1, 1).add(Duration(days: (4 - DateTime(thursday.year, 1, 1).weekday + 7) % 7));
  return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
}
