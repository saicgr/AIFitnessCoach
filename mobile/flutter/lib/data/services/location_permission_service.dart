import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing location permissions
///
/// Handles requesting, checking, and managing location permissions
/// for gym profile auto-switch functionality.
class LocationPermissionService {
  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Request "when in use" location permission
  ///
  /// This is the basic permission needed for getting current location
  /// when the app is in the foreground.
  Future<LocationPermission> requestWhenInUsePermission() async {
    debugPrint('📍 [LocationPermission] Requesting when-in-use permission...');

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('📍 [LocationPermission] Permission result: $permission');
    }

    return permission;
  }

  /// Request "always" (background) location permission
  ///
  /// Required for auto-switching gym profiles when arriving at a location.
  /// Note: On iOS, must have "when in use" permission first.
  Future<PermissionStatus> requestAlwaysPermission() async {
    debugPrint('📍 [LocationPermission] Requesting always permission...');

    // First ensure we have when-in-use permission
    final currentPermission = await Geolocator.checkPermission();
    if (currentPermission == LocationPermission.denied ||
        currentPermission == LocationPermission.deniedForever) {
      debugPrint('📍 [LocationPermission] Need when-in-use permission first');
      await requestWhenInUsePermission();
    }

    // Now request always permission using permission_handler
    // (geolocator doesn't have a direct API for background location)
    final status = await Permission.locationAlways.request();
    debugPrint('📍 [LocationPermission] Always permission result: $status');

    return status;
  }

  /// Check if we have sufficient permission for auto-switch
  ///
  /// Returns true if we have at least "when in use" permission.
  /// For full auto-switch, "always" permission is recommended.
  Future<bool> hasBasicLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  /// Check if we have background location permission for auto-switch
  Future<bool> hasBackgroundLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Open device location settings
  ///
  /// Use this when location services are disabled.
  Future<bool> openLocationSettings() async {
    debugPrint('📍 [LocationPermission] Opening location settings...');
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  ///
  /// Use this when permission is permanently denied.
  Future<bool> openAppSettings() async {
    debugPrint('📍 [LocationPermission] Opening app settings...');
    return await openAppSettings();
  }

  /// Get a user-friendly description of current permission status
  String getPermissionDescription(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission not granted';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied. Please enable in Settings.';
      case LocationPermission.whileInUse:
        return 'Location available while using app';
      case LocationPermission.always:
        return 'Background location enabled';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission';
    }
  }

  /// Check if permission was permanently denied
  bool isPermanentlyDenied(LocationPermission permission) {
    return permission == LocationPermission.deniedForever;
  }
}
