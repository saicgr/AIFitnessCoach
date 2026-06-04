import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Canonical excluded-muscle vocabulary. Lowercased — the backend
/// (`/scores/stale-muscles`, workout generation) reads
/// `preferences.excluded_muscles` as a lowercased list and skips these groups
/// when generating workouts AND when nudging about stale strength scores.
///
/// Keep in lockstep with the backend vocab in
/// `backend/api/v1/scores_breakdown.py` / the workout generator.
const List<String> kExcludableMuscleGroups = <String>[
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'forearms',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'core',
  'traps',
];

/// Human-facing label for an excludable-muscle key.
String excludedMuscleDisplayName(String key) {
  switch (key) {
    case 'quads':
      return 'Quads';
    case 'hamstrings':
      return 'Hamstrings';
    case 'glutes':
      return 'Glutes';
    case 'calves':
      return 'Calves';
    case 'core':
      return 'Core';
    case 'traps':
      return 'Traps';
    default:
      // chest → Chest, back → Back, etc.
      return key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
  }
}

/// State holder for the user's excluded muscles (a set of lowercased keys).
class ExcludedMusclesState {
  final Set<String> muscles;
  final bool isLoading;
  final String? error;

  const ExcludedMusclesState({
    this.muscles = const {},
    this.isLoading = false,
    this.error,
  });

  ExcludedMusclesState copyWith({
    Set<String>? muscles,
    bool? isLoading,
    String? error,
  }) {
    return ExcludedMusclesState(
      muscles: muscles ?? this.muscles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Reads + writes `preferences.excluded_muscles` (a lowercased JSONB list on
/// `users.preferences`). The backend already honors this list when generating
/// workouts and when deciding which muscle strength-scores are "stale".
///
/// Persistence uses the established `PUT /users/{id}` path with a merged
/// `preferences` JSON string — the same pattern `training_preferences_provider`
/// / the per-day overrides sheet use. We re-read the FULL current prefs and
/// only set the `excluded_muscles` key so no other preference is clobbered.
final excludedMusclesProvider = StateNotifierProvider<ExcludedMusclesNotifier,
    ExcludedMusclesState>((ref) {
  return ExcludedMusclesNotifier(ref);
});

class ExcludedMusclesNotifier extends StateNotifier<ExcludedMusclesState> {
  final Ref _ref;

  ExcludedMusclesNotifier(this._ref) : super(const ExcludedMusclesState()) {
    _init();
  }

  Map<String, dynamic> _parsePrefs(String? prefsJson) {
    if (prefsJson == null || prefsJson.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(prefsJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Set<String> _readExcluded(Map<String, dynamic> prefs) {
    final raw = prefs['excluded_muscles'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  /// Load from the in-memory user profile (already hydrated at app start).
  void _init() {
    try {
      final user = _ref.read(authStateProvider).user;
      if (user == null) {
        state = const ExcludedMusclesState();
        return;
      }
      final prefs = _parsePrefs(user.preferences);
      state = ExcludedMusclesState(muscles: _readExcluded(prefs));
      debugPrint(
        '🏋️ [ExcludedMuscles] Loaded ${state.muscles.length}: ${state.muscles}',
      );
    } catch (e) {
      debugPrint('❌ [ExcludedMuscles] Init error: $e');
      state = ExcludedMusclesState(error: e.toString());
    }
  }

  /// Re-read from the (possibly refreshed) user profile.
  void refresh() => _init();

  /// Toggle a single muscle in/out of the excluded set and persist.
  Future<void> toggle(String muscle) async {
    final key = muscle.trim().toLowerCase();
    if (!kExcludableMuscleGroups.contains(key)) return;
    final next = Set<String>.from(state.muscles);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    await setMuscles(next);
  }

  /// Replace the full excluded set and persist to the backend.
  Future<void> setMuscles(Set<String> muscles) async {
    final normalized = muscles
        .map((m) => m.trim().toLowerCase())
        .where((m) => kExcludableMuscleGroups.contains(m))
        .toSet();

    final previous = state.muscles;
    // Optimistic update for instant UI.
    state = state.copyWith(muscles: normalized, isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        throw Exception('No user id');
      }

      // Merge into the FULL current prefs so we never clobber other keys.
      final user = _ref.read(authStateProvider).user;
      final prefs = _parsePrefs(user?.preferences);
      // Deterministic order (matches vocab order) — stable list for the server.
      prefs['excluded_muscles'] = kExcludableMuscleGroups
          .where((m) => normalized.contains(m))
          .toList();

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {'preferences': jsonEncode(prefs)},
      );

      // Refresh the profile so the in-memory user mirrors persisted prefs.
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(muscles: normalized, isLoading: false);
      debugPrint('🏋️ [ExcludedMuscles] Saved: ${prefs['excluded_muscles']}');
    } catch (e) {
      // Roll back the optimistic change on failure (no silent degradation).
      debugPrint('❌ [ExcludedMuscles] Save error, rolling back: $e');
      state = state.copyWith(
        muscles: previous,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
