/// Persistence for the Home metrics-carousel edit sheet (page order/on-off,
/// Training-page stat-strip slots). Mirrors `local_layout_provider.dart`'s
/// SharedPreferences pattern (this codebase's established home for per-user
/// UI prefs — no backend table for this) including its "synchronous default
/// so the screen never starts in loading state" trick via an in-memory cache.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/metrics_carousel_prefs.dart';
import '../repositories/auth_repository.dart';

const _prefsKey = 'metrics_carousel_prefs_v1';

/// In-memory cache so a fresh provider instance (e.g. after a tab remount)
/// starts with the last-known prefs instead of the hard default, same trick
/// `local_layout_provider.dart` uses to avoid a first-frame flash.
MetricsCarouselPrefs? _inMemoryCache;
String? _cacheOwnerUserId;

final metricsCarouselPrefsProvider = StateNotifierProvider<
    MetricsCarouselPrefsNotifier, MetricsCarouselPrefs>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _cacheOwnerUserId) {
    _cacheOwnerUserId = userId;
    _inMemoryCache = null;
  }
  return MetricsCarouselPrefsNotifier();
});

class MetricsCarouselPrefsNotifier extends StateNotifier<MetricsCarouselPrefs> {
  MetricsCarouselPrefsNotifier()
      : super(_inMemoryCache ?? MetricsCarouselPrefs.defaults()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = MetricsCarouselPrefs.fromJson(decoded);
      _inMemoryCache = loaded;
      if (mounted) state = loaded;
    } catch (e) {
      debugPrint('⚠️ [MetricsCarouselPrefs] load failed: $e');
    }
  }

  Future<void> _persist(MetricsCarouselPrefs next) async {
    _inMemoryCache = next;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('⚠️ [MetricsCarouselPrefs] persist failed: $e');
    }
  }

  /// Reorder the page list (drag-to-reorder, level 1). Follows
  /// `ReorderableListView`'s own index contract — call this straight from
  /// `onReorder`.
  Future<void> reorderPages(int oldIndex, int newIndex) async {
    final pages = List<CarouselPageConfig>.from(state.pages);
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= pages.length) return;
    final moved = pages.removeAt(oldIndex);
    pages.insert(newIndex.clamp(0, pages.length), moved);
    await _persist(MetricsCarouselPrefs(pages: pages));
  }

  Future<void> togglePage(CarouselPageId id, bool enabled) async {
    final pages = [
      for (final p in state.pages)
        if (p.id == id) p.copyWith(enabled: enabled) else p,
    ];
    await _persist(MetricsCarouselPrefs(pages: pages));
  }

  /// Reorder slots within one page (level 2).
  Future<void> reorderSlots(CarouselPageId id, int oldIndex, int newIndex) async {
    final page = state.pages.firstWhere((p) => p.id == id);
    final slots = List<CarouselSlotId>.from(page.slots);
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= slots.length) return;
    final moved = slots.removeAt(oldIndex);
    slots.insert(newIndex.clamp(0, slots.length), moved);
    final pages = [
      for (final p in state.pages)
        if (p.id == id) p.copyWith(slots: slots) else p,
    ];
    await _persist(MetricsCarouselPrefs(pages: pages));
  }

  /// Toggle one slot on/off, enforcing the page's slot cap ([maxSlots] —
  /// 4 normal / 6 tall). Toggling ON past the cap is a no-op — the caller
  /// (the edit sheet) should offer "make the card taller" instead of letting
  /// this silently fail; see [setTall].
  Future<void> toggleSlot(CarouselPageId id, CarouselSlotId slot, bool on) async {
    final page = state.pages.firstWhere((p) => p.id == id);
    if (on && page.slots.contains(slot)) return;
    if (!on && !page.slots.contains(slot)) return;
    if (on && page.slots.length >= page.maxSlots) return;

    final slots = on
        ? [...page.slots, slot]
        : page.slots.where((s) => s != slot).toList();
    final pages = [
      for (final p in state.pages)
        if (p.id == id) p.copyWith(slots: slots) else p,
    ];
    await _persist(MetricsCarouselPrefs(pages: pages));
  }

  /// Opt a page into the taller 240px card (raises its slot cap from 4 to 6).
  Future<void> setTall(CarouselPageId id, bool tall) async {
    final pages = [
      for (final p in state.pages)
        if (p.id == id) p.copyWith(tall: tall) else p,
    ];
    await _persist(MetricsCarouselPrefs(pages: pages));
  }
}
