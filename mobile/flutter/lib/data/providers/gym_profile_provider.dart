import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../utils/tz.dart';
import '../models/gym_profile.dart';
import '../repositories/gym_profile_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/data_cache_service.dart';
import 'today_workout_provider.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
List<GymProfile>? _gymProfilesInMemoryCache;

/// True once the first cache-read has completed (hit or miss). Before this,
/// a `data([])` state means "cache still loading"; after, it means "user
/// really has no gyms". The header uses this to show a shimmer vs the
/// "Add gym" CTA.
bool _gymProfilesCacheChecked = false;

/// Provider exposing whether the gym profile cache has been read at least
/// once. Flipped to true by `_loadFromCache`.
final gymProfilesCacheCheckedProvider = StateProvider<bool>((ref) {
  return _gymProfilesCacheChecked;
});

/// Provider for the list of gym profiles for the current user
///
/// Features:
/// - Cache-first: Shows cached profiles instantly on app open
/// - Background refresh: Fetches fresh data silently
/// - Auto-creates a default profile if none exist
// Track the user_id this provider's static caches belong to so we can flush
// them on a true user-id change (sign-out → sign-in different account) and
// avoid one user's "cache checked, list empty" verdict locking the next
// user into "+ Add gym".
String? _gymProfilesCacheOwnerUserId;

final gymProfilesProvider =
    StateNotifierProvider<GymProfilesNotifier, AsyncValue<List<GymProfile>>>(
        (ref) {
  final repository = ref.watch(gymProfileRepositoryProvider);
  // Watch by user_id only — the AuthState object is recreated on every
  // emission (token refresh, profile copyWith, etc.) and a whole-object
  // ref.watch caused the notifier to be disposed mid-fetch, stranding the
  // UI in `data([])` → "+ Add gym" forever. `select` short-circuits when
  // the actual id string doesn't change. See plan §3A.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _gymProfilesCacheOwnerUserId) {
    // Real user-id change → flush the static "cache-checked" verdict and
    // the static in-memory cache so the new user gets a fresh shimmer-then-
    // fetch cycle, not the old user's empty-list residue.
    _gymProfilesCacheOwnerUserId = userId;
    _gymProfilesCacheChecked = false;
    _gymProfilesInMemoryCache = null;
  }
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

/// Provides the active gym profile's Color for MaterialApp theme override.
///
/// Returns null when no gym profiles exist (app falls back to accentColorProvider).
/// Priority: active gym profile color > user accent color selection.
final gymAccentColorProvider = Provider<Color?>((ref) {
  final activeProfile = ref.watch(activeGymProfileProvider);
  return activeProfile?.profileColor;
});

/// State notifier for managing gym profiles with cache-first pattern
class GymProfilesNotifier extends StateNotifier<AsyncValue<List<GymProfile>>> {
  final GymProfileRepository _repository;
  final String? _userId;
  final Ref _ref;
  bool _disposed = false;
  bool _hasAutoRetried = false;
  // Guard so the "no gyms → create a default from onboarding equipment" seed
  // runs at most once per notifier lifetime, and never on a fetch ERROR — this
  // prevents duplicate-gym races if the server briefly returns empty.
  bool _didAutoSeedDefault = false;

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    super.dispose();
  }

  GymProfilesNotifier(this._repository, this._userId, this._ref)
      : super(
          // Start with in-memory cache if available (instant, no loading flash).
          // Otherwise seed with an empty list so the header can paint its
          // empty-state placeholder immediately instead of flashing a
          // "Loading gym…" spinner — the persistent-cache rehydration
          // happens microseconds later and swaps in the real data.
          _gymProfilesInMemoryCache != null
              ? AsyncValue.data(_gymProfilesInMemoryCache!)
              : const AsyncValue.data(<GymProfile>[]),
        ) {
    if (_userId != null) {
      // If we have in-memory cache, just fetch fresh data in background
      if (_gymProfilesInMemoryCache != null) {
        debugPrint('⚡ [GymProfileProvider] Using in-memory cache (instant)');
        _fetchFromApi(showLoading: false);
      } else {
        // No in-memory cache — hydrate from persistent cache without
        // flipping into `loading`, then revalidate in background.
        _loadWithCacheFirst(showLoadingOnCacheMiss: false);
      }
      _startStuckStateWatchdog();
    }
  }

  Timer? _watchdog;

  /// Watchdog (plan §3D): if state is still `data([])` after 5s with a real
  /// user_id and no in-flight fetch, force a fresh fetch with the loading
  /// flag set so the widget renders a spinner instead of stranding the user
  /// at "+ Add gym" forever. Catches any race we didn't anticipate.
  void _startStuckStateWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 5), () {
      if (_disposed) return;
      final v = state.valueOrNull;
      if (v != null && v.isEmpty && _userId != null && !_isFetchInFlight) {
        debugPrint('🐶 [GymProfileProvider] Watchdog fired — state stuck at data([]), forcing refresh');
        _fetchFromApi(showLoading: true);
      }
    });
  }

  bool _isFetchInFlight = false;

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _gymProfilesInMemoryCache = null;
    debugPrint('🧹 [GymProfileProvider] In-memory cache cleared');
  }

  /// Load profiles with cache-first pattern.
  /// [showLoadingOnCacheMiss]: when false, the header paints its empty
  /// state (no "Loading gym…" text) while we silently revalidate —
  /// preferred for the cold-start home paint.
  Future<void> _loadWithCacheFirst({bool showLoadingOnCacheMiss = true}) async {
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
    final cacheMiss = cachedProfiles == null || cachedProfiles.isEmpty;
    await _fetchFromApi(showLoading: cacheMiss && showLoadingOnCacheMiss);
  }

  /// Load cached profiles from persistent storage
  /// Also updates in-memory cache for future instant access
  Future<List<GymProfile>?> _loadFromCache() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.gymProfilesKey,
        userId: _userId,
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
    } finally {
      // Regardless of hit/miss/parse-error, the cache has now been checked.
      // The header uses this to differentiate "still loading" from "user
      // really has no gyms" so we don't flash "Add gym" at cold start.
      _gymProfilesCacheChecked = true;
      try {
        _ref.read(gymProfilesCacheCheckedProvider.notifier).state = true;
      } catch (_) {
        // Ref may be disposed (provider torn down); ignore.
      }
    }
    return null;
  }

  /// Save profiles to cache (both in-memory and persistent)
  Future<void> _saveToCache(List<GymProfile> profiles) async {
    // PLAN §3E: refuse to overwrite a non-empty in-memory cache with an
    // empty list. An empty fetch result is "no data right now" — keep the
    // prior non-empty cache so the next provider boot doesn't seed with
    // a poisoned empty list and show "+ Add gym" forever. Only the FIRST
    // cache write (cold install) is allowed to seed `[]`.
    if (profiles.isEmpty &&
        _gymProfilesInMemoryCache != null &&
        _gymProfilesInMemoryCache!.isNotEmpty) {
      debugPrint('🛡️ [GymProfileProvider] Refused to overwrite cached profiles with empty list');
      return;
    }
    // Update in-memory cache FIRST for instant access on provider recreation
    _gymProfilesInMemoryCache = profiles;

    try {
      await DataCacheService.instance.cache(
        DataCacheService.gymProfilesKey,
        {
          'profiles': profiles.map((p) => p.toJson()).toList(),
          'cached_at': Tz.timestamp(),
        },
        userId: _userId,
      );
    } catch (e) {
      debugPrint('⚠️ [GymProfileProvider] Cache save error: $e');
    }
  }

  /// Fetch fresh profiles from API
  Future<void> _fetchFromApi({bool showLoading = false}) async {
    if (_userId == null || _disposed) {
      // PLAN §3 tertiary-defect: do NOT wipe a populated state when user_id
      // transitions briefly to null (e.g. token refresh emitting an
      // intermediate unauthenticated AuthState). Only wipe if we're not
      // currently showing real data — otherwise a stale-but-correct view is
      // better than flashing "+ Add gym". On real sign-out, clearAll() in
      // auth_repository handles the wipe.
      if (!_disposed && !state.hasValue) {
        state = const AsyncValue.data([]);
      }
      return;
    }

    _isFetchInFlight = true;
    try {
      if (showLoading) {
        state = const AsyncValue.loading();
      }
      debugPrint('🔄 [GymProfileProvider] Loading profiles for user: $_userId');

      final response = await _repository.getProfiles(_userId);
      if (_disposed) return;
      state = AsyncValue.data(response.profiles);

      // Save to cache for next app open
      await _saveToCache(response.profiles);

      // First-run self-heal: onboarding saves the user's equipment to their
      // preferences but never creates a gym_profiles row, so a fresh account
      // lands on "+ Add gym". If the server genuinely has zero gyms, seed a
      // default from the equipment/environment onboarding already collected so
      // the Workout tab shows the user's gym immediately. Guarded, fire-and-
      // forget (must not run on the error path).
      if (response.profiles.isEmpty) {
        unawaited(_maybeAutoSeedDefaultProfile());
      }

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
      // Notifier may have been disposed while the request was in flight
      // (user navigated away before the connection timeout fired). Touching
      // `state` after dispose throws "Tried to use GymProfilesNotifier after
      // dispose was called" → short-circuit before reading or writing state.
      if (_disposed) return;
      // PLAN §3E: previously, errors were silently swallowed when state was
      // ALREADY `data([])` (state.hasValue=true with an empty list). That
      // path stranded the user at "+ Add gym" with no UI signal. An empty
      // list is not a valid known answer when we haven't successfully
      // completed a fetch — surface the error so the widget shows a retry
      // CTA.
      final currentList = state.valueOrNull;
      final stateIsEmptyButUnverified =
          state.hasValue && (currentList == null || currentList.isEmpty);
      if (!state.hasValue || stateIsEmptyButUnverified) {
        state = AsyncValue.error(e, stack);
        // Auto-retry once after 3 seconds (handles cold-start failures)
        if (!_hasAutoRetried) {
          _hasAutoRetried = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (!_disposed) _fetchFromApi(showLoading: false);
          });
        }
      }
    } finally {
      _isFetchInFlight = false;
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

  /// Create a new gym profile and immediately make it the active one.
  ///
  /// Why auto-activate: the user just curated a name + icon + color +
  /// equipment for this gym; making them tap a separate "switch to it"
  /// step before the app reflects their work surprises them. Mirrors
  /// every other product (Spotify "Add device", Slack "Create workspace")
  /// which auto-selects the freshly-created entity.
  Future<GymProfile?> createProfile(GymProfileCreate profile) async {
    if (_userId == null) return null;

    try {
      debugPrint('➕ [GymProfileProvider] Creating profile: ${profile.name}');

      final created = await _repository.createProfile(_userId, profile);

      // Optimistic local state: demote every other profile, mark the new
      // one active. The server-side activate call below confirms it; if
      // it fails we revert by refetching.
      state.whenData((profiles) {
        final demoted = profiles.map((p) => p.copyWith(isActive: false)).toList();
        final activated = created.copyWith(isActive: true);
        final newProfiles = [...demoted, activated];
        state = AsyncValue.data(newProfiles);
        _saveToCache(newProfiles);
      });

      // Confirm server-side. Failure here is recoverable (next refresh
      // will pull the truth) — don't block the create on it.
      try {
        await _repository.activateProfile(created.id);
      } catch (e) {
        debugPrint('⚠️ [GymProfileProvider] activateProfile failed (non-fatal): $e');
      }

      debugPrint('✅ [GymProfileProvider] Profile created and activated: ${created.name}');
      return created;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error creating profile: $e');
      rethrow;
    }
  }

  /// Seed a default gym profile when the authenticated user has none — the
  /// self-heal for the "Add gym after onboarding" gap (onboarding stores
  /// equipment on the user's preferences but no gym_profiles row). Runs at most
  /// once per notifier lifetime, only after a SUCCESSFUL empty API fetch (never
  /// on error), so it can't create duplicates or fight a transient empty state.
  Future<void> _maybeAutoSeedDefaultProfile() async {
    if (_didAutoSeedDefault || _disposed || _userId == null) return;
    // Re-check: only when the server genuinely reported zero gyms.
    if ((state.valueOrNull ?? const <GymProfile>[]).isNotEmpty) return;

    // The user object carries the equipment/environment onboarding saved. If
    // it isn't hydrated yet (id known from cache but full profile still
    // loading), skip WITHOUT setting the guard so a later fetch — the 5s
    // stuck-state watchdog, a refresh, or a re-fetch — retries once we can
    // seed the gym from the user's real setup rather than an empty placeholder.
    final user = _ref.read(authStateProvider).user;
    if (user == null) return;

    _didAutoSeedDefault = true;

    // Seed from what onboarding already saved on the user so the first gym
    // reflects the real setup instead of an empty placeholder.
    final equipment = user.equipmentList;
    final environment = user.workoutEnvironment ?? 'commercial_gym';

    try {
      await createProfile(GymProfileCreate(
        name: 'My Gym',
        workoutEnvironment: environment,
        equipment: equipment,
      ));
      debugPrint(
          '🌱 [GymProfileProvider] Auto-created default gym from onboarding equipment (${equipment.length} items, env=$environment)');
    } catch (e) {
      // Leave the guard set — a manual refresh / next app launch retries.
      debugPrint('⚠️ [GymProfileProvider] Auto-seed default gym failed: $e');
    }
  }

  /// Update an existing profile
  Future<GymProfile?> updateProfile(
    String profileId,
    GymProfileUpdate update,
  ) async {
    try {
      debugPrint('✏️ [GymProfileProvider] Updating profile: $profileId');

      // Snapshot the previous active profile so we can detect equipment /
      // environment changes that should invalidate cached workouts.
      final previousActive = state.valueOrNull
          ?.where((p) => p.id == profileId)
          .firstOrNull;

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

      // If the active profile's equipment or environment changed, the cached
      // today/upcoming workouts were generated against stale equipment —
      // invalidate so generation re-evaluates against the new set. Without
      // this, equipment edits look saved (server-side) but the UI keeps
      // showing the old plan until the next manual refresh.
      if (updated.isActive && previousActive != null) {
        final equipmentChanged = !_listEq(previousActive.equipment, updated.equipment);
        final detailsChanged = !_detailsEq(
          previousActive.equipmentDetails,
          updated.equipmentDetails,
        );
        final envChanged =
            previousActive.workoutEnvironment != updated.workoutEnvironment;
        if (equipmentChanged || detailsChanged || envChanged) {
          debugPrint(
              '🔄 [GymProfileProvider] Equipment/env changed on active profile — invalidating workout caches');
          _invalidateWorkoutCaches();
        }
      }

      debugPrint('✅ [GymProfileProvider] Profile updated: ${updated.name}');
      return updated;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error updating profile: $e');
      rethrow;
    }
  }

  /// Invalidate the today + all-workouts caches so the next read regenerates
  /// against the current gym profile equipment.
  void _invalidateWorkoutCaches() {
    try {
      _ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
    } catch (e) {
      debugPrint('⚠️ [GymProfileProvider] todayWorkoutProvider invalidate failed: $e');
    }
    try {
      _ref.read(workoutsProvider.notifier).silentRefresh();
    } catch (e) {
      debugPrint('⚠️ [GymProfileProvider] workoutsProvider refresh failed: $e');
    }
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = {...a};
    final sb = {...b};
    return sa.length == sb.length && sa.containsAll(sb);
  }

  static bool _detailsEq(
    List<Map<String, dynamic>>? a,
    List<Map<String, dynamic>>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    String key(Map<String, dynamic> m) =>
        '${m['name']}|${m['quantity']}|${(m['weights'] ?? []).join(',')}';
    final ka = a.map(key).toList()..sort();
    final kb = b.map(key).toList()..sort();
    for (var i = 0; i < ka.length; i++) {
      if (ka[i] != kb[i]) return false;
    }
    return true;
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

  /// Whether the currently-active profile is the bodyweight Travel/Hotel
  /// profile (Feature 3B). Used by UI to surface "bodyweight combined" copy.
  bool get isTravelManagedActive {
    final profiles = state.valueOrNull;
    if (profiles == null) return false;
    for (final p in profiles) {
      if (p.isActive) return p.isTravelManaged;
    }
    return false;
  }

  /// One-tap Travel Mode (Feature 3B).
  ///
  /// Activates the user's single bodyweight Travel/Hotel profile (the backend
  /// finds-or-restores-or-creates it). Merges the returned active profile into
  /// local state exactly like [activateProfile]: demote every other profile,
  /// and either replace the existing travel row or APPEND it when this is the
  /// first time the user enters Travel Mode (the new profile won't be in the
  /// current list yet). Syncs accent + invalidates dependents.
  Future<GymProfile> activateTravelMode() async {
    if (_userId == null) {
      throw StateError('Cannot activate Travel Mode without a signed-in user');
    }
    try {
      debugPrint('🧳 [GymProfileProvider] Activating Travel Mode');

      final response = await _repository.activateTravelMode(_userId);
      final travel = response.activeProfile;

      state.whenData((profiles) {
        final exists = profiles.any((p) => p.id == travel.id);
        final List<GymProfile> newProfiles;
        if (exists) {
          newProfiles = profiles.map((p) {
            if (p.id == travel.id) return travel;
            return p.copyWith(isActive: false);
          }).toList();
        } else {
          // First Travel Mode activation — the freshly-created profile is not
          // in the cached list yet. Demote the rest and append it.
          newProfiles = [
            ...profiles.map((p) => p.copyWith(isActive: false)),
            travel,
          ];
        }
        state = AsyncValue.data(newProfiles);
        _saveToCache(newProfiles);
      });

      debugPrint('✅ [GymProfileProvider] Travel Mode active: ${travel.name}');

      // Sync accent + refresh profile-dependent workout providers.
      _syncAccentColor(travel.color);
      _invalidateWorkoutCaches();
      _invalidateProfileDependentProviders();

      return travel;
    } catch (e) {
      debugPrint('❌ [GymProfileProvider] Error activating Travel Mode: $e');
      rethrow;
    }
  }

  /// Reorder profiles
  Future<void> reorderProfiles(List<String> orderedIds) async {
    if (_userId == null) return;

    try {
      debugPrint('↕️ [GymProfileProvider] Reordering profiles');

      await _repository.reorderProfiles(_userId, orderedIds);

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
