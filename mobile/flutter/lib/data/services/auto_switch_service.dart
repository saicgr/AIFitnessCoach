import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gym_profile.dart';
import 'location_service.dart';

/// Service for automatically switching gym profiles based on location
///
/// Monitors the user's location and switches to the appropriate gym profile
/// when they enter a gym's geofence.
class AutoSwitchService {
  final LocationService _locationService;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _debounceTimer;

  /// Currently detected profile (within geofence)
  GymProfile? _currentlyDetectedProfile;

  /// Callback when a profile switch is suggested
  Function(GymProfile profile)? onProfileSwitchSuggested;

  /// Callback when user leaves all gym geofences
  Function()? onLeftAllGyms;

  /// Minimum time between switch suggestions (debounce)
  static const Duration _switchDebounce = Duration(seconds: 30);

  /// Distance filter for location updates (meters)
  static const int _distanceFilter = 25;

  AutoSwitchService(this._locationService);

  /// Start monitoring location for auto-switch
  ///
  /// [profiles] - List of gym profiles with locations to monitor
  /// [onSwitch] - Callback when a profile switch should occur
  void startMonitoring({
    required List<GymProfile> profiles,
    required Function(GymProfile profile) onSwitch,
    Function()? onLeaveAll,
  }) {
    onProfileSwitchSuggested = onSwitch;
    onLeftAllGyms = onLeaveAll;

    // Filter to profiles with locations and auto-switch enabled
    final profilesWithLocations = profiles
        .where((p) => p.hasLocation && p.autoSwitchEnabled)
        .toList();

    if (profilesWithLocations.isEmpty) {
      debugPrint('📍 [AutoSwitch] No profiles with locations to monitor');
      return;
    }

    debugPrint('📍 [AutoSwitch] Starting monitoring for ${profilesWithLocations.length} profiles');

    _locationSubscription?.cancel();
    _locationSubscription = _locationService
        .getLocationStream(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilter,
        )
        .listen(
          (position) => _handleLocationUpdate(position, profilesWithLocations),
          onError: (error) {
            debugPrint('❌ [AutoSwitch] Location stream error: $error');
          },
        );
  }

  /// Stop monitoring location
  void stopMonitoring() {
    debugPrint('📍 [AutoSwitch] Stopping monitoring');
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _currentlyDetectedProfile = null;
  }

  /// Handle location update and check for geofence matches
  void _handleLocationUpdate(Position position, List<GymProfile> profiles) {
    debugPrint('📍 [AutoSwitch] Location update: ${position.latitude}, ${position.longitude}');

    GymProfile? closestProfile;
    double closestDistance = double.infinity;

    // Find the closest profile within its radius
    for (final profile in profiles) {
      if (profile.latitude == null || profile.longitude == null) continue;

      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        profile.latitude!,
        profile.longitude!,
      );

      debugPrint('📍 [AutoSwitch] Distance to ${profile.name}: ${distance.toStringAsFixed(0)}m (radius: ${profile.locationRadiusMeters}m)');

      // Check if within this profile's geofence
      if (distance <= profile.locationRadiusMeters && distance < closestDistance) {
        closestProfile = profile;
        closestDistance = distance;
      }
    }

    // Handle profile detection
    if (closestProfile != null) {
      // User is within a gym's geofence
      if (_currentlyDetectedProfile?.id != closestProfile.id) {
        // Different profile than before, trigger switch
        _triggerSwitch(closestProfile);
      }
    } else {
      // User is not within any gym's geofence
      if (_currentlyDetectedProfile != null) {
        debugPrint('📍 [AutoSwitch] Left all gym geofences');
        _currentlyDetectedProfile = null;
        onLeftAllGyms?.call();
      }
    }
  }

  /// Trigger a profile switch with debouncing
  void _triggerSwitch(GymProfile profile) {
    // Cancel any pending debounce
    _debounceTimer?.cancel();

    // Debounce to prevent rapid switching
    _debounceTimer = Timer(_switchDebounce, () {
      debugPrint('🎯 [AutoSwitch] Suggesting switch to: ${profile.name}');
      _currentlyDetectedProfile = profile;
      onProfileSwitchSuggested?.call(profile);
    });
  }

  /// Check if user is currently within any gym geofence
  Future<GymProfile?> checkCurrentLocation(List<GymProfile> profiles) async {
    try {
      final position = await _locationService.getCurrentLocation(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 10),
      );

      // Find closest profile within radius
      for (final profile in profiles) {
        if (!profile.hasLocation || !profile.autoSwitchEnabled) continue;

        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          profile.latitude!,
          profile.longitude!,
        );

        if (distance <= profile.locationRadiusMeters) {
          debugPrint('📍 [AutoSwitch] Currently at: ${profile.name}');
          return profile;
        }
      }

      debugPrint('📍 [AutoSwitch] Not at any saved gym location');
      return null;
    } catch (e) {
      debugPrint('❌ [AutoSwitch] Failed to check location: $e');
      return null;
    }
  }

  /// Get distance from current location to a specific gym
  Future<double?> distanceToGym(GymProfile profile) async {
    if (!profile.hasLocation) return null;

    return await _locationService.distanceFromCurrentTo(
      profile.latitude!,
      profile.longitude!,
    );
  }

  void dispose() {
    stopMonitoring();
    _locationService.dispose();
  }
}
