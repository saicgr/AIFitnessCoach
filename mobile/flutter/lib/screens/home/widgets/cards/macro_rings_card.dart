import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Compact Apple-Watch-style concentric macro rings tile. Outer=Protein,
/// middle=Carbs, inner=Fat. Below the rings, three legend chips show current
/// grams vs target for each macro so the user can read progress without
/// going into the nutrition screen.
///
/// This tile is a half-width sibling of CaloriesSummaryCard — together they
/// form the "at-a-glance" macro block on the home screen while the full
/// interactive rings live in HeroNutritionCard.
class MacroRingsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const MacroRingsCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final proteinColor = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final summary = ref.watch(nutritionProvider).todaySummary;
    final prefs = ref.watch(nutritionPreferencesProvider);

    final proteinConsumed = (summary?.totalProteinG ?? 0).round();
    final carbsConsumed = (summary?.totalCarbsG ?? 0).round();
    final fatConsumed = (summary?.totalFatG ?? 0).round();

    final proteinTarget = prefs.currentProteinTarget;
    final carbsTarget = prefs.currentCarbsTarget;
    final fatTarget = prefs.currentFatTarget;

    // Allow overshoot up to 1.5x so the overshoot lick is visible but clamped.
    final proteinProgress = proteinTarget > 0
        ? (proteinConsumed / proteinTarget).clamp(0.0, 1.5)
        : 0.0;
    final carbsProgress = carbsTarget > 0
        ? (carbsConsumed / carbsTarget).clamp(0.0, 1.5)
        : 0.0;
    final fatProgress = fatTarget > 0
        ? (fatConsumed / fatTarget).clamp(0.0, 1.5)
        : 0.0;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.go('/nutrition');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 16, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Macros',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                height: 92,
                width: 92,
                child: CustomPaint(
                  painter: _CompactMacroRingsPainter(
                    proteinProgress: proteinProgress,
                    carbsProgress: carbsProgress,
                    fatProgress: fatProgress,
                    proteinColor: proteinColor,
                    carbsColor: carbsColor,
                    fatColor: fatColor,
                    trackColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _MacroLegendRow(
              label: 'P',
              consumed: proteinConsumed,
              target: proteinTarget,
              color: proteinColor,
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 4),
            _MacroLegendRow(
              label: 'C',
              consumed: carbsConsumed,
              target: carbsTarget,
              color: carbsColor,
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 4),
            _MacroLegendRow(
              label: 'F',
              consumed: fatConsumed,
              target: fatTarget,
              color: fatColor,
              textColor: textColor,
              textMuted: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;
  final Color textColor;
  final Color textMuted;

  const _MacroLegendRow({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${consumed}g / ${target}g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compact version of the hero's macro ring painter — narrower stroke,
/// smaller ring gap so 3 rings fit comfortably in a 92dp square.
class _CompactMacroRingsPainter extends CustomPainter {
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color trackColor;

  _CompactMacroRingsPainter({
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.0;
    const ringGap = 1.5;
    const startAngle = -math.pi / 2;

    final outerRadius = (size.width / 2) - strokeWidth / 2;
    _drawRing(canvas, center, outerRadius, strokeWidth,
        proteinProgress, proteinColor, startAngle);

    final middleRadius = outerRadius - strokeWidth - ringGap;
    _drawRing(canvas, center, middleRadius, strokeWidth,
        carbsProgress, carbsColor, startAngle);

    final innerRadius = middleRadius - strokeWidth - ringGap;
    _drawRing(canvas, center, innerRadius, strokeWidth,
        fatProgress, fatColor, startAngle);
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, double progress, Color color, double startAngle) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Keep a sliver visible so empty rings aren't invisible — matches
    // HeroNutritionCard behavior.
    final effectiveProgress = progress <= 0 ? 0.02 : progress;
    final clamped = effectiveProgress.clamp(0.0, 1.0);
    final sweep = 2 * math.pi * clamped;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, paint);

    if (progress > 1.0) {
      final overshoot = (progress - 1.0).clamp(0.0, 0.5);
      final overshootPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, 2 * math.pi * overshoot, false,
          overshootPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompactMacroRingsPainter old) {
    return old.proteinProgress != proteinProgress ||
        old.carbsProgress != carbsProgress ||
        old.fatProgress != fatProgress ||
        old.proteinColor != proteinColor ||
        old.carbsColor != carbsColor ||
        old.fatColor != fatColor ||
        old.trackColor != trackColor;
  }
}
