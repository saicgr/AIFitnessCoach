import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/fasting.dart';
import 'fasting_live_activity_service.dart';
import 'fasting_ongoing_notification_service.dart';

/// Fasting timer service provider
final fastingTimerServiceProvider = Provider<FastingTimerService>((ref) {
  final service = FastingTimerService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service for managing fasting timer, notifications, and zone transitions
class FastingTimerService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _zoneCheckTimer;
  FastingZone? _lastNotifiedZone;

  /// Drives periodic refresh of the live fast surface (ongoing notification
  /// + iOS Live Activity). Distinct from [_zoneCheckTimer].
  Timer? _liveSurfaceTimer;

  /// The zone last pushed to the live surface — updates are only sent on a
  /// zone change (native chronometers tick the clock themselves).
  FastingZone? _lastLiveSurfaceZone;

  /// The pause-state last pushed to the live surface.
  bool? _lastLiveSurfacePaused;

  FastingTimerService(this._ref);

  // ============================================
  // Notification Channel IDs
  // ============================================
  static const String _channelIdFasting = 'fasting_channel';
  static const String _channelNameFasting = 'Fasting Notifications';
  static const String _channelDescFasting =
      'Notifications for fasting progress and zone transitions';

  // ============================================
  // Notification IDs
  // ============================================
  static const int _notifIdZoneTransition = 100;
  static const int _notifIdGoalReached = 101;
  static const int _notifIdHalfway = 102;
  static const int _notifIdGoalApproaching = 103;
  static const int _notifIdEatingWindowEnding = 104;
  static const int _notifIdStreakReminder = 105;

  /// Initialize the fasting notification service
  Future<void> initialize() async {
    debugPrint('🔔 [FastingTimer] Initializing notification service');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelIdFasting,
            _channelNameFasting,
            description: _channelDescFasting,
            importance: Importance.high,
          ),
        );

    debugPrint('✅ [FastingTimer] Notification service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [FastingTimer] Notification tapped: ${response.payload}');
    // Navigate to fasting screen (handled by deep link service)
  }

  // ============================================
  // Timer Management
  // ============================================

  /// Start monitoring an active fast for zone transitions
  void startZoneMonitoring(FastingRecord fast) {
    debugPrint('⏱️ [FastingTimer] Starting zone monitoring');
    _lastNotifiedZone = fast.currentZone;
    _stopZoneMonitoring();

    // Check every minute for zone transitions
    _zoneCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkZoneTransition(fast);
    });

    // Schedule future notifications
    _scheduleNotifications(fast);
  }

  /// Stop zone monitoring
  void _stopZoneMonitoring() {
    _zoneCheckTimer?.cancel();
    _zoneCheckTimer = null;
  }

  /// Check if zone has changed and notify
  void _checkZoneTransition(FastingRecord fast) {
    final currentZone = FastingZone.fromElapsedMinutes(
      DateTime.now().difference(fast.startTime).inMinutes,
    );

    if (_lastNotifiedZone != currentZone) {
      debugPrint('🎯 [FastingTimer] Zone transition: $_lastNotifiedZone -> $currentZone');
      _lastNotifiedZone = currentZone;
      _showZoneTransitionNotification(currentZone);
    }
  }

  // ============================================
  // Notification Scheduling
  // ============================================

  /// Schedule all notifications for a fast
  Future<void> _scheduleNotifications(FastingRecord fast) async {
    debugPrint('📅 [FastingTimer] Scheduling notifications for fast');

    final now = DateTime.now();
    final elapsedMinutes = now.difference(fast.startTime).inMinutes;
    final remainingMinutes = fast.goalDurationMinutes - elapsedMinutes;

    // Schedule zone transition notifications
    for (final zone in FastingZone.values) {
      final zoneStartMinutes = zone.startHour * 60;
      if (zoneStartMinutes > elapsedMinutes) {
        final minutesUntilZone = zoneStartMinutes - elapsedMinutes;
        await _scheduleNotification(
          id: _notifIdZoneTransition + zone.index,
          title: 'New Fasting Zone! 🎯',
          body: 'You\'ve entered ${zone.displayName}. ${zone.description}',
          scheduledFor: now.add(Duration(minutes: minutesUntilZone)),
        );
      }
    }

    // Schedule halfway notification
    final halfwayMinutes = fast.goalDurationMinutes ~/ 2;
    if (halfwayMinutes > elapsedMinutes) {
      await _scheduleNotification(
        id: _notifIdHalfway,
        title: 'Halfway There! 💪',
        body: 'You\'re 50% through your fast. Keep going!',
        scheduledFor: now.add(Duration(minutes: halfwayMinutes - elapsedMinutes)),
      );
    }

    // Schedule goal approaching notification (1 hour before)
    final hourBeforeMinutes = fast.goalDurationMinutes - 60;
    if (hourBeforeMinutes > elapsedMinutes) {
      await _scheduleNotification(
        id: _notifIdGoalApproaching,
        title: 'Almost Done! ⏰',
        body: 'Just 1 hour remaining in your fast!',
        scheduledFor: now.add(Duration(minutes: hourBeforeMinutes - elapsedMinutes)),
      );
    }

    // Schedule goal reached notification
    if (remainingMinutes > 0) {
      await _scheduleNotification(
        id: _notifIdGoalReached,
        title: 'Goal Reached! 🎉',
        body: 'Congratulations! You completed your ${fast.goalDurationMinutes ~/ 60}h fast!',
        scheduledFor: now.add(Duration(minutes: remainingMinutes)),
      );
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
    String? payload,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledFor, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelIdFasting,
            _channelNameFasting,
            channelDescription: _channelDescFasting,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? 'fasting',
      );
      debugPrint('📅 [FastingTimer] Scheduled: $title at $scheduledFor');
    } catch (e) {
      debugPrint('❌ [FastingTimer] Failed to schedule notification: $e');
    }
  }

  /// Show immediate zone transition notification
  Future<void> _showZoneTransitionNotification(FastingZone zone) async {
    try {
      await _notifications.show(
        _notifIdZoneTransition,
        'New Fasting Zone! 🎯',
        'You\'ve entered ${zone.displayName}. ${zone.description}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelIdFasting,
            _channelNameFasting,
            channelDescription: _channelDescFasting,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: zone.color,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'zone_${zone.name}',
      );
    } catch (e) {
      debugPrint('❌ [FastingTimer] Failed to show zone notification: $e');
    }
  }

  /// Show fast started notification
  Future<void> showFastStartedNotification(FastingProtocol protocol) async {
    try {
      await _notifications.show(
        _notifIdZoneTransition,
        'Fast Started! 🕐',
        'Your ${protocol.displayName} fast has begun. Stay hydrated!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelIdFasting,
            _channelNameFasting,
            channelDescription: _channelDescFasting,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: 'fast_started',
      );
    } catch (e) {
      debugPrint('❌ [FastingTimer] Failed to show start notification: $e');
    }
  }

  /// Show fast completed notification
  Future<void> showFastCompletedNotification(FastEndResult result) async {
    try {
      final completionPercent = (result.record.completionPercentage ?? result.record.progress * 100);
      final message = completionPercent >= 100
          ? 'Excellent! You completed your fast!'
          : 'Great job! You completed ${completionPercent.toStringAsFixed(0)}% of your goal.';

      await _notifications.show(
        _notifIdGoalReached,
        'Fast Complete! 🎉',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelIdFasting,
            _channelNameFasting,
            channelDescription: _channelDescFasting,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'fast_completed',
      );
    } catch (e) {
      debugPrint('❌ [FastingTimer] Failed to show complete notification: $e');
    }
  }

  /// Cancel all fasting notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('🚫 [FastingTimer] Cancelling all fasting notifications');
    _stopZoneMonitoring();

    // Cancel all scheduled fasting notifications
    for (int i = 0; i < FastingZone.values.length; i++) {
      await _notifications.cancel(_notifIdZoneTransition + i);
    }
    await _notifications.cancel(_notifIdGoalReached);
    await _notifications.cancel(_notifIdHalfway);
    await _notifications.cancel(_notifIdGoalApproaching);
    await _notifications.cancel(_notifIdEatingWindowEnding);
  }

  /// Schedule eating window ending notification
  Future<void> scheduleEatingWindowEndNotification({
    required DateTime windowEnd,
    int minutesBefore = 60,
  }) async {
    final notifyAt = windowEnd.subtract(Duration(minutes: minutesBefore));
    if (notifyAt.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _notifIdEatingWindowEnding,
        title: 'Eating Window Ending ⏰',
        body: 'Your eating window closes in $minutesBefore minutes.',
        scheduledFor: notifyAt,
        payload: 'eating_window_ending',
      );
    }
  }

  /// Schedule streak reminder notification
  Future<void> scheduleStreakReminder({
    required DateTime remindAt,
  }) async {
    if (remindAt.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _notifIdStreakReminder,
        title: 'Don\'t Forget Your Fast! 🔥',
        body: 'Start your fast to maintain your streak!',
        scheduledFor: remindAt,
        payload: 'streak_reminder',
      );
    }
  }

  // ============================================
  // Zone Calculation Utilities
  // ============================================

  /// Get the next zone and time until it
  ZoneTransitionInfo? getNextZoneTransition(FastingRecord fast) {
    final currentMinutes =
        DateTime.now().difference(fast.startTime).inMinutes;
    final currentZone = FastingZone.fromElapsedMinutes(currentMinutes);

    // Find next zone
    final zones = FastingZone.values;
    final currentIndex = zones.indexOf(currentZone);

    if (currentIndex >= zones.length - 1) {
      return null; // Already at the last zone
    }

    final nextZone = zones[currentIndex + 1];
    final minutesUntilNextZone =
        (nextZone.startHour * 60) - currentMinutes;

    return ZoneTransitionInfo(
      nextZone: nextZone,
      minutesUntil: minutesUntilNextZone,
      formattedTime: _formatDuration(minutesUntilNextZone),
    );
  }

  /// Get all upcoming zone transitions
  List<ZoneTransitionInfo> getUpcomingZoneTransitions(FastingRecord fast) {
    final currentMinutes =
        DateTime.now().difference(fast.startTime).inMinutes;
    final transitions = <ZoneTransitionInfo>[];

    for (final zone in FastingZone.values) {
      final zoneStartMinutes = zone.startHour * 60;
      if (zoneStartMinutes > currentMinutes) {
        final minutesUntil = zoneStartMinutes - currentMinutes;
        transitions.add(ZoneTransitionInfo(
          nextZone: zone,
          minutesUntil: minutesUntil,
          formattedTime: _formatDuration(minutesUntil),
        ));
      }
    }

    return transitions;
  }

  /// Format duration in hours and minutes
  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // ============================================
  // Live Fast Surface (ongoing notification + iOS Live Activity)
  // ============================================

  /// Start the live fast surface for [fast]: an ongoing actionable
  /// notification (Android) and an iOS Live Activity. Respects the user's
  /// fasting notification preferences via [notificationsEnabled].
  ///
  /// Fired on fast start / resume. Idempotent — re-starting refreshes.
  Future<void> startLiveSurface(
    FastingRecord fast, {
    required bool notificationsEnabled,
  }) async {
    if (!notificationsEnabled) {
      debugPrint(
          '🕐 [FastingTimer] Notifications disabled — skipping live surface');
      return;
    }
    try {
      await FastingOngoingNotificationService.instance.initialize();
      await FastingLiveActivityService.instance.init();

      final state = _buildActivityState(fast);
      await FastingLiveActivityService.instance.start(state);
      await _showOngoingNotification(fast);

      _lastLiveSurfaceZone = fast.currentZone;
      _lastLiveSurfacePaused = fast.isPaused;

      // Refresh the surfaces periodically so stage / pause changes and the
      // ends-at body stay current. Native chronometers tick the clock.
      _liveSurfaceTimer?.cancel();
      _liveSurfaceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshLiveSurface(fast),
      );
      debugPrint('🕐 [FastingTimer] Live fast surface started');
    } catch (e) {
      debugPrint('❌ [FastingTimer] startLiveSurface failed: $e');
    }
  }

  /// Push the latest [fast] state to the live surface — call after pause /
  /// resume so the buttons + status flip immediately.
  Future<void> updateLiveSurface(
    FastingRecord fast, {
    required bool notificationsEnabled,
  }) async {
    if (!notificationsEnabled) return;
    if (!FastingOngoingNotificationService.instance.isShowing &&
        !FastingLiveActivityService.instance.isActive) {
      // Surface isn't up (e.g. notifications were off at start) — start it.
      await startLiveSurface(fast, notificationsEnabled: notificationsEnabled);
      return;
    }
    try {
      await FastingLiveActivityService.instance
          .update(_buildActivityState(fast));
      await _showOngoingNotification(fast);
      _lastLiveSurfaceZone = fast.currentZone;
      _lastLiveSurfacePaused = fast.isPaused;
    } catch (e) {
      debugPrint('❌ [FastingTimer] updateLiveSurface failed: $e');
    }
  }

  /// Tear down the live fast surface. Fired on fast end / cancel.
  Future<void> endLiveSurface() async {
    _liveSurfaceTimer?.cancel();
    _liveSurfaceTimer = null;
    _lastLiveSurfaceZone = null;
    _lastLiveSurfacePaused = null;
    try {
      await FastingLiveActivityService.instance.end();
      await FastingOngoingNotificationService.instance.cancel();
      debugPrint('🕐 [FastingTimer] Live fast surface ended');
    } catch (e) {
      debugPrint('❌ [FastingTimer] endLiveSurface failed: $e');
    }
  }

  /// Periodic tick — only pushes an update when the stage or pause-state has
  /// actually changed (cheap on battery; clocks tick natively).
  Future<void> _refreshLiveSurface(FastingRecord fast) async {
    final zone = fast.currentZone;
    if (zone != _lastLiveSurfaceZone ||
        fast.isPaused != _lastLiveSurfacePaused) {
      await FastingLiveActivityService.instance
          .update(_buildActivityState(fast));
      await _showOngoingNotification(fast);
      _lastLiveSurfaceZone = zone;
      _lastLiveSurfacePaused = fast.isPaused;
    }
  }

  /// Build the iOS Live Activity state from a [FastingRecord].
  FastingActivityState _buildActivityState(FastingRecord fast) {
    final zone = fast.currentZone;
    final goalEndsAt =
        fast.startTime.add(Duration(minutes: fast.goalDurationMinutes));
    return FastingActivityState(
      protocolName: FastingProtocol.fromString(fast.protocol).displayName,
      stageName: zone.displayName,
      stageDescription: zone.description,
      startedAt: fast.startTime,
      goalEndsAt: goalEndsAt,
      goalDurationMinutes: fast.goalDurationMinutes,
      isPaused: fast.isPaused,
      pausedSeconds: fast.totalPausedSeconds,
    );
  }

  /// Show / refresh the Android ongoing actionable notification.
  Future<void> _showOngoingNotification(FastingRecord fast) async {
    final zone = fast.currentZone;
    final goalEndsAt = fast.startTime
        .add(Duration(minutes: fast.goalDurationMinutes))
        .add(Duration(seconds: fast.totalPausedSeconds));
    // Anchor the native chronometer to start + total paused time so it
    // renders pause-aware elapsed time.
    final chronometerAnchor =
        fast.startTime.add(Duration(seconds: fast.totalPausedSeconds));

    final goalHours = fast.goalDurationMinutes ~/ 60;
    await FastingOngoingNotificationService.instance.show(
      stageName: zone.displayName,
      stageDescription: zone.description,
      elapsedText: fast.elapsedTimeString,
      goalText: '${goalHours}h goal',
      endsAtText: fast.isPaused
          ? 'Paused'
          : 'Ends ~${_formatClock(goalEndsAt)}',
      isPaused: fast.isPaused,
      progress: fast.progress,
      chronometerAnchor: chronometerAnchor,
    );
  }

  /// Format a [DateTime] as a short wall-clock time, e.g. "7:30 PM".
  String _formatClock(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // ============================================
  // Cleanup
  // ============================================

  /// Dispose of resources
  void dispose() {
    _stopZoneMonitoring();
    _liveSurfaceTimer?.cancel();
  }
}

/// Information about an upcoming zone transition
class ZoneTransitionInfo {
  final FastingZone nextZone;
  final int minutesUntil;
  final String formattedTime;

  ZoneTransitionInfo({
    required this.nextZone,
    required this.minutesUntil,
    required this.formattedTime,
  });
}
