/// Sound service for playing workout sounds.
///
/// This addresses user feedback about cheesy sounds being customizable.
///
/// Features:
/// - Countdown beeps (3, 2, 1)
/// - Exercise completion sounds (when all sets of an exercise are done)
/// - Workout completion sounds (NO applause)
/// - Rest timer end notifications
/// - Volume control
/// - Sound type selection
///
/// Sound Categories:
/// - Countdown: beep, chime, voice, tick, none
/// - Exercise Complete: chime, bell, ding, pop, whoosh, none
/// - Workout Complete: chime, bell, success, fanfare, none (NO APPLAUSE!)
/// - Rest End: beep, chime, gong, none
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for playing workout sound effects.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isInitialized = false;

  // Audio players for each sound category
  AudioPlayer? _countdownPlayer;
  AudioPlayer? _exerciseCompletePlayer;
  AudioPlayer? _workoutCompletePlayer;
  AudioPlayer? _restEndPlayer;

  // Sound preferences (can be updated from settings)
  bool countdownSoundEnabled = true;
  String countdownSoundType = 'beep';
  bool completionSoundEnabled = true;
  String completionSoundType = 'chime'; // NO applause option
  bool restTimerSoundEnabled = true;
  String restTimerSoundType = 'beep';
  bool exerciseCompletionSoundEnabled = true;
  String exerciseCompletionSoundType = 'chime';
  double soundEffectsVolume = 0.8;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize audio players
      _countdownPlayer = AudioPlayer();
      _exerciseCompletePlayer = AudioPlayer();
      _workoutCompletePlayer = AudioPlayer();
      _restEndPlayer = AudioPlayer();

      // Set audio context for mixing with other apps
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _isInitialized = true;
      debugPrint('✅ [SoundService] Initialized with audio playback');
    } catch (e) {
      debugPrint('❌ [SoundService] Initialization failed: $e');
      // Fall back to haptic-only mode
      _isInitialized = true;
    }
  }

  /// Update sound preferences
  void updatePreferences({
    bool? countdownEnabled,
    String? countdownType,
    bool? completionEnabled,
    String? completionType,
    bool? restTimerEnabled,
    String? restTimerType,
    bool? exerciseCompletionEnabled,
    String? exerciseCompletionType,
    double? volume,
  }) {
    if (countdownEnabled != null) countdownSoundEnabled = countdownEnabled;
    if (countdownType != null) countdownSoundType = countdownType;
    if (completionEnabled != null) completionSoundEnabled = completionEnabled;
    if (completionType != null) completionSoundType = completionType;
    if (restTimerEnabled != null) restTimerSoundEnabled = restTimerEnabled;
    if (restTimerType != null) restTimerSoundType = restTimerType;
    if (exerciseCompletionEnabled != null) {
      exerciseCompletionSoundEnabled = exerciseCompletionEnabled;
    }
    if (exerciseCompletionType != null) {
      exerciseCompletionSoundType = exerciseCompletionType;
    }
    if (volume != null) {
      soundEffectsVolume = volume.clamp(0.0, 1.0);
    }
  }

  /// Play countdown sound (3, 2, 1)
  Future<void> playCountdownBeep(int count) async {
    if (!countdownSoundEnabled || countdownSoundType == 'none') return;

    // Haptic feedback
    if (count <= 3 && count > 0) {
      HapticFeedback.mediumImpact();
    }

    // Audio playback
    try {
      String assetPath;
      if (countdownSoundType == 'voice') {
        assetPath = 'audio/countdown/voice_$count.mp3';
      } else {
        assetPath = 'audio/countdown/$countdownSoundType.mp3';
      }

      await _countdownPlayer?.setVolume(soundEffectsVolume);
      await _countdownPlayer?.play(AssetSource(assetPath));
      debugPrint('🔊 [SoundService] Countdown: $count ($countdownSoundType)');
    } catch (e) {
      debugPrint('⚠️ [SoundService] Countdown sound error: $e');
    }
  }

  /// Play exercise completion sound (when all sets of an exercise are done)
  Future<void> playExerciseCompletionSound() async {
    if (!exerciseCompletionSoundEnabled ||
        exerciseCompletionSoundType == 'none') {
      return;
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Audio playback
    try {
      final assetPath =
          'audio/exercise_complete/$exerciseCompletionSoundType.mp3';
      await _exerciseCompletePlayer?.setVolume(soundEffectsVolume);
      await _exerciseCompletePlayer?.play(AssetSource(assetPath));
      debugPrint(
          '🔊 [SoundService] Exercise complete ($exerciseCompletionSoundType)');
    } catch (e) {
      debugPrint('⚠️ [SoundService] Exercise completion sound error: $e');
    }
  }

  /// Play workout completion sound (entire workout finished)
  Future<void> playWorkoutCompletionSound() async {
    if (!completionSoundEnabled || completionSoundType == 'none') return;

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Audio playback
    try {
      final assetPath = 'audio/workout_complete/$completionSoundType.mp3';
      await _workoutCompletePlayer?.setVolume(soundEffectsVolume);
      await _workoutCompletePlayer?.play(AssetSource(assetPath));
      debugPrint('🔊 [SoundService] Workout complete ($completionSoundType)');
    } catch (e) {
      debugPrint('⚠️ [SoundService] Workout completion sound error: $e');
    }
  }

  /// Play rest timer end sound
  Future<void> playRestTimerSound() async {
    if (!restTimerSoundEnabled || restTimerSoundType == 'none') return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Audio playback
    try {
      final assetPath = 'audio/rest_end/$restTimerSoundType.mp3';
      await _restEndPlayer?.setVolume(soundEffectsVolume);
      await _restEndPlayer?.play(AssetSource(assetPath));
      debugPrint('🔊 [SoundService] Rest timer end ($restTimerSoundType)');
    } catch (e) {
      debugPrint('⚠️ [SoundService] Rest timer sound error: $e');
    }
  }

  /// Legacy method for backward compatibility - plays workout completion
  Future<void> playCompletionSound() async {
    await playWorkoutCompletionSound();
  }

  /// Play a specific sound file (for preview in settings)
  Future<void> playPreviewSound(String category, String soundType) async {
    if (soundType == 'none') return;

    try {
      String assetPath;
      AudioPlayer? player;

      switch (category) {
        case 'countdown':
          assetPath = soundType == 'voice'
              ? 'audio/countdown/voice_3.mp3'
              : 'audio/countdown/$soundType.mp3';
          player = _countdownPlayer;
          break;
        case 'exercise_complete':
          assetPath = 'audio/exercise_complete/$soundType.mp3';
          player = _exerciseCompletePlayer;
          break;
        case 'workout_complete':
          assetPath = 'audio/workout_complete/$soundType.mp3';
          player = _workoutCompletePlayer;
          break;
        case 'rest_end':
          assetPath = 'audio/rest_end/$soundType.mp3';
          player = _restEndPlayer;
          break;
        default:
          return;
      }

      await player?.setVolume(soundEffectsVolume);
      await player?.play(AssetSource(assetPath));
      HapticFeedback.selectionClick();
      debugPrint('🔊 [SoundService] Preview: $category/$soundType');
    } catch (e) {
      debugPrint('⚠️ [SoundService] Preview sound error: $e');
    }
  }

  /// Play a generic notification sound
  Future<void> playNotification() async {
    HapticFeedback.selectionClick();

    try {
      await _countdownPlayer?.setVolume(soundEffectsVolume);
      await _countdownPlayer?.play(AssetSource('audio/countdown/beep.mp3'));
    } catch (e) {
      // Haptic feedback is the fallback
    }
  }

  /// Stop any currently playing sound
  Future<void> stop() async {
    try {
      await _countdownPlayer?.stop();
      await _exerciseCompletePlayer?.stop();
      await _workoutCompletePlayer?.stop();
      await _restEndPlayer?.stop();
    } catch (e) {
      debugPrint('⚠️ [SoundService] Stop error: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    _countdownPlayer?.dispose();
    _exerciseCompletePlayer?.dispose();
    _workoutCompletePlayer?.dispose();
    _restEndPlayer?.dispose();
    _countdownPlayer = null;
    _exerciseCompletePlayer = null;
    _workoutCompletePlayer = null;
    _restEndPlayer = null;
    _isInitialized = false;
  }
}
