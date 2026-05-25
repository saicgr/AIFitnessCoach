import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/pillar_history_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/trends/metric_picker_sheet.dart';
import 'widgets/ask_coach_button.dart';

/// Source contract for a full-screen chart: given a [range] in days, return
/// the points to plot. The host owns the data; this screen owns chrome.
typedef ChartDataLoader = Future<List<PillarDayScore>> Function(int days);

/// Full-screen, interactive single-metric chart used by every "expand" icon
/// inside [PillarDetailScreen]. Features:
///   * time-range chips (7D / 30D / 90D / 1Y / All)
///   * pinch-to-zoom + drag-scrub via [fl_chart]'s built-in touch handling
///   * "Compare with…" button → existing [showMetricPickerSheet]
///   * Ask-Coach button (top-right) + close (top-left)
class FullScreenChartScreen extends StatefulWidget {
  /// Stable id (also the route `:id` segment) — used as the contextLabel
  /// prefix when the user opens the Ask Coach button.
  final String chartId;

  /// Display title — e.g. "Train completion · last 30 days".
  final String title;

  /// Pillar this chart belongs to (drives the accent + Ask-Coach context).
  final PillarKind pillarKind;

  /// Async loader for the chart's data. Re-invoked when the user picks a
  /// new time range chip.
  final ChartDataLoader loadData;

  const FullScreenChartScreen({
    super.key,
    required this.chartId,
    required this.title,
    required this.pillarKind,
    required this.loadData,
  });

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  static const List<({String label, int days})> _ranges = [
    (label: '7D', days: 7),
    (label: '30D', days: 30),
    (label: '90D', days: 90),
    (label: '1Y', days: 365),
    (label: 'All', days: 365),
  ];

  int _selectedRangeIndex = 1; // default 30D
  late Future<List<PillarDayScore>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadData(_ranges[_selectedRangeIndex].days);
  }

  void _pickRange(int idx) {
    setState(() {
      _selectedRangeIndex = idx;
      _future = widget.loadData(_ranges[idx].days);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  AskCoachButton(
                    contextLabel:
                        '${widget.pillarKind.label} · ${widget.title}',
                    statSnapshot: {
                      'chartId': widget.chartId,
                      'rangeDays': _ranges[_selectedRangeIndex].days,
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _RangeChipsRow(
              ranges: _ranges,
              selectedIndex: _selectedRangeIndex,
              onPicked: _pickRange,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FutureBuilder<List<PillarDayScore>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _emptyText(AppLocalizations.of(context)!.fullScreenChartCouldNotLoad, isDark);
                    }
                    final points = snap.data ?? const <PillarDayScore>[];
                    if (points.length < 2) {
                      return _emptyText(
                        AppLocalizations.of(context)!.fullScreenChartNotEnoughHistory,
                        isDark,
                      );
                    }
                    return _ChartBody(
                      points: points,
                      pillarKind: widget.pillarKind,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // The existing metric picker is wired to TrendMetric;
                        // pillar overlays will be added when TrendMetric is
                        // extended (other agent). For now, the button opens
                        // the picker as a starting affordance.
                        showMetricPickerSheet(
                          context: context,
                          exclude: const {},
                          onPicked: (_) {
                            Navigator.of(context).maybePop();
                            // TODO(pillar): wire chosen metric as an overlay
                            // once TrendMetric.pillar<Kind> entries exist.
                          },
                        );
                      },
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.fullScreenChartCompareWith),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyText(String msg, bool isDark) {
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      ),
    );
  }
}

class _RangeChipsRow extends StatelessWidget {
  final List<({String label, int days})> ranges;
  final int selectedIndex;
  final ValueChanged<int> onPicked;
  final bool isDark;

  const _RangeChipsRow({
    required this.ranges,
    required this.selectedIndex,
    required this.onPicked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ranges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onPicked(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent : border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Text(
                ranges[i].label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  final List<PillarDayScore> points;
  final PillarKind pillarKind;
  final bool isDark;

  const _ChartBody({
    required this.points,
    required this.pillarKind,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final gridColor = (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
        .withValues(alpha: 0.5);

    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    final minDate = sorted.first.date;
    final spanMs = math.max(
      1,
      sorted.last.date.difference(minDate).inMilliseconds,
    );
    for (final p in sorted) {
      final x = p.date.difference(minDate).inMilliseconds / spanMs;
      spots.add(FlSpot(x, p.completion * 100));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
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
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('${v.toInt()}',
                      style:
                          TextStyle(fontSize: 10, color: textMuted)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 0.5,
              getTitlesWidget: (v, meta) {
                final ms = (minDate.millisecondsSinceEpoch + v * spanMs).round();
                final d = DateTime.fromMillisecondsSinceEpoch(ms);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MMM d').format(d),
                      style:
                          TextStyle(fontSize: 10, color: textMuted)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            color: accent,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(
                  color: textMuted.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                    radius: 4,
                    color: accent,
                    strokeWidth: 2,
                    strokeColor:
                        isDark ? AppColors.background : AppColorsLight.background,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipColor: (_) =>
                isDark ? AppColors.elevated : AppColorsLight.elevated,
            tooltipBorder: BorderSide(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
            getTooltipItems: (spots) => spots.map((s) {
              final ms =
                  (minDate.millisecondsSinceEpoch + s.x * spanMs).round();
              final d = DateTime.fromMillisecondsSinceEpoch(ms);
              final dateStr = DateFormat('MMM d, yyyy').format(d);
              return LineTooltipItem(
                '${s.y.toStringAsFixed(0)}%\n',
                TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: dateStr,
                    style: TextStyle(color: textMuted, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
