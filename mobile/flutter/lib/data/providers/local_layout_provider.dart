import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/home_layout.dart';

const _uuid = Uuid();
const _layoutsKey = 'home_layouts';
const _activeLayoutKey = 'active_layout_id';
const _userDefaultLayoutKey = 'user_default_layout_tiles';

/// Local layout provider - stores layouts in SharedPreferences
/// This works offline without needing backend API
final localLayoutProvider =
    StateNotifierProvider<LocalLayoutNotifier, AsyncValue<HomeLayout?>>(
  (ref) => LocalLayoutNotifier(),
);

/// All local layouts provider
final allLocalLayoutsProvider =
    StateNotifierProvider<AllLocalLayoutsNotifier, AsyncValue<List<HomeLayout>>>(
  (ref) => AllLocalLayoutsNotifier(),
);

/// Local layout state notifier
class LocalLayoutNotifier extends StateNotifier<AsyncValue<HomeLayout?>> {
  LocalLayoutNotifier() : super(const AsyncValue.loading()) {
    _loadActiveLayout();
  }

  Future<void> _loadActiveLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutsJson = prefs.getString(_layoutsKey);
      final activeId = prefs.getString(_activeLayoutKey);

      if (layoutsJson == null || layoutsJson.isEmpty) {
        // Create default layout
        final defaultLayout = _createDefaultLayout();
        await _saveLayouts([defaultLayout]);
        await prefs.setString(_activeLayoutKey, defaultLayout.id);
        state = AsyncValue.data(defaultLayout);
        debugPrint('✅ [LocalLayout] Created default layout');
        return;
      }

      final List<dynamic> layoutsList = jsonDecode(layoutsJson);
      final layouts = layoutsList
          .map((json) => HomeLayout.fromJson(json as Map<String, dynamic>))
          .toList();

      if (layouts.isEmpty) {
        final defaultLayout = _createDefaultLayout();
        await _saveLayouts([defaultLayout]);
        await prefs.setString(_activeLayoutKey, defaultLayout.id);
        state = AsyncValue.data(defaultLayout);
        return;
      }

      // Find active layout or use first one
      HomeLayout? activeLayout;
      if (activeId != null) {
        activeLayout = layouts.where((l) => l.id == activeId).firstOrNull;
      }
      activeLayout ??= layouts.first;

      // Ensure all default tiles exist in the layout (add missing ones)
      activeLayout = _ensureAllDefaultTilesExist(activeLayout);

      // Update the saved layout if tiles were added
      final index = layouts.indexWhere((l) => l.id == activeLayout!.id);
      if (index != -1) {
        layouts[index] = activeLayout;
        await _saveLayouts(layouts);
      }

      state = AsyncValue.data(activeLayout);
      debugPrint('✅ [LocalLayout] Loaded: ${activeLayout.name}');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalLayout] Error loading: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  HomeLayout _createDefaultLayout() {
    final now = DateTime.now();
    return HomeLayout(
      id: 'layout_${_uuid.v4()}',
      userId: 'local',
      name: 'My Layout',
      tiles: createDefaultTiles(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Ensure all default tiles exist in the layout
  /// Adds any missing tiles at the end (hidden by default)
  HomeLayout _ensureAllDefaultTilesExist(HomeLayout layout) {
    final existingTypes = layout.tiles.map((t) => t.type).toSet();
    final missingTiles = <HomeTile>[];
    var nextOrder = layout.tiles.isEmpty ? 0 : layout.tiles.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1;

    // Check all tiles (both default visible and hidden)
    final allTileTypes = [...defaultVisibleTiles, ...defaultHiddenTiles];
    for (final type in allTileTypes) {
      if (!existingTypes.contains(type)) {
        missingTiles.add(HomeTile(
          id: 'tile_${_uuid.v4()}',
          type: type,
          size: type.defaultSize,
          order: nextOrder++,
          isVisible: false, // New tiles hidden by default
        ));
        debugPrint('📦 [LocalLayout] Adding missing tile: ${type.displayName}');
      }
    }

    if (missingTiles.isEmpty) {
      return layout;
    }

    return layout.copyWith(
      tiles: [...layout.tiles, ...missingTiles],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveLayouts(List<HomeLayout> layouts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(layouts.map((l) => l.toJson()).toList());
    await prefs.setString(_layoutsKey, json);
  }

  Future<List<HomeLayout>> _getLayouts() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutsJson = prefs.getString(_layoutsKey);
    if (layoutsJson == null || layoutsJson.isEmpty) return [];

    final List<dynamic> layoutsList = jsonDecode(layoutsJson);
    return layoutsList
        .map((json) => HomeLayout.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    await _loadActiveLayout();
  }

  Future<void> updateTiles(List<HomeTile> tiles) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final updatedLayout = currentLayout.copyWith(
      tiles: tiles,
      updatedAt: DateTime.now(),
    );

    // Save to preferences
    final layouts = await _getLayouts();
    final index = layouts.indexWhere((l) => l.id == currentLayout.id);
    if (index != -1) {
      layouts[index] = updatedLayout;
      await _saveLayouts(layouts);
    }

    state = AsyncValue.data(updatedLayout);
    debugPrint('✅ [LocalLayout] Tiles updated');
  }

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

  Future<void> reorderTiles(int oldIndex, int newIndex) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final visibleTiles = currentLayout.visibleTiles;
    if (oldIndex >= visibleTiles.length || newIndex >= visibleTiles.length) {
      return;
    }

    final movedTile = visibleTiles[oldIndex];
    final updatedTiles = List<HomeTile>.from(currentLayout.tiles);
    final visibleIds = visibleTiles.map((t) => t.id).toList();
    visibleIds.removeAt(oldIndex);
    visibleIds.insert(newIndex > oldIndex ? newIndex : newIndex, movedTile.id);

    int order = 0;
    for (final visibleId in visibleIds) {
      final index = updatedTiles.indexWhere((t) => t.id == visibleId);
      if (index != -1) {
        updatedTiles[index] = updatedTiles[index].copyWith(order: order);
        order++;
      }
    }

    for (int i = 0; i < updatedTiles.length; i++) {
      if (!updatedTiles[i].isVisible) {
        updatedTiles[i] = updatedTiles[i].copyWith(order: order);
        order++;
      }
    }

    await updateTiles(updatedTiles);
  }

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

  Future<void> addTile(TileType type, {TileSize? size}) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    if (currentLayout.tiles.any((t) => t.type == type)) {
      debugPrint('⚠️ [LocalLayout] Tile of type $type already exists');
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

  Future<void> removeTile(String tileId) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final updatedTiles =
        currentLayout.tiles.where((t) => t.id != tileId).toList();

    for (int i = 0; i < updatedTiles.length; i++) {
      updatedTiles[i] = updatedTiles[i].copyWith(order: i);
    }

    await updateTiles(updatedTiles);
  }

  Future<void> activateLayout(String layoutId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeLayoutKey, layoutId);
    await _loadActiveLayout();
  }

  Future<void> resetToDefault() async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final defaultTiles = createDefaultTiles();
    final updatedLayout = currentLayout.copyWith(
      tiles: defaultTiles,
      updatedAt: DateTime.now(),
    );

    final layouts = await _getLayouts();
    final index = layouts.indexWhere((l) => l.id == currentLayout.id);
    if (index != -1) {
      layouts[index] = updatedLayout;
      await _saveLayouts(layouts);
    }

    state = AsyncValue.data(updatedLayout);
    debugPrint('✅ [LocalLayout] Reset to default');
  }

  Future<void> applyPreset(LayoutPreset preset) async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final presetTiles = createPresetTiles(preset);
    final updatedLayout = currentLayout.copyWith(
      tiles: presetTiles,
      name: preset.displayName,
      updatedAt: DateTime.now(),
    );

    final layouts = await _getLayouts();
    final index = layouts.indexWhere((l) => l.id == currentLayout.id);
    if (index != -1) {
      layouts[index] = updatedLayout;
      await _saveLayouts(layouts);
    }

    state = AsyncValue.data(updatedLayout);
    debugPrint('✅ [LocalLayout] Applied preset: ${preset.displayName}');
  }

  HomeTile? getTileByType(TileType type) {
    return state.value?.tiles
        .where((t) => t.type == type && t.isVisible)
        .firstOrNull;
  }

  bool isTileVisible(TileType type) {
    return state.value?.tiles.any((t) => t.type == type && t.isVisible) ?? false;
  }

  /// Check if the current layout matches the app default
  bool matchesAppDefault() {
    final currentTiles = state.value?.tiles;
    if (currentTiles == null) return true;

    final defaultTiles = createDefaultTiles();

    // Compare visible tiles and their order
    final currentVisible = currentTiles
        .where((t) => t.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final defaultVisible = defaultTiles
        .where((t) => t.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (currentVisible.length != defaultVisible.length) return false;

    for (int i = 0; i < currentVisible.length; i++) {
      if (currentVisible[i].type != defaultVisible[i].type) return false;
    }

    return true;
  }

  /// Reset to app's original hardcoded layout
  Future<void> resetToAppDefault() async {
    final currentLayout = state.value;
    if (currentLayout == null) return;

    final defaultTiles = createDefaultTiles();
    final updatedLayout = currentLayout.copyWith(
      tiles: defaultTiles,
      updatedAt: DateTime.now(),
    );

    final layouts = await _getLayouts();
    final index = layouts.indexWhere((l) => l.id == currentLayout.id);
    if (index != -1) {
      layouts[index] = updatedLayout;
      await _saveLayouts(layouts);
    }

    state = AsyncValue.data(updatedLayout);
    debugPrint('✅ [LocalLayout] Reset to app default');
  }

  /// Save current layout as user's custom default
  Future<void> saveAsUserDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLayout = state.value;
    if (currentLayout != null) {
      final json = jsonEncode(currentLayout.tiles.map((t) => t.toJson()).toList());
      await prefs.setString(_userDefaultLayoutKey, json);
      debugPrint('✅ [LocalLayout] Saved as user default');
    }
  }

  /// Check if user has saved a custom default
  Future<bool> hasUserDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userDefaultLayoutKey);
  }

  /// Apply user's saved custom default
  Future<void> applyUserDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultJson = prefs.getString(_userDefaultLayoutKey);
    if (defaultJson != null) {
      final List<dynamic> tilesList = jsonDecode(defaultJson);
      final tiles = tilesList
          .map((json) => HomeTile.fromJson(json as Map<String, dynamic>))
          .toList();
      await updateTiles(tiles);
      debugPrint('✅ [LocalLayout] Applied user default');
    }
  }

  /// Get user's saved default tiles (for display in Discover tab)
  Future<List<HomeTile>?> getUserDefaultTiles() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultJson = prefs.getString(_userDefaultLayoutKey);
    if (defaultJson == null) return null;

    final List<dynamic> tilesList = jsonDecode(defaultJson);
    return tilesList
        .map((json) => HomeTile.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// All local layouts state notifier
class AllLocalLayoutsNotifier extends StateNotifier<AsyncValue<List<HomeLayout>>> {
  AllLocalLayoutsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutsJson = prefs.getString(_layoutsKey);

      if (layoutsJson == null || layoutsJson.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final List<dynamic> layoutsList = jsonDecode(layoutsJson);
      final layouts = layoutsList
          .map((json) => HomeLayout.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(layouts);
      debugPrint('✅ [AllLocalLayouts] Loaded ${layouts.length} layouts');
    } catch (e, stackTrace) {
      debugPrint('❌ [AllLocalLayouts] Error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<HomeLayout> createLayout({
    required String name,
    required List<HomeTile> tiles,
  }) async {
    final now = DateTime.now();

    final newLayout = HomeLayout(
      id: 'layout_${_uuid.v4()}',
      userId: 'local',
      name: name,
      tiles: tiles,
      isActive: false,
      createdAt: now,
      updatedAt: now,
    );

    final layouts = await _getLayouts();
    layouts.add(newLayout);
    await _saveLayouts(layouts);
    await refresh();

    return newLayout;
  }

  Future<void> deleteLayout(String layoutId) async {
    final layouts = await _getLayouts();
    layouts.removeWhere((l) => l.id == layoutId);
    await _saveLayouts(layouts);
    await refresh();
  }

  Future<void> renameLayout(String layoutId, String newName) async {
    final layouts = await _getLayouts();
    final index = layouts.indexWhere((l) => l.id == layoutId);
    if (index != -1) {
      layouts[index] = layouts[index].copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      await _saveLayouts(layouts);
      await refresh();
    }
  }

  Future<List<HomeLayout>> _getLayouts() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutsJson = prefs.getString(_layoutsKey);
    if (layoutsJson == null || layoutsJson.isEmpty) return [];

    final List<dynamic> layoutsList = jsonDecode(layoutsJson);
    return layoutsList
        .map((json) => HomeLayout.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLayouts(List<HomeLayout> layouts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(layouts.map((l) => l.toJson()).toList());
    await prefs.setString(_layoutsKey, json);
  }
}
