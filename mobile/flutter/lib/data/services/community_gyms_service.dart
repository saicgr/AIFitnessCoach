import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_profile.dart';
import 'api_client.dart';

/// Service provider for the Community Gym Catalog (Feature 3B).
final communityGymsServiceProvider = Provider<CommunityGymsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityGymsService(apiClient);
});

/// A gym in the community catalog (one row per Google Places place_id).
@immutable
class CommunityGym {
  final String placeId;
  final String name;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String source;
  final double? distanceMeters;

  const CommunityGym({
    required this.placeId,
    required this.name,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.source = 'places',
    this.distanceMeters,
  });

  factory CommunityGym.fromJson(Map<String, dynamic> json) {
    double? d(Object? v) => v is num ? v.toDouble() : null;
    return CommunityGym(
      placeId: json['place_id'] as String,
      name: (json['name'] as String?) ?? 'Gym',
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: d(json['latitude']),
      longitude: d(json['longitude']),
      source: (json['source'] as String?) ?? 'places',
      distanceMeters: d(json['distance_meters']),
    );
  }

  /// Human-readable distance ("450 m" / "2.3 km"). Empty when unknown.
  String get distanceLabel {
    final m = distanceMeters;
    if (m == null) return '';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}

/// Response from GET /community-gyms/nearby.
@immutable
class NearbyGymsResult {
  final List<CommunityGym> gyms;

  /// True when Places was unconfigured/unavailable and results came from the
  /// local catalog only — the UI should offer "search by name".
  final bool catalogOnly;

  /// True when results came from a live Places call.
  final bool fromPlaces;

  const NearbyGymsResult({
    required this.gyms,
    this.catalogOnly = false,
    this.fromPlaces = false,
  });

  factory NearbyGymsResult.fromJson(Map<String, dynamic> json) {
    final list = (json['gyms'] as List?) ?? const [];
    return NearbyGymsResult(
      gyms: list
          .whereType<Map<String, dynamic>>()
          .map(CommunityGym.fromJson)
          .toList(growable: false),
      catalogOnly: (json['catalog_only'] as bool?) ?? false,
      fromPlaces: (json['from_places'] as bool?) ?? false,
    );
  }
}

/// One consensus equipment item with its reporter count + confirmed flag.
@immutable
class ConsensusEquipment {
  final String equipment;
  final int reporterCount;
  final bool confirmed;

  const ConsensusEquipment({
    required this.equipment,
    required this.reporterCount,
    required this.confirmed,
  });

  factory ConsensusEquipment.fromJson(Map<String, dynamic> json) {
    return ConsensusEquipment(
      equipment: (json['equipment'] as String?) ?? '',
      reporterCount: (json['reporter_count'] is num)
          ? (json['reporter_count'] as num).toInt()
          : 0,
      confirmed: (json['confirmed'] as bool?) ?? false,
    );
  }
}

/// Response from GET /community-gyms/{place_id} and POST /report.
@immutable
class GymDetail {
  final CommunityGym gym;
  final List<ConsensusEquipment> confirmed;
  final List<ConsensusEquipment> reported;
  final int totalReporters;
  final int consensusMinReporters;

  const GymDetail({
    required this.gym,
    required this.confirmed,
    required this.reported,
    required this.totalReporters,
    required this.consensusMinReporters,
  });

  factory GymDetail.fromJson(Map<String, dynamic> json) {
    List<ConsensusEquipment> decode(Object? v) {
      if (v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(ConsensusEquipment.fromJson)
          .toList(growable: false);
    }

    return GymDetail(
      gym: CommunityGym.fromJson(json['gym'] as Map<String, dynamic>),
      confirmed: decode(json['confirmed']),
      reported: decode(json['reported']),
      totalReporters: (json['total_reporters'] is num)
          ? (json['total_reporters'] as num).toInt()
          : 0,
      consensusMinReporters: (json['consensus_min_reporters'] is num)
          ? (json['consensus_min_reporters'] as num).toInt()
          : 3,
    );
  }

  /// All consensus equipment names (confirmed + reported), for prefilling.
  List<String> get allEquipmentNames =>
      [...confirmed.map((e) => e.equipment), ...reported.map((e) => e.equipment)];
}

/// Dio client for the Community Gym Catalog endpoints (Feature 3B).
class CommunityGymsService {
  final ApiClient _apiClient;

  static const String _basePath = '/community-gyms';

  CommunityGymsService(this._apiClient);

  /// GET /community-gyms/nearby — gyms near a point.
  ///
  /// [query] optionally filters by name. NO mock data: an unconfigured Places
  /// key returns `catalogOnly: true` with the local canonical catalog only.
  Future<NearbyGymsResult> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    String? query,
  }) async {
    try {
      debugPrint('🏋️ [CommunityGyms] nearby ($latitude,$longitude) r=$radiusMeters');
      final response = await _apiClient.get(
        '$_basePath/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_meters': radiusMeters,
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        },
      );
      if (response.statusCode == 200) {
        return NearbyGymsResult.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load nearby gyms: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [CommunityGyms] nearby error: $e');
      rethrow;
    }
  }

  /// GET /community-gyms/{placeId} — gym + consensus equipment.
  Future<GymDetail> detail(String placeId) async {
    try {
      final response = await _apiClient.get('$_basePath/$placeId');
      if (response.statusCode == 200) {
        return GymDetail.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load gym detail: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [CommunityGyms] detail error: $e');
      rethrow;
    }
  }

  /// POST /community-gyms/{placeId}/report — upsert this user's equipment report.
  ///
  /// Returns the refreshed [GymDetail] (consensus may have changed). Optional
  /// gym metadata seeds the canonical row when reaching it outside nearby.
  Future<GymDetail> report({
    required String placeId,
    required List<String> equipment,
    List<Map<String, dynamic>> equipmentDetails = const [],
    String source = 'manual',
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('🏋️ [CommunityGyms] report $placeId (${equipment.length} items)');
      final response = await _apiClient.post(
        '$_basePath/$placeId/report',
        data: {
          'equipment': equipment,
          'equipment_details': equipmentDetails,
          'source': source,
          if (name != null) 'name': name,
          if (address != null) 'address': address,
          if (city != null) 'city': city,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      if (response.statusCode == 200) {
        return GymDetail.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to report equipment: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [CommunityGyms] report error: $e');
      rethrow;
    }
  }

  /// POST /community-gyms/{placeId}/adopt — create a gym profile prefilled from
  /// the gym's consensus equipment. Returns the created [GymProfile].
  Future<GymProfile> adopt({
    required String placeId,
    required String userId,
    String? name,
    bool confirmedOnly = false,
  }) async {
    try {
      debugPrint('🏋️ [CommunityGyms] adopt $placeId for user $userId');
      final response = await _apiClient.post(
        '$_basePath/$placeId/adopt',
        queryParameters: {'user_id': userId},
        data: {
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          'confirmed_only': confirmedOnly,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GymProfile.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to adopt gym: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [CommunityGyms] adopt error: $e');
      rethrow;
    }
  }
}
