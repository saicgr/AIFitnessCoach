import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gym_location.g.dart';

/// Represents a gym location from Google Places API or manual entry
@JsonSerializable()
class GymLocation extends Equatable {
  /// Google Places ID (if from Places API)
  @JsonKey(name: 'place_id')
  final String? placeId;

  /// Full name/title of the location (e.g., "Anytime Fitness - Downtown")
  final String name;

  /// Full formatted address
  final String address;

  /// City name for display
  final String? city;

  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Distance from user in meters (if calculated)
  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;

  const GymLocation({
    this.placeId,
    required this.name,
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  factory GymLocation.fromJson(Map<String, dynamic> json) =>
      _$GymLocationFromJson(json);
  Map<String, dynamic> toJson() => _$GymLocationToJson(this);

  /// Create from Google Places autocomplete prediction
  factory GymLocation.fromPlacePrediction(Map<String, dynamic> prediction) {
    return GymLocation(
      placeId: prediction['place_id'] as String?,
      name: prediction['structured_formatting']?['main_text'] as String? ??
          prediction['description'] as String? ??
          'Unknown',
      address: prediction['description'] as String? ?? '',
      city: null, // Will be filled from place details
      latitude: 0, // Will be filled from place details
      longitude: 0, // Will be filled from place details
    );
  }

  /// Create from Google Places place details
  factory GymLocation.fromPlaceDetails(Map<String, dynamic> details) {
    final location = details['geometry']?['location'];
    final addressComponents =
        details['address_components'] as List<dynamic>? ?? [];

    // Extract city from address components
    String? city;
    for (final component in addressComponents) {
      final types = (component['types'] as List<dynamic>?) ?? [];
      if (types.contains('locality')) {
        city = component['long_name'] as String?;
        break;
      }
    }

    return GymLocation(
      placeId: details['place_id'] as String?,
      name: details['name'] as String? ?? 'Unknown Location',
      address: details['formatted_address'] as String? ?? '',
      city: city,
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Create from current position (reverse geocoded)
  factory GymLocation.fromCurrentPosition({
    required double latitude,
    required double longitude,
    required String address,
    String? city,
  }) {
    return GymLocation(
      placeId: null,
      name: 'Current Location',
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Check if this location has valid coordinates
  bool get hasValidCoordinates =>
      latitude != 0 && longitude != 0 && latitude.abs() <= 90 && longitude.abs() <= 180;

  /// Get a short display string
  String get shortAddress {
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    // Extract first part of address
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return address;
  }

  /// Get formatted distance string
  String? get formattedDistance {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    } else {
      final miles = distanceMeters! / 1609.344;
      return '${miles.toStringAsFixed(1)} mi';
    }
  }

  /// Copy with updated distance
  GymLocation copyWithDistance(double? distance) {
    return GymLocation(
      placeId: placeId,
      name: name,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distance,
    );
  }

  @override
  List<Object?> get props => [
        placeId,
        name,
        address,
        city,
        latitude,
        longitude,
        distanceMeters,
      ];
}

/// Represents a place autocomplete prediction (before getting full details)
@JsonSerializable()
class PlacePrediction extends Equatable {
  @JsonKey(name: 'place_id')
  final String placeId;

  /// Main text (e.g., "Anytime Fitness")
  @JsonKey(name: 'main_text')
  final String mainText;

  /// Secondary text (e.g., "123 Main St, City")
  @JsonKey(name: 'secondary_text')
  final String secondaryText;

  /// Full description
  final String description;

  /// Distance in meters (if available)
  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
    this.distanceMeters,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      _$PlacePredictionFromJson(json);
  Map<String, dynamic> toJson() => _$PlacePredictionToJson(this);

  /// Create from Google Places API prediction response
  factory PlacePrediction.fromApiResponse(Map<String, dynamic> prediction) {
    final structuredFormatting =
        prediction['structured_formatting'] as Map<String, dynamic>?;

    return PlacePrediction(
      placeId: prediction['place_id'] as String? ?? '',
      mainText: structuredFormatting?['main_text'] as String? ?? '',
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
      description: prediction['description'] as String? ?? '',
      distanceMeters: (prediction['distance_meters'] as num?)?.toDouble(),
    );
  }

  /// Get formatted distance string
  String? get formattedDistance {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m away';
    } else {
      final miles = distanceMeters! / 1609.344;
      return '${miles.toStringAsFixed(1)} mi away';
    }
  }

  @override
  List<Object?> get props => [
        placeId,
        mainText,
        secondaryText,
        description,
        distanceMeters,
      ];
}
