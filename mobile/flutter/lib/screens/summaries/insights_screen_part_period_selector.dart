part of 'insights_screen.dart';


// ---------------------------------------------------------------------------
// Period Selector — horizontal scrolling pill buttons
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  final InsightsPeriod selected;
  final DateTimeRange? customRange;
  final bool isDark;
  final ValueChanged<InsightsPeriod> onSelect;
  final VoidCallback onPickCustom;

  const _PeriodSelector({
    required this.selected,
    required this.customRange,
    required this.isDark,
    required this.onSelect,
    required this.onPickCustom,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final isCustomActive = customRange != null;
    // A preset pill (1W / 1M / ...) only shows as selected when we aren't in
    // custom-range mode — otherwise the Custom pill owns the highlight so
    // the user can tell at a glance which range is live.
    Widget buildPresetPill(InsightsPeriod period) {
      final isSelected = !isCustomActive && period == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelect(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? purple : elevated,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: cardBorder),
            ),
            child: Text(
              period.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final customLabel = isCustomActive
        ? _formatCustomRange(customRange!)
        : 'Custom';

    Widget buildCustomPill() {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onPickCustom,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCustomActive ? purple : elevated,
              borderRadius: BorderRadius.circular(20),
              border: isCustomActive ? null : Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 14,
                  color: isCustomActive ? Colors.white : textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  customLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isCustomActive ? FontWeight.w700 : FontWeight.w500,
                    color: isCustomActive ? Colors.white : textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final period in InsightsPeriod.values) buildPresetPill(period),
            buildCustomPill(),
          ],
        ),
      ),
    );
  }

  /// Compact label for the Custom pill when a range is selected.
  /// Same-year:  "Mar 1 – Apr 12"   Cross-year: "Dec 15 '25 – Jan 10 '26"
  String _formatCustomRange(DateTimeRange range) {
    final sameYear = range.start.year == range.end.year;
    if (sameYear) {
      return '${DateFormat('MMM d').format(range.start)} – '
          '${DateFormat('MMM d').format(range.end)}';
    }
    return "${DateFormat("MMM d ''yy").format(range.start)} – "
        "${DateFormat("MMM d ''yy").format(range.end)}";
  }
}


// ---------------------------------------------------------------------------
// Loading State
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  final bool isDark;

  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final shimmerBase = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: index == 0 ? 180 : 120,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [shimmerBase, shimmerBase.withOpacity(0), shimmerBase],
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            );
      }),
    );
  }
}


// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(fontSize: 14, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(color: errorColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Trend Chip — shows delta vs previous period with arrow
// ---------------------------------------------------------------------------

class _TrendChip extends StatelessWidget {
  final double current;
  final double previous;
  final String suffix;

  /// When true, a positive delta is good (green). When false, a negative
  /// delta is good (e.g. body fat decrease).
  final bool positiveIsGood;

  const _TrendChip({
    required this.current,
    required this.previous,
    this.suffix = '',
    this.positiveIsGood = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delta = current - previous;
    if (delta == 0) return const SizedBox.shrink();

    final isPositive = delta > 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood
        ? (isDark ? AppColors.success : AppColorsLight.success)
        : (isDark ? AppColors.coral : AppColorsLight.coral);

    final displayDelta = delta.abs();
    final deltaText = displayDelta == displayDelta.roundToDouble()
        ? '${displayDelta.toInt()}'
        : displayDelta.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$deltaText$suffix',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Overview Card — workouts, time, calories, streak, PRs
// ---------------------------------------------------------------------------

class _OverviewCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _OverviewCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            purple.withOpacity(0.15),
            cyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Workouts completed / scheduled
          Row(
            children: [
              Text(
                '${totals.workoutsCompleted}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              Text(
                ' / ${totals.workoutsScheduled}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'workouts',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const Spacer(),
              if (previousTotals != null)
                _TrendChip(
                  current: totals.workoutsCompleted.toDouble(),
                  previous: previousTotals!.workoutsCompleted.toDouble(),
                ),
            ],
          ),

          // Completion rate bar
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totals.completionRate / 100,
              backgroundColor: elevated,
              valueColor: AlwaysStoppedAnimation(purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${totals.completionRate.toStringAsFixed(0)}% completion rate',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),

          const SizedBox(height: 16),

          // Stats row: time, calories, streak, PRs
          Row(
            children: [
              _MiniStat(
                icon: Icons.timer_outlined,
                value: _formatTime(totals.totalTimeMinutes),
                label: 'time',
                color: cyan,
                isDark: isDark,
                trend: previousTotals != null
                    ? _TrendChip(
                        current: totals.totalTimeMinutes.toDouble(),
                        previous: previousTotals!.totalTimeMinutes.toDouble(),
                        suffix: 'm',
                      )
                    : null,
              ),
              _MiniStat(
                icon: Icons.local_fire_department_outlined,
                value: _formatNumber(totals.totalCalories),
                label: 'kcal',
                color: orange,
                isDark: isDark,
                trend: previousTotals != null
                    ? _TrendChip(
                        current: totals.totalCalories.toDouble(),
                        previous: previousTotals!.totalCalories.toDouble(),
                      )
                    : null,
              ),
              _MiniStat(
                icon: Icons.whatshot_outlined,
                value: '${totals.maxStreak}',
                label: 'streak',
                color: orange,
                isDark: isDark,
              ),
              _MiniStat(
                icon: Icons.trending_up,
                value: '${totals.totalPrs}',
                label: 'PRs',
                color: success,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}


// ---------------------------------------------------------------------------
// Mini Stat — used inside the overview card stats row
// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final Widget? trend;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: textMuted),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            trend!,
          ],
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Nutrition Card
// ---------------------------------------------------------------------------

class _NutritionCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _NutritionCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final adherence = totals.avgNutritionAdherence;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            success.withOpacity(0.15),
            success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.restaurant_outlined, color: success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (adherence != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${adherence.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'adherence',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                ),
                const Spacer(),
                if (previousTotals?.avgNutritionAdherence != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _TrendChip(
                      current: adherence,
                      previous: previousTotals!.avgNutritionAdherence!,
                      suffix: '%',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (adherence / 100).clamp(0.0, 1.0),
                backgroundColor: elevated,
                valueColor: AlwaysStoppedAnimation(success),
                minHeight: 6,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Start tracking nutrition to see insights here',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Recovery Card — readiness score + mood distribution
// ---------------------------------------------------------------------------

class _RecoveryCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _RecoveryCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final readiness = totals.avgReadiness;
    final moods = totals.moodDistribution;
    final hasData = readiness != null || (moods != null && moods.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            orange.withOpacity(0.15),
            orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.battery_charging_full_outlined,
                    color: orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recovery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log your readiness and mood to see recovery insights',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            )
          else ...[
            if (readiness != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    readiness.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      ' / 100',
                      style: TextStyle(fontSize: 16, color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'readiness',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ),
                  const Spacer(),
                  if (previousTotals?.avgReadiness != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _TrendChip(
                        current: readiness,
                        previous: previousTotals!.avgReadiness!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (readiness / 100).clamp(0.0, 1.0),
                  backgroundColor: elevated,
                  valueColor: AlwaysStoppedAnimation(orange),
                  minHeight: 6,
                ),
              ),
            ],

            // Mood distribution chips
            if (moods != null && moods.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mood Distribution',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moods.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_moodIcon(entry.key)} ${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _moodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
      case 'amazing':
        return 'Great';
      case 'good':
        return 'Good';
      case 'okay':
      case 'neutral':
        return 'Okay';
      case 'tired':
      case 'low':
        return 'Tired';
      case 'bad':
      case 'terrible':
        return 'Bad';
      default:
        return mood;
    }
  }
}

