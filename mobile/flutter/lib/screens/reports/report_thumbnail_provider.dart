import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() => {'primary': primary, 'secondary': secondary};

  factory ReportThumbnailData.fromJson(Map<String, dynamic> json) =>
      ReportThumbnailData(
        primary: json['primary'] as String? ?? '',
        secondary: json['secondary'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Disk stale-while-revalidate for report-hub thumbnails.
//
// `reportThumbnailProvider` is a FutureProvider.family — its in-memory cache
// dies on every cold start, so each hub card used to re-hit Supabase before
// it could show a live stat. Persisting the tiny 2-string payload to
// SharedPreferences lets a cold open paint last-known thumbnails instantly,
// then silently revalidate. 12 h TTL — these are month-bucketed stats that
// only drift as the user logs more activity within the month.
// ---------------------------------------------------------------------------
const String _kThumbDiskPrefix = 'report_thumb::v1';
const Duration _kThumbDiskTtl = Duration(hours: 12);

String _thumbDiskKey(String userId, ReportThumbnailKey key) =>
    '$_kThumbDiskPrefix::$userId::${key.route}::${key.month.year}-${key.month.month}';

/// Read a persisted thumbnail. Returns null on miss / expiry / corruption.
/// A stored `null` payload (the query legitimately found no data) is encoded
/// as `{"empty": true}` so we can cache "no data" too and skip the re-query.
Future<({bool hit, ReportThumbnailData? data})> _readThumbDisk(
    String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return (hit: false, data: null);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return (hit: false, data: null);
    final cachedAt = decoded['cachedAt'];
    if (cachedAt is! int) return (hit: false, data: null);
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age < 0 || age >= _kThumbDiskTtl.inMilliseconds) {
      await prefs.remove(key);
      return (hit: false, data: null);
    }
    final body = decoded['data'];
    if (body is Map<String, dynamic> && body['empty'] == true) {
      return (hit: true, data: null);
    }
    if (body is Map<String, dynamic>) {
      return (hit: true, data: ReportThumbnailData.fromJson(body));
    }
    return (hit: false, data: null);
  } catch (e) {
    debugPrint('💾 [ReportThumb] disk read failed: $e');
    return (hit: false, data: null);
  }
}

/// Write-through a thumbnail (or an explicit "no data" marker). Best-effort.
Future<void> _writeThumbDisk(String key, ReportThumbnailData? data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data?.toJson() ?? {'empty': true},
      }),
    );
  } catch (e) {
    debugPrint('💾 [ReportThumb] disk write failed: $e');
  }
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

  // Cold-start cache-first: a fresh disk blob (within the 12 h TTL) is
  // returned immediately and the Supabase round-trip is skipped entirely —
  // these are month-bucketed stats, so a few hours of staleness is fine and
  // the hub card paints its live number instantly on a cold open. A stale /
  // missing blob falls through to the live query + write-through below.
  final diskKey = _thumbDiskKey(userId, key);
  final disk = await _readThumbDisk(diskKey);
  if (disk.hit) return disk.data;

  final monthStart = DateTime(key.month.year, key.month.month, 1);
  final monthEnd = DateTime(key.month.year, key.month.month + 1, 1);
  final monthStartIso = monthStart.toIso8601String();
  final monthEndIso = monthEnd.toIso8601String();
  final monthStartDate = monthStartIso.substring(0, 10);
  final monthEndDate = monthEndIso.substring(0, 10);
  final db = Supabase.instance.client;

  // Runs the live Supabase query for this (report, month). Extracted so the
  // single write-through below covers every report branch without having to
  // touch each individual `return`.
  Future<ReportThumbnailData?> runQuery() async {
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
    return null;
  }

  try {
    final result = await runQuery();
    // Write-through so the next cold start renders this card instantly.
    // A null result (no data this month) is cached too — see _writeThumbDisk.
    await _writeThumbDisk(diskKey, result);
    return result;
  } catch (_) {
    // Soft-fail — card falls back to placeholder. Keeps the hub usable
    // when one report's table is misconfigured / RLS-blocked. Not cached so
    // a transient failure retries on the next open.
    return null;
  }
});

/// ISO week-of-year. Used as an approximation to map weekly_volumes rows
/// (keyed by year + week_number) to a calendar month.
int _weekOfYear(DateTime d) {
  final thursday = d.add(Duration(days: 4 - (d.weekday)));
  final firstThursday =
      DateTime(thursday.year, 1, 1).add(Duration(days: (4 - DateTime(thursday.year, 1, 1).weekday + 7) % 7));
  return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
}
