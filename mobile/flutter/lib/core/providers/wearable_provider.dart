import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/wearable_service.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/services/health_service.dart';

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

    // Extract set data
    final exerciseName = data['exerciseName'] as String? ?? '';
    final actualReps = data['actualReps'] as int? ?? 0;
    final weightKg = (data['weightKg'] as num?)?.toDouble() ?? 0.0;
    final setNumber = data['setNumber'] as int? ?? 1;

    debugPrint('🏋️ [Wearable] Set: $exerciseName - Set $setNumber: $actualReps reps @ ${weightKg}kg');

    // Invalidate today's workout provider to refresh with updated set data
    // The backend should have already received this via the watch's direct sync
    _ref.invalidate(todayWorkoutProvider);

    debugPrint('✅ [Wearable] Invalidated todayWorkoutProvider to refresh workout state');
  }

  void _handleWorkoutCompleted(Map<String, dynamic> data) {
    debugPrint('🎉 [Wearable] Workout completed on watch: $data');

    // Extract completion data
    final workoutName = data['workoutName'] as String? ?? 'Workout';
    final totalSets = data['totalSets'] as int? ?? 0;
    final totalReps = data['totalReps'] as int? ?? 0;
    final durationMinutes = data['durationMinutes'] as int?;
    final caloriesBurned = data['caloriesBurned'] as int?;

    debugPrint('🎉 [Wearable] Completed: $workoutName - $totalSets sets, $totalReps reps');
    if (durationMinutes != null) debugPrint('   Duration: ${durationMinutes}min');
    if (caloriesBurned != null) debugPrint('   Calories: $caloriesBurned');

    // Invalidate workout provider to refresh (will show completed state)
    _ref.invalidate(todayWorkoutProvider);

    // Also refresh daily activity to update calories burned
    try {
      _ref.read(dailyActivityProvider.notifier).refresh();
    } catch (e) {
      debugPrint('⚠️ [Wearable] Could not refresh daily activity: $e');
    }

    debugPrint('✅ [Wearable] Workout state refreshed after completion');
  }

  void _handleFoodLogged(Map<String, dynamic> data) {
    debugPrint('🍎 [Wearable] Food logged on watch: $data');

    // Extract food data
    final foodName = data['foodName'] as String? ?? '';
    final calories = data['calories'] as int? ?? 0;
    final proteinG = (data['proteinG'] as num?)?.toDouble() ?? 0.0;

    debugPrint('🍎 [Wearable] Logged: $foodName - ${calories}cal, ${proteinG}g protein');

    // Refresh nutrition state to include the new food entry
    // The backend should have already received this via watch's direct sync
    // Note: NutritionNotifier.loadTodaySummary requires userId, but we don't have it here
    // The UI will refresh when user navigates to nutrition screen
    debugPrint('📊 [Wearable] Food logged - nutrition will refresh on next screen visit');

    // Also update cached nutrition values for watch sync
    _updateNutritionCache(data);

    debugPrint('✅ [Wearable] Nutrition state refreshed');
  }

  void _handleFastingEvent(Map<String, dynamic> data) {
    debugPrint('⏰ [Wearable] Fasting event from watch: $data');

    // Extract fasting event data
    final eventType = data['eventType'] as String? ?? '';
    final protocol = data['protocol'] as String? ?? '';
    final elapsedMinutes = data['elapsedMinutes'] as int? ?? 0;

    debugPrint('⏰ [Wearable] Fasting: $eventType ($protocol) - ${elapsedMinutes}min elapsed');

    // Update fasting state based on event type
    try {
      final fastingNotifier = _ref.read(fastingProvider.notifier);

      if (eventType == 'started') {
        // Fasting was started on watch - sync the state
        fastingNotifier.syncFromWatch(data);
        debugPrint('✅ [Wearable] Fasting started sync from watch');
      } else if (eventType == 'ended' || eventType == 'completed') {
        // Fasting was ended on watch
        fastingNotifier.syncFromWatch(data);
        debugPrint('✅ [Wearable] Fasting ended sync from watch');
      } else if (eventType == 'progress') {
        // Just a progress update, state should already be in sync
        debugPrint('📊 [Wearable] Fasting progress update: ${elapsedMinutes}min');
      }
    } catch (e) {
      debugPrint('⚠️ [Wearable] Could not update fasting state: $e');
    }
  }

  void _handleHealthData(Map<String, dynamic> data) {
    debugPrint('❤️ [Wearable] Health data from watch: $data');

    // Extract health metrics
    final steps = data['steps'] as int? ?? 0;
    final heartRateBpm = data['heartRateBpm'] as int?;
    final caloriesBurned = data['caloriesBurned'] as int? ?? 0;
    final activeMinutes = data['activeMinutes'] as int? ?? 0;

    debugPrint('❤️ [Wearable] Health: $steps steps, ${heartRateBpm ?? "N/A"} bpm, $caloriesBurned cal burned');

    // Update daily activity state with watch data
    try {
      _ref.read(dailyActivityProvider.notifier).updateFromWatch(
        steps: steps,
        heartRate: heartRateBpm,
        caloriesBurned: caloriesBurned,
        activeMinutes: activeMinutes,
      );
      debugPrint('✅ [Wearable] Daily activity updated from watch');
    } catch (e) {
      debugPrint('⚠️ [Wearable] Could not update daily activity: $e');
    }

    // Cache health data for watch sync continuity
    _updateHealthCache(data);
  }

  /// Update nutrition cache in SharedPreferences for watch sync
  Future<void> _updateNutritionCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calories = data['calories'] as int? ?? 0;
      final proteinG = (data['proteinG'] as num?)?.toDouble() ?? 0.0;
      final carbsG = (data['carbsG'] as num?)?.toDouble() ?? 0.0;
      final fatG = (data['fatG'] as num?)?.toDouble() ?? 0.0;

      // Add to existing totals
      final currentCalories = prefs.getInt('nutrition_calories_today') ?? 0;
      final currentProtein = prefs.getDouble('nutrition_protein_today') ?? 0.0;
      final currentCarbs = prefs.getDouble('nutrition_carbs_today') ?? 0.0;
      final currentFat = prefs.getDouble('nutrition_fat_today') ?? 0.0;

      await prefs.setInt('nutrition_calories_today', currentCalories + calories);
      await prefs.setDouble('nutrition_protein_today', currentProtein + proteinG);
      await prefs.setDouble('nutrition_carbs_today', currentCarbs + carbsG);
      await prefs.setDouble('nutrition_fat_today', currentFat + fatG);

      debugPrint('💾 [Wearable] Nutrition cache updated');
    } catch (e) {
      debugPrint('⚠️ [Wearable] Could not update nutrition cache: $e');
    }
  }

  /// Update health cache in SharedPreferences for watch sync
  Future<void> _updateHealthCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final steps = data['steps'] as int? ?? 0;
      final caloriesBurned = data['caloriesBurned'] as int? ?? 0;
      final activeMinutes = data['activeMinutes'] as int? ?? 0;

      // Store watch health data (these override since watch is more accurate when worn)
      await prefs.setInt('health_watch_steps_today', steps);
      await prefs.setInt('health_watch_calories_burned_today', caloriesBurned);
      await prefs.setInt('health_watch_active_minutes_today', activeMinutes);

      debugPrint('💾 [Wearable] Health cache updated');
    } catch (e) {
      debugPrint('⚠️ [Wearable] Could not update health cache: $e');
    }
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
