import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_stats_provider.dart';
import '../../../data/providers/fueling_split_provider.dart';
import '../../../data/providers/trend_series_provider.dart';
import '../../../widgets/charts/mini_sparkline.dart';
import '../../../widgets/stats/big_stat.dart';
import '../../../widgets/stats/stat_delta_chip.dart';
import '../../../widgets/stats/stat_section_shell.dart';
import '../../../widgets/stats/fueling_split_card.dart';
import '../../../widgets/nutrition_stats/calorie_trend_card.dart';
import '../../../widgets/nutrition_stats/macro_breakdown_card.dart';
import '../../../widgets/nutrition_stats/tdee_card.dart';
import '../../../widgets/nutrition_stats/adherence_card.dart';

/// "NUTRITION STATS" section embedded in the Nutrition tab's Daily view.
///
/// Mirrors the Workout tab's "TRAINING STATS" block: a big-number scalar strip
/// up top (week-at-a-glance), then the reusable nutrition stat cards (the same
/// public widgets the /stats Nutrition tab renders), the fueling split card,
/// and an entry point into the custom trends builder.
///
/// Every sub-card resolves its own provider and handles loading / empty /
/// error independently. NOTHING here fabricates a number: a loading provider
/// shows a skeleton, a null/empty payload shows an explicit empty state, and
/// real data shows real values.
class NutritionStatsSection extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const NutritionStatsSection({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.colors(context).accent;

    // Card chrome matched to the /stats Nutrition tab so the extracted cards
    // look pixel-identical in both places.
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final weeklySummary = ref.watch(weeklySummaryProvider(userId));
    final weeklyNutrition = ref.watch(weeklyNutritionProvider(userId));
    final detailedTDEE = ref.watch(detailedTDEEProvider(userId));
    final adherence = ref.watch(adherenceSummaryProvider(userId));
    final fueling = ref.watch(fuelingSplitProvider);
    final useKgForBody = ref.watch(useKgProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatSectionHeader(
          title: 'Nutrition stats',
          isDark: isDark,
          onSeeAll: () => context.push('/stats'),
          // Custom-trends entry, collapsed from the old full-width card into a
          // compact icon beside "See all". Pre-seeds the builder with calories.
          trendsAccent: accent,
          onTrendsTap: () =>
              context.push('/trends/custom', extra: TrendMetric.calories),
        ),
        const SizedBox(height: 12),

        // 1 — Scalar strip (week at a glance, big numbers).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _NutritionScalarStrip(
            weeklySummary: weeklySummary,
            weeklyNutrition: weeklyNutrition,
            isDark: isDark,
            accent: accent,
            useKgForBody: useKgForBody,
            cardColor: cardColor,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(height: 16),

        // The reusable stat cards are full-bleed-to-16px-gutters like the rest
        // of the Daily column, so wrap each in the same horizontal padding.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2 — Calorie trend.
              CalorieTrendCard(
                weeklyNutrition: weeklyNutrition,
                cardColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // 3 — Macro breakdown.
              MacroBreakdownCard(
                weeklyNutrition: weeklyNutrition,
                cardColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // 4 — TDEE & energy balance.
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

              // 5 — Adherence & consistency.
              AdherenceCard(
                adherence: adherence,
                cardColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // 6 — Fueling split (owned by another agent; imported only).
              // Custom trends now lives as a compact icon in the section
              // header (beside "See all"), not a full-width card here.
              FuelingSplitCard(
                fueling: fueling,
                isDark: isDark,
                accent: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The big-number week-at-a-glance strip. Renders four [BigStat] tiles
/// (avg calories with a calorie sparkline, avg protein, days logged, and
/// weight change as a delta chip) plus a one-line human summary.
///
/// The strip is driven by [weeklySummaryProvider] for the scalars and
/// [weeklyNutritionProvider] for the calorie sparkline. It never invents a
/// number: loading → skeleton, null summary → explicit empty state.
class _NutritionScalarStrip extends StatelessWidget {
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final bool isDark;
  final Color accent;
  final bool useKgForBody;
  final Color cardColor;
  final Color textMuted;

  const _NutritionScalarStrip({
    required this.weeklySummary,
    required this.weeklyNutrition,
    required this.isDark,
    required this.accent,
    required this.useKgForBody,
    required this.cardColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklySummary.when(
        loading: () => const _ScalarStripSkeleton(),
        error: (_, __) => _emptyState(
          context,
          'We could not load this week\'s nutrition summary. Pull to refresh '
          'or check back shortly.',
        ),
        data: (summary) {
          if (summary == null) {
            return _emptyState(
              context,
              'Log your meals this week and your nutrition stats will appear '
              'here.',
            );
          }

          // Real daily-calorie series for the sparkline under the calories
          // tile. Only built from actually-logged days; if fewer than two
          // points exist, MiniSparkline renders an empty placeholder (no
          // fabricated trend).
          final calorieSeries = weeklyNutrition.valueOrNull?.dailySummaries
                  .where((d) => d.calories > 0)
                  .map((d) => d.calories.toDouble())
                  .toList() ??
              const <double>[];

          // Weight change respects the body-weight unit setting (kg vs lbs);
          // null means we genuinely have no weigh-ins to compare, so the tile
          // shows a neutral "no change" chip rather than a made-up delta.
          final double? weightChangeKg = summary.weightChange;
          final bool hasWeight = weightChangeKg != null;
          final double weightDisplay = hasWeight
              ? (useKgForBody
                  ? weightChangeKg
                  : WeightUtils.kgToLbs(weightChangeKg))
              : 0.0;
          final String weightUnit = useKgForBody ? 'kg' : 'lbs';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: avg calories (with sparkline) + avg protein.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BigStat(
                        value: _formatInt(summary.avgCalories),
                        label: 'avg calories',
                        icon: Icons.local_fire_department,
                        accent: accent,
                        isDark: isDark,
                        trend: calorieSeries.length >= 2
                            ? MiniSparkline(
                                values: calorieSeries,
                                color: accent,
                                height: 30,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BigStat(
                        value: '${summary.avgProtein}',
                        unit: 'g',
                        label: 'avg protein',
                        icon: Icons.fitness_center,
                        accent: accent,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Second row: days logged + weight change.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BigStat(
                        value: '${summary.daysLogged}',
                        label: 'of 7 this week',
                        icon: Icons.calendar_today,
                        accent: accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BigStat(
                        value: hasWeight
                            ? weightDisplay.abs().toStringAsFixed(1)
                            : '--',
                        unit: hasWeight ? weightUnit : null,
                        label: 'weight change',
                        icon: Icons.monitor_weight_outlined,
                        accent: accent,
                        isDark: isDark,
                        delta: hasWeight
                            ? StatDeltaChip(
                                // For a cut, a decrease in body weight is the
                                // win, so positiveIsGood:false makes "down"
                                // read green.
                                value: weightDisplay,
                                magnitudeLabel:
                                    '${weightDisplay.abs().toStringAsFixed(1)} $weightUnit',
                                positiveIsGood: false,
                                neutralEpsilon: 0.05,
                                flatLabel: 'no change',
                                isDark: isDark,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _summaryLine(summary),
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Row(
      children: [
        Icon(Icons.insights_outlined, size: 18, color: textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 13, height: 1.3, color: textMuted),
          ),
        ),
      ],
    );
  }

  /// Thousands-separated calorie value (e.g. "2,140"). The big tile already
  /// FittedBox-scales, but a grouped number is easier to read at a glance.
  static String _formatInt(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// A short, human one-liner built entirely from this week's real numbers.
  /// Variant pools (>= 4 each) so the copy never reads robotic, with the exact
  /// figures substituted in. No em dashes.
  static String _summaryLine(WeeklySummaryData s) {
    final rng = math.Random(
      s.daysLogged * 31 + s.avgCalories + s.avgProtein * 7,
    );

    // Branch on how complete the logging week is so the tone fits the data.
    if (s.daysLogged == 0) {
      const pool = [
        'No meals logged this week yet. Log a day to start your trend.',
        'Nothing logged this week so far. Your first entry kicks things off.',
        'This week is still a blank slate. Add a meal to begin tracking.',
        'No data for this week yet. Start logging and stats will fill in.',
      ];
      return pool[rng.nextInt(pool.length)];
    }

    if (s.daysLogged >= 6) {
      final pool = [
        'Strong week: ${s.daysLogged} of 7 days logged at ${_formatInt(s.avgCalories)} cal and ${s.avgProtein}g protein on average.',
        'You logged ${s.daysLogged} of 7 days this week, averaging ${_formatInt(s.avgCalories)} cal and ${s.avgProtein}g protein.',
        '${s.daysLogged} days tracked this week. Your average sits at ${_formatInt(s.avgCalories)} cal with ${s.avgProtein}g protein.',
        'Consistent week with ${s.daysLogged} of 7 days logged, ${s.avgProtein}g protein and ${_formatInt(s.avgCalories)} cal per day.',
      ];
      return pool[rng.nextInt(pool.length)];
    }

    final pool = [
      '${s.daysLogged} of 7 days logged this week, averaging ${_formatInt(s.avgCalories)} cal and ${s.avgProtein}g protein.',
      'So far this week: ${s.daysLogged} days tracked at ${_formatInt(s.avgCalories)} cal and ${s.avgProtein}g protein on average.',
      'You have ${s.daysLogged} days in this week, sitting at ${_formatInt(s.avgCalories)} cal and ${s.avgProtein}g protein per day.',
      'This week shows ${s.daysLogged} logged days with ${s.avgProtein}g protein and ${_formatInt(s.avgCalories)} cal on average.',
    ];
    return pool[rng.nextInt(pool.length)];
  }
}

/// Layout-matched skeleton for the scalar strip while the weekly summary
/// provider resolves.
class _ScalarStripSkeleton extends StatelessWidget {
  const _ScalarStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 72, radius: 10)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, radius: 10)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 72, radius: 10)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, radius: 10)),
          ],
        ),
        SizedBox(height: 14),
        SkeletonBox(height: 14, radius: 6),
      ],
    );
  }
}
