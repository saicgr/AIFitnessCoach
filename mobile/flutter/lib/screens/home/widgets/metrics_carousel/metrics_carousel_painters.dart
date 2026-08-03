/// CustomPainter geometry for the metrics carousel — no chart package
/// (build spec: "Everything above is CustomPainter-shaped: the ring, the
/// area, the arc and the bars are all simple geometry").
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Training page ring — 12 tick marks around a bezel + an accent arc from
/// -90° proportional to [fraction]. [muted] paints the arc (and the track,
/// if [fraction] is 0) in a dim neutral rather than the accent — used when
/// there's simply nothing to celebrate yet (0 sessions).
class TickRingPainter extends CustomPainter {
  final double fraction; // 0..1, clamped by caller
  final bool muted;
  final Color trackColor;
  final Color tickColor;
  final Color accentColor;
  final Color mutedColor;

  const TickRingPainter({
    required this.fraction,
    required this.muted,
    required this.trackColor,
    required this.tickColor,
    required this.accentColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * (38 / 104);
    final tickInner = size.width * (44 / 104);
    final tickOuter = size.width * (50 / 104);

    // 12 tick marks around the bezel.
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = size.width * (1.5 / 104)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * tickInner;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * tickOuter;
      canvas.drawLine(p1, p2, tickPaint);
    }

    final strokeWidth = size.width * (8 / 104);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return; // empty track, no arc — the 0-sessions guard.

    final arcPaint = Paint()
      ..color = muted ? mutedColor : accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TickRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.muted != muted ||
      oldDelegate.accentColor != accentColor;
}

/// Volume-trend area chart. Three modes, chosen by the caller from the
/// number of real weekly points:
///   * >=2 points → gradient area + line + endpoint dot (+ small dots at
///     interior points, matching the mockup).
///   * 1 point → a single dot on a dashed baseline, no line (never draw a
///     line from nothing).
///   * 0 points → an empty dashed baseline only.
class AreaChartPainter extends CustomPainter {
  /// Normalized 0..1 values, chronological. Empty or single-element lists
  /// switch to the reduced-guard rendering described above.
  final List<double> values;
  final Color accentColor;
  final Color baselineColor;

  const AreaChartPainter({
    required this.values,
    required this.accentColor,
    required this.baselineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baselineY = size.height - 8;
    if (values.length < 2) {
      final dashPaint = Paint()
        ..color = baselineColor
        ..strokeWidth = 1;
      _drawDashedLine(canvas, Offset(6, baselineY),
          Offset(size.width - 6, baselineY), dashPaint);
      if (values.length == 1) {
        canvas.drawCircle(
          Offset(6, baselineY),
          4,
          Paint()..color = accentColor,
        );
      }
      return;
    }

    final points = <Offset>[];
    final n = values.length;
    for (int i = 0; i < n; i++) {
      final x = 6 + (size.width - 12) * (i / (n - 1));
      final y = 8 + (size.height - 16) * (1 - values[i].clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }

    final areaPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.lineTo(points.first.dx, size.height);
    areaPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentColor.withValues(alpha: 0.30), accentColor.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, gradientPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Small dots at interior points (skip first — the mockup only marks
    // interior + endpoint), larger dot at the endpoint.
    final dotPaint = Paint()..color = accentColor;
    for (int i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 2.4, dotPaint);
    }
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 3.0;
    const gapWidth = 5.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    double covered = 0;
    while (covered < total) {
      final start = a + direction * covered;
      final end = a + direction * math.min(covered + dashWidth, total);
      canvas.drawLine(start, end, paint);
      covered += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant AreaChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.accentColor != accentColor;
}

/// Recovery page's 180° readiness arc (donut, round caps).
class ReadinessArcPainter extends CustomPainter {
  final double fraction; // 0..1
  final Color trackColor;
  final Color accentColor;

  const ReadinessArcPainter({
    required this.fraction,
    required this.trackColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * (9 / 100);
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height - strokeWidth / 2 - 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    if (fraction <= 0) return;
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * fraction.clamp(0.0, 1.0), false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant ReadinessArcPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.accentColor != accentColor;
}

/// Recovery page's 7-night sleep bars. A night with no data (0) renders as a
/// hairline stub, never an invented bar height.
class SleepBarsPainter extends CustomPainter {
  /// Normalized 0..1 per night (0 = no data / no sleep logged), oldest first.
  final List<double> values;
  final Color accentColor;

  const SleepBarsPainter({required this.values, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final gap = size.width * 0.05;
    final barWidth = (size.width - gap * (n - 1)) / n;
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final h = v <= 0 ? 2.0 : size.height * (0.15 + 0.85 * v);
      final rect = Rect.fromLTWH(
        i * (barWidth + gap),
        size.height - h,
        barWidth,
        h,
      );
      final opacity = 0.5 + 0.5 * v;
      final paint = Paint()
        ..color = accentColor.withValues(alpha: v <= 0 ? 0.25 : opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SleepBarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.accentColor != accentColor;
}
