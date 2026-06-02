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

/// Sanity-guarded "active energy" calories, shared so every surface shows the
/// SAME number. Emulator / sample Health data routinely reports an active-energy
/// figure wildly inconsistent with steps (e.g. 2,179 kcal for 5,090 steps, when
/// ~0.04 kcal/step implies ~200). When the platform value is implausibly high vs
/// the step-derived estimate, fall back to the estimate so the figure is
/// consistent across the Today's Health card + NEAT screen and bogus platform
/// data is never presented as fact. Returns null only when there's no data at
/// all (so the UI can show "—").
int? trustedActiveCalories({required int steps, double? rawActiveCalories}) {
  final hasRaw = rawActiveCalories != null && rawActiveCalories > 0;
  if (steps <= 0 && !hasRaw) return null;
  final stepEst = (steps * 0.04).round();
  if (!hasRaw) return stepEst;
  // Plausible ceiling: up to ~10× the step estimate (cycling/other cardio adds
  // calories without steps), floored at 800 so low-step days aren't over-strict.
  final ceil = (stepEst * 10).clamp(800, 100000).toDouble();
  if (rawActiveCalories > ceil) {
    return stepEst > 0 ? stepEst : rawActiveCalories.round();
  }
  return rawActiveCalories.round();
}

/// Whether a day's activity has CORROBORATING intraday signal, or is just a
/// bare daily total with no supporting evidence (the emulator/sample-data
/// shape: a step total but 0 active hours + an empty hourly breakdown + an
/// implausible calorie figure). Surfaces use this to avoid celebrating a high
/// NEAT score off untrustworthy data.
bool activitySignalLooksReliable({
  required int steps,
  required int activeHours,
  required bool hourlyHasData,
  double? rawActiveCalories,
}) {
  if (activeHours > 0 || hourlyHasData) return true;
  // No intraday evidence at all → reliable only if there's simply no data to
  // doubt (steps 0). A non-zero step total with zero intraday signal is the
  // tell-tale sample-data shape → treat as unreliable.
  return steps <= 0;
}

/// Last-30-day activity history, sorted OLDEST → NEWEST (chart-friendly).
/// `keepAlive` so scrolling Home / switching tabs doesn't refetch; the device
/// sync keeps the underlying rows fresh.
final activityHistoryProvider =
    FutureProvider.autoDispose<List<ActivityHistoryDay>>((ref) async {
  ref.keepAlive();
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return const [];
  final userId = Supabase.instance.client.auth.currentUser?.id;
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
