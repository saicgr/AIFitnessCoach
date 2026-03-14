import 'package:flutter/material.dart';

/// CustomPainter that draws a dark overlay with a spotlight cutout
class AppTourSpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double cornerRadius;
  final Color overlayColor;
  final Color ringColor;
  final double spotlightPadding;

  const AppTourSpotlightPainter({
    required this.spotlightRect,
    required this.ringColor,
    this.cornerRadius = 12.0,
    this.overlayColor = const Color(0xBF000000), // 75% black
    this.spotlightPadding = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

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

    // Draw accent ring around the hole
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rRect.inflate(1), ringPaint);
  }

  @override
  bool shouldRepaint(AppTourSpotlightPainter old) {
    return old.spotlightRect != spotlightRect ||
        old.ringColor != ringColor ||
        old.cornerRadius != cornerRadius;
  }
}
