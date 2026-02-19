import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

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
  // Cached user context
  static const cachedUserName = 'notif_cached_user_name';
  static const cachedStreak = 'notif_cached_streak';
  // App open times for smart timing
  static const appOpenTimes = 'notif_app_open_times';
}

/// Notification preferences state
class NotificationPreferences {
  final bool workoutReminders;
  final bool nutritionReminders;
  final bool hydrationReminders;
  final bool aiCoachMessages;
  final bool streakAlerts;
  final bool weeklySummary;
  final bool billingReminders;
  final bool movementReminders;
  final bool liveChatMessages;
  final String quietHoursStart;
  final String quietHoursEnd;
  // Time preferences for scheduled notifications
  final String workoutReminderTime; // e.g. "08:00"
  final String nutritionBreakfastTime;
  final String nutritionLunchTime;
  final String nutritionDinnerTime;
  final String hydrationStartTime;
  final String hydrationEndTime;
  final int hydrationIntervalMinutes;
  final String streakAlertTime;
  final int weeklySummaryDay; // 0=Sunday, 6=Saturday
  final String weeklySummaryTime;
  // Movement reminder (NEAT) preferences
  final String movementReminderStartTime;
  final String movementReminderEndTime;
  final int movementStepThreshold; // Steps per hour threshold (default 250)
  // Smart timing
  final bool smartTimingEnabled;

  const NotificationPreferences({
    this.workoutReminders = true,
    this.nutritionReminders = true,
    this.hydrationReminders = true,
    this.aiCoachMessages = true,
    this.streakAlerts = true,
    this.weeklySummary = true,
    this.billingReminders = true,
    this.movementReminders = true,
    this.liveChatMessages = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    // Default times
    this.workoutReminderTime = '08:00',
    this.nutritionBreakfastTime = '08:00',
    this.nutritionLunchTime = '12:00',
    this.nutritionDinnerTime = '18:00',
    this.hydrationStartTime = '08:00',
    this.hydrationEndTime = '20:00',
    this.hydrationIntervalMinutes = 120, // Every 2 hours
    this.streakAlertTime = '18:00',
    this.weeklySummaryDay = 0, // Sunday
    this.weeklySummaryTime = '09:00',
    // Movement reminder defaults (work hours)
    this.movementReminderStartTime = '09:00',
    this.movementReminderEndTime = '17:00',
    this.movementStepThreshold = 250, // 250 steps per hour threshold
    // Smart timing
    this.smartTimingEnabled = false,
  });

  NotificationPreferences copyWith({
    bool? workoutReminders,
    bool? nutritionReminders,
    bool? hydrationReminders,
    bool? aiCoachMessages,
    bool? streakAlerts,
    bool? weeklySummary,
    bool? billingReminders,
    bool? movementReminders,
    bool? liveChatMessages,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? workoutReminderTime,
    String? nutritionBreakfastTime,
    String? nutritionLunchTime,
    String? nutritionDinnerTime,
    String? hydrationStartTime,
    String? hydrationEndTime,
    int? hydrationIntervalMinutes,
    String? streakAlertTime,
    int? weeklySummaryDay,
    String? weeklySummaryTime,
    String? movementReminderStartTime,
    String? movementReminderEndTime,
    int? movementStepThreshold,
    bool? smartTimingEnabled,
  }) {
    return NotificationPreferences(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      nutritionReminders: nutritionReminders ?? this.nutritionReminders,
      hydrationReminders: hydrationReminders ?? this.hydrationReminders,
      aiCoachMessages: aiCoachMessages ?? this.aiCoachMessages,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      billingReminders: billingReminders ?? this.billingReminders,
      movementReminders: movementReminders ?? this.movementReminders,
      liveChatMessages: liveChatMessages ?? this.liveChatMessages,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      workoutReminderTime: workoutReminderTime ?? this.workoutReminderTime,
      nutritionBreakfastTime: nutritionBreakfastTime ?? this.nutritionBreakfastTime,
      nutritionLunchTime: nutritionLunchTime ?? this.nutritionLunchTime,
      nutritionDinnerTime: nutritionDinnerTime ?? this.nutritionDinnerTime,
      hydrationStartTime: hydrationStartTime ?? this.hydrationStartTime,
      hydrationEndTime: hydrationEndTime ?? this.hydrationEndTime,
      hydrationIntervalMinutes: hydrationIntervalMinutes ?? this.hydrationIntervalMinutes,
      streakAlertTime: streakAlertTime ?? this.streakAlertTime,
      weeklySummaryDay: weeklySummaryDay ?? this.weeklySummaryDay,
      weeklySummaryTime: weeklySummaryTime ?? this.weeklySummaryTime,
      movementReminderStartTime: movementReminderStartTime ?? this.movementReminderStartTime,
      movementReminderEndTime: movementReminderEndTime ?? this.movementReminderEndTime,
      movementStepThreshold: movementStepThreshold ?? this.movementStepThreshold,
      smartTimingEnabled: smartTimingEnabled ?? this.smartTimingEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_reminders': workoutReminders,
        'nutrition_reminders': nutritionReminders,
        'hydration_reminders': hydrationReminders,
        'ai_coach_messages': aiCoachMessages,
        'streak_alerts': streakAlerts,
        'weekly_summary': weeklySummary,
        'billing_reminders': billingReminders,
        'movement_reminders': movementReminders,
        'live_chat_messages': liveChatMessages,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'workout_reminder_time': workoutReminderTime,
        'nutrition_breakfast_time': nutritionBreakfastTime,
        'nutrition_lunch_time': nutritionLunchTime,
        'nutrition_dinner_time': nutritionDinnerTime,
        'hydration_start_time': hydrationStartTime,
        'hydration_end_time': hydrationEndTime,
        'hydration_interval_minutes': hydrationIntervalMinutes,
        'streak_alert_time': streakAlertTime,
        'weekly_summary_day': weeklySummaryDay,
        'weekly_summary_time': weeklySummaryTime,
        'movement_reminder_start_time': movementReminderStartTime,
        'movement_reminder_end_time': movementReminderEndTime,
        'movement_step_threshold': movementStepThreshold,
        'smart_timing_enabled': smartTimingEnabled,
      };
}

/// Channel configuration for notifications
class _ChannelConfig {
  final String id;
  final String name;
  final String description;
  final Color color;

  const _ChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });
}

/// Callback type for storing received notifications
typedef OnNotificationReceivedCallback = void Function({
  required String title,
  required String body,
  String? type,
  Map<String, dynamic>? data,
});

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

  /// Callback for FCM token refresh - set this to sync token to backend
  OnTokenRefreshCallback? onTokenRefresh;

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
      description: 'General messages from your FitWiz coach',
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
    'schedule_reminder': _ChannelConfig(
      id: 'schedule_reminder',
      name: 'Schedule Reminders',
      description: 'Reminders for your scheduled activities, meals, and habits',
      color: Color(0xFF06B6D4), // Cyan
    ),
  };

  /// Default channel for unknown types
  static const _defaultChannel = _ChannelConfig(
    id: 'fitwiz_notifications',
    name: 'FitWiz',
    description: 'Notifications from your FitWiz coach',
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
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // NOTE: Permission request and FCM token retrieval are deferred to
    // requestPermissionWhenReady() to avoid "Unable to detect current Android Activity"
    // error when called before runApp() completes

    // Check exact alarm permission for Android 12+
    await checkAndRequestExactAlarmPermission();

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
    }

    if (!_firebaseAvailable) {
      debugPrint('⚠️ [FCM] Firebase not available, skipping FCM permission request');
      // Even without Firebase, local notifications should still work
      return;
    }

    try {
      // Request FCM permission (required for iOS and Android 13+)
      await _requestPermission();

      // Get FCM token after permission is granted
      await _getToken();

      // Set up Firebase Messaging listeners now that Activity is available
      if (messaging != null) {
        // Listen for token refresh
        messaging!.onTokenRefresh.listen((newToken) {
          debugPrint('🔔 [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
          _fcmToken = newToken;
          // Notify listeners so they can sync to backend
          onTokenRefresh?.call(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle when app is opened from notification
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check if app was opened from a notification
        final initialMessage = await messaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }

      debugPrint('✅ [FCM] Permission requested, token retrieved, and listeners configured');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error requesting permission: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher_monochrome');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 [Local] Notification tapped: ${response.payload}');
        // Call the tap callback for navigation
        onNotificationTapped?.call(response.payload);
      },
    );

    // Create all notification channels for different coaches
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Create default channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _defaultChannel.id,
          _defaultChannel.name,
          description: _defaultChannel.description,
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Create channels for each notification type
      for (final config in _channelConfigs.values) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            config.id,
            config.name,
            description: config.description,
            importance: Importance.high,
            playSound: true,
          ),
        );
      }
    }

    debugPrint('🔔 [Local] Local notifications initialized with ${_channelConfigs.length + 1} channels');
  }

  /// Request notification permission
  /// Only shows the system dialog if permission hasn't been granted yet
  Future<bool> _requestPermission() async {
    if (!_firebaseAvailable || messaging == null) {
      debugPrint('⚠️ [FCM] Firebase not available, skipping permission request');
      return false;
    }

    // First, check current permission status
    final currentSettings = await messaging!.getNotificationSettings();

    // If already authorized, don't show the dialog again
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
        currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('🔔 [FCM] Permission already granted: ${currentSettings.authorizationStatus}');
      return true;
    }

    // Only request if not authorized yet
    final settings = await messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('🔔 [FCM] Permission status: ${settings.authorizationStatus}');
    return authorized;
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    if (!_firebaseAvailable || messaging == null) {
      debugPrint('⚠️ [FCM] Firebase not available, skipping token retrieval');
      return null;
    }

    try {
      _fcmToken = await messaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('🔔 [FCM] Token: ${_fcmToken!.substring(0, 20)}...');
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ [FCM] Error getting token: $e');
      return null;
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Get notification type from data payload
    final notificationType = message.data['type'] as String?;

    // Show local notification with appropriate channel
    final notification = message.notification;
    if (notification != null) {
      final title = notification.title ?? 'FitWiz';
      final body = notification.body ?? '';

      _showLocalNotification(
        title: title,
        body: body,
        payload: message.data['action'],
        notificationType: notificationType,
      );

      // Store notification in app's notification inbox
      onNotificationReceived?.call(
        title: title,
        body: body,
        type: notificationType,
        data: message.data,
      );
    }
  }

  /// Get channel config for a notification type
  _ChannelConfig _getChannelConfig(String? notificationType) {
    if (notificationType == null) return _defaultChannel;
    return _channelConfigs[notificationType] ?? _defaultChannel;
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? notificationType,
    bool storeInInbox = false,
  }) async {
    final channelConfig = _getChannelConfig(notificationType);

    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Include notification type in payload for navigation
    final notificationPayload = notificationType ?? payload ?? 'default';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: notificationPayload,
    );

    debugPrint('🔔 [Local] Notification shown: $title (type: $notificationPayload)');

    // Store in notification inbox if requested
    if (storeInInbox) {
      onNotificationReceived?.call(
        title: title,
        body: body,
        type: notificationType,
        data: {'type': notificationType},
      );
    }
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [FCM] App opened from notification:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Data: ${message.data}');

    // Get notification type from data payload
    final notificationType = message.data['type'] as String?;

    // Handle live chat notifications
    if (notificationType == 'live_chat_message' ||
        notificationType == 'live_chat_connected' ||
        notificationType == 'live_chat_ended') {
      final ticketId = message.data['ticket_id'] as String?;
      final chatEnded = message.data['chat_ended'] == 'true';

      debugPrint('💬 [FCM] Live chat notification opened: type=$notificationType, ticketId=$ticketId, ended=$chatEnded');

      // Call the tap callback with the notification type for navigation
      onNotificationTapped?.call(notificationType);
      return;
    }

    // Handle other notification types
    if (notificationType != null) {
      onNotificationTapped?.call(notificationType);
    }
  }

  /// Show an immediate local notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? notificationType,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      notificationType: notificationType,
    );
  }

  /// Check and request exact alarm permission (Android 12+)
  Future<bool> checkAndRequestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    // Check if exact alarms are permitted
    final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
    debugPrint('🔔 [Permission] Can schedule exact notifications: $canScheduleExact');

    if (canScheduleExact != true) {
      // Request permission - this opens system settings
      await androidPlugin.requestExactAlarmsPermission();
      final afterRequest = await androidPlugin.canScheduleExactNotifications();
      debugPrint('🔔 [Permission] After request: $afterRequest');
      return afterRequest ?? false;
    }

    return canScheduleExact ?? false;
  }

  /// Register FCM token with backend
  Future<bool> registerTokenWithBackend(ApiClient apiClient, String userId) async {
    if (_fcmToken == null) {
      debugPrint('❌ [FCM] No token to register');
      return false;
    }

    try {
      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'fcm_token': _fcmToken,
          'device_platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      debugPrint('✅ [FCM] Token registered with backend');
      return true;
    } catch (e) {
      debugPrint('❌ [FCM] Error registering token: $e');
      return false;
    }
  }

  /// Send a test notification (triggers backend to send push)
  Future<bool> sendTestNotification(ApiClient apiClient, String userId) async {
    if (_fcmToken == null) {
      debugPrint('❌ [FCM] No token available for test notification');
      return false;
    }

    try {
      await apiClient.post(
        '/notifications/test',
        data: {
          'user_id': userId,
          'fcm_token': _fcmToken,
        },
      );
      debugPrint('✅ [FCM] Test notification sent');
      return true;
    } catch (e) {
      debugPrint('❌ [FCM] Error sending test notification: $e');
      return false;
    }
  }

  /// Update notification preferences on backend
  Future<bool> updatePreferences(
    ApiClient apiClient,
    String userId,
    NotificationPreferences prefs,
  ) async {
    try {
      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'notification_preferences': prefs.toJson(),
        },
      );
      debugPrint('✅ [FCM] Notification preferences updated');
      return true;
    } catch (e) {
      debugPrint('❌ [FCM] Error updating preferences: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Local Scheduled Notifications
  // ─────────────────────────────────────────────────────────────────

  /// Notification ID ranges for different types
  static const int _workoutNotificationId = 1000;
  static const int _nutritionBreakfastId = 2000;
  static const int _nutritionLunchId = 2001;
  static const int _nutritionDinnerId = 2002;
  static const int _hydrationBaseId = 3000;
  static const int _streakAlertId = 4000;
  static const int _weeklySummaryId = 5000;
  static const int _movementReminderBaseId = 6000;

  /// Base notification ID for schedule reminders (7000-7999 range)
  static const int _scheduleReminderBaseId = 7000;

  // ─────────────────────────────────────────────────────────────────
  // Template Rotation Lists
  // ─────────────────────────────────────────────────────────────────

  /// Get day-of-year (0-365) for template rotation
  static int _getDayOfYear() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays;
  }

  // Workout reminder templates (8 variants)
  static const _workoutTitles = [
    'Time to Work Out!',
    'Your Workout Awaits!',
    'Ready to Train?',
    'Let\'s Get Moving!',
    'Gym Time!',
    'Sweat Session Time!',
    'Workout O\'Clock!',
    'Time to Crush It!',
  ];
  static const _workoutBodies = [
    'Your workout is waiting. Let\'s crush those goals today!',
    'Consistency builds results. Show up and give it your best!',
    'Every rep counts. Let\'s make today a strong one!',
    'Your future self will thank you. Let\'s go!',
    'No excuses today - your body is ready for this!',
    'Progress happens one workout at a time. Start now!',
    'You\'re stronger than you think. Prove it today!',
    'The hardest part is starting. After that, it\'s all momentum!',
  ];

  // Nutrition breakfast templates (8 variants)
  static const _breakfastTitles = [
    'Breakfast Time!',
    'Good Morning! Time to Eat!',
    'Fuel Your Morning!',
    'Rise & Eat!',
    'Morning Fuel Check!',
    'Breakfast is Calling!',
    'Start Your Day Right!',
    'AM Nutrition Check!',
  ];
  static const _breakfastBodies = [
    'Don\'t forget to log your breakfast and start the day right!',
    'A good breakfast sets the tone. Log your morning meal!',
    'Fuel up for the day ahead. What are you having?',
    'Breakfast powers your morning. Track it to stay on target!',
    'Your metabolism needs a kickstart. Log your breakfast!',
    'Morning nutrition matters. Don\'t skip tracking!',
    'Start strong with a logged breakfast!',
    'What\'s fueling your morning? Log it now!',
  ];

  // Nutrition lunch templates (8 variants)
  static const _lunchTitles = [
    'Lunch Time!',
    'Midday Meal!',
    'Time for Lunch!',
    'Lunch Break!',
    'Noon Nutrition!',
    'Midday Fuel Up!',
    'Lunchtime Log!',
    'Afternoon Fuel!',
  ];
  static const _lunchBodies = [
    'Time for lunch! Remember to log your meal.',
    'Keep your nutrition on track. Log your lunch!',
    'Midday fuel matters. What are you having?',
    'Stay consistent - log your lunch to hit your goals!',
    'A balanced lunch keeps you going. Track it!',
    'Don\'t let lunch go untracked. Log it now!',
    'Halfway through the day - keep your nutrition dialed in!',
    'Your afternoon energy depends on lunch. Log it!',
  ];

  // Nutrition dinner templates (8 variants)
  static const _dinnerTitles = [
    'Dinner Time!',
    'Evening Meal!',
    'Time for Dinner!',
    'Dinner is Served!',
    'Evening Nutrition!',
    'Dinnertime Log!',
    'Last Meal of the Day!',
    'Evening Fuel Check!',
  ];
  static const _dinnerBodies = [
    'Enjoy your dinner! Don\'t forget to log it.',
    'Finish the day strong - log your dinner!',
    'Evening nutrition counts. Track your dinner!',
    'Almost done for the day. Log your final meal!',
    'A well-tracked day ends with a logged dinner!',
    'Your dinner matters for recovery. Log it!',
    'Complete your food diary - log dinner now!',
    'End the day right. Track your evening meal!',
  ];

  // Hydration templates (expanded to 8 variants)
  static const _hydrationTitles = [
    'Hydration Check!',
    'Water Break Time!',
    'Stay Hydrated!',
    'Drink Up!',
    'H2O Reminder!',
    'Thirst Alert!',
    'Water O\'Clock!',
    'Sip Reminder!',
  ];
  static const _hydrationBodies = [
    'Time to drink some water. Your body will thank you!',
    'A quick water break keeps you energized.',
    'Staying hydrated helps your workout performance!',
    'Don\'t forget to hydrate! It\'s essential for recovery.',
    'Water fuels everything. Take a sip now!',
    'Hydration boosts focus and energy. Drink up!',
    'Keep that water bottle handy. Time for a refill!',
    'Your muscles need water to perform. Hydrate now!',
  ];

  // Streak alert templates (8 variants)
  static const _streakTitles = [
    'Keep Your Streak Alive!',
    'Don\'t Break the Chain!',
    'Streak Check!',
    'Your Streak Needs You!',
    'Streak in Danger!',
    'Keep It Going!',
    'Streak Reminder!',
    'Stay Consistent!',
  ];
  static const _streakBodies = [
    'Don\'t break your streak! Complete a workout today.',
    'Your streak is counting on you. Get moving!',
    'One workout keeps the streak alive. You got this!',
    'Streaks build habits. Don\'t let today be the break!',
    'Your consistency is impressive. Keep it up today!',
    'A streak is a promise to yourself. Honor it!',
    'Every day counts. Protect your streak!',
    'Champions don\'t skip days. Keep your streak going!',
  ];

  // Weekly summary templates (8 variants)
  static const _weeklySummaryTitles = [
    'Your Weekly Summary is Ready!',
    'Week in Review!',
    'Weekly Progress Report!',
    'How Was Your Week?',
    'Weekly Fitness Recap!',
    'Your Week at a Glance!',
    'Progress Check-In!',
    'Weekly Wrap-Up!',
  ];
  static const _weeklySummaryBodies = [
    'Check out your progress from the past week.',
    'See how you did this week. Tap to review!',
    'Your weekly stats are in. Take a look!',
    'Reflect on your week and plan for the next one!',
    'Numbers don\'t lie. See your weekly progress!',
    'Another week done! Review your achievements.',
    'Your hard work is tracked. Check your summary!',
    'Week complete! See what you accomplished.',
  ];

  // ─────────────────────────────────────────────────────────────────
  // Cached User Context
  // ─────────────────────────────────────────────────────────────────

  /// Cache user's first name and streak count for personalized notifications
  static Future<void> cacheUserContext(String name, int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotificationPrefsKeys.cachedUserName, name);
    await prefs.setInt(NotificationPrefsKeys.cachedStreak, streak);
    debugPrint('🔔 [Cache] User context cached: name=$name, streak=$streak');
  }

  /// Get cached user name (returns null if not cached)
  static Future<String?> _getCachedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(NotificationPrefsKeys.cachedUserName);
  }

  /// Get cached streak count (returns null if not cached)
  static Future<int?> _getCachedStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(NotificationPrefsKeys.cachedStreak);
  }

  // ─────────────────────────────────────────────────────────────────
  // Smart Timing (App Open Tracking)
  // ─────────────────────────────────────────────────────────────────

  /// Record an app open timestamp for smart timing calculation.
  /// Maintains a rolling 14-day list of ISO timestamps.
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(NotificationPrefsKeys.appOpenTimes);
    final List<String> timestamps = raw != null
        ? List<String>.from(jsonDecode(raw) as List)
        : <String>[];

    timestamps.add(DateTime.now().toIso8601String());

    // Trim to 14 days
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    timestamps.removeWhere((t) {
      final dt = DateTime.tryParse(t);
      return dt == null || dt.isBefore(cutoff);
    });

    await prefs.setString(NotificationPrefsKeys.appOpenTimes, jsonEncode(timestamps));
    debugPrint('🔔 [SmartTiming] Recorded app open (${timestamps.length} data points)');
  }

  /// Calculate the optimal hour for workout reminders based on app usage patterns.
  /// Uses weighted average with recency decay over 14 days.
  /// Returns null if fewer than 5 data points.
  Future<int?> _calculateOptimalHour() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(NotificationPrefsKeys.appOpenTimes);
    if (raw == null) return null;

    final List<String> timestamps = List<String>.from(jsonDecode(raw) as List);
    if (timestamps.length < 5) return null;

    final now = DateTime.now();
    // Weight each hour bucket by recency
    final hourWeights = List<double>.filled(24, 0.0);

    for (final t in timestamps) {
      final dt = DateTime.tryParse(t);
      if (dt == null) continue;

      final daysAgo = now.difference(dt).inDays;
      // Recency weight: 1.0 for today, decays linearly to ~0.07 at 14 days
      final weight = 1.0 - (daysAgo / 15.0);
      if (weight <= 0) continue;

      hourWeights[dt.hour] += weight;
    }

    // Find the hour with the highest weighted score
    double maxWeight = 0;
    int bestHour = 8; // default fallback
    for (int h = 0; h < 24; h++) {
      if (hourWeights[h] > maxWeight) {
        maxWeight = hourWeights[h];
        bestHour = h;
      }
    }

    debugPrint('🔔 [SmartTiming] Optimal hour calculated: $bestHour (weight: ${maxWeight.toStringAsFixed(2)})');
    return bestHour;
  }

  /// Parse time string (e.g. "08:00") to hour and minute
  (int hour, int minute) _parseTime(String time) {
    final parts = time.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Get next occurrence of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Get next occurrence of a specific day and time
  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    var scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule all notifications based on preferences
  /// Only schedules if user has completed onboarding
  Future<void> scheduleAllNotifications(NotificationPreferences prefs) async {
    debugPrint('🔔 [Schedule] Scheduling all notifications...');

    // Cancel all existing scheduled notifications first
    await cancelAllScheduledNotifications();

    // Check if user has completed onboarding AND paywall - don't schedule notifications until both are done
    final sharedPrefs = await SharedPreferences.getInstance();
    final onboardingCompleted = sharedPrefs.getBool('onboarding_completed') ?? false;
    final paywallCompleted = sharedPrefs.getBool('paywall_completed') ?? false;
    if (!onboardingCompleted || !paywallCompleted) {
      debugPrint('⏸️ [Schedule] Skipping notification scheduling - onboarding: $onboardingCompleted, paywall: $paywallCompleted');
      return;
    }

    // Schedule each type if enabled
    if (prefs.workoutReminders) {
      await scheduleWorkoutReminder(
        prefs.workoutReminderTime,
        smartTimingEnabled: prefs.smartTimingEnabled,
      );
    }

    if (prefs.nutritionReminders) {
      await scheduleNutritionReminders(
        prefs.nutritionBreakfastTime,
        prefs.nutritionLunchTime,
        prefs.nutritionDinnerTime,
      );
    }

    if (prefs.hydrationReminders) {
      await scheduleHydrationReminders(
        prefs.hydrationStartTime,
        prefs.hydrationEndTime,
        prefs.hydrationIntervalMinutes,
      );
    }

    if (prefs.streakAlerts) {
      await scheduleStreakAlert(prefs.streakAlertTime);
    }

    if (prefs.weeklySummary) {
      await scheduleWeeklySummary(prefs.weeklySummaryDay, prefs.weeklySummaryTime);
    }

    if (prefs.movementReminders) {
      await scheduleMovementReminders(prefs);
    }

    debugPrint('✅ [Schedule] All notifications scheduled');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🔔 [Schedule] All scheduled notifications cancelled');
  }

  /// Schedule daily workout reminder with template rotation and smart timing
  Future<void> scheduleWorkoutReminder(String time, {bool smartTimingEnabled = false}) async {
    var (hour, minute) = _parseTime(time);

    // Smart timing: override hour if enabled and enough data
    if (smartTimingEnabled) {
      final optimalHour = await _calculateOptimalHour();
      if (optimalHour != null) {
        hour = optimalHour;
        minute = 0;
        debugPrint('🔔 [SmartTiming] Using optimal hour $hour for workout reminder');
      }
    }

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    final channelConfig = _channelConfigs['workout_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Template rotation
    final dayIndex = _getDayOfYear();
    var title = _workoutTitles[dayIndex % _workoutTitles.length];
    var body = _workoutBodies[dayIndex % _workoutBodies.length];

    // Personalize with cached user context
    final userName = await _getCachedUserName();
    if (userName != null && userName.isNotEmpty) {
      title = '$userName, ${title[0].toLowerCase()}${title.substring(1)}';
    }

    await _localNotifications.zonedSchedule(
      _workoutNotificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Workout reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily (smart=$smartTimingEnabled)');
  }

  /// Schedule nutrition reminders (breakfast, lunch, dinner) with template rotation
  Future<void> scheduleNutritionReminders(
    String breakfastTime,
    String lunchTime,
    String dinnerTime,
  ) async {
    final channelConfig = _channelConfigs['nutrition_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    final dayIndex = _getDayOfYear();

    // Breakfast
    final (bHour, bMinute) = _parseTime(breakfastTime);
    await _localNotifications.zonedSchedule(
      _nutritionBreakfastId,
      _breakfastTitles[dayIndex % _breakfastTitles.length],
      _breakfastBodies[dayIndex % _breakfastBodies.length],
      _nextInstanceOfTime(bHour, bMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Lunch
    final (lHour, lMinute) = _parseTime(lunchTime);
    await _localNotifications.zonedSchedule(
      _nutritionLunchId,
      _lunchTitles[dayIndex % _lunchTitles.length],
      _lunchBodies[dayIndex % _lunchBodies.length],
      _nextInstanceOfTime(lHour, lMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Dinner
    final (dHour, dMinute) = _parseTime(dinnerTime);
    await _localNotifications.zonedSchedule(
      _nutritionDinnerId,
      _dinnerTitles[dayIndex % _dinnerTitles.length],
      _dinnerBodies[dayIndex % _dinnerBodies.length],
      _nextInstanceOfTime(dHour, dMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Nutrition reminders scheduled: Breakfast=$breakfastTime, Lunch=$lunchTime, Dinner=$dinnerTime');
  }

  /// Schedule hydration reminders at intervals with template rotation
  Future<void> scheduleHydrationReminders(
    String startTime,
    String endTime,
    int intervalMinutes,
  ) async {
    final channelConfig = _channelConfigs['hydration_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    final (startHour, startMinute) = _parseTime(startTime);
    final (endHour, endMinute) = _parseTime(endTime);

    // Calculate all reminder times within the day
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    final dayIndex = _getDayOfYear();
    int notificationIndex = 0;

    for (int minutes = startMinutes; minutes <= endMinutes; minutes += intervalMinutes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      // Combine day + index for varied rotation across reminders in a day
      final templateIndex = (dayIndex + notificationIndex) % _hydrationTitles.length;

      await _localNotifications.zonedSchedule(
        _hydrationBaseId + notificationIndex,
        _hydrationTitles[templateIndex],
        _hydrationBodies[templateIndex],
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      notificationIndex++;
    }

    debugPrint('🔔 [Schedule] $notificationIndex hydration reminders scheduled from $startTime to $endTime every $intervalMinutes minutes');
  }

  /// Schedule daily streak alert with template rotation and personalization
  Future<void> scheduleStreakAlert(String time) async {
    final (hour, minute) = _parseTime(time);
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    final channelConfig = _channelConfigs['streak_alert']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Template rotation
    final dayIndex = _getDayOfYear();
    final title = _streakTitles[dayIndex % _streakTitles.length];
    var body = _streakBodies[dayIndex % _streakBodies.length];

    // Personalize with cached streak count
    final streak = await _getCachedStreak();
    if (streak != null && streak > 0) {
      body = '$body You\'re on a $streak-day streak!';
    }

    await _localNotifications.zonedSchedule(
      _streakAlertId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Streak alert scheduled for $time daily');
  }

  /// Schedule weekly summary notification with template rotation
  Future<void> scheduleWeeklySummary(int day, String time) async {
    final (hour, minute) = _parseTime(time);
    // Convert day (0=Sunday) to DateTime weekday (1=Monday, 7=Sunday)
    final weekday = day == 0 ? DateTime.sunday : day;
    final scheduledDate = _nextInstanceOfDayAndTime(weekday, hour, minute);

    final channelConfig = _channelConfigs['weekly_summary']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Template rotation (use week number for weekly notifications)
    final weekIndex = _getDayOfYear() ~/ 7;
    final title = _weeklySummaryTitles[weekIndex % _weeklySummaryTitles.length];
    final body = _weeklySummaryBodies[weekIndex % _weeklySummaryBodies.length];

    await _localNotifications.zonedSchedule(
      _weeklySummaryId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    final dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    debugPrint('🔔 [Schedule] Weekly summary scheduled for ${dayNames[day]} at $time');
  }

  // ─────────────────────────────────────────────────────────────────
  // Movement Reminder Methods (NEAT - Non-Exercise Activity Thermogenesis)
  // ─────────────────────────────────────────────────────────────────

  /// Schedule hourly movement reminder checks during work hours
  /// These are scheduled locally and will check step count when triggered
  Future<void> scheduleMovementReminders(NotificationPreferences prefs) async {
    // Cancel existing movement reminders first
    await cancelMovementReminders();

    if (!prefs.movementReminders) {
      debugPrint('🚶 [Movement] Movement reminders disabled, skipping schedule');
      return;
    }

    final (startHour, startMinute) = _parseTime(prefs.movementReminderStartTime);
    final (endHour, endMinute) = _parseTime(prefs.movementReminderEndTime);

    final channelConfig = _channelConfigs['movement_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Calculate number of hourly reminders to schedule
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    int reminderIndex = 0;
    // Schedule one reminder per hour within the time range
    for (int minutes = startMinutes; minutes <= endMinutes; minutes += 60) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      await _localNotifications.zonedSchedule(
        _movementReminderBaseId + reminderIndex,
        _getMovementReminderTitle(reminderIndex),
        _getMovementReminderBody(reminderIndex),
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'movement_reminder',
      );
      reminderIndex++;
    }

    debugPrint('🚶 [Movement] $reminderIndex movement reminders scheduled from ${prefs.movementReminderStartTime} to ${prefs.movementReminderEndTime}');
  }

  /// Cancel all movement reminder notifications
  Future<void> cancelMovementReminders() async {
    // Cancel all potential movement reminder IDs (max 24 per day)
    for (int i = 0; i < 24; i++) {
      await _localNotifications.cancel(_movementReminderBaseId + i);
    }
    debugPrint('🚶 [Movement] All movement reminders cancelled');
  }

  /// Show an immediate movement reminder notification
  /// Called when sedentary behavior is detected
  Future<void> showMovementReminder({
    required int stepsSoFar,
    required int goal,
  }) async {
    // Don't show movement reminders until onboarding and paywall are complete
    final sharedPrefs = await SharedPreferences.getInstance();
    final onboardingCompleted = sharedPrefs.getBool('onboarding_completed') ?? false;
    final paywallCompleted = sharedPrefs.getBool('paywall_completed') ?? false;
    if (!onboardingCompleted || !paywallCompleted) {
      debugPrint('⏸️ [Movement] Skipping reminder - onboarding: $onboardingCompleted, paywall: $paywallCompleted');
      return;
    }

    final title = _getMovementReminderTitle(DateTime.now().hour);
    final body = stepsSoFar == 0
        ? 'You haven\'t moved this hour. Stand up and take a quick walk!'
        : 'You\'ve taken only $stepsSoFar steps this hour. Try to hit $goal steps!';

    await _showLocalNotification(
      title: title,
      body: body,
      notificationType: 'movement_reminder',
      storeInInbox: true,
    );

    debugPrint('🚶 [Movement] Movement reminder shown: $stepsSoFar/$goal steps');
  }

  /// Get variety of movement reminder titles to avoid notification fatigue
  String _getMovementReminderTitle(int index) {
    final titles = [
      'Time to move!',
      'Stand up and stretch!',
      'Quick break?',
      'Get moving!',
      'Movement check!',
      'Desk break time!',
      'Walk break!',
      'Stretch it out!',
    ];
    return titles[index % titles.length];
  }

  /// Get variety of movement reminder body messages
  String _getMovementReminderBody(int index) {
    final bodies = [
      'A short walk can boost your energy and focus.',
      'Your body will thank you. Take 2 minutes to move!',
      'Stand up, stretch, and take a quick walk.',
      'Reduce sedentary time - every step counts!',
      'Time to shake off the stiffness. Move around!',
      'Walking improves circulation and mood.',
      'Get up and get those steps in!',
      'Small movements add up. Start now!',
    ];
    return bodies[index % bodies.length];
  }

  /// Check if current time is within movement reminder hours
  bool isWithinMovementReminderHours(NotificationPreferences prefs) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final (startHour, startMinute) = _parseTime(prefs.movementReminderStartTime);
    final (endHour, endMinute) = _parseTime(prefs.movementReminderEndTime);

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Check if current time is within quiet hours
  bool isWithinQuietHours(NotificationPreferences prefs) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final (startHour, startMinute) = _parseTime(prefs.quietHoursStart);
    final (endHour, endMinute) = _parseTime(prefs.quietHoursEnd);

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startMinutes > endMinutes) {
      // Quiet hours span midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Schedule Item Reminder Methods
  // ─────────────────────────────────────────────────────────────────

  /// Schedule a reminder for a schedule item
  Future<void> scheduleItemReminder({
    required String itemId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int minutesBefore = 15,
  }) async {
    final notificationId = _scheduleReminderBaseId + (itemId.hashCode.abs() % 1000);
    final reminderTime = scheduledTime.subtract(Duration(minutes: minutesBefore));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ [Notifications] Schedule reminder time is in the past, skipping');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    final channelConfig = _channelConfigs['schedule_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    await _localNotifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'schedule_reminder:$itemId',
    );

    debugPrint('✅ [Notifications] Scheduled reminder for "$title" at $scheduledDate (ID: $notificationId)');
  }

  /// Cancel a schedule item reminder
  Future<void> cancelItemReminder(String itemId) async {
    final notificationId = _scheduleReminderBaseId + (itemId.hashCode.abs() % 1000);
    await _localNotifications.cancel(notificationId);
    debugPrint('🔍 [Notifications] Cancelled schedule reminder for item $itemId (ID: $notificationId)');
  }

  /// Cancel all schedule reminders (IDs 7000-7999)
  Future<void> cancelAllScheduleReminders() async {
    for (int id = _scheduleReminderBaseId; id < _scheduleReminderBaseId + 1000; id++) {
      await _localNotifications.cancel(id);
    }
    debugPrint('✅ [Notifications] Cancelled all schedule reminders');
  }

  // ─────────────────────────────────────────────────────────────────
  // Debug & Testing Methods
  // ─────────────────────────────────────────────────────────────────

  /// Show an immediate local notification (for testing local notification delivery)
  Future<void> showTestLocalNotification() async {
    const title = '🧪 Test Notification';
    const body = 'This is a local notification test. If you see this, local notifications work!';
    const type = 'test';

    await _showLocalNotification(
      title: title,
      body: body,
      notificationType: type,
      storeInInbox: true,
    );

    debugPrint('🔔 [Test] Immediate local notification sent');
  }

  /// Schedule a test notification for a specific number of seconds from now
  Future<void> scheduleTestNotification(int secondsFromNow) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));

    final channelConfig = _channelConfigs['test']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Use a unique ID for test notifications
    final testId = 9000 + (DateTime.now().millisecondsSinceEpoch % 1000);

    const title = '⏰ Scheduled Test';
    final body = 'This notification was scheduled $secondsFromNow seconds ago!';

    await _localNotifications.zonedSchedule(
      testId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test',
    );

    // Store in inbox when scheduled notification fires
    // Note: For scheduled notifications, we store immediately but mark as from schedule
    onNotificationReceived?.call(
      title: title,
      body: body,
      type: 'test',
      data: {'type': 'test', 'scheduled': true},
    );

    debugPrint('🔔 [Test] Notification scheduled for $scheduledDate (ID: $testId)');
    debugPrint('🔔 [Test] Current time: ${tz.TZDateTime.now(tz.local)}');
  }

  /// Get list of all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _localNotifications.pendingNotificationRequests();
    debugPrint('🔔 [Debug] ${pending.length} pending notifications:');
    for (final notif in pending) {
      debugPrint('   - ID: ${notif.id}, Title: ${notif.title}');
    }
    return pending;
  }

  /// Get current timezone info (for debugging)
  Map<String, dynamic> getTimezoneInfo() {
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    return {
      'deviceTime': now.toString(),
      'deviceOffset': now.timeZoneOffset.toString(),
      'tzLibraryTime': tzNow.toString(),
      'tzLocation': tz.local.name,
      'tzOffset': tzNow.timeZoneOffset.toString(),
    };
  }

  // ─────────────────────────────────────────────────────────────────
  // Live Chat Navigation Helpers
  // ─────────────────────────────────────────────────────────────────

  /// Check if a notification type is a live chat notification
  static bool isLiveChatNotification(String? notificationType) {
    return notificationType == 'live_chat_message' ||
        notificationType == 'live_chat_connected' ||
        notificationType == 'live_chat_ended';
  }

  /// Get the navigation route for a notification type
  /// Returns the route path to navigate to when the notification is tapped
  static String? getNavigationRouteForNotification(String? notificationType) {
    switch (notificationType) {
      case 'live_chat_message':
      case 'live_chat_connected':
      case 'live_chat_ended':
        return '/live-chat';
      case 'workout_reminder':
        return '/workout';
      case 'nutrition_reminder':
        return '/nutrition';
      case 'hydration_reminder':
        return '/hydration';
      case 'streak_alert':
        return '/stats';
      case 'weekly_summary':
        return '/stats';
      case 'movement_reminder':
        return '/home';
      case 'schedule_reminder':
        return '/schedule';
      default:
        return null;
    }
  }

  /// Check if a live chat notification indicates the chat has ended
  static bool isLiveChatEndedNotification(String? notificationType) {
    return notificationType == 'live_chat_ended';
  }
}

/// Callback type for syncing preferences to backend
typedef PreferencesSyncCallback = Future<void> Function(NotificationPreferences prefs);

/// Notification preferences notifier
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  PreferencesSyncCallback? _onPreferencesChanged;

  NotificationPreferencesNotifier(
    this._prefs,
    this._notificationService,
  ) : super(const NotificationPreferences()) {
    _loadPreferences();
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
      hydrationStartTime: _prefs.getString(NotificationPrefsKeys.hydrationStartTime) ?? '08:00',
      hydrationEndTime: _prefs.getString(NotificationPrefsKeys.hydrationEndTime) ?? '20:00',
      hydrationIntervalMinutes: _prefs.getInt(NotificationPrefsKeys.hydrationIntervalMinutes) ?? 120,
      streakAlertTime: _prefs.getString(NotificationPrefsKeys.streakAlertTime) ?? '18:00',
      weeklySummaryDay: _prefs.getInt(NotificationPrefsKeys.weeklySummaryDay) ?? 0,
      weeklySummaryTime: _prefs.getString(NotificationPrefsKeys.weeklySummaryTime) ?? '09:00',
      // Movement reminder preferences
      movementReminderStartTime: _prefs.getString(NotificationPrefsKeys.movementReminderStartTime) ?? '09:00',
      movementReminderEndTime: _prefs.getString(NotificationPrefsKeys.movementReminderEndTime) ?? '17:00',
      movementStepThreshold: _prefs.getInt(NotificationPrefsKeys.movementStepThreshold) ?? 250,
      // Smart timing
      smartTimingEnabled: _prefs.getBool(NotificationPrefsKeys.smartTimingEnabled) ?? false,
    );
    // Schedule notifications on load
    _rescheduleNotifications();
  }

  /// Reschedule all notifications based on current state
  Future<void> _rescheduleNotifications() async {
    await _notificationService.scheduleAllNotifications(state);
  }

  /// Public method to trigger rescheduling (e.g., after restoring onboarding flag)
  Future<void> rescheduleNotifications() async {
    await _rescheduleNotifications();
  }

  /// Sync notification preferences to backend
  Future<void> _syncPreferencesToBackend() async {
    if (_onPreferencesChanged != null) {
      await _onPreferencesChanged!(state);
    }
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

      // Convert preferences to backend format
      final backendPrefs = {
        'push_notifications_enabled': true,
        'push_workout_reminders': prefs.workoutReminders,
        'push_achievement_alerts': prefs.streakAlerts,
        'push_weekly_summary': prefs.weeklySummary,
        'push_hydration_reminders': prefs.hydrationReminders,
        'push_ai_coach_messages': prefs.aiCoachMessages,
        'push_nutrition_reminders': prefs.nutritionReminders,
        'push_billing_reminders': prefs.billingReminders,
        'push_live_chat_messages': prefs.liveChatMessages,
        'weekly_summary_enabled': prefs.weeklySummary,
        'weekly_summary_day': _dayIntToString(prefs.weeklySummaryDay),
        'weekly_summary_time': prefs.weeklySummaryTime,
        'quiet_hours_start': prefs.quietHoursStart,
        'quiet_hours_end': prefs.quietHoursEnd,
        'timezone': tz.local.name,
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
