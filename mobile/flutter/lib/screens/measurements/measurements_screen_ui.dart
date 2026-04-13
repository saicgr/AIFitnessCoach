part of 'measurements_screen.dart';

/// UI builder methods extracted from _MeasurementsScreenState
extension _MeasurementsScreenStateUI on _MeasurementsScreenState {

  /// Build a horizontally-scrolling row of ALL derived metrics (BMI, WHR,
  /// Waist-to-Height, FFMI, Lean Mass, Shoulder:Waist, Chest:Waist, Arm/Leg
  /// Symmetry). Cards without data render "—" instead of being hidden, so the
  /// row is always populated and the user can see at-a-glance what's possible.
  Widget _buildDerivedMetricsSection(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final summary = state.summary;
    if (summary == null) return const SizedBox.shrink();

    final computed = computeDerivedMetrics(
      summary: summary,
      heightCm: user?.heightCm,
      gender: user?.gender,
    );

    // Deterministic order — matches the enum declaration so the row reads
    // like a health-checkup glance (composition first, ratios next,
    // symmetry last).
    const ordered = DerivedMetricType.values;

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final type = ordered[i];
          return _DerivedMetricCard(
            type: type,
            result: computed[type],
            elevated: elevated,
            textMuted: textMuted,
            mutedBorder: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            onTap: () => context.push('/measurements/derived/${type.name}'),
          );
        },
      ),
    );
  }


  Widget _buildChart(
    List<MeasurementEntry> history, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Reverse to show oldest first (left to right)
    final reversedHistory = history.reversed.toList();

    final spots = reversedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.getValueInUnit(_isMetric));
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (reversedHistory.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < reversedHistory.length) {
                  final date = reversedHistory[index].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: cyan,
                  strokeWidth: 2,
                  strokeColor: isDark ? AppColors.pureBlack : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cyan.withOpacity(0.3), cyan.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark ? AppColors.nearBlack : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = index < reversedHistory.length
                    ? reversedHistory[index].recordedAt
                    : DateTime.now();
                final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;
                return LineTooltipItem(
                  '${_formatValue(spot.y)} $unit\n${DateFormat('MMM d, y').format(date)}',
                  TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }


  // _buildMeasurementGroupCard removed — the body view + tile grid fully
  // replace the old vertical group list.

  Widget _buildHistoryList(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    if (filteredHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 40, color: textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No history yet',
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = filteredHistory[index];
          final previousValue = index < filteredHistory.length - 1
              ? filteredHistory[index + 1].getValueInUnit(_isMetric)
              : null;
          final currentValue = entry.getValueInUnit(_isMetric);
          final change = previousValue != null ? currentValue - previousValue : null;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 4, 16, 4),
            child: Dismissible(
              key: Key(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) => _confirmDelete(entry),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cyan,
                            ),
                          ),
                          Text(
                            DateFormat('MMM yy').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 9,
                              color: cyan,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('h:mm a').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 8,
                              color: cyan.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatValue(currentValue)} $unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (entry.notes?.isNotEmpty ?? false)
                            Text(
                              entry.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (change != null && change.abs() >= 0.01)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getChangeColor(_selectedType, change).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: _getChangeColor(_selectedType, change),
                            ),
                            Text(
                              _formatValue(change.abs()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getChangeColor(_selectedType, change),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: filteredHistory.length,
      ),
    );
  }

}


/// Compact fixed-width card used inside the horizontally-scrolling derived-
/// metrics row. Renders "—" when [result] is null so every card in the row
/// is always visible (zero-state communicates "you can log these too").
class _DerivedMetricCard extends StatelessWidget {
  final DerivedMetricType type;
  final DerivedMetricResult? result;
  final Color elevated;
  final Color textMuted;
  final Color mutedBorder;
  final VoidCallback onTap;

  const _DerivedMetricCard({
    required this.type,
    required this.result,
    required this.elevated,
    required this.textMuted,
    required this.mutedBorder,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case DerivedMetricType.bmi:
        return Icons.monitor_weight_outlined;
      case DerivedMetricType.leanBodyMass:
        return Icons.fitness_center;
      case DerivedMetricType.ffmi:
        return Icons.bolt_outlined;
      case DerivedMetricType.waistToHipRatio:
      case DerivedMetricType.waistToHeightRatio:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return Icons.straighten;
      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return Icons.compare_arrows;
    }
  }

  String get _shortLabel {
    switch (type) {
      case DerivedMetricType.waistToHipRatio:
        return 'WHR';
      case DerivedMetricType.waistToHeightRatio:
        return 'W:Ht';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Sh:W';
      case DerivedMetricType.chestToWaistRatio:
        return 'Ch:W';
      case DerivedMetricType.leanBodyMass:
        return 'Lean Mass';
      case DerivedMetricType.armSymmetry:
        return 'Arm Sym';
      case DerivedMetricType.legSymmetry:
        return 'Leg Sym';
      default:
        return type.displayName;
    }
  }

  String _formatValue(double v) {
    // Ratios render at 2 decimals, percentages/mass at 1, BMI/FFMI at 1.
    switch (type) {
      case DerivedMetricType.waistToHipRatio:
      case DerivedMetricType.waistToHeightRatio:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return v.toStringAsFixed(2);
      default:
        return v.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = result?.color;
    final hasData = result != null;
    final borderColor = hasData ? accent!.withValues(alpha: 0.3) : mutedBorder;
    final valueColor = hasData ? accent! : textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: valueColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_icon, size: 14, color: valueColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              hasData ? _formatValue(result!.value) : '—',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            if (hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent!.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result!.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              )
            else
              Text(
                'No data',
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
