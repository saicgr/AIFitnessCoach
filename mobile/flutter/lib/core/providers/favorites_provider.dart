import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/services/api_client.dart';

/// State for favorite exercises
class FavoritesState {
  final List<FavoriteExercise> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FavoriteExercise>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if an exercise is in favorites by name
  bool isFavorite(String exerciseName) {
    return favorites.any(
      (f) => f.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
    );
  }

  /// Get the set of favorite exercise names for quick lookup
  Set<String> get favoriteNames =>
      favorites.map((f) => f.exerciseName.toLowerCase()).toSet();
}

/// Favorites provider
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier(ref);
});

/// Notifier for managing favorite exercises state
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const FavoritesState()) {
    _init();
  }

  /// Initialize favorites from API
  Future<void> _init() async {
    await refresh();
  }

  /// Refresh favorites from API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final favorites = await repository.getFavoriteExercises(userId);

      state = state.copyWith(favorites: favorites, isLoading: false);
      debugPrint('❤️ [FavoritesProvider] Loaded ${favorites.length} favorites');
    } catch (e) {
      debugPrint('❌ [FavoritesProvider] Error loading favorites: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add an exercise to favorites
  Future<bool> addFavorite(String exerciseName, {String? exerciseId}) async {
    // Optimistic update
    final optimisticFavorite = FavoriteExercise(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      addedAt: DateTime.now(),
    );
    state = state.copyWith(
      favorites: [...state.favorites, optimisticFavorite],
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          favorites: state.favorites.where((f) => f.id != optimisticFavorite.id).toList(),
          error: 'Not logged in',
        );
        return false;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final favorite = await repository.addFavoriteExercise(
        userId,
        exerciseName,
        exerciseId: exerciseId,
      );

      // Replace optimistic with real
      state = state.copyWith(
        favorites: [
          ...state.favorites.where((f) => f.id != optimisticFavorite.id),
          favorite,
        ],
      );

      debugPrint('❤️ [FavoritesProvider] Added favorite: $exerciseName');
      return true;
    } catch (e) {
      debugPrint('❌ [FavoritesProvider] Error adding favorite: $e');
      // Rollback
      state = state.copyWith(
        favorites: state.favorites.where((f) => f.id != optimisticFavorite.id).toList(),
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove an exercise from favorites
  Future<bool> removeFavorite(String exerciseName) async {
    // Find the favorite to remove
    final favorite = state.favorites.firstWhere(
      (f) => f.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
      orElse: () => throw Exception('Favorite not found'),
    );

    // Optimistic update
    state = state.copyWith(
      favorites: state.favorites.where((f) => f.id != favorite.id).toList(),
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          favorites: [...state.favorites, favorite],
          error: 'Not logged in',
        );
        return false;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      await repository.removeFavoriteExercise(userId, exerciseName);

      debugPrint('❤️ [FavoritesProvider] Removed favorite: $exerciseName');
      return true;
    } catch (e) {
      debugPrint('❌ [FavoritesProvider] Error removing favorite: $e');
      // Rollback
      state = state.copyWith(
        favorites: [...state.favorites, favorite],
        error: e.toString(),
      );
      return false;
    }
  }

  /// Toggle favorite status for an exercise
  Future<bool> toggleFavorite(String exerciseName, {String? exerciseId}) async {
    if (state.isFavorite(exerciseName)) {
      return await removeFavorite(exerciseName);
    } else {
      return await addFavorite(exerciseName, exerciseId: exerciseId);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
