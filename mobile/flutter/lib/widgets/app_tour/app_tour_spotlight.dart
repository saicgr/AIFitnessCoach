import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter that draws a dark overlay with a spotlight cutout
class AppTourSpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double cornerRadius;
  final Color overlayColor;
  final Color ringColor;
  final double spotlightPadding;
  /// Optional gradient colors for an animated ring effect.
  final List<Color>? ringGradientColors;
  /// Rotation angle for the gradient ring (0.0 – 1.0).
  final double gradientRotation;
  /// Pixels at the BOTTOM of the canvas to leave undimmed — typically the
  /// floating tab bar's height + safe-area inset. Without this, the dim
  /// overlay sits underneath the floating nav and the bar looks washed out
  /// for the entire tour.
  final double bottomInset;

  const AppTourSpotlightPainter({
    required this.spotlightRect,
    required this.ringColor,
    this.cornerRadius = 12.0,
    this.overlayColor = const Color(0xBF000000), // 75% black
    this.spotlightPadding = 10.0,
    this.ringGradientColors,
    this.gradientRotation = 0.0,
    this.bottomInset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Shrink the dimmed area so it stops above the floating tab bar — the
    // tab bar then renders at full brightness on top of an undimmed
    // background instead of fighting the dim layer.
    final dimHeight = (size.height - bottomInset).clamp(0.0, size.height);
    final fullRect = Rect.fromLTWH(0, 0, size.width, dimHeight);

    // When spotlight rect is zero (target not yet visible), just draw the
    // full overlay without a cutout hole or ring.
    if (spotlightRect == Rect.zero) {
      canvas.drawRect(fullRect, Paint()..color = overlayColor);
      return;
    }

    // Inflate rect with padding
    final inflated = spotlightRect.inflate(spotlightPadding);
    final rRect = RRect.fromRectAndRadius(inflated, Radius.circular(cornerRadius));

    // Draw full overlay minus the cutout hole
    final holePath = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      Path()..addRRect(rRect),
    );
    canvas.drawPath(holePath, Paint()..color = overlayColor);

    // Draw ring around the hole
    final outerRRect = rRect.inflate(1);
    if (ringGradientColors != null && ringGradientColors!.length >= 2) {
      // Animated gradient ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..shader = SweepGradient(
          startAngle: gradientRotation * 2 * math.pi,
          endAngle: gradientRotation * 2 * math.pi + 2 * math.pi,
          colors: [...ringGradientColors!, ringGradientColors!.first],
          tileMode: TileMode.clamp,
        ).createShader(outerRRect.outerRect);
      canvas.drawRRect(outerRRect, ringPaint);

      // Soft glow
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = SweepGradient(
          startAngle: gradientRotation * 2 * math.pi,
          endAngle: gradientRotation * 2 * math.pi + 2 * math.pi,
          colors: [
            for (final c in ringGradientColors!) c.withValues(alpha: 0.4),
            ringGradientColors!.first.withValues(alpha: 0.4),
          ],
          tileMode: TileMode.clamp,
        ).createShader(outerRRect.outerRect);
      canvas.drawRRect(outerRRect, glowPaint);
    } else {
      // Solid ring
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(outerRRect, ringPaint);
    }
  }

  @override
  bool shouldRepaint(AppTourSpotlightPainter old) {
    return old.spotlightRect != spotlightRect ||
        old.ringColor != ringColor ||
        old.cornerRadius != cornerRadius ||
        old.ringGradientColors != ringGradientColors ||
        old.gradientRotation != gradientRotation ||
        old.bottomInset != bottomInset;
  }
}
