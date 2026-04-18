import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'audio_session_service.dart';

/// Text-to-Speech service for voice announcements during workouts.
///
/// Provides voice announcements for:
/// - Exercise transitions ("Get ready for Bench Press")
/// - Rest period endings
/// - Workout milestones
///
/// This service uses AudioSessionService to properly handle audio focus,
/// ensuring that music apps like Spotify are ducked (volume lowered)
/// during announcements rather than stopped completely.
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioSessionService _audioSession = AudioSessionService();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Currently applied voice id — keeps us from re-applying on every speak().
  String? _currentVoiceId;

  /// Initialize the TTS engine with default settings.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize audio session first for proper mixing with music apps
      await _audioSession.initializeSession();

      // Set language
      await _flutterTts.setLanguage("en-US");

      // Set speech rate (0.0 to 1.0, where 0.5 is normal speed)
      await _flutterTts.setSpeechRate(0.5);

      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(1.0);

      // Set pitch (0.5 to 2.0, where 1.0 is normal)
      await _flutterTts.setPitch(1.0);

      // Set up completion handler - restore other audio when done speaking
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _audioSession.abandonFocus();
      });

      // Set up error handler - restore other audio on error
      _flutterTts.setErrorHandler((msg) {
        debugPrint('   [TTS] Error: $msg');
        _isSpeaking = false;
        _audioSession.abandonFocus();
      });

      // Set up start handler
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      // Set up cancel handler - restore other audio if speech is cancelled
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _audioSession.abandonFocus();
      });

      _isInitialized = true;
      debugPrint('   [TTS] Initialized successfully with audio session');
    } catch (e) {
      debugPrint('   [TTS] Init error: $e');
    }
  }

  /// Apply a coach voice preference.
  ///
  /// `voiceId` must be one of: 'default' | 'coach_voice_chad' | 'coach_voice_serena'.
  /// Cross-platform voices are picked by searching getVoices() for a matching
  /// en-US male/female voice, then tuning pitch + rate per persona.
  /// Safe to call repeatedly; a no-op when the id hasn't changed.
  Future<void> applyVoice(String voiceId) async {
    if (!_isInitialized) await init();
    if (_currentVoiceId == voiceId) return;
    _currentVoiceId = voiceId;

    try {
      if (voiceId == 'coach_voice_chad') {
        // Male, energetic — deeper pitch, slightly faster
        await _selectVoiceByGender('male');
        await _flutterTts.setPitch(0.85);
        await _flutterTts.setSpeechRate(0.55);
      } else if (voiceId == 'coach_voice_serena') {
        // Female, calm — neutral pitch, slower
        await _selectVoiceByGender('female');
        await _flutterTts.setPitch(1.1);
        await _flutterTts.setSpeechRate(0.45);
      } else {
        // default
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        // Don't force a voice — let the OS pick its default
      }
      debugPrint('   [TTS] Voice set to: $voiceId');
    } catch (e) {
      debugPrint('   [TTS] applyVoice error: $e');
    }
  }

  /// Heuristically pick an en-US voice matching a target gender.
  /// Falls back silently when getVoices isn't supported on the platform.
  Future<void> _selectVoiceByGender(String gender) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices is! List) return;

      // Expected shape: [{name: "...", locale: "en-US", gender: "male"/"female"}, ...]
      final candidates = voices.where((v) {
        if (v is! Map) return false;
        final locale = v['locale']?.toString().toLowerCase() ?? '';
        final name = v['name']?.toString().toLowerCase() ?? '';
        if (!locale.startsWith('en')) return false;
        // On Android, gender is in the map. On iOS, fall back to name heuristics.
        final vGender = v['gender']?.toString().toLowerCase();
        if (vGender != null && vGender == gender) return true;
        // iOS name heuristics — common English voices
        const maleNames = ['alex', 'daniel', 'fred', 'aaron', 'arthur', 'albert'];
        const femaleNames = ['samantha', 'karen', 'moira', 'nicky', 'tessa', 'victoria', 'zoe', 'susan', 'ava'];
        final pool = gender == 'male' ? maleNames : femaleNames;
        return pool.any((n) => name.contains(n));
      }).toList();

      if (candidates.isEmpty) return;

      final pick = candidates.first as Map;
      await _flutterTts.setVoice({
        'name': pick['name']?.toString() ?? '',
        'locale': pick['locale']?.toString() ?? 'en-US',
      });
    } catch (e) {
      // getVoices may not be supported on all platforms; not fatal.
      debugPrint('   [TTS] _selectVoiceByGender fallback: $e');
    }
  }

  /// Speak the given text.
  ///
  /// Before speaking, this method:
  /// 1. Requests transient audio focus
  /// 2. Ducks (lowers volume of) other apps like Spotify
  /// 3. Speaks the text
  /// 4. Restores other apps' volume (via completion handler)
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    // Stop any ongoing speech before starting new one
    if (_isSpeaking) {
      await stop();
    }

    try {
      // Request transient audio focus to duck other apps
      await _audioSession.requestTransientFocus();

      debugPrint('   [TTS] Speaking: $text');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('   [TTS] Speak error: $e');
      // Make sure to restore audio focus on error
      await _audioSession.abandonFocus();
    }
  }

  /// Announce the next exercise during transition.
  ///
  /// Called when transitioning between exercises to announce the upcoming exercise.
  Future<void> announceNextExercise(String exerciseName) async {
    // Clean up exercise name for better speech
    final cleanName = _cleanExerciseName(exerciseName);
    await speak("Get ready for $cleanName");
  }

  /// Announce the start of rest period.
  Future<void> announceRestStart(int seconds) async {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds > 0) {
        await speak("Rest for $minutes minute${minutes > 1 ? 's' : ''} and $remainingSeconds seconds");
      } else {
        await speak("Rest for $minutes minute${minutes > 1 ? 's' : ''}");
      }
    } else {
      await speak("Rest for $seconds seconds");
    }
  }

  /// Announce the end of rest period.
  Future<void> announceRestEnd() async {
    await speak("Rest complete. Time to work!");
  }

  /// Announce workout completion.
  Future<void> announceWorkoutComplete() async {
    await speak("Congratulations! Workout complete!");
  }

  /// Announce a countdown (for the last few seconds).
  Future<void> announceCountdown(int seconds) async {
    if (seconds <= 3 && seconds > 0) {
      await speak(seconds.toString());
    }
  }

  /// Clean exercise name for better speech synthesis.
  String _cleanExerciseName(String name) {
    // Remove parenthetical notes
    String cleaned = name.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ');

    // Expand common abbreviations
    cleaned = cleaned
        .replaceAll(RegExp(r'\bDB\b', caseSensitive: false), 'dumbbell')
        .replaceAll(RegExp(r'\bBB\b', caseSensitive: false), 'barbell')
        .replaceAll(RegExp(r'\bKB\b', caseSensitive: false), 'kettlebell')
        .replaceAll(RegExp(r'\bEZ\b', caseSensitive: false), 'E Z')
        .replaceAll(RegExp(r'\b1RM\b', caseSensitive: false), 'one rep max')
        .replaceAll(RegExp(r'\bRDL\b', caseSensitive: false), 'Romanian deadlift')
        .replaceAll(RegExp(r'\bOHP\b', caseSensitive: false), 'overhead press');

    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      // Restore other apps' audio when stopping
      await _audioSession.abandonFocus();
    } catch (e) {
      debugPrint('   [TTS] Stop error: $e');
    }
  }

  /// Check if TTS is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Check if TTS is initialized.
  bool get isInitialized => _isInitialized;

  /// Get the audio session service for direct access if needed.
  AudioSessionService get audioSession => _audioSession;

  /// Dispose the TTS service.
  Future<void> dispose() async {
    await stop();
    await _audioSession.dispose();
    _isInitialized = false;
  }
}
