import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: "Week Highlights".
/// AI-narrative driven — the aiSummary quote is the hero, followed by up to
/// three highlight bullets and an encouragement card.
class WeeklyHighlightsTemplate extends StatelessWidget {
  final String dateRangeLabel;
  final String? aiSummary;
  final List<String> highlights;
  final String? encouragement;
  final bool showWatermark;

  const WeeklyHighlightsTemplate({
    super.key,
    required this.dateRangeLabel,
    this.aiSummary,
    this.highlights = const [],
    this.encouragement,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final visibleHighlights = highlights.take(3).toList();

    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0A2E),
            Color(0xFF2E1065),
            Color(0xFF1E1045),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SparkPainter())),
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
                        color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 12, color: Color(0xFFC4B5FD)),
                          SizedBox(width: 4),
                          Text(
                            'AI HIGHLIGHTS',
                            style: TextStyle(
                              color: Color(0xFFC4B5FD),
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
                      dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Big decorative quote
                if (aiSummary != null && aiSummary!.trim().isNotEmpty)
                  _SummaryQuote(text: aiSummary!)
                else
                  _PlaceholderQuote(),
                const SizedBox(height: 18),
                if (visibleHighlights.isNotEmpty) ...[
                  const Text(
                    'THIS WEEK',
                    style: TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final h in visibleHighlights) ...[
                    _HighlightBullet(text: h),
                    const SizedBox(height: 6),
                  ],
                ],
                const Spacer(),
                if (encouragement != null && encouragement!.trim().isNotEmpty)
                  _EncouragementCard(text: encouragement!),
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

class _SummaryQuote extends StatelessWidget {
  final String text;
  const _SummaryQuote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"',
          style: TextStyle(
            color: const Color(0xFFC4B5FD).withValues(alpha: 0.7),
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 0.8,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderQuote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Another week in the books. Consistency is the real flex.',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    );
  }
}

class _HighlightBullet extends StatelessWidget {
  final String text;
  const _HighlightBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFBBF24),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final String text;
  const _EncouragementCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withValues(alpha: 0.15),
            const Color(0xFFA78BFA).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded,
              color: Color(0xFF22C55E), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scattered "spark" particles for the cosmic/indigo background feel.
class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Deterministic "random-ish" placement for visual interest.
    const points = <Offset>[
      Offset(0.15, 0.10), Offset(0.85, 0.08), Offset(0.45, 0.25),
      Offset(0.20, 0.55), Offset(0.90, 0.40), Offset(0.62, 0.70),
      Offset(0.08, 0.80), Offset(0.78, 0.90), Offset(0.30, 0.92),
    ];
    const radii = <double>[1.8, 1.2, 2.2, 1.4, 1.6, 1.0, 1.3, 1.8, 1.1];
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        Offset(points[i].dx * size.width, points[i].dy * size.height),
        radii[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
