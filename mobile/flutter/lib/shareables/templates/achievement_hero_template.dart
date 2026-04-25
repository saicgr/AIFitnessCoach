import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// AchievementHero — purple-violet gradient with radial dot pattern, halo'd
/// trophy at center (orange glow circle), giant count, latest achievement
/// chip, two key-stat pills along the bottom. Cleaner than Level Up.
class AchievementHeroTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const AchievementHeroTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hl = data.highlights.where((h) => h.isPopulated).toList();
    final count = data.heroValue?.round() ??
        (hl.length > 1 ? int.tryParse(hl.first.value) ?? hl.length : hl.length);
    final latest = hl.isNotEmpty ? hl.first : null;
    final keyStats = hl.length > 1 ? hl.skip(1).take(2).toList() : <ShareableMetric>[];

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF2D1B69),
        Color(0xFF1A0E3D),
        Color(0xFF0D0721),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _DotsPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
            child: Column(
              children: [
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow halo.
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFB35B).withValues(alpha: 0.55),
                            const Color(0xFFFF6B35).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB35B), Color(0xFFFF6B35)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF6B35).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: data.aspect == ShareableAspect.story
                        ? 144
                        : 110,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -4,
                  ),
                ),
                Text(
                  count == 1 ? 'ACHIEVEMENT' : 'ACHIEVEMENTS',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 22),
                if (latest != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: const Color(0xFFFFB35B), size: 16 * mul),
                        const SizedBox(width: 6),
                        Text(
                          'Latest: ${latest.value}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13 * mul,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (keyStats.isNotEmpty)
                  Row(
                    children: [
                      for (var i = 0; i < keyStats.length; i++) ...[
                        Expanded(child: _pill(keyStats[i], mul)),
                        if (i < keyStats.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                const SizedBox(height: 20),
                if (showWatermark)
                  FitWizWatermark(
                    textColor: Colors.white,
                    fontSize: 13 * mul,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(ShareableMetric m, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            m.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            m.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsPainter extends StatelessWidget {
  const _DotsPainter();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DotsPainterImpl());
}

class _DotsPainterImpl extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final r = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final radius = 1.0 + r.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainterImpl old) => false;
}
