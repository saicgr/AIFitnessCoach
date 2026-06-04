import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/stat_typography.dart';

/// A glowing hexagon score badge — the recurring Gravl visual (the "232" / "252"
/// chip in the strength-score screenshots). Renders a hexagon outline with an
/// outer glow + a centered, auto-fitting number.
///
/// [color] is REQUIRED and never hardcoded inside — callers pass their accent /
/// theme color (`ThemeColors.of(context).accent`) so the badge stays on-theme.
/// A faint translucent fill + a crisp stroke + a blurred outer-glow stroke give
/// the "lit up" look without a backdrop blur (cheap to paint many times).
class HexagonBadge extends StatelessWidget {
  /// The number/text shown in the center (e.g. "232").
  final String value;

  /// Outline + number color. Pass an accent/theme color, never a literal.
  final Color color;

  /// Width/height of the badge box.
  final double size;

  /// Whether to draw the soft outer glow ring.
  final bool glow;

  /// Optional override for the number's font size. Defaults to ~40% of [size].
  final double? numberSize;

  /// Flat top/bottom edges (true) vs a point at top/bottom (false).
  final bool flatTop;

  const HexagonBadge({
    super.key,
    required this.value,
    required this.color,
    this.size = 64,
    this.glow = true,
    this.numberSize,
    this.flatTop = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(color: color, glow: glow, flatTop: flatTop),
        child: Center(
          child: Padding(
            // Keep the number off the angled edges.
            padding: EdgeInsets.symmetric(horizontal: size * 0.18),
            child: StatNumber(
              value: value,
              size: numberSize ?? size * 0.40,
              color: color,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color color;
  final bool glow;
  final bool flatTop;

  _HexPainter({required this.color, required this.glow, required this.flatTop});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size, flatTop);

    // Translucent fill so the center reads as "lit".
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.10),
    );

    // Soft outer glow.
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
      );
    }

    // Crisp outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  Path _hexPath(Size size, bool flatTop) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 2;
    final offset = flatTop ? 0.0 : 30.0;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final deg = 60.0 * i + offset;
      final rad = deg * math.pi / 180.0;
      final x = cx + r * math.cos(rad);
      final y = cy + r * math.sin(rad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.color != color || old.glow != glow || old.flatTop != flatTop;
}
