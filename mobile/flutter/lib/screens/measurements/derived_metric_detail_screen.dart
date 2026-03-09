import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';

/// Derived metric types that can be computed from raw measurements
enum DerivedMetricType {
  bmi,
  waistToHipRatio,
  waistToHeightRatio,
  ffmi,
  leanBodyMass,
  shoulderToWaistRatio,
  chestToWaistRatio,
  armSymmetry,
  legSymmetry,
}

/// Detail screen for a derived body metric (BMI, WHR, FFMI, etc.)
/// Shows historical trend chart with health zone lines, stats, and context.
class DerivedMetricDetailScreen extends ConsumerStatefulWidget {
  final String derivedType;

  const DerivedMetricDetailScreen({
    super.key,
    required this.derivedType,
  });

  @override
  ConsumerState<DerivedMetricDetailScreen> createState() =>
      _DerivedMetricDetailScreenState();
}

class _DerivedMetricDetailScreenState
    extends ConsumerState<DerivedMetricDetailScreen> {
  String _selectedPeriod = '30d';
  late DerivedMetricType _type;

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
  ];

  @override
  void initState() {
    super.initState();
    _type = _parseType(widget.derivedType);
    _loadMeasurements();
  }

  DerivedMetricType _parseType(String typeStr) {
    return DerivedMetricType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DerivedMetricType.bmi,
    );
  }

  Future<void> _loadMeasurements() async {
    final auth = ref.read(authStateProvider);
    if (auth.user != null) {
      await ref
          .read(measurementsProvider.notifier)
          .loadAllMeasurements(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsState = ref.watch(measurementsProvider);
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final heightCm = auth.user?.heightCm;
    final gender = auth.user?.gender;

    final history = _computeHistory(
      measurementsState.historyByType,
      _type,
      heightCm,
    );
    final filteredHistory = _filterByPeriod(history);

    final currentValue = measurementsState.summary != null
        ? _computeCurrentValue(
            measurementsState.summary!,
            _type,
            heightCm,
            gender,
          )
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: _loadMeasurements,
              color: cyan,
              child: CustomScrollView(
                slivers: [
                  // Header with title (offset for floating back button)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 12, 16, 8),
                      child: Text(
                        _getDisplayName(_type),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                    ),
                  ),

                  // Current value card
                  SliverToBoxAdapter(
                    child: _buildCurrentValueCard(
                      currentValue: currentValue,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 100.ms),
                  ),

                  // Period selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected =
                              _selectedPeriod == period['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedPeriod = period['value'] as String),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cyan.withOpacity(0.2)
                                      : elevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? cyan : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    period['label'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected ? cyan : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ),

                  // Trend chart with health zone lines
                  SliverToBoxAdapter(
                    child: _buildChartSection(
                      filteredHistory,
                      gender: gender,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 200.ms),
                  ),

                  // Stats row: Min / Avg / Max
                  SliverToBoxAdapter(
                    child: _buildStatsSection(
                      filteredHistory,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 250.ms),
                  ),

                  // Rate of change
                  SliverToBoxAdapter(
                    child: _buildRateOfChange(
                      filteredHistory,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 300.ms),
                  ),

                  // Health context card
                  if (currentValue != null)
                    SliverToBoxAdapter(
                      child: _buildHealthContextCard(
                        currentValue: currentValue,
                        isDark: isDark,
                        elevated: elevated,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        cyan: cyan,
                      ).animate().fadeIn(delay: 350.ms),
                    ),

                  // Input values card ("Based On")
                  SliverToBoxAdapter(
                    child: _buildInputValuesCard(
                      measurementsState: measurementsState,
                      heightCm: heightCm,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 400.ms),
                  ),

                  // History header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HISTORY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${filteredHistory.length} entries',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                  ),

                  // History list
                  _buildHistoryList(
                    filteredHistory,
                    isDark: isDark,
                    elevated: elevated,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cyan: cyan,
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Floating back button
            Positioned(
              top: 8,
              left: 8,
              child: GlassBackButton(
                onTap: () {
                  HapticService.light();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // ═════════════════════════════════════════════════════════════════
  // Data Computation Helpers
  // ═════════════════════════════════════════════════════════════════

  /// Compute historical derived metric values from raw measurement data.
  /// Returns entries sorted oldest-first for charting.
  List<({DateTime date, double value})> _computeHistory(
    Map<MeasurementType, List<MeasurementEntry>> historyByType,
    DerivedMetricType type,
    double? heightCm,
  ) {
    final results = <({DateTime date, double value})>[];

    switch (type) {
      case DerivedMetricType.bmi:
        // BMI is stored on weight entries
        final weightEntries = historyByType[MeasurementType.weight] ?? [];
        for (final entry in weightEntries) {
          if (entry.bmi != null) {
            results.add((date: entry.recordedAt, value: entry.bmi!));
          } else if (heightCm != null && heightCm > 0) {
            final heightM = heightCm / 100;
            final weightKg = entry.getValueInUnit(true);
            results.add(
              (date: entry.recordedAt, value: weightKg / (heightM * heightM)),
            );
          }
        }
        break;

      case DerivedMetricType.waistToHipRatio:
        // WHR is stored on waist entries
        final waistEntries = historyByType[MeasurementType.waist] ?? [];
        for (final entry in waistEntries) {
          if (entry.waistToHipRatio != null) {
            results
                .add((date: entry.recordedAt, value: entry.waistToHipRatio!));
          }
        }
        // Also try pairing waist + hips on same date
        if (results.isEmpty) {
          _addPairedHistory(
            results,
            historyByType[MeasurementType.waist] ?? [],
            historyByType[MeasurementType.hips] ?? [],
            (waist, hips) => hips > 0 ? waist / hips : null,
          );
        }
        break;

      case DerivedMetricType.waistToHeightRatio:
        // WHtR is stored on waist entries
        final waistEntries = historyByType[MeasurementType.waist] ?? [];
        for (final entry in waistEntries) {
          if (entry.waistToHeightRatio != null) {
            results.add(
                (date: entry.recordedAt, value: entry.waistToHeightRatio!));
          }
        }
        // Also try computing from waist + height
        if (results.isEmpty && heightCm != null && heightCm > 0) {
          for (final entry in waistEntries) {
            final waistCm = entry.getValueInUnit(true);
            results.add((date: entry.recordedAt, value: waistCm / heightCm));
          }
        }
        break;

      case DerivedMetricType.ffmi:
        if (heightCm == null || heightCm <= 0) break;
        final heightM = heightCm / 100;
        _addPairedHistory(
          results,
          historyByType[MeasurementType.weight] ?? [],
          historyByType[MeasurementType.bodyFat] ?? [],
          (weightKg, bodyFat) {
            if (bodyFat <= 0 || bodyFat >= 100) return null;
            final leanMass = weightKg * (1 - bodyFat / 100);
            return leanMass / (heightM * heightM) + 6.1 * (1.8 - heightM);
          },
        );
        break;

      case DerivedMetricType.leanBodyMass:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.weight] ?? [],
          historyByType[MeasurementType.bodyFat] ?? [],
          (weightKg, bodyFat) {
            if (bodyFat <= 0 || bodyFat >= 100) return null;
            return weightKg * (1 - bodyFat / 100);
          },
        );
        break;

      case DerivedMetricType.shoulderToWaistRatio:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.shoulders] ?? [],
          historyByType[MeasurementType.waist] ?? [],
          (shoulders, waist) => waist > 0 ? shoulders / waist : null,
        );
        break;

      case DerivedMetricType.chestToWaistRatio:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.chest] ?? [],
          historyByType[MeasurementType.waist] ?? [],
          (chest, waist) => waist > 0 ? chest / waist : null,
        );
        break;

      case DerivedMetricType.armSymmetry:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.bicepsLeft] ?? [],
          historyByType[MeasurementType.bicepsRight] ?? [],
          (left, right) {
            if (left <= 0 || right <= 0) return null;
            final larger = left > right ? left : right;
            final smaller = left > right ? right : left;
            return (smaller / larger) * 100; // percentage symmetry
          },
        );
        break;

      case DerivedMetricType.legSymmetry:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.thighLeft] ?? [],
          historyByType[MeasurementType.thighRight] ?? [],
          (left, right) {
            if (left <= 0 || right <= 0) return null;
            final larger = left > right ? left : right;
            final smaller = left > right ? right : left;
            return (smaller / larger) * 100; // percentage symmetry
          },
        );
        break;
    }

    // Sort oldest first for charting
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  /// Helper: pairs two measurement lists by same-day date and computes a value.
  void _addPairedHistory(
    List<({DateTime date, double value})> results,
    List<MeasurementEntry> listA,
    List<MeasurementEntry> listB,
    double? Function(double a, double b) compute,
  ) {
    // Build a map of date (day-only) -> metric value for listB
    final bByDate = <String, MeasurementEntry>{};
    for (final entry in listB) {
      final key = DateFormat('yyyy-MM-dd').format(entry.recordedAt);
      bByDate.putIfAbsent(key, () => entry);
    }

    for (final entryA in listA) {
      final key = DateFormat('yyyy-MM-dd').format(entryA.recordedAt);
      final entryB = bByDate[key];
      if (entryB != null) {
        final valueA = entryA.getValueInUnit(true);
        final valueB = entryB.getValueInUnit(true);
        final computed = compute(valueA, valueB);
        if (computed != null && computed.isFinite) {
          results.add((date: entryA.recordedAt, value: computed));
        }
      }
    }
  }

  /// Compute the current derived metric value from the latest summary data.
  ({double value, String label, Color color, String info})? _computeCurrentValue(
    MeasurementsSummary summary,
    DerivedMetricType type,
    double? heightCm,
    String? gender,
  ) {
    final isMale = gender?.toLowerCase() == 'male';

    switch (type) {
      case DerivedMetricType.bmi:
        final weight = summary.latestByType[MeasurementType.weight];
        if (weight == null || heightCm == null || heightCm <= 0) return null;
        final heightM = heightCm / 100;
        final bmi = weight.getValueInUnit(true) / (heightM * heightM);
        final cat = _getBmiCategory(bmi);
        return (value: bmi, label: cat.label, color: cat.color, info: cat.info);

      case DerivedMetricType.waistToHipRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        final hips = summary.latestByType[MeasurementType.hips];
        if (waist == null || hips == null) return null;
        final waistCm = waist.getValueInUnit(true);
        final hipsCm = hips.getValueInUnit(true);
        if (hipsCm <= 0) return null;
        final whr = waistCm / hipsCm;
        final cat = _getWhrCategory(whr, isMale: isMale);
        return (value: whr, label: cat.label, color: cat.color, info: cat.info);

      case DerivedMetricType.waistToHeightRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        if (waist == null || heightCm == null || heightCm <= 0) return null;
        final whtr = waist.getValueInUnit(true) / heightCm;
        final cat = _getWhtrCategory(whtr);
        return (
          value: whtr,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.ffmi:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight == null ||
            bodyFat == null ||
            heightCm == null ||
            heightCm <= 0) return null;
        final weightKg = weight.getValueInUnit(true);
        final bf = bodyFat.value;
        if (bf <= 0 || bf >= 100) return null;
        final heightM = heightCm / 100;
        final leanMass = weightKg * (1 - bf / 100);
        final ffmi =
            leanMass / (heightM * heightM) + 6.1 * (1.8 - heightM);
        final cat = _getFfmiCategory(ffmi, isMale: isMale);
        return (
          value: ffmi,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.leanBodyMass:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight == null || bodyFat == null) return null;
        final weightKg = weight.getValueInUnit(true);
        final bf = bodyFat.value;
        if (bf <= 0 || bf >= 100) return null;
        final lbm = weightKg * (1 - bf / 100);
        return (
          value: lbm,
          label: 'Lean Mass',
          color: AppColors.success,
          info:
              'Your lean body mass is the total weight minus fat. Higher lean mass generally indicates more muscle.',
        );

      case DerivedMetricType.shoulderToWaistRatio:
        final shoulders = summary.latestByType[MeasurementType.shoulders];
        final waist = summary.latestByType[MeasurementType.waist];
        if (shoulders == null || waist == null) return null;
        final ratio =
            shoulders.getValueInUnit(true) / waist.getValueInUnit(true);
        if (!ratio.isFinite) return null;
        final cat = _getShoulderWaistCategory(ratio, isMale: isMale);
        return (
          value: ratio,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.chestToWaistRatio:
        final chest = summary.latestByType[MeasurementType.chest];
        final waist = summary.latestByType[MeasurementType.waist];
        if (chest == null || waist == null) return null;
        final ratio =
            chest.getValueInUnit(true) / waist.getValueInUnit(true);
        if (!ratio.isFinite) return null;
        final cat = _getChestWaistCategory(ratio);
        return (
          value: ratio,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.armSymmetry:
        final left = summary.latestByType[MeasurementType.bicepsLeft];
        final right = summary.latestByType[MeasurementType.bicepsRight];
        if (left == null || right == null) return null;
        final l = left.getValueInUnit(true);
        final r = right.getValueInUnit(true);
        if (l <= 0 || r <= 0) return null;
        final larger = l > r ? l : r;
        final smaller = l > r ? r : l;
        final symmetry = (smaller / larger) * 100;
        final cat = _getSymmetryCategory(symmetry);
        return (
          value: symmetry,
          label: cat.label,
          color: cat.color,
          info:
              'Arm symmetry compares your left and right bicep measurements. ${cat.info}',
        );

      case DerivedMetricType.legSymmetry:
        final left = summary.latestByType[MeasurementType.thighLeft];
        final right = summary.latestByType[MeasurementType.thighRight];
        if (left == null || right == null) return null;
        final l = left.getValueInUnit(true);
        final r = right.getValueInUnit(true);
        if (l <= 0 || r <= 0) return null;
        final larger = l > r ? l : r;
        final smaller = l > r ? r : l;
        final symmetry = (smaller / larger) * 100;
        final cat = _getSymmetryCategory(symmetry);
        return (
          value: symmetry,
          label: cat.label,
          color: cat.color,
          info:
              'Leg symmetry compares your left and right thigh measurements. ${cat.info}',
        );
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // Category & Threshold Helpers
  // ═════════════════════════════════════════════════════════════════

  ({String label, Color color, String info}) _getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return (
        label: 'Underweight',
        color: AppColors.orange,
        info:
            'A BMI below 18.5 is considered underweight. Consider consulting a healthcare professional about nutrition strategies.',
      );
    } else if (bmi < 25) {
      return (
        label: 'Normal',
        color: AppColors.success,
        info:
            'A BMI between 18.5 and 24.9 is considered a healthy weight range. Keep up the good work!',
      );
    } else if (bmi < 30) {
      return (
        label: 'Overweight',
        color: AppColors.orange,
        info:
            'A BMI between 25 and 29.9 is considered overweight. Note: BMI does not differentiate muscle from fat.',
      );
    } else {
      return (
        label: 'Obese',
        color: AppColors.error,
        info:
            'A BMI of 30 or above is classified as obese. Consider consulting a healthcare professional for guidance.',
      );
    }
  }

  ({String label, Color color, String info}) _getWhrCategory(double whr,
      {bool isMale = true}) {
    if (isMale) {
      if (whr < 0.90) {
        return (
          label: 'Low Risk',
          color: AppColors.success,
          info:
              'A WHR below 0.90 for men indicates low cardiovascular risk. WHO considers this a healthy range.',
        );
      } else if (whr < 1.0) {
        return (
          label: 'Moderate Risk',
          color: AppColors.orange,
          info:
              'A WHR between 0.90 and 1.0 for men indicates moderate health risk. Focus on waist-reducing exercises.',
        );
      } else {
        return (
          label: 'High Risk',
          color: AppColors.error,
          info:
              'A WHR above 1.0 for men indicates increased cardiovascular risk. Consider lifestyle changes.',
        );
      }
    } else {
      if (whr < 0.80) {
        return (
          label: 'Low Risk',
          color: AppColors.success,
          info:
              'A WHR below 0.80 for women indicates low cardiovascular risk. WHO considers this a healthy range.',
        );
      } else if (whr < 0.85) {
        return (
          label: 'Moderate Risk',
          color: AppColors.orange,
          info:
              'A WHR between 0.80 and 0.85 for women indicates moderate health risk. Focus on waist-reducing exercises.',
        );
      } else {
        return (
          label: 'High Risk',
          color: AppColors.error,
          info:
              'A WHR above 0.85 for women indicates increased cardiovascular risk. Consider lifestyle changes.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getWhtrCategory(double whtr) {
    if (whtr < 0.4) {
      return (
        label: 'Underweight',
        color: AppColors.orange,
        info:
            'A WHtR below 0.4 may indicate being underweight. Consider consulting a healthcare professional.',
      );
    } else if (whtr < 0.5) {
      return (
        label: 'Healthy',
        color: AppColors.success,
        info:
            'A WHtR between 0.4 and 0.5 is considered healthy. Your waist is less than half your height.',
      );
    } else if (whtr < 0.6) {
      return (
        label: 'Overweight',
        color: AppColors.orange,
        info:
            'A WHtR between 0.5 and 0.6 indicates increased abdominal fat. Focus on reducing waist circumference.',
      );
    } else {
      return (
        label: 'Obese',
        color: AppColors.error,
        info:
            'A WHtR above 0.6 indicates significant abdominal fat and increased health risk.',
      );
    }
  }

  ({String label, Color color, String info}) _getFfmiCategory(double ffmi,
      {bool isMale = true}) {
    if (isMale) {
      if (ffmi < 18) {
        return (
          label: 'Below Average',
          color: AppColors.orange,
          info:
              'An FFMI below 18 for men is below average. Focus on progressive overload and adequate protein.',
        );
      } else if (ffmi < 20) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'An FFMI of 18-20 for men is average. You have a solid foundation of muscle.',
        );
      } else if (ffmi < 22) {
        return (
          label: 'Above Average',
          color: AppColors.success,
          info:
              'An FFMI of 20-22 for men is above average. You have notably more muscle than most.',
        );
      } else if (ffmi < 25) {
        return (
          label: 'Excellent',
          color: AppColors.info,
          info:
              'An FFMI of 22-25 for men is excellent, near the natural limit. Outstanding muscular development.',
        );
      } else {
        return (
          label: 'Superior',
          color: AppColors.purple,
          info:
              'An FFMI above 25 for men exceeds the typical natural limit (~25). Exceptional muscularity.',
        );
      }
    } else {
      if (ffmi < 14) {
        return (
          label: 'Below Average',
          color: AppColors.orange,
          info:
              'An FFMI below 14 for women is below average. Focus on resistance training and nutrition.',
        );
      } else if (ffmi < 16) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'An FFMI of 14-16 for women is average. You have a solid foundation of muscle.',
        );
      } else if (ffmi < 18) {
        return (
          label: 'Above Average',
          color: AppColors.success,
          info:
              'An FFMI of 16-18 for women is above average. Impressive muscular development.',
        );
      } else if (ffmi < 21) {
        return (
          label: 'Excellent',
          color: AppColors.info,
          info:
              'An FFMI of 18-21 for women is excellent. Outstanding lean mass for your height.',
        );
      } else {
        return (
          label: 'Superior',
          color: AppColors.purple,
          info:
              'An FFMI above 21 for women is exceptional. Elite-level muscularity.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getShoulderWaistCategory(
      double ratio,
      {bool isMale = true}) {
    if (isMale) {
      if (ratio < 1.4) {
        return (
          label: 'Narrow',
          color: AppColors.orange,
          info:
              'A shoulder-to-waist ratio below 1.4 for men indicates a narrow frame. Target shoulder exercises to build width.',
        );
      } else if (ratio < 1.6) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'A shoulder-to-waist ratio of 1.4-1.6 for men is average. Good overall proportions.',
        );
      } else {
        return (
          label: 'V-Taper',
          color: AppColors.info,
          info:
              'A shoulder-to-waist ratio above 1.6 for men indicates a strong V-taper. Excellent aesthetics!',
        );
      }
    } else {
      if (ratio < 1.3) {
        return (
          label: 'Narrow',
          color: AppColors.orange,
          info:
              'A shoulder-to-waist ratio below 1.3 for women indicates narrower shoulders relative to waist.',
        );
      } else if (ratio < 1.5) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'A shoulder-to-waist ratio of 1.3-1.5 for women is average. Well-balanced proportions.',
        );
      } else {
        return (
          label: 'Athletic',
          color: AppColors.info,
          info:
              'A shoulder-to-waist ratio above 1.5 for women indicates athletic build with broader shoulders.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getChestWaistCategory(
      double ratio) {
    if (ratio < 1.1) {
      return (
        label: 'Narrow',
        color: AppColors.orange,
        info:
            'A chest-to-waist ratio below 1.1 indicates a narrow chest relative to waist. Focus on chest and back exercises.',
      );
    } else if (ratio < 1.3) {
      return (
        label: 'Average',
        color: AppColors.success,
        info:
            'A chest-to-waist ratio of 1.1-1.3 is average. Healthy proportions between chest and waist.',
      );
    } else {
      return (
        label: 'Athletic',
        color: AppColors.info,
        info:
            'A chest-to-waist ratio above 1.3 indicates a well-developed chest relative to waist. Great proportions!',
      );
    }
  }

  ({String label, Color color, String info}) _getSymmetryCategory(
      double symmetry) {
    if (symmetry >= 97) {
      return (
        label: 'Excellent',
        color: AppColors.success,
        info:
            'Near-perfect symmetry (97%+). Both sides are very well balanced.',
      );
    } else if (symmetry >= 93) {
      return (
        label: 'Good',
        color: AppColors.success,
        info:
            'Good symmetry (93-97%). Minor difference that is within normal range.',
      );
    } else if (symmetry >= 88) {
      return (
        label: 'Moderate',
        color: AppColors.orange,
        info:
            'Moderate asymmetry (88-93%). Consider adding unilateral exercises to address the imbalance.',
      );
    } else {
      return (
        label: 'Imbalanced',
        color: AppColors.error,
        info:
            'Significant asymmetry (below 88%). Focus on unilateral training for the weaker side.',
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // Health Zone Lines for Chart
  // ═════════════════════════════════════════════════════════════════

  List<HorizontalLine> _getHealthZoneLines(
      DerivedMetricType type, String? gender) {
    final isMale = gender?.toLowerCase() == 'male';

    switch (type) {
      case DerivedMetricType.bmi:
        return [
          _zoneLine(18.5, 'Underweight', Colors.blue),
          _zoneLine(25, 'Overweight', Colors.amber),
          _zoneLine(30, 'Obese', Colors.red),
        ];

      case DerivedMetricType.waistToHipRatio:
        if (isMale) {
          return [
            _zoneLine(0.90, 'Moderate', Colors.amber),
            _zoneLine(1.0, 'High Risk', Colors.red),
          ];
        } else {
          return [
            _zoneLine(0.80, 'Moderate', Colors.amber),
            _zoneLine(0.85, 'High Risk', Colors.red),
          ];
        }

      case DerivedMetricType.waistToHeightRatio:
        return [
          _zoneLine(0.4, 'Underweight', Colors.blue),
          _zoneLine(0.5, 'Overweight', Colors.amber),
          _zoneLine(0.6, 'Obese', Colors.red),
        ];

      case DerivedMetricType.ffmi:
        if (isMale) {
          return [
            _zoneLine(18, 'Average', Colors.amber),
            _zoneLine(20, 'Above Avg', Colors.green),
            _zoneLine(25, 'Natural Limit', Colors.red),
          ];
        } else {
          return [
            _zoneLine(14, 'Average', Colors.amber),
            _zoneLine(16, 'Above Avg', Colors.green),
            _zoneLine(21, 'Natural Limit', Colors.red),
          ];
        }

      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return [
          _zoneLine(88, 'Imbalanced', Colors.red),
          _zoneLine(93, 'Moderate', Colors.amber),
          _zoneLine(97, 'Good', Colors.green),
        ];

      // No standard health zones for these
      case DerivedMetricType.leanBodyMass:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return [];
    }
  }

  HorizontalLine _zoneLine(double y, String label, Color color) {
    return HorizontalLine(
      y: y,
      color: color.withOpacity(0.3),
      strokeWidth: 1,
      dashArray: [5, 5],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
        labelResolver: (_) => label,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // Input Values (Based On)
  // ═════════════════════════════════════════════════════════════════

  List<({String label, String value})> _getInputValues(
      MeasurementsState state, double? heightCm) {
    final summary = state.summary;
    if (summary == null) return [];

    final inputs = <({String label, String value})>[];

    switch (_type) {
      case DerivedMetricType.bmi:
        final weight = summary.latestByType[MeasurementType.weight];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.waistToHipRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        final hips = summary.latestByType[MeasurementType.hips];
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        if (hips != null) {
          inputs.add((
            label: 'Hips',
            value: '${_formatValue(hips.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.waistToHeightRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.ffmi:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (bodyFat != null) {
          inputs.add((
            label: 'Body Fat',
            value: '${_formatValue(bodyFat.value)}%'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.leanBodyMass:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (bodyFat != null) {
          inputs.add((
            label: 'Body Fat',
            value: '${_formatValue(bodyFat.value)}%'
          ));
        }
        break;

      case DerivedMetricType.shoulderToWaistRatio:
        final shoulders = summary.latestByType[MeasurementType.shoulders];
        final waist = summary.latestByType[MeasurementType.waist];
        if (shoulders != null) {
          inputs.add((
            label: 'Shoulders',
            value: '${_formatValue(shoulders.getValueInUnit(true))} cm'
          ));
        }
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.chestToWaistRatio:
        final chest = summary.latestByType[MeasurementType.chest];
        final waist = summary.latestByType[MeasurementType.waist];
        if (chest != null) {
          inputs.add((
            label: 'Chest',
            value: '${_formatValue(chest.getValueInUnit(true))} cm'
          ));
        }
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.armSymmetry:
        final left = summary.latestByType[MeasurementType.bicepsLeft];
        final right = summary.latestByType[MeasurementType.bicepsRight];
        if (left != null) {
          inputs.add((
            label: 'Biceps (L)',
            value: '${_formatValue(left.getValueInUnit(true))} cm'
          ));
        }
        if (right != null) {
          inputs.add((
            label: 'Biceps (R)',
            value: '${_formatValue(right.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.legSymmetry:
        final left = summary.latestByType[MeasurementType.thighLeft];
        final right = summary.latestByType[MeasurementType.thighRight];
        if (left != null) {
          inputs.add((
            label: 'Thigh (L)',
            value: '${_formatValue(left.getValueInUnit(true))} cm'
          ));
        }
        if (right != null) {
          inputs.add((
            label: 'Thigh (R)',
            value: '${_formatValue(right.getValueInUnit(true))} cm'
          ));
        }
        break;
    }

    return inputs;
  }

  // ═════════════════════════════════════════════════════════════════
  // Utility Helpers
  // ═════════════════════════════════════════════════════════════════

  String _getDisplayName(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'BMI';
      case DerivedMetricType.waistToHipRatio:
        return 'Waist-to-Hip Ratio';
      case DerivedMetricType.waistToHeightRatio:
        return 'Waist-to-Height Ratio';
      case DerivedMetricType.ffmi:
        return 'FFMI';
      case DerivedMetricType.leanBodyMass:
        return 'Lean Body Mass';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Shoulder-to-Waist Ratio';
      case DerivedMetricType.chestToWaistRatio:
        return 'Chest-to-Waist Ratio';
      case DerivedMetricType.armSymmetry:
        return 'Arm Symmetry';
      case DerivedMetricType.legSymmetry:
        return 'Leg Symmetry';
    }
  }

  String _getUnit(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'kg/m\u00B2';
      case DerivedMetricType.waistToHipRatio:
      case DerivedMetricType.waistToHeightRatio:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return 'ratio';
      case DerivedMetricType.ffmi:
        return 'kg/m\u00B2';
      case DerivedMetricType.leanBodyMass:
        return 'kg';
      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return '%';
    }
  }

  String _getInsufficientDataHint(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'Log weight measurements to see BMI trend';
      case DerivedMetricType.waistToHipRatio:
        return 'Log waist and hip measurements on the same day';
      case DerivedMetricType.waistToHeightRatio:
        return 'Log waist measurements to see trend';
      case DerivedMetricType.ffmi:
        return 'Log weight and body fat on the same day';
      case DerivedMetricType.leanBodyMass:
        return 'Log weight and body fat on the same day';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Log shoulder and waist measurements on the same day';
      case DerivedMetricType.chestToWaistRatio:
        return 'Log chest and waist measurements on the same day';
      case DerivedMetricType.armSymmetry:
        return 'Log left and right biceps on the same day';
      case DerivedMetricType.legSymmetry:
        return 'Log left and right thigh on the same day';
    }
  }

  List<({DateTime date, double value})> _filterByPeriod(
      List<({DateTime date, double value})> history) {
    if (_selectedPeriod == 'all') return history;

    final days = _periods
        .firstWhere((p) => p['value'] == _selectedPeriod)['days'] as int;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.date.isAfter(cutoff)).toList();
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble() && value.abs() < 1000) {
      return value.toInt().toString();
    }
    // Use 2 decimal places for ratios, 1 for everything else
    if (_type == DerivedMetricType.waistToHipRatio ||
        _type == DerivedMetricType.waistToHeightRatio ||
        _type == DerivedMetricType.shoulderToWaistRatio ||
        _type == DerivedMetricType.chestToWaistRatio) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(1);
  }

  Color _getChangeColor(double change) {
    // For BMI and WHR/WHtR, decrease is generally good
    if (_type == DerivedMetricType.bmi ||
        _type == DerivedMetricType.waistToHipRatio ||
        _type == DerivedMetricType.waistToHeightRatio) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    // For FFMI, lean mass, symmetry, and ratios, increase is good
    return change > 0 ? AppColors.success : AppColors.error;
  }

  Color _getRateColor(double rate, bool isDark) {
    if (rate.abs() < 0.01) {
      return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
    return _getChangeColor(rate);
  }
}

// ═════════════════════════════════════════════════════════════════
// Shared Widgets
// ═════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMuted
                : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
