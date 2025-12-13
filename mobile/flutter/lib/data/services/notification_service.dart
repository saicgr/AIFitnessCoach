import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  const NotificationPreferences({
    this.workoutReminders = true,
    this.nutritionReminders = true,
    this.hydrationReminders = true,
    this.aiCoachMessages = true,
    this.streakAlerts = true,
    this.weeklySummary = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
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
      };
}

/// Notification service for FCM
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (required for iOS and Android 13+)
    await _requestPermission();

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

  /// Request notification permission
  Future<bool> _requestPermission() async {
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

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // TODO: Show local notification or in-app banner
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [FCM] App opened from notification:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Data: ${message.data}');

    // TODO: Navigate to relevant screen based on message data
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
}

/// Notification preferences notifier
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final SharedPreferences _prefs;

  NotificationPreferencesNotifier(this._prefs) : super(const NotificationPreferences()) {
    _loadPreferences();
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
    );
  }

  Future<void> setWorkoutReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.workoutReminders, value);
    state = state.copyWith(workoutReminders: value);
  }

  Future<void> setNutritionReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.nutritionReminders, value);
    state = state.copyWith(nutritionReminders: value);
  }

  Future<void> setHydrationReminders(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.hydrationReminders, value);
    state = state.copyWith(hydrationReminders: value);
  }

  Future<void> setAiCoachMessages(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.aiCoachMessages, value);
    state = state.copyWith(aiCoachMessages: value);
  }

  Future<void> setStreakAlerts(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.streakAlerts, value);
    state = state.copyWith(streakAlerts: value);
  }

  Future<void> setWeeklySummary(bool value) async {
    await _prefs.setBool(NotificationPrefsKeys.weeklySummary, value);
    state = state.copyWith(weeklySummary: value);
  }

  Future<void> setQuietHours(String start, String end) async {
    await _prefs.setString(NotificationPrefsKeys.quietHoursStart, start);
    await _prefs.setString(NotificationPrefsKeys.quietHoursEnd, end);
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
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
