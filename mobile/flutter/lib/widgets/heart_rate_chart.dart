import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ============================================================================
// ENHANCED HEART RATE WORKOUT CHART
// ============================================================================

/// Enhanced heart rate chart for workout completion screen.
/// Shows zone breakdown, peaks/valleys, Training Effect, and VO2 Max.
class HeartRateWorkoutChart extends StatelessWidget {
  final List<HeartRateReading> readings;
  final int? avgBpm;
  final int? maxBpm;
  final int? minBpm;
  final int maxHR;
  final int? restingHR;
  final int durationMinutes;
  final int? totalCalories;
  final double height;
  final bool showZoneBreakdown;
  final bool showTrainingEffect;
  final bool showVO2Max;
  final bool showFatBurnMetrics;

  const HeartRateWorkoutChart({
    super.key,
    required this.readings,
    this.avgBpm,
    this.maxBpm,
    this.minBpm,
    required this.maxHR,
    this.restingHR,
    required this.durationMinutes,
    this.totalCalories,
    this.height = 180,
    this.showZoneBreakdown = true,
    this.showTrainingEffect = true,
    this.showVO2Max = true,
    this.showFatBurnMetrics = true,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return _buildEmptyState(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Calculate extended stats
    final stats = ExtendedHeartRateStats(
      min: minBpm ?? readings.map((r) => r.bpm).reduce((a, b) => a < b ? a : b),
      max: maxBpm ?? readings.map((r) => r.bpm).reduce((a, b) => a > b ? a : b),
      avg: avgBpm ?? (readings.map((r) => r.bpm).reduce((a, b) => a + b) / readings.length).round(),
      samples: readings,
      maxHR: maxHR,
      restingHR: restingHR,
      durationMinutes: durationMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats chips row
        _buildStatsRow(stats, textPrimary),
        const SizedBox(height: 16),

        // Zone breakdown bar
        if (showZoneBreakdown) ...[
          _buildZoneBreakdown(stats, isDark, textPrimary, textSecondary),
          const SizedBox(height: 16),
        ],

        // Main chart with peaks/valleys
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF44336).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: height,
                child: _buildEnhancedChart(context, stats),
              ),
            ],
          ),
        ),

        // Fat Burn Metrics
        if (showFatBurnMetrics && totalCalories != null) ...[
          const SizedBox(height: 16),
          _buildFatBurnCard(stats, isDark, textPrimary, textSecondary),
        ],

        // Training Effect
        if (showTrainingEffect) ...[
          const SizedBox(height: 16),
          _buildTrainingEffectCard(stats, isDark, textPrimary, textSecondary),
        ],

        // VO2 Max
        if (showVO2Max) ...[
          const SizedBox(height: 16),
          _buildVO2MaxCard(stats, isDark, textPrimary, textSecondary),
        ],
      ],
    );
  }

  Widget _buildStatsRow(ExtendedHeartRateStats stats, Color textPrimary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatChip('Avg', stats.avg, const Color(0xFF2196F3)),
        _buildStatChip('Peak', stats.max, const Color(0xFFF44336), icon: Icons.arrow_upward),
        _buildStatChip('Min', stats.min, const Color(0xFF4CAF50), icon: Icons.arrow_downward),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.favorite, size: 14, color: color),
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

  Widget _buildZoneBreakdown(
    ExtendedHeartRateStats stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final zoneBreakdown = stats.zoneBreakdown;
    final totalSeconds = zoneBreakdown.values.fold(0, (a, b) => a + b);
    if (totalSeconds == 0) return const SizedBox.shrink();

    // Filter zones with time > 0 and sort by time
    final activeZones = zoneBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: activeZones.map((e) {
                final percent = e.value / totalSeconds;
                return Expanded(
                  flex: (percent * 100).round().clamp(1, 100),
                  child: Container(
                    color: Color(e.key.colorValue),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Zone labels
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: activeZones.map((e) {
            final minutes = (e.value / 60).round();
            final percent = ((e.value / totalSeconds) * 100).round();
            return _ZoneLegendItem(
              zone: e.key,
              minutes: minutes,
              percent: percent,
              textSecondary: textSecondary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedChart(BuildContext context, ExtendedHeartRateStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = readings.first.timestamp;

    // Create spots from readings
    final spots = readings.map((r) {
      final x = r.timestamp.difference(startTime).inSeconds.toDouble();
      return FlSpot(x, r.bpm.toDouble());
    }).toList();

    // Calculate chart bounds
    final chartMaxY = (stats.max * 1.1).ceilToDouble();
    final chartMinY = (stats.min * 0.9).floorToDouble();
    final maxX = spots.last.x;

    // Get peaks and valleys
    final peakIndices = stats.peakIndices;
    final valleyIndices = stats.valleyIndices;

    return LineChart(
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
                String label;
                if (maxX > 3600) {
                  final hours = (value / 3600).floor();
                  final mins = ((value % 3600) / 60).floor();
                  label = '${hours}h${mins}m';
                } else if (maxX > 300) {
                  label = '${minutes}m';
                } else {
                  final seconds = (value % 60).toInt();
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
                final zone = getHeartRateZone(spot.y.toInt(), maxHr: maxHR);
                return LineTooltipItem(
                  '${spot.y.toInt()} bpm\n',
                  TextStyle(
                    color: Color(zone.colorValue),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${zone.shortLabel} • $minutes:${seconds.toString().padLeft(2, '0')}',
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
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                // Show dots for peaks and valleys
                final index = spots.indexOf(spot);
                return peakIndices.contains(index) || valleyIndices.contains(index);
              },
              getDotPainter: (spot, percent, barData, index) {
                final spotIndex = spots.indexOf(spot);
                final isPeak = peakIndices.contains(spotIndex);
                final isValley = valleyIndices.contains(spotIndex);

                if (isPeak) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFFF44336),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                } else if (isValley) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFF4CAF50),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(radius: 0, color: Colors.transparent);
              },
            ),
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
    );
  }

  Widget _buildFatBurnCard(
    ExtendedHeartRateStats stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final fatBurnMinutes = stats.fatBurnMinutes.round();
    final fatCalories = totalCalories != null
        ? (totalCalories! * 0.65).round() // Approximate fat calories
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 24,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fat Burning',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fatBurnMinutes min in optimal fat burn zone',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                if (fatCalories != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '~$fatCalories calories from fat',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingEffectCard(
    ExtendedHeartRateStats stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 24,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Training Effect',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTEBox(
                  'Aerobic',
                  stats.aerobicTE,
                  stats.aerobicTELabel,
                  const Color(0xFF2196F3),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTEBox(
                  'Anaerobic',
                  stats.anaerobicTE,
                  stats.anaerobicTELabel,
                  const Color(0xFFFF9800),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTEBox(String label, double value, String effectLabel, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            effectLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVO2MaxCard(
    ExtendedHeartRateStats stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final vo2Max = stats.vo2Max;
    final vo2MaxLevel = stats.vo2MaxLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.air,
              size: 24,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated VO2 Max',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (vo2Max != null && vo2MaxLevel != null) ...[
                  Row(
                    children: [
                      Text(
                        '${vo2Max.toStringAsFixed(1)} ml/kg/min',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vo2MaxLevel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Add resting heart rate for estimation',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTimeInterval(double maxX) {
    if (maxX > 3600) return 600;
    if (maxX > 1800) return 300;
    if (maxX > 600) return 120;
    if (maxX > 300) return 60;
    return 30;
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
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
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No heart rate data recorded',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect a smartwatch to track heart rate',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone legend item with tap-to-learn feature.
class _ZoneLegendItem extends StatelessWidget {
  final HeartRateZone zone;
  final int minutes;
  final int percent;
  final Color textSecondary;

  const _ZoneLegendItem({
    required this.zone,
    required this.minutes,
    required this.percent,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showZoneInfo(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(zone.colorValue),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${zone.shortLabel} ${minutes}m ($percent%)',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showZoneInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(zone.colorValue),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${zone.name} Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zone.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Heart Rate: ${zone.percentageRange} of max',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fat burned: ${(zone.fatCaloriePercent * 100).round()}% of calories',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Color(zone.colorValue),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
