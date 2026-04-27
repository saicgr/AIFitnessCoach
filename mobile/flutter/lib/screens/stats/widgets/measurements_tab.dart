import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_loading.dart';

part 'measurements_tab_ui.dart';


// ═══════════════════════════════════════════════════════════════════
// MEASUREMENTS TAB - Weight, measurements, body composition
// ═══════════════════════════════════════════════════════════════════

class MeasurementsTab extends ConsumerStatefulWidget {
  final String? userId;
  const MeasurementsTab({super.key, this.userId});

  @override
  ConsumerState<MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends ConsumerState<MeasurementsTab> {
  String _selectedPeriod = '30d';
  MeasurementType _selectedType = MeasurementType.weight;
  List<MeasurementType> _measurementOrder = [];

  static const _defaultOrder = [
    MeasurementType.weight, MeasurementType.bodyFat,
    MeasurementType.chest, MeasurementType.waist, MeasurementType.hips,
    MeasurementType.shoulders, MeasurementType.neck,
    MeasurementType.bicepsLeft, MeasurementType.bicepsRight,
    MeasurementType.forearmLeft, MeasurementType.forearmRight,
    MeasurementType.thighLeft, MeasurementType.thighRight,
    MeasurementType.calfLeft, MeasurementType.calfRight,
  ];

  final _periods = [
    {'label': '1D', 'value': '1d', 'days': 1},
    {'label': '3D', 'value': '3d', 'days': 3},
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 3650},
  ];

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

  static const _derivedMetricPlacement = <MeasurementType, List<DerivedMetricType>>{
    MeasurementType.weight: [DerivedMetricType.bmi, DerivedMetricType.ffmi, DerivedMetricType.leanBodyMass],
    MeasurementType.waist: [DerivedMetricType.waistToHipRatio, DerivedMetricType.waistToHeightRatio],
    MeasurementType.shoulders: [DerivedMetricType.shoulderToWaistRatio],
    MeasurementType.chest: [DerivedMetricType.chestToWaistRatio],
    MeasurementType.bicepsRight: [DerivedMetricType.armSymmetry],
    MeasurementType.thighRight: [DerivedMetricType.legSymmetry],
  };

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadMeasurements();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('measurement_order');
    if (saved != null && saved.isNotEmpty) {
      final order = <MeasurementType>[];
      for (final name in saved) {
        final t = MeasurementType.values.where((t) => t.name == name).firstOrNull;
        if (t != null) order.add(t);
      }
      // Add any missing types
      for (final t in _defaultOrder) {
        if (!order.contains(t)) order.add(t);
      }
      if (mounted) setState(() => _measurementOrder = order);
    } else {
      setState(() => _measurementOrder = List.from(_defaultOrder));
    }
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'measurement_order',
      _measurementOrder.map((t) => t.name).toList(),
    );
  }



  Future<void> _loadMeasurements() async {
    final userId = widget.userId;
    if (userId == null) return;

    // Always force a fresh fetch from Supabase
    await ref.read(measurementsProvider.notifier).forceRefresh(userId);

    final state = ref.read(measurementsProvider);
    final weightHistory = state.historyByType[MeasurementType.weight] ?? [];
    debugPrint('🔍 [MeasurementsTab] Loaded ${weightHistory.length} weight entries, '
        '${state.historyByType.length} total types with data');

    // NOTE: No client-side seeding needed — DB trigger (sync_user_weight_to_body_measurements)
    // automatically creates the initial body_measurements entry when onboarding sets weight_kg.
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;
    final days = _periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as int;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
  }

  List<double> _computeEWMA(List<double> values, {double alpha = 0.3}) {
    if (values.isEmpty) return [];
    final result = <double>[values.first];
    for (int i = 1; i < values.length; i++) {
      result.add(alpha * values[i] + (1 - alpha) * result[i - 1]);
    }
    return result;
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final state = ref.watch(measurementsProvider);
    final summary = state.summary;
    final auth = ref.watch(authStateProvider);
    final heightCm = auth.user?.heightCm;
    final gender = auth.user?.gender;

    if (state.isLoading) return AppLoading.fullScreen();

    // Compute derived metrics - use profile weight as fallback
    Map<DerivedMetricType, DerivedMetricResult> derivedMetrics;
    if (summary != null && summary.latestByType.isNotEmpty) {
      derivedMetrics = computeDerivedMetrics(summary: summary, heightCm: heightCm, gender: gender);
    } else {
      derivedMetrics = computeDerivedMetrics(
        summary: MeasurementsSummary(
          latestByType: {
            if (auth.user?.weightKg != null && auth.user!.weightKg! > 0)
              MeasurementType.weight: MeasurementEntry(
                id: '', userId: '', type: MeasurementType.weight,
                value: auth.user!.weightKg!, unit: 'kg', recordedAt: DateTime.now(),
              ),
          },
          changeFromPrevious: {},
        ),
        heightCm: heightCm,
        gender: gender,
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadMeasurements,
          color: cyan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero chart card
                _buildHeroChart(
                  state: state,
                  summary: summary,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                  cardBorder: cardBorder,
                ),
                const SizedBox(height: 16),

                // Unified grouped list
                _buildGroupedList(
                  state: state,
                  summary: summary,
                  derivedMetrics: derivedMetrics,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                  cardBorder: cardBorder,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Floating FAB - quick add measurement
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'measurements_quick_add_fab',
            onPressed: () => _showQuickAddSheet(context, ref, cyan, _selectedType),
            backgroundColor: cyan,
            child: Icon(Icons.add, color: isDark ? AppColors.pureBlack : Colors.white),
          ),
        ),
      ],
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref, Color accent, [MeasurementType initialType = MeasurementType.weight]) {
    final auth = ref.read(authStateProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    MeasurementType selectedType = initialType;
    final valueController = TextEditingController();
    bool isSubmitting = false;

    String unitFor(MeasurementType t) =>
        t == MeasurementType.weight ? 'kg' : (t == MeasurementType.bodyFat ? '%' : 'cm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log ${selectedType.displayName}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MeasurementType.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final type = MeasurementType.values[index];
                        final isSelected = selectedType == type;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedType = type);
                            valueController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accent.withValues(alpha: 0.2) : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isSelected ? accent : colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            child: Text(type.displayName, style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? accent : colorScheme.onSurfaceVariant,
                            )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: selectedType.displayName,
                      suffixText: unitFor(selectedType),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : () async {
                        final val = double.tryParse(valueController.text.trim());
                        if (val == null || val <= 0) return;
                        setSheetState(() => isSubmitting = true);
                        final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
                          userId: userId, type: selectedType, value: val, unit: unitFor(selectedType),
                        );
                        if (success && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        setSheetState(() => isSubmitting = false);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeRangeChips({
    required Color cyan,
    required Color elevated,
    required Color textMuted,
    required Color cardBorder,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedPeriod = period['value'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? cyan.withOpacity(0.2) : elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? cyan : cardBorder),
              ),
              child: Text(
                period['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cyan : textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroChartContent({
    required Key key,
    required List<MeasurementEntry> filtered,
    required bool isDark,
    required Color textMuted,
    required Color cyan,
    required String unit,
  }) {
    if (filtered.isEmpty) {
      final fullHistory = ref.read(measurementsProvider).historyByType[_selectedType] ?? [];
      final hasOlderData = fullHistory.isNotEmpty;
      final periodLabel = _periods
          .firstWhere((p) => p['value'] == _selectedPeriod)['label'] as String;
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: textMuted),
            const SizedBox(height: 8),
            Text(
              hasOlderData
                  ? 'No ${_selectedType.displayName.toLowerCase()} logs in last $periodLabel'
                  : 'Log ${_selectedType.displayName.toLowerCase()} to see trends',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted),
            ),
            if (hasOlderData) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedPeriod = 'all'),
                child: Text('View all', style: TextStyle(color: cyan)),
              ),
            ],
          ],
        ),
      );
    }

    if (filtered.length == 1) {
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_formatValue(filtered.first.value)} $unit',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cyan),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(filtered.first.recordedAt),
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 8),
            Text('Log again to see trends', style: TextStyle(fontSize: 12, color: textMuted)),
          ],
        ),
      );
    }

    // 2+ entries: show chart
    if (_selectedType == MeasurementType.weight) {
      return KeyedSubtree(
        key: key,
        child: _buildWeightLineChart(filtered, cyan: cyan, textMuted: textMuted, isDark: isDark),
      );
    }
    return KeyedSubtree(
      key: key,
      child: _buildSingleLineChart(filtered, cyan: cyan, textMuted: textMuted, isDark: isDark),
    );
  }

  Widget _buildSingleLineChart(
    List<MeasurementEntry> data, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: (data.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(data[index].recordedAt),
                      style: TextStyle(fontSize: 9, color: textMuted),
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
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length < 20,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: cyan,
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.pureBlack : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cyan.withOpacity(0.2), cyan.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildDerivedPills({
    required MeasurementType type,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color textMuted,
  }) {
    final placements = _derivedMetricPlacement[type];
    if (placements == null || placements.isEmpty) return const SizedBox.shrink();

    final pills = <Widget>[];
    for (final dType in placements) {
      final result = derivedMetrics[dType];
      if (result == null) continue;
      final valueStr = dType.unit.isNotEmpty
          ? '${_formatValue(result.value)} ${dType.unit}'
          : _formatValue(result.value);

      pills.add(
        GestureDetector(
          onTap: () {
            HapticService.light();
            context.push('/measurements/derived/${dType.name}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.label.isNotEmpty
                  ? '${dType.displayName} $valueStr ${result.label}'
                  : '${dType.displayName} $valueStr',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: result.color,
              ),
            ),
          ),
        ),
      );
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8, top: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: pills,
      ),
    );
  }

  Widget _buildMeasurementRow({
    required MeasurementType type,
    required int index,
    required MeasurementsSummary? summary,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
    required bool isLast,
  }) {
    final entry = summary?.latestByType[type];
    final change = summary?.changeFromPrevious[type];
    final hasData = entry != null;
    final unit = type == MeasurementType.weight
        ? 'kg'
        : (type == MeasurementType.bodyFat ? '%' : 'cm');
    final isSelected = _selectedType == type;

    return Container(
      key: ValueKey(type),
      decoration: BoxDecoration(
        color: isSelected ? cyan.withValues(alpha: 0.06) : null,
        border: Border(
          left: isSelected
              ? BorderSide(color: cyan, width: 3)
              : BorderSide.none,
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: cardBorder, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticService.light();
              setState(() => _selectedType = type);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.drag_handle, color: textMuted, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasData ? textPrimary : textMuted,
                          ),
                        ),
                        if (hasData && change != null && change.abs() >= 0.1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 12,
                                color: _getChangeColor(type, change),
                              ),
                              Text(
                                '${_formatValue(change.abs())} ${entry.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getChangeColor(type, change),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  hasData
                      ? Text(
                          '${_formatValue(entry.value)} ${entry.unit}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        )
                      : Text(
                          '— $unit',
                          style: TextStyle(fontSize: 14, color: textMuted.withValues(alpha: 0.5)),
                        ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      context.push('/measurements/${type.name}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right, size: 18, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDerivedPills(
            type: type,
            derivedMetrics: derivedMetrics,
            isDark: isDark,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList({
    required MeasurementsState state,
    required MeasurementsSummary? summary,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int gi = 0; gi < _measurementGroups.length; gi++) ...[
            // Group header
            Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16,
                top: gi == 0 ? 16 : 20,
                bottom: 4,
              ),
              child: Text(
                (_measurementGroups[gi]['title'] as String).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // Group rows - get types for this group, filtered to user order
            Builder(builder: (context) {
              final groupTypes = _measurementGroups[gi]['types'] as List<MeasurementType>;
              // Order by the user's preference within the group
              final orderedGroupTypes = <MeasurementType>[];
              for (final t in _measurementOrder) {
                if (groupTypes.contains(t)) orderedGroupTypes.add(t);
              }
              // Add any missing types from the group
              for (final t in groupTypes) {
                if (!orderedGroupTypes.contains(t)) orderedGroupTypes.add(t);
              }

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: orderedGroupTypes.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    // Update position in the flat _measurementOrder
                    final item = orderedGroupTypes[oldIndex];
                    final otherItem = orderedGroupTypes[newIndex];
                    final flatOld = _measurementOrder.indexOf(item);
                    final flatNew = _measurementOrder.indexOf(otherItem);
                    if (flatOld >= 0 && flatNew >= 0) {
                      _measurementOrder.removeAt(flatOld);
                      final insertAt = _measurementOrder.indexOf(otherItem);
                      _measurementOrder.insert(
                        oldIndex < newIndex ? insertAt + 1 : insertAt,
                        item,
                      );
                    }
                  });
                  _saveOrder();
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final type = orderedGroupTypes[index];
                  return _buildMeasurementRow(
                    type: type,
                    index: index,
                    summary: summary,
                    derivedMetrics: derivedMetrics,
                    isDark: isDark,
                    elevated: elevated,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cyan: cyan,
                    cardBorder: cardBorder,
                    isLast: index == orderedGroupTypes.length - 1 && gi == _measurementGroups.length - 1,
                  );
                },
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getChangeColor(MeasurementType type, double change) {
    if (type == MeasurementType.weight || type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    return change > 0 ? AppColors.success : AppColors.error;
  }
}
