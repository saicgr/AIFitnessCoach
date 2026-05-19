import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
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

class CosmeticsNotifier extends StateNotifier<CosmeticsState> with CacheFirstMixin {
  final ApiClient _client;
  CosmeticsNotifier(this._client) : super(const CosmeticsState()) {
    load();
  }

  /// Cache-first load (Part-1 instant-load standard). Persists the raw catalog
  /// + ownership API responses so a cold start renders the cosmetics gallery
  /// instantly from disk, then revalidates over the network. The catalog is
  /// effectively static and ownership changes rarely, so a 12h TTL is ample.
  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    final userId = await _client.getUserId() ?? '';
    await loadCacheFirst<CosmeticsState>(
      cacheKey: 'cosmetics_gallery',
      userId: userId,
      ttl: const Duration(hours: 12),
      fetch: _fetchFresh,
      decode: _decode,
      encode: _encode,
      emit: (data, {required bool fromCache}) {
        if (mounted) {
          state = data.copyWith(loading: false, clearError: true);
        }
      },
      onError: (e, st) {
        debugPrint('load cosmetics failed: $e');
        // Keep cached catalog/owned on screen if we have it; only flag the
        // error so the cold-cache path can show the retry view.
        if (mounted) state = state.copyWith(loading: false, error: e);
      },
    );
  }

  /// Fetch + parse the catalog and ownership endpoints into a [CosmeticsState].
  Future<CosmeticsState> _fetchFresh() async {
    final cat = await _client.get('/xp/cosmetics/catalog');
    final mine = await _client.get('/xp/cosmetics/me');
    return _decode({
      'catalog': (cat.data as Map)['cosmetics'] ?? [],
      'owned': (mine.data as Map)['cosmetics'] ?? [],
    });
  }

  /// Decode the persisted/raw `{catalog: [...], owned: [...]}` envelope. The
  /// lists are the verbatim API rows, so `Cosmetic.fromJson` /
  /// `UserCosmetic.fromJson` decode them with no extra mapping.
  static CosmeticsState _decode(Map<String, dynamic> json) {
    final catalogList = ((json['catalog'] as List?) ?? const [])
        .map((j) => Cosmetic.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
    final ownedMap = <String, UserCosmetic>{
      for (final j in ((json['owned'] as List?) ?? const []))
        (j as Map).cast<String, dynamic>()['cosmetic_id'] as String:
            UserCosmetic.fromJson((j).cast<String, dynamic>()),
    };
    return CosmeticsState(catalog: catalogList, owned: ownedMap);
  }

  /// Encode for disk write-through. We persist the ORIGINAL raw API rows
  /// (carried unchanged by `_fetchFresh`) so the round-trip is loss-free even
  /// though `Cosmetic`/`UserCosmetic` have no `toJson`.
  static Map<String, dynamic> _encode(CosmeticsState s) => {
        'catalog': s.catalog.map(_encodeCosmetic).toList(),
        'owned': s.owned.values.map(_encodeOwned).toList(),
      };

  /// Re-emit a [Cosmetic] in the exact snake_case shape `Cosmetic.fromJson`
  /// consumes (colors back to `#RRGGBB` hex).
  static Map<String, dynamic> _encodeCosmetic(Cosmetic c) {
    String? hex(Color? col) => col == null
        ? null
        : '#${(col.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return {
      'id': c.id,
      'type': c.type.apiValue,
      'display_name': c.displayName,
      'description': c.description,
      'emoji': c.emoji,
      'color_hex': hex(c.color),
      'gradient_hex': hex(c.gradient),
      'tier': c.tier,
      'is_animated': c.isAnimated,
      'unlock_level': c.unlockLevel,
    };
  }

  /// Re-emit a [UserCosmetic] in the shape `UserCosmetic.fromJson` consumes.
  static Map<String, dynamic> _encodeOwned(UserCosmetic u) => {
        'cosmetic_id': u.cosmeticId,
        'unlocked_at': u.unlockedAt.toIso8601String(),
        'unlocked_at_level': u.unlockedAtLevel,
        'is_equipped': u.isEquipped,
      };

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
