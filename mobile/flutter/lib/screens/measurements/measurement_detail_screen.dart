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
                      padding: const EdgeInsetsDirectional.fromSTEB(56, 56, 16, 8),
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

                  // Range-aware hero: average over the selected range + the
                  // change across the period (Google-Health style). Computed
                  // from filteredHistory so it tracks the selected pill, not a
                  // single "latest" snapshot.
                  SliverToBoxAdapter(
                    child: _buildHeroCard(
                  filteredHistory,
                  latest: latest,
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

              // Stats summary (MIN / AVG / MAX) — only honest with ≥2 entries.
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

              // Period breakdown — weekly (30D+) or daily (≤7D) sub-period
              // averages, mirroring Google Health's weekly breakdown list.
              SliverToBoxAdapter(
                child: _buildPeriodBreakdown(
                  filteredHistory,
                  unit: unit,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 255.ms),
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
                        AppLocalizations.of(context)!.measurementDetailScreenEntries(filteredHistory.length),
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

              // About <metric> — short, accurate explainer.
              SliverToBoxAdapter(
                child: _buildAboutSection(
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 320.ms),
              ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              ),
            ),

            // Floating back button
            PositionedDirectional(top: 8,
              start: 8,
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
            PositionedDirectional(top: 8,
              end: 8,
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
        tooltip: AppLocalizations.of(context)!.measurementDetailScreenLog(_type.displayName),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  /// Range-aware hero. Big number = the AVERAGE across the selected range
  /// (Google-Health "98.7 kg avg"); the sub-line states the change across the
  /// period ("0.8 kg lost over period"), coloured by direction.
  ///
  /// Honest single-point state: with exactly one entry in the range there is
  /// no average and no trend, so we show that lone value with a "log more to
  /// see a trend" hint — never a fabricated avg/delta.
  Widget _buildHeroCard(
    List<MeasurementEntry> history, {
    required MeasurementEntry? latest,
    required String unit,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final values = history.map((e) => e.getValueInUnit(_isMetric)).toList();
    final hasData = values.isNotEmpty;
    final isSingle = values.length == 1;

    // Big number: the range average when we have a trend; the lone value when
    // there's a single entry; the all-time latest when the range is empty.
    final double? heroValue = hasData
        ? (isSingle
            ? values.first
            : values.reduce((a, b) => a + b) / values.length)
        : latest?.getValueInUnit(_isMetric);

    final String heroLabel = !hasData
        ? 'No entries in this range'
        : isSingle
            ? '1 entry — log more to see a trend'
            : '${_formatValue(heroValue!)} $unit avg · ${_rangeLabel()}';

    // Period change = newest minus oldest within the range. history is
    // newest-first, so .first is newest, .last is oldest.
    final double? periodChange = history.length >= 2
        ? history.first.getValueInUnit(_isMetric) -
            history.last.getValueInUnit(_isMetric)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            cyan.withValues(alpha: 0.15),
            cyan.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big value + unit on one consistent baseline.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  heroValue != null ? _formatValue(heroValue) : '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 46,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: cyan,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(bottom: 8, start: 6),
                child: Text(
                  unit,
                  style: TextStyle(fontSize: 18, color: textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            heroLabel,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          if (periodChange != null && periodChange.abs() >= 0.05) ...[
            const SizedBox(height: 12),
            _buildPeriodChangeIndicator(periodChange, unit, isDark: isDark),
          ] else if (latest != null && hasData) ...[
            const SizedBox(height: 8),
            Text(
              'Last logged ${DateFormat('MMM d, yyyy').format(latest.recordedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: textMuted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Human-readable label for the active range pill (e.g. "last 30 days").
  String _rangeLabel() {
    switch (_selectedPeriod) {
      case '1d':
        return 'today';
      case '3d':
        return 'last 3 days';
      case '7d':
        return 'last 7 days';
      case '30d':
        return 'last 30 days';
      case '90d':
        return 'last 90 days';
      case '6m':
        return 'last 6 months';
      case 'ytd':
        return 'year to date';
      case '1y':
        return 'last year';
      default:
        return 'all time';
    }
  }

  /// Directional "X gained/lost over period" pill. Uses a verb that reads
  /// naturally per metric, and colours by whether the direction is desirable.
  Widget _buildPeriodChangeIndicator(double change, String unit,
      {required bool isDark}) {
    final isUp = change > 0;
    // For weight and body fat a decrease is the desirable direction.
    final isDecreaseGood =
        _type == MeasurementType.weight || _type == MeasurementType.bodyFat;
    final isGoodChange = isDecreaseGood ? !isUp : isUp;

    final color = isGoodChange ? AppColors.success : AppColors.error;

    // Verb pool keeps copy human: weight/fat read "lost/gained"; girths read
    // "down/up". Exact magnitude is substituted, never rounded to theatre.
    final String verb;
    if (isDecreaseGood) {
      verb = isUp ? 'gained' : 'lost';
    } else {
      verb = isUp ? 'up' : 'down';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${_formatValue(change.abs())} $unit $verb over ${_rangeLabel()}',
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
            '${_type.displayName} over time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            SizedBox(
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
                      AppLocalizations.of(context)
                          .measurementDetailTrySelectingAWider,
                      style: TextStyle(
                          color: textMuted.withValues(alpha: 0.6),
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showAddMeasurementSheet(context),
                      child: Text(
                          AppLocalizations.of(context).metricsDashboardAddEntry,
                          style: TextStyle(color: cyan)),
                    ),
                  ],
                ),
              ),
            )
          else if (history.length < 2)
            // A single point can't form a trend line. Show the lone value as a
            // marker with an honest "not enough to chart" affordance rather
            // than a broken single-tick axis.
            _buildSinglePointChart(
              history.first,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              cyan: cyan,
            )
          else
            _buildChart(history,
                cyan: cyan, textMuted: textMuted, isDark: isDark),
        ],
      ),
    );
  }

  /// Single-entry chart affordance: a centred dot marker carrying the lone
  /// value + date, with a one-line "log again to start a trend" hint. No axis,
  /// no fake second point.
  Widget _buildSinglePointChart(
    MeasurementEntry entry, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: cyan,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cyan.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_formatValue(entry.getValueInUnit(_isMetric))} $unit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(entry.recordedAt),
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 10),
            Text(
              'Log this again to start a trend line.',
              style: TextStyle(
                  fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Athletes')),
            HorizontalLine(y: 24, color: Colors.cyan.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.cyan.withOpacity(0.7)),
                labelResolver: (_) => 'Fitness')),
            HorizontalLine(y: 31, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'Obese')),
          ];
        } else {
          return [
            HorizontalLine(y: 13, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Athletes')),
            HorizontalLine(y: 17, color: Colors.cyan.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.cyan.withOpacity(0.7)),
                labelResolver: (_) => 'Fitness')),
            HorizontalLine(y: 24, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'Obese')),
          ];
        }
      case MeasurementType.waist:
        if (g == 'female') {
          return [
            HorizontalLine(y: 80, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Healthy')),
            HorizontalLine(y: 88, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7)),
                labelResolver: (_) => 'High Risk')),
          ];
        } else {
          return [
            HorizontalLine(y: 94, color: Colors.green.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
                style: TextStyle(fontSize: 9, color: Colors.green.withOpacity(0.7)),
                labelResolver: (_) => 'Healthy')),
            HorizontalLine(y: 102, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, // rtl-keep: fl_chart HorizontalLineLabel requires Alignment
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
    // MIN/AVG/MAX only mean something with at least 2 entries. With one entry
    // all three collapse to the same value ("100/100/100" theatre) — suppress
    // it; the hero card already shows the lone value honestly.
    if (history.length < 2) return const SizedBox.shrink();

    final values = history.map((e) => e.getValueInUnit(_isMetric)).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    AppLocalizations.of(context)!.measurementDetailScreenLog2(_type.displayName),
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
                                          Text(AppLocalizations.of(context)!.measurementDetailScreenRecorded(_type.displayName)),
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
                                          AppLocalizations.of(context)!.measurementDetailScreenCouldnTSaveTry(_type.displayName.toLowerCase())),
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
