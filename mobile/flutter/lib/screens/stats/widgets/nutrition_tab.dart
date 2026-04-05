import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_stats_provider.dart';
import '../../../widgets/nutrition/health_metrics_card.dart';
import '../../../widgets/nutrition/food_mood_analytics_card.dart';

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
      return const Center(child: Text('Sign in to view nutrition stats'));
    }

    final weeklySummary = ref.watch(weeklySummaryProvider(userId!));
    final weeklyNutrition = ref.watch(weeklyNutritionProvider(userId!));
    final detailedTDEE = ref.watch(detailedTDEEProvider(userId!));
    final adherence = ref.watch(adherenceSummaryProvider(userId!));

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
            _WeeklyOverviewCard(
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 2: Calorie Trend Chart
          _CalorieTrendCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 3: Macro Breakdown
          _MacroBreakdownCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 4: TDEE & Energy Balance
          _TDEECard(
            detailedTDEE: detailedTDEE,
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 5: Adherence & Consistency
          _AdherenceCard(
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
