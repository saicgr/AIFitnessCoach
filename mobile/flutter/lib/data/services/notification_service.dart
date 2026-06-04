import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'api_client.dart';
import 'recipe_notification_router.dart';
import 'crate_notification_router.dart';
import '../../core/services/posthog_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/coach_notification_templates.dart';
import '../../utils/tz.dart';
import 'package:fitwiz/core/constants/branding.dart';


part 'notification_service_ext.dart';
part 'notification_service_ext_ext.dart';
part 'notification_service_part_channel_config.dart';
part 'notification_service_part_notification_preferences.dart';


/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM] Background message: ${message.notification?.title}');
}

/// Notification preferences keys
class NotificationPrefsKeys {
  static const workoutReminders = 'notif_workout_reminders';
  static const nutritionReminders = 'notif_nutrition_reminders';
  static const hydrationReminders = 'notif_hydration_reminders';
  static const aiCoachMessages = 'notif_ai_coach_messages';
  static const streakAlerts = 'notif_streak_alerts';
  static const weeklySummary = 'notif_weekly_summary';
  static const billingReminders = 'notif_billing_reminders';
  static const movementReminders = 'notif_movement_reminders';
  static const liveChatMessages = 'notif_live_chat_messages';
  static const cachedCoachId = 'notif_cached_coach_id';
  static const quietHoursStart = 'notif_quiet_hours_start';
  static const quietHoursEnd = 'notif_quiet_hours_end';
  // Time preferences for scheduled notifications
  static const workoutReminderTime = 'notif_workout_reminder_time';
  static const nutritionBreakfastTime = 'notif_nutrition_breakfast_time';
  static const nutritionLunchTime = 'notif_nutrition_lunch_time';
  static const nutritionDinnerTime = 'notif_nutrition_dinner_time';
  static const hydrationStartTime = 'notif_hydration_start_time';
  static const hydrationEndTime = 'notif_hydration_end_time';
  static const hydrationIntervalMinutes = 'notif_hydration_interval_minutes';
  static const streakAlertTime = 'notif_streak_alert_time';
  static const weeklySummaryDay = 'notif_weekly_summary_day'; // 0=Sunday, 6=Saturday
  static const weeklySummaryTime = 'notif_weekly_summary_time';
  // Movement reminder (NEAT) preferences
  static const movementReminderStartTime = 'notif_movement_start_time';
  static const movementReminderEndTime = 'notif_movement_end_time';
  static const movementStepThreshold = 'notif_movement_step_threshold';
  // Smart timing
  static const smartTimingEnabled = 'notif_smart_timing_enabled';
  // Accountability Coach
  static const missedWorkoutNudge = 'notif_missed_workout_nudge';
  static const missedWorkoutTime = 'notif_missed_workout_time';
  static const postWorkoutMealReminder = 'notif_post_workout_meal_reminder';
  static const postWorkoutMealDelayMinutes = 'notif_post_workout_meal_delay';
  static const habitReminders = 'notif_habit_reminders';
  static const habitReminderTime = 'notif_habit_reminder_time';
  static const weeklyCheckinReminder = 'notif_weekly_checkin_reminder';
  static const weeklyCheckinDay = 'notif_weekly_checkin_day';
  static const weeklyCheckinTime = 'notif_weekly_checkin_time';
  static const streakCelebration = 'notif_streak_celebration';
  static const milestoneCelebration = 'notif_milestone_celebration';
  static const dailyNudgeLimit = 'notif_daily_nudge_limit';
  static const accountabilityIntensity = 'notif_accountability_intensity';
  static const aiPersonalizedNudges = 'notif_ai_personalized_nudges';
  static const guiltNotifications = 'notif_guilt_notifications';
  // Daily crate reminder
  static const dailyCrateReminders = 'notif_daily_crate_reminders';
  static const dailyCrateReminderTime = 'notif_daily_crate_reminder_time';
  // Proactive health coaching (Phase C2) — per-type toggles + delivery times
  static const dailyBriefingNudge = 'notif_daily_briefing_nudge';
  static const dailyBriefingTime = 'notif_daily_briefing_time';
  // Morning sleep-score push (FEATURE 1) — per-type toggle + delivery time.
  static const sleepScoreNudge = 'notif_sleep_score_nudge';
  static const sleepScoreTime = 'notif_sleep_score_time';
  static const healthAnomalyNudge = 'notif_health_anomaly_nudge';
  static const activityGoalNudge = 'notif_activity_goal_nudge';
  static const activityNudgeTime = 'notif_activity_nudge_time';
  // Frequency preset
  static const frequencyPreset = 'notif_frequency_preset';
  // Bundle times
  static const morningBundleTime = 'notif_morning_bundle_time';
  static const middayBundleTime = 'notif_midday_bundle_time';
  static const afternoonNudgeTime = 'notif_afternoon_nudge_time';
  static const eveningBundleTime = 'notif_evening_bundle_time';
  // Weekend scheduling
  static const weekendTimesEnabled = 'notif_weekend_times_enabled';
  static const morningBundleTimeWeekend = 'notif_morning_bundle_time_weekend';
  static const middayBundleTimeWeekend = 'notif_midday_bundle_time_weekend';
  static const eveningBundleTimeWeekend = 'notif_evening_bundle_time_weekend';
  // Bundle content toggles
  static const morningIncludeWorkout = 'notif_morning_include_workout';
  static const morningIncludeBreakfast = 'notif_morning_include_breakfast';
  static const morningIncludeMotivation = 'notif_morning_include_motivation';
  static const middayIncludeLunch = 'notif_midday_include_lunch';
  static const middayIncludeHydration = 'notif_midday_include_hydration';
  static const eveningIncludeDinner = 'notif_evening_include_dinner';
  static const eveningIncludeStreak = 'notif_evening_include_streak';
  static const eveningIncludeProgress = 'notif_evening_include_progress';
  // Style preferences
  static const notificationEmoji = 'notif_emoji_enabled';
  static const notificationVibration = 'notif_vibration_enabled';
  // Master push toggle (item 6a) — gates ALL server-sent push.
  static const pushNotificationsEnabled = 'notif_push_enabled';
  // Evening recap (flagship moment; morning readiness reuses dailyBriefing*).
  static const eveningRecapNudge = 'notif_evening_recap_nudge';
  static const eveningRecapTime = 'notif_evening_recap_time';
  // Data-grounded coach moments (WS3) — per-type toggles, no local times.
  static const weeklyRecapNudge = 'notif_weekly_recap_nudge';
  static const sleepDebtNudge = 'notif_sleep_debt_nudge';
  static const rhrTrendNudge = 'notif_rhr_trend_nudge';
  static const proteinTrendNudge = 'notif_protein_trend_nudge';
  static const volumeBalanceNudge = 'notif_volume_balance_nudge';
  // Injury recovery check-in (WS-B).
  static const injuryCheckinNudge = 'notif_injury_checkin_nudge';
  // ── Cycle tracking reminders (Phase E) ──────────────────────────
  // Each cycle reminder type has its OWN toggle so the user has granular
  // control (per project notification-control rule). All cycle reminders
  // additionally respect the global quiet hours. The fertile-window and
  // peak-fertility reminders are only scheduled in TTC tracking mode.
  // `cycleRemindersMaster` is a feature-level on/off — it gates the whole
  // cycle reminder group, mirroring how the feature itself is gated on
  // `menstrual_tracking_enabled`.
  static const cycleRemindersMaster = 'notif_cycle_reminders_master';
  static const cyclePeriodApproaching = 'notif_cycle_period_approaching';
  static const cyclePeriodStart = 'notif_cycle_period_start';
  static const cycleFertileWindow = 'notif_cycle_fertile_window';
  static const cyclePeakFertility = 'notif_cycle_peak_fertility';
  static const cycleBbtReminder = 'notif_cycle_bbt_reminder';
  static const cycleBbtReminderTime = 'notif_cycle_bbt_reminder_time';
  static const cycleSymptomCheckin = 'notif_cycle_symptom_checkin';
  static const cycleSymptomCheckinTime = 'notif_cycle_symptom_checkin_time';
  static const cycleLatePeriodAlert = 'notif_cycle_late_period_alert';
  static const cycleReminderTimeOfDay = 'notif_cycle_reminder_time_of_day';
  // How many days before the predicted period the "approaching" reminder
  // fires (1-5). Default 2.
  static const cyclePeriodApproachingLeadDays =
      'notif_cycle_period_approaching_lead_days';
  // Cached cycle prediction (ISO dates) used to schedule the date-anchored
  // cycle reminders. Written by the cycle providers; read at reschedule.
  static const cycleNextPeriodDate = 'notif_cycle_next_period_date';
  static const cycleFertileWindowStart = 'notif_cycle_fertile_window_start';
  static const cyclePeakFertilityStart = 'notif_cycle_peak_fertility_start';
  static const cyclePredictedLateDate = 'notif_cycle_predicted_late_date';
  static const cycleTrackingMode = 'notif_cycle_tracking_mode';
  // Cached workout name for bundle templates
  static const cachedWorkoutName = 'notif_cached_workout_name';
  // Cached user context
  static const cachedUserName = 'notif_cached_user_name';
  static const cachedStreak = 'notif_cached_streak';
  // App open times for smart timing
  static const appOpenTimes = 'notif_app_open_times';
}

/// Callback type for handling notification taps
typedef OnNotificationTappedCallback = void Function(String? notificationType);

/// Callback type for FCM token refresh - allows syncing new token to backend
typedef OnTokenRefreshCallback = void Function(String newToken);

/// Notification service for FCM + Local Notifications
class NotificationService {
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  bool _firebaseAvailable = false;

  /// Get Firebase Messaging instance, initializing lazily
  FirebaseMessaging? get messaging {
    if (!_firebaseAvailable) return null;
    _messaging ??= FirebaseMessaging.instance;
    return _messaging;
  }

  /// Callback to store received notifications in the app's notification inbox
  OnNotificationReceivedCallback? onNotificationReceived;

  /// Callback to handle notification taps (for navigation)
  OnNotificationTappedCallback? onNotificationTapped;

  /// Backend-provided deep-link path stashed by `_handleMessageOpenedApp`
  /// when a push notification's data payload includes `deep_link`. Consumed
  /// by `_navigateToScreenForNotificationType` in app.dart as a fallback
  /// when the type-based switch falls through, so new nudge types ship
  /// from the backend without a matching client release.
  static String? pendingDeepLink;

  /// Callback for FCM token refresh - set this to sync token to backend
  OnTokenRefreshCallback? onTokenRefresh;

  /// Callback when an accountability coach nudge arrives in foreground.
  /// Set by the chat screen to trigger a message list refresh when the user
  /// is already viewing the chat while a proactive coach message arrives.
  VoidCallback? onCoachNudgeReceived;

  String? get fcmToken => _fcmToken;

  /// Notification channel configurations for different coaches
  static const Map<String, _ChannelConfig> _channelConfigs = {
    'workout_reminder': _ChannelConfig(
      id: 'workout_coach',
      name: 'Workout Coach',
      description: 'Workout reminders and motivation from your Workout Coach',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'nutrition_reminder': _ChannelConfig(
      id: 'nutrition_coach',
      name: 'Nutrition Coach',
      description: 'Meal logging reminders from your Nutrition Coach',
      color: Color(0xFF4ADE80), // Green
    ),
    'hydration_reminder': _ChannelConfig(
      id: 'hydration_coach',
      name: 'Hydration Coach',
      description: 'Water intake reminders from your Hydration Coach',
      color: Color(0xFF3B82F6), // Blue
    ),
    'streak_alert': _ChannelConfig(
      id: 'streak_coach',
      name: 'Streak Coach',
      description: 'Streak celebrations and alerts',
      color: Color(0xFFF97316), // Orange
    ),
    'weekly_summary': _ChannelConfig(
      id: 'progress_coach',
      name: 'Progress Coach',
      description: 'Weekly summaries and progress updates',
      color: Color(0xFFA855F7), // Purple
    ),
    'billing_reminder': _ChannelConfig(
      id: 'billing_coach',
      name: 'Billing Reminders',
      description: 'Subscription renewal and billing notifications',
      color: Color(0xFF10B981), // Emerald
    ),
    'movement_reminder': _ChannelConfig(
      id: 'movement_coach',
      name: 'Movement Coach',
      description: 'Hourly movement reminders to reduce sedentary time',
      color: Color(0xFFEAB308), // Yellow
    ),
    'ai_coach': _ChannelConfig(
      id: 'ai_coach',
      name: 'AI Coach',
      description: 'General messages from your ${Branding.appName} coach',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'test': _ChannelConfig(
      id: 'test_notifications',
      name: 'Test Notifications',
      description: 'Test notifications',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'live_chat': _ChannelConfig(
      id: 'live_chat',
      name: 'Live Chat Support',
      description: 'Messages from support agents',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'live_chat_message': _ChannelConfig(
      id: 'live_chat',
      name: 'Live Chat Support',
      description: 'Messages from support agents',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'live_chat_connected': _ChannelConfig(
      id: 'live_chat',
      name: 'Live Chat Support',
      description: 'Messages from support agents',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'live_chat_ended': _ChannelConfig(
      id: 'live_chat',
      name: 'Live Chat Support',
      description: 'Messages from support agents',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'daily_bundle': _ChannelConfig(
      id: 'daily_bundle',
      name: 'Daily Check-ins',
      description: 'Morning, midday, and evening check-in notifications',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'schedule_reminder': _ChannelConfig(
      id: 'schedule_reminder',
      name: 'Schedule Reminders',
      description: 'Reminders for your scheduled activities, meals, and habits',
      color: Color(0xFF06B6D4), // Cyan
    ),
    // Cycle tracking reminders (period / fertility / BBT / symptom check-in).
    // One channel for the whole feature so the OS groups them and the user
    // has a single per-channel control in system settings; the in-app
    // per-type toggles live in NotificationPreferences.
    'cycle_reminder': _ChannelConfig(
      id: 'cycle_reminder',
      name: 'Cycle Reminders',
      description: 'Period, fertility, and cycle-logging reminders',
      color: Color(0xFFEC4899), // Pink — the cycle feature accent
    ),
  };

  /// Default channel for unknown types
  static const _defaultChannel = _ChannelConfig(
    id: 'fitwiz_notifications',
    name: '${Branding.appName}',
    description: 'Notifications from your ${Branding.appName} coach',
    color: Color(0xFF00D9FF),
  );

  /// Initialize local timezone based on device timezone offset
  void _initializeLocalTimezone() {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset;

    // Find a timezone that matches the device's current offset
    // Common US timezones
    final timezoneMap = {
      const Duration(hours: -5): 'America/New_York', // EST
      const Duration(hours: -6): 'America/Chicago', // CST
      const Duration(hours: -7): 'America/Denver', // MST
      const Duration(hours: -8): 'America/Los_Angeles', // PST
      const Duration(hours: -4): 'America/New_York', // EDT (summer)
      const Duration(hours: 0): 'UTC',
      const Duration(hours: 1): 'Europe/London',
      const Duration(hours: 5, minutes: 30): 'Asia/Kolkata',
    };

    String tzName = 'America/Chicago'; // Default to CST
    for (final entry in timezoneMap.entries) {
      if (entry.key == localOffset) {
        tzName = entry.value;
        break;
      }
    }

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('🔔 [Timezone] Set to $tzName (offset: $localOffset)');
    } catch (e) {
      // Fallback to UTC
      tz.setLocalLocation(tz.UTC);
      debugPrint('⚠️ [Timezone] Fallback to UTC: $e');
    }
  }

  /// Initialize Firebase Messaging and Local Notifications
  /// Note: Permission request is deferred until requestPermissionWhenReady() is called
  /// after the Activity is available (post-runApp)
  Future<void> initialize() async {
    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();
    // Set local timezone based on device's current offset
    _initializeLocalTimezone();

    // Check if Firebase is available
    try {
      // This will throw if Firebase is not initialized
      _firebaseAvailable = Firebase.apps.isNotEmpty;
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('⚠️ [FCM] Firebase not available: $e');
    }

    if (_firebaseAvailable) {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Attach FCM listeners on EVERY cold launch so notification taps always
      // route to the right screen — not just on first-run when the
      // NotificationPrimeScreen calls requestPermissionWhenReady(). Without
      // this, returning users tap a "nutrition reminder" push and just land
      // on home because no onMessageOpenedApp handler is registered.
      try {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Cold-start FCM tap: app was launched (terminated → opened) by
        // tapping a push. Defer to next frame so router/auth are ready.
        final initialMessage = await messaging?.getInitialMessage();
        if (initialMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleMessageOpenedApp(initialMessage);
          });
        }
        debugPrint('🔔 [FCM] Listeners attached in initialize()');
      } catch (e) {
        debugPrint('⚠️ [FCM] Failed to attach listeners in initialize(): $e');
      }
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // NOTE: Permission request and FCM token retrieval are deferred to
    // requestPermissionWhenReady() to avoid "Unable to detect current Android Activity"
    // error when called before runApp() completes

    // Exact alarm permission removed — using inexact scheduling instead

    // NOTE: Firebase Messaging listeners are set up in requestPermissionWhenReady()
    // because they require Activity context on Android

    debugPrint('🔔 [FCM] Notification service initialized (Firebase: $_firebaseAvailable)');
  }

  /// Request permission and get FCM token after Activity is ready
  /// Call this from a widget's initState or after runApp() completes
  Future<void> requestPermissionWhenReady() async {
    // Request LOCAL notification permission on Android 13+ (API 33+)
    // This is separate from Firebase Messaging permission and required for
    // flutter_local_notifications to show notifications
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // Check if permission is already granted
          final granted = await androidPlugin.areNotificationsEnabled() ?? false;
          debugPrint('🔔 [Local] Android notifications enabled: $granted');

          if (!granted) {
            // Request permission - this shows the system dialog on Android 13+
            final result = await androidPlugin.requestNotificationsPermission();
            debugPrint('🔔 [Local] Android notification permission result: $result');
          }
        }
      } catch (e) {
        // Can fail with null context if Activity is not yet fully attached
        debugPrint('⚠️ [Local] Android notification permission request failed: $e');
      }
    }

    if (!_firebaseAvailable) {
      debugPrint('⚠️ [FCM] Firebase not available, skipping FCM permission request');
      // Even without Firebase, local notifications should still work
      return;
    }

    debugPrint('🔔 [FCM] Requesting permission and token...');

    try {
      // Request FCM permission (required for iOS and Android 13+)
      final permGranted = await _requestPermission();
      debugPrint('🔔 [FCM] Permission granted: $permGranted');

      // Get FCM token after permission is granted
      await _getToken();
      debugPrint('🔔 [FCM] Token result: ${_fcmToken != null ? "obtained" : "NULL"}');

      // FCM message listeners (onMessage, onMessageOpenedApp, getInitialMessage)
      // are attached in initialize() so they run on every cold launch, not
      // just when the prime screen runs. Here we only attach the token-refresh
      // listener since it depends on _fcmToken being populated above.
      if (messaging != null) {
        messaging!.onTokenRefresh.listen((newToken) {
          debugPrint('🔔 [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
          _fcmToken = newToken;
          onTokenRefresh?.call(newToken);
        });
      }

      debugPrint('✅ [FCM] Permission requested, token retrieved, and listeners configured');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error requesting permission: $e');
    }
  }
}

/// Callback type for syncing preferences to backend
typedef PreferencesSyncCallback = Future<void> Function(NotificationPreferences prefs);

/// Notification preferences notifier
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  PreferencesSyncCallback? _onPreferencesChanged;

  // Coalesce rapid toggle bursts so the OS reschedule (which can rebuild
  // dozens of pending notifications) and the backend sync (network) only
  // run once per ~300ms instead of once per tap. UI state still flips per
  // tap because state mutation is synchronous in every setter.
  Timer? _rescheduleDebounce;
  Timer? _syncDebounce;
  static const _rescheduleDebounceDelay = Duration(milliseconds: 300);
  static const _syncDebounceDelay = Duration(milliseconds: 500);

  NotificationPreferencesNotifier(
    this._prefs,
    this._notificationService,
  ) : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  @override
  void dispose() {
    // Flush any pending background work before tearing down so the user's
    // last toggle isn't lost if they switch screens immediately.
    _rescheduleDebounce?.cancel();
    _syncDebounce?.cancel();
    unawaited(_notificationService.scheduleAllNotifications(state));
    if (_onPreferencesChanged != null) {
      unawaited(_onPreferencesChanged!(state));
    }
    super.dispose();
  }

  /// Set the callback to sync preferences to backend
  /// This should be called after the API client is available (e.g., after login)
  void setSyncCallback(PreferencesSyncCallback callback) {
    _onPreferencesChanged = callback;
    // Sync immediately when callback is set
    _syncPreferencesToBackend();
  }

  void _loadPreferences() {
    state = NotificationPreferences(
      workoutReminders: _prefs.getBool(NotificationPrefsKeys.workoutReminders) ?? true,
      nutritionReminders: _prefs.getBool(NotificationPrefsKeys.nutritionReminders) ?? true,
      hydrationReminders: _prefs.getBool(NotificationPrefsKeys.hydrationReminders) ?? true,
      aiCoachMessages: _prefs.getBool(NotificationPrefsKeys.aiCoachMessages) ?? true,
      streakAlerts: _prefs.getBool(NotificationPrefsKeys.streakAlerts) ?? true,
      weeklySummary: _prefs.getBool(NotificationPrefsKeys.weeklySummary) ?? true,
      billingReminders: _prefs.getBool(NotificationPrefsKeys.billingReminders) ?? true,
      movementReminders: _prefs.getBool(NotificationPrefsKeys.movementReminders) ?? true,
      liveChatMessages: _prefs.getBool(NotificationPrefsKeys.liveChatMessages) ?? true,
      quietHoursStart: _prefs.getString(NotificationPrefsKeys.quietHoursStart) ?? '22:00',
      quietHoursEnd: _prefs.getString(NotificationPrefsKeys.quietHoursEnd) ?? '08:00',
      // Time preferences
      workoutReminderTime: _prefs.getString(NotificationPrefsKeys.workoutReminderTime) ?? '08:00',
      nutritionBreakfastTime: _prefs.getString(NotificationPrefsKeys.nutritionBreakfastTime) ?? '08:00',
      nutritionLunchTime: _prefs.getString(NotificationPrefsKeys.nutritionLunchTime) ?? '12:00',
      nutritionDinnerTime: _prefs.getString(NotificationPrefsKeys.nutritionDinnerTime) ?? '18:00',
      hydrationStartTime: _prefs.getString(NotificationPrefsKeys.hydrationStartTime) ?? '08:15',
      hydrationEndTime: _prefs.getString(NotificationPrefsKeys.hydrationEndTime) ?? '20:00',
      hydrationIntervalMinutes: _prefs.getInt(NotificationPrefsKeys.hydrationIntervalMinutes) ?? 120,
      streakAlertTime: _prefs.getString(NotificationPrefsKeys.streakAlertTime) ?? '18:00',
      weeklySummaryDay: _prefs.getInt(NotificationPrefsKeys.weeklySummaryDay) ?? 0,
      weeklySummaryTime: _prefs.getString(NotificationPrefsKeys.weeklySummaryTime) ?? '09:00',
      // Movement reminder preferences
      movementReminderStartTime: _prefs.getString(NotificationPrefsKeys.movementReminderStartTime) ?? '09:05',
      movementReminderEndTime: _prefs.getString(NotificationPrefsKeys.movementReminderEndTime) ?? '17:00',
      movementStepThreshold: _prefs.getInt(NotificationPrefsKeys.movementStepThreshold) ?? 250,
      // Smart timing
      smartTimingEnabled: _prefs.getBool(NotificationPrefsKeys.smartTimingEnabled) ?? false,
      // Accountability Coach
      missedWorkoutNudge: _prefs.getBool(NotificationPrefsKeys.missedWorkoutNudge) ?? true,
      missedWorkoutTime: _prefs.getString(NotificationPrefsKeys.missedWorkoutTime) ?? '19:00',
      postWorkoutMealReminder: _prefs.getBool(NotificationPrefsKeys.postWorkoutMealReminder) ?? true,
      postWorkoutMealDelayMinutes: _prefs.getInt(NotificationPrefsKeys.postWorkoutMealDelayMinutes) ?? 30,
      habitReminders: _prefs.getBool(NotificationPrefsKeys.habitReminders) ?? true,
      habitReminderTime: _prefs.getString(NotificationPrefsKeys.habitReminderTime) ?? '20:00',
      weeklyCheckinReminder: _prefs.getBool(NotificationPrefsKeys.weeklyCheckinReminder) ?? true,
      weeklyCheckinDay: _prefs.getInt(NotificationPrefsKeys.weeklyCheckinDay) ?? 0,
      weeklyCheckinTime: _prefs.getString(NotificationPrefsKeys.weeklyCheckinTime) ?? '09:00',
      streakCelebration: _prefs.getBool(NotificationPrefsKeys.streakCelebration) ?? true,
      milestoneCelebration: _prefs.getBool(NotificationPrefsKeys.milestoneCelebration) ?? true,
      dailyNudgeLimit: _prefs.getInt(NotificationPrefsKeys.dailyNudgeLimit) ?? 4,
      accountabilityIntensity: _prefs.getString(NotificationPrefsKeys.accountabilityIntensity) ?? 'balanced',
      aiPersonalizedNudges: _prefs.getBool(NotificationPrefsKeys.aiPersonalizedNudges) ?? true,
      guiltNotifications: _prefs.getBool(NotificationPrefsKeys.guiltNotifications) ?? true,
      // Daily crate reminder
      dailyCrateReminders: _prefs.getBool(NotificationPrefsKeys.dailyCrateReminders) ?? true,
      dailyCrateReminderTime: _prefs.getString(NotificationPrefsKeys.dailyCrateReminderTime) ?? '10:00',
      // Proactive health coaching (Phase C2)
      dailyBriefingNudge: _prefs.getBool(NotificationPrefsKeys.dailyBriefingNudge) ?? true,
      dailyBriefingTime: _prefs.getString(NotificationPrefsKeys.dailyBriefingTime) ?? '08:00',
      // Morning sleep-score push (FEATURE 1)
      sleepScoreNudge: _prefs.getBool(NotificationPrefsKeys.sleepScoreNudge) ?? true,
      sleepScoreTime: _prefs.getString(NotificationPrefsKeys.sleepScoreTime) ?? '08:00',
      healthAnomalyNudge: _prefs.getBool(NotificationPrefsKeys.healthAnomalyNudge) ?? true,
      activityGoalNudge: _prefs.getBool(NotificationPrefsKeys.activityGoalNudge) ?? true,
      activityNudgeTime: _prefs.getString(NotificationPrefsKeys.activityNudgeTime) ?? '15:00',
      // Frequency preset
      frequencyPreset: _prefs.getString(NotificationPrefsKeys.frequencyPreset) ?? 'balanced',
      // Bundle times
      morningBundleTime: _prefs.getString(NotificationPrefsKeys.morningBundleTime) ?? '07:30',
      middayBundleTime: _prefs.getString(NotificationPrefsKeys.middayBundleTime) ?? '12:30',
      afternoonNudgeTime: _prefs.getString(NotificationPrefsKeys.afternoonNudgeTime) ?? '15:00',
      eveningBundleTime: _prefs.getString(NotificationPrefsKeys.eveningBundleTime) ?? '19:00',
      // Weekend scheduling
      weekendTimesEnabled: _prefs.getBool(NotificationPrefsKeys.weekendTimesEnabled) ?? false,
      morningBundleTimeWeekend: _prefs.getString(NotificationPrefsKeys.morningBundleTimeWeekend) ?? '09:30',
      middayBundleTimeWeekend: _prefs.getString(NotificationPrefsKeys.middayBundleTimeWeekend) ?? '13:00',
      eveningBundleTimeWeekend: _prefs.getString(NotificationPrefsKeys.eveningBundleTimeWeekend) ?? '20:00',
      // Bundle content toggles
      morningIncludeWorkout: _prefs.getBool(NotificationPrefsKeys.morningIncludeWorkout) ?? true,
      morningIncludeBreakfast: _prefs.getBool(NotificationPrefsKeys.morningIncludeBreakfast) ?? true,
      morningIncludeMotivation: _prefs.getBool(NotificationPrefsKeys.morningIncludeMotivation) ?? true,
      middayIncludeLunch: _prefs.getBool(NotificationPrefsKeys.middayIncludeLunch) ?? true,
      middayIncludeHydration: _prefs.getBool(NotificationPrefsKeys.middayIncludeHydration) ?? true,
      eveningIncludeDinner: _prefs.getBool(NotificationPrefsKeys.eveningIncludeDinner) ?? true,
      eveningIncludeStreak: _prefs.getBool(NotificationPrefsKeys.eveningIncludeStreak) ?? true,
      eveningIncludeProgress: _prefs.getBool(NotificationPrefsKeys.eveningIncludeProgress) ?? true,
      // Style preferences
      notificationEmoji: _prefs.getBool(NotificationPrefsKeys.notificationEmoji) ?? true,
      notificationVibration: _prefs.getBool(NotificationPrefsKeys.notificationVibration) ?? true,
      // Cycle tracking reminders (Phase E)
      cycleRemindersMaster: _prefs.getBool(NotificationPrefsKeys.cycleRemindersMaster) ?? true,
      cyclePeriodApproaching: _prefs.getBool(NotificationPrefsKeys.cyclePeriodApproaching) ?? true,
      cyclePeriodStart: _prefs.getBool(NotificationPrefsKeys.cyclePeriodStart) ?? true,
      cycleFertileWindow: _prefs.getBool(NotificationPrefsKeys.cycleFertileWindow) ?? true,
      cyclePeakFertility: _prefs.getBool(NotificationPrefsKeys.cyclePeakFertility) ?? true,
      cycleBbtReminder: _prefs.getBool(NotificationPrefsKeys.cycleBbtReminder) ?? false,
      cycleBbtReminderTime: _prefs.getString(NotificationPrefsKeys.cycleBbtReminderTime) ?? '07:00',
      cycleSymptomCheckin: _prefs.getBool(NotificationPrefsKeys.cycleSymptomCheckin) ?? false,
      cycleSymptomCheckinTime: _prefs.getString(NotificationPrefsKeys.cycleSymptomCheckinTime) ?? '20:00',
      cycleLatePeriodAlert: _prefs.getBool(NotificationPrefsKeys.cycleLatePeriodAlert) ?? true,
      cycleReminderTimeOfDay: _prefs.getString(NotificationPrefsKeys.cycleReminderTimeOfDay) ?? '09:00',
      cyclePeriodApproachingLeadDays: _prefs.getInt(NotificationPrefsKeys.cyclePeriodApproachingLeadDays) ?? 2,
      cycleTrackingMode: _prefs.getString(NotificationPrefsKeys.cycleTrackingMode) ?? 'tracking',
      // Master push toggle (item 6a) + evening recap (flagship moment).
      pushNotificationsEnabled: _prefs.getBool(NotificationPrefsKeys.pushNotificationsEnabled) ?? true,
      eveningRecapNudge: _prefs.getBool(NotificationPrefsKeys.eveningRecapNudge) ?? true,
      eveningRecapTime: _prefs.getString(NotificationPrefsKeys.eveningRecapTime) ?? '20:00',
      // Data-grounded coach moments (WS3) — default ON.
      weeklyRecapNudge: _prefs.getBool(NotificationPrefsKeys.weeklyRecapNudge) ?? true,
      sleepDebtNudge: _prefs.getBool(NotificationPrefsKeys.sleepDebtNudge) ?? true,
      rhrTrendNudge: _prefs.getBool(NotificationPrefsKeys.rhrTrendNudge) ?? true,
      proteinTrendNudge: _prefs.getBool(NotificationPrefsKeys.proteinTrendNudge) ?? true,
      volumeBalanceNudge: _prefs.getBool(NotificationPrefsKeys.volumeBalanceNudge) ?? true,
      // Injury recovery check-in (WS-B) — default ON.
      injuryCheckinNudge: _prefs.getBool(NotificationPrefsKeys.injuryCheckinNudge) ?? true,
    );
    // Schedule notifications on load
    _rescheduleNotifications();
  }

  /// Reschedule all notifications based on current state.
  ///
  /// Now debounced + fire-and-forget so toggle setters never block the UI:
  /// rapid taps coalesce into a single trailing reschedule ~300ms after the
  /// last tap. The returned Future completes immediately — the actual OS
  /// work happens asynchronously and any errors are logged (NOT rolled back
  /// — per the plan's edge-case rule, OS reschedule failure must not
  /// revert the user's preference; only the OS plumbing failed).
  Future<void> _rescheduleNotifications() async {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(_rescheduleDebounceDelay, () {
      unawaited(() async {
        try {
          await _notificationService.scheduleAllNotifications(state);
        } catch (e) {
          debugPrint('⚠️ [Notification] Reschedule failed: $e');
        }
      }());
    });
  }

  /// Public method to trigger rescheduling (e.g., after restoring onboarding flag)
  Future<void> rescheduleNotifications() async {
    await _rescheduleNotifications();
  }

  /// Sync notification preferences to backend.
  ///
  /// Same shape as [_rescheduleNotifications]: debounced + fire-and-forget so
  /// the network roundtrip never blocks a Switch flip. Errors are logged but
  /// the local state stays — the user's preference is recorded locally and
  /// will sync on the next successful call.
  Future<void> _syncPreferencesToBackend() async {
    if (_onPreferencesChanged == null) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(_syncDebounceDelay, () {
      unawaited(() async {
        try {
          await _onPreferencesChanged!(state);
        } catch (e) {
          debugPrint('⚠️ [Notification] Backend sync failed: $e');
        }
      }());
    });
  }

  Future<void> setWorkoutReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.workoutReminders, value);
    state = state.copyWith(workoutReminders: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setNutritionReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.nutritionReminders, value);
    state = state.copyWith(nutritionReminders: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setHydrationReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.hydrationReminders, value);
    state = state.copyWith(hydrationReminders: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setAiCoachMessages(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.aiCoachMessages, value);
    state = state.copyWith(aiCoachMessages: value);
    // AI Coach messages are server-side, so sync is important
    await _syncPreferencesToBackend();
  }

  Future<void> setStreakAlerts(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.streakAlerts, value);
    state = state.copyWith(streakAlerts: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setWeeklySummary(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.weeklySummary, value);
    state = state.copyWith(weeklySummary: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setBillingReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.billingReminders, value);
    state = state.copyWith(billingReminders: value);
    // Billing reminders are server-side, so sync is important
    await _syncPreferencesToBackend();
  }

  Future<void> setLiveChatMessages(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.liveChatMessages, value);
    state = state.copyWith(liveChatMessages: value);
    // Live chat messages are server-side, so sync is important
    await _syncPreferencesToBackend();
  }

  Future<void> setQuietHours(String start, String end) async {
    await _prefs.setString(NotificationPrefsKeys.quietHoursStart, start);
    await _prefs.setString(NotificationPrefsKeys.quietHoursEnd, end);
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
    await _syncPreferencesToBackend();
  }

  // Time preference setters
  Future<void> setWorkoutReminderTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.workoutReminderTime, time);
    state = state.copyWith(workoutReminderTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setNutritionBreakfastTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.nutritionBreakfastTime, time);
    state = state.copyWith(nutritionBreakfastTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setNutritionLunchTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.nutritionLunchTime, time);
    state = state.copyWith(nutritionLunchTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setNutritionDinnerTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.nutritionDinnerTime, time);
    state = state.copyWith(nutritionDinnerTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setHydrationTimes(String startTime, String endTime, int intervalMinutes) async {
    await _prefs.setString(NotificationPrefsKeys.hydrationStartTime, startTime);
    await _prefs.setString(NotificationPrefsKeys.hydrationEndTime, endTime);
    await _prefs.setInt(NotificationPrefsKeys.hydrationIntervalMinutes, intervalMinutes);
    state = state.copyWith(
      hydrationStartTime: startTime,
      hydrationEndTime: endTime,
      hydrationIntervalMinutes: intervalMinutes,
    );
    await _rescheduleNotifications();
  }

  Future<void> setStreakAlertTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.streakAlertTime, time);
    state = state.copyWith(streakAlertTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setWeeklySummarySchedule(int day, String time) async {
    await _prefs.setInt(NotificationPrefsKeys.weeklySummaryDay, day);
    await _prefs.setString(NotificationPrefsKeys.weeklySummaryTime, time);
    state = state.copyWith(weeklySummaryDay: day, weeklySummaryTime: time);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  // Movement reminder setters
  Future<void> setMovementReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.movementReminders, value);
    state = state.copyWith(movementReminders: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setMovementReminderTimes(String startTime, String endTime) async {
    await _prefs.setString(NotificationPrefsKeys.movementReminderStartTime, startTime);
    await _prefs.setString(NotificationPrefsKeys.movementReminderEndTime, endTime);
    state = state.copyWith(
      movementReminderStartTime: startTime,
      movementReminderEndTime: endTime,
    );
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setMovementStepThreshold(int threshold) async {
    await _prefs.setInt(NotificationPrefsKeys.movementStepThreshold, threshold);
    state = state.copyWith(movementStepThreshold: threshold);
    await _syncPreferencesToBackend();
  }

  Future<void> setSmartTimingEnabled(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.smartTimingEnabled, value);
    state = state.copyWith(smartTimingEnabled: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  // ─── Accountability Coach Setters ──────────────────────────────

  Future<void> setMissedWorkoutNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.missedWorkoutNudge, value);
    state = state.copyWith(missedWorkoutNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setMissedWorkoutTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.missedWorkoutTime, time);
    state = state.copyWith(missedWorkoutTime: time);
    await _syncPreferencesToBackend();
  }

  Future<void> setPostWorkoutMealReminder(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.postWorkoutMealReminder, value);
    state = state.copyWith(postWorkoutMealReminder: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setPostWorkoutMealDelay(int minutes) async {
    await _prefs.setInt(NotificationPrefsKeys.postWorkoutMealDelayMinutes, minutes);
    state = state.copyWith(postWorkoutMealDelayMinutes: minutes);
    await _syncPreferencesToBackend();
  }

  Future<void> setHabitReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.habitReminders, value);
    state = state.copyWith(habitReminders: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setHabitReminderTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.habitReminderTime, time);
    state = state.copyWith(habitReminderTime: time);
    await _syncPreferencesToBackend();
  }

  Future<void> setWeeklyCheckinReminder(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.weeklyCheckinReminder, value);
    state = state.copyWith(weeklyCheckinReminder: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setWeeklyCheckinSchedule(int day, String time) async {
    await _prefs.setInt(NotificationPrefsKeys.weeklyCheckinDay, day);
    await _prefs.setString(NotificationPrefsKeys.weeklyCheckinTime, time);
    state = state.copyWith(weeklyCheckinDay: day, weeklyCheckinTime: time);
    await _syncPreferencesToBackend();
  }

  Future<void> setStreakCelebration(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.streakCelebration, value);
    state = state.copyWith(streakCelebration: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setMilestoneCelebration(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.milestoneCelebration, value);
    state = state.copyWith(milestoneCelebration: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setDailyNudgeLimit(int limit) async {
    await _prefs.setInt(NotificationPrefsKeys.dailyNudgeLimit, limit);
    state = state.copyWith(dailyNudgeLimit: limit);
    await _syncPreferencesToBackend();
  }

  Future<void> setAccountabilityIntensity(String intensity) async {
    await _prefs.setString(NotificationPrefsKeys.accountabilityIntensity, intensity);
    state = state.copyWith(accountabilityIntensity: intensity);
    await _syncPreferencesToBackend();
  }

  Future<void> setAiPersonalizedNudges(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.aiPersonalizedNudges, value);
    state = state.copyWith(aiPersonalizedNudges: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setGuiltNotifications(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.guiltNotifications, value);
    state = state.copyWith(guiltNotifications: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setDailyCrateReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.dailyCrateReminders, value);
    state = state.copyWith(dailyCrateReminders: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setDailyCrateReminderTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.dailyCrateReminderTime, time);
    state = state.copyWith(dailyCrateReminderTime: time);
    await _syncPreferencesToBackend();
  }

  // ─── Proactive Health Coaching Setters (Phase C2) ───────────────
  // All four are server-side cron nudges, so syncing to the backend
  // notification_preferences JSON is what actually toggles them.

  Future<void> setDailyBriefingNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.dailyBriefingNudge, value);
    state = state.copyWith(dailyBriefingNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setDailyBriefingTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.dailyBriefingTime, time);
    state = state.copyWith(dailyBriefingTime: time);
    await _syncPreferencesToBackend();
  }

  /// Morning sleep-score push (FEATURE 1) — server-side cron nudge. Shares the
  /// morning slot with the readiness briefing; the backend fires only ONE.
  Future<void> setSleepScoreNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.sleepScoreNudge, value);
    state = state.copyWith(sleepScoreNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setSleepScoreTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.sleepScoreTime, time);
    state = state.copyWith(sleepScoreTime: time);
    await _syncPreferencesToBackend();
  }

  /// Evening recap (flagship moment) — server-side cron nudge.
  Future<void> setEveningRecapNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.eveningRecapNudge, value);
    state = state.copyWith(eveningRecapNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setEveningRecapTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.eveningRecapTime, time);
    state = state.copyWith(eveningRecapTime: time);
    await _syncPreferencesToBackend();
  }

  /// Master push toggle (item 6a) — gates ALL server-sent push. Persisted to
  /// the same `notif_push_enabled` key the local post-meal reminder reads, and
  /// synced to the backend as `push_notifications_enabled` (every server nudge
  /// job short-circuits when false).
  Future<void> setPushNotificationsEnabled(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.pushNotificationsEnabled, value);
    state = state.copyWith(pushNotificationsEnabled: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setHealthAnomalyNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.healthAnomalyNudge, value);
    state = state.copyWith(healthAnomalyNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setActivityGoalNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.activityGoalNudge, value);
    state = state.copyWith(activityGoalNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setActivityNudgeTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.activityNudgeTime, time);
    state = state.copyWith(activityNudgeTime: time);
    await _syncPreferencesToBackend();
  }

  // ─── Data-grounded coach moment setters (WS3) ───────────────────
  // All five are server-side cron nudges, so syncing the JSONB to the backend
  // is what actually toggles them.

  Future<void> setWeeklyRecapNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.weeklyRecapNudge, value);
    state = state.copyWith(weeklyRecapNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setSleepDebtNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.sleepDebtNudge, value);
    state = state.copyWith(sleepDebtNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setRhrTrendNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.rhrTrendNudge, value);
    state = state.copyWith(rhrTrendNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setProteinTrendNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.proteinTrendNudge, value);
    state = state.copyWith(proteinTrendNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setVolumeBalanceNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.volumeBalanceNudge, value);
    state = state.copyWith(volumeBalanceNudge: value);
    await _syncPreferencesToBackend();
  }

  Future<void> setInjuryCheckinNudge(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.injuryCheckinNudge, value);
    state = state.copyWith(injuryCheckinNudge: value);
    await _syncPreferencesToBackend();
  }

  // ─── Frequency Preset & Bundle Setters ──────────────────────────

  Future<void> setFrequencyPreset(String preset) async {
    await _prefs.setString(NotificationPrefsKeys.frequencyPreset, preset);

    // Derive preset-specific settings
    switch (preset) {
      case 'minimal':
        await _prefs.setInt(NotificationPrefsKeys.dailyNudgeLimit, 2);
        state = state.copyWith(
          frequencyPreset: preset,
          dailyNudgeLimit: 2,
          // Disable individual notifications (bundles handle everything)
          workoutReminders: false,
          nutritionReminders: false,
          hydrationReminders: false,
          movementReminders: false,
        );
        break;
      case 'balanced':
        await _prefs.setInt(NotificationPrefsKeys.dailyNudgeLimit, 3);
        state = state.copyWith(
          frequencyPreset: preset,
          dailyNudgeLimit: 3,
          workoutReminders: false,
          nutritionReminders: false,
          hydrationReminders: false,
          movementReminders: false,
        );
        break;
      case 'full_coach':
        await _prefs.setInt(NotificationPrefsKeys.dailyNudgeLimit, 8);
        state = state.copyWith(
          frequencyPreset: preset,
          dailyNudgeLimit: 8,
          workoutReminders: true,
          nutritionReminders: true,
          hydrationReminders: true,
          movementReminders: true,
        );
        break;
    }

    // Persist derived boolean settings
    await _prefs.setBool(NotificationPrefsKeys.workoutReminders, state.workoutReminders);
    await _prefs.setBool(NotificationPrefsKeys.nutritionReminders, state.nutritionReminders);
    await _prefs.setBool(NotificationPrefsKeys.hydrationReminders, state.hydrationReminders);
    await _prefs.setBool(NotificationPrefsKeys.movementReminders, state.movementReminders);

    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setMorningBundleTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.morningBundleTime, time);
    state = state.copyWith(morningBundleTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setMiddayBundleTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.middayBundleTime, time);
    state = state.copyWith(middayBundleTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setAfternoonNudgeTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.afternoonNudgeTime, time);
    state = state.copyWith(afternoonNudgeTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setEveningBundleTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.eveningBundleTime, time);
    state = state.copyWith(eveningBundleTime: time);
    await _rescheduleNotifications();
  }

  Future<void> setWeekendTimesEnabled(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.weekendTimesEnabled, value);
    state = state.copyWith(weekendTimesEnabled: value);
    await _rescheduleNotifications();
  }

  Future<void> setWeekendBundleTimes(String morning, String midday, String evening) async {
    await _prefs.setString(NotificationPrefsKeys.morningBundleTimeWeekend, morning);
    await _prefs.setString(NotificationPrefsKeys.middayBundleTimeWeekend, midday);
    await _prefs.setString(NotificationPrefsKeys.eveningBundleTimeWeekend, evening);
    state = state.copyWith(
      morningBundleTimeWeekend: morning,
      middayBundleTimeWeekend: midday,
      eveningBundleTimeWeekend: evening,
    );
    await _rescheduleNotifications();
  }

  Future<void> setMorningBundleContent(bool workout, bool breakfast, bool motivation) async {
    await _prefs.setBool(NotificationPrefsKeys.morningIncludeWorkout, workout);
    await _prefs.setBool(NotificationPrefsKeys.morningIncludeBreakfast, breakfast);
    await _prefs.setBool(NotificationPrefsKeys.morningIncludeMotivation, motivation);
    state = state.copyWith(
      morningIncludeWorkout: workout,
      morningIncludeBreakfast: breakfast,
      morningIncludeMotivation: motivation,
    );
    await _rescheduleNotifications();
  }

  Future<void> setMiddayBundleContent(bool lunch, bool hydration) async {
    await _prefs.setBool(NotificationPrefsKeys.middayIncludeLunch, lunch);
    await _prefs.setBool(NotificationPrefsKeys.middayIncludeHydration, hydration);
    state = state.copyWith(
      middayIncludeLunch: lunch,
      middayIncludeHydration: hydration,
    );
    await _rescheduleNotifications();
  }

  Future<void> setEveningBundleContent(bool dinner, bool streak, bool progress) async {
    await _prefs.setBool(NotificationPrefsKeys.eveningIncludeDinner, dinner);
    await _prefs.setBool(NotificationPrefsKeys.eveningIncludeStreak, streak);
    await _prefs.setBool(NotificationPrefsKeys.eveningIncludeProgress, progress);
    state = state.copyWith(
      eveningIncludeDinner: dinner,
      eveningIncludeStreak: streak,
      eveningIncludeProgress: progress,
    );
    await _rescheduleNotifications();
  }

  Future<void> setNotificationEmoji(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.notificationEmoji, value);
    state = state.copyWith(notificationEmoji: value);
  }

  Future<void> setNotificationVibration(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.notificationVibration, value);
    state = state.copyWith(notificationVibration: value);
  }

  // ─── Cycle Tracking Reminder Setters (Phase E) ──────────────────
  // Each toggle reschedules the cycle reminders and syncs to the backend so
  // the server-side cycle nudge jobs honour the user's choice. Cycle reminder
  // payloads are content-free (event/type names only) — no symptom or cycle
  // data is ever attached.

  Future<void> setCycleRemindersMaster(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cycleRemindersMaster, value);
    state = state.copyWith(cycleRemindersMaster: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCyclePeriodApproaching(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cyclePeriodApproaching, value);
    state = state.copyWith(cyclePeriodApproaching: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCyclePeriodStart(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cyclePeriodStart, value);
    state = state.copyWith(cyclePeriodStart: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleFertileWindow(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cycleFertileWindow, value);
    state = state.copyWith(cycleFertileWindow: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCyclePeakFertility(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cyclePeakFertility, value);
    state = state.copyWith(cyclePeakFertility: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleBbtReminder(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cycleBbtReminder, value);
    state = state.copyWith(cycleBbtReminder: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleBbtReminderTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.cycleBbtReminderTime, time);
    state = state.copyWith(cycleBbtReminderTime: time);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleSymptomCheckin(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cycleSymptomCheckin, value);
    state = state.copyWith(cycleSymptomCheckin: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleSymptomCheckinTime(String time) async {
    await _prefs.setString(NotificationPrefsKeys.cycleSymptomCheckinTime, time);
    state = state.copyWith(cycleSymptomCheckinTime: time);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleLatePeriodAlert(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.cycleLatePeriodAlert, value);
    state = state.copyWith(cycleLatePeriodAlert: value);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCycleReminderTimeOfDay(String time) async {
    await _prefs.setString(NotificationPrefsKeys.cycleReminderTimeOfDay, time);
    state = state.copyWith(cycleReminderTimeOfDay: time);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  Future<void> setCyclePeriodApproachingLeadDays(int days) async {
    final clamped = days.clamp(1, 5);
    await _prefs.setInt(
        NotificationPrefsKeys.cyclePeriodApproachingLeadDays, clamped);
    state = state.copyWith(cyclePeriodApproachingLeadDays: clamped);
    await _rescheduleNotifications();
    await _syncPreferencesToBackend();
  }

  /// Update the cached cycle tracking mode. The TTC-only fertility reminders
  /// are only scheduled when this is `ttc`; `pregnancy` pauses all cycle
  /// prediction reminders. Called by the cycle screen / settings when the
  /// mode toggle changes.
  Future<void> setCycleTrackingMode(String mode) async {
    await _prefs.setString(NotificationPrefsKeys.cycleTrackingMode, mode);
    state = state.copyWith(cycleTrackingMode: mode);
    await _rescheduleNotifications();
  }

  /// Refresh the cached cycle prediction dates the date-anchored reminders
  /// schedule against, then reschedule. Called by the cycle providers
  /// whenever a fresh `CyclePrediction` arrives (a new period logged, the
  /// server prediction refreshed, etc.) so the reminders always track the
  /// latest forecast. All dates are ISO `yyyy-MM-dd` strings interpreted in
  /// the device's local timezone. Pass null for a field to clear it.
  Future<void> updateCyclePredictionDates({
    String? nextPeriodDate,
    String? fertileWindowStart,
    String? peakFertilityStart,
    String? predictedLateDate,
    String? trackingMode,
  }) async {
    Future<void> put(String key, String? value) async {
      if (value == null || value.isEmpty) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, value);
      }
    }

    await put(NotificationPrefsKeys.cycleNextPeriodDate, nextPeriodDate);
    await put(
        NotificationPrefsKeys.cycleFertileWindowStart, fertileWindowStart);
    await put(
        NotificationPrefsKeys.cyclePeakFertilityStart, peakFertilityStart);
    await put(NotificationPrefsKeys.cyclePredictedLateDate, predictedLateDate);
    if (trackingMode != null && trackingMode.isNotEmpty) {
      await _prefs.setString(
          NotificationPrefsKeys.cycleTrackingMode, trackingMode);
      state = state.copyWith(cycleTrackingMode: trackingMode);
    }
    await _rescheduleNotifications();
  }
}

/// Providers
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  throw UnimplementedError('Must be overridden with SharedPreferences');
});

/// Provider for syncing notification preferences to backend
/// This should be called when user logs in or preferences change
final notificationPrefsSyncProvider = Provider<NotificationPrefsSync>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationPrefsSync(apiClient);
});

/// Helper class to sync notification preferences to the backend
class NotificationPrefsSync {
  final ApiClient _apiClient;

  NotificationPrefsSync(this._apiClient);

  /// Sync current preferences to backend
  Future<void> syncPreferences(NotificationPreferences prefs) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('🔔 [Sync] Skipping backend sync - no user ID');
        return;
      }

      // Send the FULL canonical preference set under the exact snake_case keys
      // the backend cron reads from `users.notification_preferences` (JSONB).
      //
      // Previously this hand-built a 16-field `push_*` payload that the backend
      // wrote to the `notification_preferences` TABLE — but every server nudge
      // job reads the `users.notification_preferences` JSONB, which nothing
      // wrote post-onboarding. So the user's time/intensity/per-type choices
      // never reached the cron (morning briefing fired at a hardcoded 08:00,
      // toggles did nothing). `toJson()` already emits every canonical key the
      // cron expects (workout_reminders, missed_workout_nudge, daily_briefing_*,
      // accountability_intensity, evening_recap_*, push_notifications_enabled,
      // ...); we send it verbatim plus the live timezone.
      final backendPrefs = {
        ...prefs.toJson(),
        // Live IANA timezone — the cron groups users by zone for local-time
        // scheduling, so this must always reflect the device's current zone.
        'timezone': tz.local.name,
        // Weekly-summary day also sent as a string for the legacy
        // notification_preferences table column (JSONB carries the int).
        'weekly_summary_day_name': _dayIntToString(prefs.weeklySummaryDay),
      };

      await _apiClient.put(
        '/summaries/preferences/$userId',
        data: backendPrefs,
      );
      debugPrint('🔔 [Sync] Preferences synced to backend successfully');
    } catch (e) {
      debugPrint('🔔 [Sync] Failed to sync preferences to backend: $e');
    }
  }

  String _dayIntToString(int day) {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[day % 7];
  }
}
