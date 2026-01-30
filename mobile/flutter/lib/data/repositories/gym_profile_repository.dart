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
        _basePath,
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
        _basePath,
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
        '$_basePath/reorder',
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
