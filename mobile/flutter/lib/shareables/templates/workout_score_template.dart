import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// WorkoutScore — composite scorecard with a large center number (out of
/// 100), four radial mini-rings around it for sub-scores (Effort / Form /
/// Volume / Recovery), sparkle accent on overall. Spark category.
class WorkoutScoreTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WorkoutScoreTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const _categories = ['EFFORT', 'FORM', 'VOLUME', 'RECOVERY'];

  int _overallScore() {
    final populated = data.highlights.where((h) => h.isPopulated).length;
    final hasStreak = data.highlights
        .any((h) => h.label.toUpperCase().contains('STREAK'));
    final hasPR =
        data.highlights.any((h) => h.label.toUpperCase().contains('PR'));
    var s = 60 + populated * 7;
    if (hasStreak) s += 6;
    if (hasPR) s += 8;
    return s.clamp(50, 99);
  }

  List<int> _subScores(int seedFromHero, int overall) {
    final r = math.Random(seedFromHero);
    return List.generate(4, (i) {
      final spread = r.nextInt(16) - 8;
      return (overall + spread).clamp(50, 99);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final overall = _overallScore();
    final subs = _subScores((data.heroValue ?? 0).toInt() + data.title.length, overall);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF06080F),
        Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'WORKOUT SCORE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: _ScoreRingPainter(
                  score: overall,
                  accent: accent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        overall.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -3,
                        ),
                      ),
                      Text(
                        'OUT OF 100',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11 * mul,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                return _miniRing(_categories[i], subs[i], accent, mul);
              }),
            ),
            const Spacer(),
            if (showWatermark)
              FitWizWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniRing(String label, int score, Color accent, double mul) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              score: score,
              accent: accent,
              strokeWidth: 5,
              showGlow: false,
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * mul,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10 * mul,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color accent;
  final double strokeWidth;
  final bool showGlow;

  _ScoreRingPainter({
    required this.score,
    required this.accent,
    this.strokeWidth = 16,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final sweep = (score / 100.0) * 2 * math.pi;
    final ring = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [
          accent.withValues(alpha: 0.4),
          accent,
          Color.lerp(accent, Colors.white, 0.4)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      ring,
    );

    if (showGlow) {
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.score != score || old.accent != accent;
}
