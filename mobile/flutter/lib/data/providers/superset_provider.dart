import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/superset_preferences.dart';
import '../repositories/superset_repository.dart';
import '../../core/providers/auth_provider.dart';

/// Provider for superset preferences
/// M1: Removed autoDispose — preferences are persistent user data
final supersetPreferencesProvider = FutureProvider<SupersetPreferences>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const SupersetPreferences();
  }

  final repository = ref.watch(supersetRepositoryProvider);
  return repository.getPreferences(userId);
});

/// Provider for favorite superset pairs
/// M1: Removed autoDispose — favorites are persistent user data
final favoriteSupersetPairsProvider = FutureProvider<List<FavoriteSupersetPair>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  final repository = ref.watch(supersetRepositoryProvider);
  return repository.getFavorites(userId);
});

/// Provider for superset suggestions for a specific workout
/// M1: Removed autoDispose — suggestions should persist while viewing a workout
final supersetSuggestionsProvider = FutureProvider.family<List<SupersetSuggestion>, String>((ref, workoutId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  final repository = ref.watch(supersetRepositoryProvider);
  return repository.getSuggestions(userId, workoutId);
});

/// Provider for superset history
/// M1: Removed autoDispose — history is persistent user data
final supersetHistoryProvider = FutureProvider<List<SupersetHistoryEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  final repository = ref.watch(supersetRepositoryProvider);
  return repository.getHistory(userId);
});

/// Notifier for managing superset preferences state
class SupersetPreferencesNotifier extends StateNotifier<AsyncValue<SupersetPreferences>> {
  final SupersetRepository _repository;
  final String? _userId;

  SupersetPreferencesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_userId == null) {
      state = const AsyncValue.data(SupersetPreferences());
      return;
    }

    try {
      state = const AsyncValue.loading();
      final preferences = await _repository.getPreferences(_userId);
      state = AsyncValue.data(preferences);
    } catch (e, st) {
      debugPrint('❌ Error loading superset preferences: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(SupersetPreferences preferences) async {
    if (_userId == null) return;

    try {
      // Optimistically update, then sync with server
      state = AsyncValue.data(preferences);

      final updated = await _repository.updatePreferences(_userId, preferences);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      debugPrint('❌ Error updating superset preferences: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSupersetsEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(supersetsEnabled: enabled));
  }

  Future<void> toggleAntagonistPairs(bool enabled) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(preferAntagonistPairs: enabled));
  }

  Future<void> toggleCompoundSets(bool enabled) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(preferCompoundSets: enabled));
  }

  Future<void> setMaxSupersetPairs(int count) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(maxSupersetPairs: count));
  }

  Future<void> setSupersetRestSeconds(int seconds) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(supersetRestSeconds: seconds));
  }

  Future<void> setPostSupersetRestSeconds(int seconds) async {
    final current = state.valueOrNull ?? const SupersetPreferences();
    await updatePreferences(current.copyWith(postSupersetRestSeconds: seconds));
  }

  Future<void> refresh() async {
    await _loadPreferences();
  }
}

/// Provider for the superset preferences notifier
final supersetPreferencesNotifierProvider = StateNotifierProvider.autoDispose<SupersetPreferencesNotifier, AsyncValue<SupersetPreferences>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(supersetRepositoryProvider);
  return SupersetPreferencesNotifier(repository, userId);
});

/// Notifier for managing favorite superset pairs
class FavoriteSupersetPairsNotifier extends StateNotifier<AsyncValue<List<FavoriteSupersetPair>>> {
  final SupersetRepository _repository;
  final String? _userId;

  FavoriteSupersetPairsNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final favorites = await _repository.getFavorites(_userId);
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      debugPrint('❌ Error loading favorite pairs: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFavorite({
    required String exercise1Name,
    required String exercise2Name,
    String? exercise1Id,
    String? exercise2Id,
    SupersetPairingType pairingType = SupersetPairingType.antagonist,
    String? notes,
  }) async {
    if (_userId == null) return;

    try {
      final newFavorite = await _repository.addFavorite(
        _userId,
        exercise1Name,
        exercise2Name,
        exercise1Id: exercise1Id,
        exercise2Id: exercise2Id,
        pairingType: pairingType,
        notes: notes,
      );

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([newFavorite, ...current]);
    } catch (e, st) {
      debugPrint('❌ Error adding favorite pair: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFavorite(String pairId) async {
    if (_userId == null) return;

    try {
      await _repository.removeFavorite(_userId, pairId);

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((f) => f.id != pairId).toList());
    } catch (e, st) {
      debugPrint('❌ Error removing favorite pair: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadFavorites();
  }
}

/// Provider for the favorite pairs notifier
final favoriteSupersetPairsNotifierProvider = StateNotifierProvider.autoDispose<FavoriteSupersetPairsNotifier, AsyncValue<List<FavoriteSupersetPair>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(supersetRepositoryProvider);
  return FavoriteSupersetPairsNotifier(repository, userId);
});

/// Provider for superset stats
final supersetStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return {
      'total_supersets_completed': 0,
      'favorite_pairs_count': 0,
      'most_used_pairing_type': null,
      'average_time_saved_minutes': 0,
    };
  }

  final repository = ref.watch(supersetRepositoryProvider);
  return repository.getSupersetStats(userId);
});
