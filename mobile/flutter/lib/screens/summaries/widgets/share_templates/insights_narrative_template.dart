import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: AI narrative (period insights).
/// Text-dominant layout — aiSummary as the hero quote, followed by the top
/// highlights and a single "next step" tip.
class InsightsNarrativeTemplate extends StatelessWidget {
  final String periodLabel;
  final String periodName;
  final String? summary;
  final List<String> highlights;
  final List<String> tips;
  final bool showWatermark;

  const InsightsNarrativeTemplate({
    super.key,
    required this.periodLabel,
    required this.periodName,
    this.summary,
    this.highlights = const [],
    this.tips = const [],
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = highlights.isNotEmpty ? highlights.first : null;
    final tip = tips.isNotEmpty ? tips.first : null;

    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1724),
            Color(0xFF0B2B3F),
            Color(0xFF062029),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavesPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 12, color: Color(0xFF67E8F9)),
                          const SizedBox(width: 4),
                          Text(
                            '$periodName AI',
                            style: const TextStyle(
                              color: Color(0xFF67E8F9),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      periodLabel.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '"',
                  style: TextStyle(
                    color: const Color(0xFF67E8F9).withValues(alpha: 0.7),
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    height: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    summary ??
                        'Your consistency is compounding. Keep stacking the reps.',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (highlight != null) ...[
                  _BannerCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    label: 'HIGHLIGHT',
                    text: highlight,
                  ),
                  const SizedBox(height: 8),
                ],
                if (tip != null)
                  _BannerCard(
                    icon: Icons.arrow_forward_rounded,
                    iconColor: const Color(0xFF22C55E),
                    label: 'NEXT',
                    text: tip,
                  ),
                const SizedBox(height: 8),
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String text;

  const _BannerCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: iconColor.withValues(alpha: 0.8), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flowing cyan waves for the "AI / ocean" aesthetic.
class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final y = size.height * (0.25 + i * 0.22);
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 8) {
        final offset = (x / size.width) * 6.283 * 2 + i * 0.7;
        path.lineTo(x, y + 10 * (offset % 1 - 0.5));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
