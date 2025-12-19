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
}

/// Notification preferences state
class NotificationPreferences {
  final bool workoutReminders;
  final bool nutritionReminders;
  final bool hydrationReminders;
  final bool aiCoachMessages;
  final bool streakAlerts;
  final bool weeklySummary;
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

  const NotificationPreferences({
    this.workoutReminders = true,
    this.nutritionReminders = true,
    this.hydrationReminders = true,
    this.aiCoachMessages = true,
    this.streakAlerts = true,
    this.weeklySummary = true,
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
  });

  NotificationPreferences copyWith({
    bool? workoutReminders,
    bool? nutritionReminders,
    bool? hydrationReminders,
    bool? aiCoachMessages,
    bool? streakAlerts,
    bool? weeklySummary,
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
  }) {
    return NotificationPreferences(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      nutritionReminders: nutritionReminders ?? this.nutritionReminders,
      hydrationReminders: hydrationReminders ?? this.hydrationReminders,
      aiCoachMessages: aiCoachMessages ?? this.aiCoachMessages,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_reminders': workoutReminders,
        'nutrition_reminders': nutritionReminders,
        'hydration_reminders': hydrationReminders,
        'ai_coach_messages': aiCoachMessages,
        'streak_alerts': streakAlerts,
        'weekly_summary': weeklySummary,
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

/// Notification service for FCM + Local Notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  /// Callback to store received notifications in the app's notification inbox
  OnNotificationReceivedCallback? onNotificationReceived;

  /// Callback to handle notification taps (for navigation)
  OnNotificationTappedCallback? onNotificationTapped;

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
    'ai_coach': _ChannelConfig(
      id: 'ai_coach',
      name: 'AI Coach',
      description: 'General messages from your AI Fitness Coach',
      color: Color(0xFF00D9FF), // Cyan
    ),
    'test': _ChannelConfig(
      id: 'test_notifications',
      name: 'Test Notifications',
      description: 'Test notifications',
      color: Color(0xFF00D9FF), // Cyan
    ),
  };

  /// Default channel for unknown types
  static const _defaultChannel = _ChannelConfig(
    id: 'ai_fitness_coach_notifications',
    name: 'AI Fitness Coach',
    description: 'Notifications from your AI Fitness Coach',
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
  Future<void> initialize() async {
    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();
    // Set local timezone based on device's current offset
    _initializeLocalTimezone();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission (required for iOS and Android 13+)
    await _requestPermission();

    // Check exact alarm permission for Android 12+
    await checkAndRequestExactAlarmPermission();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      // TODO: Send new token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('🔔 [FCM] Notification service initialized');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

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
    // First, check current permission status
    final currentSettings = await _messaging.getNotificationSettings();

    // If already authorized, don't show the dialog again
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
        currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('🔔 [FCM] Permission already granted: ${currentSettings.authorizationStatus}');
      return true;
    }

    // Only request if not authorized yet
    final settings = await _messaging.requestPermission(
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
    try {
      _fcmToken = await _messaging.getToken();
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
      final title = notification.title ?? 'AI Fitness Coach';
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
      icon: '@mipmap/ic_launcher',
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

    // TODO: Navigate to relevant screen based on message data
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

    // Check if user has completed onboarding - don't schedule notifications until they have
    final sharedPrefs = await SharedPreferences.getInstance();
    final onboardingCompleted = sharedPrefs.getBool('onboarding_completed') ?? false;
    if (!onboardingCompleted) {
      debugPrint('⏸️ [Schedule] Skipping notification scheduling - onboarding not completed');
      return;
    }

    // Schedule each type if enabled
    if (prefs.workoutReminders) {
      await scheduleWorkoutReminder(prefs.workoutReminderTime);
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

    debugPrint('✅ [Schedule] All notifications scheduled');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🔔 [Schedule] All scheduled notifications cancelled');
  }

  /// Schedule daily workout reminder
  Future<void> scheduleWorkoutReminder(String time) async {
    final (hour, minute) = _parseTime(time);
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    final channelConfig = _channelConfigs['workout_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: channelConfig.color,
    );

    await _localNotifications.zonedSchedule(
      _workoutNotificationId,
      '💪 Time to Work Out!',
      'Your workout is waiting. Let\'s crush those goals today!',
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Workout reminder scheduled for $time daily');
  }

  /// Schedule nutrition reminders (breakfast, lunch, dinner)
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
      icon: '@mipmap/ic_launcher',
      color: channelConfig.color,
    );

    // Breakfast
    final (bHour, bMinute) = _parseTime(breakfastTime);
    await _localNotifications.zonedSchedule(
      _nutritionBreakfastId,
      '🍳 Breakfast Time!',
      'Don\'t forget to log your breakfast and start the day right!',
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
      '🥗 Lunch Time!',
      'Time for lunch! Remember to log your meal.',
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
      '🍽️ Dinner Time!',
      'Enjoy your dinner! Don\'t forget to log it.',
      _nextInstanceOfTime(dHour, dMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Nutrition reminders scheduled: Breakfast=$breakfastTime, Lunch=$lunchTime, Dinner=$dinnerTime');
  }

  /// Schedule hydration reminders at intervals
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
      icon: '@mipmap/ic_launcher',
      color: channelConfig.color,
    );

    final (startHour, startMinute) = _parseTime(startTime);
    final (endHour, endMinute) = _parseTime(endTime);

    // Calculate all reminder times within the day
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    int notificationIndex = 0;
    final hydrationMessages = [
      '💧 Hydration Check!',
      '🚰 Water Break Time!',
      '💦 Stay Hydrated!',
      '🥤 Drink Up!',
    ];
    final hydrationBodies = [
      'Time to drink some water. Your body will thank you!',
      'A quick water break keeps you energized.',
      'Staying hydrated helps your workout performance!',
      'Don\'t forget to hydrate! It\'s essential for recovery.',
    ];

    for (int minutes = startMinutes; minutes <= endMinutes; minutes += intervalMinutes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      await _localNotifications.zonedSchedule(
        _hydrationBaseId + notificationIndex,
        hydrationMessages[notificationIndex % hydrationMessages.length],
        hydrationBodies[notificationIndex % hydrationBodies.length],
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

  /// Schedule daily streak alert
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
      icon: '@mipmap/ic_launcher',
      color: channelConfig.color,
    );

    await _localNotifications.zonedSchedule(
      _streakAlertId,
      '🔥 Keep Your Streak Alive!',
      'Don\'t break your streak! Complete a workout today.',
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🔔 [Schedule] Streak alert scheduled for $time daily');
  }

  /// Schedule weekly summary notification
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
      icon: '@mipmap/ic_launcher',
      color: channelConfig.color,
    );

    await _localNotifications.zonedSchedule(
      _weeklySummaryId,
      '📊 Your Weekly Summary is Ready!',
      'Check out your progress from the past week.',
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
      icon: '@mipmap/ic_launcher',
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
    );
    // Schedule notifications on load
    _rescheduleNotifications();
  }

  /// Reschedule all notifications based on current state
  Future<void> _rescheduleNotifications() async {
    await _notificationService.scheduleAllNotifications(state);
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
