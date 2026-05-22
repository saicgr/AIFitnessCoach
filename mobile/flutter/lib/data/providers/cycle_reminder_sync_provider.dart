import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hormonal_health.dart';
import '../services/notification_service.dart';
import 'hormonal_health_provider.dart';

/// Bridges the cycle prediction (Phase B) to the cycle reminders (Phase E).
///
/// The date-anchored cycle reminders (period-approaching / start / fertile /
/// peak / late) are scheduled against cached ISO dates in SharedPreferences.
/// Those dates have to be kept fresh whenever a new `CyclePrediction` arrives
/// — a new period logged, the server prediction refreshed, the mode changed.
///
/// Rather than bake a notification side-effect into the Phase-B prediction
/// provider (which another agent owns), this provider OWNS that wiring: a
/// screen that shows cycle data simply `ref.watch`es [cycleReminderSyncProvider]
/// once and the cached reminder dates stay in lockstep with the prediction.
///
/// It is a no-op when there is no prediction or predictions are unavailable.
final cycleReminderSyncProvider = Provider.autoDispose<void>((ref) {
  final predictionAsync = ref.watch(cyclePredictionProvider);
  final prediction = predictionAsync.value;
  if (prediction == null) return;

  // Reading the StateNotifierProvider here is safe: it is overridden with
  // SharedPreferences at app start. If it somehow is not yet ready we just
  // skip — the next prediction emission retries.
  final NotificationPreferencesNotifier notifier;
  try {
    notifier = ref.read(notificationPreferencesProvider.notifier);
  } catch (e) {
    debugPrint('⚠️ [CycleReminderSync] notifier not ready: $e');
    return;
  }

  _syncPredictionToReminders(prediction, notifier);
});

/// Push the prediction's anchor dates into the notification service so the
/// cycle reminders reschedule against the latest forecast.
///
/// The "late" reminder is anchored to the day AFTER the prediction window
/// ends (`nextPeriodWindowEnd` + 1) — that is the first day the period is
/// genuinely past its expected band. When the prediction already reports the
/// period as late, the late reminder date is dropped (it would be in the
/// past) and a fresh prediction will re-anchor it after the next period.
void _syncPredictionToReminders(
  CyclePrediction prediction,
  NotificationPreferencesNotifier notifier,
) {
  String? iso(DateTime? d) {
    if (d == null) return null;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // No forecast → clear the anchored reminders (daily BBT/symptom unaffected).
  if (!prediction.predictionsAvailable) {
    notifier.updateCyclePredictionDates(
      nextPeriodDate: null,
      fertileWindowStart: null,
      peakFertilityStart: null,
      predictedLateDate: null,
      trackingMode: prediction.trackingMode.value,
    );
    return;
  }

  final lateDate =
      prediction.nextPeriodWindowEnd?.add(const Duration(days: 1));

  notifier.updateCyclePredictionDates(
    nextPeriodDate: iso(prediction.nextPeriodDate),
    fertileWindowStart: iso(prediction.fertileWindowStart),
    peakFertilityStart: iso(prediction.peakFertilityStart),
    // Drop a late date that is already in the past — the reminder would
    // never fire and a fresh prediction re-anchors it next cycle.
    predictedLateDate: prediction.isLate ? null : iso(lateDate),
    trackingMode: prediction.trackingMode.value,
  );
}
