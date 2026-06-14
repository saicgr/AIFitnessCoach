import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/muscle_analytics.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/design_system/zealova.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Horizontal bar chart showing training frequency per muscle group
class MuscleFrequencyChart extends StatelessWidget {
  final MuscleTrainingFrequency frequency;

  const MuscleFrequencyChart({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final sortedFrequencies = frequency.sortedByFrequency;

    if (sortedFrequencies.isEmpty) {
      return ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            AppLocalizations.of(context)
                .muscleFrequencyChartNoFrequencyDataAvailable,
            textAlign: TextAlign.center,
            style: ZType.ser(14, color: tc.textSecondary),
          ),
        ),
      );
    }

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend — Wrap so it reflows to 2 rows on narrow screens
          // (iPhone SE ≤ 360 dp) instead of overflowing by 5.7 px. Status
          // tints are semantic (success/warning/error), NOT the screen accent.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: tc.success, label: AppLocalizations.of(context).muscleFrequencyChartOptimal13xWk),
              _LegendItem(color: tc.warning, label: AppLocalizations.of(context).muscleFrequencyChartLow1xWk),
              _LegendItem(color: tc.error, label: AppLocalizations.of(context).muscleFrequencyChartHigh4xWk),
            ],
          ),
          const SizedBox(height: 14),
          const ZealovaRule(),
          const SizedBox(height: 4),

          // Bar list
          ...sortedFrequencies.map((f) => _FrequencyBar(
            muscleGroup: f.formattedMuscleGroup,
            frequency: f.timesPerWeek,
            status: f.frequencyStatus ?? 'optimal',
            lastTrained: f.formattedLastTrained,
          )),
        ],
      ),
    );
  }
}

/// Maps a frequency status to its semantic theme color (NOT the screen accent).
Color _statusColor(ThemeColors tc, String status) {
  switch (status) {
    case 'undertrained':
      return tc.warning;
    case 'overtrained':
      return tc.error;
    default:
      return tc.success;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
        ),
      ],
    );
  }
}

class _FrequencyBar extends StatelessWidget {
  final String muscleGroup;
  final double frequency;
  final String status;
  final String lastTrained;

  const _FrequencyBar({
    required this.muscleGroup,
    required this.frequency,
    required this.status,
    required this.lastTrained,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final barColor = _statusColor(tc, status);

    // Max frequency for bar width calculation (cap at 5)
    final maxFreq = 5.0;
    final barWidth = (frequency / maxFreq).clamp(0.05, 1.0);

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          // Muscle name — Barlow uppercase, ellipsis on narrow layouts.
          Flexible(
            flex: 2,
            child: Text(
              muscleGroup.toUpperCase(),
              style: ZType.lbl(isNarrow ? 11 : 12,
                  color: tc.textPrimary, letterSpacing: 1.2),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 10),

          // Thin 4px hairline track with a semantic fill.
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairlineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: barWidth,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Frequency as an Anton numeral.
          Text(
            '${frequency.toStringAsFixed(1)}×',
            style: ZType.disp(14, color: tc.textPrimary),
          ),
          const SizedBox(width: 8),

          // Status glyph — outlined, semantic-tinted.
          Icon(
            status == 'optimal'
                ? Icons.check_circle_outline
                : status == 'undertrained'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
            size: 16,
            color: barColor,
          ),
        ],
      ),
    );
  }
}

/// Alternative chart view using fl_chart horizontal bar chart
class MuscleFrequencyBarChart extends StatelessWidget {
  final MuscleTrainingFrequency frequency;

  const MuscleFrequencyBarChart({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final sortedFrequencies = frequency.sortedByFrequency.take(10).toList();

    if (sortedFrequencies.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxFreq = sortedFrequencies.map((f) => f.timesPerWeek).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: sortedFrequencies.length * 40.0,
      child: RepaintBoundary(
        child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxFreq * 1.2).clamp(4, 10),
          barGroups: sortedFrequencies.asMap().entries.map((entry) {
            final f = entry.value;
            // Status tint is semantic, NOT the screen accent.
            final color = _statusColor(tc, f.frequencyStatus ?? 'optimal');

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: f.timesPerWeek,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedFrequencies.length) {
                    return Text(
                      sortedFrequencies[index].formattedMuscleGroup.toUpperCase(),
                      style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}×/WK',
                    style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.hairline, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
      ),
    );
  }
}
