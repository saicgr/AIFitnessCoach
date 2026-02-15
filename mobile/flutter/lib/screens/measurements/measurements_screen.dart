import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../settings/dialogs/export_dialog.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  MeasurementType _selectedType = MeasurementType.weight;
  String _selectedGroup = 'Body Composition';
  String _selectedPeriod = '30d';
  bool _isMetric = true;
  bool _loadingTimedOut = false;
  DateTimeRange? _customDateRange;

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
    {'label': 'Custom', 'value': 'custom', 'days': 0},
  ];

  // Group measurement types by body part
  static const _measurementGroups = [
    {
      'title': 'Body Composition',
      'types': [MeasurementType.weight, MeasurementType.bodyFat],
    },
    {
      'title': 'Upper Body',
      'types': [
        MeasurementType.neck,
        MeasurementType.shoulders,
        MeasurementType.chest,
        MeasurementType.bicepsLeft,
        MeasurementType.bicepsRight,
        MeasurementType.forearmLeft,
        MeasurementType.forearmRight,
      ],
    },
    {
      'title': 'Core',
      'types': [MeasurementType.waist, MeasurementType.hips],
    },
    {
      'title': 'Lower Body',
      'types': [
        MeasurementType.thighLeft,
        MeasurementType.thighRight,
        MeasurementType.calfLeft,
        MeasurementType.calfRight,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    // Reset timeout flag when starting a new load
    if (mounted) {
      setState(() => _loadingTimedOut = false);
    }

    final auth = ref.read(authStateProvider);
    if (auth.user != null) {
      // Start a timeout timer - if loading takes more than 12 seconds, show timeout state
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted) {
          final state = ref.read(measurementsProvider);
          if (state.isLoading) {
            setState(() => _loadingTimedOut = true);
          }
        }
      });

      await ref.read(measurementsProvider.notifier).loadAllMeasurements(auth.user!.id);
    } else {
      // If no user, mark as not loading to prevent infinite spinner
      debugPrint('⚠️ No user found, cannot load measurements');
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsState = ref.watch(measurementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Body Measurements',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          // Export button
                          GestureDetector(
                            onTap: () => _showExportSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: elevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(Icons.upload_outlined, color: cyan, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit toggle
                          GestureDetector(
                            onTap: () => setState(() => _isMetric = !_isMetric),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: elevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Text(
                                _isMetric ? 'Metric' : 'Imperial',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cyan,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Period selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected = _selectedPeriod == period['value'];
                          final isCustom = period['value'] == 'custom';
                          return Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (isCustom) {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: _customDateRange,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _customDateRange = picked;
                                      _selectedPeriod = 'custom';
                                    });
                                  }
                                } else {
                                  setState(() => _selectedPeriod = period['value'] as String);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? cyan.withOpacity(0.2) : elevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? cyan : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: isCustom && isSelected && _customDateRange != null
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              period['label'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: cyan,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: cyan.withOpacity(0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          period['label'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? cyan : textSecondary,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ),

                  // BMI & WHR Cards
                  SliverToBoxAdapter(
                    child: _buildDerivedMetricsSection(
                      measurementsState,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 130.ms),
                  ),

                  // Selected measurement chart
                  SliverToBoxAdapter(
                    child: _buildChartSection(
                      measurementsState,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 150.ms),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Measurement type selector (horizontal scroll)
                  SliverToBoxAdapter(
                    child: _buildTypeSelector(
                      measurementsState,
                      isDark: isDark,
                      elevated: elevated,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      cardBorder: cardBorder,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 200.ms),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Measurement summary cards by group
                  ..._measurementGroups.expand((group) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          group['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMeasurementGroupCard(
                          measurementsState,
                          group['types'] as List<MeasurementType>,
                          isDark: isDark,
                          elevated: elevated,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                          cardBorder: cardBorder,
                          cyan: cyan,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ),
                  ]),

                  // History list for selected type
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HISTORY - ${_selectedType.displayName.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (measurementsState.historyByType[_selectedType]?.isNotEmpty ?? false)
                            Text(
                              '${measurementsState.historyByType[_selectedType]?.length ?? 0} entries',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ),

                  _buildHistoryList(
                    measurementsState,
                    isDark: isDark,
                    elevated: elevated,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                    cardBorder: cardBorder,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeasurementSheet(context),
        backgroundColor: cyan,
        foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
        child: const Icon(Icons.add),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  /// Build BMI and Waist-to-Hip Ratio cards
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
    final latestWeight = state.summary?.latestByType[MeasurementType.weight];
    final latestWaist = state.summary?.latestByType[MeasurementType.waist];
    final latestHips = state.summary?.latestByType[MeasurementType.hips];

    // Calculate BMI if we have height and weight
    double? bmi;
    String? bmiCategory;
    Color? bmiColor;
    if (user?.heightCm != null && user!.heightCm! > 0 && latestWeight != null) {
      final heightM = user.heightCm! / 100;
      // Get weight in kg (always use metric=true for BMI calculation)
      final weightKg = latestWeight.getValueInUnit(true);
      bmi = weightKg / (heightM * heightM);
      final result = _getBmiCategoryAndColor(bmi);
      bmiCategory = result.$1;
      bmiColor = result.$2;
    }

    // Calculate Waist-to-Hip Ratio if we have both measurements
    double? whr;
    String? whrCategory;
    Color? whrColor;
    if (latestWaist != null && latestHips != null) {
      // Get measurements in metric (cm) for consistent calculation
      final waistCm = latestWaist.getValueInUnit(true);
      final hipsCm = latestHips.getValueInUnit(true);
      if (hipsCm > 0) {
        whr = waistCm / hipsCm;
        final isMale = user?.gender?.toLowerCase() == 'male';
        final result = _getWhrCategoryAndColor(whr, isMale: isMale);
        whrCategory = result.$1;
        whrColor = result.$2;
      }
    }

    // Don't show section if no derived metrics available
    if (bmi == null && whr == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // BMI Card
          if (bmi != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bmiColor!.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: bmiColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.monitor_weight_outlined,
                            size: 16,
                            color: bmiColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BMI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bmiColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bmiCategory!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: bmiColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (bmi != null && whr != null) const SizedBox(width: 12),

          // Waist-to-Hip Ratio Card
          if (whr != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: whrColor!.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: whrColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.straighten,
                            size: 16,
                            color: whrColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WHR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      whr.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: whrColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: whrColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        whrCategory!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: whrColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get BMI category and color based on value
  (String, Color) _getBmiCategoryAndColor(double bmi) {
    if (bmi < 18.5) {
      return ('Underweight', AppColors.orange);
    } else if (bmi < 25) {
      return ('Normal', AppColors.success);
    } else if (bmi < 30) {
      return ('Overweight', AppColors.orange);
    } else {
      return ('Obese', AppColors.error);
    }
  }

  /// Get Waist-to-Hip Ratio category and color
  /// WHO guidelines: Men >0.90, Women >0.85 = increased health risk
  (String, Color) _getWhrCategoryAndColor(double whr, {bool isMale = true}) {
    if (isMale) {
      if (whr < 0.90) {
        return ('Low Risk', AppColors.success);
      } else if (whr < 1.0) {
        return ('Moderate', AppColors.orange);
      } else {
        return ('High Risk', AppColors.error);
      }
    } else {
      if (whr < 0.80) {
        return ('Low Risk', AppColors.success);
      } else if (whr < 0.85) {
        return ('Moderate', AppColors.orange);
      } else {
        return ('High Risk', AppColors.error);
      }
    }
  }

  Widget _buildChartSection(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (state.summary?.latestByType[_selectedType] != null)
                    Text(
                      '${_formatValue(state.summary!.latestByType[_selectedType]!.getValueInUnit(_isMetric))} $unit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cyan,
                      ),
                    ),
                ],
              ),
              if (state.summary?.changeFromPrevious[_selectedType] != null)
                _buildChangeIndicator(
                  state.summary!.changeFromPrevious[_selectedType]!,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: state.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: cyan),
                        if (_loadingTimedOut) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Taking longer than expected...',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadMeasurements,
                            child: Text('Retry', style: TextStyle(color: cyan)),
                          ),
                        ],
                      ],
                    ),
                  )
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten, size: 40, color: textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'No ${_selectedType.displayName.toLowerCase()} data yet',
                              style: TextStyle(color: textMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showAddMeasurementSheet(context),
                              child: Text('Add Entry', style: TextStyle(color: cyan)),
                            ),
                          ],
                        ),
                      )
                    : _buildChart(filteredHistory, cyan: cyan, textMuted: textMuted, isDark: isDark),
          ),
        ],
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

  Widget _buildChangeIndicator(double change, {required bool isDark}) {
    final isPositive = change > 0;
    final isNegative = change < 0;

    // For weight and body fat, decrease is usually good
    final isGoodChange = (_selectedType == MeasurementType.weight ||
                          _selectedType == MeasurementType.bodyFat)
        ? isNegative
        : isPositive;

    final color = change.abs() < 0.1
        ? (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        : isGoodChange
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _formatValue(change.abs()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<MeasurementType> _typesForGroup(String groupTitle) {
    final group = _measurementGroups.firstWhere((g) => g['title'] == groupTitle);
    return group['types'] as List<MeasurementType>;
  }

  String _groupForType(MeasurementType type) {
    for (final group in _measurementGroups) {
      final types = group['types'] as List<MeasurementType>;
      if (types.contains(type)) return group['title'] as String;
    }
    return 'Body Composition';
  }

  Widget _buildTypeSelector(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    final currentTypes = _typesForGroup(_selectedGroup);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Group dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGroup,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                  dropdownColor: elevated,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  items: _measurementGroups.map((group) {
                    final title = group['title'] as String;
                    return DropdownMenuItem(value: title, child: Text(title));
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final types = _typesForGroup(value);
                    setState(() {
                      _selectedGroup = value;
                      _selectedType = types.first;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Type dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyan),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MeasurementType>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: cyan, size: 20),
                  dropdownColor: elevated,
                  style: TextStyle(fontSize: 13, color: cyan, fontWeight: FontWeight.w600),
                  items: currentTypes.map((type) {
                    final hasData = state.historyByType[type]?.isNotEmpty ?? false;
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Expanded(child: Text(type.displayName)),
                          if (hasData)
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(color: cyan, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedType = value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementGroupCard(
    MeasurementsState state,
    List<MeasurementType> types, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: types.asMap().entries.map((entry) {
          final index = entry.key;
          final type = entry.value;
          final latest = state.summary?.latestByType[type];
          final change = state.summary?.changeFromPrevious[type];
          final unit = _isMetric ? type.metricUnit : type.imperialUnit;

          return Column(
            children: [
              InkWell(
                onTap: () => context.push('/measurements/${type.name}'),
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : index == types.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(12))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (_selectedType == type ? cyan : textMuted).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(type),
                          size: 18,
                          color: _selectedType == type ? cyan : textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            if (latest != null)
                              Text(
                                'Last: ${DateFormat('MMM d').format(latest.recordedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (latest != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatValue(latest.getValueInUnit(_isMetric))} $unit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cyan,
                              ),
                            ),
                            if (change != null && change.abs() >= 0.1)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 10,
                                    color: _getChangeColor(type, change),
                                  ),
                                  Text(
                                    _formatValue(change.abs()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getChangeColor(type, change),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ] else
                        Text(
                          '--',
                          style: TextStyle(
                            fontSize: 15,
                            color: textMuted,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < types.length - 1)
                Divider(height: 1, color: cardBorder, indent: 62),
            ],
          );
        }).toList(),
      ),
    );
  }

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
                            DateFormat('d').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cyan,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(entry.recordedAt),
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

  Future<bool> _confirmDelete(MeasurementEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevated
            : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: Text(
          'Delete this ${entry.type.displayName} entry from ${DateFormat('MMM d, y').format(entry.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final auth = ref.read(authStateProvider);
      if (auth.user != null) {
        await ref.read(measurementsProvider.notifier).deleteMeasurement(
          auth.user!.id,
          entry.id,
          entry.type,
        );
      }
    }
    return false; // Return false so dismissible doesn't animate out
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;
    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      return history.where((e) =>
        e.recordedAt.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) &&
        e.recordedAt.isBefore(_customDateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }
    final days = _periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as int;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Color _getChangeColor(MeasurementType type, double change) {
    // For weight and body fat, decrease is good
    if (type == MeasurementType.weight || type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    // For other measurements (muscle), increase is usually good
    return change > 0 ? AppColors.success : AppColors.error;
  }

  IconData _getIconForType(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.bodyFat:
        return Icons.percent;
      case MeasurementType.chest:
        return Icons.accessibility_new;
      case MeasurementType.waist:
        return Icons.straighten;
      case MeasurementType.hips:
        return Icons.straighten;
      case MeasurementType.bicepsLeft:
      case MeasurementType.bicepsRight:
        return Icons.fitness_center;
      case MeasurementType.thighLeft:
      case MeasurementType.thighRight:
        return Icons.directions_walk;
      case MeasurementType.calfLeft:
      case MeasurementType.calfRight:
        return Icons.directions_run;
      case MeasurementType.neck:
        return Icons.face;
      case MeasurementType.shoulders:
        return Icons.accessibility;
      case MeasurementType.forearmLeft:
      case MeasurementType.forearmRight:
        return Icons.sports_gymnastics;
    }
  }

  void _showExportSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _MeasurementsExportSheet(ref: ref),
      ),
    );
  }

  void _showAddMeasurementSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _AddMeasurementSheet(
          selectedType: _selectedType,
          isMetric: _isMetric,
          onSubmit: (type, value, unit, notes) async {
            final auth = ref.read(authStateProvider);
            if (auth.user != null) {
              final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
                userId: auth.user!.id,
                type: type,
                value: value,
                unit: unit,
                notes: notes,
              );
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${type.displayName} recorded'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Measurement Sheet
// ─────────────────────────────────────────────────────────────────

class _AddMeasurementSheet extends StatefulWidget {
  final MeasurementType selectedType;
  final bool isMetric;
  final Future<void> Function(MeasurementType type, double value, String unit, String? notes) onSubmit;

  const _AddMeasurementSheet({
    required this.selectedType,
    required this.isMetric,
    required this.onSubmit,
  });

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  late MeasurementType _selectedType;
  late String _selectedGroup;
  late bool _isMetric;
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  String _groupForType(MeasurementType type) {
    for (final group in _MeasurementsScreenState._measurementGroups) {
      final types = group['types'] as List<MeasurementType>;
      if (types.contains(type)) return group['title'] as String;
    }
    return 'Body Composition';
  }

  List<MeasurementType> _typesForGroup(String groupTitle) {
    final group = _MeasurementsScreenState._measurementGroups.firstWhere((g) => g['title'] == groupTitle);
    return group['types'] as List<MeasurementType>;
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedGroup = _groupForType(widget.selectedType);
    _isMetric = widget.isMetric;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Measurement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Unit toggle
                GestureDetector(
                  onTap: () => setState(() => _isMetric = !_isMetric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _isMetric ? 'Metric' : 'Imperial',
                      style: TextStyle(
                        fontSize: 12,
                        color: cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Measurement type selector
            Text(
              'MEASUREMENT TYPE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGroup,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                        dropdownColor: elevated,
                        style: TextStyle(fontSize: 13, color: textMuted),
                        items: _MeasurementsScreenState._measurementGroups.map((group) {
                          final title = group['title'] as String;
                          return DropdownMenuItem(value: title, child: Text(title));
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final types = _typesForGroup(value);
                          setState(() {
                            _selectedGroup = value;
                            _selectedType = types.first;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cyan),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MeasurementType>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: cyan, size: 20),
                        dropdownColor: elevated,
                        style: TextStyle(fontSize: 13, color: cyan, fontWeight: FontWeight.w600),
                        items: _typesForGroup(_selectedGroup).map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedType = value);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Value input
            Text(
              'VALUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unit,
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes input
            Text(
              'NOTES (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
                  disabledBackgroundColor: cyan.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.pureBlack : Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a value'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;
    final notes = _notesController.text.trim();

    // Convert to metric if imperial was entered
    double valueToStore = value;
    String unitToStore = unit;

    if (!_isMetric && _selectedType != MeasurementType.bodyFat) {
      // Convert to metric for storage
      if (unit == 'in') {
        valueToStore = value * 2.54;
        unitToStore = 'cm';
      } else if (unit == 'lbs') {
        valueToStore = value / 2.20462;
        unitToStore = 'kg';
      }
    }

    await widget.onSubmit(
      _selectedType,
      valueToStore,
      unitToStore,
      notes.isNotEmpty ? notes : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Measurements Export Sheet
// ─────────────────────────────────────────────────────────────────

class _MeasurementsExportSheet extends StatefulWidget {
  final WidgetRef ref;

  const _MeasurementsExportSheet({required this.ref});

  @override
  State<_MeasurementsExportSheet> createState() => _MeasurementsExportSheetState();
}

class _MeasurementsExportSheetState extends State<_MeasurementsExportSheet> {
  String _selectedFormat = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedTypes = {
    'weight', 'body_fat', 'chest', 'waist', 'hips', 'neck', 'shoulders',
    'biceps_left', 'biceps_right', 'forearm_left', 'forearm_right',
    'thigh_left', 'thigh_right', 'calf_left', 'calf_right',
  };

  static const _formats = [
    {'label': 'CSV', 'value': 'csv'},
    {'label': 'JSON', 'value': 'json'},
    {'label': 'Excel', 'value': 'xlsx'},
    {'label': 'Parquet', 'value': 'parquet'},
  ];

  static const _allTypes = [
    {'key': 'weight', 'label': 'Weight'},
    {'key': 'body_fat', 'label': 'Body Fat'},
    {'key': 'chest', 'label': 'Chest'},
    {'key': 'waist', 'label': 'Waist'},
    {'key': 'hips', 'label': 'Hips'},
    {'key': 'neck', 'label': 'Neck'},
    {'key': 'shoulders', 'label': 'Shoulders'},
    {'key': 'biceps_left', 'label': 'Biceps L'},
    {'key': 'biceps_right', 'label': 'Biceps R'},
    {'key': 'forearm_left', 'label': 'Forearm L'},
    {'key': 'forearm_right', 'label': 'Forearm R'},
    {'key': 'thigh_left', 'label': 'Thigh L'},
    {'key': 'thigh_right', 'label': 'Thigh R'},
    {'key': 'calf_left', 'label': 'Calf L'},
    {'key': 'calf_right', 'label': 'Calf R'},
  ];

  bool get _allSelected => _selectedTypes.length == _allTypes.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.upload_outlined, color: cyan, size: 22),
              const SizedBox(width: 10),
              Text(
                'Export Measurements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Format label with info button
          Row(
            children: [
              Text(
                'Format',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showFormatInfoDialog(context),
                child: Icon(Icons.info_outline, size: 16, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Format chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formats.map((fmt) {
              final isSelected = _selectedFormat == fmt['value'];
              return ChoiceChip(
                label: Text(fmt['label']!),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFormat = fmt['value']!),
                selectedColor: cyan.withOpacity(0.2),
                backgroundColor: elevated,
                side: BorderSide(color: isSelected ? cyan : cardBorder),
                labelStyle: TextStyle(
                  color: isSelected ? cyan : textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date range filter
          Row(
            children: [
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (_startDate != null || _endDate != null)
                GestureDetector(
                  onTap: () => setState(() { _startDate = null; _endDate = null; }),
                  child: Text('Clear', style: TextStyle(fontSize: 12, color: cyan)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _startDate != null ? DateFormat('MMM d, y').format(_startDate!) : 'Start date',
                      style: TextStyle(fontSize: 13, color: _startDate != null ? textPrimary : textMuted),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('to', style: TextStyle(color: textMuted, fontSize: 12)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _endDate != null ? DateFormat('MMM d, y').format(_endDate!) : 'End date',
                      style: TextStyle(fontSize: 13, color: _endDate != null ? textPrimary : textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Measurement types filter
          Row(
            children: [
              Text(
                'Measurements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_allSelected) {
                      _selectedTypes.clear();
                    } else {
                      _selectedTypes.addAll(_allTypes.map((t) => t['key']!));
                    }
                  });
                },
                child: Text(
                  _allSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(fontSize: 12, color: cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _allTypes.map((t) {
              final key = t['key']!;
              final isSelected = _selectedTypes.contains(key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTypes.remove(key);
                    } else {
                      _selectedTypes.add(key);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cyan.withOpacity(0.15) : elevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? cyan : cardBorder),
                  ),
                  child: Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? cyan : textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Option 1: Measurements Only
          _ExportOptionTile(
            icon: Icons.straighten,
            title: 'Measurements Only',
            subtitle: _selectedTypes.isEmpty
                ? 'Select at least one measurement type'
                : 'Export ${_allSelected ? "all" : "${_selectedTypes.length}"} measurement types as .$_selectedFormat',
            iconColor: _selectedTypes.isEmpty ? textMuted : cyan,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            elevated: elevated,
            cardBorder: cardBorder,
            onTap: _selectedTypes.isEmpty ? () {} : () => _exportMeasurements(context),
          ),
          const SizedBox(height: 10),

          // Option 2: Export All Data
          _ExportOptionTile(
            icon: Icons.cloud_download_outlined,
            title: 'Export All Data',
            subtitle: 'Workouts, nutrition, measurements & more',
            iconColor: cyan,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            elevated: elevated,
            cardBorder: cardBorder,
            onTap: () {
              Navigator.pop(context);
              showExportDialog(context, widget.ref);
            },
          ),
        ],
        ),
      ),
    );
  }

  void _showFormatInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.pureWhite,
        title: Text('Export Info', style: TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columns section
              Text('Exported Columns', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              _columnInfoRow('date', 'When the measurement was recorded', textPrimary, textSecondary),
              _columnInfoRow('type', 'Measurement type (weight, waist, etc.)', textPrimary, textSecondary),
              _columnInfoRow('value', 'The recorded value', textPrimary, textSecondary),
              _columnInfoRow('unit', 'Unit of measurement (kg, %, cm)', textPrimary, textSecondary),
              _columnInfoRow('notes', 'Optional notes for the entry', textPrimary, textSecondary),
              const SizedBox(height: 14),

              // Available types
              Text('Available Measurement Types', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              Text(
                'weight, body_fat, chest, waist, hips, neck, shoulders, biceps_left, biceps_right, forearm_left, forearm_right, thigh_left, thigh_right, calf_left, calf_right',
                style: TextStyle(fontSize: 11, color: textMuted, height: 1.5),
              ),
              const SizedBox(height: 14),

              // Formats section
              Text('Formats', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              _formatInfoRow('CSV', 'Opens in Excel, Google Sheets, any spreadsheet app', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('JSON', 'Structured data. Best for developers or importing into other apps', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('Excel', 'Native .xlsx workbook. Opens directly in Excel', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('Parquet', 'Columnar storage. Compact for large datasets. Used in Python/Pandas, R, Spark', textPrimary, textSecondary),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: cyan)),
          ),
        ],
      ),
    );
  }

  Widget _columnInfoRow(String name, String desc, Color titleColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: titleColor, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: TextStyle(fontSize: 11, color: descColor))),
        ],
      ),
    );
  }

  Widget _formatInfoRow(String name, String desc, Color titleColor, Color descColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 12, color: descColor)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _exportMeasurements(BuildContext context) async {
    final auth = widget.ref.read(authStateProvider);
    if (auth.user == null) return;

    final userId = auth.user!.id;
    final apiClient = widget.ref.read(apiClientProvider);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final queryParams = <String, String>{
        'format': _selectedFormat,
      };
      if (_startDate != null) queryParams['start_date'] = _formatDate(_startDate!);
      if (_endDate != null) queryParams['end_date'] = _formatDate(_endDate!);
      if (!_allSelected && _selectedTypes.isNotEmpty) {
        queryParams['types'] = _selectedTypes.join(',');
      }

      final useBytes = _selectedFormat != 'json';
      final response = await apiClient.dio.get(
        '${ApiConstants.apiVersion}${ApiConstants.metrics}/body/export/$userId',
        queryParameters: queryParams,
        options: Options(
          responseType: useBytes ? ResponseType.bytes : ResponseType.plain,
        ),
      );

      final dir = await getTemporaryDirectory();
      final ext = _selectedFormat == 'xlsx' ? 'xlsx' : _selectedFormat;
      final file = File('${dir.path}/measurements.$ext');

      if (useBytes) {
        await file.writeAsBytes(response.data as List<int>);
      } else {
        await file.writeAsString(response.data as String);
      }

      // Dismiss loading
      if (context.mounted) Navigator.pop(context);
      // Dismiss export sheet
      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FitWiz Measurements Export',
      );
    } catch (e) {
      // Dismiss loading
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e is DioException ? e.message : e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color elevated;
  final Color cardBorder;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.elevated,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
