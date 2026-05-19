import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../models/merch_claim.dart';
import '../repositories/merch_claim_repository.dart';
import '../services/api_client.dart';

final merchClaimRepositoryProvider = Provider<MerchClaimRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MerchClaimRepository(client);
});

@immutable
class MerchClaimsState {
  final bool loading;
  final Object? error;
  final List<MerchClaim> claims;

  const MerchClaimsState({
    this.loading = false,
    this.error,
    this.claims = const [],
  });

  List<MerchClaim> get pending =>
      claims.where((c) => c.status == 'pending_address').toList();

  List<MerchClaim> get active =>
      claims.where((c) => c.status != 'cancelled').toList();

  int get pendingCount => pending.length;

  MerchClaimsState copyWith({
    bool? loading,
    Object? error,
    List<MerchClaim>? claims,
    bool clearError = false,
  }) {
    return MerchClaimsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      claims: claims ?? this.claims,
    );
  }
}

class MerchClaimsNotifier extends StateNotifier<MerchClaimsState>
    with CacheFirstMixin {
  final MerchClaimRepository _repo;
  final ApiClient _client;
  MerchClaimsNotifier(this._repo, this._client) : super(const MerchClaimsState());

  /// Cache-first load (Part-1 instant-load standard). Persists the merch-claim
  /// list so a cold start renders the rewards screen instantly from disk, then
  /// revalidates over the network (SWR). Claims change rarely (a new milestone
  /// or a status bump), so a 12h TTL is ample.
  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    final userId = await _client.getUserId() ?? '';
    await loadCacheFirst<List<MerchClaim>>(
      cacheKey: 'merch_claims',
      userId: userId,
      ttl: const Duration(hours: 12),
      fetch: _repo.listClaims,
      // Cached under a `{claims: [...]}` envelope so the decode mirrors the
      // repository's own parsing of the API response.
      decode: (json) => ((json['claims'] as List?) ?? const [])
          .map((j) => MerchClaim.fromJson((j as Map).cast<String, dynamic>()))
          .toList(),
      encode: (claims) => {'claims': claims.map(_encodeClaim).toList()},
      emit: (claims, {required bool fromCache}) {
        if (mounted) {
          state = state.copyWith(loading: false, claims: claims, clearError: true);
        }
      },
      onError: (e, st) {
        // Keep cached claims visible on a network failure; only flag the error
        // so the cold-cache path can show the retry view.
        if (mounted) state = state.copyWith(loading: false, error: e);
      },
    );
  }

  /// Re-emit a [MerchClaim] in the exact shape `MerchClaim.fromJson` consumes
  /// — a loss-free round-trip without a `toJson` on the model.
  static Map<String, dynamic> _encodeClaim(MerchClaim c) => {
        'id': c.id,
        'merch_type': c.merchType,
        'awarded_at_level': c.awardedAtLevel,
        'status': c.status,
        'shipping_full_name': c.shippingFullName,
        'shipping_address_line1': c.shippingAddressLine1,
        'shipping_address_line2': c.shippingAddressLine2,
        'shipping_city': c.shippingCity,
        'shipping_state': c.shippingState,
        'shipping_postal_code': c.shippingPostalCode,
        'shipping_country': c.shippingCountry,
        'shipping_phone': c.shippingPhone,
        'size': c.size,
        'sizes': c.sizes,
        'notes': c.notes,
        'address_submitted_at': c.addressSubmittedAt?.toIso8601String(),
        'tracking_number': c.trackingNumber,
        'carrier': c.carrier,
        'shipped_at': c.shippedAt?.toIso8601String(),
        'delivered_at': c.deliveredAt?.toIso8601String(),
        'cancelled_at': c.cancelledAt?.toIso8601String(),
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };

  Future<MerchClaim> accept(String claimId) async {
    final updated = await _repo.accept(claimId);
    state = state.copyWith(
      claims: state.claims.map((c) => c.id == claimId ? updated : c).toList(),
    );
    _persistCurrent();
    return updated;
  }

  Future<MerchClaim> cancel(String claimId) async {
    final updated = await _repo.cancel(claimId);
    state = state.copyWith(
      claims: state.claims.map((c) => c.id == claimId ? updated : c).toList(),
    );
    _persistCurrent();
    return updated;
  }

  /// Write the current claim list through to disk after a local mutation
  /// (accept/cancel) so a restart reflects the new status instantly.
  Future<void> _persistCurrent() async {
    final userId = await _client.getUserId() ?? '';
    // Re-run loadCacheFirst's write path via a no-op fetch would be wasteful;
    // instead invalidate so the next open does a clean network read, and the
    // in-memory state already shows the mutation.
    await invalidateCacheFirst(cacheKey: 'merch_claims', userId: userId);
  }
}

final merchClaimsProvider =
    StateNotifierProvider<MerchClaimsNotifier, MerchClaimsState>((ref) {
  final repo = ref.watch(merchClaimRepositoryProvider);
  return MerchClaimsNotifier(repo, ref.watch(apiClientProvider));
});

/// Convenience: number of claims currently needing a shipping address.
final pendingMerchClaimCountProvider = Provider<int>((ref) {
  return ref.watch(merchClaimsProvider.select((s) => s.pendingCount));
});
