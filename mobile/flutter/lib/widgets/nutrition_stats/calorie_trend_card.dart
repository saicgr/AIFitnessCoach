import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../l10n/generated/app_localizations.dart';

/// Calorie Trend card — a 7-day daily-calorie bar chart with an average line.
///
/// Extracted verbatim from the /stats Nutrition tab (the original private
/// `_CalorieTrendCard` + `_CalorieBarChart`) so it can be reused on the
/// Nutrition tab without any visual change. Constructor signature unchanged.
class CalorieTrendCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const CalorieTrendCard({
    super.key,
    required this.weeklyNutrition,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklyNutrition.when(
        // Layout-matched skeleton: title line + 180pt chart placeholder.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 120, height: 16, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 180, radius: 12),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 80,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionTabPartCouldNotLoadCalorie,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null || data.dailySummaries.isEmpty) {
            return SizedBox(
              height: 80,
              child: Center(
                child: Text(AppLocalizations.of(context).nutritionTabPartNoNutritionDataThis,
                    style: TextStyle(color: textMuted)),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).nutritionTabPartCalorieTrend,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'avg ${data.averageDailyCalories.round()} cal',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _CalorieBarChart(
                  entries: data.dailySummaries,
                  avgCalories: data.averageDailyCalories,
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalorieBarChart extends StatefulWidget {
  final List<DailyNutritionEntry> entries;
  final double avgCalories;
  final bool isDark;

  const _CalorieBarChart({
    required this.entries,
    required this.avgCalories,
    required this.isDark,
  });

  @override
  State<_CalorieBarChart> createState() => _CalorieBarChartState();
}

class _CalorieBarChartState extends State<_CalorieBarChart> {
  // Memoized fl_chart BarChartData. Building all 7 bar groups + tooltip
  // closures on every unrelated rebuild of the host (a ConsumerWidget that
  // rebuilds on ANY watched provider change) is wasteful. We rebuild the
  // BarChartData only when the entries/avg/theme change.
  String? _memoKey;
  BarChartData? _memoData;

  /// Identifies the inputs that affect the chart's geometry. Daily entries
  /// are immutable, so day label + calories per day fully describe them.
  String _buildMemoKey() {
    final buf = StringBuffer('${widget.isDark}|${widget.avgCalories}|');
    for (final e in widget.entries) {
      buf.write('${e.dayLabel}:${e.calories}:'
          '${e.proteinG}:${e.carbsG}:${e.fatG};');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final memoKey = _buildMemoKey();
    if (_memoKey == memoKey && _memoData != null) {
      return BarChart(_memoData!);
    }

    final entries = widget.entries;
    final avgCalories = widget.avgCalories;
    final isDark = widget.isDark;

    final maxCal = entries
        .fold<double>(avgCalories, (m, e) => e.calories > m ? e.calories.toDouble() : m);
    final chartMax = maxCal > 0 ? (maxCal * 1.2).ceilToDouble() : 2000.0;

    final chartData = BarChartData(
        maxY: chartMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x];
              return BarTooltipItem(
                '${entry.calories} cal\nP: ${entry.proteinG.round()}g  C: ${entry.carbsG.round()}g  F: ${entry.fatG.round()}g',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[idx].dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox();
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: avgCalories,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                labelResolver: (_) => 'avg',
              ),
            ),
          ],
        ),
        barGroups: List.generate(entries.length, (i) {
          final cal = entries[i].calories.toDouble();
          final barColor = cal > 0
              ? (isDark ? const Color(0xFF4FC3F7) : const Color(0xFF1E88E5))
              : Colors.transparent;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cal > 0 ? cal : 0,
                color: barColor,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
    );

    // Cache the freshly-built chart data for the next rebuild.
    _memoKey = memoKey;
    _memoData = chartData;
    return BarChart(chartData);
  }
}
