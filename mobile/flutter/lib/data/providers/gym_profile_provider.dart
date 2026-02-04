import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/accent_color_provider.dart';
import '../models/gym_profile.dart';
import '../repositories/gym_profile_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/data_cache_service.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
List<GymProfile>? _gymProfilesInMemoryCache;

/// Provider for the list of gym profiles for the current user
///
/// Features:
/// - Cache-first: Shows cached profiles instantly on app open
/// - Background refresh: Fetches fresh data silently
/// - Auto-creates a default profile if none exist
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

/// State notifier for managing gym profiles with cache-first pattern
class GymProfilesNotifier extends StateNotifier<AsyncValue<List<GymProfile>>> {
  final GymProfileRepository _repository;
  final String? _userId;
  final Ref _ref;

  GymProfilesNotifier(this._repository, this._userId, this._ref)
      : super(
          // Start with in-memory cache if available (instant, no loading flash)
          _gymProfilesInMemoryCache != null
              ? AsyncValue.data(_gymProfilesInMemoryCache!)
              : const AsyncValue.loading(),
        ) {
    if (_userId != null) {
      // If we have in-memory cache, just fetch fresh data in background
      if (_gymProfilesInMemoryCache != null) {
        debugPrint('⚡ [GymProfileProvider] Using in-memory cache (instant)');
        _fetchFromApi(showLoading: false);
      } else {
        _loadWithCacheFirst();
      }
    }
  }

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _gymProfilesInMemoryCache = null;
    debugPrint('🧹 [GymProfileProvider] In-memory cache cleared');
  }

  /// Load profiles with cache-first pattern
  Future<void> _loadWithCacheFirst() async {
    // Step 1: Try to load from cache first
    final cachedProfiles = await _loadFromCache();
    if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
      debugPrint('⚡ [GymProfileProvider] Loaded ${cachedProfiles.length} profiles from cache');
      state = AsyncValue.data(cachedProfiles);

      // Sync accent color from cached active profile
      final activeProfile = cachedProfiles.firstWhere(
        (p) => p.isActive,
        orElse: () => cachedProfiles.first,
      );
      _syncAccentColor(activeProfile.color);
    }

    // Step 2: Fetch fresh data from API in background
    await _fetchFromApi(showLoading: cachedProfiles == null || cachedProfiles.isEmpty);
  }

  /// Load cached profiles from persistent storage
  /// Also updates in-memory cache for future instant access
  Future<List<GymProfile>?> _loadFromCache() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.gymProfilesKey,
      );
      if (cached != null && cached['profiles'] != null) {
        final profilesList = (cached['profiles'] as List)
            .map((p) => GymProfile.fromJson(p as Map<String, dynamic>))
            .toList();
        // Update in-memory cache for instant access on provider recreation
        _gymProfilesInMemoryCache = profilesList;
        return profilesList;
      }
    } catch (e) {
      debugPrint('⚠️ [GymProfileProvider] Cache parse error: $e');
    }
    return null;
  }

  /// Save profiles to cache (both in-memory and persistent)
  Future<void> _saveToCache(List<GymProfile> profiles) async {
    // Update in-memory cache FIRST for instant access on provider recreation
    _gymProfilesInMemoryCache = profiles;

    try {
      await DataCacheService.instance.cache(
        DataCacheService.gymProfilesKey,
        {
          'profiles': profiles.map((p) => p.toJson()).toList(),
          'cached_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('⚠️ [GymProfileProvider] Cache save error: $e');
    }
  }

  /// Fetch fresh profiles from API
  Future<void> _fetchFromApi({bool showLoading = false}) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      if (showLoading) {
        state = const AsyncValue.loading();
      }
      debugPrint('🔄 [GymProfileProvider] Loading profiles for user: $_userId');

      final response = await _repository.getProfiles(_userId!);
      state = AsyncValue.data(response.profiles);

      // Save to cache for next app open
      await _saveToCache(response.profiles);

      debugPrint('✅ [GymProfileProvider] Loaded ${response.profiles.length} profiles');
      if (response.activeProfileId != null) {
        final active = response.profiles.firstWhere(
          (p) => p.id == response.activeProfileId,
          orElse: () => response.profiles.first,
        );
        debugPrint('🎯 [GymProfileProvider] Active: ${active.name}');

        // Sync app accent color to match the active profile
        _syncAccentColor(active.color);
      }
    } catch (e, stack) {
      debugPrint('❌ [GymProfileProvider] Error loading profiles: $e');
      // Only set error state if we don't have cached data
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Load all profiles for the current user (legacy method for compatibility)
  Future<void> loadProfiles() async {
    await _fetchFromApi(showLoading: !state.hasValue);
  }

  /// Refresh profiles (pull to refresh)
  Future<void> refresh() async {
    await _fetchFromApi(showLoading: false);
  }

  /// Create a new gym profile
  Future<GymProfile?> createProfile(GymProfileCreate profile) async {
    if (_userId == null) return null;

    try {
      debugPrint('➕ [GymProfileProvider] Creating profile: ${profile.name}');

      final created = await _repository.createProfile(_userId!, profile);

      // Add to local state and cache
      state.whenData((profiles) {
        final newProfiles = [...profiles, created];
        state = AsyncValue.data(newProfiles);
        _saveToCache(newProfiles);
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

      // Update local state and cache
      state.whenData((profiles) {
        final index = profiles.indexWhere((p) => p.id == profileId);
        if (index != -1) {
          final newProfiles = [...profiles];
          newProfiles[index] = updated;
          state = AsyncValue.data(newProfiles);
          _saveToCache(newProfiles);
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

      // Remove from local state and update cache
      state.whenData((profiles) {
        final newProfiles = profiles.where((p) => p.id != profileId).toList();
        state = AsyncValue.data(newProfiles);
        _saveToCache(newProfiles);
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
        _saveToCache(newProfiles);
      });

      debugPrint('✅ [GymProfileProvider] Switched to: ${response.activeProfile.name}');
      debugPrint('🏋️ [GymProfileProvider] Active equipment: ${response.activeProfile.equipment.length} items');
      debugPrint('🎯 [GymProfileProvider] Environment: ${response.activeProfile.workoutEnvironment}');

      // Sync app accent color to match the gym profile color
      _syncAccentColor(response.activeProfile.color);

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

      // Update local state with new order and cache
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
        _saveToCache(reorderedProfiles);
      });

      debugPrint('✅ [GymProfileProvider] Profiles reordered');
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error reordering profiles: $e');
      rethrow;
    }
  }

  /// Duplicate a profile
  ///
  /// Creates a copy of the profile with the specified name (or "(Copy)" appended if not provided).
  /// The duplicated profile is NOT active by default.
  /// Throws an exception if a profile with the same name already exists.
  Future<GymProfile?> duplicateProfile(String profileId, [String? newName]) async {
    try {
      debugPrint('📋 [GymProfileProvider] Duplicating profile: $profileId${newName != null ? ' with name: $newName' : ''}');

      final duplicated = await _repository.duplicateProfile(profileId, newName: newName);

      // Add to local state and cache
      state.whenData((profiles) {
        final newProfiles = [...profiles, duplicated];
        state = AsyncValue.data(newProfiles);
        _saveToCache(newProfiles);
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

  /// Sync app accent color to match gym profile color
  ///
  /// Maps the gym profile hex color to the closest AccentColor enum value
  void _syncAccentColor(String hexColor) {
    final accentColor = _mapHexToAccentColor(hexColor);
    debugPrint('🎨 [GymProfileProvider] Syncing accent color: $hexColor -> ${accentColor.name}');
    _ref.read(accentColorProvider.notifier).setAccent(accentColor);
  }

  /// Map a hex color string to the closest AccentColor enum
  AccentColor _mapHexToAccentColor(String hexColor) {
    final normalizedHex = hexColor.toUpperCase().replaceAll('#', '');

    // Map gym profile colors to accent colors
    switch (normalizedHex) {
      case '00BCD4': // Cyan
        return AccentColor.cyan;
      case 'F97316': // Orange
      case 'FF9800': // Also orange
        return AccentColor.orange;
      case '8B5CF6': // Purple
      case '9C27B0': // Also purple
        return AccentColor.purple;
      case '10B981': // Green
      case '4CAF50': // Also green
        return AccentColor.green;
      case 'EF4444': // Red
      case 'F44336': // Also red
        return AccentColor.red;
      case 'F59E0B': // Amber
      case 'FFC107': // Also amber
        return AccentColor.amber;
      case 'EC4899': // Pink
      case 'E91E63': // Also pink
        return AccentColor.pink;
      case '6366F1': // Indigo
      case '3F51B5': // Also indigo
        return AccentColor.indigo;
      case '2196F3': // Blue
        return AccentColor.blue;
      case '009688': // Teal
        return AccentColor.teal;
      case 'CDDC39': // Lime
        return AccentColor.lime;
      default:
        // Default to orange if no match
        debugPrint('⚠️ [GymProfileProvider] Unknown color $hexColor, defaulting to orange');
        return AccentColor.orange;
    }
  }
}
