/// Riverpod-backed visibility/order model for the Hero Nutrition carousel's
/// micronutrient tiles, persisted to SharedPreferences (scoped per user).
///
/// Mirrors [ringVisibilityProvider] (home metric deck): the carousel reads this
/// to know which micronutrient tiles to draw and in what order; the customize
/// sheet mutates it. Goals stay FDA Daily Values (see [kMicroCatalog]) — this
/// only controls which tiles appear, home-deck style.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/auth_provider.dart';
import '../models/micronutrient_catalog.dart';

/// Per-user storage key so switching accounts on one device doesn't bleed
/// customisations.
String _microOrderKey(String? userId) => userId == null || userId.isEmpty
    ? 'nutrition_micro_order_anon'
    : 'nutrition_micro_order_$userId';

class MicroVisibilityNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  MicroVisibilityNotifier(this._ref) : super(kDefaultMicroOrder) {
    _load();
  }

  String? get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_microOrderKey(_userId));
      if (raw == null || raw.isEmpty) return; // first load → defaults
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      // Keep only ids that still exist in the catalog (drop stale slugs), dedupe
      // (a corrupt blob repeating an id would crash the keyed ReorderableList).
      final seen = <String>{};
      final ids = <String>[];
      for (final v in decoded) {
        if (v is String && microEntryById(v) != null && seen.add(v)) {
          ids.add(v);
        }
      }
      // An empty visible set is allowed (user hid every micro tile) ONLY if the
      // blob explicitly persisted that; a fully-corrupt blob (no valid ids)
      // falls back to defaults so the carousel never silently loses its micros.
      if (decoded.isNotEmpty && ids.isEmpty) return;
      state = ids;
      // Self-heal a corrupt/legacy blob so it doesn't re-clean every launch.
      if (ids.join(',') != decoded.whereType<String>().join(',')) {
        await _persist();
      }
    } catch (_) {
      // Best-effort — keep defaults on any error.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_microOrderKey(_userId), jsonEncode(state));
    } catch (_) {
      // Best-effort; in-memory state still reflects user intent.
    }
  }

  /// Replace the entire visible list (used by the reorderable list). Dedupes
  /// and drops unknown ids defensively.
  void setOrder(List<String> order) {
    final seen = <String>{};
    state = [
      for (final id in order)
        if (microEntryById(id) != null && seen.add(id)) id,
    ];
    _persist();
  }

  /// Show a hidden tile (appended at the end). No-op if already visible.
  void show(String id) {
    if (state.contains(id) || microEntryById(id) == null) return;
    state = [...state, id];
    _persist();
  }

  /// Hide a visible tile.
  void hide(String id) {
    if (!state.contains(id)) return;
    state = state.where((e) => e != id).toList(growable: false);
    _persist();
  }

  /// Restore the canonical default (every catalog tile, catalog order).
  void resetToDefault() {
    state = kDefaultMicroOrder;
    _persist();
  }
}

/// Currently visible micronutrient tile ids, in display order.
final microVisibilityProvider =
    StateNotifierProvider<MicroVisibilityNotifier, List<String>>((ref) {
  // Rebuild per account so each user loads their own persisted order.
  ref.watch(currentUserIdProvider);
  return MicroVisibilityNotifier(ref);
});

/// Catalog tiles NOT currently visible — the "add" section of the sheet.
final hiddenMicrosProvider = Provider<List<MicroCatalogEntry>>((ref) {
  final visible = ref.watch(microVisibilityProvider).toSet();
  return kMicroCatalog.where((e) => !visible.contains(e.id)).toList(growable: false);
});
