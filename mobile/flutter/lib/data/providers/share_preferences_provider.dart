import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// User's share-template preferences — favorite template ids and a
/// custom ordering. Persisted locally (SharedPreferences) for instant
/// load and synced to the backend via
/// `/api/v1/share-templates/preferences` for cross-device consistency.
class SharePreferences {
  final List<String> favorites;
  final List<String> order;

  const SharePreferences({
    this.favorites = const [],
    this.order = const [],
  });

  SharePreferences copyWith({
    List<String>? favorites,
    List<String>? order,
  }) {
    return SharePreferences(
      favorites: favorites ?? this.favorites,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'favorites': favorites,
        'template_order': order,
      };

  factory SharePreferences.fromJson(Map<String, dynamic> json) {
    return SharePreferences(
      favorites: (json['favorites'] as List?)?.cast<String>() ?? const [],
      order: (json['template_order'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class SharePreferencesNotifier extends StateNotifier<SharePreferences> {
  SharePreferencesNotifier(this._ref) : super(const SharePreferences()) {
    _loadLocal().then((_) => _fetchFromBackend());
  }

  final Ref _ref;
  static const _prefsKey = 'share_template_preferences';

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = SharePreferences.fromJson(json);
    } catch (e) {
      debugPrint('[SharePreferences] local load failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[SharePreferences] local save failed: $e');
    }
  }

  Future<void> _fetchFromBackend() async {
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.get('/share-templates/preferences');
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        final remote = SharePreferences.fromJson(resp.data as Map<String, dynamic>);
        // Remote wins iff it has any state. Empty remote means first-run;
        // keep locally-loaded order/favorites in that case.
        if (remote.favorites.isNotEmpty || remote.order.isNotEmpty) {
          state = remote;
          await _saveLocal();
        }
      }
    } catch (e) {
      debugPrint('[SharePreferences] backend fetch failed (non-blocking): $e');
    }
  }

  Future<void> _pushToBackend() async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.put('/share-templates/preferences', data: state.toJson());
    } catch (e) {
      debugPrint('[SharePreferences] backend push failed (non-blocking): $e');
    }
  }

  Future<void> toggleFavorite(String templateId) async {
    final favs = [...state.favorites];
    if (favs.contains(templateId)) {
      favs.remove(templateId);
    } else {
      favs.add(templateId);
    }
    state = state.copyWith(favorites: favs);
    await _saveLocal();
    // ignore: unawaited_futures
    _pushToBackend();
  }

  Future<void> setOrder(List<String> newOrder) async {
    state = state.copyWith(order: newOrder);
    await _saveLocal();
    // ignore: unawaited_futures
    _pushToBackend();
  }

  Future<void> reorder(int oldIndex, int newIndex, List<String> currentOrder) async {
    final list = [...currentOrder];
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await setOrder(list);
  }
}

final sharePreferencesProvider =
    StateNotifierProvider<SharePreferencesNotifier, SharePreferences>((ref) {
  return SharePreferencesNotifier(ref);
});
