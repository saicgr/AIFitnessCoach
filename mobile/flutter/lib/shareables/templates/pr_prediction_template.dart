import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// PRPrediction — trajectory line chart with current PR + projected next PR
/// (dashed extension), sparkle on the projection point, "Next PR by [date]"
/// caption. Spark category. Shows what's coming next, not just what's
/// already done.
class PRPredictionTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PRPredictionTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);
    final projection = _projection(data);
    final projDate = _projectionDate();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF0B0F19), Color(0xFF050810)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: accent, size: 20 * mul),
                const SizedBox(width: 8),
                Text(
                  'PROJECTION',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26 * mul,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hero,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 64 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18 * mul,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: accent, size: 16 * mul),
                      const SizedBox(width: 4),
                      Text(
                        'Next: $projection${unit.isNotEmpty ? " $unit" : ""}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12 * mul,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: CustomPaint(
                painter: _TrajectoryPainter(accent: accent),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Next PR by $projDate',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14 * mul,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Based on your current cadence — keep the volume steady.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12 * mul,
              ),
            ),
            const Spacer(),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  String _projection(Shareable d) {
    final v = d.heroValue;
    if (v == null) return '+5%';
    final next = (v.toDouble() * 1.05);
    if (next == next.roundToDouble()) return next.round().toString();
    return next.toStringAsFixed(1);
  }

  String _projectionDate() {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 14));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[next.month - 1]} ${next.day}';
  }
}

class _TrajectoryPainter extends CustomPainter {
  final Color accent;
  _TrajectoryPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Solid line — past data points (deterministic seed).
    final pastPoints = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final x = w * (i / 9);
      final n = math.sin(i * 0.85) * 0.08 + (i / 9) * 0.55;
      final y = h - h * (0.18 + n);
      pastPoints.add(Offset(x, y));
    }

    // Glow under the line.
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.45),
          accent.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final glowPath = Path()..moveTo(pastPoints.first.dx, h);
    for (final p in pastPoints) {
      glowPath.lineTo(p.dx, p.dy);
    }
    glowPath.lineTo(pastPoints.last.dx, h);
    glowPath.close();
    canvas.drawPath(glowPath, glow);

    // Solid past-line.
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pastPath = Path()..moveTo(pastPoints.first.dx, pastPoints.first.dy);
    for (var i = 1; i < pastPoints.length; i++) {
      pastPath.lineTo(pastPoints[i].dx, pastPoints[i].dy);
    }
    canvas.drawPath(pastPath, linePaint);

    // Dashed projection.
    final last = pastPoints.last;
    final projPoint = Offset(w - 24, h * 0.18);
    _drawDashedLine(canvas, last, projPoint, accent.withValues(alpha: 0.7));

    // Past dots.
    final dotPaint = Paint()..color = accent;
    for (final p in pastPoints) {
      canvas.drawCircle(p, 4, dotPaint);
    }
    // Halo'd projection dot.
    canvas.drawCircle(
      projPoint,
      14,
      Paint()..color = accent.withValues(alpha: 0.18),
    );
    canvas.drawCircle(projPoint, 7, Paint()..color = Colors.white);
    canvas.drawCircle(projPoint, 4, dotPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final unit = Offset(dx / dist, dy / dist);
    const dash = 10.0;
    const gap = 6.0;
    var d = 0.0;
    while (d < dist) {
      final start = a + unit * d;
      final end = a + unit * math.min(d + dash, dist);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) => old.accent != accent;
}
