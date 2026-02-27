import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import 'subscription_provider.dart';

/// Represents the limit and usage for a single feature.
class FeatureLimit {
  final int? limit;
  final int used;
  final int? remaining;
  final String? resetPeriod;
  final DateTime? resetsAt;

  const FeatureLimit({
    this.limit,
    this.used = 0,
    this.remaining,
    this.resetPeriod,
    this.resetsAt,
  });

  FeatureLimit copyWith({
    int? limit,
    int? used,
    int? remaining,
    String? resetPeriod,
    DateTime? resetsAt,
  }) {
    return FeatureLimit(
      limit: limit ?? this.limit,
      used: used ?? this.used,
      remaining: remaining ?? this.remaining,
      resetPeriod: resetPeriod ?? this.resetPeriod,
      resetsAt: resetsAt ?? this.resetsAt,
    );
  }

  factory FeatureLimit.fromJson(Map<String, dynamic> json) {
    return FeatureLimit(
      limit: json['limit'] as int?,
      used: json['used'] as int? ?? 0,
      remaining: json['remaining'] as int?,
      resetPeriod: json['reset_period'] as String?,
      resetsAt: json['resets_at'] != null
          ? DateTime.tryParse(json['resets_at'] as String)
          : null,
    );
  }
}

/// State for usage limits tracking.
class UsageLimitsState {
  final Map<String, FeatureLimit> limits;
  final bool isPremium;
  final bool isLoading;
  final String? error;

  const UsageLimitsState({
    this.limits = const {},
    this.isPremium = false,
    this.isLoading = false,
    this.error,
  });

  UsageLimitsState copyWith({
    Map<String, FeatureLimit>? limits,
    bool? isPremium,
    bool? isLoading,
    String? error,
  }) {
    return UsageLimitsState(
      limits: limits ?? this.limits,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier that fetches and manages per-feature usage limits.
class UsageTrackingNotifier extends StateNotifier<UsageLimitsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  Timer? _refreshTimer;

  UsageTrackingNotifier(this._apiClient, this._ref)
      : super(const UsageLimitsState()) {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchLimits();
    });
  }

  /// Fetch feature limits from the backend.
  Future<void> fetchLimits() async {
    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    final subState = _ref.read(subscriptionProvider);
    final isPremium = subState.isPremiumOrHigher;

    if (isPremium) {
      state = UsageLimitsState(isPremium: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.dio.get(
        '/subscriptions/$userId/feature-limits',
      );

      final data = response.data as Map<String, dynamic>;
      final limitsMap = <String, FeatureLimit>{};

      final features = data['features'] as Map<String, dynamic>? ?? data;
      for (final entry in features.entries) {
        if (entry.value is Map<String, dynamic>) {
          limitsMap[entry.key] = FeatureLimit.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      state = state.copyWith(
        limits: limitsMap,
        isPremium: data['is_premium'] as bool? ?? isPremium,
        isLoading: false,
      );

      debugPrint('✅ Usage limits fetched: ${limitsMap.length} features');
    } catch (e) {
      debugPrint('❌ Failed to fetch usage limits: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load usage limits',
      );
    }
  }

  /// Whether the user can still use the given feature.
  bool hasAccess(String featureKey) {
    if (state.isPremium) return true;
    final feature = state.limits[featureKey];
    if (feature == null) return true; // Unknown features default to allowed
    if (feature.limit == null) return true; // No limit set
    return (feature.remaining ?? (feature.limit! - feature.used)) > 0;
  }

  /// Number of remaining uses for the feature, or null if unlimited.
  int? remainingUses(String featureKey) {
    if (state.isPremium) return null;
    final feature = state.limits[featureKey];
    if (feature == null) return null;
    if (feature.limit == null) return null;
    return feature.remaining ?? (feature.limit! - feature.used);
  }

  /// Optimistically decrement a feature's remaining count locally.
  void decrementLocal(String featureKey) {
    final feature = state.limits[featureKey];
    if (feature == null) return;

    final currentRemaining =
        feature.remaining ?? ((feature.limit ?? 0) - feature.used);
    final newRemaining = (currentRemaining - 1).clamp(0, feature.limit ?? 999);

    final updated = feature.copyWith(
      used: feature.used + 1,
      remaining: newRemaining,
    );

    state = state.copyWith(
      limits: {...state.limits, featureKey: updated},
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Usage tracking provider.
final usageTrackingProvider =
    StateNotifierProvider<UsageTrackingNotifier, UsageLimitsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsageTrackingNotifier(apiClient, ref);
});
