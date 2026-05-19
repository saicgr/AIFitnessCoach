import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../core/providers/auth_provider.dart';
import '../models/referral_summary.dart';
import '../repositories/referral_repository.dart';
import '../services/api_client.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.watch(apiClientProvider));
});

/// Cache-first referral summary notifier (Part-1 instant-load standard).
///
/// On open it emits the last-known summary from disk synchronously-fast (so the
/// referrals screen renders instantly with no spinner), then revalidates over
/// the network and write-through-persists the fresh value. The referral code is
/// permanent and the counts change rarely, so a stale-but-instant render is the
/// right trade.
class ReferralSummaryNotifier extends StateNotifier<AsyncValue<ReferralSummary>>
    with CacheFirstMixin {
  ReferralSummaryNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final ReferralRepository _repo;
  final String _userId;

  /// SharedPreferences slot age before a cached summary is considered stale.
  static const _ttl = Duration(hours: 12);

  Future<void> load() => loadCacheFirst<ReferralSummary>(
        cacheKey: 'referral_summary',
        userId: _userId,
        ttl: _ttl,
        fetch: () => _repo.getSummary(),
        decode: ReferralSummary.fromJson,
        // ReferralSummary.fromJson reads these exact snake_case keys, so the
        // round-trip is loss-free without needing a toJson on the model.
        encode: (s) => {
          'referral_code': s.referralCode,
          'pending_count': s.pendingCount,
          'qualified_count': s.qualifiedCount,
          'next_milestone': s.nextMilestone,
          'next_merch_type': s.nextMerchType,
        },
        emit: (data, {required bool fromCache}) {
          if (mounted) state = AsyncValue.data(data);
        },
        onError: (e, st) {
          // Only surface the error if nothing (cached or fresh) is on screen.
          if (mounted && state is! AsyncData) state = AsyncValue.error(e, st);
        },
      );

  /// Drop the disk cache and re-fetch — used after a code is applied so the
  /// qualified_count reflects the change on the next render.
  Future<void> refresh() async {
    await invalidateCacheFirst(cacheKey: 'referral_summary', userId: _userId);
    await load();
  }
}

// `.autoDispose` — only the referrals screen reads this; tearing it down on
// screen exit cancels the in-flight request. The disk cache (CacheFirstMixin)
// makes the *next* open instant regardless of autoDispose.
final referralSummaryProvider = StateNotifierProvider.autoDispose<
    ReferralSummaryNotifier, AsyncValue<ReferralSummary>>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return ReferralSummaryNotifier(ref.watch(referralRepositoryProvider), userId);
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
        // Force a clean re-fetch (cache invalidated) so qualified_count updates.
        _ref.read(referralSummaryProvider.notifier).refresh();
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
