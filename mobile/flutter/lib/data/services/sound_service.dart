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

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Custom sound file paths (category -> absolute file path)
  final Map<String, String> _customSoundPaths = {};

  /// Get custom sound path for a category
  String? getCustomSoundPath(String category) => _customSoundPaths[category];

  /// Set a custom sound for a category by copying the file to app storage
  Future<String?> setCustomSound(String category, String sourceFilePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${appDir.path}/custom_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final ext = sourceFilePath.split('.').last.toLowerCase();
      final destPath = '${soundsDir.path}/${category}_custom.$ext';
      await File(sourceFilePath).copy(destPath);

      _customSoundPaths[category] = destPath;

      // Persist
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_sound_$category', destPath);

      debugPrint('✅ [SoundService] Custom sound set for $category: $destPath');
      return destPath;
    } catch (e) {
      debugPrint('❌ [SoundService] Failed to set custom sound: $e');
      return null;
    }
  }

  /// Remove custom sound for a category
  Future<void> removeCustomSound(String category) async {
    final path = _customSoundPaths.remove(category);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_sound_$category');
    debugPrint('🗑️ [SoundService] Custom sound removed for $category');
  }

  /// Load persisted custom sound paths
  Future<void> _loadCustomSoundPaths() async {
    final prefs = await SharedPreferences.getInstance();
    for (final category in ['countdown', 'rest_end', 'exercise_complete', 'workout_complete']) {
      final path = prefs.getString('custom_sound_$category');
      if (path != null && await File(path).exists()) {
        _customSoundPaths[category] = path;
      }
    }
  }

  /// Play a sound - custom (DeviceFileSource) or asset (AssetSource)
  Future<void> _playSound(AudioPlayer? player, String category, String soundType) async {
    if (soundType == 'custom' && _customSoundPaths.containsKey(category)) {
      await player?.setVolume(soundEffectsVolume);
      await player?.play(DeviceFileSource(_customSoundPaths[category]!));
    } else {
      final assetPath = 'audio/$category/$soundType.mp3';
      await player?.setVolume(soundEffectsVolume);
      await player?.play(AssetSource(assetPath));
    }
  }

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize audio players
      _countdownPlayer = AudioPlayer();
      _exerciseCompletePlayer = AudioPlayer();
      _workoutCompletePlayer = AudioPlayer();
      _restEndPlayer = AudioPlayer();

      // Set audio context to mix with other apps (don't pause background music)
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );

      await _loadCustomSoundPaths();

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
      if (countdownSoundType == 'voice') {
        final assetPath = 'audio/countdown/voice_$count.mp3';
        await _countdownPlayer?.setVolume(soundEffectsVolume);
        await _countdownPlayer?.play(AssetSource(assetPath));
      } else {
        await _playSound(_countdownPlayer, 'countdown', countdownSoundType);
      }
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
      await _playSound(_exerciseCompletePlayer, 'exercise_complete', exerciseCompletionSoundType);
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
      await _playSound(_workoutCompletePlayer, 'workout_complete', completionSoundType);
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
      await _playSound(_restEndPlayer, 'rest_end', restTimerSoundType);
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
      AudioPlayer? player;
      switch (category) {
        case 'countdown':
          player = _countdownPlayer;
        case 'exercise_complete':
          player = _exerciseCompletePlayer;
        case 'workout_complete':
          player = _workoutCompletePlayer;
        case 'rest_end':
          player = _restEndPlayer;
        default:
          return;
      }

      if (soundType == 'voice' && category == 'countdown') {
        await player?.setVolume(soundEffectsVolume);
        await player?.play(AssetSource('audio/countdown/voice_3.mp3'));
      } else {
        await _playSound(player, category, soundType);
      }
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
