part of 'measurement_detail_screen.dart';

/// UI builder methods extracted from _MeasurementDetailScreenState
extension _MeasurementDetailScreenStateUI on _MeasurementDetailScreenState {

  Widget _buildChart(
    List<MeasurementEntry> history, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Reverse to show oldest first (left to right)
    final reversedHistory = history.reversed.toList();

    // Use time-based X coordinates (milliseconds since epoch) so the chart
    // correctly represents the time range of the selected period.
    final now = DateTime.now();
    final double maxX = now.millisecondsSinceEpoch.toDouble();
    final double minX;
    if (_selectedPeriod == 'all' && reversedHistory.isNotEmpty) {
      // For "All", start from the oldest entry (with a small left padding)
      final oldest = reversedHistory.first.recordedAt;
      final rangePadding = now.difference(oldest).inMilliseconds * 0.05;
      minX = oldest.millisecondsSinceEpoch.toDouble() - rangePadding;
    } else {
      minX = _periodStartDate().millisecondsSinceEpoch.toDouble();
    }

    final spots = reversedHistory.map((entry) {
      return FlSpot(
        entry.recordedAt.millisecondsSinceEpoch.toDouble(),
        entry.getValueInUnit(_isMetric),
      );
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final values = spots.map((s) => s.y).toList();
    final rawMinY = values.reduce((a, b) => a < b ? a : b);
    final rawMaxY = values.reduce((a, b) => a > b ? a : b);
    // If all values are the same, add a fixed padding so the chart isn't flat
    final valuePadding = rawMinY == rawMaxY ? 5.0 : (rawMaxY - rawMinY) * 0.15;
    var minY = rawMinY - valuePadding;
    var maxY = rawMaxY + valuePadding;

    // Extend minY/maxY to encompass health zone lines
    final zoneLines = _getHealthZoneLines();
    for (final line in zoneLines) {
      if (line.y < minY) minY = line.y - valuePadding * 0.5;
      if (line.y > maxY) maxY = line.y + valuePadding * 0.5;
    }

    // Build line bars - EWMA trend line for weight with 3+ data points
    final bool showEWMA = _type == MeasurementType.weight && values.length >= 3;
    final List<LineChartBarData> lineBars = [];

    if (showEWMA) {
      final ewmaValues = _computeEWMA(values, alpha: 0.3);
      final ewmaSpots = <FlSpot>[];
      for (int i = 0; i < ewmaValues.length; i++) {
        ewmaSpots.add(FlSpot(
          reversedHistory[i].recordedAt.millisecondsSinceEpoch.toDouble(),
          ewmaValues[i],
        ));
      }

      // Raw data line: thin and dotted
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: cyan.withOpacity(0.5),
          barWidth: 1.5,
          dashArray: [4, 4],
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: cyan.withOpacity(0.5),
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.pureBlack : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );

      // EWMA trend line: thick solid with gradient fill
      lineBars.add(
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
      );
    } else {
      // Default single line
      lineBars.add(
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
      );
    }

    // Calculate appropriate date label interval
    final totalMs = maxX - minX;
    final totalDays = totalMs / (1000 * 60 * 60 * 24);
    // Aim for ~4-5 labels on the X axis
    final intervalDays = (totalDays / 4).ceil().clamp(1, 365);
    final intervalMs = intervalDays * 24 * 60 * 60 * 1000.0;

    // Pick date format based on range
    final String datePattern;
    if (totalDays <= 14) {
      datePattern = 'M/d';
    } else if (totalDays <= 180) {
      datePattern = 'MMM d';
    } else {
      datePattern = 'MMM yy';
    }

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
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
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                // Skip edge labels to prevent clipping
                if (value <= minY || value >= maxY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(fontSize: 10, color: textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: intervalMs,
              getTitlesWidget: (value, meta) {
                // Skip labels outside range, and suppress labels that land too
                // close to the min/max edges — fl_chart anchors interval ticks
                // to the epoch, which can place a tick a day or two away from
                // minX/maxX and visually overlap the edge label.
                if (value < minX || value > maxX) {
                  return const SizedBox.shrink();
                }
                final edgeThreshold = intervalMs * 0.5;
                if ((value - minX).abs() < edgeThreshold ||
                    (maxX - value).abs() < edgeThreshold) {
                  // Only keep the label if it IS the exact edge (maxX).
                  if (value != maxX && value != minX) {
                    return const SizedBox.shrink();
                  }
                }
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat(datePattern).format(date),
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        extraLinesData: ExtraLinesData(horizontalLines: zoneLines),
        lineBarsData: lineBars,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (spot) =>
                isDark ? AppColors.nearBlack : Colors.white,
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                final unit =
                    _isMetric ? _type.metricUnit : _type.imperialUnit;
                return LineTooltipItem(
                  '${_formatValue(spot.y)} $unit\n${DateFormat('MMM d, y').format(date)}',
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


  Widget _buildRateOfChangeCard(
    List<MeasurementEntry> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.length < 2) return const SizedBox.shrink();

    final values = history.map((e) => e.getValueInUnit(_isMetric)).toList();
    final first = values.last; // oldest (history is newest-first)
    final last = values.first; // newest
    final totalChange = last - first;
    final daySpan = history.first.recordedAt.difference(history.last.recordedAt).inDays;
    if (daySpan <= 0) return const SizedBox.shrink();

    final weeklyRate = totalChange / (daySpan / 7);
    final monthlyRate = totalChange / (daySpan / 30);
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

    // For weight/body fat, decrease is good
    final isDecreaseGood = _type == MeasurementType.weight || _type == MeasurementType.bodyFat;
    Color rateColor(double rate) {
      if (rate.abs() < 0.01) return textMuted;
      final isGood = isDecreaseGood ? rate < 0 : rate > 0;
      return isGood ? AppColors.success : AppColors.error;
    }
    String formatRate(double rate) {
      final sign = rate >= 0 ? '+' : '';
      return '$sign${rate.toStringAsFixed(1)} $unit';
    }

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
          Text('Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Weekly', style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(weeklyRate >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16, color: rateColor(weeklyRate)),
                        const SizedBox(width: 4),
                        Text(formatRate(weeklyRate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rateColor(weeklyRate))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              Expanded(
                child: Column(
                  children: [
                    Text('Monthly', style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(monthlyRate >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16, color: rateColor(monthlyRate)),
                        const SizedBox(width: 4),
                        Text(formatRate(monthlyRate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rateColor(monthlyRate))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildHealthContextCard({
    required MeasurementEntry? latest,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (latest == null) return const SizedBox.shrink();
    final value = latest.getValueInUnit(_isMetric);
    final g = _userGender?.toLowerCase() ?? 'male';

    final String title;
    final String subtitle;
    final Color contextColor;
    final String source;

    switch (_type) {
      case MeasurementType.bodyFat:
        title = 'Your Body Fat: ${_formatValue(value)}%';
        if (g == 'female') {
          if (value < 14) { subtitle = 'Essential fat range'; contextColor = Colors.red; source = 'ACE'; }
          else if (value < 21) { subtitle = 'Athletes range (14-20%)'; contextColor = Colors.green; source = 'ACE'; }
          else if (value < 25) { subtitle = 'Fitness range (21-24%)'; contextColor = Colors.cyan; source = 'ACE'; }
          else if (value < 32) { subtitle = 'Acceptable range (25-31%)'; contextColor = Colors.amber; source = 'ACE'; }
          else { subtitle = 'Above acceptable range'; contextColor = Colors.red; source = 'ACE'; }
        } else {
          if (value < 6) { subtitle = 'Essential fat range'; contextColor = Colors.red; source = 'ACE'; }
          else if (value < 14) { subtitle = 'Athletes range (6-13%)'; contextColor = Colors.green; source = 'ACE'; }
          else if (value < 18) { subtitle = 'Fitness range (14-17%)'; contextColor = Colors.cyan; source = 'ACE'; }
          else if (value < 25) { subtitle = 'Acceptable range (18-24%)'; contextColor = Colors.amber; source = 'ACE'; }
          else { subtitle = 'Above acceptable range'; contextColor = Colors.red; source = 'ACE'; }
        }
      case MeasurementType.waist:
        final unitLabel = _isMetric ? 'cm' : 'in';
        title = 'Your Waist: ${_formatValue(value)} $unitLabel';
        final cmValue = _isMetric ? value : value * 2.54;
        if (g == 'female') {
          if (cmValue < 80) { subtitle = 'Low Risk - below 80cm threshold'; contextColor = Colors.green; source = 'CDC/WHO'; }
          else if (cmValue < 88) { subtitle = 'Moderate Risk (80-88cm)'; contextColor = Colors.amber; source = 'CDC/WHO'; }
          else { subtitle = 'High Risk - above 88cm threshold'; contextColor = Colors.red; source = 'CDC/WHO'; }
        } else {
          if (cmValue < 94) { subtitle = 'Low Risk - below 94cm threshold'; contextColor = Colors.green; source = 'CDC/WHO'; }
          else if (cmValue < 102) { subtitle = 'Moderate Risk (94-102cm)'; contextColor = Colors.amber; source = 'CDC/WHO'; }
          else { subtitle = 'High Risk - above 102cm threshold'; contextColor = Colors.red; source = 'CDC/WHO'; }
        }
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [contextColor.withOpacity(0.15), contextColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: contextColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: contextColor, fontWeight: FontWeight.w600)),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Source: $source guideline', style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        ],
      ),
    );
  }


  Widget _buildRelatedMetrics({
    required MeasurementsSummary? summary,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (summary == null) return const SizedBox.shrink();

    // Define related metrics per type
    final Map<MeasurementType, List<MeasurementType>> relatedMap = {
      MeasurementType.weight: [MeasurementType.bodyFat, MeasurementType.waist, MeasurementType.chest],
      MeasurementType.bodyFat: [MeasurementType.weight, MeasurementType.waist],
      MeasurementType.waist: [MeasurementType.hips, MeasurementType.shoulders, MeasurementType.chest],
      MeasurementType.chest: [MeasurementType.waist, MeasurementType.shoulders],
      MeasurementType.hips: [MeasurementType.waist, MeasurementType.thighLeft],
      MeasurementType.shoulders: [MeasurementType.waist, MeasurementType.chest],
      MeasurementType.bicepsLeft: [MeasurementType.bicepsRight, MeasurementType.forearmLeft],
      MeasurementType.bicepsRight: [MeasurementType.bicepsLeft, MeasurementType.forearmRight],
      MeasurementType.thighLeft: [MeasurementType.thighRight, MeasurementType.calfLeft],
      MeasurementType.thighRight: [MeasurementType.thighLeft, MeasurementType.calfRight],
    };

    final related = relatedMap[_type];
    if (related == null || related.isEmpty) return const SizedBox.shrink();

    // Filter to only metrics that have data
    final available = related.where((t) => summary.latestByType.containsKey(t)).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('RELATED METRICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available.map((t) {
              final entry = summary.latestByType[t]!;
              final change = summary.changeFromPrevious[t];
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  // Navigate to that metric's detail
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeasurementDetailScreen(measurementType: t.name),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.displayName, style: TextStyle(fontSize: 11, color: textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatValue(entry.value)} ${entry.unit}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                      if (change != null && change.abs() >= 0.1) ...[
                        const SizedBox(width: 8),
                        Icon(
                          change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: _getRelatedChangeColor(t, change),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildHistoryList(
    List<MeasurementEntry> history, {
    required String unit,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = history[index];
          final previousValue = index < history.length - 1
              ? history[index + 1].getValueInUnit(_isMetric)
              : null;
          final currentValue = entry.getValueInUnit(_isMetric);
          final change =
              previousValue != null ? currentValue - previousValue : null;

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
            ),
          );
        },
        childCount: history.length,
      ),
    );
  }

}
