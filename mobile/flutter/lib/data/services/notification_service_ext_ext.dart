part of 'notification_service.dart';

/// Scheduled notification methods extracted from NotificationService
extension NotificationServiceScheduled on NotificationService {
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
  // Template Rotation
  // ─────────────────────────────────────────────────────────────────

  /// Get day-of-year (0-365) for template rotation
  static int _getDayOfYear() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays;
  }

  /// Build a JSON payload for scheduled notifications so the tap handler
  /// can store title/body in the bell icon inbox.
  static String _richPayload(String type, String title, String body) {
    return jsonEncode({'type': type, 'title': title, 'body': body});
  }

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

  /// Cache the user's selected coach ID for personalized notifications.
  /// For custom coaches, maps coachingStyle to the nearest predefined coach.
  static Future<void> cacheCoachId(String? coachId, {String? coachingStyle}) async {
    final prefs = await SharedPreferences.getInstance();
    String resolvedId;
    if (coachId == 'custom' && coachingStyle != null) {
      resolvedId = CoachNotificationTemplates.mapStyleToCoachId(coachingStyle);
    } else {
      resolvedId = coachId ?? 'coach_mike';
    }
    await prefs.setString(NotificationPrefsKeys.cachedCoachId, resolvedId);
    debugPrint('🔔 [Cache] Coach ID cached: $resolvedId (raw=$coachId, style=$coachingStyle)');
  }

  /// Get cached coach ID (defaults to 'coach_mike')
  static Future<String> _getCachedCoachId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(NotificationPrefsKeys.cachedCoachId) ?? 'coach_mike';
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

    timestamps.add(Tz.timestamp());

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

    final channelConfig = NotificationService._channelConfigs['workout_reminder']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Coach-personalized template rotation
    final dayIndex = _getDayOfYear();
    final coachId = await _getCachedCoachId();
    final t = CoachNotificationTemplates.get(coachId, NotificationType.workout, dayIndex);
    var title = t.title;
    var body = t.body;

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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('workout_reminder', title, body),
    );

    debugPrint('🔔 [Schedule] Workout reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} daily (smart=$smartTimingEnabled)');
  }

  /// Schedule nutrition reminders (breakfast, lunch, dinner) with template rotation
  Future<void> scheduleNutritionReminders(
    String breakfastTime,
    String lunchTime,
    String dinnerTime,
  ) async {
    final channelConfig = NotificationService._channelConfigs['nutrition_reminder']!;
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
    final coachId = await _getCachedCoachId();

    // Breakfast
    final bT = CoachNotificationTemplates.get(coachId, NotificationType.breakfast, dayIndex);
    final (bHour, bMinute) = _parseTime(breakfastTime);
    await _localNotifications.zonedSchedule(
      _nutritionBreakfastId,
      bT.title,
      bT.body,
      _nextInstanceOfTime(bHour, bMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('nutrition_reminder', bT.title, bT.body),
    );

    // Lunch
    final lT = CoachNotificationTemplates.get(coachId, NotificationType.lunch, dayIndex);
    final (lHour, lMinute) = _parseTime(lunchTime);
    await _localNotifications.zonedSchedule(
      _nutritionLunchId,
      lT.title,
      lT.body,
      _nextInstanceOfTime(lHour, lMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('nutrition_reminder', lT.title, lT.body),
    );

    // Dinner
    final dT = CoachNotificationTemplates.get(coachId, NotificationType.dinner, dayIndex);
    final (dHour, dMinute) = _parseTime(dinnerTime);
    await _localNotifications.zonedSchedule(
      _nutritionDinnerId,
      dT.title,
      dT.body,
      _nextInstanceOfTime(dHour, dMinute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('nutrition_reminder', dT.title, dT.body),
    );

    debugPrint('🔔 [Schedule] Nutrition reminders scheduled: Breakfast=$breakfastTime, Lunch=$lunchTime, Dinner=$dinnerTime');
  }

  /// Schedule hydration reminders at intervals with template rotation
  Future<void> scheduleHydrationReminders(
    String startTime,
    String endTime,
    int intervalMinutes,
  ) async {
    final channelConfig = NotificationService._channelConfigs['hydration_reminder']!;
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
    final coachId = await _getCachedCoachId();
    int notificationIndex = 0;

    for (int minutes = startMinutes; minutes <= endMinutes; minutes += intervalMinutes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      // Combine day + index for varied rotation across reminders in a day
      final templateIndex = dayIndex + notificationIndex;
      final hT = CoachNotificationTemplates.get(coachId, NotificationType.hydration, templateIndex);

      await _localNotifications.zonedSchedule(
        _hydrationBaseId + notificationIndex,
        hT.title,
        hT.body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: _richPayload('hydration_reminder', hT.title, hT.body),
      );
      notificationIndex++;
    }

    debugPrint('🔔 [Schedule] $notificationIndex hydration reminders scheduled from $startTime to $endTime every $intervalMinutes minutes');
  }

  /// Schedule daily streak alert with template rotation and personalization
  Future<void> scheduleStreakAlert(String time) async {
    final (hour, minute) = _parseTime(time);
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    final channelConfig = NotificationService._channelConfigs['streak_alert']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Coach-personalized template rotation
    final dayIndex = _getDayOfYear();
    final coachId = await _getCachedCoachId();
    final sT = CoachNotificationTemplates.get(coachId, NotificationType.streak, dayIndex);
    final title = sT.title;
    var body = sT.body;

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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('streak_alert', title, body),
    );

    debugPrint('🔔 [Schedule] Streak alert scheduled for $time daily');
  }

  /// Schedule weekly summary notification with template rotation
  Future<void> scheduleWeeklySummary(int day, String time) async {
    final (hour, minute) = _parseTime(time);
    // Convert day (0=Sunday) to DateTime weekday (1=Monday, 7=Sunday)
    final weekday = day == 0 ? DateTime.sunday : day;
    final scheduledDate = _nextInstanceOfDayAndTime(weekday, hour, minute);

    final channelConfig = NotificationService._channelConfigs['weekly_summary']!;
    final androidDetails = AndroidNotificationDetails(
      channelConfig.id,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher_monochrome',
      color: channelConfig.color,
    );

    // Coach-personalized template rotation (use week number for weekly notifications)
    final weekIndex = _getDayOfYear() ~/ 7;
    final coachId = await _getCachedCoachId();
    final wT = CoachNotificationTemplates.get(coachId, NotificationType.weeklySummary, weekIndex);
    final title = wT.title;
    final body = wT.body;

    await _localNotifications.zonedSchedule(
      _weeklySummaryId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('weekly_summary', title, body),
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

    final channelConfig = NotificationService._channelConfigs['movement_reminder']!;
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

    final coachId = await _getCachedCoachId();
    int reminderIndex = 0;
    // Schedule one reminder per hour within the time range
    for (int minutes = startMinutes; minutes <= endMinutes; minutes += 60) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      final mT = CoachNotificationTemplates.get(coachId, NotificationType.movement, reminderIndex);

      await _localNotifications.zonedSchedule(
        _movementReminderBaseId + reminderIndex,
        mT.title,
        mT.body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: _richPayload('movement_reminder', mT.title, mT.body),
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

    final coachId = await _getCachedCoachId();
    final mT = CoachNotificationTemplates.get(coachId, NotificationType.movement, DateTime.now().hour);
    final title = mT.title;
    final body = stepsSoFar == 0
        ? mT.body
        : 'You\'ve taken only $stepsSoFar steps this hour. Try to hit $goal steps!';

    await _showLocalNotification(
      title: title,
      body: body,
      notificationType: 'movement_reminder',
      storeInInbox: true,
    );

    debugPrint('🚶 [Movement] Movement reminder shown: $stepsSoFar/$goal steps');
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

    final channelConfig = NotificationService._channelConfigs['schedule_reminder']!;
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('schedule_reminder', title, body),
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
  /// Show a test notification immediately with custom content (local, no FCM needed).
  /// Pass [notificationType] to control navigation when tapped.
  Future<void> showTestNotificationWithContent({
    required String title,
    required String body,
    String notificationType = 'test',
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      notificationType: notificationType,
      storeInInbox: true,
    );
    debugPrint('🔔 [Test] Local notification shown: $title (type: $notificationType)');
  }

  Future<void> scheduleTestNotification(int secondsFromNow) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));

    final channelConfig = NotificationService._channelConfigs['test']!;
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: _richPayload('test', title, body),
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
        return '/nutrition?tab=2';
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
