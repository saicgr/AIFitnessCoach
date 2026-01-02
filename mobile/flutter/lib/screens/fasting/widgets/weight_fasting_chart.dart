import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting_impact.dart';

/// Chart showing weight trends on fasting vs non-fasting days
class WeightFastingChart extends StatelessWidget {
  final List<FastingDayData> dailyData;
  final double height;
  final bool isDark;

  const WeightFastingChart({
    super.key,
    required this.dailyData,
    this.height = 200,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Filter days with weight data
    final daysWithWeight = dailyData.where((d) => d.weight != null).toList();

    if (daysWithWeight.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: textMuted, size: 48),
              const SizedBox(height: 8),
              Text(
                'No weight data available',
                style: TextStyle(color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate min/max weight for scaling
    final weights = daysWithWeight.map((d) => d.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final paddedMin = minWeight - (range * 0.1);
    final paddedMax = maxWeight + (range * 0.1);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weight Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Fasting days', AppColors.cyan),
              const SizedBox(width: 16),
              _buildLegendItem('Non-fasting', textMuted),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _WeightChartPainter(
                data: daysWithWeight,
                minWeight: paddedMin,
                maxWeight: paddedMax,
                fastingColor: AppColors.cyan,
                nonFastingColor: textMuted.withOpacity(0.5),
                gridColor: textMuted.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<FastingDayData> data;
  final double minWeight;
  final double maxWeight;
  final Color fastingColor;
  final Color nonFastingColor;
  final Color gridColor;

  _WeightChartPainter({
    required this.data,
    required this.minWeight,
    required this.maxWeight,
    required this.fastingColor,
    required this.nonFastingColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final range = maxWeight - minWeight;
    if (range <= 0) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw data points
    final pointWidth = size.width / (data.length - 1).clamp(1, data.length);

    for (var i = 0; i < data.length; i++) {
      final day = data[i];
      if (day.weight == null) continue;

      final x = i * pointWidth;
      final normalizedWeight = (day.weight! - minWeight) / range;
      final y = size.height - (normalizedWeight * size.height);

      final pointPaint = Paint()
        ..color = day.isFastingDay ? fastingColor : nonFastingColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);

      // Draw line to next point
      if (i < data.length - 1 && data[i + 1].weight != null) {
        final nextX = (i + 1) * pointWidth;
        final nextNormalized = (data[i + 1].weight! - minWeight) / range;
        final nextY = size.height - (nextNormalized * size.height);

        final linePaint = Paint()
          ..color = gridColor
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
