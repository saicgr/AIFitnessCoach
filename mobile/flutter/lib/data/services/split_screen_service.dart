import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Service for detecting and logging split screen usage.
///
/// Uses WidgetsBindingObserver to detect when the app enters or exits
/// split screen mode by monitoring window size changes.
///
/// Tracks:
/// - When user enters split screen (timestamp, screen dimensions)
/// - When user exits split screen (duration spent)
/// - Which features were used in split screen mode
class SplitScreenService with WidgetsBindingObserver {
  final ApiClient _apiClient;

  // Split screen state tracking
  bool _isInSplitScreen = false;
  DateTime? _splitScreenEnteredAt;
  Size? _fullScreenSize;
  Size? _splitScreenSize; // Used for tracking current split dimensions
  String? _currentScreen;
  final List<String> _screensViewedDuringSplit = [];
  final List<String> _featuresUsedDuringSplit = [];
  bool _workoutActiveDuringSplit = false;

  // Threshold for detecting split screen (app width < 70% of screen)
  static const double _splitScreenThreshold = 0.70;

  SplitScreenService(this._apiClient) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Clean up observer when service is disposed
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Whether the app is currently in split screen mode
  bool get isInSplitScreen => _isInSplitScreen;

  /// Duration spent in split screen mode (if currently in split screen)
  Duration? get currentSplitScreenDuration {
    if (_splitScreenEnteredAt == null) return null;
    return DateTime.now().difference(_splitScreenEnteredAt!);
  }

  /// Set the current screen name for tracking
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
    if (_isInSplitScreen && !_screensViewedDuringSplit.contains(screenName)) {
      _screensViewedDuringSplit.add(screenName);
    }
  }

  /// Log a feature being used (for tracking during split screen)
  void logFeatureUsed(String featureName) {
    if (_isInSplitScreen && !_featuresUsedDuringSplit.contains(featureName)) {
      _featuresUsedDuringSplit.add(featureName);
    }
  }

  /// Set whether a workout is active (for correlation tracking)
  void setWorkoutActive(bool isActive) {
    if (_isInSplitScreen && isActive) {
      _workoutActiveDuringSplit = true;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _checkSplitScreenState();
  }

  /// Check and update split screen state based on current window metrics
  void _checkSplitScreenState() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenSize = view.physicalSize / view.devicePixelRatio;
    final windowSize = view.physicalSize / view.devicePixelRatio;

    // On first check, store the full screen size
    _fullScreenSize ??= screenSize;

    // Detect split screen by checking if app window is significantly smaller than screen
    // This works for both horizontal and vertical split
    final widthRatio = windowSize.width / (_fullScreenSize?.width ?? screenSize.width);
    final heightRatio = windowSize.height / (_fullScreenSize?.height ?? screenSize.height);

    // Consider it split screen if either dimension is reduced significantly
    final isSplitScreen = widthRatio < _splitScreenThreshold || heightRatio < _splitScreenThreshold;

    if (isSplitScreen && !_isInSplitScreen) {
      // Entered split screen
      _onSplitScreenEntered(windowSize, screenSize);
    } else if (!isSplitScreen && _isInSplitScreen) {
      // Exited split screen
      _onSplitScreenExited();
    } else if (isSplitScreen) {
      // Still in split screen, update size
      _splitScreenSize = windowSize;
    }
  }

  /// Called when app enters split screen mode
  void _onSplitScreenEntered(Size windowSize, Size screenSize) {
    _isInSplitScreen = true;
    _splitScreenEnteredAt = DateTime.now();
    _splitScreenSize = windowSize;
    _screensViewedDuringSplit.clear();
    _featuresUsedDuringSplit.clear();
    _workoutActiveDuringSplit = false;

    if (_currentScreen != null) {
      _screensViewedDuringSplit.add(_currentScreen!);
    }

    debugPrint(
      '[SplitScreen] Entered split screen mode: '
      'window=${windowSize.width.toInt()}x${windowSize.height.toInt()}, '
      'screen=${screenSize.width.toInt()}x${screenSize.height.toInt()}',
    );

    _logSplitScreenEntered(windowSize, screenSize);
  }

  /// Called when app exits split screen mode
  void _onSplitScreenExited() {
    final duration = _splitScreenEnteredAt != null
        ? DateTime.now().difference(_splitScreenEnteredAt!).inSeconds
        : 0;

    debugPrint(
      '[SplitScreen] Exited split screen mode: '
      'duration=${duration}s, '
      'screens=${_screensViewedDuringSplit.length}, '
      'features=${_featuresUsedDuringSplit.length}',
    );

    _logSplitScreenExited(duration);

    _isInSplitScreen = false;
    _splitScreenEnteredAt = null;
    _splitScreenSize = null;
    _screensViewedDuringSplit.clear();
    _featuresUsedDuringSplit.clear();
    _workoutActiveDuringSplit = false;
  }

  /// Log split screen entered event to backend
  Future<void> _logSplitScreenEntered(Size windowSize, Size screenSize) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/analytics/context-log',
        data: {
          'user_id': userId,
          'event_type': 'split_screen_entered',
          'event_data': {
            'device_type': _getDeviceType(),
            'screen_width': screenSize.width.toInt(),
            'screen_height': screenSize.height.toInt(),
            'app_width': windowSize.width.toInt(),
            'app_height': windowSize.height.toInt(),
            'current_screen': _currentScreen,
            'partner_app': null, // Cannot detect partner app from Flutter
            'entered_at': DateTime.now().toIso8601String(),
          },
          'context': {
            'platform': defaultTargetPlatform.name,
            'timestamp': DateTime.now().toIso8601String(),
            'is_split_screen': true,
          },
        },
      );
      debugPrint('[SplitScreen] Logged split screen entered event');
    } catch (e) {
      debugPrint('[SplitScreen] Failed to log split screen entered: $e');
    }
  }

  /// Log split screen exited event to backend
  Future<void> _logSplitScreenExited(int durationSeconds) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/analytics/context-log',
        data: {
          'user_id': userId,
          'event_type': 'split_screen_exited',
          'event_data': {
            'duration_seconds': durationSeconds,
            'duration_minutes': (durationSeconds / 60).toStringAsFixed(1),
            'device_type': _getDeviceType(),
            'screens_viewed': _screensViewedDuringSplit.toList(),
            'screens_count': _screensViewedDuringSplit.length,
            'features_used': _featuresUsedDuringSplit.toList(),
            'features_count': _featuresUsedDuringSplit.length,
            'workout_active_during_split': _workoutActiveDuringSplit,
            'partner_app': null, // Cannot detect partner app from Flutter
            'exit_reason': 'window_restored',
            'exited_at': DateTime.now().toIso8601String(),
          },
          'context': {
            'platform': defaultTargetPlatform.name,
            'timestamp': DateTime.now().toIso8601String(),
            'is_split_screen_exit': true,
          },
        },
      );
      debugPrint('[SplitScreen] Logged split screen exited event');
    } catch (e) {
      debugPrint('[SplitScreen] Failed to log split screen exited: $e');
    }
  }

  /// Determine device type based on screen size and platform
  String _getDeviceType() {
    if (_fullScreenSize == null) return 'unknown';

    final shortestSide = _fullScreenSize!.shortestSide;

    if (Platform.isAndroid || Platform.isIOS) {
      // Tablet: shortest side > 600 logical pixels
      // Foldable: aspect ratio check could help, but we use tablet for now
      if (shortestSide > 600) {
        return 'tablet';
      }
      return 'phone';
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'desktop';
    }

    return 'unknown';
  }

  /// Force check the current split screen state
  /// Call this when the app resumes or starts
  void checkCurrentState() {
    _checkSplitScreenState();
  }
}

// ============================================
// Provider
// ============================================

/// Split screen service provider (singleton)
final splitScreenServiceProvider = Provider<SplitScreenService>((ref) {
  final service = SplitScreenService(ref.watch(apiClientProvider));

  // Clean up when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream of split screen state changes
final splitScreenStateProvider = StateProvider<bool>((ref) {
  return ref.watch(splitScreenServiceProvider).isInSplitScreen;
});
