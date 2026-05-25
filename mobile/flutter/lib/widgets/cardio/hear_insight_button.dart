import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../services/cardio_audio_cues_service.dart';

import '../../l10n/generated/app_localizations.dart';
/// Inline "🔊 Hear it" button rendered next to a coach's-take line on the
/// post-cardio (synced workout) detail screen.
///
/// Behavior:
///  * Idle → shows volume_up icon. Tap calls
///    [CardioAudioCuesService.playInsight].
///  * Speaking → swaps to a pause icon. Tap calls
///    [CardioAudioCuesService.stop].
///  * If playback returns `false` (no audio output, empty text, plugin error)
///    a snackbar is surfaced via the nearest [ScaffoldMessenger].
///
/// Visual contract:
///  * Sized small (the workout-detail row is dense) — 32x32 hit area.
///  * Tinted with the active accent color via [AccentColorScope] so it
///    matches gym profile theming.
///  * NOT a [Stateful] in the global tree — it owns only the local
///    "currently speaking" flag; the singleton service owns the audio state.
class HearInsightButton extends StatefulWidget {
  const HearInsightButton({
    super.key,
    required this.insightText,
    this.tooltip = 'Hear it',
    this.service,
  });

  /// The coach-insight string to speak. Empty/whitespace text disables the
  /// button (rendered greyed out so the slot doesn't jump).
  final String insightText;

  /// Long-press tooltip (and a11y label).
  final String tooltip;

  /// Test-only injection point. Production callers leave this null and the
  /// singleton is used.
  final CardioAudioCuesService? service;

  @override
  State<HearInsightButton> createState() => _HearInsightButtonState();
}

class _HearInsightButtonState extends State<HearInsightButton> {
  late final CardioAudioCuesService _service =
      widget.service ?? CardioAudioCuesService();

  bool _isPlaying = false;

  Future<void> _onTap() async {
    // Already speaking → toggle to stop. Keep the toggle responsive even if
    // the underlying stop() future hasn't resolved yet.
    if (_isPlaying) {
      await _service.stop();
      if (!mounted) return;
      setState(() => _isPlaying = false);
      return;
    }

    final text = widget.insightText.trim();
    if (text.isEmpty) return;

    setState(() => _isPlaying = true);
    final ok = await _service.playInsight(text);
    if (!mounted) return;

    if (!ok) {
      setState(() => _isPlaying = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).hearInsightButtonNoAudioOutputAvailable,
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Wait for the utterance to end so the icon flips back to "play"
    // automatically. waitForCompletion() resolves on completion, cancel, OR
    // error, so we don't need a separate timeout.
    await _service.waitForCompletion();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final disabled = widget.insightText.trim().isEmpty;

    final color = disabled
        ? Theme.of(context).disabledColor
        : (_isPlaying ? accent : accent.withValues(alpha: 0.85));

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: _isPlaying ? AppLocalizations.of(context).hearInsightButtonStop : widget.tooltip,
        onPressed: disabled ? null : _onTap,
        icon: Icon(
          _isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
          color: color,
          semanticLabel: _isPlaying ? AppLocalizations.of(context).hearInsightButtonStopInsightPlayback : widget.tooltip,
        ),
      ),
    );
  }
}
