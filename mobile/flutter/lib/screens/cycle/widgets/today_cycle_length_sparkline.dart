/// "Last 3 cycles" cycle-length sparkline — a compact 4-bar visualisation
/// for the Today tab.
///
/// A stripped-down companion to [CycleLengthHistoryChart] (`cycle_insights_
/// charts.dart`): no axes, no legend, no average line, no tooltips. The
/// bars are the user's last 4 observed cycle lengths (oldest → newest).
/// Tapping the card navigates to the Insights tab where the full chart
/// lives.
///
/// Edge case: when fewer than 2 cycles have been logged we render a single
/// faded "ghost" bar with a one-line caption — never a generic text block.
/// This keeps the Today tab visually consistent (every card has a chart
/// shell) even before the user has enough data.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TodayCycleLengthSparkline extends StatelessWidget {
  /// Observed cycle lengths in days, oldest-first.
  final List<int> cycleLengths;

  /// Pink cycle accent.
  final Color accent;

  /// Tap callback — wired to switch to the Insights tab.
  final VoidCallback? onTap;

  const TodayCycleLengthSparkline({
    super.key,
    required this.cycleLengths,
    required this.accent,
    this.onTap,
  });

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    final hasEnough = cycleLengths.length >= 2;
    final shown =
        hasEnough ? cycleLengths.reversed.take(4).toList().reversed.toList() : <int>[];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Last cycles',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (hasEnough)
                  Text(
                    '${shown.last}d',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: fg.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _barHeight,
              child: hasEnough
                  ? _Sparkline(values: shown, accent: accent)
                  : _GhostBar(accent: accent, fg: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// The actual fl_chart-backed bar group. Bounds the y-axis 18..yMax so the
/// bars never collapse to 0 visually on short cycles.
class _Sparkline extends StatelessWidget {
  final List<int> values;
  final Color accent;

  const _Sparkline({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Pick a y-floor a little below the smallest cycle so visual bar
    // differences are perceptible (true 0..40 makes a 28d vs 32d cycle
    // look identical).
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final yMin = (minV - 4).clamp(15, 60).toDouble();
    final yMax = (maxV + 4).clamp(20, 70).toDouble();

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < values.length; i++) {
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            // fl_chart needs the rod relative to the minY for a non-zero
            // baseline. We pass actual y; minY clamps the visible area.
            toY: values[i].toDouble(),
            fromY: yMin,
            width: 14,
            color: accent.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        minY: yMin,
        maxY: yMax,
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: bars,
      ),
    );
  }
}

/// Single faded placeholder bar shown when there's not yet enough history
/// to chart. Keeps the card shape consistent with the populated state.
class _GhostBar extends StatelessWidget {
  final Color accent;
  final Color fg;

  const _GhostBar({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 14,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Text(
            'Log 2 cycles to chart',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
