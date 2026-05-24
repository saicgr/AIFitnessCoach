import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/accent_color_provider.dart';
import '../../utils/voice_set_parser.dart';

/// Floating mic FAB for in-workout voice set logging.
///
/// Tap once → start listening. Tap again (or auto-stop on silence) → run the
/// raw transcript through [VoiceSetParser] and hand the result to [onParsed].
/// Permission denial surfaces a snackbar; nothing else (the composer owns the
/// actual set commit).
///
/// Uses `AccentColorScope` so the FAB tints to the active gym profile colour.
///
/// Edge cases handled:
///   - Speech engine init failure → tap shows snackbar, never crashes.
///   - Permission denied on iOS/Android → snackbar with Settings cue.
///   - User taps mid-recording → stop immediately and parse partial transcript.
///   - Empty transcript after stop → no callback fired (silent no-op).
class VoiceMicFab extends StatefulWidget {
  /// Currently focused exercise on the workout screen. Passed into the parser
  /// so lift-mismatch can flip a `liftHint`.
  final String? currentExerciseName;

  /// Called with the parsed set when the user stops recording AND the
  /// transcript yielded any usable signal (weight, reps, warmup, or liftHint).
  final ValueChanged<ParsedSet> onParsed;

  /// Optional override label. Default: "Voice".
  final String label;

  /// Optional locale ID (e.g. "en_US"). Defaults to system locale.
  final String? localeId;

  const VoiceMicFab({
    super.key,
    required this.onParsed,
    this.currentExerciseName,
    this.label = 'Voice',
    this.localeId,
  });

  @override
  State<VoiceMicFab> createState() => _VoiceMicFabState();
}

class _VoiceMicFabState extends State<VoiceMicFab>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceSetParser _parser = const VoiceSetParser();

  bool _isInitialized = false;
  bool _isListening = false;
  String _transcript = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          // 'notListening' fires after auto-stop on silence — finalise.
          if (status == 'notListening' && _isListening) {
            _finishListening();
          }
        },
        onError: (error) {
          if (!mounted) return;
          _stopAnimation();
          setState(() => _isListening = false);
          _showSnack('Voice error: ${error.errorMsg}');
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      _isInitialized = false;
    }
  }

  void _startAnimation() => _pulseController.repeat(reverse: true);
  void _stopAnimation() {
    _pulseController.stop();
    _pulseController.value = 0.0;
  }

  Future<void> _toggle() async {
    if (_isListening) {
      await _speech.stop();
      _finishListening();
      return;
    }

    if (!_isInitialized) {
      // Re-attempt init in case permission was just granted.
      await _initSpeech();
    }
    if (!_isInitialized) {
      _showSnack('Mic permission needed — enable in Settings');
      return;
    }
    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      _showSnack('Mic permission needed — enable in Settings');
      return;
    }

    setState(() {
      _transcript = '';
      _isListening = true;
    });
    _startAnimation();
    await _speech.listen(
      localeId: widget.localeId,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) {
        _transcript = result.recognizedWords;
      },
      // Use SpeechListenOptions for newer plugin versions; both forms supported.
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  void _finishListening() {
    _stopAnimation();
    if (!mounted) return;
    setState(() => _isListening = false);
    final text = _transcript.trim();
    if (text.isEmpty) return;
    final parsed = _parser.parse(
      text,
      currentExerciseName: widget.currentExerciseName,
    );
    if (parsed.weightKg == null &&
        parsed.reps == null &&
        !parsed.isWarmup &&
        parsed.liftHint == null) {
      // Nothing usable — keep silent so we don't nag the user.
      return;
    }
    widget.onParsed(parsed);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final Widget icon = _isListening
        ? ScaleTransition(
            scale: _pulse,
            child: const Icon(Icons.graphic_eq),
          )
        : const Icon(Icons.mic_none);

    return FloatingActionButton.extended(
      onPressed: _toggle,
      backgroundColor: _isListening ? accent : accent.withValues(alpha: 0.9),
      foregroundColor: Colors.white,
      icon: icon,
      label: Text(_isListening ? 'Hearing…' : widget.label),
    );
  }
}
