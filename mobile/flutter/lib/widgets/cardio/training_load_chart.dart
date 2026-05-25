import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/training_load_repository.dart';

import '../../l10n/generated/app_localizations.dart';
/// =========================================================================
/// TrainingLoadChart — combined acute / chronic / ACWR chart for cardio
/// =========================================================================
///
/// Three series rendered together so the user reads them in one glance:
///
///   * Chronic load (28-day rolling sum, accent) — filled area, primary
///     scale = TRIMP. Slow-moving baseline.
///   * Acute load (7-day rolling sum, lighter accent) — filled area on top
///     of chronic. Wherever this rises above chronic, ACWR climbs.
///   * ACWR ratio (line, white) — secondary y-axis (0..2.5). Crosses the
///     coloured ACWR-zone background bands:
///        gray   < 0.8  (detraining)
///        green  0.8–1.3 (balanced sweet spot)
///        yellow 1.3–1.5 (loading)
///        red    > 1.5   (overreaching)
///
/// The widget owns its own provider read so callers can drop it anywhere
/// (Custom Trends grid tile, pillar detail, the dedicated screen).
///
/// Reuse note: `trend_chart.dart` is a single-axis index-normalised chart;
/// our needs are dual-axis with zone backgrounds, so we use fl_chart
/// directly. This widget is the abstraction for those use cases.
class TrainingLoadChart extends ConsumerWidget {
  /// Window length in days (matches the repository request).
  final int days;

  /// Fixed height — caller sizes the container.
  final double height;

  const TrainingLoadChart({
    super.key,
    this.days = 120,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(trainingLoadHistoryProvider);
    return SizedBox(
      height: height,
      child: asyncHistory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load training load: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        data: (points) => _ChartBody(points: points, days: days),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  final List<TrainingLoadDayPoint> points;
  final int days;
  const _ChartBody({required this.points, required this.days});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).trainingLoadChartNoCardioActivityYet,
          textAlign: TextAlign.center,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final acuteColor = accent.withValues(alpha: 0.55);
    final chronicColor = accent.withValues(alpha: 0.20);

    // Y-axis primary (TRIMP load). Headroom = 10% over the max acute/chronic.
    final loadMax = points
        .map((p) => p.acuteLoad > p.chronicLoad ? p.acuteLoad : p.chronicLoad)
        .fold<double>(0.0, (a, b) => b > a ? b : a);
    final primaryMax = (loadMax * 1.15).clamp(50.0, double.infinity);

    // Secondary axis (ACWR) is rendered indirectly: we re-scale ACWR values
    // into the primary axis for plotting, but display the secondary scale
    // (0–2.5) in the right gutter. ACWR_PLOT_MAX = 2.5 → primary_max.
    const acwrAxisMax = 2.5;
    double acwrToPrimary(double r) => (r / acwrAxisMax) * primaryMax;

    final chronicSpots = <FlSpot>[];
    final acuteSpots = <FlSpot>[];
    final acwrSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = i.toDouble();
      chronicSpots.add(FlSpot(x, p.chronicLoad));
      acuteSpots.add(FlSpot(x, p.acuteLoad));
      if (p.acwr != null) {
        // Clamp the plotted ACWR to the visible axis ceiling so a wild
        // spike doesn't disappear above the frame.
        final clamped = p.acwr!.clamp(0.0, acwrAxisMax);
        acwrSpots.add(FlSpot(x, acwrToPrimary(clamped)));
      }
    }

    // ACWR zone backgrounds — drawn as horizontal bands behind the lines.
    final zoneBands = <HorizontalRangeAnnotation>[
      HorizontalRangeAnnotation(
        y1: 0,
        y2: acwrToPrimary(0.8),
        color: Colors.grey.withValues(alpha: 0.10),
      ),
      HorizontalRangeAnnotation(
        y1: acwrToPrimary(0.8),
        y2: acwrToPrimary(1.3),
        color: Colors.green.withValues(alpha: 0.12),
      ),
      HorizontalRangeAnnotation(
        y1: acwrToPrimary(1.3),
        y2: acwrToPrimary(1.5),
        color: Colors.amber.withValues(alpha: 0.14),
      ),
      HorizontalRangeAnnotation(
        y1: acwrToPrimary(1.5),
        y2: primaryMax,
        color: Colors.redAccent.withValues(alpha: 0.12),
      ),
    ];

    final showCalibrationOverlay = points.length < 14 ||
        points.where((p) => p.dailyTrimp > 0).length < 5;

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: 0,
            maxY: primaryMax,
            extraLinesData: const ExtraLinesData(
              horizontalLines: [],
            ),
            betweenBarsData: const [],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.black.withValues(alpha: 0.85),
                getTooltipItems: (spots) {
                  if (spots.isEmpty) return [];
                  final idx = spots.first.x.toInt().clamp(0, points.length - 1);
                  final p = points[idx];
                  final dateStr = DateFormat('MMM d').format(p.date);
                  final acwrStr =
                      p.acwr != null ? p.acwr!.toStringAsFixed(2) : '—';
                  return [
                    LineTooltipItem(
                      '$dateStr\n'
                      'TRIMP ${p.dailyTrimp.toStringAsFixed(0)}\n'
                      'Acute ${p.acuteLoad.toStringAsFixed(0)}\n'
                      'Chronic ${p.chronicLoad.toStringAsFixed(0)}\n'
                      'ACWR $acwrStr',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Hide other tooltips — we already collapsed the data.
                    for (var _ in spots.skip(1))
                      const LineTooltipItem('', TextStyle(fontSize: 0)),
                  ];
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: primaryMax / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: primaryMax / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == primaryMax) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: primaryMax / 5, // 5 steps → ACWR 0.5/1/1.5/2/2.5
                  getTitlesWidget: (value, meta) {
                    final acwrValue = (value / primaryMax) * acwrAxisMax;
                    if (acwrValue < 0.05) return const SizedBox.shrink();
                    return Text(
                      acwrValue.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: (points.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final d = points[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MMM d').format(d),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: zoneBands,
            ),
            lineBarsData: [
              // Chronic (slow baseline) — filled area, drawn first.
              LineChartBarData(
                spots: chronicSpots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: accent,
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                belowBarData:
                    BarAreaData(show: true, color: chronicColor),
              ),
              // Acute (responsive load) — filled area on top.
              LineChartBarData(
                spots: acuteSpots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: accent,
                barWidth: 2.0,
                dotData: const FlDotData(show: false),
                belowBarData:
                    BarAreaData(show: true, color: acuteColor),
              ),
              // ACWR line — secondary axis (rendered on primary scale).
              LineChartBarData(
                spots: acwrSpots,
                isCurved: false,
                color: isDark ? Colors.white : Colors.black87,
                barWidth: 2.0,
                dotData: const FlDotData(show: false),
                dashArray: const [6, 4],
              ),
            ],
          ),
        ),
        if (showCalibrationOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).trainingLoadChartBuildingBaseline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
