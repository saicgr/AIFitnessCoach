import 'dart:math';
import 'package:flutter/material.dart';

/// Custom circular progress indicator with gradient support.
///
/// Flutter's default CircularProgressIndicator doesn't support gradients,
/// so this custom painter draws a gradient arc.
class GradientCircularProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double? value; // null = indeterminate
  final List<Color> gradientColors;
  final Color backgroundColor;
  final StrokeCap strokeCap;

  const GradientCircularProgressIndicator({
    super.key,
    this.size = 100,
    this.strokeWidth = 8,
    this.value,
    required this.gradientColors,
    this.backgroundColor = Colors.transparent,
    this.strokeCap = StrokeCap.round,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GradientCircularProgressPainter(
          strokeWidth: strokeWidth,
          value: value,
          gradientColors: gradientColors,
          backgroundColor: backgroundColor,
          strokeCap: strokeCap,
        ),
      ),
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double strokeWidth;
  final double? value;
  final List<Color> gradientColors;
  final Color backgroundColor;
  final StrokeCap strokeCap;

  _GradientCircularProgressPainter({
    required this.strokeWidth,
    required this.value,
    required this.gradientColors,
    required this.backgroundColor,
    required this.strokeCap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap;

      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Draw gradient arc
    if (value != null && value! > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      final gradientPaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          startAngle: -pi / 2,
          endAngle: -pi / 2 + (2 * pi * value!),
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap;

      // Draw arc from top (12 o'clock position)
      final startAngle = -pi / 2;
      final sweepAngle = 2 * pi * value!;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeCap != strokeCap;
  }
}
