import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../local/database.dart';

/// Task identifiers for background work.
const String backgroundSyncTask = 'com.fitwiz.backgroundSync';
const String backgroundPreCacheTask = 'com.fitwiz.backgroundPreCache';

/// Notification channel for sync failures.
const String _syncNotificationChannelId = 'fitwiz_sync';
const String _syncNotificationChannelName = 'Sync Status';

/// Callback dispatcher for workmanager -- must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('🔄 [BackgroundSync] Executing task: $taskName');

    try {
      switch (taskName) {
        case backgroundSyncTask:
          return await _processBackgroundSync();

        case backgroundPreCacheTask:
          debugPrint('🔄 [BackgroundSync] Pre-caching upcoming workouts...');
          // Pre-cache logic will be integrated when precache service is ready.
          return true;

        default:
          debugPrint('⚠️ [BackgroundSync] Unknown task: $taskName');
          return true;
      }
    } catch (e) {
      debugPrint('❌ [BackgroundSync] Task $taskName failed: $e');
      return false; // Workmanager will retry
    }
  });
}

/// Process pending sync queue items directly (no Riverpod in background isolate).
Future<bool> _processBackgroundSync() async {
  debugPrint('🔄 [BackgroundSync] Processing sync queue...');

  final db = AppDatabase();
  try {
    // Get Supabase session token
    String? token;
    try {
      token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint(
            '🔄 [BackgroundSync] No session, attempting refresh...');
        final refreshed =
            await Supabase.instance.client.auth.refreshSession();
        token = refreshed.session?.accessToken;
      }
    } catch (e) {
      debugPrint('❌ [BackgroundSync] Auth error: $e');
    }

    if (token == null) {
      debugPrint(
          '❌ [BackgroundSync] No auth token available, skipping sync');
      return true; // Return true so workmanager doesn't immediately retry
    }

    // Create a basic Dio client with auth header
    final dio = Dio(BaseOptions(
      baseUrl: 'https://aifitnesscoach-zqi3.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));

    // Reset stuck in_progress items
    await db.syncQueueDao
        .resetStuckInProgress(const Duration(minutes: 5));

    // Fetch pending items
    final items =
        await db.syncQueueDao.getPendingAndInProgressItems(limit: 50);
    if (items.isEmpty) {
      debugPrint('✅ [BackgroundSync] No pending items');
      return true;
    }

    debugPrint(
        '🔄 [BackgroundSync] Processing ${items.length} pending items...');

    int successCount = 0;
    int authFailCount = 0;

    for (final item in items) {
      try {
        await db.syncQueueDao.markInProgress(item.id);

        // Execute the HTTP call
        switch (item.httpMethod.toUpperCase()) {
          case 'POST':
            await dio.post(item.endpoint, data: jsonDecode(item.payload));
            break;
          case 'PUT':
            await dio.put(item.endpoint, data: jsonDecode(item.payload));
            break;
          case 'PATCH':
            await dio.patch(item.endpoint, data: jsonDecode(item.payload));
            break;
          case 'DELETE':
            await dio.delete(item.endpoint);
            break;
          default:
            debugPrint(
                '⚠️ [BackgroundSync] Unknown method: ${item.httpMethod}');
            continue;
        }

        await db.syncQueueDao.markCompleted(item.id);
        successCount++;
        debugPrint(
            '✅ [BackgroundSync] Synced item ${item.id} (${item.entityType})');
      } catch (e) {
        final errorStr = e.toString();
        final isAuthError =
            errorStr.contains('401') || errorStr.contains('403');
        if (isAuthError) authFailCount++;

        final newRetryCount = item.retryCount + 1;
        if (newRetryCount >= item.maxRetries) {
          await db.syncQueueDao.moveToDeadLetter(item.id);
          debugPrint(
              '💀 [BackgroundSync] Item ${item.id} moved to dead letter');
        } else {
          await db.syncQueueDao.markFailed(item.id, errorStr);
          debugPrint(
              '⚠️ [BackgroundSync] Item ${item.id} failed (retry $newRetryCount/${item.maxRetries})');
        }
      }
    }

    debugPrint(
        '✅ [BackgroundSync] Completed: $successCount/${items.length} synced');

    // If all items failed with auth errors, show a notification
    if (authFailCount == items.length && items.isNotEmpty) {
      await _showSyncFailureNotification();
    }

    return true;
  } finally {
    await db.close();
  }
}

/// Show a local notification when sync fails persistently.
Future<void> _showSyncFailureNotification() async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await plugin.show(
      9001,
      'FitWiz Sync Issue',
      'Your workout data could not sync. Please open the app and sign in.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _syncNotificationChannelId,
          _syncNotificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  } catch (e) {
    debugPrint('❌ [BackgroundSync] Could not show notification: $e');
  }
}

/// Service to initialize and manage background sync tasks.
class BackgroundSyncService {
  /// Initialize workmanager and register periodic tasks.
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic sync task -- every 15 minutes (minimum interval).
    await Workmanager().registerPeriodicTask(
      backgroundSyncTask,
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );

    // Register periodic pre-cache task -- every 6 hours.
    await Workmanager().registerPeriodicTask(
      backgroundPreCacheTask,
      backgroundPreCacheTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    debugPrint(
        '✅ [BackgroundSync] Workmanager initialized and tasks registered');
  }

  /// Cancel all background tasks (e.g. on logout).
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('🔄 [BackgroundSync] All background tasks cancelled');
  }
}
