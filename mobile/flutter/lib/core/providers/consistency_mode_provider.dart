import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Exercise consistency mode options
enum ConsistencyMode {
  vary,
  consistent;

  String get displayName {
    switch (this) {
      case ConsistencyMode.vary:
        return 'Vary Exercises';
      case ConsistencyMode.consistent:
        return 'Keep Consistent';
    }
  }

  String get description {
    switch (this) {
      case ConsistencyMode.vary:
        return 'AI will suggest new exercises to keep workouts fresh';
      case ConsistencyMode.consistent:
        return 'AI will prefer exercises you\'ve done before';
    }
  }

  String get value => name;

  static ConsistencyMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'consistent':
        return ConsistencyMode.consistent;
      case 'vary':
      default:
        return ConsistencyMode.vary;
    }
  }
}

/// State for consistency mode
class ConsistencyModeState {
  final ConsistencyMode mode;
  final bool isLoading;
  final String? error;

  const ConsistencyModeState({
    this.mode = ConsistencyMode.vary,
    this.isLoading = false,
    this.error,
  });

  ConsistencyModeState copyWith({
    ConsistencyMode? mode,
    bool? isLoading,
    String? error,
  }) {
    return ConsistencyModeState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Consistency mode provider
final consistencyModeProvider =
    StateNotifierProvider<ConsistencyModeNotifier, ConsistencyModeState>((ref) {
  return ConsistencyModeNotifier(ref);
});

/// Notifier for managing consistency mode state
class ConsistencyModeNotifier extends StateNotifier<ConsistencyModeState> {
  final Ref _ref;

  ConsistencyModeNotifier(this._ref) : super(const ConsistencyModeState()) {
    _init();
  }

  /// Parse preferences JSON string to Map
  Map<String, dynamic>? _parsePreferences(String? prefsJson) {
    if (prefsJson == null || prefsJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(prefsJson);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Initialize from user preferences
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        final prefsMap = _parsePreferences(authState.user!.preferences);
        if (prefsMap != null) {
          final mode = ConsistencyMode.fromString(
            prefsMap['exercise_consistency']?.toString(),
          );
          state = ConsistencyModeState(mode: mode);
          debugPrint('🔄 [ConsistencyMode] Loaded: ${mode.value}');
          return;
        }
      }
      // Use default if no user or no preferences
      state = const ConsistencyModeState();
      debugPrint('🔄 [ConsistencyMode] Using default: vary');
    } catch (e) {
      debugPrint('❌ [ConsistencyMode] Init error: $e');
      state = ConsistencyModeState(error: e.toString());
    }
  }

  /// Set consistency mode and sync to backend
  Future<void> setMode(ConsistencyMode mode) async {
    if (mode == state.mode) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'exercise_consistency': mode.value},
        );
        debugPrint('🔄 [ConsistencyMode] Synced: ${mode.value}');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(mode: mode, isLoading: false);
      debugPrint('🔄 [ConsistencyMode] Updated to: ${mode.value}');
    } catch (e) {
      debugPrint('❌ [ConsistencyMode] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle between vary and consistent modes
  Future<void> toggle() async {
    final newMode = state.mode == ConsistencyMode.vary
        ? ConsistencyMode.consistent
        : ConsistencyMode.vary;
    await setMode(newMode);
  }

  /// Refresh from user profile
  Future<void> refresh() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user != null) {
      final prefsMap = _parsePreferences(authState.user!.preferences);
      if (prefsMap != null) {
        state = ConsistencyModeState(
          mode: ConsistencyMode.fromString(
            prefsMap['exercise_consistency']?.toString(),
          ),
        );
      }
    }
  }
}
