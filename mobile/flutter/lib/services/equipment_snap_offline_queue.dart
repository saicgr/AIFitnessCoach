/// Minimal in-memory offline queue for equipment-snap uploads.
///
/// The main `SyncEngine` (`data/services/sync_engine.dart`) is workout-domain
/// scoped with typed entities (workout / workout_log / readiness) and a Drift
/// `pending_sync_queue` table. Wiring snap uploads through it would require a
/// new entity type, a new DAO row, conflict-resolution wiring, and migration —
/// none of which add value for a transient interactive task. Instead this
/// queue lives purely in memory: if the app is killed before reconnect, the
/// snap is dropped (acceptable: the user still has the photo on their roll
/// and can retake).
///
/// Behavior:
///   - `enqueue()` records the captured bytes + mode + workout context.
///   - On the next `ConnectivityStatus.online` event the queue drains: each
///     entry is uploaded to `POST /api/v1/equipment/snap` and the resulting
///     SnapResponse is broadcast on [drainResults] so the UI can show a
///     local notification ("Identified your snap: …").
///
/// Why not use `workmanager`? It's already in pubspec but it's iOS-quirky for
/// payloads >100KB and we'd need a background isolate that re-bootstraps
/// auth. For an interactive feature we'd rather drain on app-foreground +
/// reconnect, which this queue handles directly.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../data/services/api_client.dart';
import '../data/services/connectivity_service.dart';

/// One queued snap upload.
@immutable
class QueuedSnap {
  final String id;
  final Uint8List imageBytes;
  final String contentType; // e.g. "image/jpeg"
  final String mode; // 'swap' | 'add' | 'identify'
  final String? workoutId;
  final String? replacingExerciseId;
  final DateTime queuedAt;

  const QueuedSnap({
    required this.id,
    required this.imageBytes,
    required this.contentType,
    required this.mode,
    required this.workoutId,
    required this.replacingExerciseId,
    required this.queuedAt,
  });
}

/// Result emitted on [EquipmentSnapOfflineQueue.drainResults] after each
/// successful drain.
@immutable
class DrainedSnapResult {
  final QueuedSnap original;
  final Map<String, dynamic> snapResponse;
  const DrainedSnapResult({
    required this.original,
    required this.snapResponse,
  });
}

class EquipmentSnapOfflineQueue {
  final Ref _ref;
  final List<QueuedSnap> _queue = [];
  final StreamController<DrainedSnapResult> _resultsCtrl =
      StreamController<DrainedSnapResult>.broadcast();
  final StreamController<int> _depthCtrl =
      StreamController<int>.broadcast();
  StreamSubscription<ConnectivityStatus>? _connSub;
  bool _isDraining = false;

  EquipmentSnapOfflineQueue(this._ref) {
    final conn = _ref.read(connectivityServiceProvider);
    _connSub = conn.statusStream.listen((status) {
      if (status == ConnectivityStatus.online && _queue.isNotEmpty) {
        // Defer slightly so the radio + DNS settle before we hit the API.
        Future.delayed(const Duration(milliseconds: 800), _drain);
      }
    });
  }

  /// Stream of (queuedSnap, snapResponse) pairs as the queue drains.
  Stream<DrainedSnapResult> get drainResults => _resultsCtrl.stream;

  /// Stream of current queue depth — drives any "1 snap pending" pill.
  Stream<int> get depthStream => _depthCtrl.stream;

  int get depth => _queue.length;

  void enqueue(QueuedSnap snap) {
    _queue.add(snap);
    _depthCtrl.add(_queue.length);
    debugPrint('🏋️ [SnapQueue] enqueued (depth=${_queue.length})');
    // Try to drain right away — connectivity may already be back by now.
    final conn = _ref.read(connectivityServiceProvider);
    if (conn.currentStatus == ConnectivityStatus.online) {
      Future.microtask(_drain);
    }
  }

  Future<void> _drain() async {
    if (_isDraining || _queue.isEmpty) return;
    _isDraining = true;
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.first;
        final ok = await _uploadOne(next);
        if (!ok) {
          // Network flaked again — stop and wait for the next online event.
          break;
        }
        _queue.removeAt(0);
        _depthCtrl.add(_queue.length);
      }
    } finally {
      _isDraining = false;
    }
  }

  Future<bool> _uploadOne(QueuedSnap snap) async {
    try {
      final api = _ref.read(apiClientProvider);
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          snap.imageBytes,
          filename: 'queued_snap.jpg',
          contentType: DioMediaType.parse(snap.contentType),
        ),
        'mode': snap.mode,
        if (snap.workoutId != null) 'workout_id': snap.workoutId,
        if (snap.replacingExerciseId != null)
          'replacing_exercise_id': snap.replacingExerciseId,
      });
      final resp = await api.post(
        '${ApiConstants.apiBaseUrl}/equipment/snap',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (resp.statusCode != 200 || resp.data is! Map) return false;
      final snapResp = Map<String, dynamic>.from(resp.data as Map);
      _resultsCtrl.add(DrainedSnapResult(
        original: snap,
        snapResponse: snapResp,
      ));
      // Fire-and-forget local notification — best-effort. The deeplink
      // payload (`fitwiz://snap/<id>`) is the route our existing widget
      // URL scheme already handles; if the originating sheet was closed
      // the user lands back at chat which can pick up the snap_id.
      unawaited(_notifyResult(snap, snapResp));
      return true;
    } on DioException catch (e) {
      // Distinguish "transient" (retry) from "permanent" (drop).
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        debugPrint('⚠️ [SnapQueue] transient: ${e.type} — retry on next online');
        return false;
      }
      // 4xx (paywall, oversize, bad mime) → drop so we don't loop forever.
      debugPrint('❌ [SnapQueue] permanent ${e.response?.statusCode}: dropping');
      _queue.removeAt(0);
      _depthCtrl.add(_queue.length);
      return _queue.isNotEmpty; // continue draining the rest
    } catch (e) {
      debugPrint('❌ [SnapQueue] unexpected: $e');
      return false;
    }
  }

  static const _channelId = 'equipment_snap_results';
  static const _channelName = 'Snapped equipment results';

  Future<void> _notifyResult(
    QueuedSnap snap,
    Map<String, dynamic> snapResp,
  ) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      // Re-init is idempotent and cheap; main.dart sets up the global
      // channel but we declare our own here to keep this module decoupled.
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final matched = snapResp['matched'] == true;
      final canonical = snapResp['equipment_canonical_name'] as String? ?? '';
      final List matches = (snapResp['matches'] as List?) ?? const [];
      final topName = matches.isNotEmpty
          ? ((matches.first as Map)['name']?.toString() ?? '')
          : '';

      final title = matched
          ? 'Identified your snap: $topName'
          : "We couldn't identify your snap";
      final body = matched
          ? (canonical.isNotEmpty
              ? 'Found ${canonical.replaceAll('_', ' ')}. Tap to view matches.'
              : 'Tap to view matches.')
          : 'Open Zealova to retake or describe instead.';

      await plugin.show(
        snap.id.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Result of an offline-queued equipment snap',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'fitwiz://snap/${snapResp['snapped_equipment_id'] ?? ''}',
      );
    } catch (e) {
      debugPrint('⚠️ [SnapQueue] notification failed: $e');
    }
  }

  void dispose() {
    _connSub?.cancel();
    _resultsCtrl.close();
    _depthCtrl.close();
  }
}

/// Singleton queue, lifecycle bound to the Riverpod container.
final equipmentSnapOfflineQueueProvider =
    Provider<EquipmentSnapOfflineQueue>((ref) {
  final q = EquipmentSnapOfflineQueue(ref);
  ref.onDispose(q.dispose);
  return q;
});
