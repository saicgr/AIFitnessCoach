import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/accent_color_provider.dart';
import '../shareable_data.dart';

/// Adapter that maps backend nutrition report payloads (daily / weekly /
/// monthly) onto the unified `Shareable` payload so the same gallery
/// (`ShareableSheet`) handles every nutrition share. Replaces the
/// stand-alone `ShareNutritionSheet` carousel.
class NutritionAdapter {
  /// Build a `Shareable` from `POST /nutrition/reports/daily`.
  static Shareable? fromDailyReport({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final calories = (json['calories_consumed'] as num?)?.toInt() ?? 0;
    final target = (json['calorie_target'] as num?)?.toInt() ?? 2000;
    final macros = (json['macros'] as Map?) ?? const {};
    final protein = (macros['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = (macros['carbs_g'] as num?)?.toDouble() ?? 0;
    final fat = (macros['fat_g'] as num?)?.toDouble() ?? 0;
    final fiber = (macros['fiber_g'] as num?)?.toDouble() ?? 0;
    final inflam = (json['inflammation_score'] as num?)?.toDouble();
    final contribs =
        ((json['inflammation_top_contributors'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
    final summary = json['ai_summary'] as String? ?? '';
    final tips = ((json['tomorrow_suggestions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final firstName = json['user_first_name'] as String?;
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) return null;
    final accent = ref.read(accentColorProvider).getColor(true);

    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null ? "$firstName's Daily Nutrition" : 'Daily Nutrition',
      periodLabel: json['date'] as String? ?? '',
      heroValue: calories,
      heroUnitSingular: 'kcal',
      highlights: [
        ShareableMetric(
          label: 'CALORIES',
          value: '$calories / $target',
          icon: Icons.local_fire_department_rounded,
          accent: const Color(0xFFFF6B35),
        ),
        ShareableMetric(
          label: 'PROTEIN',
          value: '${protein.round()}g',
          icon: Icons.egg_alt_rounded,
        ),
        ShareableMetric(
          label: 'CARBS',
          value: '${carbs.round()}g',
          icon: Icons.bakery_dining_rounded,
        ),
        ShareableMetric(
          label: 'FAT',
          value: '${fat.round()}g',
          icon: Icons.water_drop_rounded,
        ),
        if (fiber > 0)
          ShareableMetric(
            label: 'FIBER',
            value: '${fiber.round()}g',
            icon: Icons.spa_rounded,
          ),
        if (inflam != null)
          ShareableMetric(
            label: 'INFLAMMATION',
            value: inflam.toStringAsFixed(1),
            icon: Icons.healing_rounded,
            accent: inflam >= 6
                ? const Color(0xFFEF4444)
                : (inflam >= 4 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          ),
      ],
      subMetrics: [
        if (summary.isNotEmpty)
          ShareableMetric(label: 'SUMMARY', value: summary),
        for (final t in tips.take(3))
          ShareableMetric(label: 'TIP', value: t),
        if (contribs.isNotEmpty)
          ShareableMetric(
            label: 'INFLAM SOURCES',
            value: contribs.take(3).join(' · '),
          ),
      ],
      accentColor: accent,
    );
  }

  /// Build a `Shareable` from `POST /nutrition/reports/weekly`.
  ///
  /// The 7-day macro arrays go into `subMetrics` so weekly templates
  /// (`nutritionWeekMacroCircles`, `nutritionWeekBars`) can read them
  /// without a separate field.
  static Shareable? fromWeeklyReport({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final dailyCals = ((json['daily_calories'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    if (dailyCals.isEmpty) return null;
    final dailyMacros =
        ((json['daily_macros'] as List?) ?? const []).cast<Map>();
    final avg = (json['weekly_avg_calories'] as num?)?.toInt() ?? 0;
    final daysCal = (json['days_hit_calorie_goal'] as num?)?.toInt() ?? 0;
    final daysProt = (json['days_hit_protein_goal'] as num?)?.toInt() ?? 0;
    final inflTrend = ((json['inflammation_trend'] as List?) ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    final delta = (json['week_over_week_delta'] as Map?) ?? const {};
    final narrative = json['ai_narrative'] as String? ?? '';
    final firstName = json['user_first_name'] as String?;

    final pct = (delta['calories_avg_pct'] as num?)?.toDouble() ?? 0;
    final arrow = pct > 0 ? '↑' : (pct < 0 ? '↓' : '→');

    final accent = ref.read(accentColorProvider).getColor(true);
    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null
          ? "$firstName's Weekly Wrap"
          : 'Weekly Nutrition Wrap',
      periodLabel:
          '${json['week_start']} → ${json['week_end']}',
      heroValue: avg,
      heroUnitSingular: 'kcal/day',
      highlights: [
        ShareableMetric(
          label: 'AVG CAL',
          value: '$avg',
          icon: Icons.local_fire_department_rounded,
        ),
        ShareableMetric(
          label: 'GOAL HITS',
          value: '$daysCal/7',
          icon: Icons.check_circle_rounded,
          accent: const Color(0xFF10B981),
        ),
        ShareableMetric(
          label: 'PROTEIN HITS',
          value: '$daysProt/7',
          icon: Icons.egg_alt_rounded,
        ),
        ShareableMetric(
          label: 'WEEK Δ',
          value: '$arrow ${pct.abs().toStringAsFixed(1)}%',
          icon: Icons.trending_up_rounded,
        ),
      ],
      subMetrics: [
        if (narrative.isNotEmpty)
          ShareableMetric(label: 'NARRATIVE', value: narrative),
        // Encode the 7-day arrays so weekly templates can render charts.
        ShareableMetric(
          label: 'DAILY_CAL_ARRAY',
          value: dailyCals.join(','),
        ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_PROTEIN_ARRAY',
            value: dailyMacros
                .map((m) => ((m['protein_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_CARBS_ARRAY',
            value: dailyMacros
                .map((m) => ((m['carbs_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_FAT_ARRAY',
            value: dailyMacros
                .map((m) => ((m['fat_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (inflTrend.isNotEmpty)
          ShareableMetric(
            label: 'INFLAM_TREND_ARRAY',
            value: inflTrend.map((v) => v.toStringAsFixed(1)).join(','),
          ),
      ],
      accentColor: accent,
    );
  }

  /// Build a `Shareable` for a monthly calendar heatmap from a 30-day
  /// summary payload (`{daily_calories: List<int>, daily_macro_hits:
  /// List<int>}` where macro_hits ∈ {0,1,2,3}).
  static Shareable? fromMonthlySummary({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final cals = ((json['daily_calories'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    if (cals.isEmpty) return null;
    final hits = ((json['daily_macro_hits'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    final daysTracked = cals.where((c) => c > 0).length;
    final bestStreak = (json['best_streak'] as num?)?.toInt() ?? 0;
    final avg = cals.isEmpty ? 0 : (cals.reduce((a, b) => a + b) / cals.length).round();
    final accent = ref.read(accentColorProvider).getColor(true);
    final firstName = json['user_first_name'] as String?;

    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null
          ? "$firstName's Month in Macros"
          : 'Month in Macros',
      periodLabel: json['month_label'] as String? ?? '',
      heroValue: daysTracked,
      heroUnitSingular: 'day tracked',
      heroSuffix: daysTracked == 1 ? null : 's',
      highlights: [
        ShareableMetric(label: 'AVG CAL', value: '$avg'),
        ShareableMetric(label: 'BEST STREAK', value: '$bestStreak days'),
        ShareableMetric(label: 'TRACKED', value: '$daysTracked / ${cals.length}'),
      ],
      subMetrics: [
        ShareableMetric(label: 'CAL_ARRAY', value: cals.join(',')),
        if (hits.isNotEmpty)
          ShareableMetric(label: 'MACRO_HITS_ARRAY', value: hits.join(',')),
      ],
      accentColor: accent,
    );
  }
}
