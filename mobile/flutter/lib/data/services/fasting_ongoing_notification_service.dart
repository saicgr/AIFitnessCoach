/// Persistent, actionable ongoing notification for an active fast.
///
/// Shows a non-dismissable notification with the live fast — elapsed time
/// (native chronometer on Android), current metabolic stage, and goal /
/// ends-at — plus **Pause / Resume** and **End Fast** action buttons.
///
/// The action buttons are wired to callbacks that the app sets to call the
/// `fastingProvider` notifier methods (`pauseFast` / `resumeFast` /
/// `endFast`). Uses [flutter_local_notifications] only — no extra packages.
///
/// Android renders the full ongoing notification with chronometer + buttons.
/// On iOS, `flutter_local_notifications` cannot show a truly persistent
/// ongoing notification (the OS owns notification lifecycle) — the rich live
/// surface on iOS is the Live Activity (see [LiveActivityService]); this
/// service no-ops on iOS for the ongoing-notification path.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Action IDs used in fasting notification buttons.
class FastingNotifActionIds {
  static const pauseResume = 'fasting_pause_resume';
  static const endFast = 'fasting_end_fast';
}

/// Top-level callback required by flutter_local_notifications for
/// notification actions received while the app is in the background.
/// Must be a top-level or static function annotated with `vm:entry-point`.
@pragma('vm:entry-point')
void fastingOnBackgroundNotificationResponse(NotificationResponse response) {
  // The plugin spins up a short-lived isolate for background actions. We
  // forward the action into a static slot the main isolate drains on resume;
  // when the app is already foregrounded the foreground callback handles it
  // directly. This stub ensures background taps aren't dropped.
  debugPrint(
      '🕐 [FastingNotif] Background action: ${response.actionId}');
  FastingOngoingNotificationService.recordPendingBackgroundAction(
      response.actionId);
}

/// Singleton service that manages the persistent ongoing fast notification.
class FastingOngoingNotificationService {
  FastingOngoingNotificationService._();
  static final FastingOngoingNotificationService instance =
      FastingOngoingNotificationService._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Fixed notification ID so we can update / cancel deterministically.
  /// Distinct from the fasting-timer scheduled-notification IDs (100-105).
  static const int _notificationId = 110;

  static const String _channelId = 'active_fast';
  static const String _channelName = 'Active Fast';
  static const String _channelDescription =
      'Ongoing notification shown during an active fast';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isShowing = false;
  bool _permissionGranted = true;

  /// External callbacks wired by the app (see [wireCallbacks]). They should
  /// call the `fastingProvider` notifier's `pauseFast` / `resumeFast` /
  /// `endFast` methods.
  VoidCallback? onPauseResumePressed;
  VoidCallback? onEndFastPressed;
  VoidCallback? onNotificationTapped;

  /// Background-isolate action that fired while the app was not foregrounded.
  /// Drained by [drainPendingBackgroundAction] when the app resumes.
  static String? _pendingBackgroundAction;

  /// Whether the most recent [show] call had the fast paused. Needed so a
  /// background pause/resume tap toggles correctly even without live state.
  bool _lastIsPaused = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the plugin & create the low-importance channel.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          fastingOnBackgroundNotificationResponse,
    );

    if (Platform.isAndroid) {
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
        try {
          final granted =
              await androidPlugin.requestNotificationsPermission();
          _permissionGranted = granted ?? true;
        } catch (e) {
          debugPrint('⚠️ [FastingNotif] Permission request failed: $e');
          _permissionGranted = true; // fail-open
        }
      }
    }

    _initialized = true;
    debugPrint(
        '🕐 [FastingNotif] Initialized (permission=$_permissionGranted)');
  }

  // ---------------------------------------------------------------------------
  // Callback wiring
  // ---------------------------------------------------------------------------

  /// Wire the action callbacks to the fasting provider. Pass closures that
  /// call `fastingProvider.notifier`'s methods with the live user id.
  void wireCallbacks({
    required VoidCallback onPauseResume,
    required VoidCallback onEndFast,
    VoidCallback? onTap,
  }) {
    onPauseResumePressed = onPauseResume;
    onEndFastPressed = onEndFast;
    onNotificationTapped = onTap;
  }

  void clearCallbacks() {
    onPauseResumePressed = null;
    onEndFastPressed = null;
    onNotificationTapped = null;
  }

  // ---------------------------------------------------------------------------
  // Background action draining
  // ---------------------------------------------------------------------------

  /// Called from the background isolate to stash an action for later replay.
  static void recordPendingBackgroundAction(String? actionId) {
    if (actionId != null) _pendingBackgroundAction = actionId;
  }

  /// Drain any action that fired while the app was backgrounded and dispatch
  /// it to the wired callbacks. Call this on app resume.
  void drainPendingBackgroundAction() {
    final action = _pendingBackgroundAction;
    if (action == null) return;
    _pendingBackgroundAction = null;
    debugPrint('🕐 [FastingNotif] Draining background action: $action');
    _dispatchAction(action);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Show or update the ongoing fast notification.
  ///
  /// [startedAt] should be the wall-clock start shifted forward by total
  /// paused seconds, so the Android chronometer renders correct elapsed time.
  /// [endsAtText] is a human "ends ~7:30 PM" / goal string for the body.
  Future<void> show({
    required String stageName,
    required String stageDescription,
    required String elapsedText,
    required String goalText,
    required String endsAtText,
    required bool isPaused,
    required double progress,
    DateTime? chronometerAnchor,
  }) async {
    if (!Platform.isAndroid) {
      // iOS persistent notification isn't supported by the plugin — the
      // Live Activity is the iOS live surface. No-op here.
      _isShowing = true;
      _lastIsPaused = isPaused;
      return;
    }
    if (!_initialized) await initialize();
    if (!_permissionGranted) return;

    _lastIsPaused = isPaused;

    final pauseResumeLabel = isPaused ? 'Resume' : 'Pause';
    final showChronometer = chronometerAnchor != null && !isPaused;
    final progressPercent = (progress.clamp(0.0, 1.0) * 100).round();

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
      onlyAlertOnce: true, // no sound/vibration on every update
      showWhen: showChronometer,
      when: showChronometer
          ? chronometerAnchor.millisecondsSinceEpoch
          : null,
      usesChronometer: showChronometer,
      subText: showChronometer ? endsAtText : '$elapsedText · $endsAtText',
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.service,
      styleInformation: BigTextStyleInformation(
        stageDescription,
        contentTitle: 'Fasting · $stageName',
        summaryText: goalText,
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          FastingNotifActionIds.pauseResume,
          pauseResumeLabel,
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          FastingNotifActionIds.endFast,
          'End Fast',
          showsUserInterface: true, // bring app to foreground on end
          cancelNotification: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        _notificationId,
        'Fasting · $stageName',
        '${isPaused ? '⏸ Paused' : '🔥 In Progress'}  ·  $goalText',
        details,
        payload: 'active_fast',
      );
      _isShowing = true;
    } catch (e) {
      debugPrint('⚠️ [FastingNotif] show() failed: $e');
    }
  }

  /// Cancel / remove the ongoing fast notification.
  Future<void> cancel() async {
    if (!_isShowing) return;
    if (Platform.isAndroid) {
      await _plugin.cancel(_notificationId);
    }
    _isShowing = false;
    debugPrint('🕐 [FastingNotif] Cancelled');
  }

  /// Whether the ongoing notification is currently visible.
  bool get isShowing => _isShowing;

  /// Whether the last shown state was paused (used by background toggle).
  bool get lastIsPaused => _lastIsPaused;

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint(
        '🕐 [FastingNotif] Action: ${response.actionId}, payload: ${response.payload}');
    if (response.actionId == null) {
      if (response.payload == 'active_fast') onNotificationTapped?.call();
      return;
    }
    _dispatchAction(response.actionId!);
  }

  void _dispatchAction(String actionId) {
    switch (actionId) {
      case FastingNotifActionIds.pauseResume:
        onPauseResumePressed?.call();
        break;
      case FastingNotifActionIds.endFast:
        onEndFastPressed?.call();
        break;
    }
  }
}
