import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/cache/offline_write_queue.dart';
import '../providers/root_messenger.dart';
import 'api_client.dart';

/// Single owner of the disk-persisted offline queue for the finish-time bulk
/// set-performance POST (`POST /performance/logs/bulk`).
///
/// E2E register row #169: a session's sets can be logged in-memory (green
/// tick, volume update, celebration banner all render) and the workout can
/// report "completed" normally, while the bulk write that turns those
/// in-memory sets into `performance_logs` rows silently fails — the workout
/// screen fires it with `unawaited(...)` and `WorkoutRepository
/// .logSetPerformancesBulk` swallows every error internally and returns `0`,
/// so the `.catchError` on the caller's Future never even runs. No exception
/// ever reaches anything that could retry or tell the user.
///
/// This queue makes that write durable the same way `WorkoutCompletionQueue`
/// already makes `/complete` durable: when the bulk POST inserts fewer rows
/// than were sent, the FULL record list is enqueued and replayed on
///
///   1. connectivity restored — [OfflineWriteQueue.bindConnectivity], armed on
///      enqueue; and
///   2. app launch / foreground resume — [flush], wired from `app.dart`.
///
/// Replaying the FULL list (not just the missing rows) is safe: `POST
/// /performance/logs/bulk` upserts on `(workout_log_id, exercise_name,
/// set_number)` (see `advanced_progressive_persistence.dart`), so re-sending
/// already-inserted rows is a no-op overwrite, not a duplicate.
///
/// The shared disk slot is keyed `offline_wq::set_performances_bulk::<userId>`.
class SetPerformanceQueue {
  SetPerformanceQueue._();
  static final SetPerformanceQueue instance = SetPerformanceQueue._();

  static const String feature = 'set_performances_bulk';
  final OfflineWriteQueue _queue = OfflineWriteQueue(feature: feature);

  /// True once [enqueue] has surfaced the "still syncing" toast, so a
  /// later successful drain can tell the user their sets landed — and so a
  /// retry that fails again doesn't re-show the same toast on every
  /// connectivity blip. Reset after the confirming toast fires.
  bool _pendingToastShown = false;

  /// Replay sender bound to [apiClient]. Returns `true` on a 2xx (drop from
  /// queue — the upsert contract makes re-sending already-inserted rows
  /// safe) or on a poison item (missing/malformed records); `false` on a
  /// transient failure (offline / 5xx / timeout) so the flush stops and
  /// keeps the item queued.
  Future<bool> Function(Map<String, dynamic>) _sender(ApiClient apiClient) {
    return (Map<String, dynamic> body) async {
      try {
        final records = body['records'];
        if (records is! List || records.isEmpty) return true; // poison — drop
        final resp = await apiClient.post(
          '/performance/logs/bulk',
          data: records,
        );
        final ok = resp.statusCode != null &&
            resp.statusCode! >= 200 &&
            resp.statusCode! < 300;
        if (ok) {
          debugPrint(
              '📤 [SetPerformanceQueue] replayed ${records.length} set(s)');
          // Only confirm if the user was actually told something was wrong —
          // the ordinary (never-queued) path stays silent as before.
          if (_pendingToastShown) {
            _pendingToastShown = false;
            rootSnackBar(const SnackBar(
              content: Text('Your workout sets are all synced now.'),
              duration: Duration(seconds: 3),
            ));
          }
        }
        return ok;
      } catch (_) {
        return false; // transient — keep queued, stop the flush
      }
    };
  }

  /// Enqueue a bulk set-performance write that inserted fewer rows than were
  /// sent (including zero) and arm the connectivity-restored flush. Never
  /// throws — a persistence failure here is logged, not surfaced via
  /// exceptions, since the caller is already on a background/fire-and-forget
  /// path — but per E2E #169 ("no error was shown at any point") this DOES
  /// surface a user-facing toast via the root messenger, so a completion
  /// that silently failed to sync no longer looks identical to one that
  /// worked. The toast survives navigation (it's on `rootScaffoldMessengerKey`,
  /// not this screen's own context, which may already be gone/popped).
  Future<void> enqueue({
    required String userId,
    required List<Map<String, dynamic>> records,
    required ApiClient apiClient,
  }) async {
    if (records.isEmpty) return;
    final body = <String, dynamic>{
      'records': records,
      'idempotency_key': OfflineWriteQueue.idempotencyKey('setperf_bulk'),
    };
    await _queue.enqueue(userId: userId, body: body);
    _queue.bindConnectivity(userId: userId, sender: _sender(apiClient));
    _pendingToastShown = true;
    rootSnackBar(const SnackBar(
      content: Text(
          "Some of your sets didn't save yet — we'll keep retrying in the background."),
      duration: Duration(seconds: 5),
    ));
  }

  /// Drain any queued bulk writes now. Call on app launch + on
  /// `AppLifecycleState.resumed`. Cheap no-op when the queue is empty; never
  /// throws. Re-arms the connectivity flush in case items remain after a
  /// transient stop.
  Future<void> flush({
    required String userId,
    required ApiClient apiClient,
  }) async {
    try {
      if (await _queue.isEmpty(userId)) return;
      debugPrint('📤 [SetPerformanceQueue] launch/resume drain…');
      await _queue.flush(userId: userId, sender: _sender(apiClient));
      _queue.bindConnectivity(userId: userId, sender: _sender(apiClient));
    } catch (e) {
      debugPrint('⚠️ [SetPerformanceQueue] flush failed: $e');
    }
  }
}
