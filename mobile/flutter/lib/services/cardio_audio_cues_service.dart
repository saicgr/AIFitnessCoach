import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Post-cardio TTS playback service for coach insights.
///
/// SCOPE: This service ships POST-RUN playback only — the user taps the
/// "🔊 Hear it" button next to the coach's-take line on a completed cardio
/// session. Live mid-run cue scheduling is intentionally deferred and is NOT
/// part of this service (see Wave 3 SLICE_TTS scope notes).
///
/// Responsibilities:
///  * Speak a single insight string via `flutter_tts`.
///  * Coordinate with `audio_session` so background music (Spotify, Podcasts,
///    Apple Music) is ducked while we speak and restored on completion.
///  * Refuse to play when no audio output route is available (e.g. no
///    headphones AND no built-in speaker route) — caller surfaces a snackbar
///    based on the `false` return value.
///  * Honor a user-configurable voice id, persisted via `SharedPreferences`
///    under the [voicePrefsKey] key.
///
/// Edge cases handled:
///  * `init()` is idempotent.
///  * `playInsight()` while already speaking → stops the current utterance
///    cleanly before starting the new one (prevents overlap).
///  * `stop()` is safe to call when not speaking.
///  * Empty / whitespace-only insight text is rejected (returns `false`) so we
///    never duck music for a no-op.
///  * Any thrown error from the TTS plugin abandons audio focus so we don't
///    leave music ducked forever.
class CardioAudioCuesService {
  CardioAudioCuesService._internal();

  static final CardioAudioCuesService _instance =
      CardioAudioCuesService._internal();

  /// Singleton accessor — one TTS engine instance per process is sufficient
  /// and avoids competing audio focus requests.
  factory CardioAudioCuesService() => _instance;

  /// Test-only constructor: allows injecting fakes for `flutter_tts`,
  /// `audio_session`, and `SharedPreferences`. Production code MUST go through
  /// the singleton factory.
  @visibleForTesting
  CardioAudioCuesService.forTesting({
    FlutterTts? tts,
    AudioSession? session,
    SharedPreferences? prefs,
  })  : _tts = tts ?? FlutterTts(),
        _injectedSession = session,
        _prefs = prefs;

  /// SharedPreferences key for the user-selected voice id. The composer in
  /// `settings_card.dart` writes the same key — keep these in sync.
  static const String voicePrefsKey = 'tts_voice';

  /// Sentinel voice id meaning "use the platform default voice" — written
  /// when the user has not made an explicit choice.
  static const String defaultVoiceId = 'default';

  FlutterTts _tts = FlutterTts();
  AudioSession? _injectedSession;
  AudioSession? _session;
  SharedPreferences? _prefs;

  bool _initialized = false;
  bool _isSpeaking = false;
  String? _appliedVoiceId;

  /// Completer that fires when the in-flight utterance ends (completion,
  /// error, or cancel). `playInsight` awaits this so the caller can `await`
  /// the full speak lifecycle if desired (currently the UI doesn't, but tests
  /// do).
  Completer<void>? _speakCompleter;

  /// Whether the most recent `playInsight` call is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Whether `init()` has completed successfully at least once.
  bool get isInitialized => _initialized;

  /// One-shot initialization: wires the audio session config (mix-with-others
  /// + duckOthers, same shape as `AudioSessionService`) and registers TTS
  /// lifecycle handlers. Safe to call repeatedly.
  Future<void> init() async {
    if (_initialized) return;

    try {
      _session = _injectedSession ?? await AudioSession.instance;

      // Mirror the existing AudioSessionService config so background music
      // ducks instead of stopping. spokenAudio mode + duckOthers is the
      // canonical "voice prompt over music" combo on iOS.
      await _session!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers |
                AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistanceSonification,
          flags: AndroidAudioFlags.none,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        // Restore other apps' audio on completion. Fire-and-forget so we don't
        // block the plugin callback thread.
        unawaited(_restoreFocus());
        _resolveSpeak();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        unawaited(_restoreFocus());
        _resolveSpeak();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (kDebugMode) {
          debugPrint('   [CardioAudioCues] TTS error: $msg');
        }
        unawaited(_restoreFocus());
        _resolveSpeak();
      });

      // Apply persisted voice preference (no-op if user hasn't chosen one).
      _prefs ??= await SharedPreferences.getInstance();
      final stored = _prefs!.getString(voicePrefsKey);
      if (stored != null && stored.isNotEmpty) {
        await _applyVoice(stored);
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   [CardioAudioCues] init error: $e');
      }
      // Re-throw — caller (HearInsightButton) catches and surfaces an error.
      rethrow;
    }
  }

  /// Speak the given insight. Returns `true` if speech actually started,
  /// `false` if we bailed out (no text, no output route, init failed).
  ///
  /// Caller should surface a snackbar on `false` — e.g. "No audio output
  /// device — connect headphones or unmute your speaker."
  Future<bool> playInsight(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    try {
      await init();
    } catch (_) {
      return false;
    }

    // Headphone / route awareness: if there's literally no output device,
    // skip speaking. `audio_session` exposes the current route via
    // `getDevices(includeInputs: false)`; an empty list means no output
    // available (rare — usually built-in speaker exists, but on iPad without
    // a speaker route this can happen).
    try {
      final devices = await _session?.getDevices(includeInputs: false);
      if (devices != null && devices.isEmpty) {
        return false;
      }
    } catch (_) {
      // getDevices not implemented on this platform — fall through and
      // attempt speech. The OS will route to whatever default is available.
    }

    // If something is already speaking, stop it cleanly first so the new
    // utterance isn't queued behind the old one.
    if (_isSpeaking) {
      await stop();
    }

    _speakCompleter = Completer<void>();

    try {
      final activated = await _session?.setActive(true);
      if (activated == false) {
        // Couldn't get focus — abort rather than speaking over a phone call.
        _resolveSpeak();
        return false;
      }

      // Speak. Note: flutter_tts `speak` returns immediately; completion is
      // signaled via the completion handler we registered in init().
      final result = await _tts.speak(trimmed);
      // Plugin returns 1 on success, 0 on failure (per package docs).
      if (result == 0) {
        await _restoreFocus();
        _resolveSpeak();
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   [CardioAudioCues] playInsight error: $e');
      }
      await _restoreFocus();
      _resolveSpeak();
      return false;
    }
  }

  /// Halt a mid-utterance speech. Idempotent: safe to call when nothing is
  /// playing.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   [CardioAudioCues] stop error: $e');
      }
    }
    _isSpeaking = false;
    await _restoreFocus();
    _resolveSpeak();
  }

  /// Update the user's voice preference. Persists to SharedPreferences and
  /// applies the voice immediately so the next `playInsight` uses it.
  ///
  /// Voice ids match `TTSService.applyVoice` for cross-feature consistency:
  /// `'default' | 'coach_voice_chad' | 'coach_voice_serena'`.
  Future<void> setVoice(String voiceId) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(voicePrefsKey, voiceId);
    if (_initialized) {
      await _applyVoice(voiceId);
    }
  }

  /// Read the persisted voice id, defaulting to [defaultVoiceId].
  Future<String> currentVoice() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(voicePrefsKey) ?? defaultVoiceId;
  }

  Future<void> _applyVoice(String voiceId) async {
    if (_appliedVoiceId == voiceId) return;
    _appliedVoiceId = voiceId;
    try {
      if (voiceId == 'coach_voice_chad') {
        await _tts.setPitch(0.85);
        await _tts.setSpeechRate(0.55);
      } else if (voiceId == 'coach_voice_serena') {
        await _tts.setPitch(1.1);
        await _tts.setSpeechRate(0.45);
      } else {
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   [CardioAudioCues] applyVoice error: $e');
      }
    }
  }

  Future<void> _restoreFocus() async {
    try {
      // notifyOthersOnDeactivation is the magic flag that tells Spotify et al.
      // "you can ramp back up now." Without it on iOS music stays ducked
      // until the user opens the music app.
      await _session?.setActive(
        false,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   [CardioAudioCues] restore focus error: $e');
      }
    }
  }

  void _resolveSpeak() {
    final c = _speakCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _speakCompleter = null;
  }

  /// Test-only: await the in-flight utterance to finish. Returns immediately
  /// if nothing is speaking.
  @visibleForTesting
  Future<void> waitForCompletion() async {
    final c = _speakCompleter;
    if (c == null) return;
    return c.future;
  }
}
