import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

/// Audio Session service for managing audio focus and mixing with other apps.
///
/// This service ensures that the app's TTS announcements don't stop music apps
/// like Spotify or Apple Music. Instead, it temporarily lowers (ducks) the
/// volume of other apps during announcements.
///
/// Key features:
/// - Configures audio session to mix with other apps
/// - Ducks other audio during TTS playback
/// - Restores audio levels after TTS completes
/// - Handles both iOS (AVAudioSession) and Android (AudioManager)
class AudioSessionService {
  static final AudioSessionService _instance = AudioSessionService._internal();
  factory AudioSessionService() => _instance;
  AudioSessionService._internal();

  AudioSession? _session;
  bool _isInitialized = false;
  bool _isDucking = false;

  /// Initialize the audio session for mixing with other apps.
  ///
  /// On iOS: Uses AVAudioSessionCategory.playback with mixWithOthers and
  ///         duckOthers options.
  /// On Android: Uses AndroidAudioAttributes with USAGE_ASSISTANCE_SONIFICATION
  ///             for non-intrusive audio that ducks other apps.
  Future<void> initializeSession() async {
    if (_isInitialized) return;

    try {
      _session = await AudioSession.instance;

      // Configure audio session for TTS that mixes with and ducks other audio
      await _session!.configure(AudioSessionConfiguration(
        // iOS Configuration
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers |
            AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,

        // Android Configuration
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          // USAGE_ASSISTANCE_SONIFICATION allows ducking without interrupting
          usage: AndroidAudioUsage.assistanceSonification,
          flags: AndroidAudioFlags.none,
        ),
        // Request transient focus that allows ducking
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));

      // Handle audio interruptions (phone calls, etc.)
      _session!.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Audio was interrupted (e.g., phone call)
          debugPrint('   [AudioSession] Interrupted: ${event.type}');
        } else {
          // Interruption ended
          debugPrint('   [AudioSession] Interruption ended');
        }
      });

      // Handle becoming noisy (headphones unplugged)
      _session!.becomingNoisyEventStream.listen((_) {
        debugPrint('   [AudioSession] Becoming noisy (headphones unplugged)');
      });

      _isInitialized = true;
      debugPrint('   [AudioSession] Initialized successfully');
    } catch (e) {
      debugPrint('   [AudioSession] Init error: $e');
    }
  }

  /// Request transient audio focus before playing TTS.
  ///
  /// This tells the system we're about to play audio and other apps should
  /// lower their volume (duck).
  Future<bool> requestTransientFocus() async {
    if (!_isInitialized) {
      await initializeSession();
    }

    try {
      // Activate the session - this will cause other apps to duck
      final activated = await _session?.setActive(true);
      if (activated == true) {
        _isDucking = true;
        debugPrint('   [AudioSession] Transient focus acquired, ducking active');
        return true;
      }
      debugPrint('   [AudioSession] Failed to acquire focus');
      return false;
    } catch (e) {
      debugPrint('   [AudioSession] Request focus error: $e');
      return false;
    }
  }

  /// Duck other apps' audio temporarily.
  ///
  /// On iOS, this is handled automatically when we activate the session
  /// with duckOthers option.
  /// On Android, we use AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK.
  Future<void> duckOtherAudio() async {
    if (!_isInitialized) {
      await initializeSession();
    }

    if (_isDucking) return;

    try {
      await _session?.setActive(true);
      _isDucking = true;
      debugPrint('   [AudioSession] Ducking other audio');
    } catch (e) {
      debugPrint('   [AudioSession] Duck error: $e');
    }
  }

  /// Restore other apps' audio volume.
  ///
  /// Called after TTS completes to unduck other apps.
  Future<void> unduckOtherAudio() async {
    if (!_isDucking) return;

    try {
      // On iOS, we need to deactivate with notifyOthersOnDeactivation
      // to properly restore other apps' volume
      if (Platform.isIOS) {
        await _session?.setActive(
          false,
          avAudioSessionSetActiveOptions:
              AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        );
      } else {
        // On Android, simply deactivating releases focus
        await _session?.setActive(false);
      }
      _isDucking = false;
      debugPrint('   [AudioSession] Unducked other audio');
    } catch (e) {
      debugPrint('   [AudioSession] Unduck error: $e');
    }
  }

  /// Abandon audio focus after TTS completes.
  ///
  /// This releases audio focus and allows other apps to resume
  /// their normal volume.
  Future<void> abandonFocus() async {
    await unduckOtherAudio();
  }

  /// Check if the audio session is currently ducking other apps.
  bool get isDucking => _isDucking;

  /// Check if the audio session is initialized.
  bool get isInitialized => _isInitialized;

  /// Dispose of the audio session.
  Future<void> dispose() async {
    if (_isDucking) {
      await unduckOtherAudio();
    }
    _isInitialized = false;
    debugPrint('   [AudioSession] Disposed');
  }
}
