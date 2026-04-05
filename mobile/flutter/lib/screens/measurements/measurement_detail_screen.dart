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
import '../../widgets/glass_sheet.dart';

part 'measurement_detail_screen_part_stat_item.dart';

part 'measurement_detail_screen_ui.dart';


/// Detail screen for a specific measurement type
/// Shows chart, history list, and allows logging new entries
class MeasurementDetailScreen extends ConsumerStatefulWidget {
  final String measurementType;

  const MeasurementDetailScreen({
    super.key,
    required this.measurementType,
  });

  @override
  ConsumerState<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState
    extends ConsumerState<MeasurementDetailScreen> {
  String _selectedPeriod = '30d';
  bool _isMetric = true;
  late MeasurementType _type;
  String? _userGender;

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
  ];

  @override
  void initState() {
    super.initState();
    _type = MeasurementType.values.firstWhere(
      (t) => t.name == widget.measurementType,
      orElse: () => MeasurementType.weight,
    );
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final auth = ref.read(authStateProvider);
    _userGender = auth.user?.gender;
    if (auth.user != null) {
      await ref
          .read(measurementsProvider.notifier)
          .loadAllMeasurements(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsState = ref.watch(measurementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final history = measurementsState.historyByType[_type] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;
    final latest = measurementsState.summary?.latestByType[_type];
    final change = measurementsState.summary?.changeFromPrevious[_type];

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
                              _type.displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
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
                    ),
                  ),

                  // Current value card
                  SliverToBoxAdapter(
                    child: _buildCurrentValueCard(
                  latest: latest,
                  change: change,
                  unit: unit,
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
                      final isSelected = _selectedPeriod == period['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedPeriod = period['value'] as String),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? cyan.withOpacity(0.2) : elevated,
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

              // Chart
              SliverToBoxAdapter(
                child: _buildChartSection(
                  filteredHistory,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 200.ms),
              ),

              // Stats summary
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
                child: _buildRateOfChangeCard(
                  filteredHistory,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 260.ms),
              ),

              // Health context
              SliverToBoxAdapter(
                child: _buildHealthContextCard(
                  latest: latest,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 270.ms),
              ),

              // Related metrics
              SliverToBoxAdapter(
                child: _buildRelatedMetrics(
                  summary: measurementsState.summary,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 280.ms),
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
                ).animate().fadeIn(delay: 300.ms),
              ),

              // History list
              _buildHistoryList(
                filteredHistory,
                unit: unit,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementSheet(context),
        backgroundColor: cyan,
        foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Log ${_type.displayName}'),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  Widget _buildCurrentValueCard({
    required MeasurementEntry? latest,
    required double? change,
    required String unit,
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
                latest != null
                    ? _formatValue(latest.getValueInUnit(_isMetric))
                    : '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: cyan,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' $unit',
                  style: TextStyle(
                    fontSize: 20,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latest != null)
            Text(
              'Last updated ${DateFormat('MMM d, yyyy').format(latest.recordedAt)}',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
          if (change != null && change.abs() >= 0.1) ...[
            const SizedBox(height: 12),
            _buildChangeIndicator(change, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(double change, {required bool isDark}) {
    final isPositive = change > 0;
    final isNegative = change < 0;

    // For weight and body fat, decrease is usually good
    final isGoodChange =
        (_type == MeasurementType.weight || _type == MeasurementType.bodyFat)
            ? isNegative
            : isPositive;

    final color = change.abs() < 0.1
        ? (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        : isGoodChange
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${_formatValue(change.abs())} from previous',
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

  Widget _buildChartSection(
    List<MeasurementEntry> history, {
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
                          'No data yet',
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
                : _buildChart(history, cyan: cyan, textMuted: textMuted, isDark: isDark),
          ),
        ],
      ),
    );
  }

  List<double> _computeEWMA(List<double> values, {double alpha = 0.3}) {
    if (values.isEmpty) return [];
    final result = <double>[values.first];
    for (int i = 1; i < values.length; i++) {
      result.add(alpha * values[i] + (1 - alpha) * result[i - 1]);
    }
    return result;
  }

  List<HorizontalLine> _getHealthZoneLines() {
    final g = _userGender?.toLowerCase() ?? 'male';
    switch (_type) {
      case MeasurementType.bodyFat:
        if (g == 'female') {
          return [
            HorizontalLine(y: 20, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Athletes')),
            HorizontalLine(y: 24, color: Colors.cyan.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.cyan.withOpacity(0.7)),
                labelResolver: (_) => 'Fitness')),
            HorizontalLine(y: 31, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'Obese')),
          ];
        } else {
          return [
            HorizontalLine(y: 13, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Athletes')),
            HorizontalLine(y: 17, color: Colors.cyan.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.cyan.withOpacity(0.7)),
                labelResolver: (_) => 'Fitness')),
            HorizontalLine(y: 24, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'Obese')),
          ];
        }
      case MeasurementType.waist:
        if (g == 'female') {
          return [
            HorizontalLine(y: 80, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Healthy')),
            HorizontalLine(y: 88, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'High Risk')),
          ];
        } else {
          return [
            HorizontalLine(y: 94, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Healthy')),
            HorizontalLine(y: 102, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'High Risk')),
          ];
        }
      default:
        return [];
    }
  }

  Widget _buildStatsSection(
    List<MeasurementEntry> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    final values = history.map((e) => e.getValueInUnit(_isMetric)).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

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

  Color _getRelatedChangeColor(MeasurementType type, double change) {
    if (type == MeasurementType.weight || type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    return change > 0 ? AppColors.success : AppColors.error;
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
    return false;
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;

    final days =
        (_periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as num).toInt();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Color _getChangeColor(double change) {
    // For weight and body fat, decrease is good
    if (_type == MeasurementType.weight || _type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    // For other measurements (muscle), increase is usually good
    return change > 0 ? AppColors.success : AppColors.error;
  }

  void _showAddMeasurementSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

    final valueController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
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
                  Text(
                    'Log ${_type.displayName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  controller: valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  controller: notesController,
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
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final valueText = valueController.text.trim();
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

                            setSheetState(() => isSubmitting = true);

                            final notes = notesController.text.trim();

                            // Convert to metric if imperial was entered
                            double valueToStore = value;
                            String unitToStore = unit;

                            if (!_isMetric &&
                                _type != MeasurementType.bodyFat) {
                              if (unit == 'in') {
                                valueToStore = value * 2.54;
                                unitToStore = 'cm';
                              } else if (unit == 'lbs') {
                                valueToStore = value / 2.20462;
                                unitToStore = 'kg';
                              }
                            }

                            final auth = ref.read(authStateProvider);
                            if (auth.user != null) {
                              final success = await ref
                                  .read(measurementsProvider.notifier)
                                  .recordMeasurement(
                                    userId: auth.user!.id,
                                    type: _type,
                                    value: valueToStore,
                                    unit: unitToStore,
                                    notes: notes.isNotEmpty ? notes : null,
                                  );
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${_type.displayName} recorded'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }

                            setSheetState(() => isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
                      disabledBackgroundColor: cyan.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
