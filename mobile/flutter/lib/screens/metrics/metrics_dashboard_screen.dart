import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/stat_typography.dart';
import '../../core/services/posthog_service.dart';
import '../../core/stats/stat_trend.dart';
import '../../core/stats/stat_trend_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/custom_metrics_provider.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/repositories/metrics_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/trends/trend_correlation.dart' show TrendPoint;
import '../../l10n/generated/app_localizations.dart';
import 'widgets/key_metrics_grid.dart';
import 'widgets/health_checks_section.dart';
import '../common/app_refresh_indicator.dart';

class MetricsDashboardScreen extends ConsumerStatefulWidget {
  const MetricsDashboardScreen({super.key});

  @override
  ConsumerState<MetricsDashboardScreen> createState() =>
      _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState
    extends ConsumerState<MetricsDashboardScreen> {
  String _selectedPeriod = '1d';
  String _selectedMetric = 'weight';

  static const _periods = [
    {'label': '1D', 'value': '1d'},
    {'label': '7D', 'value': '7d'},
    {'label': '30D', 'value': '30d'},
    {'label': '90D', 'value': '90d'},
    {'label': 'All', 'value': 'all'},
  ];

  List<Map<String, Object>> _buildMetrics(AppLocalizations l10n) => [
    {'label': l10n.metricsDashboardWeight, 'value': 'weight', 'icon': Icons.monitor_weight, 'unit': 'kg'},
    {'label': l10n.metricsDashboardBodyFat, 'value': 'body_fat', 'icon': Icons.percent, 'unit': '%'},
    {'label': l10n.metricsDashboardMuscleMass, 'value': 'muscle_mass', 'icon': Icons.fitness_center, 'unit': 'kg'},
    {'label': l10n.metricsDashboardBmi, 'value': 'bmi', 'icon': Icons.speed, 'unit': ''},
    {'label': l10n.metricsDashboardHeartRate, 'value': 'resting_heart_rate', 'icon': Icons.favorite, 'unit': 'bpm'},
    {'label': l10n.metricsDashboardCalories, 'value': 'calories_burned', 'icon': Icons.local_fire_department, 'unit': 'kcal'},
  ];

  @override
  void initState() {
    super.initState();
    ref.read(posthogServiceProvider).capture(eventName: 'metrics_dashboard_viewed');
    // Non-blocking: defer the metrics load until after the first frame so the
    // skeleton paints instantly. The StateNotifier retains any data from an
    // earlier visit this session, so a return shows it immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    final auth = ref.read(authStateProvider);
    if (auth.user != null) {
      await ref.read(metricsProvider.notifier).loadMetrics(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metricsState = ref.watch(metricsProvider);
    final metrics = _buildMetrics(l10n);
    final selectedMetricInfo = metrics.firstWhere(
      (m) => m['value'] == _selectedMetric,
      orElse: () => metrics.first,
    );

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: _loadMetrics,
          color: AppColors.cyan,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.metricsDashboardHealthMetrics,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.metricsDashboardTrackYourProgressOver,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              // Key metrics grid — Google-Health-style at-a-glance cards
              // (weight, energy, intake, macros, steps, exercise days,
              // mindfulness). Sources from data we already collect; each card
              // has a true No-data state. The interactive trends (period
              // selector + per-metric chart) live below as a deeper dive.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const KeyMetricsGrid(),
                ).animate().fadeIn(delay: 130.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const HealthChecksSection(),
                ).animate().fadeIn(delay: 160.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.metricsDashboardTrends,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Period selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = period['value']!),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cyan.withOpacity(0.2)
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.cyan
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                period['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.cyan
                                      : AppColors.textSecondary,
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

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Current metrics cards. Cache-first: when the StateNotifier
              // already holds metrics they render instantly; on a cold load a
              // layout-matched 2x2 skeleton grid stands in for the four cards.
              if (metricsState.latestMetrics != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCurrentMetricsGrid(metricsState.latestMetrics!),
                  ).animate().fadeIn(delay: 200.ms),
                )
              else if (metricsState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _MetricsGridSkeleton(),
                  ),
                ),

              // User-defined custom metric cards (rendered with the same big
              // StatNumber + delta + sparkline treatment as the built-ins).
              SliverToBoxAdapter(
                child: _CustomMetricsSection(
                  range: _trendRange,
                  onLog: _logCustomMetric,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Metric selector for chart
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: metrics.length,
                    itemBuilder: (context, index) {
                      final metric = metrics[index];
                      final isSelected = _selectedMetric == metric['value'];
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMetric = metric['value'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cyan.withOpacity(0.2)
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.cyan
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  metric['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.cyan
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  metric['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.cyan
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 250.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Chart
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: metricsState.isLoading
                      ? const SkeletonBox(height: 218, radius: 12)
                      : metricsState.history.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedMetricInfo['icon'] as IconData,
                                    size: 48,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.metricsDashboardNoMetricDataYet(selectedMetricInfo['label'] as String),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _showAddMetricSheet(context),
                                    child: Text(l10n.metricsDashboardAddEntry),
                                  ),
                                ],
                              ),
                            )
                          : _buildChart(metricsState.history),
                ).animate().fadeIn(delay: 300.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick stats section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.metricsDashboardQuickStats,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickStatCard(
                              title: l10n.metricsDashboardWorkoutsThisWeek,
                              value: '${metricsState.latestMetrics?.workoutsCompleted ?? 0}',
                              icon: Icons.fitness_center,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickStatCard(
                              title: l10n.metricsDashboardActiveStreak,
                              value: '${metricsState.latestMetrics?.streak ?? 0} days',
                              icon: Icons.local_fire_department,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickStatCard(
                              title: l10n.metricsDashboardTotalTime,
                              value: '${(metricsState.latestMetrics?.totalMinutes ?? 0) ~/ 60}h',
                              icon: Icons.timer,
                              color: AppColors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickStatCard(
                              title: l10n.metricsDashboardCaloriesBurned,
                              value: '${metricsState.latestMetrics?.caloriesBurned ?? 0}',
                              icon: Icons.local_fire_department,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // Add metric FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMetricSheet(context),
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.pureBlack,
        child: const Icon(Icons.add),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  /// Maps the dashboard's selected period chip to the trend engine's range.
  /// Defaults to 30 days (the redesign's default window) for '1d' / unknown.
  TrendRange get _trendRange => switch (_selectedPeriod) {
        '7d' => TrendRange.d7,
        '30d' => TrendRange.d30,
        '90d' => TrendRange.d90,
        'all' => TrendRange.all,
        _ => TrendRange.d30,
      };

  Widget _buildCurrentMetricsGrid(HealthMetrics metrics) {
    final l10n = AppLocalizations.of(context)!;
    final range = _trendRange;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardWeight,
                value: metrics.weightKg?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                icon: Icons.monitor_weight,
                color: AppColors.cyan,
                trendMetric: TrendMetric.weight,
                range: range,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardBodyFat,
                value: metrics.bodyFatPercent?.toStringAsFixed(1) ?? '--',
                unit: '%',
                icon: Icons.percent,
                color: AppColors.purple,
                trendMetric: TrendMetric.bodyFat,
                range: range,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardBmi,
                value: metrics.bmi?.toStringAsFixed(1) ?? '--',
                unit: '',
                icon: Icons.speed,
                color: _getBmiColor(metrics.bmi),
                trendMetric: TrendMetric.bmi,
                range: range,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardRestingHr,
                value: '${metrics.restingHeartRate ?? '--'}',
                unit: 'bpm',
                icon: Icons.favorite,
                color: AppColors.error,
                trendMetric: TrendMetric.restingHeartRate,
                range: range,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(List<MetricHistoryEntry> history) {
    if (history.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.metricsDashboardNoDataAvailable, style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    // Filter history to the selected period window
    final cutoff = switch (_selectedPeriod) {
      '1d'  => DateTime.now().subtract(const Duration(days: 1)),
      '7d'  => DateTime.now().subtract(const Duration(days: 7)),
      '30d' => DateTime.now().subtract(const Duration(days: 30)),
      '90d' => DateTime.now().subtract(const Duration(days: 90)),
      _     => null, // 'all'
    };
    final filtered = cutoff == null
        ? history
        : history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
    final display = filtered.isEmpty ? history : filtered;

    final spots = display.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    var minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.95;
    var maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.05;
    // Guard a degenerate range (all values equal, e.g. all 0) — a zero
    // horizontalInterval makes fl_chart assert / NaN (edge case C).
    if (maxY - minY < 1e-6) {
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
            color: AppColors.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (display.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < display.length) {
                  final date = display[index].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
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
            color: AppColors.cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.cyan,
                  strokeWidth: 2,
                  strokeColor: AppColors.pureBlack,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withOpacity(0.3),
                  AppColors.cyan.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.nearBlack,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = index < display.length
                    ? display[index].recordedAt
                    : DateTime.now();
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}\n${date.month}/${date.day}',
                  const TextStyle(
                    color: AppColors.textPrimary,
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

  Color _getBmiColor(double? bmi) {
    if (bmi == null) return AppColors.textMuted;
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  void _showAddMetricSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => _AddMetricSheet(
        onSubmit: (metricType, value) async {
          final auth = ref.read(authStateProvider);
          if (auth.user != null) {
            await ref.read(metricsRepositoryProvider).recordMetric(
                  userId: auth.user!.id,
                  metricType: metricType,
                  value: value,
                );
            _loadMetrics();
          }
          if (mounted) Navigator.pop(context);
        },
        onSubmitCustom: (label, unit, direction, firstValue) async {
          final auth = ref.read(authStateProvider);
          if (auth.user == null) {
            if (mounted) Navigator.pop(context);
            return;
          }
          final repo = ref.read(metricsRepositoryProvider);
          try {
            final def = await repo.createCustomMetric(
              userId: auth.user!.id,
              label: label,
              unit: unit,
              goodDirection: direction,
            );
            // Optional first value: log it immediately so the new card has data.
            if (firstValue != null) {
              await repo.logCustomMetric(
                metricId: def.id,
                userId: auth.user!.id,
                value: firstValue,
              );
            }
            // Refresh the custom-metric list (and any history just seeded).
            ref.invalidate(customMetricsProvider);
            ref.invalidate(customMetricHistoryProvider);
          } catch (e) {
            debugPrint('❌ [Metrics] create custom metric failed: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not save the metric. Please try again.')),
              );
            }
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  /// Logs a new value for an existing custom metric via a small numeric dialog,
  /// then refreshes that metric's history + the definition list.
  Future<void> _logCustomMetric(CustomMetricDef def) async {
    final auth = ref.read(authStateProvider);
    if (auth.user == null) return;
    final value = await showDialog<double>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _LogCustomValueDialog(def: def),
    );
    if (value == null) return;
    try {
      await ref.read(metricsRepositoryProvider).logCustomMetric(
            metricId: def.id,
            userId: auth.user!.id,
            value: value,
          );
      ref.invalidate(customMetricsProvider);
      ref.invalidate(customMetricHistoryProvider);
    } catch (e) {
      debugPrint('❌ [Metrics] log custom metric failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the value. Please try again.')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Metrics Grid Skeleton
// ─────────────────────────────────────────────────────────────────

/// Layout-matched skeleton for the 2x2 current-metrics grid, shown on a cold
/// load instead of leaving the slot blank until the network resolves.
class _MetricsGridSkeleton extends StatelessWidget {
  const _MetricsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 116, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 116, radius: 16)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 116, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 116, radius: 16)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Metric Card
// ─────────────────────────────────────────────────────────────────

/// A built-in health-metric card: a big glanceable [StatNumber] plus a real
/// trend delta + sparkline pulled from the unified trend engine for this
/// metric. When the engine reports fewer than 2 points ([StatTrendData.hasTrend]
/// false) the trend area renders nothing rather than fabricating a flat line.
class _MetricCard extends ConsumerWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final TrendMetric trendMetric;
  final TrendRange range;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.trendMetric,
    required this.range,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync =
        ref.watch(statTrendProvider(TrendSeriesKey(trendMetric, range)));
    final data = trendAsync.valueOrNull;
    final hasTrend = data?.hasTrend ?? false;
    // The arrow in the header mirrors the delta direction (when we have one).
    final headerChange = hasTrend ? data!.change : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              if (headerChange != null && !headerChange.isFlat)
                Icon(
                  StatTrend.icon(headerChange.direction),
                  size: 16,
                  color: StatTrend.color(
                    context,
                    headerChange.direction,
                    data!.goodDirection,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StatNumber(
            value: value,
            unit: unit.isEmpty ? null : unit,
            size: StatType.primary,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: StatType.label,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasTrend) ...[
            const SizedBox(height: 8),
            StatDeltaLine(
              change: data!.change!,
              good: data.goodDirection,
              unit: data.unit,
            ),
            const SizedBox(height: 6),
            Sparkline(points: data.points, color: color, height: 32),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Stat Card
// ─────────────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatNumber(
                  value: value,
                  size: StatType.secondary,
                  color: color,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: StatType.labelSm,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Metric Sheet
// ─────────────────────────────────────────────────────────────────

class _AddMetricSheet extends StatefulWidget {
  final Function(String metricType, double value) onSubmit;

  /// Called when the user defines a brand-new custom metric. [firstValue] is
  /// null when they leave the value field blank (define now, log later).
  final Future<void> Function(
    String label,
    String unit,
    GoodDirection direction,
    double? firstValue,
  ) onSubmitCustom;

  const _AddMetricSheet({required this.onSubmit, required this.onSubmitCustom});

  @override
  State<_AddMetricSheet> createState() => _AddMetricSheetState();
}

/// Sentinel preset value that switches the sheet into custom-definition mode.
const String _kCustomMetricSentinel = '__custom__';

class _AddMetricSheetState extends State<_AddMetricSheet> {
  String _selectedMetric = 'weight';
  final _valueController = TextEditingController();

  // Custom-metric definition fields (only used when _isCustomMode).
  final _customNameController = TextEditingController();
  final _customUnitController = TextEditingController();
  GoodDirection _customDirection = GoodDirection.neutral;

  bool get _isCustomMode => _selectedMetric == _kCustomMetricSentinel;

  List<Map<String, String>> _buildMetricOptions(AppLocalizations l10n) => [
    {'label': l10n.metricsDashboardWeight, 'value': 'weight', 'unit': 'kg'},
    {'label': l10n.metricsDashboardBodyFatPct, 'value': 'body_fat', 'unit': '%'},
    {'label': l10n.metricsDashboardMuscleMass, 'value': 'muscle_mass', 'unit': 'kg'},
    {'label': l10n.metricsDashboardWaist, 'value': 'waist', 'unit': 'cm'},
    {'label': l10n.metricsDashboardHip, 'value': 'hip', 'unit': 'cm'},
    {'label': l10n.metricsDashboardRestingHeartRate, 'value': 'resting_heart_rate', 'unit': 'bpm'},
    {'label': 'Custom metric', 'value': _kCustomMetricSentinel, 'unit': ''},
  ];

  @override
  void dispose() {
    _valueController.dispose();
    _customNameController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  /// Definition fields for a brand-new custom metric: name, unit, and a 3-way
  /// "which way is good" selector. The first-value field is optional (define
  /// now, log later).
  List<Widget> _buildCustomFields(AppLocalizations l10n) {
    const labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 1,
    );
    InputDecoration field(String hint, {String? suffix}) => InputDecoration(
          hintText: hint,
          suffixText: suffix,
          filled: true,
          fillColor: AppColors.elevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    return [
      const Text('NAME', style: labelStyle),
      const SizedBox(height: 8),
      TextField(
        controller: _customNameController,
        textCapitalization: TextCapitalization.words,
        decoration: field('e.g. Sleep quality, Mood, HRV'),
      ),
      const SizedBox(height: 20),
      const Text('UNIT (OPTIONAL)', style: labelStyle),
      const SizedBox(height: 8),
      TextField(
        controller: _customUnitController,
        decoration: field('e.g. hours, score, ms'),
      ),
      const SizedBox(height: 20),
      const Text('DIRECTION', style: labelStyle),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _directionChip('Higher is better', GoodDirection.higher),
          _directionChip('Lower is better', GoodDirection.lower),
          _directionChip('No preference', GoodDirection.neutral),
        ],
      ),
      const SizedBox(height: 20),
      const Text('FIRST VALUE (OPTIONAL)', style: labelStyle),
      const SizedBox(height: 8),
      TextField(
        controller: _valueController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: field(
          l10n.metricsDashboardEnterValue,
          suffix: _customUnitController.text.trim().isEmpty
              ? null
              : _customUnitController.text.trim(),
        ),
      ),
    ];
  }

  Widget _directionChip(String label, GoodDirection direction) {
    final isSelected = _customDirection == direction;
    return GestureDetector(
      onTap: () => setState(() => _customDirection = direction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.2)
              : AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _submitCustom() {
    final name = _customNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the metric a name first.')),
      );
      return;
    }
    final unit = _customUnitController.text.trim();
    // Empty value field means "define now, log later" (empty input = no value,
    // never a fabricated zero).
    final raw = _valueController.text.trim();
    final firstValue = raw.isEmpty ? null : double.tryParse(raw);
    widget.onSubmitCustom(name, unit, _customDirection, firstValue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metricOptions = _buildMetricOptions(l10n);
    final selectedOption = metricOptions.firstWhere(
      (m) => m['value'] == _selectedMetric,
    );

    return GlassSheet(
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
              l10n.metricsDashboardAddMetric,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Metric type selector
            Text(
              l10n.metricsDashboardMetricType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metricOptions.map((option) {
                final isSelected = _selectedMetric == option['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMetric = option['value'] ?? _selectedMetric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan.withOpacity(0.2)
                          : AppColors.elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      option['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Either the preset value input, or the custom-metric definition
            // fields. The preset path is untouched.
            if (_isCustomMode)
              ..._buildCustomFields(l10n)
            else ...[
              Text(
                l10n.metricsDashboardValue,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: l10n.metricsDashboardEnterValue,
                  suffixText: selectedOption['unit'],
                  filled: true,
                  fillColor: AppColors.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCustomMode
                    ? _submitCustom
                    : () {
                        final value = double.tryParse(_valueController.text);
                        if (value != null) {
                          widget.onSubmit(_selectedMetric, value);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.pureBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.metricsDashboardSave,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Custom metrics section + card
// ─────────────────────────────────────────────────────────────────

/// Renders the user's custom metric definitions as a 2-up grid of cards,
/// matching the built-in metric grid. Renders nothing (no header, no empty
/// chrome) when the user has no custom metrics, so the section is invisible
/// until they create one.
class _CustomMetricsSection extends ConsumerWidget {
  final TrendRange range;
  final Future<void> Function(CustomMetricDef def) onLog;

  const _CustomMetricsSection({required this.range, required this.onLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defsAsync = ref.watch(customMetricsProvider);
    final defs =
        defsAsync.valueOrNull?.where((d) => d.isActive).toList() ??
            const <CustomMetricDef>[];
    if (defs.isEmpty) return const SizedBox.shrink();

    // Lay out in pairs so each card is half-width, mirroring the built-in grid.
    final rows = <Widget>[];
    for (var i = 0; i < defs.length; i += 2) {
      final left = defs[i];
      final right = (i + 1 < defs.length) ? defs[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CustomMetricCard(def: left, range: range, onLog: onLog),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _CustomMetricCard(
                      def: right, range: range, onLog: onLog),
            ),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}

/// A single custom-metric card: big [StatNumber] for the latest logged value
/// plus a [StatDeltaLine] + [Sparkline] computed from the metric's history.
/// Tap to log a new value, long-press also logs (a quick affordance). With
/// fewer than two logs only the number shows (never a fabricated trend).
class _CustomMetricCard extends ConsumerWidget {
  final CustomMetricDef def;
  final TrendRange range;
  final Future<void> Function(CustomMetricDef def) onLog;

  const _CustomMetricCard({
    required this.def,
    required this.range,
    required this.onLog,
  });

  /// A stable, distinct accent per custom metric (deterministic from its key)
  /// so two cards don't share a color. Neutral metrics still get a hue here;
  /// the trend coloring (green/red) is what stays neutral.
  Color get _accent {
    const palette = [
      AppColors.cyan,
      AppColors.purple,
      AppColors.success,
      AppColors.orange,
    ];
    return palette[def.key.hashCode.abs() % palette.length];
  }

  /// Maps the dashboard range to a `days` lookback for the history fetch.
  /// `all` uses a wide 5-year window (the math only needs first vs last).
  int _daysFor(TrendRange r) => r.days == 0 ? 1825 : r.days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _accent;
    final pointsAsync = ref.watch(
      customMetricHistoryProvider(
        CustomMetricHistoryArgs(def.id, days: _daysFor(range)),
      ),
    );
    final points = pointsAsync.valueOrNull ?? const <TrendPoint>[];
    final latest = points.isNotEmpty ? points.last.value : null;
    final change = StatChange.fromPoints(points);
    final hasTrend = points.length >= 2 && change != null;

    return GestureDetector(
      onTap: () => onLog(def),
      onLongPress: () => onLog(def),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.insights_rounded, size: 18, color: color),
                ),
                const Spacer(),
                if (hasTrend && !change.isFlat)
                  Icon(
                    StatTrend.icon(change.direction),
                    size: 16,
                    color: StatTrend.color(
                        context, change.direction, def.goodDirection),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StatNumber(
              value: latest != null ? StatTrend.fmt(latest) : '--',
              unit: def.unit.isEmpty ? null : def.unit,
              size: StatType.primary,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              def.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: StatType.label,
                color: AppColors.textSecondary,
              ),
            ),
            if (hasTrend) ...[
              const SizedBox(height: 8),
              StatDeltaLine(
                change: change,
                good: def.goodDirection,
                unit: def.unit,
              ),
              const SizedBox(height: 6),
              Sparkline(points: points, color: color, height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Log custom value dialog
// ─────────────────────────────────────────────────────────────────

/// A minimal numeric-entry dialog for logging a new value of a custom metric.
/// Returns the parsed value via `Navigator.pop`, or null on cancel.
class _LogCustomValueDialog extends StatefulWidget {
  final CustomMetricDef def;

  const _LogCustomValueDialog({required this.def});

  @override
  State<_LogCustomValueDialog> createState() => _LogCustomValueDialogState();
}

class _LogCustomValueDialogState extends State<_LogCustomValueDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.nearBlack,
      title: Text(
        'Log ${widget.def.label}',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Enter value',
          suffixText: widget.def.unit.isEmpty ? null : widget.def.unit,
          filled: true,
          fillColor: AppColors.elevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: AppColors.pureBlack,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

