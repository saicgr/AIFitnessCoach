import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/time_slot_utils.dart';
import '../models/gym_profile.dart';
import 'gym_profile_provider.dart';

/// Key for storing time auto-switch enabled preference
const String _timeAutoSwitchEnabledKey = 'time_auto_switch_enabled';

/// Provider for the current time slot
/// Refreshes automatically when the time slot changes
final currentTimeSlotProvider = StateNotifierProvider<CurrentTimeSlotNotifier, TimeSlot>((ref) {
  return CurrentTimeSlotNotifier();
});

/// Notifier for current time slot with auto-refresh
class CurrentTimeSlotNotifier extends StateNotifier<TimeSlot> {
  Timer? _timer;

  CurrentTimeSlotNotifier() : super(TimeSlotUtils.getCurrentTimeSlot()) {
    _startTimer();
  }

  void _startTimer() {
    // Check every minute if time slot has changed
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final newSlot = TimeSlotUtils.getCurrentTimeSlot();
      if (newSlot != state) {
        debugPrint('⏰ [TimeSlot] Time slot changed: ${state.label} → ${newSlot.label}');
        state = newSlot;
      }
    });
  }

  /// Force refresh the current time slot
  void refresh() {
    state = TimeSlotUtils.getCurrentTimeSlot();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for time-based auto-switch global enabled setting
final timeAutoSwitchEnabledProvider = StateNotifierProvider<TimeAutoSwitchEnabledNotifier, bool>((ref) {
  return TimeAutoSwitchEnabledNotifier();
});

/// Notifier for time-based auto-switch enabled setting
class TimeAutoSwitchEnabledNotifier extends StateNotifier<bool> {
  TimeAutoSwitchEnabledNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_timeAutoSwitchEnabledKey) ?? true;
      debugPrint('⏰ [TimeAutoSwitch] Loaded preference: $state');
    } catch (e) {
      debugPrint('❌ [TimeAutoSwitch] Failed to load preference: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_timeAutoSwitchEnabledKey, enabled);
      debugPrint('⏰ [TimeAutoSwitch] Saved preference: $enabled');
    } catch (e) {
      debugPrint('❌ [TimeAutoSwitch] Failed to save preference: $e');
    }
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

/// Provider for profiles that match the current time slot
final timeMatchingProfilesProvider = Provider<List<GymProfile>>((ref) {
  final currentSlot = ref.watch(currentTimeSlotProvider);
  final isEnabled = ref.watch(timeAutoSwitchEnabledProvider);

  if (!isEnabled) return [];

  final profilesState = ref.watch(gymProfilesProvider);
  final profiles = profilesState.valueOrNull ?? [];

  return profiles.where((p) =>
    p.preferredTimeSlot == currentSlot.value &&
    p.timeAutoSwitchEnabled
  ).toList();
});

/// Provider for suggested time-based profile switch
/// Returns the profile that should be suggested based on current time
/// Returns null if no suggestion (already active or no match)
final timeSuggestedProfileProvider = Provider<GymProfile?>((ref) {
  final isEnabled = ref.watch(timeAutoSwitchEnabledProvider);
  if (!isEnabled) return null;

  final matchingProfiles = ref.watch(timeMatchingProfilesProvider);
  if (matchingProfiles.isEmpty) return null;

  // Get active profile
  final profilesState = ref.watch(gymProfilesProvider);
  final profiles = profilesState.valueOrNull ?? [];
  final activeProfile = profiles.firstWhere(
    (p) => p.isActive,
    orElse: () => profiles.first,
  );

  // Find matching profile that is not already active
  final suggestion = matchingProfiles.firstWhere(
    (p) => p.id != activeProfile.id,
    orElse: () => matchingProfiles.first,
  );

  // Don't suggest if already active
  if (suggestion.id == activeProfile.id) return null;

  return suggestion;
});

/// Provider that returns profiles with time preferences configured
final profilesWithTimePreferenceProvider = Provider<List<GymProfile>>((ref) {
  final profilesState = ref.watch(gymProfilesProvider);
  final profiles = profilesState.valueOrNull ?? [];
  return profiles.where((p) => p.hasTimePreference).toList();
});

/// Provider that checks if time-based auto-switch can be enabled
/// (has at least one profile with time preference)
final canEnableTimeAutoSwitchProvider = Provider<bool>((ref) {
  final profilesWithTime = ref.watch(profilesWithTimePreferenceProvider);
  return profilesWithTime.isNotEmpty;
});
