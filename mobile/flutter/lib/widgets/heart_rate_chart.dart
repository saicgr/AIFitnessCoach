import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/providers/heart_rate_provider.dart';

/// Line chart displaying heart rate over workout duration.
/// Uses fl_chart library for smooth, animated charts.
class HeartRateChart extends StatelessWidget {
  final List<HeartRateReading> readings;
  final int? avgBpm;
  final int? maxBpm;
  final int? minBpm;
  final double height;

  const HeartRateChart({
    super.key,
    required this.readings,
    this.avgBpm,
    this.maxBpm,
    this.minBpm,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startTime = readings.first.timestamp;

    // Create spots from readings
    final spots = readings.map((r) {
      final x = r.timestamp.difference(startTime).inSeconds.toDouble();
      return FlSpot(x, r.bpm.toDouble());
    }).toList();

    // Calculate chart bounds
    final bpmValues = readings.map((r) => r.bpm).toList();
    final chartMaxY = (bpmValues.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();
    final chartMinY = (bpmValues.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
    final maxX = spots.last.x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        if (avgBpm != null || maxBpm != null || minBpm != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (avgBpm != null)
                  _buildStatChip('Avg', avgBpm!, const Color(0xFF2196F3)),
                if (maxBpm != null) ...[
                  const SizedBox(width: 8),
                  _buildStatChip('Peak', maxBpm!, const Color(0xFFF44336)),
                ],
                if (minBpm != null) ...[
                  const SizedBox(width: 8),
                  _buildStatChip('Min', minBpm!, const Color(0xFF4CAF50)),
                ],
              ],
            ),
          ),

        // Chart
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateTimeInterval(maxX),
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final minutes = (value / 60).floor();
                      final seconds = (value % 60).toInt();
                      String label;
                      if (maxX > 3600) {
                        // Over an hour, show hours:minutes
                        final hours = (value / 3600).floor();
                        final mins = ((value % 3600) / 60).floor();
                        label = '${hours}h${mins}m';
                      } else if (maxX > 300) {
                        // Over 5 minutes, show just minutes
                        label = '${minutes}m';
                      } else {
                        // Under 5 minutes, show minutes:seconds
                        label = '$minutes:${seconds.toString().padLeft(2, '0')}';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: chartMinY,
              maxY: chartMaxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => isDark ? Colors.grey[800]! : Colors.white,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final minutes = (spot.x / 60).floor();
                      final seconds = (spot.x % 60).toInt();
                      final zone = getHeartRateZone(spot.y.toInt());
                      return LineTooltipItem(
                        '${spot.y.toInt()} bpm\n',
                        TextStyle(
                          color: Color(zone.colorValue),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '$minutes:${seconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: const Color(0xFFF44336),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF44336).withValues(alpha: 0.3),
                        const Color(0xFFF44336).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTimeInterval(double maxX) {
    if (maxX > 3600) return 600; // 10 minutes for hour+ workouts
    if (maxX > 1800) return 300; // 5 minutes for 30min+ workouts
    if (maxX > 600) return 120; // 2 minutes for 10min+ workouts
    if (maxX > 300) return 60; // 1 minute for 5min+ workouts
    return 30; // 30 seconds for short workouts
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.watch_off,
              size: 32,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'No heart rate data',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wear your watch during workouts to track heart rate',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact heart rate summary card with mini chart.
/// Shows stats and a small preview chart.
class HeartRateSummaryCard extends StatelessWidget {
  final List<HeartRateReading> readings;
  final int? avgBpm;
  final int? maxBpm;
  final int? minBpm;
  final VoidCallback? onTap;

  const HeartRateSummaryCard({
    super.key,
    required this.readings,
    this.avgBpm,
    this.maxBpm,
    this.minBpm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final hasData = readings.isNotEmpty;

    return GestureDetector(
      onTap: hasData ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasData
                ? const Color(0xFFF44336).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (hasData ? const Color(0xFFF44336) : Colors.grey)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 20,
                    color: hasData ? const Color(0xFFF44336) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heart Rate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        hasData
                            ? '${readings.length} readings'
                            : 'No data recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasData && onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: textSecondary,
                    size: 20,
                  ),
              ],
            ),

            if (hasData) ...[
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildStat('Avg', avgBpm, textPrimary, textSecondary),
                  const SizedBox(width: 24),
                  _buildStat('Max', maxBpm, textPrimary, textSecondary),
                  const SizedBox(width: 24),
                  _buildStat('Min', minBpm, textPrimary, textSecondary),
                ],
              ),

              const SizedBox(height: 16),

              // Mini chart
              SizedBox(
                height: 60,
                child: _buildMiniChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int? value, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value != null ? '$value bpm' : '--',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    if (readings.isEmpty) return const SizedBox.shrink();

    final startTime = readings.first.timestamp;
    final spots = readings.map((r) {
      final x = r.timestamp.difference(startTime).inSeconds.toDouble();
      return FlSpot(x, r.bpm.toDouble());
    }).toList();

    final bpmValues = readings.map((r) => r.bpm).toList();
    final chartMaxY = (bpmValues.reduce((a, b) => a > b ? a : b) * 1.05).ceilToDouble();
    final chartMinY = (bpmValues.reduce((a, b) => a < b ? a : b) * 0.95).floorToDouble();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: chartMinY,
        maxY: chartMaxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFFF44336),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF44336).withValues(alpha: 0.2),
                  const Color(0xFFF44336).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
