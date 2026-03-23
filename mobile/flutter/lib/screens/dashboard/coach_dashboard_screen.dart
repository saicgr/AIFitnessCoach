import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/gradient_circular_progress_indicator.dart';
import '../../widgets/pill_app_bar.dart';

/// Coach Dashboard — a "glance" view of the athlete's week.
///
/// Displays workout compliance, nutrition adherence, readiness sparkline,
/// measurement changes, today's mood, and active goal progress.
class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  Future<Map<String, dynamic>> _fetchDashboard() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null) throw Exception('User not authenticated');
    return ref.read(dashboardRepositoryProvider).getWeeklyDashboard(userId);
  }

  void _retry() {
    setState(() {
      _dashboardFuture = _fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PillAppBar(title: 'This Week'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoading.fullScreen();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString(), colorScheme);
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              final future = _fetchDashboard();
              setState(() => _dashboardFuture = future);
              await future;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. Compliance + Nutrition rings
                  _ComplianceRow(data: data, colors: colors),

                  const SizedBox(height: 12),

                  // 2. Readiness sparkline
                  _ReadinessSparkline(
                    data: data,
                    colors: colors,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 12),

                  // 3. Measurement highlights
                  _MeasurementCards(data: data, colors: colors),

                  const SizedBox(height: 12),

                  // 4. Mood today
                  _MoodCard(data: data, colors: colors, colorScheme: colorScheme),

                  const SizedBox(height: 12),

                  // 5. Active goals
                  _ActiveGoals(data: data, colors: colors, colorScheme: colorScheme),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 1. Compliance + Nutrition Rings
// ─────────────────────────────────────────────────────────────────

class _ComplianceRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeColors colors;

  const _ComplianceRow({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final compliance = data['workout_compliance'] as Map<String, dynamic>? ?? {};
    final completed = (compliance['completed'] as num?)?.toInt() ?? 0;
    final target = (compliance['target'] as num?)?.toInt() ?? 1;
    final workoutPct = (compliance['pct'] as num?)?.toDouble() ?? 0.0;

    final nutritionPct =
        (data['nutrition_adherence_pct'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _RingCard(
            label: 'Workouts',
            centerText: '$completed/$target',
            pct: workoutPct,
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RingCard(
            label: 'Nutrition',
            centerText: '${nutritionPct.round()}%',
            pct: nutritionPct,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _RingCard extends StatelessWidget {
  final String label;
  final String centerText;
  final double pct;
  final ThemeColors colors;

  const _RingCard({
    required this.label,
    required this.centerText,
    required this.pct,
    required this.colors,
  });

  /// Returns the status color based on percentage thresholds.
  Color _statusColor() {
    if (pct >= 75) return colors.success;
    if (pct >= 50) return colors.warning;
    return colors.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GradientCircularProgressIndicator(
                size: 100,
                strokeWidth: 10,
                value: (pct / 100).clamp(0.0, 1.0),
                gradientColors: [statusColor, statusColor],
                backgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              Text(
                centerText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 2. Readiness Sparkline (7-day fl_chart LineChart)
// ─────────────────────────────────────────────────────────────────

class _ReadinessSparkline extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeColors colors;
  final ColorScheme colorScheme;

  const _ReadinessSparkline({
    required this.data,
    required this.colors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final rawScores = data['readiness_scores'] as List<dynamic>? ?? [];

    if (rawScores.isEmpty) return const SizedBox.shrink();

    // Parse scores & build spots
    final spots = <FlSpot>[];
    final dayLabels = <int, String>{};
    final dateFormat = DateFormat('E'); // Mon, Tue, ...

    for (var i = 0; i < rawScores.length; i++) {
      final entry = rawScores[i] as Map<String, dynamic>;
      final score = (entry['readiness_score'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), score));

      final dateStr = entry['measured_at'] as String?;
      if (dateStr != null) {
        try {
          dayLabels[i] = dateFormat.format(DateTime.parse(dateStr));
        } catch (_) {
          dayLabels[i] = '';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Readiness',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final label =
                            dayLabels[value.toInt()] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: colors.accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: colors.accent,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toInt().toString(),
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 3. Measurement Highlights
// ─────────────────────────────────────────────────────────────────

class _MeasurementCards extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeColors colors;

  const _MeasurementCards({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final highlights =
        data['measurement_highlights'] as Map<String, dynamic>? ?? {};
    final weightChange =
        (highlights['weight_change_kg'] as num?)?.toDouble() ?? 0;
    final bfChange =
        (highlights['body_fat_change'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _ChangeCard(
            label: 'Weight',
            value: weightChange,
            unit: 'kg',
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChangeCard(
            label: 'Body Fat',
            value: bfChange,
            unit: '%',
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final ThemeColors colors;

  const _ChangeCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // For weight and body fat, a decrease is positive progress
    final isPositive = value <= 0;
    final arrow = value < 0 ? '\u2193' : (value > 0 ? '\u2191' : '');
    final changeColor = value == 0
        ? colorScheme.onSurfaceVariant
        : (isPositive ? colors.success : colors.error);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$arrow ${value.abs().toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 4. Mood Today
// ─────────────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeColors colors;
  final ColorScheme colorScheme;

  const _MoodCard({
    required this.data,
    required this.colors,
    required this.colorScheme,
  });

  static const _moodLabels = <String, String>{
    '\u{1F60A}': 'Feeling great',
    '\u{1F642}': 'Doing okay',
    '\u{1F610}': 'Neutral',
    '\u{1F614}': 'Not great',
    '\u{1F622}': 'Struggling',
    '\u{1F620}': 'Frustrated',
    '\u{1F634}': 'Exhausted',
    '\u{1F4AA}': 'Pumped up',
  };

  @override
  Widget build(BuildContext context) {
    final mood = data['mood_today'] as String?;
    if (mood == null || mood.isEmpty) return const SizedBox.shrink();

    final label = _moodLabels[mood] ?? 'Today\'s mood';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Text(mood, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 5. Active Goals
// ─────────────────────────────────────────────────────────────────

class _ActiveGoals extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeColors colors;
  final ColorScheme colorScheme;

  const _ActiveGoals({
    required this.data,
    required this.colors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final goals = data['upcoming_goals'] as List<dynamic>? ?? [];
    if (goals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Active Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...goals.map((g) {
            final goal = g as Map<String, dynamic>;
            final name = goal['name'] as String? ?? '';
            final pct =
                (goal['progress_pct'] as num?)?.toDouble() ?? 0;
            final progressColor = pct >= 75
                ? colors.success
                : (pct >= 50 ? colors.warning : colors.error);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor:
                          colorScheme.outline.withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
