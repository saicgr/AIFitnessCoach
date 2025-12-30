import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/home_layout.dart';
import '../repositories/auth_repository.dart';
import '../repositories/home_layout_repository.dart';

const _uuid = Uuid();

/// Active layout provider - the currently active layout for the home screen
final activeLayoutProvider =
    StateNotifierProvider<ActiveLayoutNotifier, AsyncValue<HomeLayout?>>(
  (ref) {
    final repository = ref.watch(homeLayoutRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    return ActiveLayoutNotifier(repository, userId, ref);
  },
);

/// All layouts provider - list of all user layouts
final allLayoutsProvider =
    StateNotifierProvider<AllLayoutsNotifier, AsyncValue<List<HomeLayout>>>(
  (ref) {
    final repository = ref.watch(homeLayoutRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    return AllLayoutsNotifier(repository, userId, ref);
  },
);

/// Templates provider - system layout templates
final layoutTemplatesProvider =
    FutureProvider<List<HomeLayoutTemplate>>((ref) async {
  final repository = ref.watch(homeLayoutRepositoryProvider);
  return await repository.getTemplates();
});

/// Active layout state notifier
class ActiveLayoutNotifier extends StateNotifier<AsyncValue<HomeLayout?>> {
  final HomeLayoutRepository _repository;
  final String? _userId;
  final Ref _ref;

  ActiveLayoutNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadActiveLayout();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Load the active layout from API
  Future<void> _loadActiveLayout() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final layout = await _repository.getActiveLayout(_userId);
      state = AsyncValue.data(layout);
      debugPrint('✅ [ActiveLayout] Loaded: ${layout.name}');
    } catch (e, stackTrace) {
      debugPrint('❌ [ActiveLayout] Error loading: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh the active layout
  Future<void> refresh() async {
    await _loadActiveLayout();
  }

  /// Update the active layout tiles (optimistic update)
  Future<void> updateTiles(List<HomeTile> tiles) async {
    if (_userId == null) return;

    final currentLayout = state.value;
    if (currentLayout == null) return;

    // Optimistic update
    state = AsyncValue.data(currentLayout.copyWith(
      tiles: tiles,
      updatedAt: DateTime.now(),
    ));

    try {
      final updatedLayout = await _repository.updateLayout(
        layoutId: currentLayout.id,
        userId: _userId,
        tiles: tiles,
      );
      state = AsyncValue.data(updatedLayout);
      debugPrint('✅ [ActiveLayout] Tiles updated');
    } catch (e, stackTrace) {
      debugPrint('❌ [ActiveLayout] Error updating tiles: $e');
      // Rollback
      state = AsyncValue.data(currentLayout);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Toggle visibility of a tile
  Future<void> toggleTileVisibility(String tileId) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final updatedTiles = currentLayout.tiles.map((tile) {
      if (tile.id == tileId) {
        return tile.copyWith(isVisible: !tile.isVisible);
      }
      return tile;
    }).toList();

    await updateTiles(updatedTiles);
  }

  /// Reorder tiles
  Future<void> reorderTiles(int oldIndex, int newIndex) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final visibleTiles = currentLayout.visibleTiles;
    if (oldIndex >= visibleTiles.length || newIndex >= visibleTiles.length) {
      return;
    }

    // Get the tile being moved
    final movedTile = visibleTiles[oldIndex];

    // Create new tiles list with updated orders
    final updatedTiles = List<HomeTile>.from(currentLayout.tiles);

    // Remove and reinsert with new order
    final visibleIds = visibleTiles.map((t) => t.id).toList();
    visibleIds.removeAt(oldIndex);
    visibleIds.insert(newIndex > oldIndex ? newIndex : newIndex, movedTile.id);

    // Update order values for all tiles
    int order = 0;
    for (final visibleId in visibleIds) {
      final index = updatedTiles.indexWhere((t) => t.id == visibleId);
      if (index != -1) {
        updatedTiles[index] = updatedTiles[index].copyWith(order: order);
        order++;
      }
    }

    // Hidden tiles get order after visible tiles
    for (int i = 0; i < updatedTiles.length; i++) {
      if (!updatedTiles[i].isVisible) {
        updatedTiles[i] = updatedTiles[i].copyWith(order: order);
        order++;
      }
    }

    await updateTiles(updatedTiles);
  }

  /// Change tile size
  Future<void> changeTileSize(String tileId, TileSize newSize) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final updatedTiles = currentLayout.tiles.map((tile) {
      if (tile.id == tileId) {
        return tile.copyWith(size: newSize);
      }
      return tile;
    }).toList();

    await updateTiles(updatedTiles);
  }

  /// Add a new tile
  Future<void> addTile(TileType type, {TileSize? size}) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    // Check if tile already exists
    if (currentLayout.tiles.any((t) => t.type == type)) {
      debugPrint('⚠️ [ActiveLayout] Tile of type $type already exists');
      return;
    }

    final newTile = HomeTile(
      id: 'tile_${_uuid.v4()}',
      type: type,
      size: size ?? type.defaultSize,
      order: currentLayout.tiles.length,
      isVisible: true,
    );

    final updatedTiles = [...currentLayout.tiles, newTile];
    await updateTiles(updatedTiles);
  }

  /// Remove a tile
  Future<void> removeTile(String tileId) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final updatedTiles =
        currentLayout.tiles.where((t) => t.id != tileId).toList();

    // Re-order remaining tiles
    for (int i = 0; i < updatedTiles.length; i++) {
      updatedTiles[i] = updatedTiles[i].copyWith(order: i);
    }

    await updateTiles(updatedTiles);
  }

  /// Activate a different layout
  Future<void> activateLayout(String layoutId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final layout = await _repository.activateLayout(
        layoutId: layoutId,
        userId: _userId,
      );
      state = AsyncValue.data(layout);
      debugPrint('✅ [ActiveLayout] Activated: ${layout.name}');

      // Refresh all layouts list
      _ref.read(allLayoutsProvider.notifier).refresh();
    } catch (e, stackTrace) {
      debugPrint('❌ [ActiveLayout] Error activating: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Get tile by type (convenience method)
  HomeTile? getTileByType(TileType type) {
    return state.value?.tiles
        .where((t) => t.type == type && t.isVisible)
        .firstOrNull;
  }

  /// Check if a tile type is visible
  bool isTileVisible(TileType type) {
    return state.value?.tiles.any((t) => t.type == type && t.isVisible) ??
        false;
  }
}

/// All layouts state notifier
class AllLayoutsNotifier extends StateNotifier<AsyncValue<List<HomeLayout>>> {
  final HomeLayoutRepository _repository;
  final String? _userId;
  final Ref _ref;

  AllLayoutsNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      refresh();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  /// Refresh layouts list
  Future<void> refresh() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final layouts = await _repository.getLayouts(_userId);
      state = AsyncValue.data(layouts);
      debugPrint('✅ [AllLayouts] Loaded ${layouts.length} layouts');
    } catch (e, stackTrace) {
      debugPrint('❌ [AllLayouts] Error loading: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create a new layout
  Future<HomeLayout> createLayout({
    required String name,
    required List<HomeTile> tiles,
    String? templateId,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final newLayout = await _repository.createLayout(
        userId: _userId,
        name: name,
        tiles: tiles,
        templateId: templateId,
      );

      await refresh();
      debugPrint('✅ [AllLayouts] Created layout: ${newLayout.name}');
      return newLayout;
    } catch (e) {
      debugPrint('❌ [AllLayouts] Error creating layout: $e');
      rethrow;
    }
  }

  /// Create a layout from a template
  Future<HomeLayout> createFromTemplate({
    required String templateId,
    String? name,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final newLayout = await _repository.createFromTemplate(
        userId: _userId,
        templateId: templateId,
        name: name,
      );

      await refresh();
      debugPrint('✅ [AllLayouts] Created layout from template: ${newLayout.name}');
      return newLayout;
    } catch (e) {
      debugPrint('❌ [AllLayouts] Error creating from template: $e');
      rethrow;
    }
  }

  /// Delete a layout
  Future<void> deleteLayout(String layoutId) async {
    if (_userId == null) return;

    try {
      await _repository.deleteLayout(
        layoutId: layoutId,
        userId: _userId,
      );

      await refresh();
      debugPrint('✅ [AllLayouts] Deleted layout');
    } catch (e) {
      debugPrint('❌ [AllLayouts] Error deleting layout: $e');
      rethrow;
    }
  }

  /// Rename a layout
  Future<void> renameLayout(String layoutId, String newName) async {
    if (_userId == null) return;

    try {
      await _repository.updateLayout(
        layoutId: layoutId,
        userId: _userId,
        name: newName,
      );

      await refresh();
      debugPrint('✅ [AllLayouts] Renamed layout to: $newName');
    } catch (e) {
      debugPrint('❌ [AllLayouts] Error renaming layout: $e');
      rethrow;
    }
  }
}

/// Provider to check if homescreen customization should use old or new system
/// This can be used during migration period
final useNewLayoutSystemProvider = Provider<bool>((ref) {
  // Always use new system - old system removed
  return true;
});
