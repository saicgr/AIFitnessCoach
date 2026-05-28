/// Upstream-signal providers for previously-dormant home cards.
///
/// One provider per backend endpoint added in `backend/api/v1/home_signals.py`:
///   - `sleepTargetProvider`             → GET /users/me/sleep-target
///   - `todayWorkoutScheduleProvider`    → GET /workouts/today/schedule
///   - `plannedVsActualProvider(id)`     → GET /workouts/{id}/planned-vs-actual
///   - `wearableBatteryProvider`         → GET /wearables/battery
///   - `proposedRescheduleSlotProvider(id)` → GET /workouts/proposed-reschedule-slot
///
/// All providers are `autoDispose`, return null on auth/network failure
/// (cards self-collapse), and never silently invent data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../services/api_client.dart';

// ---------------------------------------------------------------------------
// Bedtime window
// ---------------------------------------------------------------------------
class SleepTarget {
  final int targetSleepMinutes;
  final String? wakeAlarmLocalTime; // HH:mm
  final String? derivedBedtimeLocalTime; // HH:mm

  const SleepTarget({
    required this.targetSleepMinutes,
    required this.wakeAlarmLocalTime,
    required this.derivedBedtimeLocalTime,
  });

  factory SleepTarget.fromJson(Map<String, dynamic> j) => SleepTarget(
        targetSleepMinutes: (j['target_sleep_minutes'] as num?)?.toInt() ?? 480,
        wakeAlarmLocalTime: j['wake_alarm_local_time'] as String?,
        derivedBedtimeLocalTime: j['derived_bedtime_local_time'] as String?,
      );
}

final sleepTargetProvider =
    FutureProvider.autoDispose<SleepTarget?>((ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>('/users/me/sleep-target');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return SleepTarget.fromJson(data);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Today schedule (HH:mm for the T-30 + pre-workout-fuel cards)
// ---------------------------------------------------------------------------
class TodayWorkoutSchedule {
  final String? workoutId;
  final String? scheduledLocalTime; // HH:mm
  const TodayWorkoutSchedule(
      {required this.workoutId, required this.scheduledLocalTime});
}

final todayWorkoutScheduleProvider =
    FutureProvider.autoDispose<TodayWorkoutSchedule?>((ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>('/workouts/today/schedule');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return TodayWorkoutSchedule(
      workoutId: data['workout_id'] as String?,
      scheduledLocalTime: data['scheduled_local_time'] as String?,
    );
  } catch (_) {
    return null;
  }
});

/// Helper — given an "HH:mm" string and a "now" DateTime, returns the number
/// of minutes from now until that time TODAY (negative if it has already
/// passed). Returns null on parse failure.
int? minutesUntilLocal(String? hhmm, DateTime now) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final target = DateTime(now.year, now.month, now.day, h, m);
  return target.difference(now).inMinutes;
}

// ---------------------------------------------------------------------------
// Planned vs actual
// ---------------------------------------------------------------------------
class PlannedVsActual {
  final int? plannedSets;
  final int? actualSets;
  final int? plannedDurationMin;
  final int? actualDurationMin;
  final double? deltaPct;

  const PlannedVsActual({
    required this.plannedSets,
    required this.actualSets,
    required this.plannedDurationMin,
    required this.actualDurationMin,
    required this.deltaPct,
  });

  factory PlannedVsActual.fromJson(Map<String, dynamic> j) => PlannedVsActual(
        plannedSets: (j['planned_sets'] as num?)?.toInt(),
        actualSets: (j['actual_sets'] as num?)?.toInt(),
        plannedDurationMin: (j['planned_duration_min'] as num?)?.toInt(),
        actualDurationMin: (j['actual_duration_min'] as num?)?.toInt(),
        deltaPct: (j['delta_pct'] as num?)?.toDouble(),
      );

  bool get hasAnySignal =>
      plannedSets != null ||
      actualSets != null ||
      plannedDurationMin != null ||
      actualDurationMin != null;
}

final plannedVsActualProvider =
    FutureProvider.autoDispose.family<PlannedVsActual?, String>(
        (ref, workoutId) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
        '/workouts/$workoutId/planned-vs-actual');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return PlannedVsActual.fromJson(data);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Wearable battery
// ---------------------------------------------------------------------------
class WearableBattery {
  final String? source;
  final int? batteryPct;
  final String? lastSyncedAt;
  const WearableBattery({
    required this.source,
    required this.batteryPct,
    required this.lastSyncedAt,
  });
}

final wearableBatteryProvider =
    FutureProvider.autoDispose<WearableBattery?>((ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>('/wearables/battery');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final count = (data['count'] as num?)?.toInt() ?? 0;
    if (count == 0) return null;
    return WearableBattery(
      source: data['source'] as String?,
      batteryPct: (data['battery_pct'] as num?)?.toInt(),
      lastSyncedAt: data['last_synced_at'] as String?,
    );
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Proposed reschedule slot
// ---------------------------------------------------------------------------
class ProposedRescheduleSlot {
  final String? proposedDate; // ISO
  final String? proposedWorkoutId;
  const ProposedRescheduleSlot({
    required this.proposedDate,
    required this.proposedWorkoutId,
  });

  bool get hasDate => proposedDate != null && proposedDate!.isNotEmpty;
}

final proposedRescheduleSlotProvider =
    FutureProvider.autoDispose.family<ProposedRescheduleSlot?, String>(
        (ref, workoutId) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
        '/workouts/proposed-reschedule-slot',
        queryParameters: {'workout_id': workoutId});
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final date = data['proposed_date'] as String?;
    if (date == null || date.isEmpty) return null;
    return ProposedRescheduleSlot(
      proposedDate: date,
      proposedWorkoutId: data['proposed_workout_id'] as String?,
    );
  } catch (_) {
    return null;
  }
});
