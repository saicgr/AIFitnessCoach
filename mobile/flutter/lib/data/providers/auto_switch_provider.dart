import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gym_profile.dart';
import '../services/auto_switch_service.dart';
import '../services/location_service.dart';
import 'gym_profile_provider.dart';
import 'location_permission_provider.dart';
import 'time_slot_provider.dart';
import '../repositories/workout_repository.dart';
import 'today_workout_provider.dart';

/// Key for storing auto-switch enabled preference
const String _autoSwitchEnabledKey = 'auto_switch_enabled';

/// Provider for the auto-switch service
final autoSwitchServiceProvider = Provider<AutoSwitchService>((ref) {
  final locationService = LocationService();
  final service = AutoSwitchService(locationService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for auto-switch enabled setting
final autoSwitchEnabledProvider = StateNotifierProvider<AutoSwitchEnabledNotifier, bool>((ref) {
  return AutoSwitchEnabledNotifier();
});

/// Notifier for auto-switch enabled setting
class AutoSwitchEnabledNotifier extends StateNotifier<bool> {
  AutoSwitchEnabledNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_autoSwitchEnabledKey) ?? false;
      debugPrint('📍 [AutoSwitchEnabled] Loaded preference: $state');
    } catch (e) {
      debugPrint('❌ [AutoSwitchEnabled] Failed to load preference: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoSwitchEnabledKey, enabled);
      debugPrint('📍 [AutoSwitchEnabled] Saved preference: $enabled');
    } catch (e) {
      debugPrint('❌ [AutoSwitchEnabled] Failed to save preference: $e');
    }
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

/// State for auto-switch monitoring
class AutoSwitchState {
  final bool isMonitoring;
  final GymProfile? detectedProfile;
  final GymProfile? suggestedProfile;
  final String? error;
  final DateTime? lastCheck;

  const AutoSwitchState({
    this.isMonitoring = false,
    this.detectedProfile,
    this.suggestedProfile,
    this.error,
    this.lastCheck,
  });

  AutoSwitchState copyWith({
    bool? isMonitoring,
    GymProfile? detectedProfile,
    GymProfile? suggestedProfile,
    String? error,
    DateTime? lastCheck,
    bool clearDetected = false,
    bool clearSuggested = false,
  }) {
    return AutoSwitchState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      detectedProfile: clearDetected ? null : (detectedProfile ?? this.detectedProfile),
      suggestedProfile: clearSuggested ? null : (suggestedProfile ?? this.suggestedProfile),
      error: error,
      lastCheck: lastCheck ?? this.lastCheck,
    );
  }
}

/// Notifier for managing auto-switch monitoring
class AutoSwitchNotifier extends StateNotifier<AutoSwitchState> {
  final AutoSwitchService _service;
  final Ref _ref;

  AutoSwitchNotifier(this._service, this._ref) : super(const AutoSwitchState());

  /// Start monitoring location for auto-switch
  Future<bool> startMonitoring() async {
    debugPrint('📍 [AutoSwitchNotifier] Attempting to start monitoring...');

    // Check if enabled
    final isEnabled = _ref.read(autoSwitchEnabledProvider);
    if (!isEnabled) {
      debugPrint('📍 [AutoSwitchNotifier] Auto-switch is disabled in settings');
      return false;
    }

    // Check permission
    final hasPermission = await _ref.read(hasBackgroundLocationPermissionProvider.future);
    if (!hasPermission) {
      debugPrint('📍 [AutoSwitchNotifier] Background location permission not granted');
      state = state.copyWith(
        error: 'Background location permission required for auto-switch',
        isMonitoring: false,
      );
      return false;
    }

    // Get profiles with locations
    final profilesState = _ref.read(gymProfilesProvider);
    final profiles = profilesState.valueOrNull ?? [];
    final profilesWithLocations = profiles
        .where((p) => p.hasLocation && p.autoSwitchEnabled)
        .toList();

    if (profilesWithLocations.isEmpty) {
      debugPrint('📍 [AutoSwitchNotifier] No profiles with locations');
      state = state.copyWith(
        error: 'No gym profiles have locations set',
        isMonitoring: false,
      );
      return false;
    }

    // Start monitoring
    _service.startMonitoring(
      profiles: profilesWithLocations,
      onSwitch: (profile) {
        debugPrint('🎯 [AutoSwitchNotifier] Switch suggested: ${profile.name}');
        state = state.copyWith(
          suggestedProfile: profile,
          detectedProfile: profile,
          lastCheck: DateTime.now(),
        );
      },
      onLeaveAll: () {
        debugPrint('📍 [AutoSwitchNotifier] Left all gym geofences');
        state = state.copyWith(
          clearDetected: true,
          lastCheck: DateTime.now(),
        );
      },
    );

    state = state.copyWith(isMonitoring: true, error: null);
    return true;
  }

  /// Stop monitoring
  void stopMonitoring() {
    debugPrint('📍 [AutoSwitchNotifier] Stopping monitoring');
    _service.stopMonitoring();
    state = state.copyWith(isMonitoring: false, clearDetected: true);
  }

  /// Check current location and return matching profile (if any)
  Future<GymProfile?> checkCurrentLocation() async {
    final profilesState = _ref.read(gymProfilesProvider);
    final profiles = profilesState.valueOrNull ?? [];

    final profile = await _service.checkCurrentLocation(profiles);
    state = state.copyWith(
      detectedProfile: profile,
      lastCheck: DateTime.now(),
    );
    return profile;
  }

  /// Accept the suggested profile switch
  Future<void> acceptSuggestedSwitch() async {
    final suggested = state.suggestedProfile;
    if (suggested == null) return;

    debugPrint('📍 [AutoSwitchNotifier] Accepting switch to: ${suggested.name}');

    try {
      await _ref.read(gymProfilesProvider.notifier).activateProfile(suggested.id);

      // Reset generation state and invalidate workout providers for new profile
      TodayWorkoutNotifier.resetGenerationState();
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(workoutsProvider);

      state = state.copyWith(clearSuggested: true);
    } catch (e) {
      debugPrint('❌ [AutoSwitchNotifier] Failed to switch: $e');
      state = state.copyWith(error: 'Failed to switch profile');
    }
  }

  /// Dismiss the suggested switch without accepting
  void dismissSuggestedSwitch() {
    debugPrint('📍 [AutoSwitchNotifier] Dismissing suggested switch');
    state = state.copyWith(clearSuggested: true);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Provider for auto-switch notifier
final autoSwitchProvider =
    StateNotifierProvider<AutoSwitchNotifier, AutoSwitchState>((ref) {
  final service = ref.watch(autoSwitchServiceProvider);
  return AutoSwitchNotifier(service, ref);
});

/// Provider that indicates if auto-switch can be enabled
/// (has profiles with locations and permission)
final canEnableAutoSwitchProvider = FutureProvider<bool>((ref) async {
  // Check for background location permission
  final hasPermission = await ref.watch(hasBackgroundLocationPermissionProvider.future);
  if (!hasPermission) return false;

  // Check for profiles with locations
  final profilesState = ref.watch(gymProfilesProvider);
  final profiles = profilesState.valueOrNull ?? [];
  final hasProfilesWithLocations = profiles.any((p) => p.hasLocation);

  return hasProfilesWithLocations;
});

/// Provider that returns profiles with auto-switch configured
final autoSwitchProfilesProvider = Provider<List<GymProfile>>((ref) {
  final profilesState = ref.watch(gymProfilesProvider);
  final profiles = profilesState.valueOrNull ?? [];
  return profiles.where((p) => p.hasLocation && p.autoSwitchEnabled).toList();
});

/// Combined suggested profile provider
/// Priority: Location match > Time match
/// Returns the best profile suggestion based on location or time
final combinedSuggestedProfileProvider = Provider<GymProfile?>((ref) {
  // First check location-based suggestion
  final autoSwitchState = ref.watch(autoSwitchProvider);
  final locationSuggestion = autoSwitchState.suggestedProfile;

  // Location takes priority - if we have a location suggestion, use it
  if (locationSuggestion != null) {
    debugPrint('🎯 [CombinedSuggestion] Using location-based suggestion: ${locationSuggestion.name}');
    return locationSuggestion;
  }

  // If no location suggestion, check time-based suggestion
  final timeSuggestion = ref.watch(timeSuggestedProfileProvider);
  if (timeSuggestion != null) {
    debugPrint('⏰ [CombinedSuggestion] Using time-based suggestion: ${timeSuggestion.name}');
    return timeSuggestion;
  }

  return null;
});

/// Provider that indicates the source of the current suggestion
enum SuggestionSource { none, location, time }

final suggestionSourceProvider = Provider<SuggestionSource>((ref) {
  final autoSwitchState = ref.watch(autoSwitchProvider);
  if (autoSwitchState.suggestedProfile != null) {
    return SuggestionSource.location;
  }

  final timeSuggestion = ref.watch(timeSuggestedProfileProvider);
  if (timeSuggestion != null) {
    return SuggestionSource.time;
  }

  return SuggestionSource.none;
});

/// Provider that indicates if any auto-switch is available (location or time)
final hasAutoSwitchSuggestionProvider = Provider<bool>((ref) {
  return ref.watch(combinedSuggestedProfileProvider) != null;
});
