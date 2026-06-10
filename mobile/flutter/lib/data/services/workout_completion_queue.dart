import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/cache/offline_write_queue.dart';
import '../../core/providers/workout_mutation_coordinator.dart';
import 'api_client.dart';

/// Single owner of the disk-persisted offline queue for workout-completion
/// POSTs (`POST /workouts/{id}/complete`).
///
/// Completion is two independent writes: the workout_log + per-set rows (which
/// save reliably), and the separate `/complete` call that flips
/// `workouts.is_completed` (the ONLY thing the Home/Workout UI reads to decide
/// "done vs upcoming"). When that second call fails, the completion is enqueued
/// here and replayed on TWO triggers:
///
///   1. connectivity restored — [OfflineWriteQueue.bindConnectivity], armed on
///      enqueue; and
///   2. **app launch / foreground resume** — [flush], wired from `app.dart`.
///
/// Trigger (2) closes the gap that stranded a finished workout for two days: a
/// `/complete` that failed WHILE ONLINE enqueued fine, but the device never
/// went offline→online again, so the connectivity-only flush never fired. A
/// DB-side trigger (migration 2256) is the durable backstop; this is the client
/// path that also re-fires `/complete` so its server side-effects (PRs / XP /
/// score recalc) still land.
///
/// The shared disk slot is keyed `offline_wq::workout_complete::<userId>`, so
/// this single instance owns exactly the rows the completion flow enqueues.
class WorkoutCompletionQueue {
  WorkoutCompletionQueue._();
  static final WorkoutCompletionQueue instance = WorkoutCompletionQueue._();

  static const String feature = 'workout_complete';
  final OfflineWriteQueue _queue = OfflineWriteQueue(feature: feature);

  /// Replay sender bound to [apiClient]. Returns `true` on a 2xx (drop from
  /// queue) or on a poison row (missing id); `false` on a transient failure
  /// (offline / 5xx / timeout) so the flush stops and keeps the item queued.
  /// On success it refreshes Home + Workout tabs via the root container so a
  /// late replay is never silent.
  Future<bool> Function(Map<String, dynamic>) _sender(ApiClient apiClient) {
    return (Map<String, dynamic> body) async {
      try {
        final wid = body['workout_id'] as String?;
        if (wid == null) return true; // poison item — drop it
        final resp = await apiClient.post(
          '/workouts/$wid/complete',
          data: {'idempotency_key': body['idempotency_key']},
        );
        final ok = resp.statusCode != null &&
            resp.statusCode! >= 200 &&
            resp.statusCode! < 300;
        if (ok) {
          unawaited(refreshAfterWorkoutMutation(
              source: 'completion_queue_flush', workoutId: wid));
        }
        return ok; // server de-dupes a replay via the idempotency key
      } catch (_) {
        return false; // transient — keep queued, stop the flush
      }
    };
  }

  /// Enqueue a failed completion for later replay and arm the
  /// connectivity-restored flush. The idempotency key rides on the body so a
  /// replay can never double-complete (server de-dupes; the DB trigger is also
  /// idempotent).
  Future<void> enqueue({
    required String userId,
    required String workoutId,
    required ApiClient apiClient,
  }) async {
    final body = <String, dynamic>{
      'workout_id': workoutId,
      'idempotency_key': OfflineWriteQueue.idempotencyKey('wkout_complete'),
    };
    await _queue.enqueue(userId: userId, body: body);
    _queue.bindConnectivity(userId: userId, sender: _sender(apiClient));
  }

  /// Drain any queued completions now. Call on app launch + on
  /// `AppLifecycleState.resumed`. Cheap no-op when the queue is empty; never
  /// throws. Re-arms the connectivity flush in case items remain after a
  /// transient stop.
  Future<void> flush({
    required String userId,
    required ApiClient apiClient,
  }) async {
    try {
      if (await _queue.isEmpty(userId)) return;
      debugPrint('📤 [WorkoutCompletionQueue] launch/resume drain…');
      await _queue.flush(userId: userId, sender: _sender(apiClient));
      _queue.bindConnectivity(userId: userId, sender: _sender(apiClient));
    } catch (e) {
      debugPrint('⚠️ [WorkoutCompletionQueue] flush failed: $e');
    }
  }
}
