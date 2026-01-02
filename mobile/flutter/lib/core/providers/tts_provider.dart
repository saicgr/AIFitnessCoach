import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/audio_session_service.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Provider for the AudioSession service singleton.
///
/// This ensures the audio session is properly configured for mixing
/// with other apps (like Spotify) before any TTS is used.
final audioSessionServiceProvider = Provider<AudioSessionService>((ref) {
  final service = AudioSessionService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the TTS service singleton.
final ttsServiceProvider = Provider<TTSService>((ref) {
  final service = TTSService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Voice announcements state
class VoiceAnnouncementsState {
  /// Whether voice announcements are enabled.
  final bool isEnabled;

  /// Whether the state is loading.
  final bool isLoading;

  /// Error message, if any.
  final String? error;

  const VoiceAnnouncementsState({
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
  });

  VoiceAnnouncementsState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? error,
  }) {
    return VoiceAnnouncementsState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for voice announcements enabled state.
///
/// This persists the setting locally and syncs to backend.
final voiceAnnouncementsProvider =
    StateNotifierProvider<VoiceAnnouncementsNotifier, VoiceAnnouncementsState>(
        (ref) {
  return VoiceAnnouncementsNotifier(ref);
});

/// Notifier for managing voice announcements state.
class VoiceAnnouncementsNotifier extends StateNotifier<VoiceAnnouncementsState> {
  final Ref _ref;
  static const String _prefsKey = 'voice_announcements_enabled';

  VoiceAnnouncementsNotifier(this._ref) : super(const VoiceAnnouncementsState()) {
    _init();
  }

  /// Initialize from local storage.
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_prefsKey) ?? false;

      state = VoiceAnnouncementsState(isEnabled: isEnabled);
      debugPrint('   [VoiceAnnouncements] Loaded: enabled=$isEnabled');

      // Initialize TTS if enabled
      if (isEnabled) {
        await _ref.read(ttsServiceProvider).init();
      }
    } catch (e) {
      debugPrint('   [VoiceAnnouncements] Init error: $e');
      state = VoiceAnnouncementsState(error: e.toString());
    }
  }

  /// Toggle voice announcements on/off.
  Future<void> toggle() async {
    await setEnabled(!state.isEnabled);
  }

  /// Set voice announcements enabled state.
  Future<void> setEnabled(bool enabled) async {
    if (enabled == state.isEnabled) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save locally first for instant feedback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, enabled);

      // Initialize TTS if enabling
      if (enabled) {
        await _ref.read(ttsServiceProvider).init();
      }

      // Sync to backend
      try {
        final apiClient = _ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();

        if (userId != null) {
          await apiClient.put(
            '${ApiConstants.users}/$userId',
            data: {
              'notification_preferences': {
                'voice_announcements_enabled': enabled,
              },
            },
          );
          debugPrint('   [VoiceAnnouncements] Synced to backend: enabled=$enabled');
        }
      } catch (syncError) {
        // Don't fail the operation if backend sync fails
        debugPrint('   [VoiceAnnouncements] Backend sync failed: $syncError');
      }

      state = state.copyWith(isEnabled: enabled, isLoading: false);
      debugPrint('   [VoiceAnnouncements] Updated to: enabled=$enabled');
    } catch (e) {
      debugPrint('   [VoiceAnnouncements] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Speak announcement if voice is enabled.
  Future<void> announceIfEnabled(String text) async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).speak(text);
    }
  }

  /// Announce next exercise if voice is enabled.
  Future<void> announceNextExerciseIfEnabled(String exerciseName) async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).announceNextExercise(exerciseName);
    }
  }

  /// Announce rest start if voice is enabled.
  Future<void> announceRestStartIfEnabled(int seconds) async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).announceRestStart(seconds);
    }
  }

  /// Announce rest end if voice is enabled.
  Future<void> announceRestEndIfEnabled() async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).announceRestEnd();
    }
  }

  /// Announce workout complete if voice is enabled.
  Future<void> announceWorkoutCompleteIfEnabled() async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).announceWorkoutComplete();
    }
  }

  /// Announce countdown if voice is enabled (for last 3 seconds).
  Future<void> announceCountdownIfEnabled(int seconds) async {
    if (state.isEnabled) {
      await _ref.read(ttsServiceProvider).announceCountdown(seconds);
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    await _ref.read(ttsServiceProvider).stop();
  }
}
