import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_preferences.dart';
import '../repositories/audio_preferences_repository.dart';

// ============================================
// AUDIO PREFERENCES STATE
// ============================================

/// Complete audio preferences state
class AudioPreferencesState {
  final AudioPreferences? preferences;
  final bool isLoading;
  final String? error;

  const AudioPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
  });

  AudioPreferencesState copyWith({
    AudioPreferences? preferences,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AudioPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if background music is allowed
  bool get allowsBackgroundMusic =>
      preferences?.allowBackgroundMusic ?? true;

  /// Check if audio ducking is enabled
  bool get hasDuckingEnabled =>
      preferences?.audioDucking ?? true;

  /// Get TTS volume
  double get ttsVolume => preferences?.ttsVolume ?? 1.0;

  /// Get duck volume level
  double get duckVolumeLevel => preferences?.duckVolumeLevel ?? 0.3;
}

// ============================================
// AUDIO PREFERENCES NOTIFIER
// ============================================

/// Audio preferences state notifier
class AudioPreferencesNotifier extends StateNotifier<AudioPreferencesState> {
  final AudioPreferencesRepository _repository;

  AudioPreferencesNotifier(this._repository)
      : super(const AudioPreferencesState());

  /// Initialize audio preferences for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔊 [AudioPrefsProvider] Initializing for $userId');
      final preferences = await _repository.getPreferences(userId);
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
      debugPrint(
          '✅ [AudioPrefsProvider] Initialized: backgroundMusic=${preferences.allowBackgroundMusic}');
    } catch (e) {
      debugPrint('❌ [AudioPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update allow background music preference
  Future<void> setAllowBackgroundMusic(String userId, bool value) async {
    await _updatePreference(
      userId: userId,
      type: AudioPreferenceType.allowBackgroundMusic,
      value: value,
      optimisticUpdate: (prefs) => prefs.copyWith(allowBackgroundMusic: value),
    );
  }

  /// Update TTS volume preference
  Future<void> setTtsVolume(String userId, double value) async {
    await _updatePreference(
      userId: userId,
      type: AudioPreferenceType.ttsVolume,
      value: value,
      optimisticUpdate: (prefs) => prefs.copyWith(ttsVolume: value),
    );
  }

  /// Update audio ducking preference
  Future<void> setAudioDucking(String userId, bool value) async {
    await _updatePreference(
      userId: userId,
      type: AudioPreferenceType.audioDucking,
      value: value,
      optimisticUpdate: (prefs) => prefs.copyWith(audioDucking: value),
    );
  }

  /// Update duck volume level preference
  Future<void> setDuckVolumeLevel(String userId, double value) async {
    await _updatePreference(
      userId: userId,
      type: AudioPreferenceType.duckVolumeLevel,
      value: value,
      optimisticUpdate: (prefs) => prefs.copyWith(duckVolumeLevel: value),
    );
  }

  /// Update mute during video preference
  Future<void> setMuteDuringVideo(String userId, bool value) async {
    await _updatePreference(
      userId: userId,
      type: AudioPreferenceType.muteDuringVideo,
      value: value,
      optimisticUpdate: (prefs) => prefs.copyWith(muteDuringVideo: value),
    );
  }

  /// Generic method to update a single preference with optimistic update
  Future<void> _updatePreference({
    required String userId,
    required AudioPreferenceType type,
    required dynamic value,
    required AudioPreferences Function(AudioPreferences) optimisticUpdate,
  }) async {
    // Optimistically update the UI
    final previousPrefs = state.preferences;
    if (previousPrefs != null) {
      state = state.copyWith(
        preferences: optimisticUpdate(previousPrefs),
        clearError: true,
      );
    }

    try {
      debugPrint('🔊 [AudioPrefsProvider] Updating ${type.name} to $value');
      final preferences = await _repository.updateSinglePreference(
        userId: userId,
        type: type,
        value: value,
      );
      state = state.copyWith(preferences: preferences);
      debugPrint('✅ [AudioPrefsProvider] ${type.name} updated');
    } catch (e) {
      debugPrint('❌ [AudioPrefsProvider] Update error: $e');
      // Revert on error
      if (previousPrefs != null) {
        state = state.copyWith(preferences: previousPrefs, error: e.toString());
      } else {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  /// Update all preferences at once
  Future<void> updateAllPreferences({
    required String userId,
    bool? allowBackgroundMusic,
    double? ttsVolume,
    bool? audioDucking,
    double? duckVolumeLevel,
    bool? muteDuringVideo,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔊 [AudioPrefsProvider] Updating all preferences');
      final preferences = await _repository.updatePreferences(
        userId: userId,
        allowBackgroundMusic: allowBackgroundMusic,
        ttsVolume: ttsVolume,
        audioDucking: audioDucking,
        duckVolumeLevel: duckVolumeLevel,
        muteDuringVideo: muteDuringVideo,
      );
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
      debugPrint('✅ [AudioPrefsProvider] All preferences updated');
    } catch (e) {
      debugPrint('❌ [AudioPrefsProvider] Update all error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Audio preferences state provider
final audioPreferencesProvider =
    StateNotifierProvider<AudioPreferencesNotifier, AudioPreferencesState>(
        (ref) {
  return AudioPreferencesNotifier(
    ref.watch(audioPreferencesRepositoryProvider),
  );
});

/// Convenience provider for just the preferences object
final currentAudioPreferencesProvider = Provider<AudioPreferences?>((ref) {
  return ref.watch(audioPreferencesProvider).preferences;
});

/// Convenience provider to check if loading
final audioPreferencesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(audioPreferencesProvider).isLoading;
});

/// Convenience provider for error state
final audioPreferencesErrorProvider = Provider<String?>((ref) {
  return ref.watch(audioPreferencesProvider).error;
});

/// Provider to check if background music is allowed
final allowsBackgroundMusicProvider = Provider<bool>((ref) {
  return ref.watch(audioPreferencesProvider).allowsBackgroundMusic;
});

/// Provider to check if audio ducking is enabled
final hasDuckingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(audioPreferencesProvider).hasDuckingEnabled;
});

/// Provider for TTS volume
final ttsVolumeProvider = Provider<double>((ref) {
  return ref.watch(audioPreferencesProvider).ttsVolume;
});
