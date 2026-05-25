import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting_impact.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Weight Trends — weight on fasting vs non-fasting days.
///
/// This chart is kept bespoke (NOT migrated to the shared [TrendChart])
/// because its defining feature is per-point colouring: each dot is tinted
/// by whether that day was a fasting day. TrendChart models a single uniform
/// series and cannot express that distinction. It is themed via
/// [ThemeColors] and given a tap tooltip so it still feels consistent with
/// the rest of the Trends system (Phase G5a/G5c).
class WeightFastingChart extends ConsumerStatefulWidget {
  final List<FastingDayData> dailyData;
  final double height;
  final bool isDark;

  const WeightFastingChart({
    super.key,
    required this.dailyData,
    this.height = 220,
    this.isDark = true,
  });

  @override
  ConsumerState<WeightFastingChart> createState() =>
      _WeightFastingChartState();
}

class _WeightFastingChartState extends ConsumerState<WeightFastingChart> {
  /// Index of the day currently surfaced by the tap tooltip, or null.
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);

    // Filter days with weight data.
    final daysWithWeight =
        widget.dailyData.where((d) => d.weight != null).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (daysWithWeight.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: colors.textMuted, size: 48),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).weightFastingChartNoWeightDataAvailable,
                style: TextStyle(color: colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate min/max weight for scaling.
    final weights = daysWithWeight.map((d) => d.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final paddedMin = minWeight - (range == 0 ? 1 : range * 0.1);
    final paddedMax = maxWeight + (range == 0 ? 1 : range * 0.1);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).weightTrendCardWeightTrends,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Fasting days', colors.accent),
              const SizedBox(width: 16),
              _buildLegendItem('Non-fasting', colors.textMuted),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  // Tap a point to surface its date + weight (G5c tooltip).
                  onTapDown: (details) {
                    final w = constraints.maxWidth;
                    final step =
                        w / (daysWithWeight.length - 1).clamp(1, double.infinity);
                    final idx = (details.localPosition.dx / step)
                        .round()
                        .clamp(0, daysWithWeight.length - 1);
                    setState(() {
                      _selectedIndex = _selectedIndex == idx ? null : idx;
                    });
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _WeightChartPainter(
                      data: daysWithWeight,
                      minWeight: paddedMin,
                      maxWeight: paddedMax,
                      fastingColor: colors.accent,
                      nonFastingColor:
                          colors.textMuted.withValues(alpha: 0.5),
                      gridColor: colors.cardBorder.withValues(alpha: 0.5),
                      lineColor: colors.accent.withValues(alpha: 0.45),
                      selectedIndex: _selectedIndex,
                      tooltipBg: colors.surface,
                      tooltipBorder: colors.cardBorder,
                      tooltipText: colors.textPrimary,
                      tooltipMuted: colors.textMuted,
                    ),
                  ),
                );
              },
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
  final Color lineColor;
  final int? selectedIndex;
  final Color tooltipBg;
  final Color tooltipBorder;
  final Color tooltipText;
  final Color tooltipMuted;

  _WeightChartPainter({
    required this.data,
    required this.minWeight,
    required this.maxWeight,
    required this.fastingColor,
    required this.nonFastingColor,
    required this.gridColor,
    required this.lineColor,
    required this.selectedIndex,
    required this.tooltipBg,
    required this.tooltipBorder,
    required this.tooltipText,
    required this.tooltipMuted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final range = maxWeight - minWeight;
    if (range <= 0) return;

    // Draw grid lines.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pointWidth = size.width / (data.length - 1).clamp(1, data.length);

    double xOf(int i) => i * pointWidth;
    double yOf(double weight) =>
        size.height - (((weight - minWeight) / range) * size.height);

    // Draw connecting lines.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;
    for (var i = 0; i < data.length - 1; i++) {
      if (data[i].weight == null || data[i + 1].weight == null) continue;
      canvas.drawLine(
        Offset(xOf(i), yOf(data[i].weight!)),
        Offset(xOf(i + 1), yOf(data[i + 1].weight!)),
        linePaint,
      );
    }

    // Draw data points.
    for (var i = 0; i < data.length; i++) {
      final day = data[i];
      if (day.weight == null) continue;
      final pointPaint = Paint()
        ..color = day.isFastingDay ? fastingColor : nonFastingColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(xOf(i), yOf(day.weight!)), 4, pointPaint);
    }

    // Draw tap tooltip + crosshair for the selected point.
    final sel = selectedIndex;
    if (sel != null && sel >= 0 && sel < data.length) {
      final day = data[sel];
      if (day.weight != null) {
        final px = xOf(sel);
        final py = yOf(day.weight!);

        // Crosshair.
        canvas.drawLine(
          Offset(px, 0),
          Offset(px, size.height),
          Paint()
            ..color = tooltipMuted.withValues(alpha: 0.5)
            ..strokeWidth = 1,
        );
        // Emphasised dot.
        canvas.drawCircle(
          Offset(px, py),
          6,
          Paint()
            ..color = day.isFastingDay ? fastingColor : nonFastingColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(px, py),
          6,
          Paint()
            ..color = tooltipBg
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        // Tooltip text.
        final dateStr = DateFormat('MMM d').format(day.date);
        final tag = day.isFastingDay ? 'Fasting' : 'Non-fasting';
        final tp = TextPainter(
          text: TextSpan(children: [
            TextSpan(
              text: '${day.weight!.toStringAsFixed(1)}\n',
              style: TextStyle(
                color: tooltipText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '$dateStr · $tag',
              style: TextStyle(color: tooltipMuted, fontSize: 10),
            ),
          ]),
          textDirection: TextDirection.ltr,
        )..layout();

        const pad = 8.0;
        var boxX = px - tp.width / 2 - pad;
        boxX = boxX.clamp(0.0, size.width - tp.width - 2 * pad);
        final boxY = (py - tp.height - 2 * pad - 8).clamp(0.0, size.height);
        final rect = Rect.fromLTWH(
          boxX,
          boxY,
          tp.width + 2 * pad,
          tp.height + 2 * pad,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, Paint()..color = tooltipBg);
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = tooltipBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        tp.paint(canvas, Offset(boxX + pad, boxY + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.minWeight != minWeight ||
      oldDelegate.maxWeight != maxWeight;
}
