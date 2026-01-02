import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_client.dart';

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsService(apiClient);
});

/// Screen time tracker provider (for automatic screen tracking)
final screenTimeTrackerProvider = Provider<ScreenTimeTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return ScreenTimeTracker(analytics);
});

/// Analytics service for tracking user behavior and screen time
class AnalyticsService {
  final ApiClient _apiClient;

  String? _sessionId;
  String? _userId;
  String? _anonymousId;
  DateTime? _sessionStartTime;

  // Device info cache
  String? _deviceType;
  String? _deviceModel;
  String? _osVersion;
  String? _appVersion;
  String? _appBuild;

  // Offline queue for batch upload
  final List<Map<String, dynamic>> _offlineQueue = [];
  Timer? _batchTimer;

  static const _batchUploadInterval = Duration(seconds: 30);
  static const _maxQueueSize = 100;

  AnalyticsService(this._apiClient);

  /// Initialize analytics with user info
  Future<void> initialize({String? userId}) async {
    _userId = userId;
    _anonymousId ??= const Uuid().v4();

    // Get device info
    await _loadDeviceInfo();

    // Start session
    await startSession();

    // Start batch upload timer
    _startBatchTimer();
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      _appVersion = packageInfo.version;
      _appBuild = packageInfo.buildNumber;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceType = 'ios';
        _deviceModel = iosInfo.model;
        _osVersion = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceType = 'android';
        _deviceModel = androidInfo.model;
        _osVersion = androidInfo.version.release;
      }
    } catch (e) {
      debugPrint('Failed to load device info: $e');
    }
  }

  /// Start a new analytics session
  Future<String?> startSession({String? entryPoint}) async {
    try {
      final response = await _apiClient.dio.post(
        '/analytics/session/start',
        data: {
          'user_id': _userId,
          'anonymous_id': _anonymousId,
          'device_type': _deviceType,
          'device_model': _deviceModel,
          'os_version': _osVersion,
          'app_version': _appVersion,
          'app_build': _appBuild,
          'entry_point': entryPoint ?? 'launch',
        },
      );

      _sessionId = response.data['session_id'];
      _sessionStartTime = DateTime.now();

      debugPrint('Analytics session started: $_sessionId');
      return _sessionId;
    } catch (e) {
      debugPrint('Failed to start analytics session: $e');
      // Generate local session ID for offline tracking
      _sessionId = const Uuid().v4();
      _sessionStartTime = DateTime.now();
      return _sessionId;
    }
  }

  /// End the current session
  Future<void> endSession() async {
    if (_sessionId == null) return;

    try {
      await _apiClient.dio.post(
        '/analytics/session/end',
        data: {'session_id': _sessionId},
      );

      debugPrint('Analytics session ended: $_sessionId');
    } catch (e) {
      debugPrint('Failed to end analytics session: $e');
    }

    // Upload any remaining queued events
    await _uploadBatch();

    _sessionId = null;
    _sessionStartTime = null;
  }

  /// Update user ID (after login)
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Track a screen view
  Future<String?> trackScreenView({
    required String screenName,
    String? screenClass,
    String? previousScreen,
    Map<String, dynamic>? extraParams,
  }) async {
    final data = {
      'user_id': _userId,
      'session_id': _sessionId,
      'screen_name': screenName,
      'screen_class': screenClass,
      'previous_screen': previousScreen,
      'extra_params': extraParams,
    };

    try {
      final response = await _apiClient.dio.post(
        '/analytics/screen-view',
        data: data,
      );

      return response.data['screen_view_id'];
    } catch (e) {
      debugPrint('Failed to track screen view: $e');
      // Queue for batch upload
      _queueEvent('screen_view', data);
      return null;
    }
  }

  /// Track screen exit with duration
  Future<void> trackScreenExit({
    required String screenViewId,
    required int durationMs,
    int? scrollDepthPercent,
    int? interactionsCount,
  }) async {
    final data = {
      'screen_view_id': screenViewId,
      'duration_ms': durationMs,
      'scroll_depth_percent': scrollDepthPercent,
      'interactions_count': interactionsCount,
    };

    try {
      await _apiClient.dio.post(
        '/analytics/screen-exit',
        data: data,
      );
    } catch (e) {
      debugPrint('Failed to track screen exit: $e');
      _queueEvent('screen_exit', data);
    }
  }

  /// Track a custom event
  Future<void> trackEvent({
    required String eventName,
    String? category,
    Map<String, dynamic>? properties,
    String? screenName,
  }) async {
    final data = {
      'user_id': _userId,
      'session_id': _sessionId,
      'anonymous_id': _anonymousId,
      'event_name': eventName,
      'event_category': category,
      'properties': properties,
      'screen_name': screenName,
      'device_type': _deviceType,
      'app_version': _appVersion,
    };

    try {
      await _apiClient.dio.post(
        '/analytics/event',
        data: data,
      );
    } catch (e) {
      debugPrint('Failed to track event: $e');
      _queueEvent('event', data);
    }
  }

  /// Track funnel event
  Future<void> trackFunnelEvent({
    required String funnelName,
    required String stepName,
    int? stepNumber,
    int? timeSinceFunnelStartMs,
    bool completed = false,
    bool droppedOff = false,
    String? dropOffReason,
    Map<String, dynamic>? properties,
  }) async {
    final data = {
      'user_id': _userId,
      'session_id': _sessionId,
      'anonymous_id': _anonymousId,
      'funnel_name': funnelName,
      'step_name': stepName,
      'step_number': stepNumber,
      'time_since_funnel_start_ms': timeSinceFunnelStartMs,
      'completed': completed,
      'dropped_off': droppedOff,
      'drop_off_reason': dropOffReason,
      'properties': properties,
    };

    try {
      await _apiClient.dio.post(
        '/analytics/funnel',
        data: data,
      );
    } catch (e) {
      debugPrint('Failed to track funnel event: $e');
      _queueEvent('funnel', data);
    }
  }

  /// Track onboarding step
  Future<void> trackOnboardingStep({
    required String stepName,
    int? stepNumber,
    bool completed = false,
    bool skipped = false,
    int? durationMs,
    int? aiMessagesReceived,
    int? userMessagesSent,
    List<String>? optionsSelected,
    String? error,
    String? experimentId,
    String? variant,
  }) async {
    final data = {
      'user_id': _userId,
      'session_id': _sessionId,
      'anonymous_id': _anonymousId,
      'step_name': stepName,
      'step_number': stepNumber,
      'completed': completed,
      'skipped': skipped,
      'duration_ms': durationMs,
      'ai_messages_received': aiMessagesReceived,
      'user_messages_sent': userMessagesSent,
      'options_selected': optionsSelected,
      'error': error,
      'experiment_id': experimentId,
      'variant': variant,
    };

    try {
      await _apiClient.dio.post(
        '/analytics/onboarding',
        data: data,
      );
    } catch (e) {
      debugPrint('Failed to track onboarding step: $e');
      _queueEvent('onboarding', data);
    }
  }

  /// Track paywall impression
  Future<void> trackPaywallImpression({
    required String screen,
    required String action,
    String? source,
    String? selectedProduct,
    int? timeOnScreenMs,
    String? experimentId,
    String? variant,
  }) async {
    try {
      await _apiClient.dio.post(
        '/subscriptions/${_userId ?? 'anonymous'}/paywall-impression',
        data: {
          'screen': screen,
          'source': source,
          'action': action,
          'selected_product': selectedProduct,
          'time_on_screen_ms': timeOnScreenMs,
          'session_id': _sessionId,
          'device_type': _deviceType,
          'app_version': _appVersion,
          'experiment_id': experimentId,
          'variant': variant,
        },
      );
    } catch (e) {
      debugPrint('Failed to track paywall impression: $e');
    }
  }

  /// Track app error
  Future<void> trackError({
    required String errorType,
    String? errorMessage,
    String? errorCode,
    String? stackTrace,
    String? screenName,
    String? action,
    Map<String, dynamic>? extraData,
  }) async {
    final data = {
      'user_id': _userId,
      'session_id': _sessionId,
      'error_type': errorType,
      'error_message': errorMessage,
      'error_code': errorCode,
      'stack_trace': stackTrace,
      'screen_name': screenName,
      'action': action,
      'device_type': _deviceType,
      'os_version': _osVersion,
      'app_version': _appVersion,
      'extra_data': extraData,
    };

    try {
      await _apiClient.dio.post(
        '/analytics/error',
        data: data,
      );
    } catch (e) {
      debugPrint('Failed to track error: $e');
      _queueEvent('error', data);
    }
  }

  /// Queue event for batch upload
  void _queueEvent(String type, Map<String, dynamic> data) {
    if (_offlineQueue.length >= _maxQueueSize) {
      // Remove oldest event
      _offlineQueue.removeAt(0);
    }

    _offlineQueue.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Start batch upload timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchUploadInterval, (_) {
      _uploadBatch();
    });
  }

  /// Upload queued events
  Future<void> _uploadBatch() async {
    if (_offlineQueue.isEmpty) return;

    final events = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    try {
      await _apiClient.dio.post(
        '/analytics/batch',
        data: {
          'user_id': _userId,
          'session_id': _sessionId,
          'events': events,
        },
      );

      debugPrint('Uploaded ${events.length} queued analytics events');
    } catch (e) {
      debugPrint('Failed to upload batch: $e');
      // Re-queue events
      _offlineQueue.insertAll(0, events);
    }
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
  }

  // Convenience methods for common events

  /// Track workout started
  Future<void> trackWorkoutStarted(String workoutId, String workoutName) async {
    await trackEvent(
      eventName: 'workout_started',
      category: 'engagement',
      properties: {
        'workout_id': workoutId,
        'workout_name': workoutName,
      },
    );
  }

  /// Track workout completed
  Future<void> trackWorkoutCompleted(
    String workoutId, {
    required int durationSeconds,
    required int exercisesCompleted,
    int? caloriesBurned,
  }) async {
    await trackEvent(
      eventName: 'workout_completed',
      category: 'engagement',
      properties: {
        'workout_id': workoutId,
        'duration_seconds': durationSeconds,
        'exercises_completed': exercisesCompleted,
        'calories_burned': caloriesBurned,
      },
    );
  }

  /// Track AI message sent
  Future<void> trackAiMessageSent({
    String? intent,
    int? messageLength,
  }) async {
    await trackEvent(
      eventName: 'ai_message_sent',
      category: 'engagement',
      properties: {
        'intent': intent,
        'message_length': messageLength,
      },
    );
  }

  /// Track feature used
  Future<void> trackFeatureUsed(String featureName) async {
    await trackEvent(
      eventName: 'feature_used',
      category: 'feature',
      properties: {'feature': featureName},
    );
  }
}

/// Helper class for automatic screen time tracking
class ScreenTimeTracker {
  final AnalyticsService _analytics;

  String? _currentScreenViewId;
  String? _currentScreenName;
  DateTime? _screenEnteredAt;
  int _interactionsCount = 0;

  ScreenTimeTracker(this._analytics);

  /// Call when entering a new screen
  Future<void> enterScreen({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? extraParams,
  }) async {
    // Exit previous screen first
    await exitCurrentScreen();

    _currentScreenName = screenName;
    _screenEnteredAt = DateTime.now();
    _interactionsCount = 0;

    _currentScreenViewId = await _analytics.trackScreenView(
      screenName: screenName,
      screenClass: screenClass,
      previousScreen: _currentScreenName,
      extraParams: extraParams,
    );
  }

  /// Call when exiting current screen
  Future<void> exitCurrentScreen({int? scrollDepthPercent}) async {
    if (_currentScreenViewId == null || _screenEnteredAt == null) return;

    final durationMs = DateTime.now().difference(_screenEnteredAt!).inMilliseconds;

    await _analytics.trackScreenExit(
      screenViewId: _currentScreenViewId!,
      durationMs: durationMs,
      scrollDepthPercent: scrollDepthPercent,
      interactionsCount: _interactionsCount,
    );

    _currentScreenViewId = null;
    _currentScreenName = null;
    _screenEnteredAt = null;
    _interactionsCount = 0;
  }

  /// Record an interaction (tap, swipe, etc.)
  void recordInteraction() {
    _interactionsCount++;
  }

  /// Get current screen duration
  int get currentDurationMs {
    if (_screenEnteredAt == null) return 0;
    return DateTime.now().difference(_screenEnteredAt!).inMilliseconds;
  }

  /// Get current screen name
  String? get currentScreenName => _currentScreenName;
}
