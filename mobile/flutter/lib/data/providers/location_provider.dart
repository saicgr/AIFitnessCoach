import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'location_permission_provider.dart';

/// Provider for the location service
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current location (one-time fetch)
///
/// Use this when you need the current location once.
/// Auto-refreshes when permission status changes.
final currentLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  // Watch permission status - refresh when it changes
  final hasPermission = await ref.watch(hasLocationPermissionProvider.future);

  if (!hasPermission) {
    debugPrint('📍 [LocationProvider] No location permission');
    return null;
  }

  final service = ref.watch(locationServiceProvider);

  try {
    final position = await service.getCurrentLocation(
      accuracy: LocationAccuracy.high,
      timeout: const Duration(seconds: 15),
    );
    debugPrint('✅ [LocationProvider] Current location: ${position.latitude}, ${position.longitude}');
    return position;
  } catch (e) {
    debugPrint('❌ [LocationProvider] Failed to get location: $e');
    return null;
  }
});

/// Provider for last known location (fast, cached)
///
/// Use this for quick location access without waiting.
final lastKnownLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.getLastKnownLocation();
});

/// State for location streaming
class LocationStreamState {
  final Position? currentPosition;
  final bool isStreaming;
  final String? error;
  final DateTime? lastUpdated;

  const LocationStreamState({
    this.currentPosition,
    this.isStreaming = false,
    this.error,
    this.lastUpdated,
  });

  LocationStreamState copyWith({
    Position? currentPosition,
    bool? isStreaming,
    String? error,
    DateTime? lastUpdated,
  }) {
    return LocationStreamState(
      currentPosition: currentPosition ?? this.currentPosition,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for managing location streaming
///
/// Use this for continuous location updates (e.g., for auto-switch feature).
class LocationStreamNotifier extends StateNotifier<LocationStreamState> {
  final LocationService _service;
  final Ref _ref;
  StreamSubscription<Position>? _subscription;

  LocationStreamNotifier(this._service, this._ref)
      : super(const LocationStreamState());

  /// Start streaming location updates
  Future<void> startStreaming({
    int distanceFilterMeters = 50,
  }) async {
    if (state.isStreaming) {
      debugPrint('📍 [LocationStreamNotifier] Already streaming');
      return;
    }

    // Check permission first
    final hasPermission = await _ref.read(hasLocationPermissionProvider.future);
    if (!hasPermission) {
      state = state.copyWith(
        error: 'Location permission not granted',
        isStreaming: false,
      );
      return;
    }

    debugPrint('📍 [LocationStreamNotifier] Starting location stream...');
    state = state.copyWith(isStreaming: true, error: null);

    try {
      final stream = _service.getLocationStream(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );

      _subscription = stream.listen(
        (position) {
          debugPrint('📍 [LocationStreamNotifier] Position update: ${position.latitude}, ${position.longitude}');
          state = state.copyWith(
            currentPosition: position,
            lastUpdated: DateTime.now(),
            error: null,
          );
        },
        onError: (error) {
          debugPrint('❌ [LocationStreamNotifier] Stream error: $error');
          state = state.copyWith(
            error: error.toString(),
            isStreaming: false,
          );
        },
      );
    } catch (e) {
      debugPrint('❌ [LocationStreamNotifier] Failed to start stream: $e');
      state = state.copyWith(
        error: e.toString(),
        isStreaming: false,
      );
    }
  }

  /// Stop streaming location updates
  void stopStreaming() {
    debugPrint('📍 [LocationStreamNotifier] Stopping location stream');
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isStreaming: false);
  }

  /// Get current location once and update state
  Future<Position?> refreshCurrentLocation() async {
    debugPrint('📍 [LocationStreamNotifier] Refreshing current location...');

    try {
      final position = await _service.getCurrentLocation(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 15),
      );

      state = state.copyWith(
        currentPosition: position,
        lastUpdated: DateTime.now(),
        error: null,
      );

      return position;
    } catch (e) {
      debugPrint('❌ [LocationStreamNotifier] Failed to refresh: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    stopStreaming();
    super.dispose();
  }
}

/// Provider for location stream notifier
final locationStreamProvider =
    StateNotifierProvider<LocationStreamNotifier, LocationStreamState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationStreamNotifier(service, ref);
});

/// Provider for calculating distance from current location to a point
///
/// Usage: ref.watch(distanceToProvider((lat: 37.7749, lon: -122.4194)))
final distanceToProvider =
    FutureProvider.autoDispose.family<double?, ({double lat, double lon})>(
  (ref, coords) async {
    final service = ref.watch(locationServiceProvider);
    return await service.distanceFromCurrentTo(coords.lat, coords.lon);
  },
);

/// Provider for formatted distance from current location to a point
final formattedDistanceToProvider =
    FutureProvider.autoDispose.family<String?, ({double lat, double lon})>(
  (ref, coords) async {
    final distance = await ref.watch(distanceToProvider(coords).future);
    if (distance == null) return null;

    final service = ref.watch(locationServiceProvider);
    return service.formatDistanceMiles(distance);
  },
);
