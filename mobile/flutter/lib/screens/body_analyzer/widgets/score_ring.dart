import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Circular gauge used by the Body Analyzer 3-ring grid (Body Fat / Muscle
/// Mass / Symmetry). Deliberately self-contained — no external chart dep —
/// because the animation is fast enough on every device and the widget
/// stays snappy inside a Column rebuild.
class ScoreRing extends StatelessWidget {
  final String label;
  final String value; // "18%" / "9/10"
  final double fill; // 0.0..1.0
  final Color color;
  final bool isDark;

  const ScoreRing({
    super.key,
    required this.label,
    required this.value,
    required this.fill,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: CustomPaint(
              painter: _RingPainter(
                fill: fill.clamp(0.0, 1.0),
                color: color,
                trackColor: color.withValues(alpha: 0.18),
                strokeWidth: 8,
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fill;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.fill,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (fill <= 0) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.75), color],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * fill,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fill,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.fill != fill ||
        old.color != color ||
        old.trackColor != trackColor;
  }
}
