import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for communicating with Wear OS watch.
/// Handles bidirectional sync for workouts, nutrition, fasting, and health data.
class WearableService {
  static const _methodChannel = MethodChannel('com.aifitnesscoach.app/wearable');
  static const _eventChannel = EventChannel('com.aifitnesscoach.app/wearable_events');

  static WearableService? _instance;
  static WearableService get instance => _instance ??= WearableService._();

  WearableService._();

  StreamSubscription? _eventSubscription;
  final _eventController = StreamController<WearableEvent>.broadcast();

  /// Stream of events from the watch
  Stream<WearableEvent> get events => _eventController.stream;

  /// Initialize the wearable service and start listening for events
  void initialize() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .map((event) => _parseEvent(event as Map))
        .listen(
          (event) => _eventController.add(event),
          onError: (error) => debugPrint('❌ Wearable event error: $error'),
        );
    debugPrint('✅ WearableService initialized');
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
  }

  WearableEvent _parseEvent(Map event) {
    final type = event['type'] as String;
    final data = event['data'] as String;
    return WearableEvent(type: type, data: jsonDecode(data));
  }

  // ==================== Connection Status ====================

  /// Check if watch is connected
  Future<bool> isWatchConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWatchConnected');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking watch connection: $e');
      return false;
    }
  }

  /// Check if any WearOS device is connected (even without FitWiz app).
  /// Use this to determine whether to show "Install on Watch" prompt.
  Future<bool> hasConnectedWearDevice() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('hasConnectedWearDevice');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking for Wear device: $e');
      return false;
    }
  }

  /// Check if FitWiz watch app is installed on the connected watch.
  /// Returns false if no watch connected or FitWiz not installed.
  Future<bool> isWatchAppInstalled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWatchAppInstalled');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking watch app installation: $e');
      return false;
    }
  }

  /// Prompt the user to install FitWiz watch app from Play Store on their watch.
  /// Opens Play Store directly on the connected watch.
  /// Returns true if prompt was sent successfully, false otherwise.
  Future<bool> promptWatchAppInstall() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('promptWatchAppInstall');
      if (result == true) {
        debugPrint('✅ Prompted watch app installation');
      }
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error prompting watch app install: $e');
      return false;
    }
  }

  /// Get watch connection status with details.
  /// Returns a map with 'hasDevice', 'hasApp', and 'isConnected'.
  Future<WatchConnectionStatus> getWatchConnectionStatus() async {
    try {
      final hasDevice = await hasConnectedWearDevice();
      if (!hasDevice) {
        return WatchConnectionStatus.noDevice();
      }

      final hasApp = await isWatchAppInstalled();
      if (!hasApp) {
        return WatchConnectionStatus.noApp();
      }

      return WatchConnectionStatus.connected();
    } catch (e) {
      debugPrint('❌ Error getting watch connection status: $e');
      return WatchConnectionStatus.error(e.toString());
    }
  }

  // ==================== Send Data to Watch ====================

  /// Send today's workout to watch
  Future<bool> sendWorkoutToWatch(Map<String, dynamic> workout) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendWorkoutToWatch',
        {'workout': jsonEncode(workout)},
      );
      debugPrint('✅ Workout sent to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error sending workout to watch: $e');
      return false;
    }
  }

  /// Send nutrition summary to watch
  Future<bool> sendNutritionSummaryToWatch(Map<String, dynamic> summary) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendNutritionSummaryToWatch',
        {'summary': jsonEncode(summary)},
      );
      debugPrint('✅ Nutrition summary sent to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error sending nutrition summary to watch: $e');
      return false;
    }
  }

  /// Send health goals to watch
  Future<bool> sendHealthGoalsToWatch(Map<String, dynamic> goals) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendHealthGoalsToWatch',
        {'goals': jsonEncode(goals)},
      );
      debugPrint('✅ Health goals sent to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error sending health goals to watch: $e');
      return false;
    }
  }

  /// Send health data from phone's Health Connect to watch
  Future<bool> sendHealthDataToWatch(Map<String, dynamic> healthData) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendHealthDataToWatch',
        {'health': jsonEncode(healthData)},
      );
      debugPrint('✅ Health data sent to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error sending health data to watch: $e');
      return false;
    }
  }

  /// Send user profile to watch
  Future<bool> sendUserProfileToWatch(Map<String, dynamic> profile) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendUserProfileToWatch',
        {'profile': jsonEncode(profile)},
      );
      debugPrint('✅ User profile sent to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error sending user profile to watch: $e');
      return false;
    }
  }

  // ==================== Notifications ====================

  /// Notify watch that sync is complete
  Future<bool> notifySyncComplete() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('notifySyncComplete');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error notifying sync complete: $e');
      return false;
    }
  }

  /// Notify watch that workout was updated
  Future<bool> notifyWorkoutUpdated() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('notifyWorkoutUpdated');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error notifying workout updated: $e');
      return false;
    }
  }

  // ==================== Authentication Sync ====================

  /// Sync user credentials to watch for authenticated API calls.
  /// This should be called after successful login.
  Future<bool> syncUserCredentials({
    required String userId,
    required String authToken,
    String? refreshToken,
    int? expiryMs,
  }) async {
    try {
      // Check if watch is connected first
      final connected = await isWatchConnected();
      if (!connected) {
        debugPrint('⚠️ Watch not connected, skipping credential sync');
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>(
        'sendUserCredentialsToWatch',
        {
          'userId': userId,
          'authToken': authToken,
          if (refreshToken != null) 'refreshToken': refreshToken,
          if (expiryMs != null) 'expiryMs': expiryMs,
        },
      );
      debugPrint('✅ User credentials synced to watch');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error syncing credentials to watch: $e');
      return false;
    }
  }

  // ==================== Convenience Methods ====================

  /// Create workout data for watch from workout model
  Map<String, dynamic> createWorkoutForWatch({
    required String id,
    required String name,
    required String type,
    required List<Map<String, dynamic>> exercises,
    required int estimatedDuration,
    required List<String> targetMuscleGroups,
    required String scheduledDate,
  }) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'exercises': exercises,
      'estimatedDuration': estimatedDuration,
      'targetMuscleGroups': targetMuscleGroups,
      'scheduledDate': scheduledDate,
    };
  }

  /// Create nutrition summary for watch
  Map<String, dynamic> createNutritionSummaryForWatch({
    required String date,
    required int totalCalories,
    required int calorieGoal,
    required double proteinG,
    required double proteinGoalG,
    required double carbsG,
    required double carbsGoalG,
    required double fatG,
    required double fatGoalG,
    required int waterMl,
    required int waterGoalMl,
  }) {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'calorieGoal': calorieGoal,
      'proteinG': proteinG,
      'proteinGoalG': proteinGoalG,
      'carbsG': carbsG,
      'carbsGoalG': carbsGoalG,
      'fatG': fatG,
      'fatGoalG': fatGoalG,
      'waterMl': waterMl,
      'waterGoalMl': waterGoalMl,
    };
  }

  /// Create health goals for watch
  Map<String, dynamic> createHealthGoalsForWatch({
    required int stepsGoal,
    required int activeMinutesGoal,
    required int caloriesBurnedGoal,
    required double sleepHoursGoal,
    required int waterMlGoal,
  }) {
    return {
      'stepsGoal': stepsGoal,
      'activeMinutesGoal': activeMinutesGoal,
      'caloriesBurnedGoal': caloriesBurnedGoal,
      'sleepHoursGoal': sleepHoursGoal,
      'waterMlGoal': waterMlGoal,
    };
  }
}

/// Event received from watch
class WearableEvent {
  final String type;
  final Map<String, dynamic> data;

  WearableEvent({required this.type, required this.data});

  @override
  String toString() => 'WearableEvent(type: $type, data: $data)';
}

// ==================== Event Types ====================

class WearableEventTypes {
  static const workoutSetLogged = 'workout_set_logged';
  static const workoutCompleted = 'workout_completed';
  static const foodLogged = 'food_logged';
  static const fastingEvent = 'fasting_event';
  static const healthDataReceived = 'health_data_received';
  static const workoutStartedOnWatch = 'workout_started_on_watch';
  static const workoutEndedOnWatch = 'workout_ended_on_watch';
  static const fastingStartedOnWatch = 'fasting_started_on_watch';
  static const fastingEndedOnWatch = 'fasting_ended_on_watch';

  /// Live heart rate updates during workout (streamed every 5 seconds from watch)
  static const liveHeartRate = 'live_heart_rate';
}

// ==================== Watch Connection Status ====================

/// Represents the connection status between phone and watch.
enum WatchConnectionState {
  /// No WearOS device paired/connected
  noDevice,

  /// WearOS device connected but FitWiz app not installed
  noApp,

  /// FitWiz watch app installed and connected
  connected,

  /// Error checking connection status
  error,
}

/// Detailed watch connection status.
class WatchConnectionStatus {
  final WatchConnectionState state;
  final bool hasDevice;
  final bool hasApp;
  final String? errorMessage;

  WatchConnectionStatus._({
    required this.state,
    required this.hasDevice,
    required this.hasApp,
    this.errorMessage,
  });

  /// No WearOS device connected
  factory WatchConnectionStatus.noDevice() => WatchConnectionStatus._(
        state: WatchConnectionState.noDevice,
        hasDevice: false,
        hasApp: false,
      );

  /// WearOS device connected but FitWiz not installed
  factory WatchConnectionStatus.noApp() => WatchConnectionStatus._(
        state: WatchConnectionState.noApp,
        hasDevice: true,
        hasApp: false,
      );

  /// Fully connected with FitWiz app
  factory WatchConnectionStatus.connected() => WatchConnectionStatus._(
        state: WatchConnectionState.connected,
        hasDevice: true,
        hasApp: true,
      );

  /// Error state
  factory WatchConnectionStatus.error(String message) => WatchConnectionStatus._(
        state: WatchConnectionState.error,
        hasDevice: false,
        hasApp: false,
        errorMessage: message,
      );

  /// Whether the watch is fully connected (device + app)
  bool get isConnected => state == WatchConnectionState.connected;

  /// Whether we should show install prompt (device exists but no app)
  bool get shouldShowInstallPrompt => state == WatchConnectionState.noApp;

  @override
  String toString() => 'WatchConnectionStatus(state: $state, hasDevice: $hasDevice, hasApp: $hasApp)';
}
