import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Superset pairing strategy
enum SupersetPairingType {
  antagonist,
  compound;

  String get displayName {
    switch (this) {
      case SupersetPairingType.antagonist:
        return 'Antagonist Pairs';
      case SupersetPairingType.compound:
        return 'Compound Sets';
    }
  }

  String get description {
    switch (this) {
      case SupersetPairingType.antagonist:
        return 'Pair opposing muscles (chest/back, biceps/triceps)';
      case SupersetPairingType.compound:
        return 'Same muscle group exercises back-to-back';
    }
  }

  String get value => name;

  static SupersetPairingType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'compound':
        return SupersetPairingType.compound;
      case 'antagonist':
      default:
        return SupersetPairingType.antagonist;
    }
  }
}

/// A saved favorite superset pair
class FavoriteSupersetPair {
  final String id;
  final String exercise1Name;
  final String exercise2Name;
  final String? exercise1Id;
  final String? exercise2Id;

  const FavoriteSupersetPair({
    required this.id,
    required this.exercise1Name,
    required this.exercise2Name,
    this.exercise1Id,
    this.exercise2Id,
  });

  factory FavoriteSupersetPair.fromJson(Map<String, dynamic> json) {
    return FavoriteSupersetPair(
      id: json['id'] as String? ?? '',
      exercise1Name: json['exercise1_name'] as String? ?? '',
      exercise2Name: json['exercise2_name'] as String? ?? '',
      exercise1Id: json['exercise1_id'] as String?,
      exercise2Id: json['exercise2_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise1_name': exercise1Name,
      'exercise2_name': exercise2Name,
      'exercise1_id': exercise1Id,
      'exercise2_id': exercise2Id,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteSupersetPair && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Superset preferences state
class SupersetPreferencesState {
  /// Whether supersets are enabled for AI-generated workouts
  final bool supersetsEnabled;

  /// Whether to prefer antagonist muscle pairings
  final bool preferAntagonistPairs;

  /// Whether to allow compound sets (same muscle group)
  final bool allowCompoundSets;

  /// Maximum number of supersets per workout (1-5)
  final int maxSupersetsPerWorkout;

  /// Rest time between exercises in a superset (seconds)
  final int restBetweenExercises;

  /// Rest time after completing a superset (seconds)
  final int restAfterSuperset;

  /// List of favorite superset pairs
  final List<FavoriteSupersetPair> favoritePairs;

  /// Loading state
  final bool isLoading;

  /// Error message
  final String? error;

  const SupersetPreferencesState({
    this.supersetsEnabled = true,
    this.preferAntagonistPairs = true,
    this.allowCompoundSets = false,
    this.maxSupersetsPerWorkout = 3,
    this.restBetweenExercises = 10,
    this.restAfterSuperset = 90,
    this.favoritePairs = const [],
    this.isLoading = false,
    this.error,
  });

  SupersetPreferencesState copyWith({
    bool? supersetsEnabled,
    bool? preferAntagonistPairs,
    bool? allowCompoundSets,
    int? maxSupersetsPerWorkout,
    int? restBetweenExercises,
    int? restAfterSuperset,
    List<FavoriteSupersetPair>? favoritePairs,
    bool? isLoading,
    String? error,
  }) {
    return SupersetPreferencesState(
      supersetsEnabled: supersetsEnabled ?? this.supersetsEnabled,
      preferAntagonistPairs: preferAntagonistPairs ?? this.preferAntagonistPairs,
      allowCompoundSets: allowCompoundSets ?? this.allowCompoundSets,
      maxSupersetsPerWorkout: maxSupersetsPerWorkout ?? this.maxSupersetsPerWorkout,
      restBetweenExercises: restBetweenExercises ?? this.restBetweenExercises,
      restAfterSuperset: restAfterSuperset ?? this.restAfterSuperset,
      favoritePairs: favoritePairs ?? this.favoritePairs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Display string for rest between exercises
  String get restBetweenExercisesDisplay {
    if (restBetweenExercises == 0) return 'No rest';
    return '${restBetweenExercises}s';
  }

  /// Display string for rest after superset
  String get restAfterSupersetDisplay => '${restAfterSuperset}s';

  /// Convert state to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'supersets_enabled': supersetsEnabled,
      'prefer_antagonist_pairs': preferAntagonistPairs,
      'allow_compound_sets': allowCompoundSets,
      'max_supersets_per_workout': maxSupersetsPerWorkout,
      'rest_between_exercises': restBetweenExercises,
      'rest_after_superset': restAfterSuperset,
      'favorite_pairs': favoritePairs.map((p) => p.toJson()).toList(),
    };
  }

  /// Create state from JSON
  factory SupersetPreferencesState.fromJson(Map<String, dynamic> json) {
    final favPairsJson = json['favorite_pairs'] as List<dynamic>? ?? [];
    final favoritePairs = favPairsJson
        .map((p) => FavoriteSupersetPair.fromJson(p as Map<String, dynamic>))
        .toList();

    return SupersetPreferencesState(
      supersetsEnabled: json['supersets_enabled'] as bool? ?? true,
      preferAntagonistPairs: json['prefer_antagonist_pairs'] as bool? ?? true,
      allowCompoundSets: json['allow_compound_sets'] as bool? ?? false,
      maxSupersetsPerWorkout: json['max_supersets_per_workout'] as int? ?? 3,
      restBetweenExercises: json['rest_between_exercises'] as int? ?? 10,
      restAfterSuperset: json['rest_after_superset'] as int? ?? 90,
      favoritePairs: favoritePairs,
    );
  }
}

/// Superset preferences provider
final supersetPreferencesProvider =
    StateNotifierProvider<SupersetPreferencesNotifier, SupersetPreferencesState>(
        (ref) {
  return SupersetPreferencesNotifier(ref);
});

/// Superset preferences notifier for managing state
class SupersetPreferencesNotifier extends StateNotifier<SupersetPreferencesState> {
  final Ref _ref;

  SupersetPreferencesNotifier(this._ref) : super(const SupersetPreferencesState()) {
    _init();
  }

  /// Parse preferences JSON string to Map
  Map<String, dynamic>? _parsePreferences(String? prefsJson) {
    if (prefsJson == null || prefsJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(prefsJson);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Initialize preferences from user profile
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        final prefsMap = _parsePreferences(authState.user!.preferences);
        if (prefsMap != null) {
          final supersetPrefs = prefsMap['superset_preferences'] as Map<String, dynamic>?;
          if (supersetPrefs != null) {
            state = SupersetPreferencesState.fromJson(supersetPrefs);
            debugPrint('   [SupersetPrefs] Loaded preferences');
            return;
          }
        }
      }
      // Use defaults if no user or no preferences
      state = const SupersetPreferencesState();
      debugPrint('   [SupersetPrefs] Using defaults');
    } catch (e) {
      debugPrint('   [SupersetPrefs] Init error: $e');
      state = SupersetPreferencesState(error: e.toString());
    }
  }

  /// Sync current state to backend
  Future<void> _syncToBackend() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        // Get current preferences
        final authState = _ref.read(authStateProvider);
        final currentPrefs = _parsePreferences(authState.user?.preferences) ?? {};

        // Update superset preferences
        currentPrefs['superset_preferences'] = state.toJson();

        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'preferences': jsonEncode(currentPrefs)},
        );
        debugPrint('   [SupersetPrefs] Synced to backend');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();
    } catch (e) {
      debugPrint('   [SupersetPrefs] Sync error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Toggle supersets enabled
  Future<void> setSupersetsEnabled(bool enabled) async {
    if (enabled == state.supersetsEnabled) return;
    state = state.copyWith(supersetsEnabled: enabled, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] supersetsEnabled = $enabled');
  }

  /// Toggle prefer antagonist pairs
  Future<void> setPreferAntagonistPairs(bool prefer) async {
    if (prefer == state.preferAntagonistPairs) return;
    state = state.copyWith(preferAntagonistPairs: prefer, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] preferAntagonistPairs = $prefer');
  }

  /// Toggle allow compound sets
  Future<void> setAllowCompoundSets(bool allow) async {
    if (allow == state.allowCompoundSets) return;
    state = state.copyWith(allowCompoundSets: allow, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] allowCompoundSets = $allow');
  }

  /// Set max supersets per workout
  Future<void> setMaxSupersetsPerWorkout(int max) async {
    final clampedMax = max.clamp(1, 5);
    if (clampedMax == state.maxSupersetsPerWorkout) return;
    state = state.copyWith(maxSupersetsPerWorkout: clampedMax, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] maxSupersetsPerWorkout = $clampedMax');
  }

  /// Set rest between exercises
  Future<void> setRestBetweenExercises(int seconds) async {
    if (seconds == state.restBetweenExercises) return;
    state = state.copyWith(restBetweenExercises: seconds, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] restBetweenExercises = $seconds');
  }

  /// Set rest after superset
  Future<void> setRestAfterSuperset(int seconds) async {
    if (seconds == state.restAfterSuperset) return;
    state = state.copyWith(restAfterSuperset: seconds, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] restAfterSuperset = $seconds');
  }

  /// Add a favorite pair
  Future<void> addFavoritePair(FavoriteSupersetPair pair) async {
    if (state.favoritePairs.contains(pair)) return;
    final newPairs = [...state.favoritePairs, pair];
    state = state.copyWith(favoritePairs: newPairs, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] Added favorite pair: ${pair.exercise1Name} + ${pair.exercise2Name}');
  }

  /// Remove a favorite pair
  Future<void> removeFavoritePair(String pairId) async {
    final newPairs = state.favoritePairs.where((p) => p.id != pairId).toList();
    if (newPairs.length == state.favoritePairs.length) return;
    state = state.copyWith(favoritePairs: newPairs, isLoading: true, error: null);
    await _syncToBackend();
    state = state.copyWith(isLoading: false);
    debugPrint('   [SupersetPrefs] Removed favorite pair: $pairId');
  }

  /// Refresh preferences from user profile
  Future<void> refresh() async {
    await _init();
  }
}
