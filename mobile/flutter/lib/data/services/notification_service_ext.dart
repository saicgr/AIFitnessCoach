part of 'notification_service.dart';

/// Core notification methods extracted from NotificationService
extension NotificationServiceCore on NotificationService {
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
        final payload = response.payload;
        // Try to parse rich JSON payload (contains title, body, type)
        if (payload != null && payload.startsWith('{')) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final type = data['type'] as String?;
            final title = data['title'] as String?;
            final body = data['body'] as String?;
            // Store in notification inbox
            if (title != null && body != null) {
              onNotificationReceived?.call(
                title: title,
                body: body,
                type: type,
                data: {'type': type},
              );
            }
            // Navigate based on type
            onNotificationTapped?.call(type);
          } catch (_) {
            onNotificationTapped?.call(payload);
          }
        } else {
          onNotificationTapped?.call(payload);
        }
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
          NotificationService._defaultChannel.id,
          NotificationService._defaultChannel.name,
          description: NotificationService._defaultChannel.description,
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Create channels for each notification type
      for (final config in NotificationService._channelConfigs.values) {
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

    debugPrint('🔔 [Local] Local notifications initialized with ${NotificationService._channelConfigs.length + 1} channels');
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

    // Retry up to 3 times — emulators can be slow to provision tokens
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        _fcmToken = await messaging!.getToken();
        if (_fcmToken != null) {
          debugPrint('🔔 [FCM] Token obtained (attempt ${attempt + 1}): ${_fcmToken!.substring(0, 20)}...');
          return _fcmToken;
        }
        debugPrint('⚠️ [FCM] getToken() returned null (attempt ${attempt + 1}/3)');
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('❌ [FCM] Error getting token (attempt ${attempt + 1}/3): $e');
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    debugPrint('❌ [FCM] Failed to get token after 3 attempts. Push notifications will not work.');
    return null;
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Get notification type from data payload
    final notificationType = message.data['type'] as String?;

    // ACCOUNTABILITY COACH: If a nudge arrives while user is in the chat,
    // trigger a chat refresh so the new coach message appears in real-time.
    // The message is already saved in chat_messages DB by the backend.
    if (notificationType == 'ai_coach_accountability' ||
        (message.data['accountability'] == 'true')) {
      onCoachNudgeReceived?.call();
      debugPrint('🤖 [FCM] Coach nudge received in foreground — triggering chat refresh');
    }

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
    if (notificationType == null) return NotificationService._defaultChannel;
    return NotificationService._channelConfigs[notificationType] ?? NotificationService._defaultChannel;
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
    final notification = message.notification;

    // Store in inbox so it appears in the notification list
    if (notification != null) {
      onNotificationReceived?.call(
        title: notification.title ?? 'FitWiz',
        body: notification.body ?? '',
        type: notificationType,
        data: message.data,
      );
    }

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

    // Handle meal_reminder (scheduled recipe log) — action_data routes to the
    // confirm-and-log sheet via RecipeNotificationRouter.
    if (notificationType == 'meal_reminder') {
      RecipeNotificationRouter.pending = RecipeNotificationActionData(
        action: (message.data['action'] as String?) ?? 'log_recipe',
        recipeId: message.data['recipe_id'] as String?,
        mealType: message.data['meal_type'] as String?,
        servings: double.tryParse((message.data['servings'] as String?) ?? '1') ?? 1.0,
        scheduledLogId: message.data['scheduled_log_id'] as String?,
        cookEventId: message.data['cook_event_id'] as String?,
      );
      onNotificationTapped?.call('meal_reminder');
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

}
