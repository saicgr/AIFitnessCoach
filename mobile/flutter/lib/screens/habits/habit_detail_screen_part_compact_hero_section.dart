part of 'habit_detail_screen.dart';


// ============================================
// COMPACT HERO SECTION (icon + ring + stats in one row)
// Eliminates wasted vertical space by combining header and ring
// ============================================

class _CompactHeroSection extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _CompactHeroSection({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Streak ring on left, name + stats on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Streak ring (compact)
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SimpleCircularProgressBar(
                    size: 100,
                    progressStrokeWidth: 8,
                    backStrokeWidth: 8,
                    valueNotifier: ValueNotifier(data.completionRate.toDouble()),
                    progressColors: [habitColor, habitColor.withValues(alpha: 0.7)],
                    backColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    startAngle: -90,
                    mergeMode: true,
                    animationDuration: 1,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.currentStreak}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'day streak',
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Name + description + mini stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + name row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              habitColor.withValues(alpha: 0.2),
                              habitColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(data.icon, color: habitColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    data.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (data.isAutoTracked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: habitColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: habitColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (data.description != null && data.description!.isNotEmpty)
                              Text(
                                data.description!,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Habit strength bar
                  _HabitStrengthBar(
                    strength: data.habitStrength,
                    habitColor: habitColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 2: Quick stats - 4 compact tiles
        Row(
          children: [
            _MiniStatTile(icon: Icons.local_fire_department, value: '${data.currentStreak}', label: 'Streak', color: Colors.orange, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.emoji_events, value: '${data.longestStreak}', label: 'Best', color: Colors.amber, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.check_circle_outline, value: '${data.totalCompletions}', label: 'Total', color: Colors.green, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.trending_up, value: '${data.completionRate}%', label: 'Rate', color: habitColor, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
          ],
        ),
        // Best streak proximity alert
        if (data.daysUntilBestStreak != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '${data.daysUntilBestStreak} days until you beat your personal best!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


/// Habit strength bar (Loop-style exponential score)
class _HabitStrengthBar extends StatelessWidget {
  final double strength;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;

  const _HabitStrengthBar({
    required this.strength,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Habit Strength',
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              '${strength.round()}%',
              style: TextStyle(fontSize: 11, color: habitColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength / 100,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(habitColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}


class _MiniStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const _MiniStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
            Text(label, style: TextStyle(fontSize: 9, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}


// ============================================
// TAB 1: OVERVIEW
// ============================================

class _OverviewTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _OverviewTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion trend sparkline + trend arrow
          _TrendSparkline(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Weekly completion bar chart
          _WeeklyBarChart(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Day of week breakdown
          _DayOfWeekChart(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
          ),
        ],
      ),
    );
  }
}


// ============================================
// TREND SPARKLINE + TREND ARROW
// ============================================

class _TrendSparkline extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _TrendSparkline({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rates = data.weeklyRates;
    final trend = data.trend;
    final hasData = rates.any((r) => r > 0);

    Color trendColor;
    IconData trendIcon;
    String trendLabel;
    switch (trend) {
      case 'improving':
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        trendLabel = 'Improving';
        break;
      case 'declining':
        trendColor = Colors.redAccent;
        trendIcon = Icons.trending_down;
        trendLabel = 'Declining';
        break;
      default:
        trendColor = Colors.amber;
        trendIcon = Icons.trending_flat;
        trendLabel = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // Trend indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(trendIcon, color: trendColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Trend label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trendLabel,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: trendColor),
              ),
              Text(
                '8-week trend',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Sparkline chart
          if (hasData)
            SizedBox(
              width: 120,
              height: 36,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1,
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rates.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: trendColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: trendColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text('--', style: TextStyle(fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }
}


// ============================================
// WEEKLY BAR CHART
// ============================================

class _WeeklyBarChart extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _WeeklyBarChart({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bars = data.weeklyBars;
    final hasData = bars.any((b) => b.daysCompleted > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: habitColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Weekly Completions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Complete this habit to see weekly trends',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 7,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.85),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      tooltipMargin: 6,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bar = bars[group.x.toInt()];
                        return BarTooltipItem(
                          '${bar.daysCompleted}/7 days',
                          TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= bars.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              bars[index].label,
                              style: TextStyle(
                                color: bars[index].isCurrentWeek ? habitColor : textSecondary,
                                fontSize: 8,
                                fontWeight: bars[index].isCurrentWeek ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == 7) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text('${value.toInt()}', style: TextStyle(fontSize: 9, color: textSecondary)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 20,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 7,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: textSecondary.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: List.generate(bars.length, (index) {
                    final bar = bars[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: bar.daysCompleted.toDouble(),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          gradient: LinearGradient(
                            colors: bar.isCurrentWeek
                                ? [habitColor, habitColor.withValues(alpha: 0.7)]
                                : [habitColor.withValues(alpha: 0.55), habitColor.withValues(alpha: 0.3)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ============================================
// DAY-OF-WEEK BREAKDOWN
// ============================================

class _DayOfWeekChart extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _DayOfWeekChart({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final rates = data.dayOfWeekRates;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final hasData = rates.values.any((v) => v > 0);

    int? bestDay;
    int? worstDay;
    double bestRate = -1;
    double worstRate = 2;
    if (hasData) {
      for (int d = 1; d <= 7; d++) {
        final rate = rates[d] ?? 0;
        if (rate > bestRate) { bestRate = rate; bestDay = d; }
        if (rate < worstRate) { worstRate = rate; worstDay = d; }
      }
    }

    const fullDayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week_rounded, color: habitColor, size: 18),
              const SizedBox(width: 8),
              Text('Day of Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 60,
              child: Center(child: Text('Not enough data yet', style: TextStyle(fontSize: 12, color: textSecondary))),
            )
          else ...[
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final rate = rates[day] ?? 0;
                  final isBest = day == bestDay;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(rate * 100).round()}%',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isBest ? habitColor : textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: rate.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isBest ? habitColor : habitColor.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
                              color: isBest ? habitColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (bestDay != null)
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 13, color: Colors.green),
                      const SizedBox(width: 3),
                      Text(
                        'Best: ${fullDayNames[bestDay]} (${(bestRate * 100).round()}%)',
                        style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (worstDay != null && bestDay != worstDay)
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 13, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Text(
                        'Weakest: ${fullDayNames[worstDay]} (${(worstRate * 100).round()}%)',
                        style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


// ============================================
// TAB 2: CALENDAR (HEATMAP + MONTHLY)
// ============================================

class _CalendarTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _CalendarTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YearlyHeatmap(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder, isDark: isDark),
          const SizedBox(height: 16),
          Text('Monthly Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 10),
          _MonthlySummary(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder),
        ],
      ),
    );
  }
}


// ============================================
// GITHUB-STYLE YEARLY HEATMAP
// ============================================

class _YearlyHeatmap extends StatefulWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _YearlyHeatmap({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  State<_YearlyHeatmap> createState() => _YearlyHeatmapState();
}

