/// Persistent notification for active workouts (Android foreground-style).
///
/// Shows an ongoing, non-dismissable notification with workout info,
/// timer, exercise progress, and Pause/Resume + Stop action buttons.
/// Uses [flutter_local_notifications] only — no extra packages.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Action IDs used in notification buttons.
class _ActionIds {
  static const pauseResume = 'workout_pause_resume';
  static const stop = 'workout_stop';
}

/// Top-level callback required by flutter_local_notifications for
/// notification actions received while the app is in the background.
/// Must be a top-level or static function.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Actions are handled in-process via the foreground callback; this stub
  // is required so the plugin doesn't drop background taps entirely.
  debugPrint('🏋️ [WorkoutNotif] Background action: ${response.actionId}');
}

/// Singleton service that manages the persistent workout notification.
///
/// This is intentionally **not** a Riverpod provider so it stays decoupled
/// from the widget tree and can be called from anywhere.
class WorkoutNotificationService {
  WorkoutNotificationService._();
  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Fixed notification ID so we can update / cancel deterministically.
  static const int _notificationId = 999;

  static const String _channelId = 'active_workout';
  static const String _channelName = 'Active Workout';
  static const String _channelDescription =
      'Ongoing notification shown during an active workout session';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isShowing = false;
  bool _permissionGranted = true; // assume yes until we check

  /// External callbacks wired up by the active workout screen / provider.
  VoidCallback? onPauseResumePressed;
  VoidCallback? onStopPressed;
  VoidCallback? onNotificationTapped;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the plugin & create the low-importance channel.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      _initialized = true;
      return; // Persistent notifications are Android-only for now
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher_monochrome');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create a dedicated low-importance channel (no sound / vibration).
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.low, // silent updates
          playSound: false,
          enableVibration: false,
          enableLights: false,
        ),
      );

      // Android 13+ requires runtime POST_NOTIFICATIONS permission.
      // If denied, we silently no-op in show() rather than spamming
      // failed calls every second.
      try {
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionGranted = granted ?? true;
      } catch (e) {
        debugPrint('⚠️ [WorkoutNotif] Permission request failed: $e');
        _permissionGranted = true; // fail-open; show() will try and may fail
      }
    }

    _initialized = true;
    debugPrint('🏋️ [WorkoutNotif] Initialized (permission=$_permissionGranted)');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Show or update the persistent workout notification.
  ///
  /// Call this every second (on timer tick) to keep the notification current.
  ///
  /// When [startedAt] is supplied the Android chronometer renders the elapsed
  /// time natively (no per-second Dart push required for the clock). When
  /// [completedExercises] is supplied an integer progress bar is drawn
  /// against [totalExercises].
  Future<void> show({
    required String workoutName,
    required String currentExerciseName,
    required String timerText,
    required String exerciseProgress,
    required bool isPaused,
    DateTime? startedAt,
    int? completedExercises,
    int? totalExercises,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) await initialize();
    if (!_permissionGranted) return; // user denied POST_NOTIFICATIONS

    final pauseResumeLabel = isPaused ? 'Resume' : 'Pause';
    const pauseResumeIcon =
        'ic_launcher_monochrome'; // DrawableResourceAndroidIcon uses @drawable/

    final showChronometer = startedAt != null && !isPaused;
    final progressKnown = completedExercises != null &&
        totalExercises != null &&
        totalExercises > 0;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true, // critical — prevents sound/vibration on every update
      // Native chronometer handles the ticking clock — if startedAt is
      // provided we anchor `when` to wall-clock start and let Android render
      // elapsed time. Fallback to subText when we don't have a start time or
      // the user is paused (chronometer has no "freeze" mode).
      showWhen: showChronometer,
      when: showChronometer ? startedAt.millisecondsSinceEpoch : null,
      usesChronometer: showChronometer,
      subText: showChronometer ? null : timerText,
      showProgress: progressKnown,
      maxProgress: progressKnown ? totalExercises : 0,
      progress: progressKnown ? completedExercises : 0,
      icon: '@drawable/ic_launcher_monochrome',
      category: AndroidNotificationCategory.service,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _ActionIds.pauseResume,
          pauseResumeLabel,
          icon: DrawableResourceAndroidBitmap(pauseResumeIcon),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          _ActionIds.stop,
          'Stop',
          icon: DrawableResourceAndroidBitmap(pauseResumeIcon),
          showsUserInterface: true, // bring app to foreground on stop
          cancelNotification: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        _notificationId,
        '$workoutName  ·  $exerciseProgress',
        '${isPaused ? '⏸ Paused' : '🏋️ In Progress'}  ·  $currentExerciseName',
        details,
        payload: 'active_workout',
      );
      _isShowing = true;
    } catch (e) {
      debugPrint('⚠️ [WorkoutNotif] show() failed: $e');
    }
  }

  /// Cancel / remove the persistent notification.
  Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    if (!_isShowing) return;

    await _plugin.cancel(_notificationId);
    _isShowing = false;
    debugPrint('🏋️ [WorkoutNotif] Cancelled');
  }

  /// Whether the notification is currently visible.
  bool get isShowing => _isShowing;

  /// Clean up callbacks. Call when the workout ends.
  void clearCallbacks() {
    onPauseResumePressed = null;
    onStopPressed = null;
    onNotificationTapped = null;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint(
        '🏋️ [WorkoutNotif] Action: ${response.actionId}, payload: ${response.payload}');

    switch (response.actionId) {
      case _ActionIds.pauseResume:
        onPauseResumePressed?.call();
        break;
      case _ActionIds.stop:
        onStopPressed?.call();
        break;
      default:
        // Tapped the notification body (no actionId)
        if (response.payload == 'active_workout') {
          onNotificationTapped?.call();
        }
        break;
    }
  }
}
