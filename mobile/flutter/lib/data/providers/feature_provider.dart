import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feature_request.dart';
import '../repositories/auth_repository.dart';
import '../repositories/feature_repository.dart';

/// Features state provider
final featuresProvider =
    StateNotifierProvider<FeaturesNotifier, AsyncValue<List<FeatureRequest>>>(
  (ref) {
    final repository = ref.watch(featureRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    return FeaturesNotifier(repository, userId);
  },
);

/// Provider for remaining submissions count
final remainingSubmissionsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final repository = ref.watch(featureRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return {'used': 0, 'remaining': 2, 'total_limit': 2};
    }

    return await repository.getRemainingSubmissions(userId);
  },
);

/// Features state notifier
class FeaturesNotifier extends StateNotifier<AsyncValue<List<FeatureRequest>>> {
  final FeatureRepository _repository;
  final String? _userId;

  FeaturesNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  /// Refresh features list
  Future<void> refresh({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final features = await _repository.getFeatures(
        status: status,
        userId: _userId,
      );
      state = AsyncValue.data(features);
    } catch (e, stackTrace) {
      debugPrint('❌ [FeaturesNotifier] Error refreshing features: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Toggle vote for a feature (optimistic update with rollback on error)
  Future<void> toggleVote(String featureId) async {
    if (_userId == null) {
      debugPrint('❌ [FeaturesNotifier] Cannot vote - user not authenticated');
      return;
    }

    // Optimistic update
    state.whenData((features) {
      final updatedFeatures = features.map((feature) {
        if (feature.id == featureId) {
          final newVoted = !feature.userHasVoted;
          final newCount = feature.voteCount + (newVoted ? 1 : -1);
          return feature.copyWith(
            userHasVoted: newVoted,
            voteCount: newCount,
          );
        }
        return feature;
      }).toList();

      state = AsyncValue.data(updatedFeatures);
    });

    try {
      // Make API call
      await _repository.toggleVote(
        featureId: featureId,
        userId: _userId,
      );
      debugPrint('✅ [FeaturesNotifier] Vote toggled successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FeaturesNotifier] Error toggling vote: $e');
      // Rollback optimistic update on error
      await refresh();
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create a new feature suggestion
  Future<FeatureRequest> createFeature({
    required String title,
    required String description,
    required String category,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('🔍 [FeaturesNotifier] Creating feature: $title');

      final newFeature = await _repository.createFeature(
        title: title,
        description: description,
        category: category,
        userId: _userId,
      );

      debugPrint('✅ [FeaturesNotifier] Feature created successfully');

      // Refresh the list to include the new feature
      await refresh();

      return newFeature;
    } catch (e) {
      debugPrint('❌ [FeaturesNotifier] Error creating feature: $e');
      rethrow;
    }
  }

  /// Get features by status (helper method)
  List<FeatureRequest> getFeaturesByStatus(String status) {
    return state.when(
      data: (features) => features.where((f) => f.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get voting features
  List<FeatureRequest> get votingFeatures => getFeaturesByStatus('voting');

  /// Get planned features (with countdown timers)
  List<FeatureRequest> get plannedFeatures => getFeaturesByStatus('planned');

  /// Get in-progress features
  List<FeatureRequest> get inProgressFeatures =>
      getFeaturesByStatus('in_progress');

  /// Get released features
  List<FeatureRequest> get releasedFeatures => getFeaturesByStatus('released');

  /// Get top voted planned features for home screen (max 3)
  List<FeatureRequest> get topPlannedFeatures {
    return state.when(
      data: (features) {
        return features
            .where((f) => f.status == 'planned' && f.releaseDate != null)
            .take(3)
            .toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }
}
