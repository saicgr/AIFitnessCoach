import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/gym_location.dart';

/// Service for Google Places API integration
///
/// Provides gym/place search, autocomplete, and reverse geocoding.
class PlacesService {
  late final Dio _dio;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  PlacesService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // Google Maps removed for v1 — hardcode placeholder so isConfigured returns false
  String get _apiKey => 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// Check if API key is configured
  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// Search for places (gyms) using autocomplete
  ///
  /// [query] - Search text (e.g., "Anytime Fitness")
  /// [latitude] / [longitude] - Optional user location for proximity ranking
  /// [radiusMeters] - Search radius in meters (default 50km)
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
    int radiusMeters = 50000,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ [PlacesService] API key not configured');
      return [];
    }

    if (query.isEmpty) return [];

    debugPrint('🔍 [PlacesService] Searching places: "$query"');

    try {
      final params = <String, dynamic>{
        'input': query,
        'key': _apiKey,
        'types': 'gym|health|establishment', // Focus on gyms and fitness places
        'components': 'country:us', // Restrict to US (remove for global)
      };

      // Add location bias if user location is available
      if (latitude != null && longitude != null) {
        params['location'] = '$latitude,$longitude';
        params['radius'] = radiusMeters.toString();
        params['origin'] = '$latitude,$longitude'; // For distance calculation
      }

      final response = await _dio.get(
        '/place/autocomplete/json',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          final predictions = data['predictions'] as List<dynamic>? ?? [];
          final results = predictions
              .map((p) =>
                  PlacePrediction.fromApiResponse(p as Map<String, dynamic>))
              .toList();

          debugPrint(
              '✅ [PlacesService] Found ${results.length} places for "$query"');
          return results;
        } else if (status == 'ZERO_RESULTS') {
          debugPrint('📍 [PlacesService] No results for "$query"');
          return [];
        } else {
          debugPrint(
              '❌ [PlacesService] API error: $status - ${data['error_message']}');
          return [];
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ [PlacesService] Search error: $e');
      return [];
    }
  }

  /// Get place details by place ID
  ///
  /// Returns full location information including coordinates.
  Future<GymLocation?> getPlaceDetails(String placeId) async {
    if (!isConfigured) {
      debugPrint('⚠️ [PlacesService] API key not configured');
      return null;
    }

    debugPrint('🔍 [PlacesService] Getting details for place: $placeId');

    try {
      final response = await _dio.get(
        '/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields':
              'place_id,name,formatted_address,geometry,address_components',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          final result = data['result'] as Map<String, dynamic>?;
          if (result != null) {
            final location = GymLocation.fromPlaceDetails(result);
            debugPrint(
                '✅ [PlacesService] Got details: ${location.name} at ${location.latitude}, ${location.longitude}');
            return location;
          }
        } else {
          debugPrint(
              '❌ [PlacesService] Details error: $status - ${data['error_message']}');
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [PlacesService] Details error: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to get address
  ///
  /// [latitude] / [longitude] - Coordinates to reverse geocode
  Future<GymLocation?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    if (!isConfigured) {
      debugPrint('⚠️ [PlacesService] API key not configured');
      return null;
    }

    debugPrint(
        '🔍 [PlacesService] Reverse geocoding: $latitude, $longitude');

    try {
      final response = await _dio.get(
        '/geocode/json',
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final firstResult = results.first as Map<String, dynamic>;
            final address = firstResult['formatted_address'] as String? ?? '';

            // Extract city
            String? city;
            final components =
                firstResult['address_components'] as List<dynamic>? ?? [];
            for (final component in components) {
              final types = (component['types'] as List<dynamic>?) ?? [];
              if (types.contains('locality')) {
                city = component['long_name'] as String?;
                break;
              }
            }

            final location = GymLocation.fromCurrentPosition(
              latitude: latitude,
              longitude: longitude,
              address: address,
              city: city,
            );

            debugPrint('✅ [PlacesService] Reverse geocoded: $address');
            return location;
          }
        } else {
          debugPrint(
              '❌ [PlacesService] Geocode error: $status - ${data['error_message']}');
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [PlacesService] Reverse geocode error: $e');
      return null;
    }
  }

  /// Search nearby gyms around a location
  ///
  /// Uses Places Nearby Search instead of autocomplete.
  Future<List<GymLocation>> searchNearbyGyms({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ [PlacesService] API key not configured');
      return [];
    }

    debugPrint(
        '🔍 [PlacesService] Searching nearby gyms at: $latitude, $longitude');

    try {
      final response = await _dio.get(
        '/place/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radiusMeters,
          'type': 'gym',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>? ?? [];
          final locations = results.map((result) {
            final r = result as Map<String, dynamic>;
            final loc = r['geometry']?['location'];
            return GymLocation(
              placeId: r['place_id'] as String?,
              name: r['name'] as String? ?? 'Unknown Gym',
              address: r['vicinity'] as String? ?? '',
              latitude: (loc?['lat'] as num?)?.toDouble() ?? 0,
              longitude: (loc?['lng'] as num?)?.toDouble() ?? 0,
            );
          }).toList();

          debugPrint('✅ [PlacesService] Found ${locations.length} nearby gyms');
          return locations;
        } else if (status == 'ZERO_RESULTS') {
          debugPrint('📍 [PlacesService] No nearby gyms found');
          return [];
        } else {
          debugPrint(
              '❌ [PlacesService] Nearby search error: $status - ${data['error_message']}');
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ [PlacesService] Nearby search error: $e');
      return [];
    }
  }

  void dispose() {
    _dio.close();
  }
}
