import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroRingsCard — the headline macro-share format.
///
/// A near-black, accent-tinted canvas with a centered [MacroViz.appleRings]
/// (three concentric Activity rings, calories in the core) as the visual
/// centerpiece. Above the rings: a small eyebrow + the dish/meal title.
/// Below: an optional one-line `foodItems` summary and the watermark.
///
/// This is the photo-LESS counterpart to the photo food cards — every datum
/// comes from `data.nutrition` / `data.foodItems`. Missing nutrition renders
/// the empty ring structure (handled inside `MacroViz`), never a crash.
class MacroRingsCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroRingsCardTemplate({
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

    // Story (9:16) has the most vertical room, square (1:1) the least —
    // scale the rings down on the tighter aspects so nothing overflows.
    final ringScale = aspect == ShareableAspect.story
        ? 1.32
        : aspect == ShareableAspect.portrait
            ? 1.18
            : 1.06;

    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'NUTRITION';
    final itemsLine = _itemsSummary(data);

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      // Deep accent-tinted gradient — the rings carry the color, the canvas
      // just frames them. Deliberately darker than the canvas default so the
      // ring strokes pop.
      backgroundOverride: [
        Color.lerp(const Color(0xFF07090F), accent, 0.16) ??
            const Color(0xFF07090F),
        const Color(0xFF05060A),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 70, 36, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Eyebrow ───────────────────────────────────────────────
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(height: 8 * mul),
            // ─── Title ─────────────────────────────────────────────────
            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30 * mul,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -0.5,
              ),
            ),
            if (data.periodLabel.trim().isNotEmpty) ...[
              SizedBox(height: 6 * mul),
              Text(
                data.periodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13 * mul,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            // ─── Rings centerpiece ─────────────────────────────────────
            Expanded(
              child: Center(
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.appleRings,
                  accentColor: accent,
                  scale: ringScale,
                  healthScore: data.healthScore,
                ),
              ),
            ),
            // ─── Macro legend ──────────────────────────────────────────
            _MacroLegend(nutrition: nutrition, mul: mul),
            if (itemsLine != null) ...[
              SizedBox(height: 12 * mul),
              Text(
                itemsLine,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13 * mul,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
            SizedBox(height: 18 * mul),
            // ─── Watermark ─────────────────────────────────────────────
            if (showWatermark) AppWatermark(textColor: Colors.white, fontSize: 13 * mul),
          ],
        ),
      ),
    );
  }

  /// "Grilled chicken, rice & broccoli" — a comma-joined item line. Returns
  /// null when there are no named items so the row simply collapses.
  static String? _itemsSummary(Shareable data) {
    final items = data.foodItems;
    if (items == null || items.isEmpty) return null;
    final names = items
        .map((f) => f.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return null;
    if (names.length <= 3) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2} more';
  }
}

/// A `protein 32g · carbs 40g · fat 12g` legend in macro colors. Each macro
/// keeps its app-constant hue so the legend reads against the same-colored
/// ring above it.
class _MacroLegend extends StatelessWidget {
  final ShareableNutrition nutrition;
  final double mul;

  const _MacroLegend({required this.nutrition, required this.mul});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14 * mul,
      runSpacing: 6 * mul,
      children: [
        _entry('Protein', nutrition.proteinG, AppColors.macroProtein),
        _entry('Carbs', nutrition.carbsG, AppColors.macroCarbs),
        _entry('Fat', nutrition.fatG, AppColors.macroFat),
      ],
    );
  }

  Widget _entry(String label, double? grams, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9 * mul,
          height: 9 * mul,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 6 * mul),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              // "—" for a genuinely-unknown macro, never a fabricated "0g".
              text: shareableMacroGrams(grams),
              style: TextStyle(
                color: Colors.white,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w800,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
