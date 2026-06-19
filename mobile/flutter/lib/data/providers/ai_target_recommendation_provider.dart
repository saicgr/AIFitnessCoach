import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ai_target_recommendation_repository.dart';

/// The on-demand state of the AI "Recommend Targets" fetch. A small explicit
/// state object (rather than an `AsyncValue`) so the preview sheet can keep the
/// last good [result] visible while a forced re-analyze runs, and so the
/// "Analyzing your nutrition…" copy is a first-class state — not just a generic
/// spinner. Mirrors the loading / result / error shape of the progress-analysis
/// feature.
class AiTargetRecommendationState {
  /// True while a fetch is in flight (initial analyze OR a forced refresh).
  final bool isLoading;

  /// The last successfully-parsed recommendation, or null before the first
  /// successful fetch. Kept across a forced refresh so the sheet doesn't blank.
  final NutritionTargetsRecommendation? result;

  /// A user-facing error message from the last failed fetch, or null. Per
  /// `feedback_no_silent_fallbacks` a failure surfaces here — never fake data.
  final String? error;

  const AiTargetRecommendationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  AiTargetRecommendationState copyWith({
    bool? isLoading,
    NutritionTargetsRecommendation? result,
    String? error,
    bool clearError = false,
  }) {
    return AiTargetRecommendationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the AI target-recommendation fetch for the Edit Targets sheet. One
/// notifier per sheet instance (the provider is `autoDispose`), so closing the
/// sheet discards the in-memory recommendation and the next open re-analyzes.
class AiTargetRecommendationNotifier
    extends StateNotifier<AiTargetRecommendationState> {
  final AiTargetRecommendationRepository _repository;

  AiTargetRecommendationNotifier(this._repository)
      : super(const AiTargetRecommendationState());

  /// Run the analysis. [force] true bypasses the server cache to regenerate.
  /// Coalesces nothing — the UI disables the trigger while [isLoading] is true.
  Future<void> analyze({bool force = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rec = await _repository.fetchRecommendation(force: force);
      state = AiTargetRecommendationState(isLoading: false, result: rec);
    } catch (e) {
      debugPrint('❌ [AiTargetRecommendation] analyze failed: $e');
      state = state.copyWith(
        isLoading: false,
        // Keep the prior result (if any) so a failed re-analyze doesn't wipe a
        // good recommendation; the sheet shows the error banner alongside.
        error: 'Could not build your recommendation. Tap to retry.',
      );
    }
  }
}

/// The AI target-recommendation provider. `autoDispose` so each Edit Targets
/// sheet starts fresh — there's no value in caching a stale recommendation in
/// memory after the sheet closes (the backend caches it server-side anyway).
final aiTargetRecommendationProvider = StateNotifierProvider.autoDispose<
    AiTargetRecommendationNotifier, AiTargetRecommendationState>((ref) {
  return AiTargetRecommendationNotifier(
    ref.watch(aiTargetRecommendationRepositoryProvider),
  );
});
