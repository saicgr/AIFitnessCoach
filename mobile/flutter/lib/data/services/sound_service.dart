/// Sound service for playing workout sounds.
///
/// This addresses user feedback about cheesy sounds being customizable.
///
/// Features:
/// - Countdown beeps (3, 2, 1)
/// - Completion sounds (NO applause)
/// - Rest timer notifications
/// - Volume control
/// - Sound type selection
///
/// NOTE: Audio playback is stubbed until audioplayers package is added.
library;

import 'package:flutter/services.dart';

/// Service for playing workout sound effects.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isInitialized = false;

  // Sound preferences (can be updated from settings)
  bool countdownSoundEnabled = true;
  String countdownSoundType = 'beep';
  bool completionSoundEnabled = true;
  String completionSoundType = 'chime'; // NO applause option
  bool restTimerSoundEnabled = true;
  String restTimerSoundType = 'beep';
  double soundEffectsVolume = 0.8;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Initialize audio player when audioplayers package is added
      _isInitialized = true;
      print('   [SoundService] Initialized (haptic feedback only until audio package added)');
    } catch (e) {
      print('   [SoundService] Initialization failed: $e');
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
    double? volume,
  }) {
    if (countdownEnabled != null) countdownSoundEnabled = countdownEnabled;
    if (countdownType != null) countdownSoundType = countdownType;
    if (completionEnabled != null) completionSoundEnabled = completionEnabled;
    if (completionType != null) completionSoundType = completionType;
    if (restTimerEnabled != null) restTimerSoundEnabled = restTimerEnabled;
    if (restTimerType != null) restTimerSoundType = restTimerType;
    if (volume != null) {
      soundEffectsVolume = volume.clamp(0.0, 1.0);
    }
  }

  /// Play countdown sound (3, 2, 1)
  Future<void> playCountdownBeep(int count) async {
    if (!countdownSoundEnabled) return;

    // Use haptic feedback as fallback
    if (count <= 3 && count > 0) {
      HapticFeedback.mediumImpact();
    }

    // TODO: Play actual sound when audio package is added
    print('   [SoundService] Countdown: $count');
  }

  /// Play completion sound (workout/set finished)
  Future<void> playCompletionSound() async {
    if (!completionSoundEnabled) return;

    // Use haptic feedback as fallback
    HapticFeedback.heavyImpact();

    // TODO: Play actual sound when audio package is added
    print('   [SoundService] Completion sound');
  }

  /// Play rest timer sound
  Future<void> playRestTimerSound() async {
    if (!restTimerSoundEnabled) return;

    // Use haptic feedback as fallback
    HapticFeedback.lightImpact();

    // TODO: Play actual sound when audio package is added
    print('   [SoundService] Rest timer sound');
  }

  /// Play a generic notification sound
  Future<void> playNotification() async {
    HapticFeedback.selectionClick();

    // TODO: Play actual sound when audio package is added
  }

  /// Stop any currently playing sound
  Future<void> stop() async {
    // TODO: Stop audio when package is added
  }

  /// Dispose of the service
  void dispose() {
    // TODO: Dispose audio player when package is added
    _isInitialized = false;
  }
}
