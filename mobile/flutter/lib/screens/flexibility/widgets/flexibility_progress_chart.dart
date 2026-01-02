import 'package:flutter/material.dart';
import '../../../data/models/flexibility_assessment.dart';

/// Chart widget showing flexibility progress over time
class FlexibilityProgressChart extends StatelessWidget {
  final FlexibilityTrend trend;
  final double height;

  const FlexibilityProgressChart({
    super.key,
    required this.trend,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trend.trendData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    // Extract measurements and find range
    final measurements = trend.trendData
        .map((d) => (d['measurement'] as num).toDouble())
        .toList();
    final minVal = measurements.reduce((a, b) => a < b ? a : b);
    final maxVal = measurements.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final padding = range * 0.1; // 10% padding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Stats
        _buildSummaryStats(theme),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              data: trend.trendData,
              minValue: minVal - padding,
              maxValue: maxVal + padding,
              lineColor: theme.colorScheme.primary,
              fillColor: theme.colorScheme.primary.withOpacity(0.1),
              gridColor: theme.colorScheme.onSurface.withOpacity(0.1),
              textStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ) ?? const TextStyle(fontSize: 10),
              unit: trend.unit,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Legend
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    final isPositive = trend.isPositiveImprovement;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'First',
            value: _formatMeasurement(
              (trend.firstAssessment['measurement'] as num).toDouble(),
            ),
            rating: trend.firstAssessment['rating'] as String?,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Latest',
            value: _formatMeasurement(
              (trend.latestAssessment['measurement'] as num).toDouble(),
            ),
            rating: trend.latestAssessment['rating'] as String?,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Change',
            value: '${isPositive ? '+' : ''}${trend.improvementAbsolute.toStringAsFixed(1)}',
            suffix: trend.unit == 'degrees' ? '\u00B0' : ' ${trend.unit}',
            isPositive: isPositive,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${trend.totalAssessments} assessments',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 16),
        if (trend.ratingLevelsGained != 0) ...[
          Icon(
            trend.ratingLevelsGained > 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: trend.ratingLevelsGained > 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            '${trend.ratingLevelsGained.abs()} rating level${trend.ratingLevelsGained.abs() > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: trend.ratingLevelsGained > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatMeasurement(double value) {
    if (value == value.truncate()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String? rating;
  final bool? isPositive;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
    this.rating,
    this.isPositive,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color? valueColor;
    if (isPositive != null) {
      valueColor = isPositive! ? Colors.green : Colors.red;
    } else if (rating != null) {
      valueColor = _getRatingColor(rating!);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(
                    suffix!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: valueColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
          if (rating != null) ...[
            const SizedBox(height: 4),
            Text(
              rating!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _getRatingColor(rating!),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final TextStyle textStyle;
  final String unit;

  _ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textStyle,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final range = maxValue - minValue;
    if (range == 0) return;

    final leftPadding = 40.0;
    final rightPadding = 16.0;
    final topPadding = 16.0;
    final bottomPadding = 24.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = topPadding + (chartHeight * i / gridLines);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Draw Y-axis labels
      final value = maxValue - (range * i / gridLines);
      final textSpan = TextSpan(
        text: value.toStringAsFixed(value == value.truncate() ? 0 : 1),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculate points
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final measurement = (data[i]['measurement'] as num).toDouble();
      final x = leftPadding + (chartWidth * i / (data.length - 1).clamp(1, double.infinity));
      final y = topPadding + chartHeight - (chartHeight * (measurement - minValue) / range);
      points.add(Offset(x, y));
    }

    // Draw fill
    if (points.length > 1) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height - bottomPadding);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, size.height - bottomPadding);
      fillPath.close();

      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 5, pointBorderPaint);
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw point colors based on rating
    for (var i = 0; i < points.length; i++) {
      final rating = data[i]['rating'] as String?;
      if (rating != null) {
        final ratingColor = _getRatingColor(rating);
        final innerPaint = Paint()
          ..color = ratingColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 3, innerPaint);
      }
    }
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
