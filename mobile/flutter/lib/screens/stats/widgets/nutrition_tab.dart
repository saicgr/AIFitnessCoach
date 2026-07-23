import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../widgets/design_system/zealova.dart';
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
import '../../common/app_refresh_indicator.dart';
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

    return AppRefreshIndicator(
      onRefresh: () async {
        // Clear both cache tiers first — a plain invalidate would re-serve the
        // stale-while-revalidate snapshot, making pull-to-refresh show last
        // cycle's numbers until a second pull.
        await clearNutritionStatsAndFuelingCaches();
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
    final tc = ThemeColors.of(context);
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
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
                style: ZType.lbl(12, color: tc.textMuted)),
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
                  Icon(Icons.calendar_today,
                      size: 14, color: tc.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .nutritionCaloriesByCyclePhase
                          .toUpperCase(),
                      style: ZType.lbl(13, color: tc.textPrimary),
                    ),
                  ),
                  if (phase != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: cyclePhaseOverlayColor(phase)
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        phase.displayName.toUpperCase(),
                        style: ZType.lbl(
                          10,
                          color: cyclePhaseOverlayColor(phase),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Shaded columns mark your cycle phase — read intake swings '
                'against where you are in your cycle.',
                style: TextStyle(
                    fontSize: 12, color: tc.textMuted, height: 1.35),
              ),
              const SizedBox(height: 16),
              if (entries.length < 2)
                SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(AppLocalizations.of(context).nutritionLogAFewDays,
                        style: ZType.lbl(12, color: tc.textMuted)),
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
    final tc = ThemeColors.of(context);
    final rangeStart = entries.first.date;
    final rangeEnd = entries.last.date;
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    if (totalDays <= 0) return const SizedBox.shrink();

    final maxCal = entries.fold<double>(
        0, (m, e) => e.calories > m ? e.calories.toDouble() : m);
    final chartMax = maxCal > 0 ? (maxCal * 1.2).ceilToDouble() : 2000.0;

    final barColor = tc.accent;
    final labelColor = tc.textMuted;

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
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(2)),
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
                getTooltipColor: (_) => tc.surface,
                getTooltipItem: (group, gi, rod, ri) {
                  final dayOffset = group.x;
                  final entry = entries.firstWhere(
                    (e) =>
                        e.date.difference(rangeStart).inDays == dayOffset,
                    orElse: () => entries.first,
                  );
                  return BarTooltipItem(
                    '${entry.calories} cal',
                    ZType.data(11, color: tc.textPrimary),
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
                        days[date.weekday - 1].toUpperCase(),
                        style: ZType.lbl(9, color: labelColor),
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
                      style: ZType.data(9, color: labelColor),
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
                color: isDark ? AppColors.hairline : tc.cardBorder,
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
