import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A semi-transparent overlay of a "before" image on top of the current view,
/// with crosshair alignment guides for pose matching.
class GhostOverlayWidget extends StatelessWidget {
  final String beforeImageUrl;
  final double opacity;
  final bool showGuides;

  const GhostOverlayWidget({
    super.key,
    required this.beforeImageUrl,
    this.opacity = 0.4,
    this.showGuides = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Semi-transparent before image
        Opacity(
          opacity: opacity,
          child: CachedNetworkImage(
            imageUrl: beforeImageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // Alignment crosshair guides
        if (showGuides)
          IgnorePointer(
            child: CustomPaint(
              painter: _CrosshairPainter(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Horizontal center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Thirds lines (rule of thirds for body alignment)
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), paint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      color != oldDelegate.color;
}
