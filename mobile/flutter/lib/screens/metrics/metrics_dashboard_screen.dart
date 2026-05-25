import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/repositories/metrics_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/glass_sheet.dart';
import '../../l10n/generated/app_localizations.dart';

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
        child: RefreshIndicator(
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
                        padding: const EdgeInsets.only(right: 8),
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

  Widget _buildCurrentMetricsGrid(HealthMetrics metrics) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardWeight,
                value: metrics.weightKg?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                icon: Icons.monitor_weight,
                color: AppColors.cyan,
                trend: _getTrend(metrics.weightKg, metrics.previousWeightKg),
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
                trend: _getTrend(metrics.bodyFatPercent, null, lowerIsBetter: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: l10n.metricsDashboardBmi,
                value: metrics.bmi?.toStringAsFixed(1) ?? '--',
                unit: '',
                icon: Icons.speed,
                color: _getBmiColor(metrics.bmi),
                trend: null,
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
                trend: null,
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

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.05;

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

  String? _getTrend(double? current, double? previous, {bool lowerIsBetter = false}) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff.abs() < 0.1) return null;
    final isPositive = lowerIsBetter ? diff < 0 : diff > 0;
    return isPositive ? 'up' : 'down';
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
      ),
    );
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? trend;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
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
              if (trend != null)
                Icon(
                  trend == 'up' ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trend == 'up' ? AppColors.success : AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
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

  const _AddMetricSheet({required this.onSubmit});

  @override
  State<_AddMetricSheet> createState() => _AddMetricSheetState();
}

class _AddMetricSheetState extends State<_AddMetricSheet> {
  String _selectedMetric = 'weight';
  final _valueController = TextEditingController();

  List<Map<String, String>> _buildMetricOptions(AppLocalizations l10n) => [
    {'label': l10n.metricsDashboardWeight, 'value': 'weight', 'unit': 'kg'},
    {'label': l10n.metricsDashboardBodyFatPct, 'value': 'body_fat', 'unit': '%'},
    {'label': l10n.metricsDashboardMuscleMass, 'value': 'muscle_mass', 'unit': 'kg'},
    {'label': l10n.metricsDashboardWaist, 'value': 'waist', 'unit': 'cm'},
    {'label': l10n.metricsDashboardHip, 'value': 'hip', 'unit': 'cm'},
    {'label': l10n.metricsDashboardRestingHeartRate, 'value': 'resting_heart_rate', 'unit': 'bpm'},
  ];

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
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

            // Value input
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
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
