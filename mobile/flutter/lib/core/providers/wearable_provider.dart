import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/wearable_service.dart';

/// Provider for wearable (WearOS) sync functionality.
/// Handles bidirectional sync between phone and watch.

/// Watch connection status
final watchConnectedProvider = StateProvider<bool>((ref) => false);

/// Last sync timestamp
final lastWatchSyncProvider = StateProvider<DateTime?>((ref) => null);

/// Wearable event stream provider
final wearableEventsProvider = StreamProvider<WearableEvent>((ref) {
  if (!Platform.isAndroid) {
    // WearOS only works on Android
    return const Stream.empty();
  }

  // Initialize the service if not already done
  WearableService.instance.initialize();

  return WearableService.instance.events;
});

/// Wearable sync notifier for managing watch communication
class WearableSyncNotifier extends ChangeNotifier {
  bool _isConnected = false;
  DateTime? _lastSync;
  bool _isSyncing = false;

  bool get isConnected => _isConnected;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;

  WearableSyncNotifier() {
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (!Platform.isAndroid) return;

    try {
      _isConnected = await WearableService.instance.isWatchConnected();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [Wearable] Error checking connection: $e');
    }
  }

  /// Refresh connection status
  Future<void> refreshConnection() async {
    await _checkConnection();
  }

  /// Send today's workout to watch
  Future<bool> syncWorkoutToWatch(Map<String, dynamic> workout) async {
    if (!Platform.isAndroid || !_isConnected) return false;

    try {
      _isSyncing = true;
      notifyListeners();

      final success = await WearableService.instance.sendWorkoutToWatch(workout);

      if (success) {
        _lastSync = DateTime.now();
        debugPrint('✅ [Wearable] Workout synced to watch');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [Wearable] Error syncing workout: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Send nutrition summary to watch
  Future<bool> syncNutritionToWatch(Map<String, dynamic> summary) async {
    if (!Platform.isAndroid || !_isConnected) return false;

    try {
      final success =
          await WearableService.instance.sendNutritionSummaryToWatch(summary);

      if (success) {
        _lastSync = DateTime.now();
        debugPrint('✅ [Wearable] Nutrition synced to watch');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [Wearable] Error syncing nutrition: $e');
      return false;
    }
  }

  /// Send health goals to watch
  Future<bool> syncHealthGoalsToWatch(Map<String, dynamic> goals) async {
    if (!Platform.isAndroid || !_isConnected) return false;

    try {
      final success = await WearableService.instance.sendHealthGoalsToWatch(goals);

      if (success) {
        debugPrint('✅ [Wearable] Health goals synced to watch');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [Wearable] Error syncing health goals: $e');
      return false;
    }
  }
}

/// Provider for wearable sync notifier
final wearableSyncProvider =
    ChangeNotifierProvider<WearableSyncNotifier>((ref) {
  return WearableSyncNotifier();
});

/// Handles incoming events from watch and updates app state
class WearableEventHandler {
  final Ref _ref;
  StreamSubscription<WearableEvent>? _subscription;

  WearableEventHandler(this._ref);

  /// Start listening for watch events
  void startListening() {
    if (!Platform.isAndroid) return;

    _subscription?.cancel();
    _subscription = WearableService.instance.events.listen(
      _handleEvent,
      onError: (e) => debugPrint('❌ [Wearable] Event error: $e'),
    );

    debugPrint('✅ [Wearable] Started listening for watch events');
  }

  /// Stop listening for watch events
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleEvent(WearableEvent event) {
    debugPrint('📱 [Wearable] Received event: ${event.type}');

    switch (event.type) {
      case WearableEventTypes.workoutSetLogged:
        _handleWorkoutSetLogged(event.data);
        break;
      case WearableEventTypes.workoutCompleted:
        _handleWorkoutCompleted(event.data);
        break;
      case WearableEventTypes.foodLogged:
        _handleFoodLogged(event.data);
        break;
      case WearableEventTypes.fastingEvent:
        _handleFastingEvent(event.data);
        break;
      case WearableEventTypes.healthDataReceived:
        _handleHealthData(event.data);
        break;
      default:
        debugPrint('⚠️ [Wearable] Unknown event type: ${event.type}');
    }
  }

  void _handleWorkoutSetLogged(Map<String, dynamic> data) {
    debugPrint('🏋️ [Wearable] Set logged on watch: $data');
    // TODO: Update local workout state with the logged set
    // This would invalidate/refresh the workout provider
  }

  void _handleWorkoutCompleted(Map<String, dynamic> data) {
    debugPrint('🎉 [Wearable] Workout completed on watch: $data');
    // TODO: Update local state to reflect completed workout
    // This would trigger a refresh of the workout list
  }

  void _handleFoodLogged(Map<String, dynamic> data) {
    debugPrint('🍎 [Wearable] Food logged on watch: $data');
    // TODO: Refresh nutrition state to include the new food entry
  }

  void _handleFastingEvent(Map<String, dynamic> data) {
    debugPrint('⏰ [Wearable] Fasting event from watch: $data');
    // TODO: Update fasting state
  }

  void _handleHealthData(Map<String, dynamic> data) {
    debugPrint('❤️ [Wearable] Health data from watch: $data');
    // TODO: Process health data (steps, heart rate, etc.)
  }
}

/// Provider for wearable event handler
final wearableEventHandlerProvider = Provider<WearableEventHandler>((ref) {
  final handler = WearableEventHandler(ref);

  // Auto-start listening when on Android
  if (Platform.isAndroid) {
    handler.startListening();
  }

  ref.onDispose(() {
    handler.stopListening();
  });

  return handler;
});
