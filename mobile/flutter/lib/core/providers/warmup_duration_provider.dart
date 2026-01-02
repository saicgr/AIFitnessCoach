import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Warmup and stretch duration preferences state
class WarmupDurationState {
  /// Warmup duration in minutes (1-15)
  final int warmupDurationMinutes;

  /// Stretch/cooldown duration in minutes (1-15)
  final int stretchDurationMinutes;

  /// Whether the state is loading
  final bool isLoading;

  /// Error message, if any
  final String? error;

  const WarmupDurationState({
    this.warmupDurationMinutes = 5,
    this.stretchDurationMinutes = 5,
    this.isLoading = false,
    this.error,
  });

  WarmupDurationState copyWith({
    int? warmupDurationMinutes,
    int? stretchDurationMinutes,
    bool? isLoading,
    String? error,
  }) {
    return WarmupDurationState(
      warmupDurationMinutes: warmupDurationMinutes ?? this.warmupDurationMinutes,
      stretchDurationMinutes: stretchDurationMinutes ?? this.stretchDurationMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for warmup and stretch duration preferences
final warmupDurationProvider =
    StateNotifierProvider<WarmupDurationNotifier, WarmupDurationState>((ref) {
  return WarmupDurationNotifier(ref);
});

/// Notifier for managing warmup and stretch duration preferences
class WarmupDurationNotifier extends StateNotifier<WarmupDurationState> {
  final Ref _ref;

  WarmupDurationNotifier(this._ref) : super(const WarmupDurationState()) {
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

  /// Clamp duration to valid range (1-15)
  int _clampDuration(int? value) {
    if (value == null) return 5;
    return value.clamp(1, 15);
  }

  /// Initialize preferences from user profile
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        final prefsMap = _parsePreferences(authState.user!.preferences);
        if (prefsMap != null) {
          final warmupDuration = _clampDuration(
            prefsMap['warmup_duration_minutes'] as int?,
          );
          final stretchDuration = _clampDuration(
            prefsMap['stretch_duration_minutes'] as int?,
          );
          state = WarmupDurationState(
            warmupDurationMinutes: warmupDuration,
            stretchDurationMinutes: stretchDuration,
          );
          debugPrint(
            '   [WarmupDuration] Loaded: warmup=${warmupDuration}min, stretch=${stretchDuration}min',
          );
          return;
        }
      }
      // Use defaults if no user or no preferences
      state = const WarmupDurationState();
      debugPrint('   [WarmupDuration] Using defaults: warmup=5min, stretch=5min');
    } catch (e) {
      debugPrint('   [WarmupDuration] Init error: $e');
      state = WarmupDurationState(error: e.toString());
    }
  }

  /// Set warmup duration and sync to backend
  Future<void> setWarmupDuration(int minutes) async {
    final clampedMinutes = _clampDuration(minutes);
    if (clampedMinutes == state.warmupDurationMinutes) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        // Get current preferences and merge
        final authState = _ref.read(authStateProvider);
        final currentPrefs = _parsePreferences(authState.user?.preferences) ?? {};
        currentPrefs['warmup_duration_minutes'] = clampedMinutes;

        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'preferences': jsonEncode(currentPrefs)},
        );
        debugPrint('   [WarmupDuration] Synced warmup_duration: ${clampedMinutes}min');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(warmupDurationMinutes: clampedMinutes, isLoading: false);
      debugPrint('   [WarmupDuration] Updated warmup_duration to: ${clampedMinutes}min');
    } catch (e) {
      debugPrint('   [WarmupDuration] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set stretch duration and sync to backend
  Future<void> setStretchDuration(int minutes) async {
    final clampedMinutes = _clampDuration(minutes);
    if (clampedMinutes == state.stretchDurationMinutes) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        // Get current preferences and merge
        final authState = _ref.read(authStateProvider);
        final currentPrefs = _parsePreferences(authState.user?.preferences) ?? {};
        currentPrefs['stretch_duration_minutes'] = clampedMinutes;

        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'preferences': jsonEncode(currentPrefs)},
        );
        debugPrint('   [WarmupDuration] Synced stretch_duration: ${clampedMinutes}min');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(stretchDurationMinutes: clampedMinutes, isLoading: false);
      debugPrint('   [WarmupDuration] Updated stretch_duration to: ${clampedMinutes}min');
    } catch (e) {
      debugPrint('   [WarmupDuration] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set both warmup and stretch duration at once
  Future<void> setBothDurations({
    required int warmupMinutes,
    required int stretchMinutes,
  }) async {
    final clampedWarmup = _clampDuration(warmupMinutes);
    final clampedStretch = _clampDuration(stretchMinutes);

    if (clampedWarmup == state.warmupDurationMinutes &&
        clampedStretch == state.stretchDurationMinutes) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        // Get current preferences and merge
        final authState = _ref.read(authStateProvider);
        final currentPrefs = _parsePreferences(authState.user?.preferences) ?? {};
        currentPrefs['warmup_duration_minutes'] = clampedWarmup;
        currentPrefs['stretch_duration_minutes'] = clampedStretch;

        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'preferences': jsonEncode(currentPrefs)},
        );
        debugPrint(
          '   [WarmupDuration] Synced both: warmup=${clampedWarmup}min, stretch=${clampedStretch}min',
        );
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(
        warmupDurationMinutes: clampedWarmup,
        stretchDurationMinutes: clampedStretch,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('   [WarmupDuration] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh preferences from user profile
  Future<void> refresh() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user != null) {
      final prefsMap = _parsePreferences(authState.user!.preferences);
      if (prefsMap != null) {
        state = WarmupDurationState(
          warmupDurationMinutes: _clampDuration(
            prefsMap['warmup_duration_minutes'] as int?,
          ),
          stretchDurationMinutes: _clampDuration(
            prefsMap['stretch_duration_minutes'] as int?,
          ),
        );
      }
    }
  }
}
