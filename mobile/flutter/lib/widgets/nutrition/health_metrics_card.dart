import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/health_service.dart';

/// Provider for blood glucose data
/// Note: Removed autoDispose to prevent refetching on navigation
final bloodGlucoseDataProvider = FutureProvider<List<BloodGlucoseReading>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  return await healthService.getBloodGlucoseData(days: 7);
});

/// Provider for insulin data
/// Note: Removed autoDispose to prevent refetching on navigation
final insulinDataProvider = FutureProvider<List<InsulinDose>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  return await healthService.getInsulinData(days: 7);
});

/// Provider for daily glucose summary
/// Note: Removed autoDispose to prevent refetching on navigation
final dailyGlucoseSummaryProvider = FutureProvider<BloodGlucoseSummary>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  return await healthService.getDailyGlucoseSummary();
});

/// Health Metrics Card - Shows blood glucose and insulin tracking
class HealthMetricsCard extends ConsumerWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const HealthMetricsCard({
    super.key,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(dailyGlucoseSummaryProvider);
    final glucoseReadingsAsync = ref.watch(bloodGlucoseDataProvider);

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap ?? () => _showHealthMetricsSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bloodtype_outlined,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'BLOOD GLUCOSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            glucoseAsync.when(
              loading: () => _buildLoadingState(textMuted),
              error: (_, __) => _buildNoDataState(textMuted),
              data: (summary) {
                if (!summary.hasData) {
                  return _buildNoDataState(textMuted);
                }
                return _buildGlucoseSummary(summary, textPrimary, textMuted);
              },
            ),
            const SizedBox(height: 16),
            // Mini chart
            glucoseReadingsAsync.when(
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox(height: 60),
              data: (readings) {
                if (readings.isEmpty) {
                  return const SizedBox(height: 60);
                }
                return SizedBox(
                  height: 60,
                  child: _buildMiniChart(readings, textMuted),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Loading health data...',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildNoDataState(Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No glucose data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect Health Connect to see your blood glucose',
          style: TextStyle(fontSize: 12, color: textMuted.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildGlucoseSummary(
    BloodGlucoseSummary summary,
    Color textPrimary,
    Color textMuted,
  ) {
    final statusColor = _getStatusColor(summary.averageGlucose);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  summary.averageGlucose.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'mg/dL',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            Text(
              'Average today',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatPill(
              '${summary.timeInRange.toStringAsFixed(0)}%',
              'In range',
              const Color(0xFF6BCB77),
              textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.readingCount} readings',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatPill(String value, String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(List<BloodGlucoseReading> readings, Color textMuted) {
    if (readings.length < 2) {
      return Center(
        child: Text(
          'Not enough data for chart',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      );
    }

    // Take last 24 readings
    final chartReadings = readings.take(24).toList().reversed.toList();

    final spots = chartReadings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: 50,
        maxY: 200,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFF6B6B),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
            ),
          ),
          // Target range indicator lines
          LineChartBarData(
            spots: List.generate(chartReadings.length, (i) => FlSpot(i.toDouble(), 70)),
            isCurved: false,
            color: textMuted.withOpacity(0.3),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
          LineChartBarData(
            spots: List.generate(chartReadings.length, (i) => FlSpot(i.toDouble(), 180)),
            isCurved: false,
            color: textMuted.withOpacity(0.3),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double glucose) {
    if (glucose < 70) return const Color(0xFFE74C3C); // Low - red
    if (glucose <= 100) return const Color(0xFF6BCB77); // Normal - green
    if (glucose <= 125) return const Color(0xFFF39C12); // Elevated - yellow/orange
    if (glucose <= 180) return const Color(0xFFFF6B6B); // High - coral
    return const Color(0xFFE74C3C); // Very high - red
  }

  void _showHealthMetricsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthMetricsDetailSheet(isDark: isDark),
    );
  }
}

/// Detailed Health Metrics Sheet
class _HealthMetricsDetailSheet extends ConsumerWidget {
  final bool isDark;

  const _HealthMetricsDetailSheet({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(bloodGlucoseDataProvider);
    final insulinAsync = ref.watch(insulinDataProvider);
    final summaryAsync = ref.watch(dailyGlucoseSummaryProvider);

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bloodtype_outlined,
                    color: Color(0xFFFF6B6B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Health Metrics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Summary
                  summaryAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildErrorCard('Unable to load summary', elevated, textMuted),
                    data: (summary) => _buildSummaryCard(
                      summary,
                      elevated,
                      textPrimary,
                      textMuted,
                      cardBorder,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Readings
                  Text(
                    'RECENT READINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  glucoseAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildErrorCard('Unable to load readings', elevated, textMuted),
                    data: (readings) {
                      if (readings.isEmpty) {
                        return _buildEmptyCard(
                          'No blood glucose readings',
                          'Connect a glucose monitor via Health Connect',
                          elevated,
                          textMuted,
                          cardBorder,
                        );
                      }
                      return _buildReadingsList(readings, elevated, textPrimary, textMuted, cardBorder);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Insulin Data
                  Text(
                    'INSULIN DELIVERY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  insulinAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildErrorCard('Unable to load insulin data', elevated, textMuted),
                    data: (doses) {
                      if (doses.isEmpty) {
                        return _buildEmptyCard(
                          'No insulin data',
                          'Insulin delivery data from connected devices will appear here',
                          elevated,
                          textMuted,
                          cardBorder,
                        );
                      }
                      return _buildInsulinList(doses, elevated, textPrimary, textMuted, cardBorder);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BloodGlucoseSummary summary,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    if (!summary.hasData) {
      return _buildEmptyCard(
        'No data for today',
        'Blood glucose readings will appear here',
        elevated,
        textMuted,
        cardBorder,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile(
                summary.averageGlucose.toStringAsFixed(0),
                'Average',
                'mg/dL',
                _getStatusColor(summary.averageGlucose),
                textMuted,
              ),
              Container(
                width: 1,
                height: 60,
                color: cardBorder,
              ),
              _buildMetricTile(
                summary.minGlucose.toStringAsFixed(0),
                'Min',
                'mg/dL',
                textPrimary,
                textMuted,
              ),
              Container(
                width: 1,
                height: 60,
                color: cardBorder,
              ),
              _buildMetricTile(
                summary.maxGlucose.toStringAsFixed(0),
                'Max',
                'mg/dL',
                textPrimary,
                textMuted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Time in range bars
          _buildTimeInRangeBars(summary, textPrimary, textMuted),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String value,
    String label,
    String unit,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor),
        ),
      ],
    );
  }

  Widget _buildTimeInRangeBars(
    BloodGlucoseSummary summary,
    Color textPrimary,
    Color textMuted,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Text('Time in Range', style: TextStyle(fontSize: 14, color: textPrimary)),
            const Spacer(),
            Text(summary.controlStatus, style: TextStyle(fontSize: 12, color: textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              // Below range (red)
              if (summary.timeBelowRange > 0)
                Expanded(
                  flex: (summary.timeBelowRange * 10).round(),
                  child: Container(
                    height: 8,
                    color: const Color(0xFFE74C3C),
                  ),
                ),
              // In range (green)
              if (summary.timeInRange > 0)
                Expanded(
                  flex: (summary.timeInRange * 10).round(),
                  child: Container(
                    height: 8,
                    color: const Color(0xFF6BCB77),
                  ),
                ),
              // Above range (orange)
              if (summary.timeAboveRange > 0)
                Expanded(
                  flex: (summary.timeAboveRange * 10).round(),
                  child: Container(
                    height: 8,
                    color: const Color(0xFFF39C12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRangeLegend('Below', summary.timeBelowRange, const Color(0xFFE74C3C), textMuted),
            _buildRangeLegend('In range', summary.timeInRange, const Color(0xFF6BCB77), textMuted),
            _buildRangeLegend('Above', summary.timeAboveRange, const Color(0xFFF39C12), textMuted),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeLegend(String label, double percent, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${percent.toStringAsFixed(0)}% $label',
          style: TextStyle(fontSize: 11, color: textColor),
        ),
      ],
    );
  }

  Widget _buildReadingsList(
    List<BloodGlucoseReading> readings,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    // Take last 10 readings
    final displayReadings = readings.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: displayReadings.asMap().entries.map((entry) {
          final reading = entry.value;
          final isLast = entry.key == displayReadings.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(reading.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(reading.recordedAt),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                    ),
                    if (reading.mealContext != null)
                      Text(
                        _formatMealContext(reading.mealContext!),
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  reading.value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(reading.value),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'mg/dL',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsulinList(
    List<InsulinDose> doses,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    // Take last 10 doses
    final displayDoses = doses.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: displayDoses.asMap().entries.map((entry) {
          final dose = entry.value;
          final isLast = entry.key == displayDoses.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF3498DB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(dose.deliveredAt),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                    ),
                    Text(
                      dose.source,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  dose.units.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'units',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorCard(String message, Color elevated, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: textMuted)),
      ),
    );
  }

  Widget _buildEmptyCard(
    String title,
    String subtitle,
    Color elevated,
    Color textMuted,
    Color cardBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bloodtype_outlined,
            size: 40,
            color: textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: textMuted.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatMealContext(String context) {
    switch (context) {
      case 'before_breakfast':
        return 'Before breakfast';
      case 'after_breakfast':
        return 'After breakfast';
      case 'before_lunch':
        return 'Before lunch';
      case 'after_lunch':
        return 'After lunch';
      case 'before_dinner':
        return 'Before dinner';
      case 'after_dinner':
        return 'After dinner';
      default:
        return 'General';
    }
  }

  Color _getStatusColor(double glucose) {
    if (glucose < 70) return const Color(0xFFE74C3C);
    if (glucose <= 100) return const Color(0xFF6BCB77);
    if (glucose <= 125) return const Color(0xFFF39C12);
    if (glucose <= 180) return const Color(0xFFFF6B6B);
    return const Color(0xFFE74C3C);
  }
}
