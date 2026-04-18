import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cosmetic.dart';
import '../services/api_client.dart';

/// Combined cosmetics state: full catalog + user's ownership/equip state.
@immutable
class CosmeticsState {
  final bool loading;
  final Object? error;
  final List<Cosmetic> catalog;
  final Map<String, UserCosmetic> owned; // keyed by cosmetic_id

  const CosmeticsState({
    this.loading = false,
    this.error,
    this.catalog = const [],
    this.owned = const {},
  });

  /// Currently-equipped cosmetic of the given type, or null.
  Cosmetic? equippedOfType(CosmeticType type) {
    for (final c in catalog) {
      if (c.type != type) continue;
      final u = owned[c.id];
      if (u?.isEquipped == true) return c;
    }
    return null;
  }

  /// Whether the user owns the given cosmetic.
  bool ownsCosmetic(String id) => owned.containsKey(id);

  /// All catalog entries grouped by type, preserving unlock_level order.
  Map<CosmeticType, List<Cosmetic>> get catalogByType {
    final m = <CosmeticType, List<Cosmetic>>{};
    for (final c in catalog) {
      m.putIfAbsent(c.type, () => []).add(c);
    }
    return m;
  }

  CosmeticsState copyWith({
    bool? loading,
    Object? error,
    List<Cosmetic>? catalog,
    Map<String, UserCosmetic>? owned,
    bool clearError = false,
  }) =>
      CosmeticsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        catalog: catalog ?? this.catalog,
        owned: owned ?? this.owned,
      );
}

class CosmeticsNotifier extends StateNotifier<CosmeticsState> {
  final ApiClient _client;
  CosmeticsNotifier(this._client) : super(const CosmeticsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final cat = await _client.get('/xp/cosmetics/catalog');
      final mine = await _client.get('/xp/cosmetics/me');
      final catalogList = ((cat.data as Map)['cosmetics'] as List? ?? [])
          .map((j) => Cosmetic.fromJson(j as Map<String, dynamic>))
          .toList();
      final ownedMap = <String, UserCosmetic>{
        for (final j in ((mine.data as Map)['cosmetics'] as List? ?? []))
          (j as Map<String, dynamic>)['cosmetic_id'] as String:
              UserCosmetic.fromJson(j),
      };
      state = state.copyWith(loading: false, catalog: catalogList, owned: ownedMap);
    } catch (e) {
      debugPrint('load cosmetics failed: $e');
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> equip(String cosmeticId) async {
    try {
      await _client.post('/xp/cosmetics/equip', data: {'cosmetic_id': cosmeticId});
      // Reload to pick up the new equip state
      await load();
    } catch (e) {
      debugPrint('equip cosmetic failed: $e');
      rethrow;
    }
  }

  Future<void> unequip(String cosmeticId) async {
    try {
      await _client.post('/xp/cosmetics/unequip', data: {'cosmetic_id': cosmeticId});
      await load();
    } catch (e) {
      debugPrint('unequip cosmetic failed: $e');
      rethrow;
    }
  }
}

final cosmeticsProvider =
    StateNotifierProvider<CosmeticsNotifier, CosmeticsState>((ref) {
  return CosmeticsNotifier(ref.watch(apiClientProvider));
});

/// Convenience: currently-equipped badge (null if nothing equipped).
final equippedBadgeProvider = Provider<Cosmetic?>((ref) {
  return ref.watch(cosmeticsProvider.select((s) => s.equippedOfType(CosmeticType.badge)));
});

/// Convenience: currently-equipped frame (null if nothing equipped).
final equippedFrameProvider = Provider<Cosmetic?>((ref) {
  return ref.watch(cosmeticsProvider.select((s) => s.equippedOfType(CosmeticType.frame)));
});
