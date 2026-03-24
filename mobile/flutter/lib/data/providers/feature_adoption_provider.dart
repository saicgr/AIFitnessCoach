import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'milestones_provider.dart';

// ============================================
// Feature Adoption Model
// ============================================

/// Represents a single adopted feature with usage metadata.
class FeatureAdoption {
  final String id;
  final String featureKey;
  final String firstUsedAt;
  final int useCount;
  final String lastUsedAt;

  const FeatureAdoption({
    required this.id,
    required this.featureKey,
    required this.firstUsedAt,
    required this.useCount,
    required this.lastUsedAt,
  });

  factory FeatureAdoption.fromJson(Map<String, dynamic> json) {
    return FeatureAdoption(
      id: json['id'] as String,
      featureKey: json['feature_key'] as String,
      firstUsedAt: json['first_used_at'] as String,
      useCount: json['use_count'] as int? ?? 1,
      lastUsedAt: json['last_used_at'] as String,
    );
  }
}

// ============================================
// Feature Adoption State
// ============================================

class FeatureAdoptionState {
  final Map<String, FeatureAdoption> features;
  final bool isLoading;
  final String? error;

  const FeatureAdoptionState({
    this.features = const {},
    this.isLoading = false,
    this.error,
  });

  FeatureAdoptionState copyWith({
    Map<String, FeatureAdoption>? features,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FeatureAdoptionState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if a feature has been used at least once.
  bool hasUsedFeature(String key) => features.containsKey(key);

  /// Get the use count for a feature (0 if never used).
  int useCount(String key) => features[key]?.useCount ?? 0;
}

// ============================================
// Feature Adoption Notifier
// ============================================

class FeatureAdoptionNotifier extends StateNotifier<FeatureAdoptionState> {
  final ApiClient _apiClient;
  final MilestonesNotifier? _milestonesNotifier;
  String? _currentUserId;

  /// Maps feature adoption keys to first_steps milestone triggers.
  static const _featureToMilestoneTrigger = <String, String>{
    'first_workout_completed': 'first_workout_completed',
    'first_photo_meal': 'first_photo_meal',
    'first_barcode_scan': 'first_barcode_scan',
    'first_chat_message': 'first_chat_message',
  };

  /// Feature keys currently being tracked (to avoid duplicate in-flight requests).
  final Set<String> _inFlightKeys = {};

  FeatureAdoptionNotifier(this._apiClient, [this._milestonesNotifier])
      : super(const FeatureAdoptionState());

  /// Set user ID for this session.
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all adopted features from the backend.
  Future<void> loadAdoption({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[FeatureAdoption] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get(
        '/analytics/$uid/feature-adoption',
      );

      final data = response.data as Map<String, dynamic>;
      final featuresList = data['features'] as List<dynamic>? ?? [];

      final featuresMap = <String, FeatureAdoption>{};
      for (final item in featuresList) {
        final adoption =
            FeatureAdoption.fromJson(item as Map<String, dynamic>);
        featuresMap[adoption.featureKey] = adoption;
      }

      state = state.copyWith(features: featuresMap, isLoading: false);
      debugPrint(
          '[FeatureAdoption] Loaded ${featuresMap.length} adopted features');
    } catch (e) {
      debugPrint('[FeatureAdoption] Error loading adoption: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feature adoption: $e',
      );
    }
  }

  /// Record usage of a feature. Upserts on the backend:
  /// - First call creates the record (use_count=1).
  /// - Subsequent calls increment use_count.
  ///
  /// Updates local state optimistically.
  Future<void> trackFeature(String key) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[FeatureAdoption] No user ID, skipping track');
      return;
    }

    // Deduplicate concurrent calls for the same key
    if (_inFlightKeys.contains(key)) return;
    _inFlightKeys.add(key);

    try {
      final response = await _apiClient.post(
        '/analytics/$uid/feature-adoption',
        data: {'feature_key': key},
      );

      final data = response.data as Map<String, dynamic>;
      final useCount = data['use_count'] as int? ?? 1;
      final isFirstUse = data['is_first_use'] as bool? ?? false;

      // Update local state
      final existing = state.features[key];
      final now = DateTime.now().toIso8601String();
      final updated = FeatureAdoption(
        id: existing?.id ?? '',
        featureKey: key,
        firstUsedAt: existing?.firstUsedAt ?? now,
        useCount: useCount,
        lastUsedAt: now,
      );

      final newFeatures = Map<String, FeatureAdoption>.from(state.features);
      newFeatures[key] = updated;
      state = state.copyWith(features: newFeatures);

      if (isFirstUse) {
        debugPrint('[FeatureAdoption] First use of "$key"');
        // Check if this feature maps to a first_steps milestone
        final milestoneTrigger = _featureToMilestoneTrigger[key];
        if (milestoneTrigger != null && _milestonesNotifier != null) {
          // Fire-and-forget: award the milestone in the background
          _milestonesNotifier.awardFirstStep(milestoneTrigger);
        }
      } else {
        debugPrint('[FeatureAdoption] Tracked "$key" (count: $useCount)');
      }
    } catch (e) {
      debugPrint('[FeatureAdoption] Error tracking "$key": $e');
      // Non-blocking: don't update error state for tracking failures
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  /// Check if a feature has been used at least once.
  bool hasUsedFeature(String key) => state.hasUsedFeature(key);

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Main feature adoption provider.
final featureAdoptionProvider =
    StateNotifierProvider<FeatureAdoptionNotifier, FeatureAdoptionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final milestonesNotifier = ref.watch(milestonesProvider.notifier);
  return FeatureAdoptionNotifier(apiClient, milestonesNotifier);
});

/// Whether a specific feature has been used (convenience family provider).
final hasUsedFeatureProvider = Provider.family<bool, String>((ref, key) {
  return ref.watch(featureAdoptionProvider).hasUsedFeature(key);
});

/// Use count for a specific feature (convenience family provider).
final featureUseCountProvider = Provider.family<int, String>((ref, key) {
  return ref.watch(featureAdoptionProvider).useCount(key);
});

/// Loading state (convenience provider).
final featureAdoptionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(featureAdoptionProvider).isLoading;
});
