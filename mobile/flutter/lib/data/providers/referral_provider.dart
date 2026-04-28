import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_summary.dart';
import '../repositories/referral_repository.dart';
import '../services/api_client.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.watch(apiClientProvider));
});

// `.autoDispose` — only the referrals screen reads this; tearing it down
// on screen exit cancels the in-flight request and forces a fresh fetch
// next time the user opens referrals (summary may have changed).
final referralSummaryProvider =
    FutureProvider.autoDispose<ReferralSummary>((ref) async {
  return ref.watch(referralRepositoryProvider).getSummary();
});

@immutable
class ReferralApplyResult {
  final bool success;
  final String message;
  const ReferralApplyResult({required this.success, required this.message});
}

class ReferralApplyNotifier extends StateNotifier<AsyncValue<ReferralApplyResult?>> {
  final ReferralRepository _repo;
  final Ref _ref;
  ReferralApplyNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<ReferralApplyResult> apply(String code) async {
    state = const AsyncValue.loading();
    try {
      final r = await _repo.applyCode(code);
      final result = ReferralApplyResult(success: r.success, message: r.message);
      state = AsyncValue.data(result);
      if (r.success) {
        _ref.invalidate(referralSummaryProvider);
      }
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final referralApplyProvider =
    StateNotifierProvider<ReferralApplyNotifier, AsyncValue<ReferralApplyResult?>>((ref) {
  return ReferralApplyNotifier(ref.watch(referralRepositoryProvider), ref);
});
