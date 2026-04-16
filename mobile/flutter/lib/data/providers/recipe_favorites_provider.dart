/// Optimistic in-memory state for recipe favorites.
///
/// Mirrors the pattern used in `core/providers/favorites_provider.dart` for
/// exercise favorites, but keyed by recipe UUID (not exerciseName) and backed
/// by a `Set<String>` for O(1) `.contains()` checks in list rendering.
///
/// Unlike the exercise favorites provider, this notifier does NOT fetch on
/// init — favorites are hydrated via `favoriteRecipesProvider` when the user
/// opens a screen that needs them (Favorites tab, Discover feed, recipe
/// detail). Screens should call [RecipeFavoritesNotifier.hydrate] with the
/// server's truth to pre-populate the local set so every subsequent heart
/// icon can render instantly without a network round-trip.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/recipe_repository.dart';

/// Immutable state: set of favorited recipe ids.
///
/// `isLoading` covers the brief window while a single toggle's API call is in
/// flight — the UI can dim the heart icon or disable rapid re-taps, though
/// because we apply state optimistically the spinner is rarely visible.
class RecipeFavoritesState {
  /// Favorited recipe ids (UUIDs).
  final Set<String> ids;

  /// True while any toggle() call is in flight.
  final bool isLoading;

  const RecipeFavoritesState({
    this.ids = const {},
    this.isLoading = false,
  });

  bool contains(String id) => ids.contains(id);

  RecipeFavoritesState copyWith({
    Set<String>? ids,
    bool? isLoading,
  }) {
    return RecipeFavoritesState(
      ids: ids ?? this.ids,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier with optimistic add/remove + rollback-on-error.
class RecipeFavoritesNotifier extends StateNotifier<RecipeFavoritesState> {
  final Ref _ref;

  RecipeFavoritesNotifier(this._ref) : super(const RecipeFavoritesState());

  /// Merge server-provided ids into the local set without dropping any
  /// optimistic entries that haven't been confirmed yet.
  ///
  /// Safe to call repeatedly (idempotent) — use this when a list screen loads
  /// a fresh batch of recipes and wants to pre-populate heart states.
  void hydrate(Iterable<String> ids) {
    if (ids.isEmpty) return;
    state = state.copyWith(ids: {...state.ids, ...ids});
  }

  /// Replace the entire favorites set with the server's truth. Use this when
  /// the Favorites screen refreshes — anything not in [ids] is treated as
  /// removed.
  void replace(Iterable<String> ids) {
    state = state.copyWith(ids: {...ids});
  }

  /// True if the recipe is currently favorited (locally).
  bool isFavorited(String recipeId) => state.contains(recipeId);

  /// Add a favorite (optimistic, with server round-trip and rollback).
  Future<void> add(String recipeId) async {
    if (state.contains(recipeId)) return;
    final newIds = {...state.ids, recipeId};
    state = state.copyWith(ids: newIds);
    try {
      await _ref
          .read(recipeRepositoryProvider)
          .toggleFavorite(recipeId, favorite: true);
    } catch (e) {
      debugPrint('❌ [RecipeFavorites] add failed for $recipeId: $e');
      // Rollback
      final rollback = {...state.ids}..remove(recipeId);
      state = state.copyWith(ids: rollback);
      rethrow;
    }
  }

  /// Remove a favorite (optimistic, with server round-trip and rollback).
  Future<void> remove(String recipeId) async {
    if (!state.contains(recipeId)) return;
    final newIds = {...state.ids}..remove(recipeId);
    state = state.copyWith(ids: newIds);
    try {
      await _ref
          .read(recipeRepositoryProvider)
          .toggleFavorite(recipeId, favorite: false);
    } catch (e) {
      debugPrint('❌ [RecipeFavorites] remove failed for $recipeId: $e');
      // Rollback
      final rollback = {...state.ids, recipeId};
      state = state.copyWith(ids: rollback);
      rethrow;
    }
  }

  /// Toggle favorite on/off with optimistic update + rollback on error.
  ///
  /// Throws the underlying network error after rolling back so callers can
  /// surface a snackbar ("Couldn't save favorite. Try again.").
  Future<void> toggle(String recipeId) async {
    final wasFav = state.contains(recipeId);
    // Optimistic apply
    final newIds = {...state.ids};
    if (wasFav) {
      newIds.remove(recipeId);
    } else {
      newIds.add(recipeId);
    }
    state = state.copyWith(ids: newIds);

    try {
      await _ref
          .read(recipeRepositoryProvider)
          .toggleFavorite(recipeId, favorite: !wasFav);
    } catch (e) {
      debugPrint('❌ [RecipeFavorites] toggle failed for $recipeId: $e');
      // Rollback to prior state.
      final rollback = {...state.ids};
      if (wasFav) {
        rollback.add(recipeId);
      } else {
        rollback.remove(recipeId);
      }
      state = state.copyWith(ids: rollback);
      rethrow;
    }
  }
}

/// App-wide recipe favorites state. Not autoDispose — heart icons across
/// multiple screens (Discover, Favorites, Detail, RecipesTab) all read from
/// the same set, and we don't want the set to get dropped when one screen
/// disposes.
final recipeFavoritesProvider =
    StateNotifierProvider<RecipeFavoritesNotifier, RecipeFavoritesState>(
  (ref) => RecipeFavoritesNotifier(ref),
);
