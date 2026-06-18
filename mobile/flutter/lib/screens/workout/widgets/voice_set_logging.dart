/// Voice set logging — "225 for 8" → weight + reps.
///
/// Hands-free set entry for the gym: tap the mic, say the numbers, and the
/// parsed weight/reps drop into the active set. Backed by the real
/// `speech_to_text` package (already a dependency) with `permission_handler`
/// for the mic prompt. When recognition is unavailable (no permission, sim
/// without a mic, unsupported locale) the button degrades gracefully with a
/// "voice logging unavailable" toast instead of throwing.
///
/// The PARSER ([VoiceSetParser]) is pure + unit-tested-friendly and shared by
/// both the easy and advanced layouts. The weight number is interpreted in the
/// user's WORKOUT weight unit (lb by default per project rule); callers pass
/// `useKg` so the parsed value lands in display units the caller already uses.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';

/// Result of parsing a spoken set phrase.
class ParsedVoiceSet {
  /// First number heard — interpreted as weight in the caller's display unit.
  /// Null when no weight was spoken (e.g. bodyweight "just 12 reps").
  final double? weight;

  /// Second number heard — interpreted as reps. Null when not spoken.
  final int? reps;

  const ParsedVoiceSet({this.weight, this.reps});

  bool get isEmpty => weight == null && reps == null;
  bool get hasBoth => weight != null && reps != null;

  @override
  String toString() => 'ParsedVoiceSet(weight: $weight, reps: $reps)';
}

/// Pure parser for spoken set phrases. Handles digits and number words.
///
/// Supported shapes (case-insensitive):
///   • "225 for 8"          → weight 225, reps 8
///   • "225 by 8"           → weight 225, reps 8
///   • "225 x 8" / "225x8"  → weight 225, reps 8
///   • "two twenty five for eight" → 225, 8
///   • "135 pounds 10 reps" → 135, 10
///   • "8 reps" / "just 8"  → reps 8 only (bodyweight)
///
/// Strategy: normalize number-words to digits, strip unit/filler words, then
/// take the first numeric token as weight and the second as reps. If only one
/// number is present AND the phrase mentions "rep(s)" (or no weight unit), it
/// is treated as reps; otherwise the lone number is treated as weight.
class VoiceSetParser {
  // Spoken-word → value for compounding (e.g. "two twenty five" = 2*100 + 25).
  // NOTE: the homophones "for" (4) / "to"/"too" (2) are deliberately NOT here —
  // in gym phrasing ("225 for 8") they are separators, and STT renders them
  // ambiguously. They live in [_separators] instead. The spelled digit words
  // "four" / "two" remain real numbers.
  static const Map<String, int> _units = {
    'zero': 0, 'oh': 0, 'one': 1, 'two': 2, 'three': 3,
    'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8,
    'ate': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
    'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
    'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
  };
  static const Map<String, int> _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
    'seventy': 70, 'eighty': 80, 'ninety': 90,
  };
  static const Map<String, int> _scales = {
    'hundred': 100, 'thousand': 1000,
  };

  // Words that separate weight from reps — NOT number words. Note "for" and
  // "to" double as homophones of 4/2, but in a "<num> for <num>" frame they're
  // separators; we resolve this by treating them as separators only when they
  // sit between two already-formed numbers.
  static const Set<String> _separators = {
    'for', 'to', 'too', 'by', 'x', 'times', 'reps', 'rep', 'at', 'and',
  };

  // Unit / filler words to drop entirely.
  static const Set<String> _filler = {
    'pounds', 'pound', 'lbs', 'lb', 'kilos', 'kilo', 'kilograms', 'kilogram',
    'kg', 'kgs', 'just', 'did', 'i', 'log', 'set', 'a', 'of', 'the', 'with',
    'weight', 'plus',
  };

  /// Parse a raw transcript into weight/reps. [mentionsReps] is derived
  /// internally; callers only pass the transcript.
  static ParsedVoiceSet parse(String transcript) {
    if (transcript.trim().isEmpty) return const ParsedVoiceSet();

    final lower = transcript.toLowerCase().trim();
    final mentionsRepWord =
        RegExp(r'\breps?\b').hasMatch(lower);

    // Tokenize on whitespace and the "x" digit-glue (e.g. "225x8"). Use a
    // mapped replace so $1/$2 expand (replaceAll treats them literally).
    final rawTokens = lower
        .replaceAllMapped(
            RegExp(r'(\d)\s*[x×]\s*(\d)'), (m) => '${m[1]} x ${m[2]}')
        .replaceAll(RegExp(r'[^a-z0-9.\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    // Walk tokens, compounding consecutive number-words / digits into numbers,
    // splitting on separator tokens.
    final numbers = <double>[];
    int? pendingUnits; // accumulating sub-hundred value
    int pendingTotal = 0; // accumulating hundreds/thousands
    bool building = false;

    void flush() {
      if (building) {
        final value = pendingTotal + (pendingUnits ?? 0);
        numbers.add(value.toDouble());
      }
      pendingUnits = null;
      pendingTotal = 0;
      building = false;
    }

    for (var i = 0; i < rawTokens.length; i++) {
      final t = rawTokens[i];

      // Pure numeric token (possibly decimal).
      final asNum = double.tryParse(t);
      if (asNum != null) {
        // A bare digit token is its own number — flush any word-built number.
        flush();
        numbers.add(asNum);
        continue;
      }

      if (_scales.containsKey(t)) {
        final scale = _scales[t]!;
        final base = (pendingUnits ?? (building ? 0 : 1));
        pendingTotal += base * scale;
        pendingUnits = null;
        building = true;
        continue;
      }
      if (_tens.containsKey(t)) {
        pendingUnits = (pendingUnits ?? 0) + _tens[t]!;
        building = true;
        continue;
      }
      if (_units.containsKey(t)) {
        // "two twenty (five)" style: a unit followed by a tens word means
        // hundreds (two twenty five → 225). Detect by peeking ahead.
        final next = i + 1 < rawTokens.length ? rawTokens[i + 1] : null;
        if (next != null && _tens.containsKey(next) && !building) {
          pendingTotal += _units[t]! * 100;
          building = true;
          continue;
        }
        pendingUnits = (pendingUnits ?? 0) + _units[t]!;
        building = true;
        continue;
      }

      // Separator or filler → close the current number.
      if (_separators.contains(t) || _filler.contains(t)) {
        flush();
        continue;
      }

      // Unknown word — treat as a boundary.
      flush();
    }
    flush();

    if (numbers.isEmpty) return const ParsedVoiceSet();

    if (numbers.length == 1) {
      // Lone number. If the phrase said "reps", it's reps; else weight.
      if (mentionsRepWord) {
        return ParsedVoiceSet(reps: numbers.first.round());
      }
      return ParsedVoiceSet(weight: numbers.first);
    }

    // First = weight, second = reps (industry phrasing "<weight> for <reps>").
    return ParsedVoiceSet(
      weight: numbers[0],
      reps: numbers[1].round(),
    );
  }
}

/// Compact mic button that captures a spoken set and reports the parsed
/// weight/reps via [onParsed]. Designed to sit in a set row / table header.
///
/// Lifecycle is fully self-contained: it owns the [SpeechToText] instance,
/// requests mic permission on first tap, shows a live listening sheet, and
/// stops on a final result or timeout. If speech is unavailable it surfaces a
/// graceful toast and never crashes.
class VoiceSetMicButton extends StatefulWidget {
  /// Fired with the parsed result when a usable transcript is recognized.
  final ValueChanged<ParsedVoiceSet> onParsed;

  /// User's workout weight unit — drives the listening-sheet hint copy.
  final bool useKg;

  /// Optional size of the icon button.
  final double size;

  const VoiceSetMicButton({
    super.key,
    required this.onParsed,
    this.useKg = false,
    this.size = 22,
  });

  @override
  State<VoiceSetMicButton> createState() => _VoiceSetMicButtonState();
}

class _VoiceSetMicButtonState extends State<VoiceSetMicButton> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _initialized = false;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onError: (e) => debugPrint('🎤 [Voice] error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('🎤 [Voice] status: $s'),
      );
    } catch (e) {
      debugPrint('❌ [Voice] initialize failed: $e');
      _available = false;
    }
    return _available;
  }

  Future<void> _onTap() async {
    HapticFeedback.lightImpact();

    // Mic permission (graceful: a denied/permanently-denied state → toast).
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) _toast('Microphone permission needed for voice logging');
      return;
    }

    final ok = await _ensureInitialized();
    if (!ok) {
      if (mounted) _toast('Voice logging unavailable on this device');
      return;
    }
    if (!mounted) return;

    await _showListeningSheet();
  }

  Future<void> _showListeningSheet() async {
    String heard = '';
    ParsedVoiceSet parsed = const ParsedVoiceSet();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          // Start listening once the sheet is up.
          void startListen() {
            _speech.listen(
              onResult: (r) {
                heard = r.recognizedWords;
                parsed = VoiceSetParser.parse(heard);
                setSheet(() {});
                if (r.finalResult) {
                  // Defer pop so the final transcript paints briefly.
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (!ctx.mounted) return;
                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                  });
                }
              },
              listenFor: const Duration(seconds: 8),
              pauseFor: const Duration(seconds: 3),
              localeId: null,
              listenOptions: SpeechListenOptions(
                partialResults: true,
                cancelOnError: true,
              ),
            );
          }

          // Kick off listening on first build.
          if (_speech.isNotListening && heard.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_speech.isNotListening) startListen();
            });
          }

          final unit = widget.useKg ? 'kg' : 'lb';
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.mic, color: accent, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  heard.isEmpty ? 'Listening…' : '"$heard"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  parsed.isEmpty
                      ? 'Try "225 for 8"'
                      : 'Logging '
                          '${parsed.weight != null ? '${_fmt(parsed.weight!)} $unit' : 'bodyweight'}'
                          '${parsed.reps != null ? ' × ${parsed.reps}' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: parsed.isEmpty
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : accent,
                    fontWeight: parsed.isEmpty ? FontWeight.w400 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    _speech.stop();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        });
      },
    );

    // Sheet dismissed — make sure recognition is stopped and report result.
    await _speech.stop();
    if (!parsed.isEmpty) {
      widget.onParsed(parsed);
      if (mounted) HapticFeedback.mediumImpact();
    }
  }

  String _fmt(double w) =>
      w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return IconButton(
      tooltip: 'Voice log a set',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: widget.size + 16,
        height: widget.size + 16,
      ),
      icon: Icon(Icons.mic_none_rounded, size: widget.size, color: accent),
      onPressed: _onTap,
    );
  }
}
