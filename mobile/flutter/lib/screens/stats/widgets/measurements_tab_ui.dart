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

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
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
                        _selectedType.displayName.toUpperCase(),
                        style: ZType.lbl(15,
                            color: textPrimary, letterSpacing: 1.2),
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
                Flexible(
                  child: StatNumber(
                    value: _formatValue(latest.value),
                    unit: unit,
                    size: StatType.primary,
                    color: textPrimary,
                    alignment: Alignment.centerRight,
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
                    style: ZType.data(13,
                        color: _getChangeColor(_selectedType, change)),
                  ),
                ],
              ] else
                Text(AppLocalizations.of(context)!.measurementsTabUiValue(unit), style: ZType.data(15, color: textMuted)),
            ],
          ),

          // 30-day trend delta + sparkline for the selected metric, when it
          // maps to a unified TrendMetric and has >=2 real points. Renders
          // nothing otherwise (no fabricated flat line).
          _buildTrendStrip(cyan: cyan),

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
    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Text(
                    AppLocalizations.of(context).measurementsTabUiChooseMetric.toUpperCase(),
                    style: ZType.lbl(14, color: textPrimary, letterSpacing: 1.5),
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
                                  AppLocalizations.of(context).measurementsTabUiNoData,
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
    // Memoize: the EWMA series + both FlSpot lists are expensive to rebuild;
    // reuse the cached LineChartData when the chart inputs are unchanged.
    final memoKey = _buildChartMemoKey(data, isDark);
    if (_chartMemoKey == memoKey && _chartMemoData != null) {
      return LineChart(_chartMemoData!);
    }

    final rawValues = data.map((e) => e.value).toList();
    final ewmaValues = _computeEWMA(rawValues);

    final rawSpots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();
    final ewmaSpots = ewmaValues.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value)).toList();

    final allValues = [...rawValues, ...ewmaValues];
    final minY = allValues.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.02;

    final chartData = LineChartData(
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
                style: ZType.lbl(9, color: textMuted, letterSpacing: 0.5),
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
                      style: ZType.lbl(8, color: textMuted, letterSpacing: 0.5),
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
                    ZType.data(12,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColorsLight.textPrimary),
                  );
                }
                final date = index < data.length ? data[index].recordedAt : DateTime.now();
                return LineTooltipItem(
                  '${_formatValue(spot.y)} kg\n${DateFormat('MMM d').format(date)}',
                  ZType.data(12,
                      weight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary),
                );
              }).toList();
            },
          ),
        ),
    );

    // Cache the freshly-built chart data for the next rebuild.
    _chartMemoKey = memoKey;
    _chartMemoData = chartData;
    return LineChart(chartData);
  }

  /// Maps the currently-selected body measurement onto the unified trend
  /// engine's [TrendMetric], when one exists. Only measurements with a real
  /// time-series source in [TrendMetric] are mapped; anything else returns
  /// null so the trend strip is simply hidden.
  TrendMetric? _trendMetricFor(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return TrendMetric.weight;
      case MeasurementType.bodyFat:
        return TrendMetric.bodyFat;
      case MeasurementType.chest:
        return TrendMetric.chest;
      case MeasurementType.waist:
        return TrendMetric.waist;
      case MeasurementType.hips:
        return TrendMetric.hips;
      case MeasurementType.neck:
        return TrendMetric.neck;
      case MeasurementType.shoulders:
        return TrendMetric.shoulders;
      case MeasurementType.bicepsLeft:
        return TrendMetric.bicepsLeft;
      case MeasurementType.bicepsRight:
        return TrendMetric.bicepsRight;
      case MeasurementType.thighLeft:
        return TrendMetric.thighLeft;
      case MeasurementType.thighRight:
        return TrendMetric.thighRight;
      case MeasurementType.calfLeft:
        return TrendMetric.calfLeft;
      case MeasurementType.calfRight:
        return TrendMetric.calfRight;
      case MeasurementType.forearmLeft:
        return TrendMetric.forearmLeft;
      case MeasurementType.forearmRight:
        return TrendMetric.forearmRight;
    }
  }

  /// A 30-day glanceable trend: plain-language delta line on the left, a mini
  /// sparkline on the right. Sourced from the unified [statTrendProvider]; the
  /// metric's own [GoodDirection] colors the delta. Hidden entirely when the
  /// metric is unmapped or has fewer than 2 real points.
  Widget _buildTrendStrip({required Color cyan}) {
    final metric = _trendMetricFor(_selectedType);
    if (metric == null) return const SizedBox.shrink();

    final async = ref.watch(
      statTrendProvider(TrendSeriesKey(metric, TrendRange.d30)),
    );
    return async.maybeWhen(
      data: (t) {
        if (!t.hasTrend) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: StatDeltaLine(
                  change: t.change!,
                  good: t.goodDirection,
                  unit: t.unit,
                  period: 'in 30 days',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Sparkline(points: t.points, color: cyan, height: 32),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

}
