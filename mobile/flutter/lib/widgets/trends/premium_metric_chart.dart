import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/services/haptic_service.dart';
import 'trend_correlation.dart';

/// The user-selectable / descriptor-driven chart styles for the universal
/// metric detail screen and the Custom Trends primary series.
enum PremiumChartType { line, area, bar }

/// A premium, custom-painted metric chart — the "not flat" visual upgrade.
///
/// One widget renders line / area / bar / (bar + trend overlay) with:
///  * gradient fill + gradient stroke,
///  * a soft glow halo behind the line / bars (MaskFilter blur),
///  * a smooth Catmull-Rom curve (no overshoot) with an emphasised end-point dot,
///  * a dashed goal line + faint goal band, and per-point dots coloured
///    green (goal met) / orange (missed),
///  * a moving-average trend overlay on bar charts,
///  * an animated draw-on (line reveal / bars grow) on mount, and
///  * a 60fps scrub crosshair with a floating value bubble + haptics.
///
/// Coordinates are index-based (equal-width days) — the convention for daily
/// fitness charts (Google Fit / Fitbit) and what the daily-breakdown list pairs
/// with. Purely presentational; the host owns range + data.
class PremiumMetricChart extends StatefulWidget {
  /// Window data, ascending by date. Empty → caller shows its own empty state.
  final List<TrendPoint> points;
  final PremiumChartType type;
  final Color color;
  final String unit;

  /// Optional goal reference. When set, draws a dashed goal line + band and
  /// colours per-point dots / bars by [goalMet].
  final double? goal;

  /// True when higher is better (steps, sleep, protein). False when lower is
  /// better (resting HR, body fat). Drives goal-met colouring.
  final bool goalDirectionUp;

  /// EWMA factor for the line/area stroke (and the bar trend overlay).
  final double smoothingAlpha;

  /// On bar charts, overlay a glowing moving-average trend line + dots.
  final bool showTrendOverlay;

  final double height;
  final bool animate;

  const PremiumMetricChart({
    super.key,
    required this.points,
    required this.color,
    this.unit = '',
    this.type = PremiumChartType.line,
    this.goal,
    this.goalDirectionUp = true,
    this.smoothingAlpha = 0.25,
    this.showTrendOverlay = true,
    this.height = 220,
    this.animate = true,
  });

  @override
  State<PremiumMetricChart> createState() => _PremiumMetricChartState();
}

class _PremiumMetricChartState extends State<PremiumMetricChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  int? _scrubIndex;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.animate) {
      _draw.forward();
    } else {
      _draw.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PremiumMetricChart old) {
    super.didUpdateWidget(old);
    // Re-run the draw-on when the data shape or chart type changes.
    if (old.points.length != widget.points.length ||
        old.type != widget.type ||
        old.color != widget.color) {
      _scrubIndex = null;
      if (widget.animate) {
        _draw
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _onScrub(Offset local, Size size) {
    final n = widget.points.length;
    if (n == 0) return;
    const leftPad = 40.0, rightPad = 10.0;
    final plotW = size.width - leftPad - rightPad;
    final t = ((local.dx - leftPad) / plotW).clamp(0.0, 1.0);
    final idx = (t * (n - 1)).round().clamp(0, n - 1);
    if (idx != _scrubIndex) {
      HapticService.selection();
      setState(() => _scrubIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onScrub(d.localPosition, context.size ?? Size.zero),
        onHorizontalDragStart: (d) =>
            _onScrub(d.localPosition, context.size ?? Size.zero),
        onHorizontalDragUpdate: (d) =>
            _onScrub(d.localPosition, context.size ?? Size.zero),
        onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
        onTapUp: (_) => setState(() => _scrubIndex = null),
        onTapCancel: () => setState(() => _scrubIndex = null),
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _PremiumChartPainter(
              points: widget.points,
              type: widget.type,
              color: widget.color,
              unit: widget.unit,
              goal: widget.goal,
              goalDirectionUp: widget.goalDirectionUp,
              smoothingAlpha: widget.smoothingAlpha,
              showTrendOverlay: widget.showTrendOverlay,
              progress: Curves.easeOutCubic.transform(_draw.value),
              scrubIndex: _scrubIndex,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  final PremiumChartType type;
  final Color color;
  final String unit;
  final double? goal;
  final bool goalDirectionUp;
  final double smoothingAlpha;
  final bool showTrendOverlay;
  final double progress;
  final int? scrubIndex;
  final ThemeColors colors;

  static const Color _met = Color(0xFF37D67A);
  static const Color _missed = Color(0xFFFF9F43);

  _PremiumChartPainter({
    required this.points,
    required this.type,
    required this.color,
    required this.unit,
    required this.goal,
    required this.goalDirectionUp,
    required this.smoothingAlpha,
    required this.showTrendOverlay,
    required this.progress,
    required this.scrubIndex,
    required this.colors,
  });

  static const double _leftPad = 40;
  static const double _rightPad = 10;
  static const double _topPad = 10;
  static const double _bottomPad = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => p.value).toList();
    final isBar = type == PremiumChartType.bar;

    // ── Y scale (include goal; bars baseline at 0) ───────────────────────
    double yMin = values.reduce(math.min);
    double yMax = values.reduce(math.max);
    if (goal != null) {
      yMin = math.min(yMin, goal!);
      yMax = math.max(yMax, goal!);
    }
    if (isBar) yMin = math.min(0, yMin);
    if (yMax == yMin) yMax = yMin + 1;
    final pad = (yMax - yMin) * 0.14;
    yMin = isBar ? yMin : yMin - pad;
    yMax = yMax + pad;

    final plot = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );

    double xOf(int i) => points.length == 1
        ? plot.center.dx
        : plot.left + plot.width * (i / (points.length - 1));
    double yOf(double v) =>
        plot.bottom - plot.height * ((v - yMin) / (yMax - yMin));

    _paintGrid(canvas, plot, yMin, yMax);
    if (goal != null) _paintGoal(canvas, plot, yOf(goal!));

    if (isBar) {
      _paintBars(canvas, plot, xOf, yOf, yMin);
      if (showTrendOverlay && points.length >= 2) {
        _paintTrendOverlay(canvas, plot, xOf, yOf);
      }
    } else {
      _paintLineArea(canvas, plot, xOf, yOf, yMin);
    }

    _paintXLabels(canvas, plot, xOf);
    if (scrubIndex != null) _paintScrub(canvas, plot, xOf, yOf, size);
  }

  // ── Grid + Y labels ────────────────────────────────────────────────────
  void _paintGrid(Canvas canvas, Rect plot, double yMin, double yMax) {
    final grid = Paint()
      ..color = colors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const rows = 4;
    for (var r = 0; r <= rows; r++) {
      final t = r / rows;
      final y = plot.bottom - plot.height * t;
      if (r != 0 && r != rows) {
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      }
      final v = yMin + (yMax - yMin) * t;
      _text(
        canvas,
        _fmt(v),
        Offset(plot.left - 6, y),
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddle: true,
        color: colors.textMuted,
        size: 9.5,
      );
    }
  }

  void _paintGoal(Canvas canvas, Rect plot, double gy) {
    // Faint band toward the "good" side of the goal.
    final bandTop = goalDirectionUp ? plot.top : gy;
    final bandBottom = goalDirectionUp ? gy : plot.bottom;
    if (bandBottom > bandTop) {
      canvas.drawRect(
        Rect.fromLTRB(plot.left, bandTop, plot.right, bandBottom),
        Paint()..color = _met.withValues(alpha: 0.06),
      );
    }
    // Dashed goal line.
    final paint = Paint()
      ..color = _met.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    const dash = 5.0, gap = 5.0;
    double x = plot.left;
    while (x < plot.right) {
      canvas.drawLine(Offset(x, gy), Offset(math.min(x + dash, plot.right), gy),
          paint);
      x += dash + gap;
    }
  }

  // ── Bars ───────────────────────────────────────────────────────────────
  void _paintBars(
      Canvas canvas, Rect plot, double Function(int) xOf,
      double Function(double) yOf, double yMin) {
    final n = points.length;
    final slot = plot.width / n;
    final barW = math.min(28.0, slot * 0.56);
    final baseY = yOf(yMin < 0 ? 0 : yMin);
    for (var i = 0; i < n; i++) {
      final cx = n == 1 ? plot.center.dx : plot.left + slot * (i + 0.5);
      final v = points[i].value;
      final fullTop = yOf(v);
      // animated grow
      final top = baseY - (baseY - fullTop) * progress;
      final met = goal == null ? null : _isMet(v);
      final c = met == null
          ? color
          : (met ? _met : _missed);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(cx - barW / 2, top, cx + barW / 2, baseY),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      );
      // glow
      canvas.drawRRect(
        rect,
        Paint()
          ..color = c.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // gradient fill
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, top),
            Offset(cx, baseY),
            [Color.lerp(c, Colors.white, 0.22)!, c],
          ),
      );
    }
  }

  void _paintTrendOverlay(Canvas canvas, Rect plot,
      double Function(int) xOf, double Function(double) yOf) {
    final smooth = ewmaPoints(points, alpha: smoothingAlpha);
    final pts = [
      for (var i = 0; i < smooth.length; i++) Offset(xOf(i), yOf(smooth[i].value))
    ];
    final path = _smoothPath(pts);
    _drawProgressPath(canvas, plot, path, const Color(0xFFFFB43A),
        width: 2.6, glow: true);
    // dots
    final dotPaint = Paint()..color = const Color(0xFFFFB43A);
    final ring = Paint()
      ..color = colors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final shown = (pts.length * progress).ceil();
    for (var i = 0; i < shown && i < pts.length; i++) {
      canvas.drawCircle(pts[i], 3.0, dotPaint);
      canvas.drawCircle(pts[i], 3.0, ring);
    }
  }

  // ── Line / Area ──────────────────────────────────────────────────────
  void _paintLineArea(Canvas canvas, Rect plot, double Function(int) xOf,
      double Function(double) yOf, double yMin) {
    final smooth = smoothingAlpha >= 1.0
        ? points
        : ewmaPoints(points, alpha: smoothingAlpha);
    final pts = [
      for (var i = 0; i < smooth.length; i++) Offset(xOf(i), yOf(smooth[i].value))
    ];

    if (pts.length == 1) {
      canvas.drawCircle(pts.first, 5, Paint()..color = color);
      return;
    }

    final linePath = _smoothPath(pts);

    // Area fill (animated via clip).
    if (type == PremiumChartType.area) {
      final fill = Path.from(linePath)
        ..lineTo(pts.last.dx, plot.bottom)
        ..lineTo(pts.first.dx, plot.bottom)
        ..close();
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(
          plot.left, plot.top, plot.left + plot.width * progress, plot.bottom));
      canvas.drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, plot.top),
            Offset(0, plot.bottom),
            [
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.06),
              color.withValues(alpha: 0.0),
            ],
            [0.0, 0.6, 1.0],
          ),
      );
      canvas.restore();
    }

    _drawProgressPath(canvas, plot, linePath, color, width: 3.4, glow: true);

    // raw dots + goal-met colouring (faint) — only when not too dense.
    if (points.length <= 40) {
      final rawPts = [
        for (var i = 0; i < points.length; i++)
          Offset(xOf(i), yOf(points[i].value))
      ];
      final shown = (rawPts.length * progress).ceil();
      for (var i = 0; i < shown && i < rawPts.length; i++) {
        final met = goal == null ? null : _isMet(points[i].value);
        final dc = met == null ? color : (met ? _met : _missed);
        canvas.drawCircle(rawPts[i], 2.6, Paint()..color = dc.withValues(alpha: 0.55));
      }
    }

    // Emphasised end-point dot.
    if (progress > 0.98) {
      final end = pts.last;
      canvas.drawCircle(end, 8, Paint()..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(end, 5, Paint()..color = color);
      canvas.drawCircle(
          end,
          5,
          Paint()
            ..color = colors.background
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  /// Draws [path] revealed left→right by [progress], with an optional glow.
  void _drawProgressPath(Canvas canvas, Rect plot, Path path, Color c,
      {required double width, bool glow = false}) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
        0, 0, plot.left + plot.width * progress + 0.5, plot.bottom + 40));
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 2
          ..strokeCap = StrokeCap.round
          ..color = c.withValues(alpha: 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          Offset(plot.left, 0),
          Offset(plot.right, 0),
          [Color.lerp(c, Colors.white, 0.28)!, c],
        ),
    );
    canvas.restore();
  }

  // ── Scrub crosshair + bubble ──────────────────────────────────────────
  void _paintScrub(Canvas canvas, Rect plot, double Function(int) xOf,
      double Function(double) yOf, Size size) {
    final i = scrubIndex!.clamp(0, points.length - 1);
    final p = points[i];
    final x = xOf(i);
    final y = yOf(p.value);
    canvas.drawLine(
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = colors.textMuted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = color);
    canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()
          ..color = colors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final label = '${_fmt(p.value)}${unit.isEmpty ? '' : ' $unit'}';
    final dateStr = DateFormat('MMM d').format(p.date);
    final tp = _layout('$label\n$dateStr',
        color: colors.textPrimary, size: 11.5, weight: FontWeight.w700);
    final bw = tp.width + 18, bh = tp.height + 12;
    var bx = x - bw / 2;
    bx = bx.clamp(plot.left, plot.right - bw);
    final by = math.max(plot.top, y - bh - 12);
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(10));
    canvas.drawRRect(
        r,
        Paint()
          ..color = colors.elevated
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5));
    canvas.drawRRect(
        r,
        Paint()
          ..color = colors.cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    tp.paint(canvas, Offset(bx + 9, by + 6));
  }

  // ── X labels ─────────────────────────────────────────────────────────
  void _paintXLabels(Canvas canvas, Rect plot, double Function(int) xOf) {
    final n = points.length;
    if (n == 0) return;
    final idxs = n <= 3
        ? List.generate(n, (i) => i)
        : [0, (n - 1) ~/ 2, n - 1];
    for (final i in idxs) {
      _text(
        canvas,
        DateFormat('MMM d').format(points[i].date),
        Offset(xOf(i), plot.bottom + 8),
        align: TextAlign.center,
        anchorCenter: true,
        color: colors.textMuted,
        size: 9.5,
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  bool _isMet(double v) => goalDirectionUp ? v >= goal! : v <= goal!;

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  TextPainter _layout(String s,
      {required Color color, required double size, FontWeight? weight}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color, fontSize: size, fontWeight: weight ?? FontWeight.w500, height: 1.25)),
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(Canvas canvas, String s, Offset at,
      {TextAlign align = TextAlign.left,
      bool anchorRight = false,
      bool anchorCenter = false,
      bool anchorMiddle = false,
      required Color color,
      double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size)),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenter) dx -= tp.width / 2;
    var dy = at.dy;
    if (anchorMiddle) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  static String _fmt(double v) {
    if (v.abs() >= 1000) return NumberFormat.compact().format(v);
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(_PremiumChartPainter old) =>
      old.progress != progress ||
      old.scrubIndex != scrubIndex ||
      old.points != points ||
      old.type != type ||
      old.color != color ||
      old.goal != goal;
}
