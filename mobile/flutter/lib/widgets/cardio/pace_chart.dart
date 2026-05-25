import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';

import '../../l10n/generated/app_localizations.dart';
/// One time-stamped GPS sample carrying instantaneous pace (sec/km).
/// Defined as a top-level typedef so callers and tests can construct records
/// without re-typing the field labels.
typedef PaceSample = ({DateTime t, double secPerKm});

/// Half-open paused-segment window [start, end).
typedef PauseSegment = ({DateTime start, DateTime end});

/// Pace-over-time chart for an outdoor cardio session.
///
/// Renders a smoothed (30s rolling mean) pace line. Paused segments produce
/// visual gaps by emitting `null` Y values into the line bar — fl_chart treats
/// `FlSpot.nullSpot` as a discontinuity.
///
/// Card chrome mirrors `_Card` in `pillar_detail_screen.dart:1178` —
/// 20px border-radius, surface fill, 1px cardBorder stroke.
class PaceChart extends StatelessWidget {
  final List<PaceSample> paceSeries;
  final List<PauseSegment>? pausedSegments;

  /// 'mi' or 'km'. Y-axis label adapts accordingly.
  final String distanceUnit;

  /// Optional fullscreen handler. When null, no expand button is shown.
  /// Parent owns the navigation — this widget never pushes a screen.
  final VoidCallback? onExpand;

  const PaceChart({
    super.key,
    required this.paceSeries,
    required this.distanceUnit,
    this.pausedSegments,
    this.onExpand,
  });

  /// 30-second centered rolling mean of secPerKm. Returns one smoothed value
  /// per input sample, preserving timestamps.
  static List<PaceSample> smoothPace(List<PaceSample> raw) {
    if (raw.isEmpty) return const [];
    const window = Duration(seconds: 30);
    final out = <PaceSample>[];
    for (var i = 0; i < raw.length; i++) {
      final centerT = raw[i].t;
      double sum = 0;
      int count = 0;
      // Symmetric ±15s window. Walk a small range; series is timestamped and
      // typically sub-second cadence, so this stays O(n·k) with small k.
      for (var j = 0; j < raw.length; j++) {
        final dt = raw[j].t.difference(centerT).abs();
        if (dt <= window ~/ 2) {
          sum += raw[j].secPerKm;
          count++;
        }
      }
      out.add((t: raw[i].t, secPerKm: count == 0 ? raw[i].secPerKm : sum / count));
    }
    return out;
  }

  /// Builds the spot list with `null` Y values inside paused windows so the
  /// line breaks visually. Exposed for tests.
  static List<FlSpot> buildSpots(
    List<PaceSample> smoothed,
    List<PauseSegment>? pauses,
    String unit,
  ) {
    if (smoothed.isEmpty) return const [];
    final firstMs = smoothed.first.t.millisecondsSinceEpoch;
    final spots = <FlSpot>[];
    for (final s in smoothed) {
      final x = (s.t.millisecondsSinceEpoch - firstMs) / 1000.0; // seconds
      final inPause = pauses?.any(
            (p) => !s.t.isBefore(p.start) && s.t.isBefore(p.end),
          ) ??
          false;
      if (inPause) {
        // fl_chart's null-spot sentinel renders as a gap in the line.
        spots.add(FlSpot.nullSpot);
      } else {
        // Convert sec/km to sec per requested distance unit for the Y axis.
        final yPerUnit = unit == 'mi' ? s.secPerKm * 1.609344 : s.secPerKm;
        spots.add(FlSpot(x, yPerUnit));
      }
    }
    return spots;
  }

  /// Formats a duration in seconds as `MM:SS`. Negative or non-finite -> '—'.
  static String formatPace(double secs) {
    if (!secs.isFinite || secs < 0) return '—';
    final total = secs.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (paceSeries.isEmpty) return const SizedBox.shrink();

    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final smoothed = smoothPace(paceSeries);
    final spots = buildSpots(smoothed, pausedSegments, distanceUnit);

    // Compute Y bounds ignoring null spots.
    final ys = spots
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.y)
        .toList();
    if (ys.isEmpty) return const SizedBox.shrink();
    final yMin = ys.reduce((a, b) => a < b ? a : b);
    final yMax = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((yMax - yMin).abs() * 0.15).clamp(5.0, 60.0);

    return _ChartCard(
      title: AppLocalizations.of(context).syncedWorkoutDetailPace,
      onExpand: onExpand,
      height: 180,
      child: LineChart(
        LineChartData(
          minY: (yMin - pad).clamp(0, double.infinity),
          maxY: yMax + pad,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: accent,
              barWidth: 2.4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.18),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.cardBorder.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${formatPace(value)}/$distanceUnit',
                      style:
                          TextStyle(fontSize: 9, color: colors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared card chrome used by all three cardio chart widgets.
/// Mirrors `_Card` style at pillar_detail_screen.dart:1178 — 20px BR, surface
/// fill, 1px cardBorder, with an optional expand-to-fullscreen affordance.
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final VoidCallback? onExpand;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.child,
    required this.height,
    this.onExpand,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (onExpand != null)
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  tooltip: AppLocalizations.of(context).paceChartExpand,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onExpand,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: height, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

/// Internal helper exposed only to sibling cardio chart widgets in this
/// directory (pace/elevation/splits) so they share one card chrome.
class CardioChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final VoidCallback? onExpand;
  final Widget? trailing;

  const CardioChartCard({
    super.key,
    required this.title,
    required this.child,
    required this.height,
    this.onExpand,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => _ChartCard(
        title: title,
        height: height,
        onExpand: onExpand,
        trailing: trailing,
        child: child,
      );
}

