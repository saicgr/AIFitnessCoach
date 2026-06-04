import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/community_gyms_service.dart';
import 'location_provider.dart';

/// Re-export of the service provider so callers can import from one place.
export '../services/community_gyms_service.dart' show communityGymsServiceProvider;

/// Search radius (metres) for the nearby-gyms request. Decision: 5000m.
const int kNearbyGymsRadiusMeters = 5000;

/// Location-driven nearby-gyms provider (Feature 3B).
///
/// Family argument is the optional name filter (empty string = no filter).
/// Resolves the device's current location, then queries the community catalog.
/// Throws [NoLocationException] when location is unavailable so the screen can
/// render a permission/empty state instead of a fabricated list (no mock data).
final nearbyGymsProvider = FutureProvider.autoDispose
    .family<NearbyGymsResult, String>((ref, query) async {
  final position = await ref.watch(currentLocationProvider.future);
  if (position == null) {
    debugPrint('📍 [CommunityGymsProvider] No location — cannot search nearby gyms');
    throw const NoLocationException();
  }

  final service = ref.watch(communityGymsServiceProvider);
  return service.nearby(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusMeters: kNearbyGymsRadiusMeters,
    query: query.trim().isEmpty ? null : query.trim(),
  );
});

/// Detail provider for a single community gym (family on place_id).
final communityGymDetailProvider = FutureProvider.autoDispose
    .family<GymDetail, String>((ref, placeId) async {
  final service = ref.watch(communityGymsServiceProvider);
  return service.detail(placeId);
});

/// Raised when nearby-gyms is requested without an available device location.
class NoLocationException implements Exception {
  const NoLocationException();

  @override
  String toString() =>
      'Location unavailable. Enable location to find gyms near you.';
}
