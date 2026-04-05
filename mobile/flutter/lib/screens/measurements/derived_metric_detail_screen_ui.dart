part of 'derived_metric_detail_screen.dart';

/// UI builder methods extracted from _DerivedMetricDetailScreenState
extension _DerivedMetricDetailScreenStateUI on _DerivedMetricDetailScreenState {

  // ─────────────────────────────────────────────────────────────────
  // Current Value Card
  // ─────────────────────────────────────────────────────────────────

  Widget _buildCurrentValueCard({
    required ({double value, String label, Color color, String info})? currentValue,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyan.withOpacity(0.15),
            cyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue != null
                    ? _formatValue(currentValue.value)
                    : '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: currentValue?.color ?? cyan,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' ${_getUnit(_type)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (currentValue != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentValue.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentValue.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: currentValue.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  // Chart Section with Health Zone Lines
  // ─────────────────────────────────────────────────────────────────

  Widget _buildChartSection(
    List<({DateTime date, double value})> history, {
    required String? gender,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 40, color: textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Insufficient data',
                          style: TextStyle(color: textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getInsufficientDataHint(_type),
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _buildChart(
                    history,
                    gender: gender,
                    cyan: cyan,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildChart(
    List<({DateTime date, double value})> history, {
    required String? gender,
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Already sorted oldest-first from _computeHistory
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final values = spots.map((s) => s.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    // Include health zone lines in min/max calculation
    final zoneLines = _getHealthZoneLines(_type, gender);
    double minY = dataMin;
    double maxY = dataMax;
    for (final line in zoneLines) {
      if (line.y < minY) minY = line.y;
      if (line.y > maxY) maxY = line.y;
    }
    final range = maxY - minY;
    minY = minY - range * 0.1;
    maxY = maxY + range * 0.1;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

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
        extraLinesData: ExtraLinesData(horizontalLines: zoneLines),
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
              interval: (history.length / 4)
                  .ceil()
                  .toDouble()
                  .clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < history.length) {
                  final date = history[index].date;
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
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  strokeColor:
                      isDark ? AppColors.pureBlack : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  cyan.withOpacity(0.3),
                  cyan.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) =>
                isDark ? AppColors.nearBlack : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = index < history.length
                    ? history[index].date
                    : DateTime.now();
                return LineTooltipItem(
                  '${_formatValue(spot.y)} ${_getUnit(_type)}\n${DateFormat('MMM d, y').format(date)}',
                  TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
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


  // ─────────────────────────────────────────────────────────────────
  // Stats Section: Min / Avg / Max
  // ─────────────────────────────────────────────────────────────────

  Widget _buildStatsSection(
    List<({DateTime date, double value})> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    final values = history.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = _getUnit(_type);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Min',
              value: '${_formatValue(min)} $unit',
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          Expanded(
            child: _StatItem(
              label: 'Avg',
              value: '${_formatValue(avg)} $unit',
              color: cyan,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          Expanded(
            child: _StatItem(
              label: 'Max',
              value: '${_formatValue(max)} $unit',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  // Rate of Change
  // ─────────────────────────────────────────────────────────────────

  Widget _buildRateOfChange(
    List<({DateTime date, double value})> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.length < 2) return const SizedBox.shrink();

    final first = history.first;
    final last = history.last;
    final totalChange = last.value - first.value;
    final daysBetween = last.date.difference(first.date).inDays;

    if (daysBetween <= 0) return const SizedBox.shrink();

    final weeklyRate = totalChange / (daysBetween / 7);
    final monthlyRate = totalChange / (daysBetween / 30);

    String formatRate(double rate) {
      final sign = rate >= 0 ? '+' : '';
      return '$sign${_formatValue(rate)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Weekly Rate',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatRate(weeklyRate)}/week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getRateColor(weeklyRate, isDark),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Monthly Rate',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatRate(monthlyRate)}/month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getRateColor(monthlyRate, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  // Health Context Card
  // ─────────────────────────────────────────────────────────────────

  Widget _buildHealthContextCard({
    required ({double value, String label, Color color, String info}) currentValue,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            currentValue.color.withOpacity(0.12),
            currentValue.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentValue.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${_getDisplayName(_type)}: ${_formatValue(currentValue.value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: currentValue.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currentValue.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: currentValue.color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentValue.info,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  // Input Values Card ("Based On")
  // ─────────────────────────────────────────────────────────────────

  Widget _buildInputValuesCard({
    required MeasurementsState measurementsState,
    required double? heightCm,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final inputs = _getInputValues(measurementsState, heightCm);
    if (inputs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BASED ON',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...inputs.map((input) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      input.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    Text(
                      input.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  // History List
  // ─────────────────────────────────────────────────────────────────

  Widget _buildHistoryList(
    List<({DateTime date, double value})> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.isEmpty) {
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

    // Reverse so newest is at the top for the list
    final reversedHistory = history.reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = reversedHistory[index];
          final previousValue = index < reversedHistory.length - 1
              ? reversedHistory[index + 1].value
              : null;
          final change =
              previousValue != null ? entry.value - previousValue : null;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(entry.date),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cyan,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(entry.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_formatValue(entry.value)} ${_getUnit(_type)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (change != null && change.abs() >= 0.01)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getChangeColor(change).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: _getChangeColor(change),
                          ),
                          Text(
                            _formatValue(change.abs()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getChangeColor(change),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        childCount: reversedHistory.length,
      ),
    );
  }

}
