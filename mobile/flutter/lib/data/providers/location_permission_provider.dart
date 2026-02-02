import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_permission_service.dart';

/// Provider for the location permission service
final locationPermissionServiceProvider = Provider<LocationPermissionService>((ref) {
  return LocationPermissionService();
});

/// Provider for current location permission status
///
/// Auto-refreshes when the app resumes.
final locationPermissionStatusProvider = FutureProvider.autoDispose<LocationPermission>((ref) async {
  final service = ref.watch(locationPermissionServiceProvider);
  final permission = await service.getPermissionStatus();
  debugPrint('📍 [LocationPermissionProvider] Current status: $permission');
  return permission;
});

/// Provider for whether location services are enabled
final locationServiceEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(locationPermissionServiceProvider);
  final enabled = await service.isLocationServiceEnabled();
  debugPrint('📍 [LocationPermissionProvider] Location services enabled: $enabled');
  return enabled;
});

/// Provider for whether we have basic location permission
final hasLocationPermissionProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(locationPermissionServiceProvider);
  return await service.hasBasicLocationPermission();
});

/// Provider for whether we have background location permission (for auto-switch)
final hasBackgroundLocationPermissionProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(locationPermissionServiceProvider);
  return await service.hasBackgroundLocationPermission();
});

/// State notifier for managing location permission requests
class LocationPermissionNotifier extends StateNotifier<AsyncValue<LocationPermission>> {
  final LocationPermissionService _service;
  final Ref _ref;

  LocationPermissionNotifier(this._service, this._ref)
      : super(const AsyncValue.loading()) {
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final permission = await _service.getPermissionStatus();
      state = AsyncValue.data(permission);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Request when-in-use location permission
  Future<LocationPermission> requestWhenInUsePermission() async {
    debugPrint('📍 [LocationPermissionNotifier] Requesting when-in-use permission...');
    state = const AsyncValue.loading();

    try {
      final permission = await _service.requestWhenInUsePermission();
      state = AsyncValue.data(permission);

      // Invalidate related providers
      _ref.invalidate(hasLocationPermissionProvider);
      _ref.invalidate(hasBackgroundLocationPermissionProvider);

      return permission;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Request always (background) permission
  Future<void> requestBackgroundPermission() async {
    debugPrint('📍 [LocationPermissionNotifier] Requesting background permission...');

    try {
      await _service.requestAlwaysPermission();
      await _loadCurrentStatus();

      // Invalidate related providers
      _ref.invalidate(hasBackgroundLocationPermissionProvider);
    } catch (e) {
      debugPrint('❌ [LocationPermissionNotifier] Error requesting background permission: $e');
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _service.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _service.openAppSettings();
  }

  /// Refresh permission status
  Future<void> refresh() async {
    await _loadCurrentStatus();
    _ref.invalidate(hasLocationPermissionProvider);
    _ref.invalidate(hasBackgroundLocationPermissionProvider);
  }
}

/// Provider for the permission notifier
final locationPermissionNotifierProvider =
    StateNotifierProvider<LocationPermissionNotifier, AsyncValue<LocationPermission>>((ref) {
  final service = ref.watch(locationPermissionServiceProvider);
  return LocationPermissionNotifier(service, ref);
});
