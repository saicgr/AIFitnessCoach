import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/photo_backdrop.dart';

/// PhotoQuote — user's photo full-bleed under a heavier scrim, with a
/// large serif italic quote centered. Editorial / motivational format.
class PhotoQuoteTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoQuoteTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const List<String> _fallbackQuotes = [
    'The work you don\'t see is the work that matters.',
    'Discipline is just memory you keep in your body.',
    'Show up. Lift the thing. Repeat.',
    'Strong is a habit, not a moment.',
    'You don\'t skip leg day. You skip excuses.',
    'Reps don\'t care if you\'re tired.',
  ];

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final quote = _resolveQuote(data);
    final attribution = (data.userDisplayName ?? data.title).trim();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoBackdrop(
            path: data.customPhotoPath,
            fallbackGradient: [
              Colors.black,
              Color.lerp(accent, Colors.black, 0.7)!,
            ],
            topScrim: 0.40,
            bottomScrim: 0.70,
            vignette: true,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              data.aspect == ShareableAspect.story ? 56 : 40,
              80,
              data.aspect == ShareableAspect.story ? 56 : 40,
              48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 56 * mul,
                  color: accent.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 12),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                    fontSize: 30 * mul,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    height: 1.25,
                    letterSpacing: -0.3,
                    shadows: const [
                      Shadow(blurRadius: 12, color: Colors.black87),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 60,
                  height: 2,
                  color: accent,
                ),
                const SizedBox(height: 14),
                if (attribution.isNotEmpty)
                  Text(
                    attribution.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12 * mul,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                const Spacer(),
                if (showWatermark)
                  AppWatermark(
                    textColor: Colors.white,
                    fontSize: 12 * mul,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveQuote(Shareable d) {
    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    if (hero != '—' && hero.isNotEmpty) {
      if (unit.isNotEmpty) return '$hero $unit. No shortcuts.';
    }
    final idx = (d.title.hashCode & 0x7FFFFFFF) % _fallbackQuotes.length;
    return _fallbackQuotes[idx];
  }
}
