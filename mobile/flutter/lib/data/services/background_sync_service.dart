import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/constants/api_constants.dart';
import '../../utils/tz.dart';
import '../local/database.dart';
import 'health_import_service.dart';
import 'health_service.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Task identifiers for background work.
const String backgroundSyncTask = 'com.fitwiz.backgroundSync';
const String backgroundPreCacheTask = 'com.fitwiz.backgroundPreCache';

/// Periodic external-workout import (Apple Watch / Apple Health / Health
/// Connect). Workouts recorded OUTSIDE the app are auto-imported headlessly
/// so they don't depend on the user opening the home screen (B12).
const String backgroundExternalWorkoutSyncTask =
    'com.fitwiz.backgroundExternalWorkoutSync';

/// SharedPreferences key — user opt-out of background external-workout import.
/// Default true (matches the existing foreground auto-import-when-connected
/// behavior). The settings "Auto-import external workouts" toggle writes here.
const String kAutoImportExternalWorkoutsKey = 'auto_import_external_workouts';

/// Periodic background sync of TODAY's daily activity (steps / sleep / vitals)
/// from Apple Health / Health Connect. Health data only syncs while the app is
/// foregrounded otherwise, so for a user who doesn't open the app the server's
/// health data goes stale and recovery/health nudges can't fire. This keeps it
/// fresh headlessly so health-grounded re-engagement notifications stay accurate
/// (and the freshness gate lets them fire). See plan §2A-ii.
const String backgroundDailyActivitySyncTask =
    'com.fitwiz.backgroundDailyActivitySync';

/// SharedPreferences key — user opt-out of background health sync. Default true.
/// The Settings "Sync health in the background" toggle writes here.
const String kBackgroundHealthSyncKey = 'background_health_sync_enabled';

/// Persisted consent-denied gate shared with ActivityService — once the backend
/// 403s for missing health-data consent, stop hammering /activity/sync.
const String _kActivityConsentDeniedKey = 'activity_health_consent_denied';

/// Notification channel for sync failures.
const String _syncNotificationChannelId = 'fitwiz_sync';
const String _syncNotificationChannelName = 'Sync Status';

/// Callback dispatcher for workmanager -- must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('🔄 [BackgroundSync] Executing task: $taskName');

    // WorkManager runs in a separate isolate — Supabase must be initialized
    // here with the SAME storage config as main.dart so the background
    // isolate can read the persisted session. Without matching authOptions,
    // the default `flutter_secure_storage` backend is used here while the
    // main app writes to SharedPreferences under `supabase.auth.token`,
    // and the background isolate never finds a refresh token.
    try {
      await Supabase.initialize(
        url: ApiConstants.supabaseUrl,
        anonKey: ApiConstants.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'supabase.auth.token',
          ),
        ),
      );
      debugPrint('✅ [BackgroundSync] Supabase initialized in background isolate');
    } catch (e) {
      // Already initialized (e.g. on iOS where isolate may be reused)
      debugPrint('🔄 [BackgroundSync] Supabase init: $e');
    }

    try {
      switch (taskName) {
        case backgroundSyncTask:
          return await _processBackgroundSync();

        case backgroundPreCacheTask:
          debugPrint('🔄 [BackgroundSync] Pre-caching upcoming workouts...');
          // Pre-cache logic will be integrated when precache service is ready.
          return true;

        case backgroundExternalWorkoutSyncTask:
          return await _processExternalWorkoutImport();

        case backgroundDailyActivitySyncTask:
          return await _processDailyActivitySync();

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
        final refreshed = await Supabase.instance.client.auth
            .refreshSession()
            .timeout(ApiConstants.tokenRefreshTimeout);
        token = refreshed.session?.accessToken;
      }
    } on AuthSessionMissingException {
      // Expected when the user is signed out, hasn't signed in yet, or the
      // refresh token expired between WorkManager firings. NOT an error —
      // sync simply has nothing to do until the user is back in foreground.
      debugPrint(
          'ℹ️ [BackgroundSync] No persisted session in background isolate (user signed out or refresh token expired) — skipping');
    } catch (e) {
      debugPrint('⚠️ [BackgroundSync] Unexpected auth error (will skip): $e');
    }

    if (token == null) {
      debugPrint(
          'ℹ️ [BackgroundSync] No auth token available, skipping sync (normal when signed out)');
      return true; // Return true so workmanager doesn't immediately retry
    }

    // Create a basic Dio client with auth header
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
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

/// Resolve the current Supabase access token in a background isolate.
/// Returns null when signed out / refresh token expired (callers should
/// no-op, not error). Mirrors the auth handling in [_processBackgroundSync].
Future<String?> _resolveBackgroundToken() async {
  try {
    var token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      final refreshed = await Supabase.instance.client.auth
          .refreshSession()
          .timeout(ApiConstants.tokenRefreshTimeout);
      token = refreshed.session?.accessToken;
    }
    return token;
  } on AuthSessionMissingException {
    return null;
  } catch (e) {
    debugPrint('⚠️ [ExternalWorkoutSync] Auth resolve failed (skip): $e');
    return null;
  }
}

/// Headless import of workouts recorded outside the app (Apple Watch / Apple
/// Health / Health Connect). Runs in the WorkManager isolate so external
/// workouts auto-import even when the user never opens the home screen (B12).
///
/// Dedup: by the platform workout UUID via [ImportedWorkoutTracker] — the same
/// tracker the foreground path uses, so a workout imported in background won't
/// re-surface in the foreground sheet and vice-versa.
///
/// Time handling: each workout's `scheduled_date` is the LOCAL calendar day the
/// workout actually happened on (`Tz.localDate(startTime)` → YYYY-MM-DD). The
/// backend buckets scheduled_date by the leading date portion
/// (`str(scheduled_date)[:10]` in today.py + workout_db.py), so we must send the
/// user's local training day, not the UTC instant — otherwise an evening
/// workout west of UTC shifts forward a calendar day (B13(a)). We never
/// substitute a server/UTC "now" for the workout's own clock (see
/// feedback_user_local_time_only).
Future<bool> _processExternalWorkoutImport() async {
  // Respect the user opt-out toggle (default ON).
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kAutoImportExternalWorkoutsKey) ?? true;
    if (!enabled) {
      debugPrint('ℹ️ [ExternalWorkoutSync] Disabled by user — skipping');
      return true;
    }
  } catch (_) {
    // If prefs can't be read, default to enabled (fail-open to the
    // historical behavior) rather than silently dropping imports.
  }

  final token = await _resolveBackgroundToken();
  if (token == null) {
    debugPrint('ℹ️ [ExternalWorkoutSync] No auth token — skipping');
    return true;
  }

  // The /workouts endpoints need the backend user id in the create payload.
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('ℹ️ [ExternalWorkoutSync] No user id — skipping');
    return true;
  }

  final healthService = HealthService();
  final importService = HealthImportService();

  // Verify read access before querying. No permission = nothing to do (user
  // hasn't connected Health on this device). hasHealthPermissions() configures
  // the plugin internally, so no separate configure call is needed.
  try {
    final hasPerms = await healthService.hasHealthPermissions();
    if (!hasPerms) {
      debugPrint('ℹ️ [ExternalWorkoutSync] No Health permission — skipping');
      return true;
    }
  } catch (e) {
    debugPrint('⚠️ [ExternalWorkoutSync] Health configure/perm check failed: $e');
    return true;
  }

  List<PendingWorkoutImport> pending;
  try {
    pending = await importService.getUnimportedWorkouts(healthService);
  } catch (e) {
    debugPrint('❌ [ExternalWorkoutSync] Discovery failed: $e');
    return true; // don't thrash retries on a transient plugin error
  }

  if (pending.isEmpty) {
    debugPrint('✅ [ExternalWorkoutSync] No new external workouts');
    return true;
  }

  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ));

  int imported = 0;
  for (final p in pending) {
    try {
      // Enrich (HR series, zones, cadence, training load) when possible.
      var enriched = p;
      try {
        enriched =
            await importService.enrichWithFullMetrics(p, healthService);
      } catch (e) {
        debugPrint('⚠️ [ExternalWorkoutSync] Enrich failed (raw import): $e');
      }

      final metadata = enriched.toMetadata();
      if (enriched.caloriesBurned != null) {
        metadata['calories_burned'] = enriched.caloriesBurned;
      }
      if (enriched.distanceMeters != null) {
        metadata['distance_meters'] = enriched.distanceMeters;
      }
      if (enriched.totalSteps != null) {
        metadata['total_steps'] = enriched.totalSteps;
      }

      final createResp = await dio.post(
        '${ApiConstants.workouts}/',
        data: {
          'user_id': userId,
          'name': _externalWorkoutName(enriched.activityKind),
          'type': enriched.activityType,
          'difficulty': 'intermediate',
          // B13(a): local calendar day the workout happened on (backend buckets
          // scheduled_date by YYYY-MM-DD — see the time-handling note above).
          'scheduled_date': Tz.localDate(enriched.startTime),
          'exercises_json': '[]',
          'duration_minutes': enriched.durationMinutes,
          'generation_method': 'health_connect_import',
          'generation_source': 'health_connect',
          'generation_metadata': jsonEncode(metadata),
        },
      );

      final workoutId = (createResp.data as Map?)?['id'] as String?;
      if (workoutId == null) continue;

      await dio.post(
        '${ApiConstants.workouts}/$workoutId/complete',
        queryParameters: {'completion_method': 'marked_done'},
      );

      // Dedup: mark UUID so neither background nor foreground re-imports it.
      await importService.markImported(p.uuid);
      imported++;
    } catch (e) {
      // Skip this one, keep going — a single bad row shouldn't fail the batch.
      debugPrint('⚠️ [ExternalWorkoutSync] Import failed for ${p.uuid}: $e');
    }
  }

  debugPrint(
      '✅ [ExternalWorkoutSync] Imported $imported/${pending.length} external workouts');
  return true;
}

/// Headless sync of TODAY's daily activity (steps / sleep / vitals) to
/// /activity/sync so health data stays fresh even when the app isn't opened.
/// Mirrors the foreground build in health_service_part_daily_activity.dart and
/// the /activity/sync payload in activity_service.dart. No-ops when the user
/// disabled background sync, hasn't granted Health permission, or has denied
/// health-data consent. Always returns true on non-fatal errors so WorkManager
/// doesn't thrash retries.
///
/// NOTE: deliberately does NOT touch last_active_at — this is a background
/// signal, and marking a dormant user "active" would defeat the dormancy taper.
/// (/activity/sync has no last_active write; only /home/bootstrap + FCM do.)
Future<bool> _processDailyActivitySync() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(kBackgroundHealthSyncKey) ?? true)) {
      debugPrint('ℹ️ [DailyActivitySync] Disabled by user — skipping');
      return true;
    }
    if (prefs.getBool(_kActivityConsentDeniedKey) ?? false) {
      debugPrint('ℹ️ [DailyActivitySync] Health consent denied — skipping');
      return true;
    }
  } catch (_) {
    // Fail-open to the historical behavior (attempt sync) on a prefs error.
  }

  final token = await _resolveBackgroundToken();
  if (token == null) {
    debugPrint('ℹ️ [DailyActivitySync] No auth token — skipping');
    return true;
  }
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('ℹ️ [DailyActivitySync] No user id — skipping');
    return true;
  }

  final healthService = HealthService();
  try {
    if (!await healthService.hasHealthPermissions()) {
      debugPrint('ℹ️ [DailyActivitySync] No Health permission — skipping');
      return true;
    }
  } catch (e) {
    debugPrint('⚠️ [DailyActivitySync] Health perm check failed: $e');
    return true;
  }

  try {
    final steps = await healthService.getTodaySteps();
    final activeEnergy = await healthService.getTodayActiveEnergy();
    final sleepData = await healthService.getSleepData(days: 1);
    final vitals = await healthService.getTodayVitals();
    final overnight = await healthService.getOvernightVitals();
    final restingHR = vitals['restingHeartRate'] as int?;
    final hasSleep = sleepData.hasData;

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');

    final payload = <String, dynamic>{
      'user_id': userId,
      'activity_date': '${now.year}-${two(now.month)}-${two(now.day)}',
      'steps': steps,
      'calories_burned': activeEnergy,
      'active_calories': activeEnergy,
      'resting_heart_rate': restingHR,
      'sleep_minutes': hasSleep ? sleepData.totalMinutes : null,
      'deep_sleep_minutes': hasSleep ? sleepData.deepMinutes : null,
      'rem_sleep_minutes': hasSleep ? sleepData.remMinutes : null,
      'light_sleep_minutes': hasSleep ? sleepData.lightMinutes : null,
      'awake_sleep_minutes':
          hasSleep && sleepData.awakeMinutes > 0 ? sleepData.awakeMinutes : null,
      'avg_heart_rate': vitals['avgHeartRate'],
      'max_heart_rate': vitals['maxHeartRate'],
      'water_ml': vitals['waterMl'],
      'sleep_start': hasSleep ? sleepData.bedTime?.toIso8601String() : null,
      'sleep_end': hasSleep ? sleepData.wakeTime?.toIso8601String() : null,
      'sleep_latency_minutes': hasSleep ? sleepData.latencyMinutes : null,
      'sleep_efficiency': hasSleep ? sleepData.efficiency : null,
      'wake_ups': hasSleep ? sleepData.wakeUps : null,
      'active_minutes': 0,
      if (overnight['hrv'] != null) 'hrv': overnight['hrv'],
      if (overnight['bloodOxygen'] != null) 'blood_oxygen': overnight['bloodOxygen'],
      if (overnight['respiratoryRate'] != null)
        'respiratory_rate': overnight['respiratoryRate'],
      if (overnight['bodyTemperature'] != null)
        'body_temperature': overnight['bodyTemperature'],
      'source': Platform.isAndroid ? 'health_connect' : 'apple_health',
    };

    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));

    final resp = await dio.post('/activity/sync', data: payload);
    debugPrint(
        '✅ [DailyActivitySync] Synced (steps=$steps, status=${resp.statusCode})');
    return true;
  } catch (e) {
    // Latch the consent gate for EXACTLY ONE cause: a 403 the server tagged
    // `health_data_consent_required` (it read the flag and it is false).
    // A bare string match on '403'/'Forbidden' also caught ownership 403s and
    // the transient 503 the server returns when it CANNOT read the consent flag
    // (consent_guard fails closed on a DB blip) — permanently disabling health
    // sync over a transient Supabase error. Read the error code off the wire,
    // exactly like ActivityService._classifySyncResponse.
    final code = e is DioException
        ? e.response?.headers.value('X-Zealova-Error-Code')
        : null;
    if (code == 'health_data_consent_required') {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kActivityConsentDeniedKey, true);
      } catch (_) {}
      debugPrint('🚫 [DailyActivitySync] Health consent not granted — gating');
    } else {
      // Everything else (transient 403/503, network) leaves the gate open so
      // the next scheduled sync retries.
      debugPrint('❌ [DailyActivitySync] $e');
    }
    return true; // never thrash retries on a transient error
  }
}

/// User-friendly title for a headlessly-imported external workout, keyed by the
/// granular activity kind. Mirrors `HealthImportNotifier._buildWorkoutName`.
String _externalWorkoutName(String kind) {
  switch (kind) {
    case 'walking':
      return 'Walking';
    case 'running':
      return 'Running';
    case 'cycling':
      return 'Cycling';
    case 'swimming':
      return 'Swimming';
    case 'rowing':
      return 'Rowing';
    case 'hiking':
      return 'Hiking';
    case 'elliptical':
      return 'Elliptical';
    case 'stairs':
      return 'Stair Climb';
    case 'skating':
      return 'Skating';
    case 'dance':
      return 'Dance';
    case 'yoga':
      return 'Yoga';
    case 'pilates':
      return 'Pilates';
    case 'hiit':
      return 'HIIT';
    case 'tennis':
      return 'Tennis';
    case 'basketball':
      return 'Basketball';
    case 'football':
      return 'Football';
    case 'soccer':
      return 'Soccer';
    case 'strength':
      return 'Strength Session';
    default:
      return 'Workout';
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
      '${Branding.appName} Sync Issue',
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

    // Register periodic external-workout import (Apple Watch / Health) — every
    // 30 minutes. Imports workouts recorded outside the app even when the user
    // never opens the home screen (B12). Internally no-ops when the user has
    // disabled auto-import or hasn't granted Health permission.
    await Workmanager().registerPeriodicTask(
      backgroundExternalWorkoutSyncTask,
      backgroundExternalWorkoutSyncTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    // Register periodic daily-activity health sync — every 30 minutes. Keeps
    // steps/sleep/vitals fresh on the server even when the app isn't opened, so
    // health-grounded re-engagement nudges stay accurate. Internally no-ops when
    // the user disabled background health sync or hasn't granted permission.
    await Workmanager().registerPeriodicTask(
      backgroundDailyActivitySyncTask,
      backgroundDailyActivitySyncTask,
      frequency: const Duration(minutes: 30),
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

  /// Persist the user's "sync health in the background" preference. The
  /// background task reads this on each firing. Settings toggle calls this.
  static Future<void> setBackgroundHealthSync(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kBackgroundHealthSyncKey, enabled);
      debugPrint('🔄 [BackgroundSync] background health sync = $enabled');
    } catch (e) {
      debugPrint('❌ [BackgroundSync] Failed to persist health-sync pref: $e');
    }
  }

  /// Read the current "sync health in the background" preference (default ON).
  static Future<bool> isBackgroundHealthSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kBackgroundHealthSyncKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Persist the user's "auto-import external workouts" preference. The
  /// background task reads this on each firing. Settings toggle calls this.
  static Future<void> setAutoImportExternalWorkouts(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kAutoImportExternalWorkoutsKey, enabled);
      debugPrint('🔄 [BackgroundSync] auto-import external workouts = $enabled');
    } catch (e) {
      debugPrint('❌ [BackgroundSync] Failed to persist auto-import pref: $e');
    }
  }

  /// Read the current "auto-import external workouts" preference (default ON).
  static Future<bool> isAutoImportExternalWorkoutsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kAutoImportExternalWorkoutsKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Kick a one-off external-workout import immediately (e.g. right after the
  /// user grants Health permission, or on app foreground) instead of waiting
  /// for the next 30-minute periodic tick.
  static Future<void> triggerExternalWorkoutSyncNow() async {
    await Workmanager().registerOneOffTask(
      '$backgroundExternalWorkoutSyncTask.oneoff',
      backgroundExternalWorkoutSyncTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    debugPrint('🔄 [BackgroundSync] Triggered one-off external-workout sync');
  }

  /// Cancel all background tasks (e.g. on logout).
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('🔄 [BackgroundSync] All background tasks cancelled');
  }
}
