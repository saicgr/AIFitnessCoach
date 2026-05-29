import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/providers/nutrition_stats_provider.dart';
import '../../../widgets/charts/cycle_phase_chart_overlay.dart';
import '../../../widgets/nutrition/health_metrics_card.dart';
import '../../../widgets/nutrition/food_mood_analytics_card.dart';
import '../../../widgets/nutrition_stats/weekly_overview_card.dart';
import '../../../widgets/nutrition_stats/calorie_trend_card.dart';
import '../../../widgets/nutrition_stats/macro_breakdown_card.dart';
import '../../../widgets/nutrition_stats/tdee_card.dart';
import '../../../widgets/nutrition_stats/adherence_card.dart';

import '../../../l10n/generated/app_localizations.dart';
part 'nutrition_tab_part_weekly_overview_card.dart';
part 'nutrition_tab_part_adherence_card.dart';


// ═══════════════════════════════════════════════════════════════════
// NUTRITION TAB - Calorie trends, macro breakdown, goals
// ═══════════════════════════════════════════════════════════════════

class NutritionTab extends ConsumerWidget {
  final String? userId;
  const NutritionTab({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (userId == null || userId!.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).nutritionSignInToView));
    }

    final weeklySummary = ref.watch(weeklySummaryProvider(userId!));
    final weeklyNutrition = ref.watch(weeklyNutritionProvider(userId!));
    final detailedTDEE = ref.watch(detailedTDEEProvider(userId!));
    final adherence = ref.watch(adherenceSummaryProvider(userId!));

    // Cycle-aware overlay context — a clean no-op when cycle tracking is off.
    final tracksCycle = ref.watch(hasHormonalTrackingProvider);
    final cyclePrediction =
        tracksCycle ? ref.watch(cyclePredictionProvider).value : null;
    final showCycleOverlay =
        tracksCycle && CyclePhaseChartOverlay.canRender(cyclePrediction);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weeklySummaryProvider(userId!));
        ref.invalidate(weeklyNutritionProvider(userId!));
        ref.invalidate(detailedTDEEProvider(userId!));
        ref.invalidate(adherenceSummaryProvider(userId!));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Weekly Overview Summary
            WeeklyOverviewCard(
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 2: Calorie Trend Chart
          CalorieTrendCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 3: Macro Breakdown
          MacroBreakdownCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 4: TDEE & Energy Balance
          TDEECard(
            detailedTDEE: detailedTDEE,
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 4b: Cycle-aware calorie & expenditure overlay (Phase G —
          // MacroFactor 1.8 / 1.18). Only rendered when the user tracks a
          // menstrual cycle; otherwise omitted entirely (no empty slot).
          if (showCycleOverlay) ...[
            _CycleCalorieOverlayCard(
              weeklyNutrition: weeklyNutrition,
              prediction: cyclePrediction!,
              cardColor: cardColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],

          // Card 5: Adherence & Consistency
          AdherenceCard(
            adherence: adherence,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 6: Health Metrics (existing)
          HealthMetricsCard(isDark: isDark),
          const SizedBox(height: 16),

          // Card 7: Food-Mood Analytics (existing)
          FoodMoodAnalyticsCard(userId: userId!, isDark: isDark),

          const SizedBox(height: 80),
        ],
      ),
    ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// Card 4b — Cycle-aware calorie & expenditure overlay
// ═══════════════════════════════════════════════════════════════════
//
// Shades menstrual / follicular / fertile / luteal phase columns behind the
// daily-calorie chart so calorie-intake swings are read against where the
// user is in her cycle (higher late-luteal hunger, etc.). Reuses the shared
// [CyclePhaseChartOverlay] so it stays visually consistent with the home
// weight-trend card and the Cycle screen's own charts. (MacroFactor 1.8,
// 1.18.)

class _CycleCalorieOverlayCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final CyclePrediction prediction;
  final Color cardColor;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  const _CycleCalorieOverlayCard({
    required this.weeklyNutrition,
    required this.prediction,
    required this.cardColor,
    required this.textPrimary,
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
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 160, height: 16, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 160, radius: 12),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionCouldNotLoadCycle,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          // Keep only days that actually carry a parseable date + intake.
          final entries = <_DatedCalorieEntry>[];
          if (data != null) {
            for (final e in data.dailySummaries) {
              final dt = DateTime.tryParse(e.date);
              if (dt != null) {
                entries.add(_DatedCalorieEntry(
                  date: DateTime(dt.year, dt.month, dt.day),
                  calories: e.calories,
                ));
              }
            }
          }
          entries.sort((a, b) => a.date.compareTo(b.date));

          final phase = prediction.currentPhase;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFF64B5F6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).nutritionCaloriesByCyclePhase,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (phase != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cyclePhaseOverlayColor(phase)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phase.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cyclePhaseOverlayColor(phase),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Shaded columns mark your cycle phase — read intake swings '
                'against where you are in your cycle.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),
              if (entries.length < 2)
                SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(AppLocalizations.of(context).nutritionLogAFewDays,
                        style: TextStyle(color: textMuted, fontSize: 13)),
                  ),
                )
              else
                SizedBox(
                  height: 170,
                  child: RepaintBoundary(
                    child: _CyclePhaseCalorieChart(
                      entries: entries,
                      prediction: prediction,
                      isDark: isDark,
                    ),
                  ),
                ),
              if (entries.length >= 2) ...[
                const SizedBox(height: 10),
                CyclePhaseChartOverlay.legend(context,
                    isDark: isDark, compact: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A dated daily-calorie point for the cycle overlay chart.
class _DatedCalorieEntry {
  final DateTime date;
  final int calories;
  const _DatedCalorieEntry({required this.date, required this.calories});
}

/// Daily-calorie bar chart with the cycle-phase overlay painted behind it.
class _CyclePhaseCalorieChart extends StatelessWidget {
  final List<_DatedCalorieEntry> entries;
  final CyclePrediction prediction;
  final bool isDark;

  const _CyclePhaseCalorieChart({
    required this.entries,
    required this.prediction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rangeStart = entries.first.date;
    final rangeEnd = entries.last.date;
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    if (totalDays <= 0) return const SizedBox.shrink();

    final maxCal = entries.fold<double>(
        0, (m, e) => e.calories > m ? e.calories.toDouble() : m);
    final chartMax = maxCal > 0 ? (maxCal * 1.2).ceilToDouble() : 2000.0;

    final barColor =
        isDark ? const Color(0xFF4FC3F7) : const Color(0xFF1E88E5);
    final labelColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Bar chart x is the day-offset from rangeStart so it lines up 1:1 with
    // the overlay's date-keyed columns.
    final barGroups = <BarChartGroupData>[
      for (final e in entries)
        BarChartGroupData(
          x: e.date.difference(rangeStart).inDays,
          barRods: [
            BarChartRodData(
              toY: e.calories > 0 ? e.calories.toDouble() : 0,
              color: e.calories > 0 ? barColor : Colors.transparent,
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ],
        ),
    ];

    return Stack(
      children: [
        // Layer 1 — phase columns behind the bars. The left/bottom padding
        // matches the chart's reserved axis space so columns align with data.
        CyclePhaseChartOverlay(
          prediction: prediction,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          leftPadding: 36,
          bottomPadding: 24,
        ),
        // Layer 2 — the calorie bars.
        BarChart(
          BarChartData(
            maxY: chartMax,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    isDark ? const Color(0xFF2A2A2A) : Colors.white,
                getTooltipItem: (group, gi, rod, ri) {
                  final dayOffset = group.x;
                  final entry = entries.firstWhere(
                    (e) =>
                        e.date.difference(rangeStart).inDays == dayOffset,
                    orElse: () => entries.first,
                  );
                  return BarTooltipItem(
                    '${entry.calories} cal',
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
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final dayOffset = value.toInt();
                    final date =
                        rangeStart.add(Duration(days: dayOffset));
                    const days = [
                      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                    ];
                    if (dayOffset < 0 || dayOffset > totalDays) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        days[date.weekday - 1],
                        style:
                            TextStyle(fontSize: 10, color: labelColor),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == meta.max) {
                      return const SizedBox();
                    }
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 9, color: labelColor),
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
            barGroups: barGroups,
          ),
        ),
      ],
    );
  }
}
