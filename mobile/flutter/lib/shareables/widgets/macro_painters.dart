import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pure `CustomPainter`s backing the 14 macro-visualization styles rendered by
/// `MacroViz` (`macro_viz.dart`).
///
/// LAYERING NOTE — INTENTIONAL COPY-AND-PUBLISH FORK.
/// `lib/shareables/` must not import anything from `lib/screens/`. The ring /
/// bar geometry below is therefore a deliberate fork of the originals:
///   • concentric-ring math  ← `_CompactMacroRingsPainter`
///       (`lib/screens/home/widgets/cards/macro_rings_card.dart`)
///   • single-ring math      ← `_RingPainter`
///       (`lib/screens/nutrition/widgets/menu_analysis/macro_budget_ring.dart`)
///   • stacked-bar math      ← `_MacroBar` / `_Track`
///       (`lib/screens/home/widgets/home/unified_home_widgets.dart`)
/// Keep the geometry behaviorally identical to those sources; do NOT add an
/// import to re-share them — the architectural rule forbids it.
///
/// Everything here is provider-free and context-free so the share-capture
/// pipeline can screenshot it deterministically.

/// One progress ring inside [RingsPainter]: a 0..1+ progress with its color.
/// `progress` may exceed 1.0 — values above 1.0 paint a brighter "overshoot"
/// lap on top of the full ring (ported from the home macro-rings card).
@immutable
class MacroRing {
  final double progress;
  final Color color;

  const MacroRing(this.progress, this.color);
}

/// N concentric progress rings, outermost first. Used for both the single
/// calorie ring (one entry) and the Apple-style trio (three entries).
///
/// Geometry forked from `_CompactMacroRingsPainter`: each inner ring steps in
/// by `strokeWidth + gap`; an empty ring still paints a 2% sliver so it reads
/// as "present, not started"; overshoot (progress > 1.0) paints a lighter lap.
class RingsPainter extends CustomPainter {
  /// Rings ordered outer → inner.
  final List<MacroRing> rings;
  final double strokeWidth;

  /// Radial gap between adjacent rings.
  final double gap;
  final Color trackColor;

  /// Rounded stroke caps (Apple-rings look) vs butt caps.
  final bool roundCaps;

  /// 12 o'clock start, clockwise sweep — matches every in-app ring.
  final double startAngle;

  const RingsPainter({
    required this.rings,
    this.strokeWidth = 9.0,
    this.gap = 1.5,
    this.trackColor = const Color(0x14FFFFFF),
    this.roundCaps = true,
    this.startAngle = -math.pi / 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rings.isEmpty || size.shortestSide <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final cap = roundCaps ? StrokeCap.round : StrokeCap.butt;

    // Outermost ring sits half a stroke inside the box edge.
    var radius = (size.shortestSide / 2) - strokeWidth / 2;
    for (final ring in rings) {
      if (radius <= strokeWidth / 2) break; // Ran out of room — stop cleanly.
      _drawRing(canvas, center, radius, ring, cap);
      radius -= strokeWidth + gap;
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    MacroRing ring,
    StrokeCap cap,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = cap,
    );

    // Keep a sliver visible so an empty ring is never invisible.
    final effective = ring.progress <= 0 ? 0.02 : ring.progress;
    final clamped = effective.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      startAngle,
      2 * math.pi * clamped,
      false,
      Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = cap,
    );

    // Overshoot lap — a brighter partial arc when the macro is over goal.
    if (ring.progress > 1.0) {
      final overshoot = (ring.progress - 1.0).clamp(0.0, 0.5);
      canvas.drawArc(
        rect,
        startAngle,
        2 * math.pi * overshoot,
        false,
        Paint()
          ..color = Color.lerp(ring.color, Colors.white, 0.35)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = cap,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingsPainter old) =>
      old.strokeWidth != strokeWidth ||
      old.gap != gap ||
      old.trackColor != trackColor ||
      old.roundCaps != roundCaps ||
      old.startAngle != startAngle ||
      !_ringsEqual(old.rings, rings);

  static bool _ringsEqual(List<MacroRing> a, List<MacroRing> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].progress != b[i].progress || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }
}

/// One wedge of a [MacroPiePainter] / [PlatePainter] donut.
@immutable
class MacroWedge {
  /// Relative magnitude — wedges are sized by `value / sum(values)`.
  final double value;
  final Color color;

  const MacroWedge(this.value, this.color);
}

/// A donut split into proportional wedges. Backs the `macroPie` style and,
/// with [rim] enabled, the `plate` style.
///
/// When every wedge value is 0 it draws a single faint full ring so an empty
/// payload still renders as a recognizable donut rather than nothing.
class MacroPiePainter extends CustomPainter {
  final List<MacroWedge> wedges;

  /// Donut thickness as a fraction of the radius (0..1]. 1.0 = a full pie.
  final double thicknessFraction;

  /// Angular gap (radians) between wedges so the slices read as separate.
  final double wedgeGap;

  /// Optional plate-rim stroke just outside the donut (the `plate` style).
  final bool rim;
  final Color rimColor;
  final Color emptyColor;
  final double startAngle;

  const MacroPiePainter({
    required this.wedges,
    this.thicknessFraction = 0.42,
    this.wedgeGap = 0.04,
    this.rim = false,
    this.rimColor = const Color(0x33FFFFFF),
    this.emptyColor = const Color(0x14FFFFFF),
    this.startAngle = -math.pi / 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final thickness =
        (outer * thicknessFraction.clamp(0.05, 1.0)).clamp(1.0, outer);
    // The arc is stroked along the mid-radius of the donut band.
    final radius = outer - thickness / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = wedges.fold<double>(0, (s, w) => s + math.max(0, w.value));

    if (total <= 0) {
      // Empty payload — a faint full ring keeps the shape legible.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = emptyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness,
      );
    } else {
      final live = wedges.where((w) => w.value > 0).toList();
      // Gaps only make sense between 2+ visible wedges.
      final gap = live.length > 1 ? wedgeGap : 0.0;
      final usable = (2 * math.pi) - gap * live.length;
      var angle = startAngle;
      for (final w in live) {
        final sweep = usable * (w.value / total);
        canvas.drawArc(
          rect,
          angle,
          sweep,
          false,
          Paint()
            ..color = w.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.butt,
        );
        angle += sweep + gap;
      }
    }

    if (rim) {
      canvas.drawCircle(
        center,
        outer - 0.75,
        Paint()
          ..color = rimColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MacroPiePainter old) =>
      old.thicknessFraction != thicknessFraction ||
      old.wedgeGap != wedgeGap ||
      old.rim != rim ||
      old.rimColor != rimColor ||
      old.emptyColor != emptyColor ||
      old.startAngle != startAngle ||
      !_wedgesEqual(old.wedges, wedges);

  static bool _wedgesEqual(List<MacroWedge> a, List<MacroWedge> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}

/// A solid "balanced plate": a filled disc split into proportional wedges with
/// a subtle rim. An alternative to [MacroPiePainter] for the `plate` style
/// when a full pie (not a donut) is wanted.
class PlatePainter extends CustomPainter {
  final List<MacroWedge> wedges;
  final Color rimColor;
  final Color emptyColor;
  final double startAngle;

  const PlatePainter({
    required this.wedges,
    this.rimColor = const Color(0x44FFFFFF),
    this.emptyColor = const Color(0x14FFFFFF),
    this.startAngle = -math.pi / 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = wedges.fold<double>(0, (s, w) => s + math.max(0, w.value));

    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = emptyColor
          ..style = PaintingStyle.fill,
      );
    } else {
      var angle = startAngle;
      for (final w in wedges) {
        if (w.value <= 0) continue;
        final sweep = 2 * math.pi * (w.value / total);
        canvas.drawArc(
          rect,
          angle,
          sweep,
          true, // useCenter — filled pie slice.
          Paint()
            ..color = w.color
            ..style = PaintingStyle.fill,
        );
        angle += sweep;
      }
    }

    // Plate rim on top so slice edges stay crisp.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant PlatePainter old) =>
      old.rimColor != rimColor ||
      old.emptyColor != emptyColor ||
      old.startAngle != startAngle ||
      !MacroPiePainter._wedgesEqual(old.wedges, wedges);
}

/// A 180–270° arc gauge (speedometer) with a track + colored fill, for the
/// `gauge` style. `progress` clamps to 0..1; the fill sweeps from the left of
/// the arc toward the right.
class GaugePainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color trackColor;
  final double strokeWidth;

  /// Total arc span in radians. `pi` = a 180° semicircle (default);
  /// `pi * 1.5` = a 270° gauge.
  final double sweepAngle;

  const GaugePainter({
    required this.progress,
    required this.fillColor,
    this.trackColor = const Color(0x1FFFFFFF),
    this.strokeWidth = 16,
    this.sweepAngle = math.pi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final span = sweepAngle.clamp(math.pi / 2, 2 * math.pi - 0.01);
    // Center the arc horizontally; anchor it so a 180° gauge sits as a clean
    // semicircle filling the box width.
    final radius =
        math.max(1.0, math.min(size.width / 2, size.height) - strokeWidth / 2);
    final center = Offset(size.width / 2, size.height - strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Symmetric about straight-up (-pi/2): a 180° gauge runs pi..2pi.
    final start = -math.pi / 2 - span / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, span, false, track);

    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      final fill = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, span * p, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.sweepAngle != sweepAngle;
}

/// One segment of a [StackedBarPainter].
@immutable
class BarSegment {
  /// Relative magnitude — segment width is `value / sum(values)`.
  final double value;
  final Color color;

  const BarSegment(this.value, this.color);
}

/// A single rounded horizontal bar split into proportional segments.
/// Forked from `_MacroBar` / `_Track`: a clipped rounded-rect track with the
/// segments laid left-to-right inside it. An all-zero payload paints just the
/// faint track.
class StackedBarPainter extends CustomPainter {
  final List<BarSegment> segments;
  final Color trackColor;

  /// Corner radius; clamped to half the bar height so it can't over-round.
  final double radius;

  const StackedBarPainter({
    required this.segments,
    this.trackColor = const Color(0x1FFFFFFF),
    this.radius = 999,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final r = math.min(radius, size.height / 2);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );

    // Track.
    canvas.drawRRect(rrect, Paint()..color = trackColor);

    final total = segments.fold<double>(0, (s, x) => s + math.max(0, x.value));
    if (total <= 0) return;

    // Clip to the rounded track so segment ends inherit the rounding.
    canvas.save();
    canvas.clipRRect(rrect);
    var x = 0.0;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final w = size.width * (seg.value / total);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w + 0.5, size.height), // +0.5 hides seams.
        Paint()..color = seg.color,
      );
      x += w;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StackedBarPainter old) =>
      old.trackColor != trackColor ||
      old.radius != radius ||
      !_segEqual(old.segments, segments);

  static bool _segEqual(List<BarSegment> a, List<BarSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}

/// One column of a [ColumnChartPainter].
@immutable
class ChartColumn {
  /// Absolute magnitude — heights are scaled against the tallest column.
  final double value;
  final Color color;

  const ChartColumn(this.value, this.color);
}

/// N vertical bars, heights proportional to value, drawn along a baseline.
/// An all-zero payload paints short faint stubs so the chart still has shape.
class ColumnChartPainter extends CustomPainter {
  final List<ChartColumn> columns;

  /// Fraction of each column's slot width the bar actually occupies (0..1).
  final double barWidthFraction;
  final double radius;

  /// Faint stub height (px) drawn when all values are 0.
  final double emptyStub;

  const ColumnChartPainter({
    required this.columns,
    this.barWidthFraction = 0.62,
    this.radius = 6,
    this.emptyStub = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (columns.isEmpty || size.width <= 0 || size.height <= 0) return;
    final slot = size.width / columns.length;
    final barW = (slot * barWidthFraction.clamp(0.1, 1.0));
    final maxVal = columns.fold<double>(
      0,
      (m, c) => math.max(m, math.max(0, c.value)),
    );

    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final centerX = slot * i + slot / 2;
      final double h;
      if (maxVal <= 0) {
        h = emptyStub;
      } else {
        // Reserve a little headroom so the value label above never clips.
        h = (math.max(0, col.value) / maxVal) * size.height;
      }
      final clampedH = h.clamp(emptyStub, size.height);
      final rect = Rect.fromLTWH(
        centerX - barW / 2,
        size.height - clampedH,
        barW,
        clampedH,
      );
      // Round only the top corners — bars sit on a baseline.
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = maxVal <= 0 ? col.color.withValues(alpha: 0.25) : col.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ColumnChartPainter old) =>
      old.barWidthFraction != barWidthFraction ||
      old.radius != radius ||
      old.emptyStub != emptyStub ||
      !_colEqual(old.columns, columns);

  static bool _colEqual(List<ChartColumn> a, List<ChartColumn> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}

/// A 10×10 grid of rounded cells, filled in reading order (top-left → right,
/// then down) by category proportion — an infographic "waffle" chart.
///
/// Cell counts are computed with largest-remainder rounding so the 100 cells
/// are split exactly in proportion to the category values. Unfilled cells get
/// [emptyColor].
class WafflePainter extends CustomPainter {
  /// Category → (proportion magnitude, color). Cells are allocated in list
  /// order; magnitudes need not sum to anything in particular.
  final List<MacroWedge> categories;
  final Color emptyColor;

  /// Gap between cells as a fraction of the cell pitch (0..0.5).
  final double cellGapFraction;
  final double cellRadius;

  /// Grid side length — 10 → the canonical 100-cell waffle.
  final int side;

  const WafflePainter({
    required this.categories,
    this.emptyColor = const Color(0x14FFFFFF),
    this.cellGapFraction = 0.16,
    this.cellRadius = 3,
    this.side = 10,
  });

  /// Largest-remainder allocation of [total] cells across [categories].
  List<int> _allocate(int total) {
    final sum =
        categories.fold<double>(0, (s, c) => s + math.max(0, c.value));
    if (sum <= 0) return List<int>.filled(categories.length, 0);
    final exact = categories
        .map((c) => math.max(0.0, c.value) / sum * total)
        .toList();
    final floors = exact.map((e) => e.floor()).toList();
    var used = floors.fold<int>(0, (s, f) => s + f);
    // Hand out the leftover cells to the largest fractional remainders.
    final remainder = <MapEntry<int, double>>[
      for (var i = 0; i < exact.length; i++)
        MapEntry(i, exact[i] - floors[i]),
    ]..sort((a, b) => b.value.compareTo(a.value));
    var idx = 0;
    while (used < total && idx < remainder.length) {
      floors[remainder[idx].key]++;
      used++;
      idx++;
    }
    return floors;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0 || side <= 0) return;
    final total = side * side;
    final alloc = _allocate(total);

    // Flatten allocations into a per-cell color list (reading order).
    final cellColors = <Color>[];
    for (var c = 0; c < categories.length; c++) {
      for (var k = 0; k < alloc[c]; k++) {
        cellColors.add(categories[c].color);
      }
    }
    while (cellColors.length < total) {
      cellColors.add(emptyColor);
    }

    final pitch = size.shortestSide / side;
    final gap = pitch * cellGapFraction.clamp(0.0, 0.5);
    final cell = pitch - gap;
    // Center the square grid inside a possibly non-square box.
    final ox = (size.width - pitch * side) / 2;
    final oy = (size.height - pitch * side) / 2;

    for (var i = 0; i < total; i++) {
      final row = i ~/ side;
      final col = i % side;
      final rect = Rect.fromLTWH(
        ox + col * pitch + gap / 2,
        oy + row * pitch + gap / 2,
        cell,
        cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cellRadius)),
        Paint()..color = cellColors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant WafflePainter old) =>
      old.emptyColor != emptyColor ||
      old.cellGapFraction != cellGapFraction ||
      old.cellRadius != cellRadius ||
      old.side != side ||
      !MacroPiePainter._wedgesEqual(old.categories, categories);
}
