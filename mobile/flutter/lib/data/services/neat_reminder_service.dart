import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_service.dart';
import 'notification_service.dart';

/// NEAT (Non-Exercise Activity Thermogenesis) Reminder Service
///
/// Monitors hourly step count and triggers movement reminders
/// when the user is sedentary (below step threshold).
///
/// Features:
/// - Hourly step count monitoring
/// - Configurable step threshold (default: 250 steps/hour)
/// - Respects quiet hours and work hours settings
/// - Integrates with Health Connect / HealthKit for step data

/// State for the NEAT reminder service
class NeatReminderState {
  final bool isMonitoring;
  final int currentHourSteps;
  final int stepThreshold;
  final DateTime? lastCheckTime;
  final DateTime? lastReminderTime;
  final int remindersToday;
  final String? error;

  const NeatReminderState({
    this.isMonitoring = false,
    this.currentHourSteps = 0,
    this.stepThreshold = 250,
    this.lastCheckTime,
    this.lastReminderTime,
    this.remindersToday = 0,
    this.error,
  });

  NeatReminderState copyWith({
    bool? isMonitoring,
    int? currentHourSteps,
    int? stepThreshold,
    DateTime? lastCheckTime,
    DateTime? lastReminderTime,
    int? remindersToday,
    String? error,
  }) {
    return NeatReminderState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      currentHourSteps: currentHourSteps ?? this.currentHourSteps,
      stepThreshold: stepThreshold ?? this.stepThreshold,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      lastReminderTime: lastReminderTime ?? this.lastReminderTime,
      remindersToday: remindersToday ?? this.remindersToday,
      error: error,
    );
  }

  /// Whether the user is currently sedentary (below step threshold)
  bool get isSedentary => currentHourSteps < stepThreshold;

  /// Progress towards hourly step goal (0.0 to 1.0)
  double get progress => stepThreshold > 0
      ? (currentHourSteps / stepThreshold).clamp(0.0, 1.0)
      : 0.0;
}

/// NEAT Reminder Service Notifier
class NeatReminderNotifier extends StateNotifier<NeatReminderState> {
  final HealthService _healthService;
  final NotificationService _notificationService;
  final NotificationPreferences _notificationPrefs;
  final HealthSyncState _healthSyncState;

  Timer? _monitoringTimer;

  /// Preference keys for NEAT service
  static const String _lastReminderTimeKey = 'neat_last_reminder_time';
  static const String _remindersTodayKey = 'neat_reminders_today';
  static const String _lastReminderDateKey = 'neat_last_reminder_date';

  NeatReminderNotifier({
    required HealthService healthService,
    required NotificationService notificationService,
    required NotificationPreferences notificationPrefs,
    required HealthSyncState healthSyncState,
  })  : _healthService = healthService,
        _notificationService = notificationService,
        _notificationPrefs = notificationPrefs,
        _healthSyncState = healthSyncState,
        super(NeatReminderState(
          stepThreshold: notificationPrefs.movementStepThreshold,
        )) {
    _loadPersistedState();
  }

  /// Load persisted state from SharedPreferences
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastReminderMs = prefs.getInt(_lastReminderTimeKey);
      final remindersToday = prefs.getInt(_remindersTodayKey) ?? 0;
      final lastReminderDate = prefs.getString(_lastReminderDateKey);

      // Reset daily counter if it's a new day
      final today = DateTime.now().toIso8601String().split('T')[0];
      final actualRemindersToday = lastReminderDate == today ? remindersToday : 0;

      state = state.copyWith(
        lastReminderTime: lastReminderMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastReminderMs)
            : null,
        remindersToday: actualRemindersToday,
        stepThreshold: _notificationPrefs.movementStepThreshold,
      );

      debugPrint('🚶 [NEAT] State loaded: $actualRemindersToday reminders today');
    } catch (e) {
      debugPrint('❌ [NEAT] Error loading persisted state: $e');
    }
  }

  /// Save state to SharedPreferences
  Future<void> _savePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.lastReminderTime != null) {
        await prefs.setInt(_lastReminderTimeKey,
            state.lastReminderTime!.millisecondsSinceEpoch);
      }
      await prefs.setInt(_remindersTodayKey, state.remindersToday);
      await prefs.setString(_lastReminderDateKey,
          DateTime.now().toIso8601String().split('T')[0]);
    } catch (e) {
      debugPrint('❌ [NEAT] Error saving persisted state: $e');
    }
  }

  /// Start monitoring for sedentary behavior
  /// Checks step count periodically and triggers reminders when needed
  Future<void> startMonitoring() async {
    if (state.isMonitoring) {
      debugPrint('🚶 [NEAT] Already monitoring');
      return;
    }

    if (!_notificationPrefs.movementReminders) {
      debugPrint('🚶 [NEAT] Movement reminders disabled, not starting monitoring');
      return;
    }

    if (!_healthSyncState.isConnected) {
      debugPrint('⚠️ [NEAT] Health Connect not connected, cannot monitor steps');
      state = state.copyWith(
        error: 'Health Connect not connected',
        isMonitoring: false,
      );
      return;
    }

    state = state.copyWith(isMonitoring: true, error: null);
    debugPrint('🚶 [NEAT] Started step monitoring');

    // Initial check
    await checkCurrentHourActivity();

    // Set up periodic monitoring (every 15 minutes)
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => checkCurrentHourActivity(),
    );
  }

  /// Stop monitoring for sedentary behavior
  Future<void> stopMonitoring() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    state = state.copyWith(isMonitoring: false);
    debugPrint('🚶 [NEAT] Stopped step monitoring');
  }

  /// Check the current hour's step activity and trigger reminder if needed
  Future<void> checkCurrentHourActivity() async {
    if (!_notificationPrefs.movementReminders) {
      debugPrint('🚶 [NEAT] Movement reminders disabled, skipping check');
      return;
    }

    // Check if within allowed hours
    if (!isWithinAllowedHours()) {
      debugPrint('🚶 [NEAT] Outside allowed hours, skipping check');
      return;
    }

    // Check if in quiet hours
    if (_notificationService.isWithinQuietHours(_notificationPrefs)) {
      debugPrint('🚶 [NEAT] In quiet hours, skipping check');
      return;
    }

    try {
      // Get steps for the current hour
      final stepsThisHour = await _getStepsForCurrentHour();

      state = state.copyWith(
        currentHourSteps: stepsThisHour,
        lastCheckTime: DateTime.now(),
        stepThreshold: _notificationPrefs.movementStepThreshold,
      );

      debugPrint('🚶 [NEAT] Current hour steps: $stepsThisHour / ${_notificationPrefs.movementStepThreshold}');

      // Check if sedentary and should show reminder
      if (stepsThisHour < _notificationPrefs.movementStepThreshold) {
        await _triggerMovementReminderIfNeeded(stepsThisHour);
      }
    } catch (e) {
      debugPrint('❌ [NEAT] Error checking activity: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get step count for the current hour
  Future<int> _getStepsForCurrentHour() async {
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);

    try {
      // Get total steps for today
      final totalSteps = await _healthService.getTodaySteps();

      // For now, we use a simple heuristic - divide by hours elapsed
      // A more accurate implementation would query Health API for the specific hour
      final hoursElapsed = now.hour + 1; // +1 because we count the current hour
      final avgStepsPerHour = totalSteps ~/ hoursElapsed;

      // For more accurate per-hour tracking, we could use:
      // await _healthService.getStepsInRange(hourStart, now);
      // But since that's not available, we use the average as an estimate

      return avgStepsPerHour;
    } catch (e) {
      debugPrint('❌ [NEAT] Error getting steps for current hour: $e');
      return 0;
    }
  }

  /// Check if current time is within allowed reminder hours
  bool isWithinAllowedHours() {
    return _notificationService.isWithinMovementReminderHours(_notificationPrefs);
  }

  /// Trigger a movement reminder if appropriate
  Future<void> _triggerMovementReminderIfNeeded(int currentSteps) async {
    final now = DateTime.now();

    // Don't send more than 8 reminders per day
    if (state.remindersToday >= 8) {
      debugPrint('🚶 [NEAT] Max daily reminders reached, skipping');
      return;
    }

    // Don't send reminder if we just sent one in the last 45 minutes
    if (state.lastReminderTime != null) {
      final minutesSinceLastReminder =
          now.difference(state.lastReminderTime!).inMinutes;
      if (minutesSinceLastReminder < 45) {
        debugPrint('🚶 [NEAT] Too soon since last reminder ($minutesSinceLastReminder min), skipping');
        return;
      }
    }

    // Show the movement reminder
    await _notificationService.showMovementReminder(
      stepsSoFar: currentSteps,
      goal: _notificationPrefs.movementStepThreshold,
    );

    state = state.copyWith(
      lastReminderTime: now,
      remindersToday: state.remindersToday + 1,
    );

    await _savePersistedState();

    debugPrint('🚶 [NEAT] Movement reminder sent (#${state.remindersToday} today)');
  }

  /// Manually refresh the step count
  Future<void> refreshStepCount() async {
    await checkCurrentHourActivity();
  }

  /// Update step threshold
  void updateStepThreshold(int threshold) {
    state = state.copyWith(stepThreshold: threshold);
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

/// Provider for NEAT reminder service
final neatReminderProvider = StateNotifierProvider<NeatReminderNotifier, NeatReminderState>((ref) {
  final healthService = ref.watch(healthServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final notificationPrefs = ref.watch(notificationPreferencesProvider);
  final healthSyncState = ref.watch(healthSyncProvider);

  return NeatReminderNotifier(
    healthService: healthService,
    notificationService: notificationService,
    notificationPrefs: notificationPrefs,
    healthSyncState: healthSyncState,
  );
});

/// Provider to auto-start monitoring when appropriate
final neatAutoStartProvider = Provider<void>((ref) {
  final neatNotifier = ref.read(neatReminderProvider.notifier);
  final notificationPrefs = ref.watch(notificationPreferencesProvider);
  final healthSyncState = ref.watch(healthSyncProvider);

  // Auto-start when Health is connected and movement reminders are enabled
  if (healthSyncState.isConnected && notificationPrefs.movementReminders) {
    neatNotifier.startMonitoring();
  }

  return;
});
