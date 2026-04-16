import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_profile.dart';
import '../services/api_client.dart';

/// Gym Profile repository provider
final gymProfileRepositoryProvider = Provider<GymProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GymProfileRepository(apiClient);
});

/// Repository for gym profile API operations
class GymProfileRepository {
  final ApiClient _apiClient;

  static const String _basePath = '/gym-profiles';

  GymProfileRepository(this._apiClient);

  /// Get all gym profiles for a user
  ///
  /// Auto-creates a default profile if none exist
  Future<GymProfileListResponse> getProfiles(String userId) async {
    try {
      debugPrint('📋 [GymProfile] Fetching profiles for user: $userId');

      final response = await _apiClient.get(
        '$_basePath/',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final listResponse = GymProfileListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint(
            '✅ [GymProfile] Fetched ${listResponse.count} profiles');
        if (listResponse.activeProfileId != null) {
          debugPrint(
              '🎯 [GymProfile] Active profile: ${listResponse.activeProfileId}');
        }
        return listResponse;
      }

      throw Exception('Failed to fetch profiles: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error fetching profiles: $e');
      rethrow;
    }
  }

  /// Get the active gym profile for a user
  ///
  /// Auto-creates a default profile if none exist
  Future<GymProfile?> getActiveProfile(String userId) async {
    try {
      debugPrint('🔍 [GymProfile] Getting active profile for user: $userId');

      final response = await _apiClient.get(
        '$_basePath/active',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final profile = GymProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Active profile: ${profile.name}');
        debugPrint('🏋️ [GymProfile] Equipment: ${profile.equipment.length} items');
        debugPrint('📍 [GymProfile] Environment: ${profile.workoutEnvironment}');
        return profile;
      }

      debugPrint('⚠️ [GymProfile] No active profile found');
      return null;
    } catch (e) {
      debugPrint('❌ [GymProfile] Error getting active profile: $e');
      rethrow;
    }
  }

  /// Get a single gym profile by ID
  Future<GymProfile> getProfile(String profileId) async {
    try {
      debugPrint('🔍 [GymProfile] Fetching profile: $profileId');

      final response = await _apiClient.get('$_basePath/$profileId');

      if (response.statusCode == 200) {
        final profile = GymProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Fetched: ${profile.name}');
        return profile;
      }

      throw Exception('Profile not found');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error fetching profile: $e');
      rethrow;
    }
  }

  /// Create a new gym profile
  Future<GymProfile> createProfile(
    String userId,
    GymProfileCreate profile,
  ) async {
    try {
      debugPrint('➕ [GymProfile] Creating profile: ${profile.name}');
      debugPrint('🏋️ [GymProfile] Equipment: ${profile.equipment}');
      debugPrint('🎨 [GymProfile] Color: ${profile.color}');

      final response = await _apiClient.post(
        '$_basePath/',
        queryParameters: {'user_id': userId},
        data: profile.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdProfile = GymProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Created: ${createdProfile.name} (${createdProfile.id})');
        return createdProfile;
      }

      throw Exception('Failed to create profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error creating profile: $e');
      rethrow;
    }
  }

  /// Update an existing gym profile
  Future<GymProfile> updateProfile(
    String profileId,
    GymProfileUpdate update,
  ) async {
    try {
      debugPrint('✏️ [GymProfile] Updating profile: $profileId');

      final response = await _apiClient.put(
        '$_basePath/$profileId',
        data: update.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedProfile = GymProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Updated: ${updatedProfile.name}');
        return updatedProfile;
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error updating profile: $e');
      rethrow;
    }
  }

  /// Delete a gym profile
  ///
  /// Cannot delete the last profile - users must have at least one
  Future<void> deleteProfile(String profileId) async {
    try {
      debugPrint('🗑️ [GymProfile] Deleting profile: $profileId');

      final response = await _apiClient.delete('$_basePath/$profileId');

      if (response.statusCode == 200) {
        debugPrint('✅ [GymProfile] Profile deleted');
        return;
      }

      throw Exception('Failed to delete profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error deleting profile: $e');
      rethrow;
    }
  }

  /// Activate (switch to) a gym profile
  ///
  /// Deactivates all other profiles and sets this one as active
  Future<ActivateProfileResponse> activateProfile(String profileId) async {
    try {
      debugPrint('🔄 [GymProfile] Activating profile: $profileId');

      final response = await _apiClient.post(
        '$_basePath/$profileId/activate',
      );

      if (response.statusCode == 200) {
        final activateResponse = ActivateProfileResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Activated: ${activateResponse.activeProfile.name}');
        debugPrint('🏋️ [GymProfile] Active equipment: ${activateResponse.activeProfile.equipment.length} items');
        debugPrint('🎯 [GymProfile] Environment: ${activateResponse.activeProfile.workoutEnvironment}');
        return activateResponse;
      }

      throw Exception('Failed to activate profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error activating profile: $e');
      rethrow;
    }
  }

  /// Reorder gym profiles
  ///
  /// Updates the display order based on the provided list of profile IDs
  Future<void> reorderProfiles(String userId, List<String> orderedIds) async {
    try {
      debugPrint('↕️ [GymProfile] Reordering ${orderedIds.length} profiles');

      final response = await _apiClient.post(
        '$_basePath/reorder/',
        queryParameters: {'user_id': userId},
        data: {'profile_ids': orderedIds},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [GymProfile] Profiles reordered');
        return;
      }

      throw Exception('Failed to reorder profiles: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error reordering profiles: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // AI Gym-Equipment Importer (see plan: pure-swinging-lighthouse.md)
  // ---------------------------------------------------------------------------

  /// Kick off an async equipment-import job for a gym profile.
  ///
  /// Backend contract (POST /api/v1/gym-profiles/{id}/import-equipment):
  ///   {source: "file",   s3_key, mime_type}
  ///   {source: "images", s3_keys}
  ///   {source: "text",   raw_text}
  ///   {source: "url",    url}
  ///
  /// Returns a job handle that the caller polls via [pollMediaJob].
  ///
  /// Edge cases handled explicitly:
  /// - 404 → profile not found (likely not yet persisted; caller must create
  ///   the profile first and retry).
  /// - 422 → bad payload (malformed s3_key / empty text). We surface the
  ///   raw validation detail so the UI can show it.
  /// - 503 → backend degraded (Gemini down). UI should offer retry.
  Future<ImportJobResponse> importEquipment({
    required String gymProfileId,
    required ImportSource source,
  }) async {
    try {
      final body = source.toJson();
      debugPrint('🏋️ [GymProfile] Import equipment: profile=$gymProfileId '
          'source=${source.kind}');

      final response = await _apiClient.post(
        '$_basePath/$gymProfileId/import-equipment',
        data: body,
        // Backend is async — it returns immediately with a job_id. Short
        // timeout is fine (no Gemini inline).
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = response.data as Map<String, dynamic>;
        final job = ImportJobResponse.fromJson(data);
        debugPrint('✅ [GymProfile] Import job queued: ${job.jobId}');
        return job;
      }

      throw Exception(
          'Failed to start import (HTTP ${response.statusCode}): ${response.statusMessage}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error starting import: $e');
      rethrow;
    }
  }

  /// Poll a media-analysis job by id.
  ///
  /// Returns the latest [MediaJobStatus]. Callers decide when to stop polling
  /// based on `status in {completed, failed}` or a wall-clock timeout.
  Future<MediaJobStatus> pollMediaJob(String jobId) async {
    try {
      final response = await _apiClient.get('/media-jobs/$jobId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = MediaJobStatus.fromJson(data);
        debugPrint('🔍 [GymProfile] Job $jobId → ${status.status}');
        return status;
      }
      throw Exception('Job poll failed: HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error polling job $jobId: $e');
      rethrow;
    }
  }

  /// Duplicate a gym profile
  ///
  /// Creates a copy of the profile with the specified name (or "(Copy)" appended if not provided).
  /// The duplicated profile is NOT active by default.
  /// Throws an exception if a profile with the same name already exists.
  Future<GymProfile> duplicateProfile(String profileId, {String? newName}) async {
    try {
      debugPrint('📋 [GymProfile] Duplicating profile: $profileId${newName != null ? ' with name: $newName' : ''}');

      final response = await _apiClient.post(
        '$_basePath/$profileId/duplicate',
        data: newName != null ? {'name': newName} : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final duplicatedProfile = GymProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [GymProfile] Duplicated to: ${duplicatedProfile.name} (${duplicatedProfile.id})');
        return duplicatedProfile;
      }

      throw Exception('Failed to duplicate profile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [GymProfile] Error duplicating profile: $e');
      rethrow;
    }
  }
}

// =============================================================================
// AI Gym-Equipment Importer — models
// =============================================================================
//
// Plain Dart classes (no freezed / json_serializable) because:
//   * this file is not currently using code-gen, and
//   * build_runner is forbidden by project policy (Flutter 3.38.10 pin).
//
// Tradeoff: hand-written fromJson/toJson. Kept minimal and defensive —
// unknown / missing fields default to sensible empty values instead of
// throwing, because the backend runs async and may return partial rows
// while the job is still in-flight.

/// Possible equipment-import input kinds. One of these is posted to
/// POST /api/v1/gym-profiles/{id}/import-equipment.
enum ImportSourceKind { file, images, text, url }

extension ImportSourceKindX on ImportSourceKind {
  String get wire {
    switch (this) {
      case ImportSourceKind.file:
        return 'file';
      case ImportSourceKind.images:
        return 'images';
      case ImportSourceKind.text:
        return 'text';
      case ImportSourceKind.url:
        return 'url';
    }
  }
}

/// Sealed-style variant wrapper for the four supported import inputs.
///
/// Use the named constructors to build one; the resulting object serializes
/// to the backend payload via [toJson].
class ImportSource {
  final ImportSourceKind kind;

  /// source=file
  final String? s3Key;
  final String? mimeType;

  /// source=images
  final List<String>? s3Keys;

  /// source=text
  final String? rawText;

  /// source=url
  final String? url;

  const ImportSource._({
    required this.kind,
    this.s3Key,
    this.mimeType,
    this.s3Keys,
    this.rawText,
    this.url,
  });

  factory ImportSource.file({required String s3Key, required String mimeType}) {
    assert(s3Key.isNotEmpty, 's3Key must not be empty');
    return ImportSource._(
      kind: ImportSourceKind.file,
      s3Key: s3Key,
      mimeType: mimeType,
    );
  }

  factory ImportSource.images({required List<String> s3Keys}) {
    assert(s3Keys.isNotEmpty, 's3Keys must not be empty');
    return ImportSource._(kind: ImportSourceKind.images, s3Keys: s3Keys);
  }

  factory ImportSource.text({required String rawText}) {
    assert(rawText.trim().isNotEmpty, 'rawText must not be blank');
    return ImportSource._(kind: ImportSourceKind.text, rawText: rawText);
  }

  factory ImportSource.url({required String url}) {
    assert(url.trim().isNotEmpty, 'url must not be blank');
    return ImportSource._(kind: ImportSourceKind.url, url: url);
  }

  Map<String, dynamic> toJson() {
    switch (kind) {
      case ImportSourceKind.file:
        return {'source': kind.wire, 's3_key': s3Key, 'mime_type': mimeType};
      case ImportSourceKind.images:
        return {'source': kind.wire, 's3_keys': s3Keys};
      case ImportSourceKind.text:
        return {'source': kind.wire, 'raw_text': rawText};
      case ImportSourceKind.url:
        return {'source': kind.wire, 'url': url};
    }
  }
}

/// Response from POST /import-equipment — just a handle to poll.
class ImportJobResponse {
  final String jobId;
  final String status; // typically "pending"

  const ImportJobResponse({required this.jobId, required this.status});

  factory ImportJobResponse.fromJson(Map<String, dynamic> json) {
    return ImportJobResponse(
      jobId: json['job_id'] as String,
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}

/// Status of a media-analysis job as returned by GET /media-jobs/{id}.
///
/// The full `result_json` is only populated when status == "completed".
/// We expose it as a strongly-typed [ExtractedEquipmentResult] but also keep
/// the raw map so callers can render forward-compatible fields we haven't
/// mapped yet.
class MediaJobStatus {
  final String id;
  final String status; // pending | processing | completed | failed
  final String? errorMessage;
  final Map<String, dynamic>? resultJson;
  final ExtractedEquipmentResult? equipmentResult;

  const MediaJobStatus({
    required this.id,
    required this.status,
    this.errorMessage,
    this.resultJson,
    this.equipmentResult,
  });

  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'cancelled';
  bool get isSuccess => status == 'completed';

  factory MediaJobStatus.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result_json'];
    Map<String, dynamic>? resultJson;
    ExtractedEquipmentResult? equipmentResult;
    if (rawResult is Map<String, dynamic>) {
      resultJson = rawResult;
      // Best-effort decode. If the backend ever ships a schema shift, we
      // surface the raw map to the UI instead of crashing.
      try {
        equipmentResult = ExtractedEquipmentResult.fromJson(rawResult);
      } catch (e) {
        debugPrint('⚠️ [GymProfile] Could not decode result_json: $e');
      }
    }
    return MediaJobStatus(
      id: json['id'] as String,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      resultJson: resultJson,
      equipmentResult: equipmentResult,
    );
  }
}

/// One row inside the matched / unmatched lists emitted by the extractor.
class ExtractedEquipment {
  /// Canonical equipment name from our taxonomy (e.g. "dumbbells").
  /// Empty for unmatched rows.
  final String canonical;

  /// Raw string extracted from the source document.
  final String raw;

  /// Extractor confidence 0.0 – 1.0.
  final double confidence;

  /// Optional quantity (e.g. "6" dumbbells).
  final int? quantity;

  /// Optional weight range (e.g. "5-100 lb").
  final String? weightRange;

  const ExtractedEquipment({
    required this.canonical,
    required this.raw,
    required this.confidence,
    this.quantity,
    this.weightRange,
  });

  factory ExtractedEquipment.fromJson(Map<String, dynamic> json) {
    // Edge case: confidence may come back as int (1) or double (0.95) or null.
    final conf = json['confidence'];
    final confidence = conf is num ? conf.toDouble() : 0.0;
    return ExtractedEquipment(
      canonical: (json['canonical'] as String?) ?? '',
      raw: (json['raw'] as String?) ?? '',
      confidence: confidence.clamp(0.0, 1.0),
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : null,
      weightRange: json['weight_range'] as String?,
    );
  }
}

/// Decoded payload of `result_json` when status == "completed".
class ExtractedEquipmentResult {
  final List<ExtractedEquipment> matched;
  final List<ExtractedEquipment> unmatched;
  final String? inferredEnvironment; // commercial_gym | home_gym | ...
  final int totalExtracted;

  const ExtractedEquipmentResult({
    required this.matched,
    required this.unmatched,
    required this.inferredEnvironment,
    required this.totalExtracted,
  });

  factory ExtractedEquipmentResult.fromJson(Map<String, dynamic> json) {
    List<ExtractedEquipment> decode(Object? v) {
      if (v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(ExtractedEquipment.fromJson)
          .toList(growable: false);
    }

    return ExtractedEquipmentResult(
      matched: decode(json['matched']),
      unmatched: decode(json['unmatched']),
      inferredEnvironment: json['inferred_environment'] as String?,
      totalExtracted: (json['total_extracted'] is num)
          ? (json['total_extracted'] as num).toInt()
          : 0,
    );
  }
}
