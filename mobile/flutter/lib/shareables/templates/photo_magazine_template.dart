import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/photo_backdrop.dart';

/// PhotoMagazine — user photo full-bleed with a magazine-cover headline
/// stack (giant title in serif italic, datelines, cover lines, barcode).
/// Distinct from MagazineCover (which is solid-gradient, no photo) and
/// PhotoQuote (which is centered single quote).
class PhotoMagazineTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoMagazineTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String _coverLine(Shareable d, int idx) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (idx >= hl.length) return '';
    final h = hl[idx];
    return '${h.value} ${h.label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);
    final lineA = _coverLine(data, 1);
    final lineB = _coverLine(data, 2);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoBackdrop(
            path: data.customPhotoPath,
            fallbackGradient: [
              accent,
              Color.lerp(accent, Colors.black, 0.6)!,
            ],
            topScrim: 0.30,
            bottomScrim: 0.45,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row — masthead "FITWIZ" + issue.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'FITWIZ',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        color: Colors.white,
                        fontSize: data.aspect == ShareableAspect.story
                            ? 88
                            : 64,
                        fontWeight: FontWeight.w900,
                        height: 0.85,
                        letterSpacing: -3,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.periodLabel.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * mul,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'ISSUE NO. 01',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 10 * mul,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 2, color: Colors.white),
                const Spacer(),
                // Cover lines (left).
                if (lineA.isNotEmpty)
                  _coverChip('FEATURE', lineA, accent, mul),
                if (lineB.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _coverChip('PLUS', lineB, accent, mul),
                ],
                const SizedBox(height: 18),
                // Big italic headline.
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                    fontSize: data.aspect == ShareableAspect.story
                        ? 56
                        : 42,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.0,
                    letterSpacing: -1.2,
                    shadows: const [
                      Shadow(blurRadius: 16, color: Colors.black87),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hero != '—')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          unit.isEmpty ? hero : '$hero $unit',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16 * mul,
                            fontWeight: FontWeight.w900,
                          ),
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
                const SizedBox(height: 16),
                // Faux barcode.
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    painter: _BarcodePainter(),
                    size: const Size(120, 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverChip(String kicker, String body, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kicker,
            style: TextStyle(
              color: accent,
              fontSize: 10 * mul,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            body,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13 * mul,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    var x = 0.0;
    var seed = 11;
    while (x < size.width) {
      final w = (seed % 4) + 1.0;
      if (seed % 3 != 0) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w + 1.5;
      seed = (seed * 13 + 7) % 29;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
