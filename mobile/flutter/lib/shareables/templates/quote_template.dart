import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// QuoteTemplate — moody dark canvas with a large serif italic quote
/// auto-generated from the share data, small attribution, accent rule.
/// Plain-text version of PhotoQuote (no photo backdrop).
class QuoteTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const QuoteTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const _fallback = [
    'Discipline is just memory you keep in your body.',
    'Reps don\'t care if you\'re tired.',
    'Show up. Lift the thing. Repeat.',
    'Strong is a habit, not a moment.',
  ];

  String _quote(Shareable d) {
    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    if (hero != '—' && hero.isNotEmpty && unit.isNotEmpty) {
      return '$hero $unit. No shortcuts.';
    }
    final i = (d.title.hashCode & 0x7FFFFFFF) % _fallback.length;
    return _fallback[i];
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF06070A), Color(0xFF0F1118)],
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          data.aspect == ShareableAspect.story ? 56 : 40,
          80,
          data.aspect == ShareableAspect.story ? 56 : 40,
          56,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 2,
              color: accent,
            ),
            const SizedBox(height: 8),
            Text(
              data.periodLabel.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 11 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            Icon(Icons.format_quote_rounded,
                color: accent, size: 56 * mul),
            const SizedBox(height: 10),
            Text(
              _quote(data),
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: Colors.white,
                fontSize: 36 * mul,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.2,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 60,
              height: 2,
              color: accent,
            ),
            const SizedBox(height: 12),
            Text(
              (data.userDisplayName ?? data.title).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            if (showWatermark)
              FitWizWatermark(
                textColor: Colors.white,
                fontSize: 12 * mul,
              ),
          ],
        ),
      ),
    );
  }
}
