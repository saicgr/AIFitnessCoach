import 'package:flutter/material.dart';

import 'trend_correlation.dart';

/// A compact area + line sparkline for a saved trend's primary series.
///
/// Pure presentation — it takes already-resolved [TrendPoint]s and a colour and
/// paints a normalised mini chart (min→max over the visible window). Both the
/// home "Your trends" carousel and the Saved-trends sheet feed it points from
/// `trendSeriesProvider`, so the look stays identical across surfaces.
///
/// Needs ≥2 points to draw a line; with fewer it renders nothing (callers show
/// an honest "log again" / "no data" hint in that case).
class MiniTrendSparkline extends StatelessWidget {
  final List<TrendPoint> points;
  final Color color;

  /// When true, fills the area under the line with a soft vertical gradient.
  final bool fill;

  const MiniTrendSparkline({
    super.key,
    required this.points,
    required this.color,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniSparkPainter(points: points, color: color, fill: fill),
      size: Size.infinite,
    );
  }
}

class _MiniSparkPainter extends CustomPainter {
  final List<TrendPoint> points;
  final Color color;
  final bool fill;

  _MiniSparkPainter({
    required this.points,
    required this.color,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    var minV = points.first.value;
    var maxV = points.first.value;
    for (final p in points) {
      if (p.value < minV) minV = p.value;
      if (p.value > maxV) maxV = p.value;
    }
    // Flat series (all equal) → a horizontal mid-line, not a divide-by-zero.
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final minMs = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxMs = points.last.date.millisecondsSinceEpoch.toDouble();
    final spanX = (maxMs - minMs).abs() < 1e-9 ? 1.0 : (maxMs - minMs);

    // Inset top/bottom so the line never clips against the card edge.
    const padY = 4.0;
    final h = size.height - padY * 2;

    Offset at(int i) {
      final x =
          (points[i].date.millisecondsSinceEpoch - minMs) / spanX * size.width;
      final y = padY + (1 - (points[i].value - minV) / span) * h;
      return Offset(x, y);
    }

    final path = Path();
    final first = at(0);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final o = at(i);
      path.lineTo(o.dx, o.dy);
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Emphasise the latest value with a small end dot.
    final last = at(points.length - 1);
    canvas.drawCircle(last, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MiniSparkPainter old) =>
      old.points != points || old.color != color || old.fill != fill;
}
