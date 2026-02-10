import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local/database.dart';
import '../local/database_provider.dart';

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
        'FitWiz Sync Issue',
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
      'exported_at': DateTime.now().toIso8601String(),
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
      subject: 'FitWiz Sync Export',
    );
  }

  /// Reset all dead letter items back to pending after successful re-authentication.
  Future<int> resetAfterReAuth() async {
    return _db.syncQueueDao.recoverDeadLetterItems();
  }

  void dispose() {
    _notificationTimer?.cancel();
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
