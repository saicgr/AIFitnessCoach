import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/services/api_client.dart';

/// State for variation percentage preference
class VariationState {
  final int percentage;
  final String description;
  final bool isLoading;
  final String? error;

  const VariationState({
    this.percentage = 30,
    this.description = 'Balanced variety',
    this.isLoading = false,
    this.error,
  });

  VariationState copyWith({
    int? percentage,
    String? description,
    bool? isLoading,
    String? error,
  }) {
    return VariationState(
      percentage: percentage ?? this.percentage,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing variation percentage preference
final variationProvider = StateNotifierProvider<VariationNotifier, VariationState>((ref) {
  return VariationNotifier(ref);
});

class VariationNotifier extends StateNotifier<VariationState> {
  final Ref _ref;

  VariationNotifier(this._ref) : super(const VariationState(isLoading: true)) {
    _loadVariation();
  }

  Future<void> _loadVariation() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final pref = await repo.getVariationPreference(userId);
      state = state.copyWith(
        percentage: pref.variationPercentage,
        description: pref.description,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading variation preference: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadVariation();
  }

  Future<bool> setVariation(int percentage) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      // Optimistic update
      state = state.copyWith(
        percentage: percentage,
        description: _getDescription(percentage),
      );

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final pref = await repo.setVariationPreference(userId, percentage);

      state = state.copyWith(
        percentage: pref.variationPercentage,
        description: pref.description,
      );
      return true;
    } catch (e) {
      debugPrint('Error setting variation preference: $e');
      // Reload on error
      await _loadVariation();
      return false;
    }
  }

  String _getDescription(int percentage) {
    if (percentage == 0) {
      return 'Same exercises every week';
    } else if (percentage <= 25) {
      return 'Minimal variety - mostly consistent';
    } else if (percentage <= 50) {
      return 'Balanced variety';
    } else if (percentage <= 75) {
      return 'High variety - frequent changes';
    } else {
      return 'Maximum variety - new exercises each week';
    }
  }
}
