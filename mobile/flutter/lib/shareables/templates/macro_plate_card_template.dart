import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroPlateCard — a warm "what's on your plate" macro card.
///
/// Centerpiece is the [MacroViz.plate] visual (a rimmed circular plate split
/// into macro wedges by calorie share). The card leans warm — a toasted-amber
/// gradient and an "ON YOUR PLATE" eyebrow — so it reads as a meal card, not
/// a clinical chart. A calorie figure sits beneath the plate, then a compact
/// itemized list of what the meal contained.
///
/// Photo-LESS card: every datum is from `data.nutrition` / `data.foodItems`.
class MacroPlateCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroPlateCardTemplate({
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

    final plateScale = aspect == ShareableAspect.story
        ? 1.34
        : aspect == ShareableAspect.portrait
            ? 1.18
            : 1.04;

    // How many itemized rows fit before we collapse the rest into "+N more".
    final maxItems = aspect == ShareableAspect.story
        ? 5
        : aspect == ShareableAspect.portrait
            ? 4
            : 3;
    final items = data.foodItems ?? const <ShareableFood>[];
    final namedItems = items.where((f) => f.name.trim().isNotEmpty).toList();
    final visibleItems = namedItems.take(maxItems).toList();
    final hiddenCount = namedItems.length - visibleItems.length;

    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'ON YOUR PLATE';

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      // Warm toasted gradient — independent of the accent so the card always
      // feels like a meal. The accent still drives the plate's calorie color.
      backgroundOverride: const [
        Color(0xFF1C1209),
        Color(0xFF120B05),
        Color(0xFF0B0703),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 72, 38, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Eyebrow ───────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  size: 15 * mul,
                  color: const Color(0xFFE9B872),
                ),
                SizedBox(width: 7 * mul),
                Flexible(
                  child: Text(
                    eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFE9B872),
                      fontSize: 12 * mul,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * mul),
            // ─── Title ─────────────────────────────────────────────────
            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFFFBF3E7),
                fontSize: 29 * mul,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -0.4,
              ),
            ),
            // ─── Plate centerpiece ─────────────────────────────────────
            Expanded(
              child: Center(
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.plate,
                  accentColor: accent,
                  textColor: const Color(0xFFFBF3E7),
                  scale: plateScale,
                ),
              ),
            ),
            SizedBox(height: 6 * mul),
            // ─── Calorie figure ────────────────────────────────────────
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: nutrition.calories <= 0
                      ? '—'
                      : '${nutrition.calories}',
                  style: TextStyle(
                    color: const Color(0xFFFBF3E7),
                    fontSize: 38 * mul,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: '  kcal',
                  style: TextStyle(
                    color: const Color(0xFFE9B872),
                    fontSize: 15 * mul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
            if (visibleItems.isNotEmpty) ...[
              SizedBox(height: 14 * mul),
              _PlateItems(
                items: visibleItems,
                hiddenCount: hiddenCount,
                mul: mul,
              ),
            ],
            SizedBox(height: 18 * mul),
            // ─── Watermark ─────────────────────────────────────────────
            if (showWatermark)
              AppWatermark(
                textColor: const Color(0xFFFBF3E7),
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }
}

/// The compact itemized list under the plate — each row is a faint warm
/// divider dot + the food name + (when present) its serving amount. Caller
/// pre-caps the list; a non-zero [hiddenCount] appends a "+N more" line.
class _PlateItems extends StatelessWidget {
  final List<ShareableFood> items;
  final int hiddenCount;
  final double mul;

  const _PlateItems({
    required this.items,
    required this.hiddenCount,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final f in items)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3 * mul),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5 * mul,
                  height: 5 * mul,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE9B872),
                  ),
                ),
                SizedBox(width: 8 * mul),
                Flexible(
                  child: Text(
                    _line(f),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFFBF3E7).withValues(alpha: 0.82),
                      fontSize: 14 * mul,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hiddenCount > 0)
          Padding(
            padding: EdgeInsets.only(top: 3 * mul),
            child: Text(
              '+$hiddenCount more',
              style: TextStyle(
                color: const Color(0xFFE9B872).withValues(alpha: 0.85),
                fontSize: 12.5 * mul,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  /// "Grilled chicken · 150g" — name with the serving amount appended when
  /// the item carries one.
  String _line(ShareableFood f) {
    final name = f.name.trim();
    final amount = f.amount?.trim();
    if (amount == null || amount.isEmpty) return name;
    return '$name  ·  $amount';
  }
}
