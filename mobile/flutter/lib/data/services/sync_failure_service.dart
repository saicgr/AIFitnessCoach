import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../utils/tz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local/database.dart';
import '../local/database_provider.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Service for monitoring sync health, exporting dead letter items,
/// and triggering recovery actions.
class SyncFailureService {
  final AppDatabase _db;
  Timer? _notificationTimer;
  DateTime? _firstFailureTime;
  static const _failureNotificationThreshold = Duration(hours: 24);

  SyncFailureService(this._db);

  /// Start periodic monitoring of sync health.
  /// If dead letter count > 0 for > 24 hours, trigger a local notification.
  void startMonitoring() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkSyncHealth(),
    );
  }

  Future<void> _checkSyncHealth() async {
    try {
      final deadLetterItems = await _db.syncQueueDao.getDeadLetterItems();
      if (deadLetterItems.isEmpty) {
        _firstFailureTime = null;
        return;
      }

      _firstFailureTime ??= DateTime.now();

      final elapsed = DateTime.now().difference(_firstFailureTime!);
      if (elapsed >= _failureNotificationThreshold) {
        await _showProlongedFailureNotification(deadLetterItems.length);
        // Reset so we don't spam notifications
        _firstFailureTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('❌ [SyncFailure] Health check error: $e');
    }
  }

  Future<void> _showProlongedFailureNotification(int count) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await plugin.show(
        9002,
        '${Branding.appName} Sync Issue',
        '$count change${count == 1 ? '' : 's'} have not synced for over 24 hours. '
            'Open the app to resolve.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitwiz_sync',
            'Sync Status',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('❌ [SyncFailure] Could not show notification: $e');
    }
  }

  /// Export dead letter items as a JSON file for debugging/support.
  Future<File> exportDeadLetterItems() async {
    final items = await _db.syncQueueDao.getDeadLetterItems();
    final export = {
      'exported_at': Tz.timestamp(),
      'item_count': items.length,
      'items': items
          .map((item) => {
                'id': item.id,
                'operation_type': item.operationType,
                'entity_type': item.entityType,
                'entity_id': item.entityId,
                'payload': item.payload,
                'http_method': item.httpMethod,
                'endpoint': item.endpoint,
                'created_at': item.createdAt.toIso8601String(),
                'retry_count': item.retryCount,
                'last_error': item.lastError,
                'status': item.status,
              })
          .toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/fitwiz_sync_export_$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
    );
    return file;
  }

  /// Share an exported file via the system share sheet.
  Future<void> shareExport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${Branding.appName} Sync Export',
    );
  }

  /// Reset all dead letter items back to pending after successful re-authentication.
  Future<int> resetAfterReAuth() async {
    return _db.syncQueueDao.recoverDeadLetterItems();
  }

  /// Move a single dead-letter item back to the pending queue and kick off
  /// a sync. Returns true if the item was retryable (auth/network/server
  /// transient errors); false for permanent validation errors that would
  /// re-fail immediately — caller should encourage Edit & re-log instead.
  Future<bool> retryItem(int id) async {
    final items = await _db.syncQueueDao.getDeadLetterItems();
    final item = items.firstWhere(
      (it) => it.id == id,
      orElse: () => throw StateError('Sync queue item $id not found'),
    );
    final kind = SyncErrorKind.classify(item.lastError);
    if (!kind.isRetryable) return false;
    await _db.syncQueueDao.retrySingle(id);
    return true;
  }

  /// Permanently delete a dead-letter row. The user has explicitly given up
  /// on this item. Caller should typically prompt for an export-first
  /// confirmation when the payload contains user-generated text.
  Future<void> discardItem(int id) async {
    await _db.syncQueueDao.hardDelete(id);
  }

  void dispose() {
    _notificationTimer?.cancel();
  }
}

/// Coarse classification of why a sync item ended up in dead_letter.
/// Drives the per-row CTA on the Sync Details screen — for instance, a
/// validation_4xx item shouldn't show "Retry now" because it'll just
/// fail again with the same error.
enum SyncErrorKind {
  /// 401/403 from the server. Resolution = re-login.
  auth,
  /// Network unreachable / DNS / SSL handshake / timeout. Resolution = retry
  /// when connectivity returns.
  network,
  /// 4xx (other than 401/403). The payload itself is rejected. User must
  /// edit the underlying data; pure retry will just re-fail.
  validation4xx,
  /// 5xx server error. Worth retrying — the server may have recovered.
  server5xx,
  /// Local-DB JSON parse failure or row-shape corruption. Item is unsalvageable;
  /// only options are export + discard.
  corrupt,
  /// Anything else (last_error null, unrecognized).
  unknown;

  bool get isRetryable => switch (this) {
        SyncErrorKind.auth => false,
        SyncErrorKind.network => true,
        SyncErrorKind.validation4xx => false,
        SyncErrorKind.server5xx => true,
        SyncErrorKind.corrupt => false,
        SyncErrorKind.unknown => true,
      };

  String get displayLabel => switch (this) {
        SyncErrorKind.auth => 'Auth',
        SyncErrorKind.network => 'Offline',
        SyncErrorKind.validation4xx => 'Validation',
        SyncErrorKind.server5xx => 'Server',
        SyncErrorKind.corrupt => 'Corrupt',
        SyncErrorKind.unknown => 'Unknown',
      };

  /// Best-effort classification from a raw error message string. The retry
  /// engine writes free-text errors via `markFailed`, so we string-match on
  /// the substrings that show up in HTTP / Dio / connectivity errors.
  static SyncErrorKind classify(String? lastError) {
    if (lastError == null || lastError.trim().isEmpty) return SyncErrorKind.unknown;
    final s = lastError.toLowerCase();
    if (s.contains('401') || s.contains('403') ||
        s.contains('unauthor') || s.contains('forbidden') ||
        s.contains('jwt') || s.contains('expired token')) {
      return SyncErrorKind.auth;
    }
    if (s.contains('socketexception') ||
        s.contains('handshake') ||
        s.contains('connection') ||
        s.contains('timeout') ||
        s.contains('unreachable') ||
        s.contains('failed host lookup') ||
        s.contains('network')) {
      return SyncErrorKind.network;
    }
    if (s.contains('500') || s.contains('502') ||
        s.contains('503') || s.contains('504') ||
        s.contains('internal server error') ||
        s.contains('bad gateway')) {
      return SyncErrorKind.server5xx;
    }
    if (s.contains('400') || s.contains('422') || s.contains('409') ||
        s.contains('validation') || s.contains('invalid')) {
      return SyncErrorKind.validation4xx;
    }
    if (s.contains('formatexception') ||
        s.contains('jsondecode') ||
        s.contains('parse')) {
      return SyncErrorKind.corrupt;
    }
    return SyncErrorKind.unknown;
  }
}

/// Provider for the sync failure service.
final syncFailureServiceProvider = Provider<SyncFailureService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = SyncFailureService(db);
  service.startMonitoring();
  ref.onDispose(() => service.dispose());
  return service;
});
