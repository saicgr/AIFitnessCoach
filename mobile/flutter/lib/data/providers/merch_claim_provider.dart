import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class MerchClaimsNotifier extends StateNotifier<MerchClaimsState> {
  final MerchClaimRepository _repo;
  MerchClaimsNotifier(this._repo) : super(const MerchClaimsState());

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final claims = await _repo.listClaims();
      state = state.copyWith(loading: false, claims: claims);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<MerchClaim> accept(String claimId) async {
    final updated = await _repo.accept(claimId);
    state = state.copyWith(
      claims: state.claims.map((c) => c.id == claimId ? updated : c).toList(),
    );
    return updated;
  }

  Future<MerchClaim> cancel(String claimId) async {
    final updated = await _repo.cancel(claimId);
    state = state.copyWith(
      claims: state.claims.map((c) => c.id == claimId ? updated : c).toList(),
    );
    return updated;
  }
}

final merchClaimsProvider =
    StateNotifierProvider<MerchClaimsNotifier, MerchClaimsState>((ref) {
  final repo = ref.watch(merchClaimRepositoryProvider);
  return MerchClaimsNotifier(repo);
});

/// Convenience: number of claims currently needing a shipping address.
final pendingMerchClaimCountProvider = Provider<int>((ref) {
  return ref.watch(merchClaimsProvider.select((s) => s.pendingCount));
});
