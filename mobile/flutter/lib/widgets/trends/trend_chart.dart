import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_colors.dart';
import 'trend_correlation.dart';

/// =========================================================================
/// TrendChart — graph-first multi-metric trend chart (rebuilt G8)
/// =========================================================================
///
/// One fl_chart-based widget for the Custom Trends screen. Features:
///  * 1 PRIMARY series on the real (left) value axis — EWMA-smoothed.
///  * UP TO 4 OVERLAY series. With overlays present every series (primary
///    included) is min/max-normalised to a shared 0–100 index so one chart
///    stays readable — research: >3 raw-scale lines is unreadable; an indexed
///    chart preserves shape, which is what a trend reader actually wants.
///  * Series distinguished by colour AND line style (primary solid, overlays
///    dashed) AND a direct end-of-line label — never colour alone.
///  * Toggleable EVENT overlays (workouts / fasting / rest days) drawn as
///    faint vertical bands BEHIND the metric lines.
///  * Pinch-to-zoom + pan on the X (time) axis.
///  * Drag-scrub crosshair tooltip showing the real value + date.
///
/// The chart is purely presentational — the host screen owns metric/range
/// selection, the legend, stats and the AI insight.

/// A horizontal health-zone band (e.g. "Healthy" / "Goal").
///
/// Kept for the single-series host screens (measurements, goals, volume,
/// nutrition patterns) that draw a goal/zone reference line.
class TrendZoneBand {
  final double value;
  final String label;
  final Color color;

  const TrendZoneBand({
    required this.value,
    required this.label,
    required this.color,
  });
}

/// A series of points plus presentation metadata, ready to render.
class TrendChartSeries {
  /// Stable identity (used as legend key / dedup). Defaults to [label] when
  /// the host doesn't supply one (single-series legacy callers).
  final String? _id;
  final String label;
  final String unit;
  final List<TrendPoint> points;

  /// Series colour. When null the chart falls back to the [TrendChart.accent].
  final Color? color;

  /// EWMA smoothing factor. Set 1.0 to disable smoothing (raw line only).
  final double smoothingAlpha;

  /// Optional health-zone bands drawn behind this series (primary only).
  final List<TrendZoneBand> zoneBands;

  const TrendChartSeries({
    String? id,
    required this.label,
    required this.unit,
    required this.points,
    this.color,
    this.smoothingAlpha = 0.25,
    this.zoneBands = const [],
  }) : _id = id;

  String get id => _id ?? label;
}

/// One event-overlay layer for the chart background.
class TrendEventLayer {
  final String label;
  final Color color;

  /// Calendar days (date-only) the event occurred on.
  final Set<DateTime> days;

  const TrendEventLayer({
    required this.label,
    required this.color,
    required this.days,
  });
}

/// The shared interactive trend chart.
class TrendChart extends StatefulWidget {
  /// Primary series — drives the real value axis.
  final TrendChartSeries primary;

  /// Up to 4 overlay series. When non-empty, all series render normalised.
  final List<TrendChartSeries> overlays;

  /// Event-overlay layers drawn as background bands.
  final List<TrendEventLayer> events;

  /// Fallback accent for series that don't carry their own [color]. Legacy
  /// single-series host screens pass this; the Custom Trends screen instead
  /// gives every series an explicit colour.
  final Color? accent;

  /// When true, the chart renders its own built-in legend + min/avg/max stat
  /// row (legacy single-series host screens). The Custom Trends screen owns
  /// its own chrome and passes false.
  final bool showBuiltInChrome;

  /// Chart drawing height.
  final double height;

  const TrendChart({
    super.key,
    required this.primary,
    this.overlays = const [],
    this.events = const [],
    this.accent,
    this.showBuiltInChrome = true,
    this.height = 260,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  /// Visible X window as a fraction [0,1] of the full data span.
  double _viewStart = 0.0;
  double _viewEnd = 1.0;

  // Gesture scratch state.
  double? _gestureFocalX;
  double _gestureStartViewStart = 0.0;
  double _gestureStartViewEnd = 1.0;

  static const double _minWindow = 0.08;

  double get _windowSpan => _viewEnd - _viewStart;

  bool get _normalized => widget.overlays.isNotEmpty;

  @override
  void didUpdateWidget(TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = _shapeKey(oldWidget);
    final newKey = _shapeKey(widget);
    if (oldKey != newKey) {
      _viewStart = 0.0;
      _viewEnd = 1.0;
    }
  }

  static String _shapeKey(TrendChart w) =>
      '${w.primary.id}:${w.primary.points.length}'
      '|${w.overlays.map((o) => '${o.id}:${o.points.length}').join(',')}';

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    if (widget.primary.points.isEmpty) {
      return _emptyState(colors);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showBuiltInChrome) ...[
          _builtInLegend(colors),
          const SizedBox(height: 12),
        ],
        if (_normalized)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Overlay metrics shown as a 0–100 index for readability — '
              'tap a point for real values.',
              style: TextStyle(fontSize: 10.5, color: colors.textMuted),
            ),
          ),
        GestureDetector(
          onScaleStart: (d) {
            _gestureFocalX = (d.localFocalPoint.dx / context.size!.width)
                .clamp(0.0, 1.0);
            _gestureStartViewStart = _viewStart;
            _gestureStartViewEnd = _viewEnd;
          },
          onScaleUpdate: (d) {
            setState(() {
              final startSpan =
                  _gestureStartViewEnd - _gestureStartViewStart;
              final anchor = _gestureStartViewStart +
                  (_gestureFocalX ?? 0.5) * startSpan;
              var newSpan =
                  (startSpan / d.scale).clamp(_minWindow, 1.0).toDouble();
              var newStart = anchor - (_gestureFocalX ?? 0.5) * newSpan;
              final panFrac = -d.focalPointDelta.dx /
                  (context.size?.width ?? 1) *
                  newSpan;
              newStart += panFrac;
              newStart = newStart.clamp(0.0, 1.0 - newSpan).toDouble();
              _viewStart = newStart;
              _viewEnd = newStart + newSpan;
            });
          },
          child: SizedBox(
            height: widget.height,
            child: _buildChart(colors),
          ),
        ),
        if (_windowSpan < 0.999) ...[
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _viewStart = 0.0;
                _viewEnd = 1.0;
              }),
              child: Text('Pinch to zoom · tap to reset',
                  style:
                      TextStyle(fontSize: 11, color: colors.textMuted)),
            ),
          ),
        ],
        if (widget.showBuiltInChrome) ...[
          const SizedBox(height: 14),
          _builtInStatRow(colors),
        ],
      ],
    );
  }

  /// Resolves the effective colour for a series — its own, else the accent,
  /// else the theme accent.
  Color _colorOf(TrendChartSeries s, ThemeColors colors) =>
      s.color ?? widget.accent ?? colors.accent;

  // ── Built-in chrome (legacy single-series host screens) ───────────────

  Widget _builtInLegend(ThemeColors colors) {
    final all = <TrendChartSeries>[widget.primary, ...widget.overlays];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < all.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: _colorOf(all[i], colors),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(all[i].label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
            ],
          ),
      ],
    );
  }

  Widget _builtInStatRow(ThemeColors colors) {
    final values = widget.primary.points.map((p) => p.value).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final avgV = values.reduce((a, b) => a + b) / values.length;
    final unit = widget.primary.unit;

    Widget cell(String label, double v, Color c) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: colors.textMuted)),
              const SizedBox(height: 3),
              Text('${_fmt(v)} $unit',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c)),
            ],
          ),
        );

    Widget divider() =>
        Container(width: 1, height: 28, color: colors.cardBorder);

    return Row(
      children: [
        cell('MIN', minV, colors.success),
        divider(),
        cell('AVG', avgV, _colorOf(widget.primary, colors)),
        divider(),
        cell('MAX', maxV, colors.error),
      ],
    );
  }

  // ── Chart ─────────────────────────────────────────────────────────────

  /// Resolves the list of (series, renderPoints) pairs. When normalised, every
  /// series' points are mapped onto a shared 0–100 index.
  List<({TrendChartSeries series, List<TrendPoint> render})> _resolveSeries() {
    final all = <TrendChartSeries>[widget.primary, ...widget.overlays];
    return [
      for (final s in all)
        (
          series: s,
          render: _normalized ? normalizeToIndex(s.points) : s.points,
        ),
    ];
  }

  Widget _buildChart(ThemeColors colors) {
    final resolved = _resolveSeries();

    // Full time span across ALL series.
    final allDates = <DateTime>[
      for (final r in resolved) ...r.series.points.map((p) => p.date),
    ];
    final minDate = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final spanMs =
        math.max(1, maxDate.difference(minDate).inMilliseconds);

    double xOf(DateTime d) =>
        d.difference(minDate).inMilliseconds / spanMs;

    final minX = _viewStart;
    final maxX = _viewEnd;

    // Y bounds: the union of every rendered series.
    final allYs = <double>[
      for (final r in resolved) ...r.render.map((p) => p.value),
    ];
    final yMin = allYs.reduce(math.min);
    final yMax = allYs.reduce(math.max);
    final pad = math.max((yMax - yMin) * 0.12, _epsilon(yMax));
    final yLow = _normalized ? -4.0 : yMin - pad;
    final yHigh = _normalized ? 104.0 : yMax + pad;

    // ── Line bars ────────────────────────────────────────────────────────
    final bars = <LineChartBarData>[];
    // barIndex → series, so the tooltip can identify each spot.
    final barOwner = <int>[];

    for (var i = 0; i < resolved.length; i++) {
      final s = resolved[i].series;
      final render = resolved[i].render;
      final isPrimary = i == 0;
      final col = _colorOf(s, colors);

      // Raw scatter dots (primary only, subtle) — keeps the real cadence
      // visible without cluttering when overlays are present.
      if (isPrimary && !_normalized) {
        bars.add(LineChartBarData(
          spots: [for (final p in render) FlSpot(xOf(p.date), p.value)],
          isCurved: false,
          barWidth: 0,
          color: col.withValues(alpha: 0.0),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 2.4,
              color: col.withValues(alpha: 0.4),
              strokeWidth: 0,
            ),
          ),
        ));
        barOwner.add(i);
      }

      // A series with no points contributes no bar at all (the host screen
      // surfaces an honest per-metric note instead — see FIX 2).
      if (render.isEmpty) continue;

      final smooth = s.smoothingAlpha >= 1.0
          ? render
          : ewmaPoints(render, alpha: s.smoothingAlpha);
      // A single-point series can't draw a line — fl_chart renders nothing for
      // a 1-spot curved bar. Force a visible dot so the lone logged value is
      // never silently dropped. A ≥2-point series always draws its line.
      final isSinglePoint = smooth.length == 1;
      bars.add(LineChartBarData(
        spots: [for (final p in smooth) FlSpot(xOf(p.date), p.value)],
        isCurved: true,
        curveSmoothness: 0.28,
        barWidth: isPrimary ? 3 : 2.4,
        color: col,
        // Primary solid, overlays dashed — distinguishable beyond colour.
        dashArray: isPrimary ? null : const [6, 4],
        dotData: FlDotData(
          show: isSinglePoint,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: isPrimary ? 4 : 3.4,
            color: col,
            strokeWidth: 0,
          ),
        ),
        belowBarData: isPrimary
            ? BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    col.withValues(alpha: 0.20),
                    col.withValues(alpha: 0.0),
                  ],
                ),
              )
            : BarAreaData(show: false),
      ));
      barOwner.add(i);
    }

    // ── Health-zone reference lines (primary only, raw scale) ────────────
    final zoneLines = <HorizontalLine>[
      if (!_normalized)
        for (final band in widget.primary.zoneBands)
          if (band.value >= yLow && band.value <= yHigh)
            HorizontalLine(
              y: band.value,
              color: band.color.withValues(alpha: 0.45),
              strokeWidth: 1,
              dashArray: const [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 9,
                  color: band.color.withValues(alpha: 0.8),
                ),
                labelResolver: (_) => band.label,
              ),
            ),
    ];

    // ── Event-overlay background bands ───────────────────────────────────
    final eventBands = <VerticalRangeAnnotation>[];
    for (final layer in widget.events) {
      for (final day in layer.days) {
        if (day.isBefore(minDate) || day.isAfter(maxDate)) continue;
        // A day occupies a thin slice of the X span.
        final dayStart = xOf(DateTime(day.year, day.month, day.day));
        final dayWidth =
            (const Duration(days: 1).inMilliseconds / spanMs);
        eventBands.add(VerticalRangeAnnotation(
          x1: dayStart,
          x2: (dayStart + dayWidth).clamp(0.0, 1.0),
          color: layer.color.withValues(alpha: 0.14),
        ));
      }
    }

    final gridColor = colors.cardBorder.withValues(alpha: 0.5);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: yLow,
        maxY: yHigh,
        lineBarsData: bars,
        clipData: const FlClipData.all(),
        rangeAnnotations:
            RangeAnnotations(verticalRangeAnnotations: eventBands),
        extraLinesData: ExtraLinesData(horizontalLines: zoneLines),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((yHigh - yLow) / 4)
              .clamp(_epsilon(yHigh), double.infinity),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _normalized ? value.toStringAsFixed(0) : _fmt(value),
                    style:
                        TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 0.5,
              getTitlesWidget: (value, meta) {
                final ms = (minDate.millisecondsSinceEpoch +
                        value * spanMs)
                    .round();
                final d = DateTime.fromMillisecondsSinceEpoch(ms);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MMM d').format(d),
                      style: TextStyle(
                          fontSize: 9, color: colors.textMuted)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(
                  color: colors.textMuted.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, _, bar, __) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: bar.color ?? _colorOf(widget.primary, colors),
                    strokeWidth: 2,
                    strokeColor: colors.background,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipColor: (_) => colors.elevated,
            tooltipBorder: BorderSide(color: colors.cardBorder),
            getTooltipItems: (spots) {
              return spots.map((s) {
                final ms = (minDate.millisecondsSinceEpoch +
                        s.x * spanMs)
                    .round();
                final d = DateTime.fromMillisecondsSinceEpoch(ms);
                final dateStr = DateFormat('MMM d, yyyy').format(d);
                final ownerIdx = (s.barIndex >= 0 &&
                        s.barIndex < barOwner.length)
                    ? barOwner[s.barIndex]
                    : 0;
                final owned = resolved[ownerIdx];
                // Recover the REAL value for the touched day (the bar may be
                // smoothed/normalised — the tooltip must show truth).
                final real = _realValueNear(owned.series, d);
                return LineTooltipItem(
                  '${owned.series.label}\n',
                  TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${_fmt(real)} ${owned.series.unit}\n',
                      style: TextStyle(
                        color: _colorOf(owned.series, colors),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: dateStr,
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Finds the real (un-normalised, un-smoothed) value closest to [day].
  static double _realValueNear(TrendChartSeries s, DateTime day) {
    if (s.points.isEmpty) return 0;
    TrendPoint best = s.points.first;
    var bestDiff = (best.date.difference(day)).inMinutes.abs();
    for (final p in s.points) {
      final diff = p.date.difference(day).inMinutes.abs();
      if (diff < bestDiff) {
        best = p;
        bestDiff = diff;
      }
    }
    return best.value;
  }

  // ── Empty state ───────────────────────────────────────────────────────

  Widget _emptyState(ThemeColors colors) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: colors.textMuted),
            const SizedBox(height: 8),
            Text('No data in this range',
                style: TextStyle(color: colors.textMuted)),
            const SizedBox(height: 4),
            Text('Try a wider time range or log a new entry',
                style: TextStyle(
                    color: colors.textMuted.withValues(alpha: 0.6),
                    fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static double _epsilon(double scale) =>
      math.max(scale.abs() * 0.001, 0.01);

  static String _fmt(double v) {
    if (v.abs() >= 1000) {
      return NumberFormat.compact().format(v);
    }
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
