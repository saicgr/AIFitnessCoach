import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

/// A compact sparkline chart showing exercise weight progression
/// over the last few sessions. Designed to be embedded inline
/// within exercise cards or list tiles (~70px tall).
///
/// The parent is responsible for fetching and passing [weights].
/// When [isLoading] is true a shimmer placeholder is shown.
/// When fewer than 2 data points are available a "Not enough history"
/// message is displayed instead of the chart.
class ExerciseMiniChart extends StatelessWidget {
  /// Historical max weights per session, oldest first.
  final List<double> weights;

  /// Optional date labels corresponding to each weight entry.
  final List<String>? dates;

  /// Whether the current theme is dark mode.
  final bool isDark;

  /// Accent color used for the line, dots, and gradient fill.
  final Color accentColor;

  /// Called when the user taps the chart (e.g. to navigate to full history).
  final VoidCallback? onTap;

  /// When true, shows a shimmer loading placeholder instead of the chart.
  final bool isLoading;

  const ExerciseMiniChart({
    super.key,
    required this.weights,
    this.dates,
    required this.isDark,
    required this.accentColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 70,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return _buildShimmer(context);
    }

    if (weights.length < 2) {
      return _buildInsufficientData(context);
    }

    return _buildChart(context);
  }

  // ---------------------------------------------------------------------------
  // Shimmer loading placeholder
  // ---------------------------------------------------------------------------
  Widget _buildShimmer(BuildContext context) {
    final baseColor = isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    final highlightColor = isDark
        ? AppColors.glassSurface
        : AppColorsLight.glassSurface;

    return _ShimmerContainer(
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  // ---------------------------------------------------------------------------
  // Not enough data state
  // ---------------------------------------------------------------------------
  Widget _buildInsufficientData(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 16,
            color: mutedColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Not enough history',
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sparkline chart
  // ---------------------------------------------------------------------------
  Widget _buildChart(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), weights[i]));
    }

    final minWeight = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Add 10% padding so the line doesn't touch edges
    final range = maxWeight - minWeight;
    final padding = range == 0 ? maxWeight * 0.1 : range * 0.15;
    final minY = (minWeight - padding).clamp(0.0, double.infinity);
    final maxY = maxWeight + padding;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (weights.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: accentColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLast = index == weights.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 5 : 3,
                    color: isLast
                        ? accentColor
                        : accentColor.withValues(alpha: 0.7),
                    strokeWidth: isLast ? 2.5 : 1.5,
                    strokeColor: isDark
                        ? AppColors.pureBlack
                        : AppColorsLight.pureWhite,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              tooltipRoundedRadius: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  final weightStr = spot.y % 1 == 0
                      ? '${spot.y.toInt()} kg'
                      : '${spot.y.toStringAsFixed(1)} kg';

                  String label = weightStr;
                  if (dates != null &&
                      index >= 0 &&
                      index < dates!.length) {
                    label = '$weightStr\n${dates![index]}';
                  }

                  return LineTooltipItem(
                    label,
                    TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: accentColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: accentColor,
                        strokeWidth: 2,
                        strokeColor: isDark
                            ? AppColors.pureBlack
                            : AppColorsLight.pureWhite,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}

// =============================================================================
// Shimmer animation widget
// =============================================================================

class _ShimmerContainer extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerContainer({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
