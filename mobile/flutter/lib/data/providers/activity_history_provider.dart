/// Per-day activity history (steps / resting-HR / calories / sleep) for the
/// last N days, sourced from `GET /api/v1/activity/history/{userId}`.
///
/// Powers the inline sparklines on the Home "Today's Health" card and the
/// per-day trailing-trend rail in the Home timeline. Read-only: the activity
/// rows are written by the device→backend sync (`activity_service`); we only
/// fetch the recorded history here.
///
/// Returns an empty list (never throws) when there's no session, no data, or
/// the request fails — every consumer self-hides on empty so the UI degrades
/// to "no sparkline" rather than an error.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/user_provider.dart';
import '../services/api_client.dart';

/// One day of recorded activity. Only the fields the sparklines need are
/// parsed; the endpoint returns more.
@immutable
class ActivityHistoryDay {
  final DateTime date; // date-only (local midnight)
  final int steps;
  final int? restingHeartRate;
  final double caloriesBurned;
  final int? sleepMinutes;

  const ActivityHistoryDay({
    required this.date,
    required this.steps,
    required this.restingHeartRate,
    required this.caloriesBurned,
    required this.sleepMinutes,
  });

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static ActivityHistoryDay? fromJson(Map<String, dynamic> j) {
    final raw = j['activity_date'];
    DateTime? parsed;
    if (raw is String) parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return ActivityHistoryDay(
      date: _dateOnly(parsed),
      steps: (j['steps'] as num?)?.toInt() ?? 0,
      restingHeartRate: (j['resting_heart_rate'] as num?)?.toInt(),
      caloriesBurned: (j['calories_burned'] as num?)?.toDouble() ?? 0,
      sleepMinutes: (j['sleep_minutes'] as num?)?.toInt(),
    );
  }
}

/// Last-30-day activity history, sorted OLDEST → NEWEST (chart-friendly).
/// `keepAlive` so scrolling Home / switching tabs doesn't refetch; the device
/// sync keeps the underlying rows fresh.
final activityHistoryProvider =
    FutureProvider.autoDispose<List<ActivityHistoryDay>>((ref) async {
  ref.keepAlive();
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return const [];
  // Use the APP user id (public.users.id), NOT the Supabase auth `sub`. The
  // /activity/history/{user_id} endpoint authorizes against current_user["id"]
  // (the app id), so passing the auth sub here 403s. This is the same id source
  // fasting/consistency callers use.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get(
      '/activity/history/$userId',
      queryParameters: {'limit': 30},
    );
    final data = res.data;
    if (data is! List) return const [];
    final out = <ActivityHistoryDay>[];
    for (final e in data) {
      if (e is Map<String, dynamic>) {
        final day = ActivityHistoryDay.fromJson(e);
        if (day != null) out.add(day);
      }
    }
    // Endpoint returns newest-first; sort ascending for left→right charts.
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  } catch (e) {
    debugPrint('⚠️ [ActivityHistory] fetch failed: $e');
    return const [];
  }
});
