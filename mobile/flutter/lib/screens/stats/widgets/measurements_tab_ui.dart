part of 'measurements_tab.dart';

/// UI builder methods extracted from _MeasurementsTabState
extension _MeasurementsTabStateUI on _MeasurementsTabState {

  Widget _buildHeroChart({
    required MeasurementsState state,
    required MeasurementsSummary? summary,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filtered = _filterByPeriod(history).reversed.toList();
    final latest = summary?.latestByType[_selectedType];
    final change = summary?.changeFromPrevious[_selectedType];
    final unit = _selectedType == MeasurementType.weight
        ? 'kg'
        : (_selectedType == MeasurementType.bodyFat ? '%' : 'cm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: type picker (left), latest value + change (right)
          Row(
            children: [
              InkWell(
                onTap: () => _showMetricPicker(context, cyan, textPrimary, isDark),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedType.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down,
                          size: 22, color: textMuted),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (latest != null) ...[
                Text(
                  '${_formatValue(latest.value)} $unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (change != null && change.abs() >= 0.1) ...[
                  const SizedBox(width: 6),
                  Icon(
                    change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: _getChangeColor(_selectedType, change),
                  ),
                  Text(
                    _formatValue(change.abs()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getChangeColor(_selectedType, change),
                    ),
                  ),
                ],
              ] else
                Text('— $unit', style: TextStyle(fontSize: 16, color: textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Time range chips
          _buildTimeRangeChips(cyan: cyan, elevated: elevated, textMuted: textMuted, cardBorder: cardBorder),
          const SizedBox(height: 12),

          // Chart area with animated transitions
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildHeroChartContent(
                key: ValueKey('${_selectedType.name}_$_selectedPeriod'),
                filtered: filtered,
                isDark: isDark,
                textMuted: textMuted,
                cyan: cyan,
                unit: unit,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showMetricPicker(
      BuildContext context, Color accent, Color textPrimary, bool isDark) {
    final state = ref.read(measurementsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Text(
                    'Choose metric',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: MeasurementType.values.map((type) {
                        final isSelected = type == _selectedType;
                        final hasData =
                            (state.historyByType[type]?.isNotEmpty) ?? false;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? accent
                                : textPrimary.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          title: Text(
                            type.displayName,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: hasData
                              ? null
                              : Text(
                                  'no data',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        textPrimary.withValues(alpha: 0.4),
                                  ),
                                ),
                          onTap: () {
                            HapticService.light();
                            setState(() => _selectedType = type);
                            Navigator.pop(sheetCtx);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightLineChart(
    List<MeasurementEntry> data, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    final rawValues = data.map((e) => e.value).toList();
    final ewmaValues = _computeEWMA(rawValues);

    final rawSpots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();
    final ewmaSpots = ewmaValues.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value)).toList();

    final allValues = [...rawValues, ...ewmaValues];
    final minY = allValues.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.02;

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
              interval: (data.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(data[index].recordedAt),
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
          // Raw data - thin dotted line
          LineChartBarData(
            spots: rawSpots,
            isCurved: true,
            color: cyan.withOpacity(0.4),
            barWidth: 1.5,
            dashArray: [4, 4],
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: cyan.withOpacity(0.5),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // EWMA trend - thick solid line
          LineChartBarData(
            spots: ewmaSpots,
            isCurved: true,
            color: cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
                if (spot.barIndex == 1) {
                  return LineTooltipItem(
                    'Trend: ${_formatValue(spot.y)} kg',
                    TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                final date = index < data.length ? data[index].recordedAt : DateTime.now();
                return LineTooltipItem(
                  '${_formatValue(spot.y)} kg\n${DateFormat('MMM d').format(date)}',
                  TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
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

}
