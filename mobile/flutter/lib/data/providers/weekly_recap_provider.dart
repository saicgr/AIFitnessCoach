import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_recap.dart';
import '../services/api_client.dart';

/// Compute the ISO year-week identifier for a local DateTime. Used as the
/// SharedPreferences ack key so each week's recap fires at most once per
/// device. Format: "YYYY-Wxx" (e.g. "2026-W16").
String isoWeekKey(DateTime local) {
  // Roll to Monday of the same ISO week
  final monday = local.subtract(Duration(days: local.weekday - 1));
  // ISO week number calculation (Thursday-based)
  final thursday = monday.add(const Duration(days: 3));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstMonday =
      firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
  final week = ((thursday.difference(firstMonday).inDays) / 7).floor() + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

/// Returns true when the user's local device time is past Monday 06:00 of
/// the current ISO week. The recap modal uses this as its "ready-to-fire"
/// gate — we don't want to wake users at 12:05 AM on Monday.
bool isPastMondayMorning(DateTime now) {
  // Find Monday 06:00 of the current ISO week. If `now` is before that
  // Monday-6am moment, we wait; otherwise it's ready.
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final monday6am =
      DateTime(monday.year, monday.month, monday.day, 6, 0);
  return !now.isBefore(monday6am);
}

/// Cache key for "user has seen this week's recap on this device".
String _prefKeyForWeek(String weekKey) => 'weekly_recap_ack_$weekKey';

/// AsyncNotifier-style state holder for per-week ack. Writes through to
/// SharedPreferences so the ack survives app restarts.
class WeeklyRecapAckNotifier extends StateNotifier<Set<String>> {
  WeeklyRecapAckNotifier() : super(<String>{}) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((k) => k.startsWith('weekly_recap_ack_'))
          .map((k) => k.substring('weekly_recap_ack_'.length))
          .toSet();
      state = keys;
    } catch (_) {/* ignore — unhydrated ack defaults to empty */}
  }

  bool hasAcked(String weekKey) => state.contains(weekKey);

  Future<void> ack(String weekKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyForWeek(weekKey), true);
    } catch (_) {/* best-effort */}
    state = {...state, weekKey};
  }
}

final weeklyRecapAckProvider =
    StateNotifierProvider<WeeklyRecapAckNotifier, Set<String>>(
  (ref) => WeeklyRecapAckNotifier(),
);

/// Fetches the weekly recap payload for the default (previous complete)
/// ISO week. Auto-disposed so cold-starts retry; re-fetched when the user
/// switches board.
final weeklyRecapProvider =
    FutureProvider.autoDispose<WeeklyRecap?>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(
      '/leaderboard/weekly-recap',
      queryParameters: {'board': 'xp'},
    );
    return WeeklyRecap.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('weeklyRecapProvider failed: $e');
    return null;
  }
});

/// Gating provider consumed by MainShell. Returns the WeeklyRecap payload
/// if and only if:
///   1. Device local time is past Monday 06:00 of the current ISO week.
///   2. User hasn't already acknowledged this week's recap.
///   3. Recap contains meaningful content (ranked last week, or has awards).
/// Otherwise returns null.
final weeklyRecapGateProvider = Provider<WeeklyRecap?>((ref) {
  final now = DateTime.now();
  if (!isPastMondayMorning(now)) return null;

  final weekKey = isoWeekKey(now);
  final acked = ref.watch(weeklyRecapAckProvider);
  if (acked.contains(weekKey)) return null;

  final recap = ref.watch(weeklyRecapProvider).valueOrNull;
  if (recap == null) return null;
  if (!recap.hasMeaningfulContent) return null;
  return recap;
});
