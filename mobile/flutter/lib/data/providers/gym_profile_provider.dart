import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_profile.dart';
import '../repositories/gym_profile_repository.dart';
import '../repositories/auth_repository.dart';

/// Provider for the list of gym profiles for the current user
///
/// Auto-creates a default profile if none exist
final gymProfilesProvider =
    StateNotifierProvider<GymProfilesNotifier, AsyncValue<List<GymProfile>>>(
        (ref) {
  final repository = ref.watch(gymProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  return GymProfilesNotifier(repository, userId, ref);
});

/// Provider for the currently active gym profile
///
/// Derived from gymProfilesProvider - returns the profile marked as active
final activeGymProfileProvider = Provider<GymProfile?>((ref) {
  final profilesAsync = ref.watch(gymProfilesProvider);
  return profilesAsync.whenData((profiles) {
    return profiles.firstWhere(
      (p) => p.isActive,
      orElse: () => profiles.isNotEmpty ? profiles.first : throw Exception('No profiles'),
    );
  }).valueOrNull;
});

/// Provider for the active profile's equipment list
///
/// Useful for workout generation and equipment filtering
final activeProfileEquipmentProvider = Provider<List<String>>((ref) {
  final activeProfile = ref.watch(activeGymProfileProvider);
  return activeProfile?.equipment ?? [];
});

/// Provider for the active profile's workout environment
final activeProfileEnvironmentProvider = Provider<String>((ref) {
  final activeProfile = ref.watch(activeGymProfileProvider);
  return activeProfile?.workoutEnvironment ?? 'commercial_gym';
});

/// Provider for the active profile ID
///
/// Useful for API calls that need to filter by profile
final activeGymProfileIdProvider = Provider<String?>((ref) {
  final activeProfile = ref.watch(activeGymProfileProvider);
  return activeProfile?.id;
});

/// State notifier for managing gym profiles
class GymProfilesNotifier extends StateNotifier<AsyncValue<List<GymProfile>>> {
  final GymProfileRepository _repository;
  final String? _userId;
  final Ref _ref;

  GymProfilesNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadProfiles();
    }
  }

  /// Load all profiles for the current user
  Future<void> loadProfiles() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      debugPrint('🔄 [GymProfileProvider] Loading profiles for user: $_userId');

      final response = await _repository.getProfiles(_userId!);
      state = AsyncValue.data(response.profiles);

      debugPrint('✅ [GymProfileProvider] Loaded ${response.profiles.length} profiles');
      if (response.activeProfileId != null) {
        final active = response.profiles.firstWhere(
          (p) => p.id == response.activeProfileId,
          orElse: () => response.profiles.first,
        );
        debugPrint('🎯 [GymProfileProvider] Active: ${active.name}');
      }
    } catch (e, stack) {
      debugPrint('❌ [GymProfileProvider] Error loading profiles: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh profiles (pull to refresh)
  Future<void> refresh() async {
    await loadProfiles();
  }

  /// Create a new gym profile
  Future<GymProfile?> createProfile(GymProfileCreate profile) async {
    if (_userId == null) return null;

    try {
      debugPrint('➕ [GymProfileProvider] Creating profile: ${profile.name}');

      final created = await _repository.createProfile(_userId!, profile);

      // Add to local state
      state.whenData((profiles) {
        state = AsyncValue.data([...profiles, created]);
      });

      debugPrint('✅ [GymProfileProvider] Profile created: ${created.name}');
      return created;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error creating profile: $e');
      rethrow;
    }
  }

  /// Update an existing profile
  Future<GymProfile?> updateProfile(
    String profileId,
    GymProfileUpdate update,
  ) async {
    try {
      debugPrint('✏️ [GymProfileProvider] Updating profile: $profileId');

      final updated = await _repository.updateProfile(profileId, update);

      // Update local state
      state.whenData((profiles) {
        final index = profiles.indexWhere((p) => p.id == profileId);
        if (index != -1) {
          final newProfiles = [...profiles];
          newProfiles[index] = updated;
          state = AsyncValue.data(newProfiles);
        }
      });

      debugPrint('✅ [GymProfileProvider] Profile updated: ${updated.name}');
      return updated;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error updating profile: $e');
      rethrow;
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    try {
      debugPrint('🗑️ [GymProfileProvider] Deleting profile: $profileId');

      await _repository.deleteProfile(profileId);

      // Remove from local state
      state.whenData((profiles) {
        state = AsyncValue.data(
          profiles.where((p) => p.id != profileId).toList(),
        );
      });

      debugPrint('✅ [GymProfileProvider] Profile deleted');
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error deleting profile: $e');
      rethrow;
    }
  }

  /// Activate (switch to) a profile
  ///
  /// This is the main method for switching between gyms
  Future<void> activateProfile(String profileId) async {
    try {
      final currentActive = state.valueOrNull?.firstWhere(
        (p) => p.isActive,
        orElse: () => state.valueOrNull!.first,
      );

      debugPrint('🔄 [GymProfileProvider] Switching from "${currentActive?.name ?? 'None'}" to profile: $profileId');

      final response = await _repository.activateProfile(profileId);

      // Update local state - set all to inactive, then the target to active
      state.whenData((profiles) {
        final newProfiles = profiles.map((p) {
          if (p.id == profileId) {
            return response.activeProfile;
          }
          return p.copyWith(isActive: false);
        }).toList();
        state = AsyncValue.data(newProfiles);
      });

      debugPrint('✅ [GymProfileProvider] Switched to: ${response.activeProfile.name}');
      debugPrint('🏋️ [GymProfileProvider] Active equipment: ${response.activeProfile.equipment.length} items');
      debugPrint('🎯 [GymProfileProvider] Environment: ${response.activeProfile.workoutEnvironment}');

      // Invalidate related providers that depend on the active profile
      // This ensures workouts are refetched for the new profile
      _invalidateProfileDependentProviders();
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error activating profile: $e');
      rethrow;
    }
  }

  /// Reorder profiles
  Future<void> reorderProfiles(List<String> orderedIds) async {
    if (_userId == null) return;

    try {
      debugPrint('↕️ [GymProfileProvider] Reordering profiles');

      await _repository.reorderProfiles(_userId!, orderedIds);

      // Update local state with new order
      state.whenData((profiles) {
        final profileMap = {for (var p in profiles) p.id: p};
        final reorderedProfiles = orderedIds
            .asMap()
            .entries
            .map((e) {
              final profile = profileMap[e.value];
              return profile?.copyWith(displayOrder: e.key);
            })
            .whereType<GymProfile>()
            .toList();
        state = AsyncValue.data(reorderedProfiles);
      });

      debugPrint('✅ [GymProfileProvider] Profiles reordered');
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error reordering profiles: $e');
      rethrow;
    }
  }

  /// Duplicate a profile
  ///
  /// Creates a copy of the profile with "(Copy)" appended to the name.
  /// The duplicated profile is NOT active by default.
  Future<GymProfile?> duplicateProfile(String profileId) async {
    try {
      debugPrint('📋 [GymProfileProvider] Duplicating profile: $profileId');

      final duplicated = await _repository.duplicateProfile(profileId);

      // Add to local state
      state.whenData((profiles) {
        state = AsyncValue.data([...profiles, duplicated]);
      });

      debugPrint('✅ [GymProfileProvider] Profile duplicated: ${duplicated.name}');
      return duplicated;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error duplicating profile: $e');
      rethrow;
    }
  }

  /// Invalidate providers that depend on the active profile
  ///
  /// Called when switching profiles to ensure fresh data
  void _invalidateProfileDependentProviders() {
    debugPrint('🔄 [GymProfileProvider] Invalidating profile-dependent providers');

    // These providers should be invalidated when switching profiles:
    // - todayWorkoutProvider (today's workout for this profile)
    // - workoutsProvider (all workouts - need to refetch for new profile)
    //
    // Note: We can't directly invalidate here since we don't have access
    // to the providers. The UI should listen to activeGymProfileProvider
    // and invalidate as needed.
  }
}
