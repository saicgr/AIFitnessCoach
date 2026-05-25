import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_circle_fab.dart';
import '../../widgets/glass_sheet.dart';
import '../../utils/share_report_helper.dart';
import '../../core/constants/branding.dart';
import '../../widgets/trends/trend_chart.dart';
import '../../widgets/trends/trend_correlation.dart';

import '../../l10n/generated/app_localizations.dart';
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
  late bool _isMetric;
  late MeasurementType _type;
  String? _userGender;
  // Used by share_report_helper to capture the chart + summary stats as a PNG.
  final GlobalKey _shareRepaintKey = GlobalKey();

  final _periods = [
    {'label': '1D', 'value': '1d', 'days': 1},
    {'label': '3D', 'value': '3d', 'days': 3},
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': '6M', 'value': '6m', 'days': 182},
    {'label': 'YTD', 'value': 'ytd', 'days': -1},
    {'label': '1Y', 'value': '1y', 'days': 365},
    {'label': 'All', 'value': 'all', 'days': 0},
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    _isMetric = auth.user?.usesMetricMeasurements ?? true;
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
    // Use the user's selected accent so the chart actually has color in light
    // mode (AppColorsLight.cyan is monochrome grey).
    final cyan = ref.colors(context).accent;

    final history = measurementsState.historyByType[_type] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;
    final latest = measurementsState.summary?.latestByType[_type];
    // G7a: only surface a "from previous" delta when at least 2 real entries
    // exist in the selected range. On a single data point the delta is
    // meaningless ("↑ 28.5 from previous" against nothing).
    final change = filteredHistory.length >= 2
        ? measurementsState.summary?.changeFromPrevious[_type]
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content. RepaintBoundary lets share_report_helper snapshot
            // the chart + stats into a PNG without including the floating
            // back button or share FAB in the exported image.
            RepaintBoundary(
              key: _shareRepaintKey,
              child: RefreshIndicator(
              onRefresh: _loadMeasurements,
              color: cyan,
              child: CustomScrollView(
                slivers: [
                  // Header with title. The horizontal insets clear BOTH
                  // floating affordances in the Stack: 56px on the left for
                  // the back button, 56px on the right for the share FAB —
                  // otherwise the "Metric" unit pill collides with the share
                  // button (G7c).
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 56, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _type.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          // Custom Trends entry — opens the trends explorer
                          // pre-selected to this measurement's metric.
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                            icon: LineIcon('custom_trend',
                                color: textMuted, size: 22),
                            tooltip: AppLocalizations.of(context).measurementDetailViewTrends,
                            onPressed: () {
                              HapticService.light();
                              context.push('/trends/custom',
                                  extra: _trendMetricForType(_type));
                            },
                          ),
                          const SizedBox(width: 4),
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
                                _isMetric ? AppLocalizations.of(context).measurementsScreenPartMetric : AppLocalizations.of(context).measurementsScreenPartImperial,
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

              // Period selector — scrollable pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _periods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final period = _periods[index];
                      final isSelected = _selectedPeriod == period['value'];
                      return GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedPeriod = period['value'] as String);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? cyan.withOpacity(0.2) : elevated,
                            // Full-pill radius — matches the period row on the main
                            // measurements screen for a unified look.
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected ? cyan : cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              period['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? cyan : textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 150.ms),
              ),

              // Breathing room between the period chip row and the chart.
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

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
                        AppLocalizations.of(context).measurementDetailHistory,
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
            // Floating share button (mirrors the per-row share affordance on
            // Reports & Insights — exports the chart as a PNG via
            // share_report_helper.shareReportScreen).
            Positioned(
              top: 8,
              right: 8,
              child: _ShareIconButton(
                onTap: () {
                  HapticService.light();
                  shareReportScreen(
                    context: context,
                    repaintKey: _shareRepaintKey,
                    caption: '${_type.displayName} trend'
                        '${latest != null ? ' — ${latest.value.toStringAsFixed(1)} $unit' : ''}',
                    subject: '${Branding.appName} ${_type.displayName}',
                  );
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GlassCircleFab(
        onPressed: () => _showAddMeasurementSheet(context),
        tooltip: 'Log ${_type.displayName}',
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
            AppLocalizations.of(context).progressChartsTrends,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          history.isEmpty
                ? SizedBox(
                    height: 220,
                    child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 40, color: textMuted),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).trendChartNoDataInThis,
                          style: TextStyle(color: textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).measurementDetailTrySelectingAWider,
                          style: TextStyle(color: textMuted.withValues(alpha: 0.6), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _showAddMeasurementSheet(context),
                          child: Text(AppLocalizations.of(context).metricsDashboardAddEntry, style: TextStyle(color: cyan)),
                        ),
                      ],
                    ),
                  ))
                : _buildChart(history, cyan: cyan, textMuted: textMuted, isDark: isDark),
        ],
      ),
    );
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
              label: AppLocalizations.of(context).syncedWorkoutDetailMin,
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
              label: AppLocalizations.of(context).syncedWorkoutDetailAvg,
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
              label: AppLocalizations.of(context).strengthOverviewCardMax,
              value: '${_formatValue(max)} $unit',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps the viewed [MeasurementType] to its matching [TrendMetric] so the
  /// Custom Trends explorer opens pre-selected to this measurement. Matches on
  /// the shared `apiValue`/`measurementType` key; returns null when unmapped
  /// (the route then falls back to the default Weight metric).
  TrendMetric? _trendMetricForType(MeasurementType type) {
    for (final m in TrendMetric.values) {
      if (m.measurementType == type.apiValue) return m;
    }
    return null;
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
        title: Text(AppLocalizations.of(context).workoutHistoryImportDeleteEntry),
        content: Text(
          'Delete this ${entry.type.displayName} entry from ${DateFormat('MMM d, y').format(entry.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context).buttonDelete),
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

  /// Returns the start date for the currently selected period.
  /// Used by both filtering and chart X-axis range.
  ///
  /// "1D" means *today in the user's local timezone* — anchored to midnight,
  /// not "rolling 24h." Otherwise an entry from this morning falls outside
  /// the filter once the user opens the screen later in the day (caught
  /// 2026-05-12). See [[feedback_user_local_time_only]].
  DateTime _periodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '1d':
        return DateTime(now.year, now.month, now.day);
      case '3d':
        return now.subtract(const Duration(days: 3));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '6m':
        return now.subtract(const Duration(days: 182));
      case 'ytd':
        return DateTime(now.year, 1, 1);
      case '1y':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;
    final cutoff = _periodStartDate();
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
    final cyan = ref.colors(context).accent;
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
                  AppLocalizations.of(context).measurementsScreenPartNotesOptional,
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
                    hintText: AppLocalizations.of(context).measurementsScreenPartAddAnyNotes,
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
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).measurementsScreenPartPleaseEnterAValue),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final value = double.tryParse(valueText);
                            if (value == null || value <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).recordAttemptPleaseEnterAValid),
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
                              try {
                                final success = await ref
                                    .read(measurementsProvider.notifier)
                                    .recordMeasurement(
                                      userId: auth.user!.id,
                                      type: _type,
                                      value: valueToStore,
                                      unit: unitToStore,
                                      notes: notes.isNotEmpty ? notes : null,
                                    );
                                if (!success) {
                                  throw StateError(
                                      '${_type.displayName} save returned false');
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('${_type.displayName} recorded'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                    '[MeasurementDetail] record failed: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Couldn't save ${_type.displayName.toLowerCase()}. Try again."),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
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
                        : Text(
                            AppLocalizations.of(context).buttonSave,
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

/// Frosted-glass share icon. Mirrors GlassBackButton's circle shape so the
/// header reads as a symmetric pair of floating affordances.
class _ShareIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _ShareIconButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black87;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: fg.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.ios_share_rounded, size: 18, color: fg),
        ),
      ),
    );
  }
}
