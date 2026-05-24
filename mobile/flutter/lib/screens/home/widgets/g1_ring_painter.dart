/// G1 Open-arc gradient ring painter.
///
/// Translates the `vG1(values)` SVG renderer in
/// `design-mocks/home/circle-compositions.html` into Flutter CustomPainter
/// form, plus three additions that aren't in the JS mock but are required by
/// the home-redesign plan (§1):
///
///   * a full-circle ghost outline (Whoop/Bevel "ghost ring" effect)
///   * a small filled goal-tick dot on the ring
///   * a diagonal-hatch zero-state fill in the 270° arc band
///
/// Layer order (back → front):
///   1. radial halo backdrop
///   2. 360° ghost outline
///   3. 270° track arc
///   4. 270° progress arc (sweep gradient)
///   5. goal-tick dot                 (optional)
///   6. diagonal hatch zero-state    (optional)
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'score_colors.dart';

/// Canonical track colour used by the mock (`TRACK = '#E8E6E0'`).
const Color kG1TrackColor = Color(0xFFE8E6E0);

/// Stroke width for the arc (matches `stroke = 7` in `vG1`).
const double kG1Stroke = 7.0;

/// Arc geometry — mirrors `startA = 135, endA = 135 + 270` in the mock.
///
/// Mathematical convention here matches the SVG renderer: 0° = +x (right),
/// 90° = +y (down). Flutter's `Canvas.drawArc` uses the same convention.
const double kG1StartAngleDeg = 135.0;
const double kG1SweepDeg = 270.0;

class G1RingPainter extends CustomPainter {
  /// 0.0 → 1.0. Clamped before draw.
  final double progress;

  /// Pillar/contributor accent color. Drives the sweep gradient + halo + dot.
  final Color color;

  /// Track color behind the progress arc. Defaults to [kG1TrackColor] when
  /// callers don't pass an explicit theme-aware value.
  final Color trackColor;

  /// Optional angle (degrees, same convention as start angle) at which to
  /// paint the small filled goal-tick dot. When null, the dot is skipped.
  final double? goalTickAt;

  /// When true AND [progress] is exactly 0, paints a 45° diagonal hatch
  /// pattern across the 270° arc band. Mirrors Whoop Strain 0% treatment.
  final bool isZero;

  const G1RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.goalTickAt,
    this.isZero = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double p = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

    final Offset center = Offset(size.width / 2, size.height / 2);
    // Stroke must fit inside the canvas. Halo gets +10px headroom in the mock
    // but here we squeeze inside the bounds the parent layout gives us.
    final double r =
        math.min(size.width, size.height) / 2 - kG1Stroke / 2 - 2;
    if (r <= 0) return;

    final Rect arcRect = Rect.fromCircle(center: center, radius: r);

    // 1) Halo backdrop ----------------------------------------------------
    // Mock: radialGradient cx=50% cy=50% r=55% — 40% transparent → 100% at 0.22 alpha.
    // We approximate that two-stop ramp with a 3-stop Flutter RadialGradient
    // so the inner ~40% is fully transparent before fading up.
    final Paint haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.22),
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: r + 10),
      );
    canvas.drawCircle(center, r + 10, haloPaint);

    // 2) Full-circle ghost outline ---------------------------------------
    final Paint ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.14);
    canvas.drawCircle(center, r, ghostPaint);

    // 3) 270° track arc ---------------------------------------------------
    final double startRad = kG1StartAngleDeg * math.pi / 180.0;
    final double sweepRad = kG1SweepDeg * math.pi / 180.0;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kG1Stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor.withValues(alpha: 0.6);
    canvas.drawArc(arcRect, startRad, sweepRad, false, trackPaint);

    // 4) Progress arc (sweep gradient) -----------------------------------
    if (p > 0) {
      // SweepGradient defaults to angle 0 = +x and sweeps counter-clockwise
      // visually, but mathematically clockwise in our (y-down) coordinate
      // system. We rotate the gradient so its 0-stop sits at the arc start.
      final Paint progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kG1Stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweepRad,
          colors: [
            shadeColor(color, 0.18),
            color,
            shadeColor(color, -0.15),
          ],
          stops: const [0.0, 0.6, 1.0],
          transform: GradientRotation(startRad),
        ).createShader(arcRect);
      canvas.drawArc(arcRect, startRad, sweepRad * p, false, progressPaint);
    }

    // 5) Goal-tick dot ----------------------------------------------------
    if (goalTickAt != null) {
      final double tickRad = goalTickAt! * math.pi / 180.0;
      final Offset tickPos = Offset(
        center.dx + r * math.cos(tickRad),
        center.dy + r * math.sin(tickRad),
      );
      final Paint dotPaint = Paint()..color = color;
      canvas.drawCircle(tickPos, 3.0, dotPaint);
    }

    // 6) Zero-state diagonal hatch ---------------------------------------
    if (isZero && p == 0) {
      _paintZeroHatch(canvas, center, r);
    }
  }

  /// Fills the 270° arc band area with 45° diagonal hatch lines (3pt spacing,
  /// 1pt thick, `color.withOpacity(0.55)`). Clipped to a ring band of width
  /// [kG1Stroke] around radius r, and further clipped to the 270° sector so
  /// the hatch doesn't bleed into the top gap.
  void _paintZeroHatch(Canvas canvas, Offset center, double r) {
    canvas.save();

    // Build a ring-band clip (outer radius - inner radius == kG1Stroke).
    final Path ring = Path()
      ..addOval(Rect.fromCircle(center: center, radius: r + kG1Stroke / 2))
      ..addOval(Rect.fromCircle(center: center, radius: r - kG1Stroke / 2))
      ..fillType = PathFillType.evenOdd;

    // Sector clip for the 270° span. Built as a wedge from the centre.
    final double startRad = kG1StartAngleDeg * math.pi / 180.0;
    final double sweepRad = kG1SweepDeg * math.pi / 180.0;
    final Path sector = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + (r + kG1Stroke) * math.cos(startRad),
        center.dy + (r + kG1Stroke) * math.sin(startRad),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: r + kG1Stroke),
        startRad,
        sweepRad,
        false,
      )
      ..close();

    // Intersect ring ∩ sector.
    final Path clip = Path.combine(PathOperation.intersect, ring, sector);
    canvas.clipPath(clip);

    final Paint hatchPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double diag = (r + kG1Stroke) * 2;
    const double spacing = 3.0;
    // Walk lines across a square that bounds the ring, drawing 45° diagonals.
    for (double d = -diag; d <= diag; d += spacing) {
      final Offset p1 = Offset(center.dx + d, center.dy - diag);
      final Offset p2 = Offset(center.dx + d + diag * 2, center.dy + diag);
      canvas.drawLine(p1, p2, hatchPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant G1RingPainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.trackColor != trackColor ||
        old.goalTickAt != goalTickAt ||
        old.isZero != isZero;
  }
}
