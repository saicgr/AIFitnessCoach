/// Google-Health-style "Key metrics" grid for the metrics dashboard.
///
/// Surfaces the at-a-glance metrics Google Health leads with — weight, energy
/// burned, calorie intake, macros, steps, exercise days, mindfulness — each
/// pulled from data Zealova already collects and each with a true 4-state
/// render (loading / error / no-data / value). "No data" is distinguished from
/// a real 0: a missing daily row reads "No data"; a logged 0 reads 0.
///
/// Sparklines are mini bar rows (not fl_chart) so degenerate inputs — zero,
/// one, or all-equal points — can never divide-by-zero or mislead; today's
/// (still-accumulating) bar is de-emphasized.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/combined_health_provider.dart';
import '../../../data/providers/mindfulness_provider.dart';
import '../../../data/providers/neat_provider.dart';
import '../../../data/providers/nutrition_stats_provider.dart';
import '../../../data/repositories/metrics_repository.dart';
import '../../../data/services/health_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class KeyMetricsGrid extends ConsumerWidget {
  const KeyMetricsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);

    final metrics = ref.watch(metricsProvider).latestMetrics;
    final healthAsync = ref.watch(combinedHealthHistoryProvider);
    final mindfulAsync = ref.watch(mindfulnessTodayProvider);
    final mindfulHist = ref.watch(mindfulnessHistoryProvider).asData?.value;
    final useKg = ref.watch(useKgProvider);
    final weightUnit = ref.watch(weightUnitProvider);
    final stepGoal = ref.watch(stepGoalProvider);
    final nutritionAsync = userId == null
        ? null
        : ref.watch(weeklyNutritionProvider(userId));

    final history = healthAsync.asData?.value;
    final today = history?.dayFor(DateTime.now());
    final last7Activity = _lastNActivity(history, 7);

    // Physiologic / sanity clamps (edge case N): a glitchy wearable value
    // (2M steps, 0 weight, absurd energy) must read as "No data", never as a
    // real number. Out-of-range collapses to null.
    final weightKg = (metrics?.weightKg != null && metrics!.weightKg! > 0)
        ? metrics.weightKg
        : null;
    final stepsToday =
        (today != null && today.steps >= 0 && today.steps <= 100000)
            ? today.steps
            : null;
    final energyToday = (today != null &&
            today.caloriesBurned >= 0 &&
            today.caloriesBurned <= 20000)
        ? today.caloriesBurned
        : null;

    // ---- Weight (goal-neutral trend, user's body-weight unit) -------------
    final weightCard = _MetricTile(
      label: l10n.metricsDashboardWeight,
      icon: Icons.monitor_weight,
      color: AppColors.cyan,
      value: weightKg == null
          ? null
          : _trim(WeightUtils.fromKg(weightKg, displayInLbs: !useKg)),
      unit: weightKg == null ? '' : weightUnit,
      // Delta computed in kg (storage unit) then shown neutrally — never
      // colored, so a goal-consistent gain/loss is never "good/bad".
      subtitle: weightKg == null
          ? null
          : _neutralWeightDelta(metrics, useKg, weightUnit),
      onTap: () => context.push('/measurements'),
    );

    // ---- Energy burned (today active energy) ------------------------------
    final energyCard = _MetricTile(
      label: l10n.metricsDashboardEnergyBurned,
      icon: Icons.local_fire_department,
      color: AppColors.orange,
      loading: healthAsync.isLoading && history == null,
      error: healthAsync.hasError,
      value: energyToday == null ? null : '${energyToday.round()}',
      unit: 'kcal',
      bars: last7Activity.map(_clampEnergyBar).toList(),
      onTap: () => context.push('/health/combined'),
    );

    // ---- Calorie intake + macros (today, from weekly nutrition) -----------
    final nutritionToday = _todayNutrition(nutritionAsync?.asData?.value);
    final nutritionLoading = nutritionAsync?.isLoading ?? false;
    final nutritionError = nutritionAsync?.hasError ?? false;
    final intakeCard = _MetricTile(
      label: l10n.metricsDashboardCalorieIntake,
      icon: Icons.restaurant,
      color: AppColors.green,
      loading: nutritionLoading && nutritionToday == null,
      error: nutritionError,
      value: nutritionToday == null ? null : '${nutritionToday.calories}',
      unit: 'kcal',
      bars: _last7Nutrition(nutritionAsync?.asData?.value, (e) => e.calories.toDouble()),
      onTap: () => context.go('/nutrition'),
    );

    // ---- Steps ------------------------------------------------------------
    final stepsCard = _MetricTile(
      label: l10n.metricsDashboardSteps,
      icon: Icons.directions_walk,
      color: AppColors.cyan,
      loading: healthAsync.isLoading && history == null,
      error: healthAsync.hasError,
      value: stepsToday == null ? null : '$stepsToday',
      unit: '',
      subtitle: stepsToday == null
          ? null
          : l10n.metricsDashboardOfGoal(_compact(stepGoal)),
      bars: last7Activity.map(_clampStepsBar).toList(),
      onTap: () => context.push('/health/combined'),
    );

    // ---- Mindfulness ------------------------------------------------------
    final mindful = mindfulAsync.asData?.value;
    final mindfulCard = _MetricTile(
      label: l10n.metricsDashboardMindfulnessMinutes,
      icon: Icons.self_improvement,
      color: AppColors.purple,
      loading: mindfulAsync.isLoading && mindful == null,
      error: mindfulAsync.hasError,
      value: mindful == null ? null : '${mindful.minutes}',
      unit: 'min',
      subtitle: mindful == null
          ? null
          : (mindful.goalMet
              ? l10n.metricsDashboardGoalMet
              : l10n.metricsDashboardOfGoal('${mindful.targetMinutes} min')),
      bars: mindfulHist?.map((d) => d.minutes.toDouble()).toList(),
      onTap: () =>
          context.push('/mindfulness/session?source=breathwork&duration=5'),
    );

    // ---- Exercise days (this week) ----------------------------------------
    final exerciseCard = _MetricTile(
      label: l10n.metricsDashboardExerciseDays,
      icon: Icons.fitness_center,
      color: AppColors.success,
      value: metrics?.workoutsCompleted == null
          ? null
          : '${metrics!.workoutsCompleted}',
      unit: '',
      subtitle: metrics?.workoutsCompleted == null
          ? null
          : l10n.metricsDashboardThisWeek,
      onTap: () => context.go('/workouts'),
    );

    // Wall-of-No-data guard (edge case L): a brand-new / disconnected user
    // would otherwise see a grid of "No data" cards. When most key metrics are
    // empty AND nothing is still loading, lead with a single Get-started CTA
    // instead. The cards still render below it.
    final anyLoading = healthAsync.isLoading ||
        (nutritionAsync?.isLoading ?? false) ||
        mindfulAsync.isLoading;
    final hasFlags = <bool>[
      weightKg != null,
      energyToday != null,
      nutritionToday != null,
      stepsToday != null,
      mindful != null,
      metrics?.workoutsCompleted != null,
    ];
    final emptyRatio =
        hasFlags.where((h) => !h).length / hasFlags.length;
    final showGetStarted = !anyLoading && emptyRatio >= 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.metricsDashboardKeyMetrics),
        const SizedBox(height: 12),
        if (showGetStarted) ...[
          _GetStartedCta(
            title: l10n.metricsDashboardGetStartedTitle,
            body: l10n.metricsDashboardGetStartedCta,
            onTap: () => context.push('/health/combined'),
          ),
          const SizedBox(height: 12),
        ],
        _row(weightCard, energyCard),
        const SizedBox(height: 12),
        _row(intakeCard, stepsCard),
        const SizedBox(height: 12),
        // Macros — full-width card with carbs / fat / protein pills.
        _MacrosCard(
          loading: nutritionLoading && nutritionToday == null,
          error: nutritionError,
          today: nutritionToday,
          onTap: () => context.go('/nutrition'),
        ),
        const SizedBox(height: 12),
        _row(mindfulCard, exerciseCard),
      ],
    );
  }

  Widget _row(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      );

  // Sparkline bar values with the same physiologic clamps as the headline
  // value (edge case N): an out-of-range day reads as a gap, not a spike.
  static double? _clampStepsBar(DailyActivity? d) {
    if (d == null) return null;
    final s = d.steps;
    return (s >= 0 && s <= 100000) ? s.toDouble() : null;
  }

  static double? _clampEnergyBar(DailyActivity? d) {
    if (d == null) return null;
    final e = d.caloriesBurned;
    return (e >= 0 && e <= 20000) ? e : null;
  }

  // Last N daily-activity rows aligned oldest→newest, null where a day has no
  // synced row (so the sparkline shows gaps, not collapsed points).
  static List<DailyActivity?> _lastNActivity(
      CombinedHealthHistory? history, int n) {
    final out = <DailyActivity?>[];
    final now = DateTime.now();
    for (var i = n - 1; i >= 0; i--) {
      out.add(history?.dayFor(now.subtract(Duration(days: i))));
    }
    return out;
  }

  static _NutritionDay? _todayNutrition(WeeklyNutritionData? data) {
    if (data == null || data.dailySummaries.isEmpty) return null;
    final todayKey = _ymd(DateTime.now());
    for (final e in data.dailySummaries) {
      if (e.date.startsWith(todayKey)) {
        return _NutritionDay(
            calories: e.calories,
            carbs: e.carbsG,
            fat: e.fatG,
            protein: e.proteinG);
      }
    }
    return null; // no entry for today yet → "No data"
  }

  static List<double?>? _last7Nutrition(
      WeeklyNutritionData? data, double Function(DailyNutritionEntry) pick) {
    if (data == null || data.dailySummaries.isEmpty) return null;
    final byDate = {for (final e in data.dailySummaries) e.date.substring(0, 10): e};
    final now = DateTime.now();
    final out = <double?>[];
    for (var i = 6; i >= 0; i--) {
      final key = _ymd(now.subtract(Duration(days: i)));
      final e = byDate[key];
      out.add(e == null ? null : pick(e));
    }
    return out;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _trim(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }

  static String _compact(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k' : '$v';

  static String? _neutralWeightDelta(
      HealthMetrics? m, bool useKg, String unit) {
    if (m?.weightKg == null || m?.previousWeightKg == null) return null;
    final deltaKg = m!.weightKg! - m.previousWeightKg!;
    if (deltaKg.abs() < 0.05) return null;
    final shown = WeightUtils.kgToLbs(deltaKg.abs());
    final v = useKg ? deltaKg.abs() : shown;
    final arrow = deltaKg > 0 ? '▲' : '▼';
    return '$arrow ${_trim(v)} $unit';
  }
}

/// Shown at the top of the grid for brand-new / disconnected users instead of
/// a wall of "No data" cards (edge case L).
class _GetStartedCta extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  const _GetStartedCta(
      {required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $body',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_graph, color: AppColors.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionDay {
  final int calories;
  final double carbs;
  final double fat;
  final double protein;
  const _NutritionDay(
      {required this.calories,
      required this.carbs,
      required this.fat,
      required this.protein});
}

/// A single 4-state metric tile with an optional mini-bar sparkline.
class _MetricTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool error;

  /// The display value, or null → "No data".
  final String? value;
  final String unit;
  final String? subtitle;

  /// Optional sparkline series (oldest→newest; null entries = gaps).
  final List<double?>? bars;
  final VoidCallback? onTap;

  const _MetricTile({
    required this.label,
    required this.icon,
    required this.color,
    this.loading = false,
    this.error = false,
    required this.value,
    required this.unit,
    this.subtitle,
    this.bars,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Accessibility (edge case T): a single spoken label conveys the value;
    // the decorative sparkline is excluded so a screen reader reads the number,
    // not "chart". Status is never color-only.
    final spoken = loading
        ? '$label, loading'
        : error
            ? '$label, unavailable'
            : value == null
                ? '$label, ${l10n.metricsDashboardNoData}'
                : '$label, $value $unit${subtitle != null ? ', $subtitle' : ''}';
    return Semantics(
      button: onTap != null,
      label: spoken,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _body(l10n),
              if (bars != null && !loading && !error && value != null) ...[
                const SizedBox(height: 10),
                // Decorative — the spoken Semantics label already conveys the
                // value, so the screen reader skips the bars (edge case T).
                ExcludeSemantics(child: _MiniBars(values: bars!, color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (loading) {
      return Container(
        height: 26,
        width: 60,
        decoration: BoxDecoration(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    if (error) {
      return const Text('—',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted));
    }
    if (value == null) {
      return Text(
        l10n.metricsDashboardNoData,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
      ],
    );
  }
}

/// Full-width macros card: carbs / fat / protein with macro-specific colors.
class _MacrosCard extends StatelessWidget {
  final bool loading;
  final bool error;
  final _NutritionDay? today;
  final VoidCallback? onTap;

  const _MacrosCard(
      {required this.loading,
      required this.error,
      required this.today,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cCarbs = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final cFat = isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    final cProtein =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(l10n.metricsDashboardMacros,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              Container(
                height: 22,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6)),
              )
            else if (error)
              const Text('—',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted))
            else if (today == null)
              Text(l10n.metricsDashboardNoData,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted))
            else
              Row(
                children: [
                  _macro(l10n.metricsDashboardCarbs,
                      today!.carbs.round(), cCarbs),
                  _macro(l10n.metricsDashboardFat, today!.fat.round(), cFat),
                  _macro(l10n.metricsDashboardProtein,
                      today!.protein.round(), cProtein),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, int grams, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 3),
            Text('${grams}g',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
}

/// A compact mini bar sparkline. Robust to degenerate inputs by construction:
/// 0 bars → empty; 1 bar → that bar; all-equal → uniform mid bars (no
/// divide-by-zero). The last bar (today, still accumulating) is dimmed.
class _MiniBars extends StatelessWidget {
  final List<double?> values;
  final Color color;

  const _MiniBars({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return const SizedBox(height: 22);
    final maxV = present.reduce((a, b) => a > b ? a : b);
    final hasRange = maxV > 0;

    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final v = values[i];
          final isToday = i == values.length - 1;
          if (v == null) {
            // Gap — faint placeholder so spacing stays date-true.
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final frac = hasRange ? (v / maxV).clamp(0.08, 1.0) : 0.4;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: 22 * frac,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isToday ? 0.45 : 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
