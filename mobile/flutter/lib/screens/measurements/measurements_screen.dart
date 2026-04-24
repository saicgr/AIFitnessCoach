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
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_circle_fab.dart';
import 'measurement_unit_conversion.dart';
import 'widgets/measurement_body_view.dart';
import 'widgets/measurement_tile_grid.dart';
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

  _ViewMode _viewMode = _ViewMode.body;

  /// Key the view-mode preference is stored under so it persists across app
  /// launches.
  static const _viewModePrefKey = 'measurements_view_mode';

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': '6M', 'value': '6m', 'days': 182},
    {'label': 'YTD', 'value': 'ytd', 'days': 0}, // computed at filter time
    {'label': '1Y', 'value': '1y', 'days': 365},
    {'label': 'All', 'value': 'all', 'days': 0},
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
    _restoreViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'measurements_viewed');
    });
  }

  Future<void> _restoreViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewModePrefKey);
    if (raw == null || !mounted) return;
    final restored = _ViewMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => _ViewMode.body,
    );
    if (restored != _viewMode) {
      setState(() => _viewMode = restored);
    }
  }

  Future<void> _setViewMode(_ViewMode mode) async {
    if (mode == _viewMode) return;
    HapticService.light();
    setState(() => _viewMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModePrefKey, mode.name);
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
            // Main content. Body view fits in one viewport (figure + derived
            // pill row above) — disable scrolling. Tile view scrolls normally
            // with pull-to-refresh.
            RefreshIndicator(
              onRefresh: _loadMeasurements,
              color: cyan,
              child: CustomScrollView(
                physics: _viewMode == _ViewMode.body
                    ? const NeverScrollableScrollPhysics()
                    : null,
                slivers: [
                  // Header with title (offset for floating back button)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Measurements',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          // View-mode toggle (Body / Tiles)
                          _ViewModeToggle(
                            mode: _viewMode,
                            accent: cyan,
                            elevated: elevated,
                            cardBorder: cardBorder,
                            textMuted: textMuted,
                            onChanged: _setViewMode,
                          ),
                          const SizedBox(width: 8),
                          // Body Analyzer entry
                          GestureDetector(
                            onTap: () => context.go('/body-analyzer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB24BF3).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFB24BF3).withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Color(0xFFB24BF3),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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

                  // Period selector — only relevant to the chart + history
                  // (trend analysis) which live in Tile view. Hide in Body
                  // view where the UI is focused on logging current values.
                  // Horizontally scrollable so 6M / YTD / 1Y / All / Custom
                  // all fit without squishing.
                  if (_viewMode == _ViewMode.tiles)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _periods.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final period = _periods[index];
                          final isSelected = _selectedPeriod == period['value'];
                          final isCustom = period['value'] == 'custom';
                          return GestureDetector(
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? cyan.withOpacity(0.2) : elevated,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected ? cyan : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: isCustom && isSelected && _customDateRange != null
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                            );
                        },
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ),

                  // Breathing room below the period chip row (tiles only —
                  // body view doesn't render chips at all).
                  if (_viewMode == _ViewMode.tiles)
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Derived metrics row (BMI, WHR, …) + chart cluster — the
                  // glance-worthy stats sit directly below the date pills,
                  // BEFORE the tile grid, so users see trends first and dig
                  // into individual metrics second.
                  if (_viewMode == _ViewMode.tiles) ...[
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
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Selected measurement chart + type selector — moved
                    // above the tile grid so the trend graph reads right
                    // under the BMI / WHR cards.
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
                    SliverToBoxAdapter(
                      child: _buildTypeSelector(
                        measurementsState,
                        isDark: isDark,
                        elevated: elevated,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                        cyan: cyan,
                      ).animate().fadeIn(delay: 170.ms),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],

                  // Main metric editor — body silhouette or tile grid. In
                  // tiles view this now sits after the chart cluster.
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _viewMode == _ViewMode.body
                          ? KeyedSubtree(
                              key: const ValueKey('body-view'),
                              child: MeasurementBodyView(
                                state: measurementsState,
                                isMetric: _isMetric,
                              ),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('tile-view'),
                              child: MeasurementTileGrid(
                                state: measurementsState,
                                isMetric: _isMetric,
                                onLogRequested: (type) =>
                                    _showAddMeasurementSheet(context, prefilledType: type),
                              ),
                            ),
                    ).animate().fadeIn(delay: 190.ms),
                  ),

                  // (Derived metrics in body view now live as pills in the
                  // top row inside MeasurementBodyView, alongside Weight and
                  // Body Fat — same height, same interaction model.)

                  // History only shows in tile view (trend analysis). Body
                  // view stays focused on logging current values.
                  if (_viewMode == _ViewMode.tiles) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

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
                  ],

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
      floatingActionButton: GlassCircleFab(
        onPressed: () => _showAddMeasurementSheet(context),
        tooltip: 'Add measurement',
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  // BMI / WHR categorization now lives in computeDerivedMetrics() in
  // measurements_repository.dart; removed the duplicate helpers from here.

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
    // YTD = since Jan 1 of current year; can't be a fixed day count.
    if (_selectedPeriod == 'ytd') {
      final startOfYear = DateTime(DateTime.now().year, 1, 1);
      return history.where((e) => e.recordedAt.isAfter(startOfYear)).toList();
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

  /// Canonical icon mapping. Static so callers in part files and widgets
  /// can reuse it without plumbing a `_MeasurementsScreenState` instance
  /// through.
  static IconData _iconFor(MeasurementType type) {
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
        return Icons.back_hand;
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

  void _showAddMeasurementSheet(BuildContext context, {MeasurementType? prefilledType}) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _AddMeasurementSheet(
          selectedType: prefilledType ?? _selectedType,
          isMetric: _isMetric,
          lockedType: prefilledType,
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

/// Body-vs-tile view mode for the measurements screen. Persisted to
/// SharedPreferences so the user's last choice sticks.
enum _ViewMode { body, tiles }

/// Two-segment pill toggle rendered in the measurements header row. Uses the
/// same accent/elevated palette as the other header chips so it visually
/// belongs with Export + Metric.
class _ViewModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final Color accent;
  final Color elevated;
  final Color cardBorder;
  final Color textMuted;
  final Future<void> Function(_ViewMode) onChanged;

  const _ViewModeToggle({
    required this.mode,
    required this.accent,
    required this.elevated,
    required this.cardBorder,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(icon: Icons.accessibility_new, selected: mode == _ViewMode.body, value: _ViewMode.body),
          _segment(icon: Icons.grid_view_rounded, selected: mode == _ViewMode.tiles, value: _ViewMode.tiles),
        ],
      ),
    );
  }

  Widget _segment({required IconData icon, required bool selected, required _ViewMode value}) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 16, color: selected ? accent : textMuted),
      ),
    );
  }
}

