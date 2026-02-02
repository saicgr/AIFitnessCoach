import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service for location-related operations
///
/// Wraps geolocator functionality for getting current location,
/// streaming location updates, and calculating distances.
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Get current location
  ///
  /// Returns the current device position with specified accuracy.
  /// Throws exception if location services are disabled or permission denied.
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint('📍 [LocationService] Getting current location...');

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ [LocationService] Location services disabled');
      throw LocationServiceDisabledException();
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ [LocationService] Location permission denied');
        throw PermissionDeniedException('Location');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ [LocationService] Location permission permanently denied');
      throw PermissionDeniedException('Location (permanently denied)');
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeout,
      ),
    );

    debugPrint('✅ [LocationService] Got location: ${position.latitude}, ${position.longitude}');
    return position;
  }

  /// Get last known location (cached)
  ///
  /// Returns the last known position without making a new request.
  /// Can return null if no cached position available.
  Future<Position?> getLastKnownLocation() async {
    debugPrint('📍 [LocationService] Getting last known location...');
    final position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      debugPrint('✅ [LocationService] Last known: ${position.latitude}, ${position.longitude}');
    } else {
      debugPrint('⚠️ [LocationService] No last known location');
    }
    return position;
  }

  /// Start streaming location updates
  ///
  /// Returns a stream of position updates. Use for real-time tracking.
  /// Remember to cancel the subscription when done.
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    debugPrint('📍 [LocationService] Starting location stream (distanceFilter: ${distanceFilter}m)');

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Calculate distance between two points in meters
  ///
  /// Uses Haversine formula for accurate great-circle distance.
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate distance from current position to a target
  Future<double?> distanceFromCurrentTo(double targetLat, double targetLon) async {
    try {
      final current = await getCurrentLocation(
        accuracy: LocationAccuracy.medium,
        timeout: const Duration(seconds: 10),
      );
      return calculateDistance(
        current.latitude,
        current.longitude,
        targetLat,
        targetLon,
      );
    } catch (e) {
      debugPrint('❌ [LocationService] Failed to calculate distance: $e');
      return null;
    }
  }

  /// Check if a position is within a radius of a target
  bool isWithinRadius(
    Position currentPosition,
    double targetLat,
    double targetLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLat,
      targetLon,
    );
    return distance <= radiusMeters;
  }

  /// Format distance for display
  ///
  /// Returns human-readable distance string (e.g., "150 m" or "2.3 km")
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format distance in miles
  String formatDistanceMiles(double meters) {
    final miles = meters / 1609.344;
    if (miles < 0.1) {
      final feet = meters * 3.28084;
      return '${feet.round()} ft';
    } else {
      return '${miles.toStringAsFixed(1)} mi';
    }
  }

  /// Stop any active location streaming
  void stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint('📍 [LocationService] Location stream stopped');
  }

  /// Dispose resources
  void dispose() {
    stopLocationStream();
  }
}

/// Custom exception for when location services are disabled
class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled on this device';
}

/// Custom exception for permission denied
class PermissionDeniedException implements Exception {
  final String permission;
  PermissionDeniedException(this.permission);

  @override
  String toString() => '$permission permission was denied';
}
