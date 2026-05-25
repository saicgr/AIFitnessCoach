part of 'nutrition_tab.dart';


// ── Card 1: Weekly Overview ──────────────────────────────────────

class _WeeklyOverviewCard extends StatelessWidget {
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _WeeklyOverviewCard({
    required this.weeklySummary,
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
      child: weeklySummary.when(
        // Layout-matched skeleton: title line + a row of 3 stat badges.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 140, height: 16, radius: 6),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
              ],
            ),
          ],
        ),
        error: (_, __) => _errorRow('Could not load weekly summary'),
        data: (data) {
          if (data == null) return _errorRow('No data available');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).nutritionTabPartWeeklyOverview,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetDaysLogged,
                    value: '${data.daysLogged}/7',
                    icon: Icons.calendar_today,
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetAvgCalories,
                    value: '${data.avgCalories}',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF9800),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetAvgProtein,
                    value: '${data.avgProtein}g',
                    icon: Icons.fitness_center,
                    color: const Color(0xFF009688),
                    isDark: isDark,
                  ),
                  if (data.weightChange != null) ...[
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: AppLocalizations.of(context).workoutSummaryAdvancedWeight,
                      value:
                          '${data.weightChange! > 0 ? '+' : ''}${data.weightChange!.toStringAsFixed(1)} kg',
                      icon: data.weightChange! > 0
                          ? Icons.trending_up
                          : data.weightChange! < 0
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: const Color(0xFF2196F3),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorRow(String message) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: textMuted),
        const SizedBox(width: 8),
        Text(message, style: TextStyle(color: textMuted, fontSize: 13)),
      ],
    );
  }
}


class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


// ── Card 2: Calorie Trend Chart ──────────────────────────────────

class _CalorieTrendCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _CalorieTrendCard({
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
  // closures on every unrelated rebuild of the NutritionTab (it is a
  // ConsumerWidget that rebuilds on ANY watched provider change) is wasteful.
  // We rebuild the BarChartData only when the entries/avg/theme change.
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


// ── Card 3: Macro Breakdown ──────────────────────────────────────

class _MacroBreakdownCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _MacroBreakdownCard({
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
        // Layout-matched skeleton: title + stacked bar + 3 macro rows.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 150, height: 16, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 20, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionTabPartCouldNotLoadMacros,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null || data.daysWithData == 0) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text(AppLocalizations.of(context).nutritionTabPartNoMacroDataThis,
                    style: TextStyle(color: textMuted)),
              ),
            );
          }
          final macros = data.averageMacros;
          final totalCals = (macros.protein * 4) +
              (macros.carbs * 4) +
              (macros.fat * 9);
          final proteinPct =
              totalCals > 0 ? (macros.protein * 4 / totalCals * 100) : 0.0;
          final carbsPct =
              totalCals > 0 ? (macros.carbs * 4 / totalCals * 100) : 0.0;
          final fatPct =
              totalCals > 0 ? (macros.fat * 9 / totalCals * 100) : 0.0;

          const proteinColor = Color(0xFF009688);
          const carbsColor = Color(0xFF42A5F5);
          const fatColor = Color(0xFFFF9800);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).nutritionTabPartMacroBreakdown,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).nutritionTabPartWeeklyAverageDistribution,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),
              // Stacked bar showing macro distribution
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      if (proteinPct > 0)
                        Expanded(
                          flex: proteinPct.round().clamp(1, 100),
                          child: Container(color: proteinColor),
                        ),
                      if (carbsPct > 0)
                        Expanded(
                          flex: carbsPct.round().clamp(1, 100),
                          child: Container(color: carbsColor),
                        ),
                      if (fatPct > 0)
                        Expanded(
                          flex: fatPct.round().clamp(1, 100),
                          child: Container(color: fatColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Macro detail rows
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                grams: macros.protein,
                pct: proteinPct,
                color: proteinColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                grams: macros.carbs,
                pct: carbsPct,
                color: carbsColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetFat,
                grams: macros.fat,
                pct: fatPct,
                color: fatColor,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}


class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final double pct;
  final Color color;
  final bool isDark;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ),
        Text(
          '${grams.round()}g',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${pct.round()}%',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ],
    );
  }
}


// ── Card 4: TDEE & Energy Balance ────────────────────────────────

class _TDEECard extends StatelessWidget {
  final AsyncValue<DetailedTDEE?> detailedTDEE;
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _TDEECard({
    required this.detailedTDEE,
    required this.weeklySummary,
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
      child: detailedTDEE.when(
        // Layout-matched skeleton: title + large TDEE figure + 2 detail rows.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 180, height: 16, radius: 6),
            SizedBox(height: 12),
            SkeletonBox(width: 160, height: 32, radius: 8),
            SizedBox(height: 12),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionTabPartCouldNotLoadTdee,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (tdee) {
          if (tdee == null) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text(AppLocalizations.of(context).nutritionTabPartNotEnoughDataFor,
                    style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            );
          }

          final avgIntake =
              weeklySummary.valueOrNull?.avgCalories ?? 0;
          final confidenceColor = switch (tdee.confidenceLevel) {
            'high' => const Color(0xFF4CAF50),
            'medium' => const Color(0xFFFF9800),
            _ => const Color(0xFFF44336),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).nutritionTabPartTdeeEnergyBalance,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tdee.confidenceLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: confidenceColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main TDEE display
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tdee.tdee}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      'cal/day  ${tdee.uncertaintyDisplay}',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Intake vs TDEE
              if (avgIntake > 0) ...[
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Avg intake: $avgIntake cal',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${avgIntake - tdee.tdee > 0 ? '+' : ''}${avgIntake - tdee.tdee} cal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (avgIntake - tdee.tdee).abs() < 100
                            ? const Color(0xFF4CAF50)
                            : (avgIntake > tdee.tdee
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF42A5F5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Weight trend
              Row(
                children: [
                  Icon(
                    tdee.weightTrend.direction == 'losing'
                        ? Icons.trending_down
                        : tdee.weightTrend.direction == 'gaining'
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weight: ${tdee.weightTrend.formattedWeeklyRate}',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
              // Metabolic adaptation warning
              if (tdee.hasAdaptation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 16, color: Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tdee.metabolicAdaptation?.actionDescription ??
                              'Metabolic adaptation detected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

