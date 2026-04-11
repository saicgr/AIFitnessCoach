import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Macros breakdown template - Pie chart style with macro percentages
class NutritionMacrosBreakdownTemplate extends StatelessWidget {
  final int totalCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final String dateLabel;
  final bool showWatermark;

  const NutritionMacrosBreakdownTemplate({
    super.key,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    required this.dateLabel,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalMacroG = proteinG + carbsG + fatG;
    final proteinPct = totalMacroG > 0 ? (proteinG / totalMacroG * 100).round() : 0;
    final carbsPct = totalMacroG > 0 ? (carbsG / totalMacroG * 100).round() : 0;
    final fatPct = totalMacroG > 0 ? (100 - proteinPct - carbsPct) : 0;

    // Calories from each macro
    final proteinCal = (proteinG * 4).round();
    final carbsCal = (carbsG * 4).round();
    final fatCal = (fatG * 9).round();

    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'MACRO BREAKDOWN',
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),

            const SizedBox(height: 20),

            // Donut chart
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _DonutPainter(
                        proteinPct: proteinPct / 100.0,
                        carbsPct: carbsPct / 100.0,
                        fatPct: fatPct / 100.0,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalCalories',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Macro details
            _MacroDetailRow(
              label: 'Protein',
              grams: proteinG,
              calories: proteinCal,
              percent: proteinPct,
              color: AppColors.macroProtein,
            ),
            const SizedBox(height: 12),
            _MacroDetailRow(
              label: 'Carbs',
              grams: carbsG,
              calories: carbsCal,
              percent: carbsPct,
              color: AppColors.macroCarbs,
            ),
            const SizedBox(height: 12),
            _MacroDetailRow(
              label: 'Fat',
              grams: fatG,
              calories: fatCal,
              percent: fatPct,
              color: AppColors.macroFat,
            ),

            if (fiberG != null && fiberG! > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Fiber', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  const Spacer(),
                  Text('${fiberG!.round()}g', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroDetailRow extends StatelessWidget {
  final String label;
  final double grams;
  final int calories;
  final int percent;
  final Color color;

  const _MacroDetailRow({
    required this.label,
    required this.grams,
    required this.calories,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        const Spacer(),
        Text('${grams.round()}g', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '${calories}cal',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;

  _DonutPainter({required this.proteinPct, required this.carbsPct, required this.fatPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 20.0;
    const gap = 0.04; // gap between segments

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    // Protein
    if (proteinPct > 0) {
      paint.color = AppColors.macroProtein;
      final sweep = proteinPct * 2 * math.pi - gap;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep > 0 ? sweep : 0, false, paint);
      startAngle += proteinPct * 2 * math.pi;
    }

    // Carbs
    if (carbsPct > 0) {
      paint.color = AppColors.macroCarbs;
      final sweep = carbsPct * 2 * math.pi - gap;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep > 0 ? sweep : 0, false, paint);
      startAngle += carbsPct * 2 * math.pi;
    }

    // Fat
    if (fatPct > 0) {
      paint.color = AppColors.macroFat;
      final sweep = fatPct * 2 * math.pi - gap;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep > 0 ? sweep : 0, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
