import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'health_service.dart';

/// Activity service provider
final activityServiceProvider = Provider<ActivityService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityService(apiClient);
});

/// Service for syncing daily activity data to Supabase
class ActivityService {
  final ApiClient _apiClient;

  // Cached "consent denied" flag — once the backend rejects sync with 403
  // (no health-data consent), stop hammering the endpoint. Persisted to
  // SharedPreferences so it survives app restarts (without persistence the
  // gate reset on every launch and we kept re-spamming production).
  // Cleared by Settings → Privacy when the user toggles consent back on.
  static const _kConsentDeniedKey = 'activity_health_consent_denied';
  bool _consentDenied = false;

  // Serializes the FIRST sync attempt after cold start so syncActivity +
  // syncActivityBatch don't both fire 403s before the consent gate has had
  // a chance to set itself. After the first response we never await here
  // again. Caught 2026-05-12 — Render logs showed paired 403s every cold
  // launch for users who hadn't enabled health-data consent.
  Future<void>? _firstAttemptInFlight;

  ActivityService(this._apiClient) {
    _loadConsentFlag();
  }

  Future<void> _loadConsentFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _consentDenied = prefs.getBool(_kConsentDeniedKey) ?? false;
    } catch (_) {
      _consentDenied = false;
    }
  }

  Future<void> _persistConsentDenied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kConsentDeniedKey, true);
    } catch (_) {}
  }

  /// Call from Settings when the user re-enables health-data consent so the
  /// next sync attempt actually hits the wire.
  Future<void> resetConsentGate() async {
    _consentDenied = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kConsentDeniedKey);
    } catch (_) {}
  }

  /// Sync daily activity to backend
  Future<Map<String, dynamic>?> syncActivity({
    required String userId,
    required DailyActivity activity,
  }) async {
    // Always re-read the persisted gate (a single cheap bool read): AISettings
    // seeds it proactively from the server's health_data_consent AFTER this
    // service is constructed, so a one-time in-memory cache would miss the seed
    // and fire a stray first-launch 403.
    await _loadConsentFlag();
    // If another sync is the first-out-of-the-gate, wait for it to come
    // back before deciding — saves a paired 403 on cold start.
    if (_firstAttemptInFlight != null) {
      try { await _firstAttemptInFlight; } catch (_) {}
    }
    if (_consentDenied) {
      debugPrint('⏭️ [Activity] Sync skipped — health consent denied (persisted)');
      return null;
    }
    final attemptCompleter = _firstAttemptInFlight == null ? Completer<void>() : null;
    if (attemptCompleter != null) {
      _firstAttemptInFlight = attemptCompleter.future;
    }
    try {
      debugPrint('🏃 [Activity] Syncing activity for ${activity.date}...');

      // distance_meters / hrv / blood_oxygen / body_temperature /
      // respiratory_rate / flights_climbed / basal_calories were dropped
      // from the client payload 2026-05-07 — Google Play Health Connect
      // minimum scope policy required removing those permissions, so the
      // mobile DailyActivity model no longer carries them. Backend Pydantic
      // schema still accepts them as Optional fields (back-compat with
      // older app versions still in production).
      final response = await _apiClient.post(
        '/activity/sync',
        data: {
          'user_id': userId,
          'activity_date': _formatDate(activity.date),
          'steps': activity.steps,
          'calories_burned': activity.caloriesBurned,
          'active_calories': activity.caloriesBurned, // Use same value if no separate active calories
          'resting_heart_rate': activity.restingHeartRate,
          'sleep_minutes': activity.sleepMinutes,
          'deep_sleep_minutes': activity.deepSleepMinutes,
          'rem_sleep_minutes': activity.remSleepMinutes,
          'avg_heart_rate': activity.avgHeartRate,
          'max_heart_rate': activity.maxHeartRate,
          'light_sleep_minutes': activity.lightSleepMinutes,
          'awake_sleep_minutes': activity.awakeSleepMinutes,
          'sleep_start': activity.sleepStart?.toIso8601String(),
          'sleep_end': activity.sleepEnd?.toIso8601String(),
          'sleep_latency_minutes': activity.sleepLatencyMinutes,
          'sleep_efficiency': activity.sleepEfficiency,
          // FEATURE 1 — the in-app sleep score + wake-up count for the morning push.
          'sleep_score': activity.sleepScore,
          'wake_ups': activity.wakeUps,
          'water_ml': activity.waterMl,
          // Active/exercise minutes — populated by the Apple Watch companion
          // sync (watch_sync). The phone Health Connect read does NOT request
          // EXERCISE_TIME: that would re-expand the deliberately minimised HC
          // permission scope and needs a Play Data Safety review first.
          'active_minutes': activity.activeMinutes ?? 0,
          // Vitals overnight bio-signals — only sent when present so a daytime
          // sync (no overnight reading yet) never nulls out the night's values.
          if (activity.hrv != null) 'hrv': activity.hrv,
          if (activity.bloodOxygen != null) 'blood_oxygen': activity.bloodOxygen,
          if (activity.respiratoryRate != null)
            'respiratory_rate': activity.respiratoryRate,
          if (activity.bodyTemperature != null)
            'body_temperature': activity.bodyTemperature,
          'source': Platform.isAndroid ? 'health_connect' : 'apple_health',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Activity] Synced activity successfully');
        return response.data as Map<String, dynamic>?;
      } else {
        debugPrint('❌ [Activity] Sync failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Surface 403 (consent missing) once and disable retries for this session.
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('Forbidden')) {
        _consentDenied = true;
        unawaited(_persistConsentDenied());
        debugPrint('🚫 [Activity] Health consent missing — sync gated until user re-enables');
      } else {
        debugPrint('❌ [Activity] Error syncing activity: $e');
      }
      return null;
    } finally {
      attemptCompleter?.complete();
    }
  }

  /// Manually correct a day's activity / sleep (Gap 5 — "edit anything").
  ///
  /// Only pass the fields the user actually edited; each becomes a LOCKED
  /// override the backend protects from future wearable re-syncs. Pass `0`
  /// (not null) to assert "I wasn't wearing it" (e.g. sleepMinutes: 0).
  /// Returns the updated activity map, or null on failure.
  Future<Map<String, dynamic>?> overrideDailyActivity({
    required String userId,
    required DateTime date,
    int? steps,
    int? activeCalories,
    int? sleepMinutes,
    int? deepSleepMinutes,
    int? remSleepMinutes,
    int? lightSleepMinutes,
    int? restingHeartRate,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'activity_date': _formatDate(date),
        if (steps != null) 'steps': steps,
        if (activeCalories != null) 'active_calories': activeCalories,
        if (sleepMinutes != null) 'sleep_minutes': sleepMinutes,
        if (deepSleepMinutes != null) 'deep_sleep_minutes': deepSleepMinutes,
        if (remSleepMinutes != null) 'rem_sleep_minutes': remSleepMinutes,
        if (lightSleepMinutes != null) 'light_sleep_minutes': lightSleepMinutes,
        if (restingHeartRate != null) 'resting_heart_rate': restingHeartRate,
      };
      final response = await _apiClient.patch('/activity/override', data: body);
      if (response.statusCode == 200) {
        debugPrint('✅ [Activity] Override saved');
        return response.data as Map<String, dynamic>?;
      }
      debugPrint('❌ [Activity] Override failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error overriding activity: $e');
      return null;
    }
  }

  /// Get today's activity from backend
  Future<DailyActivity?> getTodayActivity(String userId) async {
    try {
      final response = await _apiClient.get(
        '/activity/today/$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseActivity(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error getting today activity: $e');
      return null;
    }
  }

  /// Get today's calories burned from chat- / manually-logged activities.
  ///
  /// Phase 6 — feeds the home flame icon so an AI-Coach-logged activity
  /// ("I did 30 min yoga") shows its burned calories even without a
  /// connected wearable. The backend already de-duplicates against
  /// wearable-synced sessions, so this value can be safely ADDED to the
  /// HealthKit total without double-counting.
  Future<int> getAiBurnedCaloriesToday(String userId) async {
    try {
      final response = await _apiClient.get('/activity/ai-burned/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return (data['ai_burned_calories'] as num?)?.round() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [Activity] Error getting AI burned calories: $e');
      return 0;
    }
  }

  /// Get activity history from backend
  Future<List<DailyActivity>> getActivityHistory(
    String userId, {
    int limit = 30,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) {
        queryParams['from_date'] = _formatDate(fromDate);
      }
      if (toDate != null) {
        queryParams['to_date'] = _formatDate(toDate);
      }

      final response = await _apiClient.get(
        '/activity/history/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List<dynamic>;
        return list.map((item) => _parseActivity(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Activity] Error getting activity history: $e');
      return [];
    }
  }

  /// Get activity summary from backend
  Future<Map<String, dynamic>?> getActivitySummary(
    String userId, {
    int days = 7,
  }) async {
    try {
      final response = await _apiClient.get(
        '/activity/summary/$userId',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Activity] Error getting activity summary: $e');
      return null;
    }
  }

  /// Batch sync multiple days of activity
  Future<Map<String, dynamic>?> batchSyncActivities({
    required String userId,
    required List<DailyActivity> activities,
  }) async {
    // Always re-read the persisted gate (a single cheap bool read): AISettings
    // seeds it proactively from the server's health_data_consent AFTER this
    // service is constructed, so a one-time in-memory cache would miss the seed
    // and fire a stray first-launch 403.
    await _loadConsentFlag();
    if (_firstAttemptInFlight != null) {
      try { await _firstAttemptInFlight; } catch (_) {}
    }
    if (_consentDenied) {
      debugPrint('⏭️ [Activity] Batch sync skipped — health consent denied (persisted)');
      return null;
    }
    final attemptCompleter = _firstAttemptInFlight == null ? Completer<void>() : null;
    if (attemptCompleter != null) {
      _firstAttemptInFlight = attemptCompleter.future;
    }
    try {
      debugPrint('🏃 [Activity] Batch syncing ${activities.length} days...');

      // See `syncActivity` above — same minimum-scope payload trim applies.
      final data = activities.map((a) => {
        'user_id': userId,
        'activity_date': _formatDate(a.date),
        'steps': a.steps,
        'calories_burned': a.caloriesBurned,
        'active_calories': a.caloriesBurned,
        'resting_heart_rate': a.restingHeartRate,
        'sleep_minutes': a.sleepMinutes,
        'deep_sleep_minutes': a.deepSleepMinutes,
        'rem_sleep_minutes': a.remSleepMinutes,
        'avg_heart_rate': a.avgHeartRate,
        'max_heart_rate': a.maxHeartRate,
        'light_sleep_minutes': a.lightSleepMinutes,
        'awake_sleep_minutes': a.awakeSleepMinutes,
        'sleep_start': a.sleepStart?.toIso8601String(),
        'sleep_end': a.sleepEnd?.toIso8601String(),
        'sleep_latency_minutes': a.sleepLatencyMinutes,
        'sleep_efficiency': a.sleepEfficiency,
        // FEATURE 1 — the in-app sleep score + wake-up count for the morning push.
        'sleep_score': a.sleepScore,
        'wake_ups': a.wakeUps,
        'water_ml': a.waterMl,
        'source': Platform.isAndroid ? 'health_connect' : 'apple_health',
      }).toList();

      final response = await _apiClient.post(
        '/activity/sync-batch',
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Activity] Batch sync completed');
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('Forbidden')) {
        _consentDenied = true;
        unawaited(_persistConsentDenied());
        debugPrint('🚫 [Activity] Health consent missing — batch sync gated until user re-enables');
      } else {
        debugPrint('❌ [Activity] Error batch syncing: $e');
      }
      return null;
    } finally {
      attemptCompleter?.complete();
    }
  }

  /// Parse activity from JSON response. The backend may still return
  /// `distance_meters` / `hrv` / `blood_oxygen` / `body_temperature` /
  /// `respiratory_rate` / `flights_climbed` / `basal_calories` for rows
  /// written by older app versions, but the new client doesn't surface
  /// them — see Google Play Health Connect minimum-scope edit (2026-05-07).
  DailyActivity _parseActivity(Map<String, dynamic> json) {
    return DailyActivity(
      steps: json['steps'] as int? ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0,
      restingHeartRate: json['resting_heart_rate'] as int?,
      sleepMinutes: json['sleep_minutes'] as int?,
      deepSleepMinutes: json['deep_sleep_minutes'] as int?,
      remSleepMinutes: json['rem_sleep_minutes'] as int?,
      date: DateTime.parse(json['activity_date'] as String),
      isFromHealthConnect: true,
      avgHeartRate: json['avg_heart_rate'] as int?,
      maxHeartRate: json['max_heart_rate'] as int?,
      lightSleepMinutes: json['light_sleep_minutes'] as int?,
      awakeSleepMinutes: json['awake_sleep_minutes'] as int?,
      sleepStart: json['sleep_start'] != null ? DateTime.tryParse(json['sleep_start'] as String) : null,
      sleepEnd: json['sleep_end'] != null ? DateTime.tryParse(json['sleep_end'] as String) : null,
      sleepLatencyMinutes: json['sleep_latency_minutes'] as int?,
      sleepEfficiency: (json['sleep_efficiency'] as num?)?.toDouble(),
      sleepScore: json['sleep_score'] as int?,
      wakeUps: json['wake_ups'] as int?,
      waterMl: json['water_ml'] as int?,
    );
  }

  /// Format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
