import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroPieCard — a clean "macro split" card.
///
/// Centerpiece is a [MacroViz.macroPie] donut (one ring split into P/C/F
/// wedges by calorie share). Below it, a three-row legend gives each macro
/// its color swatch, name, gram value, AND its share of total calories as a
/// percentage — the pie answers "how is this balanced", the legend gives the
/// exact numbers.
///
/// Photo-LESS card: every datum is from `data.nutrition`. When nutrition is
/// all-zero the pie renders its empty track and percentages read 0%.
class MacroPieCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroPieCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = data.aspect;
    final mul = aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();

    final pieScale = aspect == ShareableAspect.story
        ? 1.36
        : aspect == ShareableAspect.portrait
            ? 1.2
            : 1.05;

    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'MACRO SPLIT';

    // Calorie contribution per macro (4/4/9 kcal/g) — the same basis the pie
    // painter uses, so the legend percentages match the wedge sizes exactly.
    final pKcal = math.max(0.0, nutrition.proteinG) * 4;
    final cKcal = math.max(0.0, nutrition.carbsG) * 4;
    final fKcal = math.max(0.0, nutrition.fatG) * 9;
    final totalKcal = pKcal + cKcal + fKcal;

    int pct(double part) =>
        totalKcal <= 0 ? 0 : ((part / totalKcal) * 100).round();

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0C0E16), accent, 0.14) ??
            const Color(0xFF0C0E16),
        const Color(0xFF080A11),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 70, 38, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 7 * mul,
                  height: 22 * mul,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                SizedBox(width: 10 * mul),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.6,
                        ),
                      ),
                      SizedBox(height: 3 * mul),
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27 * mul,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ─── Pie centerpiece ───────────────────────────────────────
            Expanded(
              child: Center(
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.macroPie,
                  accentColor: accent,
                  scale: pieScale,
                ),
              ),
            ),
            SizedBox(height: 6 * mul),
            // ─── P/C/F legend with percentages ─────────────────────────
            _LegendRow(
              label: 'Protein',
              grams: nutrition.proteinG,
              percent: pct(pKcal),
              color: AppColors.macroProtein,
              mul: mul,
            ),
            SizedBox(height: 10 * mul),
            _LegendRow(
              label: 'Carbs',
              grams: nutrition.carbsG,
              percent: pct(cKcal),
              color: AppColors.macroCarbs,
              mul: mul,
            ),
            SizedBox(height: 10 * mul),
            _LegendRow(
              label: 'Fat',
              grams: nutrition.fatG,
              percent: pct(fKcal),
              color: AppColors.macroFat,
              mul: mul,
            ),
            SizedBox(height: 20 * mul),
            // ─── Watermark ─────────────────────────────────────────────
            if (showWatermark)
              AppWatermark(textColor: Colors.white, fontSize: 13 * mul),
          ],
        ),
      ),
    );
  }
}

/// One legend row: color swatch + macro name on the left, `Xg` and a `· N%`
/// share on the right. The percentage is the macro's calorie share so it
/// lines up with the donut wedge sizes.
class _LegendRow extends StatelessWidget {
  final String label;
  final double grams;
  final int percent;
  final Color color;
  final double mul;

  const _LegendRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12 * mul,
          height: 12 * mul,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3 * mul),
          ),
        ),
        SizedBox(width: 10 * mul),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15 * mul,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${grams.round()}g',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * mul,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 8 * mul),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * mul,
            vertical: 3 * mul,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$percent%',
            style: TextStyle(
              color: color,
              fontSize: 12 * mul,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
