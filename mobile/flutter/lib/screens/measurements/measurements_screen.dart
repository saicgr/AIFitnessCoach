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
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_sheet.dart';
import '../settings/dialogs/export_dialog.dart';

part 'measurements_screen_part_add_measurement_sheet.dart';

part 'measurements_screen_ui.dart';


class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  MeasurementType _selectedType = MeasurementType.weight;
  String _selectedGroup = 'Body Composition';
  String _selectedPeriod = '30d';
  late bool _isMetric;
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
    final auth = ref.read(authStateProvider);
    _isMetric = auth.user?.usesMetricMeasurements ?? true;
    _loadMeasurements();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'measurements_viewed');
    });
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
                            onTap: () {
                              setState(() => _isMetric = !_isMetric);
                              ref.read(authStateProvider.notifier).updateUserProfile({
                                'measurement_unit': _isMetric ? 'cm' : 'in',
                              });
                            },
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
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 40, color: textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load data',
                              style: TextStyle(color: textMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadMeasurements,
                              child: Text('Retry', style: TextStyle(color: cyan)),
                            ),
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
    final days = (_periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as num).toInt();
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
