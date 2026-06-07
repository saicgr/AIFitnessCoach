import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// FoodScoreCard — the meal's 1-10 health score as the hero: a big arc dial
/// colored by score band, a qualitative label, and a `MacroViz.donutTrio`
/// mini block. Falls back to a calorie hero when no score is present.
class FoodScoreCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;
  /// Display the score out of 100 instead of 10 (Calorii-audit P3.4 — a more
  /// marketable dial). Underlying score stays 1-10.
  final int scoreOutOf;

  const FoodScoreCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
    this.scoreOutOf = 10,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = data.aspect;
    final mul = aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    final score = data.healthScore;

    final dialSize = (aspect == ShareableAspect.story
            ? 360.0
            : aspect == ShareableAspect.portrait
                ? 320.0
                : 280.0) *
        1.0;
    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? '${data.mealLabel!.trim().toUpperCase()} · SCORE'
        : 'MEAL SCORE';

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0A0C11), accent, 0.16) ??
            const Color(0xFF0A0C11),
        const Color(0xFF050608),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 74, 38, 46),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(height: 8 * mul),
            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 29 * mul,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -0.5,
              ),
            ),
            Expanded(
              child: Center(
                child: score != null
                    ? _ScoreDial(score: score, size: dialSize, outOf: scoreOutOf)
                    : _CalorieHero(calories: nutrition.calories, mul: mul),
              ),
            ),
            if (score != null) ...[
              Text(
                _scoreLabel(score),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 18 * mul),
            ],
            MacroViz(
              nutrition: nutrition,
              style: MacroVizStyle.donutTrio,
              accentColor: accent,
              scale: mul * 0.92,
            ),
            SizedBox(height: 18 * mul),
            if (showWatermark)
              AppWatermark(textColor: Colors.white, fontSize: 13 * mul),
          ],
        ),
      ),
    );
  }

  static String _scoreLabel(int s) {
    if (s >= 9) return 'Elite fuel';
    if (s >= 7) return 'Great choice';
    if (s >= 5) return 'Solid meal';
    if (s >= 3) return 'Room to improve';
    return 'Indulgent';
  }
}

/// Band color for a 1-10 health score — green high, amber mid, red low.
/// A data-semantic color (like the macro colors), not the brand accent.
Color _bandColor(int score) {
  if (score >= 8) return const Color(0xFF22C55E);
  if (score >= 6) return const Color(0xFF84CC16);
  if (score >= 4) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

class _ScoreDial extends StatelessWidget {
  final int score; // stored 1-10
  final double size;
  /// Display scale — 10 (default) or 100 for a more marketable 0–100 dial
  /// (Calorii-audit P3.4). The underlying arc fill is unchanged (score/10).
  final int outOf;

  const _ScoreDial({required this.score, required this.size, this.outOf = 10});

  @override
  Widget build(BuildContext context) {
    final color = _bandColor(score);
    final displayValue = outOf == 100 ? score * 10 : score;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ScoreArcPainter(
              progress: (score / 10).clamp(0.0, 1.0),
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displayValue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * (outOf == 100 ? 0.28 : 0.34),
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              Text(
                'OUT OF $outOf',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.055,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 2);
    // 270° dial — starts bottom-left, sweeps clockwise.
    const start = math.pi * 0.75;
    const total = math.pi * 1.5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawArc(arcRect, start, total, false, track);

    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + total,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(arcRect);
    canvas.drawArc(arcRect, start, total * progress, false, value);
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _CalorieHero extends StatelessWidget {
  final int calories;
  final double mul;

  const _CalorieHero({required this.calories, required this.mul});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$calories',
          style: TextStyle(
            color: Colors.white,
            fontSize: 120 * mul,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -4,
          ),
        ),
        Text(
          'CALORIES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16 * mul,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
