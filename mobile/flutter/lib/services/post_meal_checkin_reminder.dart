/// One-shot local notification that nudges the user to fill in the post-meal
/// check-in 45 minutes after a meal is logged, if they skipped it.
///
/// Design notes:
/// - Fires ONLY when `post_meal_checkin_disabled = false` AND
///   `post_meal_reminder_enabled = true`.
/// - Cancelled automatically when mood_after is filled (caller responsibility —
///   see [cancelForLog]).
/// - Deep-links to `/nutrition?openCheckin=<food_log_id>` so the sheet can
///   re-open bound to the right log.
/// - Copy adapts when a passive mood inference exists on the log, making the
///   reminder a 1-tap confirm instead of a generic nudge.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// SharedPreferences keys owned by NotificationService. We read them here to
/// avoid bleeding Riverpod into this singleton — fewer moving parts, same
/// source of truth.
class _NotifPrefKeys {
  static const masterEnabled = 'notif_push_enabled';
  static const quietHoursEnabled = 'notif_quiet_hours_enabled';
  static const quietHoursStart = 'notif_quiet_hours_start';
  static const quietHoursEnd = 'notif_quiet_hours_end';
  static const vacationMode = 'notif_vacation_mode';
}

/// Singleton responsible for scheduling/canceling the 45-min check-in reminder.
class PostMealCheckinReminderService {
  PostMealCheckinReminderService._();
  static final PostMealCheckinReminderService instance =
      PostMealCheckinReminderService._();

  static const String _channelId = 'post_meal_checkin_reminder';
  static const String _channelName = 'Post-Meal Check-in';
  static const String _channelDescription =
      'Gentle nudge 45 minutes after a meal to capture how you feel.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _channelCreated = false;
  bool _initialized = false;

  /// Callback registered from the root app; invoked when the user taps the
  /// 45-min reminder notification. The app wires this up so it can call
  /// `context.go('/nutrition?openCheckin=<id>')` and open the sheet bound
  /// to that log.
  void Function(String foodLogId)? onOpenCheckin;

  /// Derives a stable notification ID from the food_log UUID so scheduling
  /// the same log twice replaces the prior notification and cancellation can
  /// find it by the same ID.
  static int notificationIdFor(String foodLogId) {
    return foodLogId.hashCode & 0x7fffffff; // positive 31-bit int
  }

  /// Initialize the plugin with our own channel + tap handler. Safe to call
  /// multiple times — subsequent calls are no-ops. The main NotificationService
  /// uses a separate plugin instance, so this tap handler is dedicated to the
  /// post-meal reminder and won't conflict.
  Future<void> initialize({
    void Function(String foodLogId)? onOpenCheckinCallback,
  }) async {
    if (onOpenCheckinCallback != null) {
      onOpenCheckin = onOpenCheckinCallback;
    }
    if (_initialized) return;

    const androidInit =
        AndroidInitializationSettings('@drawable/ic_launcher_monochrome');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleTap,
    );
    await _ensureChannel();
    _initialized = true;
  }

  void _handleTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    // Payload format: "openCheckin=<food_log_id>"
    if (payload.startsWith('openCheckin=')) {
      final id = payload.substring('openCheckin='.length);
      if (id.isNotEmpty) {
        debugPrint('🍽️ [CheckinReminder] Tap → openCheckin=$id');
        onOpenCheckin?.call(id);
      }
    }
  }

  Future<void> _ensureChannel() async {
    if (_channelCreated || !Platform.isAndroid) {
      _channelCreated = true;
      return;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    _channelCreated = true;
  }

  /// Schedule a one-shot reminder [delay] after `loggedAt` (default 45 min).
  /// If [delay] resolves to the past, schedule nothing.
  ///
  /// Honors four layers of user control before scheduling:
  /// 1. Feature-level: `checkinDisabled` (Don't-show-again) / `reminderEnabled`
  /// 2. Master push toggle (NotificationService master switch)
  /// 3. Vacation mode
  /// 4. Quiet hours: if the fire time falls inside [start, end), shift to end
  Future<void> scheduleForLog({
    required String foodLogId,
    required DateTime loggedAt,
    Duration delay = const Duration(minutes: 45),
    String? mealSummary,
    String? inferredMood,
    bool reminderEnabled = true,
    bool checkinDisabled = false,
  }) async {
    if (!reminderEnabled || checkinDisabled) return;
    if (foodLogId.isEmpty) return;

    // Layers 2 + 3: master toggle + vacation mode.
    final prefs = await SharedPreferences.getInstance();
    final masterEnabled = prefs.getBool(_NotifPrefKeys.masterEnabled) ?? true;
    if (!masterEnabled) {
      debugPrint('🍽️ [CheckinReminder] Skipped — master push disabled');
      return;
    }
    final vacation = prefs.getBool(_NotifPrefKeys.vacationMode) ?? false;
    if (vacation) {
      debugPrint('🍽️ [CheckinReminder] Skipped — vacation mode active');
      return;
    }

    var fireAt = loggedAt.toLocal().add(delay);

    // Layer 4: quiet hours. Shift the fire time to the end of the window if
    // we'd otherwise nudge someone in the middle of the night.
    final quietEnabled = prefs.getBool(_NotifPrefKeys.quietHoursEnabled) ?? true;
    if (quietEnabled) {
      fireAt = _shiftOutOfQuietHours(
        fireAt,
        startHHmm: prefs.getString(_NotifPrefKeys.quietHoursStart) ?? '22:00',
        endHHmm: prefs.getString(_NotifPrefKeys.quietHoursEnd) ?? '08:00',
      );
    }

    if (fireAt.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      // Too close / in the past — would be noise, skip.
      return;
    }

    await _ensureChannel();

    final zoned = tz.TZDateTime.from(fireAt, tz.local);
    final id = notificationIdFor(foodLogId);
    final (title, body) = _copyFor(
      inferredMood: inferredMood,
      mealSummary: mealSummary,
    );

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.active,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        zoned,
        details,
        payload: 'openCheckin=$foodLogId',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
        '🍽️ [CheckinReminder] Scheduled log=$foodLogId for ${zoned.toIso8601String()}',
      );
    } catch (e, st) {
      debugPrint('❌ [CheckinReminder] Schedule failed: $e\n$st');
    }
  }

  /// Cancel the reminder for a given food_log. Call this on successful mood
  /// update so a nudge doesn't fire after the user already answered.
  Future<void> cancelForLog(String foodLogId) async {
    if (foodLogId.isEmpty) return;
    try {
      await _plugin.cancel(notificationIdFor(foodLogId));
    } catch (e) {
      debugPrint('⚠️ [CheckinReminder] Cancel failed: $e');
    }
  }

  (String title, String body) _copyFor({
    String? inferredMood,
    String? mealSummary,
  }) {
    final m = mealSummary?.isNotEmpty == true
        ? 'your ${mealSummary!}'
        : 'your meal';
    if (inferredMood != null && inferredMood.isNotEmpty) {
      return (
        'How did that meal sit?',
        'We guessed $m might leave you feeling $inferredMood. Tap to confirm or fix it.',
      );
    }
    return (
      'How did that meal feel?',
      'Quick 10-second check-in on $m — helps us spot what fuels you vs what drains you.',
    );
  }

  /// Shift `fireAt` out of the quiet-hours window [start, end). Window may
  /// wrap past midnight (e.g. 22:00 → 08:00).
  ///
  /// Strategy: if the fire time lands inside the window, push it to the
  /// window's end time on the appropriate calendar date. Never the reverse
  /// direction — we never pull a reminder *earlier*.
  DateTime _shiftOutOfQuietHours(
    DateTime fireAt, {
    required String startHHmm,
    required String endHHmm,
  }) {
    final startParts = startHHmm.split(':');
    final endParts = endHHmm.split(':');
    if (startParts.length != 2 || endParts.length != 2) return fireAt;
    final startH = int.tryParse(startParts[0]) ?? 22;
    final startM = int.tryParse(startParts[1]) ?? 0;
    final endH = int.tryParse(endParts[0]) ?? 8;
    final endM = int.tryParse(endParts[1]) ?? 0;

    final local = fireAt.toLocal();
    final startToday = DateTime(local.year, local.month, local.day, startH, startM);
    var endToday = DateTime(local.year, local.month, local.day, endH, endM);

    // Wraps midnight: 22:00–08:00 means the window spans two calendar days.
    final wrapsMidnight =
        endH < startH || (endH == startH && endM <= startM);

    bool inWindow;
    DateTime windowEnd;
    if (wrapsMidnight) {
      final startYesterday = startToday.subtract(const Duration(days: 1));
      // Case 1: fireAt is after today's start (evening) → in window until tomorrow's end.
      // Case 2: fireAt is before today's end (early morning) → in window, exit at today's end.
      if (!local.isBefore(startToday)) {
        inWindow = true;
        windowEnd = endToday.add(const Duration(days: 1));
      } else if (local.isBefore(endToday)) {
        inWindow = true;
        windowEnd = endToday;
      } else if (local.isBefore(startToday) && local.isAfter(startYesterday)) {
        inWindow = false;
        windowEnd = endToday;
      } else {
        inWindow = false;
        windowEnd = endToday;
      }
    } else {
      // Non-wrapping window (e.g. 12:00–14:00). Just check containment.
      inWindow = !local.isBefore(startToday) && local.isBefore(endToday);
      windowEnd = endToday;
    }
    if (!inWindow) return fireAt;
    return windowEnd.add(const Duration(minutes: 1));
  }
}
