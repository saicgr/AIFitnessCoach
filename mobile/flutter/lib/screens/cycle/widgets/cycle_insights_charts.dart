/// Interactive insight charts for the Cycle "Insights" tab.
///
/// Built on `fl_chart`. Each chart carries an "Ask coach about this"
/// affordance and a touch tooltip / scrub interaction so interactivity is
/// consistent with the headline temperature chart.
///   • [CycleLengthHistoryChart]  — bars + average line + variability band
///   • [CycleSymptomHeatmap]      — symptom frequency grid
///   • [CyclePhaseDonut]          — phase-distribution donut
///   • [CycleStatsBlock]          — avg / min / max length, regularity
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_chat.dart';
import '../cycle_visuals.dart';

import '../../../l10n/generated/app_localizations.dart';
// ===========================================================================
// Shared chart card scaffold
// ===========================================================================

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  /// Seed for "Ask coach about this".
  final String coachSeed;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    required this.coachSeed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => openCycleChat(context, coachSeed),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 11, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).cycleTemperatureChartAsk,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 320.ms);
  }
}

// ===========================================================================
// Cycle-length history — bars + average line + variability band
// ===========================================================================

class CycleLengthHistoryChart extends StatefulWidget {
  /// Observed cycle lengths in days, oldest-first.
  final List<int> cycleLengths;
  final CycleStats stats;
  final Color accent;

  const CycleLengthHistoryChart({
    super.key,
    required this.cycleLengths,
    required this.stats,
    required this.accent,
  });

  @override
  State<CycleLengthHistoryChart> createState() =>
      _CycleLengthHistoryChartState();
}

class _CycleLengthHistoryChartState extends State<CycleLengthHistoryChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    if (widget.cycleLengths.isEmpty) {
      return _ChartCard(
        title: AppLocalizations.of(context).cycleInsightsChartsCycleLengthHistory,
        icon: Icons.bar_chart_rounded,
        accent: widget.accent,
        coachSeed: cycleDatumSeed('my cycle length history'),
        child: _EmptyHint(
          fg: fg,
          text: 'Log at least two periods to see your cycle-length history.',
        ),
      );
    }

    final avg = widget.stats.avgCycleLength ??
        (widget.cycleLengths.reduce((a, b) => a + b) /
            widget.cycleLengths.length);
    final stddev = widget.stats.cycleLengthStddev ?? 0;
    final maxLen = widget.cycleLengths.reduce((a, b) => a > b ? a : b);
    final yMax = (maxLen * 1.25).ceilToDouble().clamp(10.0, double.infinity);

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < widget.cycleLengths.length; i++) {
      final v = widget.cycleLengths[i].toDouble();
      final touched = _touched == i;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: v,
            width: 16,
            color: touched
                ? widget.accent
                : widget.accent.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return _ChartCard(
      title: AppLocalizations.of(context).cycleInsightsChartsCycleLengthHistory,
      icon: Icons.bar_chart_rounded,
      accent: widget.accent,
      coachSeed: cycleDatumSeed(
        'my cycle length history — average '
        '${avg.toStringAsFixed(1)} days, variability '
        '±${stddev.toStringAsFixed(1)} days',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: RepaintBoundary(
              child: BarChart(
                BarChartData(
                  maxY: yMax,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark
                          ? const Color(0xFF222222)
                          : Colors.white,
                      getTooltipItem: (group, gi, rod, ri) =>
                          BarTooltipItem(
                        '${rod.toY.round()} days',
                        TextStyle(
                          color: fg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.spot == null) {
                        setState(() => _touched = null);
                        return;
                      }
                      setState(() =>
                          _touched = response!.spot!.touchedBarGroupIndex);
                    },
                  ),
                  // Variability band (avg ± stddev) + average line.
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: (avg - stddev).clamp(0, yMax),
                        y2: (avg + stddev).clamp(0, yMax),
                        color: widget.accent.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: avg,
                        color: CyclePhaseColors.luteal,
                        strokeWidth: 1.4,
                        dashArray: [5, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(
                            color: CyclePhaseColors.luteal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          labelResolver: (_) =>
                              'Avg ${avg.toStringAsFixed(0)}d',
                        ),
                      ),
                    ],
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: fg.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: yMax / 4,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.max || v == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            v.toInt().toString(),
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.4),
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= widget.cycleLengths.length) {
                            return const SizedBox.shrink();
                          }
                          final showEvery =
                              widget.cycleLengths.length > 8 ? 2 : 1;
                          if (i % showEvery != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '#${i + 1}',
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.4),
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: bars,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shaded band is your typical variability '
            '(±${stddev.toStringAsFixed(1)} days).',
            style: TextStyle(
              color: fg.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Symptom heatmap — frequency of each symptom
// ===========================================================================

class CycleSymptomHeatmap extends StatelessWidget {
  /// Symptom display-name → occurrence count over the window.
  final Map<String, int> symptomCounts;
  final Color accent;

  const CycleSymptomHeatmap({
    super.key,
    required this.symptomCounts,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    if (symptomCounts.isEmpty) {
      return _ChartCard(
        title: AppLocalizations.of(context).cycleInsightsChartsSymptomPatterns,
        icon: Icons.grid_view_rounded,
        accent: accent,
        coachSeed: cycleDatumSeed('my symptom patterns'),
        child: _EmptyHint(
          fg: fg,
          text: 'Log symptoms in your daily check-in to see patterns here.',
        ),
      );
    }

    final entries = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.first.value;

    return _ChartCard(
      title: AppLocalizations.of(context).cycleInsightsChartsSymptomPatterns,
      icon: Icons.grid_view_rounded,
      accent: accent,
      coachSeed: cycleDatumSeed(
        'my symptom patterns — most common: '
        '${entries.take(3).map((e) => e.key).join(', ')}',
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((e) {
          final intensity = (e.value / maxCount).clamp(0.15, 1.0);
          return _SymptomTile(
            label: e.key,
            count: e.value,
            intensity: intensity,
            accent: accent,
            fg: fg,
          );
        }).toList(),
      ),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  final String label;
  final int count;
  final double intensity;
  final Color accent;
  final Color fg;

  const _SymptomTile({
    required this.label,
    required this.count,
    required this.intensity,
    required this.accent,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label logged $count time${count == 1 ? '' : 's'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1 + intensity * 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Phase distribution donut
// ===========================================================================

class CyclePhaseDonut extends StatefulWidget {
  /// Phase → day count over the window.
  final Map<CyclePhase, int> phaseDays;
  final Color accent;

  const CyclePhaseDonut({
    super.key,
    required this.phaseDays,
    required this.accent,
  });

  @override
  State<CyclePhaseDonut> createState() => _CyclePhaseDonutState();
}

class _CyclePhaseDonutState extends State<CyclePhaseDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    final total =
        widget.phaseDays.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return _ChartCard(
        title: AppLocalizations.of(context).cycleInsightsChartsPhaseDistribution,
        icon: Icons.donut_large_rounded,
        accent: widget.accent,
        coachSeed: cycleDatumSeed('how my cycle splits across phases'),
        child: _EmptyHint(
          fg: fg,
          text: 'Track a full cycle to see how your phases break down.',
        ),
      );
    }

    final phases = CyclePhase.values
        .where((p) => (widget.phaseDays[p] ?? 0) > 0)
        .toList();

    return _ChartCard(
      title: AppLocalizations.of(context).cycleInsightsChartsPhaseDistribution,
      icon: Icons.donut_large_rounded,
      accent: widget.accent,
      coachSeed: cycleDatumSeed('how my cycle splits across phases'),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: RepaintBoundary(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        setState(() => _touched = null);
                        return;
                      }
                      setState(() => _touched = response!
                          .touchedSection!.touchedSectionIndex);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < phases.length; i++)
                      _section(phases[i], i, total),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: phases.map((p) {
                final days = widget.phaseDays[p] ?? 0;
                final pct = (days / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: CyclePhaseColors.of(p),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(CyclePhase p, int index, int total) {
    final days = widget.phaseDays[p] ?? 0;
    final touched = _touched == index;
    return PieChartSectionData(
      value: days.toDouble(),
      color: CyclePhaseColors.of(p),
      radius: touched ? 30 : 24,
      title: touched ? '${days}d' : '',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ===========================================================================
// Cycle stats block
// ===========================================================================

class CycleStatsBlock extends StatelessWidget {
  final CycleStats stats;
  final Color accent;

  const CycleStatsBlock({
    super.key,
    required this.stats,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    String d(num? v) => v == null ? '—' : v.toStringAsFixed(0);

    final tiles = <_Stat>[
      _Stat('Avg length',
          stats.avgCycleLength == null
              ? '—'
              : '${stats.avgCycleLength!.toStringAsFixed(1)}d'),
      _Stat('Shortest', '${d(stats.minCycleLength)}d'),
      _Stat('Longest', '${d(stats.maxCycleLength)}d'),
      _Stat('Variability',
          stats.cycleLengthStddev == null
              ? '—'
              : '±${stats.cycleLengthStddev!.toStringAsFixed(1)}d'),
      _Stat('Period length',
          stats.avgPeriodLength == null
              ? '—'
              : '${stats.avgPeriodLength!.toStringAsFixed(1)}d'),
      _Stat('Regularity', _regularityLabel(stats.regularity)),
    ];

    return _ChartCard(
      title: AppLocalizations.of(context).cycleInsightsChartsCycleStats,
      icon: Icons.insights_rounded,
      accent: accent,
      coachSeed: cycleDatumSeed(
        'my cycle stats — ${stats.cyclesTracked} cycles tracked, '
        '${_regularityLabel(stats.regularity).toLowerCase()}',
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tiles
            .map((t) => _StatTile(stat: t, fg: fg, accent: accent))
            .toList(),
      ),
    );
  }

  String _regularityLabel(String regularity) {
    switch (regularity) {
      case 'regular':
        return 'Regular';
      case 'irregular':
        return 'Irregular';
      default:
        return 'Building';
    }
  }
}

class _Stat {
  final String label;
  final String value;
  _Stat(this.label, this.value);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  final Color fg;
  final Color accent;

  const _StatTile({
    required this.stat,
    required this.fg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Two-up tiles that reflow — use a fractional width so they never
    // overflow on the smallest device.
    final width = (MediaQuery.of(context).size.width - 32 - 14 - 8) / 2;
    return Container(
      width: width.clamp(120.0, 220.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label.toUpperCase(),
            style: TextStyle(
              color: fg.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.value,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Shared empty hint
// ===========================================================================

class _EmptyHint extends StatelessWidget {
  final Color fg;
  final String text;
  const _EmptyHint({required this.fg, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg.withValues(alpha: 0.5),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
