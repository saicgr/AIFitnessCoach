import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_location.dart';
import '../services/places_service.dart';
import 'location_provider.dart';

/// Provider for the places service
final placesServiceProvider = Provider<PlacesService>((ref) {
  final service = PlacesService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider to check if Google Places API is configured
final isPlacesApiConfiguredProvider = Provider<bool>((ref) {
  final service = ref.watch(placesServiceProvider);
  return service.isConfigured;
});

/// State for place search
class PlaceSearchState {
  final String query;
  final List<PlacePrediction> predictions;
  final bool isSearching;
  final String? error;

  const PlaceSearchState({
    this.query = '',
    this.predictions = const [],
    this.isSearching = false,
    this.error,
  });

  PlaceSearchState copyWith({
    String? query,
    List<PlacePrediction>? predictions,
    bool? isSearching,
    String? error,
  }) {
    return PlaceSearchState(
      query: query ?? this.query,
      predictions: predictions ?? this.predictions,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

/// Notifier for place search with debouncing
class PlaceSearchNotifier extends StateNotifier<PlaceSearchState> {
  final PlacesService _service;
  final Ref _ref;
  Timer? _debounceTimer;

  PlaceSearchNotifier(this._service, this._ref)
      : super(const PlaceSearchState());

  /// Search for places with debouncing
  void search(String query) {
    state = state.copyWith(query: query);

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = state.copyWith(predictions: [], isSearching: false);
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query != state.query) return; // Query changed, skip

    state = state.copyWith(isSearching: true, error: null);

    try {
      // Try to get current location for better results
      double? lat;
      double? lon;
      try {
        final locationState = _ref.read(locationStreamProvider);
        lat = locationState.currentPosition?.latitude;
        lon = locationState.currentPosition?.longitude;
      } catch (e) {
        // Location not available, continue without
      }

      final predictions = await _service.searchPlaces(
        query,
        latitude: lat,
        longitude: lon,
      );

      // Only update if query still matches
      if (query == state.query) {
        state = state.copyWith(
          predictions: predictions,
          isSearching: false,
        );
      }
    } catch (e) {
      debugPrint('❌ [PlaceSearchNotifier] Search error: $e');
      if (query == state.query) {
        state = state.copyWith(
          error: 'Search failed. Please try again.',
          isSearching: false,
        );
      }
    }
  }

  /// Clear search results
  void clear() {
    _debounceTimer?.cancel();
    state = const PlaceSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for place search
final placeSearchProvider =
    StateNotifierProvider<PlaceSearchNotifier, PlaceSearchState>((ref) {
  final service = ref.watch(placesServiceProvider);
  return PlaceSearchNotifier(service, ref);
});

/// Provider for getting place details
///
/// Usage: ref.watch(placeDetailsProvider('ChIJ...'))
final placeDetailsProvider =
    FutureProvider.autoDispose.family<GymLocation?, String>((ref, placeId) async {
  final service = ref.watch(placesServiceProvider);
  return await service.getPlaceDetails(placeId);
});

/// Provider for reverse geocoding current location
final currentLocationAddressProvider = FutureProvider.autoDispose<GymLocation?>((ref) async {
  final locationState = ref.watch(locationStreamProvider);
  final position = locationState.currentPosition;

  if (position == null) {
    debugPrint('📍 [Places] No current position for reverse geocode');
    return null;
  }

  final service = ref.watch(placesServiceProvider);
  return await service.reverseGeocode(position.latitude, position.longitude);
});

/// Provider for nearby gyms around current location
final nearbyGymsProvider = FutureProvider.autoDispose<List<GymLocation>>((ref) async {
  final locationState = ref.watch(locationStreamProvider);
  final position = locationState.currentPosition;

  if (position == null) {
    debugPrint('📍 [Places] No current position for nearby search');
    return [];
  }

  final service = ref.watch(placesServiceProvider);
  return await service.searchNearbyGyms(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusMeters: 5000, // 5km radius
  );
});

/// State for selected gym location
class SelectedLocationState {
  final GymLocation? location;
  final bool isLoading;
  final String? error;

  const SelectedLocationState({
    this.location,
    this.isLoading = false,
    this.error,
  });

  SelectedLocationState copyWith({
    GymLocation? location,
    bool? isLoading,
    String? error,
  }) {
    return SelectedLocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing selected location in the picker
class SelectedLocationNotifier extends StateNotifier<SelectedLocationState> {
  final PlacesService _service;
  final Ref _ref;

  SelectedLocationNotifier(this._service, this._ref)
      : super(const SelectedLocationState());

  /// Select a place from autocomplete prediction
  Future<void> selectFromPrediction(PlacePrediction prediction) async {
    debugPrint('📍 [SelectedLocation] Selecting: ${prediction.mainText}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final location = await _service.getPlaceDetails(prediction.placeId);
      if (location != null) {
        state = SelectedLocationState(location: location);
        debugPrint('✅ [SelectedLocation] Selected: ${location.name}');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not get location details',
        );
      }
    } catch (e) {
      debugPrint('❌ [SelectedLocation] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location',
      );
    }
  }

  /// Use current location
  Future<void> useCurrentLocation() async {
    debugPrint('📍 [SelectedLocation] Using current location...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current position
      final locationNotifier = _ref.read(locationStreamProvider.notifier);
      final position = await locationNotifier.refreshCurrentLocation();

      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not get current location',
        );
        return;
      }

      // Reverse geocode to get address
      final location = await _service.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (location != null) {
        state = SelectedLocationState(location: location);
        debugPrint('✅ [SelectedLocation] Current location: ${location.address}');
      } else {
        // Create location without address
        state = SelectedLocationState(
          location: GymLocation(
            name: 'Current Location',
            address: '${position.latitude}, ${position.longitude}',
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SelectedLocation] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location',
      );
    }
  }

  /// Set location directly
  void setLocation(GymLocation location) {
    state = SelectedLocationState(location: location);
  }

  /// Clear selected location
  void clear() {
    state = const SelectedLocationState();
  }
}

/// Provider for selected location in the picker
final selectedLocationProvider =
    StateNotifierProvider<SelectedLocationNotifier, SelectedLocationState>(
        (ref) {
  final service = ref.watch(placesServiceProvider);
  return SelectedLocationNotifier(service, ref);
});
