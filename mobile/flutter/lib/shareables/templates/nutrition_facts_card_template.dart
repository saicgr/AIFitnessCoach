import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// NutritionFactsCard — the whole share card IS a parody of the iconic FDA
/// "Nutrition Facts" panel: black-on-white, the chunky condensed title, thick
/// rules, a giant Calories row, then Protein / Carbs / Fat / Fiber lines with
/// grams, and an itemized ingredients list of the logged `foodItems` below.
///
/// It is deliberately the most "designed" of the photo-less food cards — the
/// panel is instantly recognizable, so a logged meal rendered as one reads as
/// a clever, screenshot-worthy artifact rather than a generic stat tile.
///
/// Renders identically across all 3 aspects: the panel is centered and
/// width-capped, the ingredients list caps its visible rows per aspect and
/// collapses the remainder into a single "+N more" line so nothing overflows.
class NutritionFactsCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const NutritionFactsCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  // The panel's own palette — fixed black-on-cream regardless of accent so it
  // stays true to the real-world label it parodies.
  static const Color _ink = Color(0xFF111111);
  static const Color _paper = Color(0xFFFBFAF6);

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final n = data.nutrition ?? const ShareableNutrition();
    final items = data.foodItems ?? const <ShareableFood>[];

    // Visible ingredient cap by aspect — story (9:16) is tallest, square
    // (1:1) shortest. Remainder collapses to a "+N more" line.
    final isStory = data.aspect == ShareableAspect.story;
    final isPortrait = data.aspect == ShareableAspect.portrait;
    final maxItems = isStory
        ? 8
        : isPortrait
            ? 6
            : 4;
    final visible = items.take(maxItems).toList();
    final overflow = items.length - visible.length;

    final fiber = n.fiberG ?? 0;
    final showFiber = fiber > 0;
    final servingLabel = _servingLabel(items.length);

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: EdgeInsets.fromLTRB(
              26 * mul,
              22 * mul,
              26 * mul,
              20 * mul,
            ),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ink, width: 3.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Title ───────────────────────────────────────────────
                Text(
                  'Nutrition Facts',
                  maxLines: 1,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 38 * mul,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 6 * mul),
                // Meal label as the "serving" eyebrow line.
                Text(
                  _eyebrow(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15 * mul,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3 * mul),
                Text(
                  servingLabel,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13.5 * mul,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8 * mul),
                _rule(8 * mul),
                SizedBox(height: 5 * mul),
                // "Amount per serving" microcopy.
                Text(
                  'Amount per serving',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2 * mul),
                // ─── Calories — the headline row ─────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Calories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 28 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      n.calories > 0 ? '${n.calories}' : '0',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 50 * mul,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * mul),
                _rule(5 * mul),
                SizedBox(height: 5 * mul),
                // ─── Macro rows ──────────────────────────────────────────
                _MacroRow(
                  label: 'Total Fat',
                  grams: n.fatG,
                  color: AppColors.macroFat,
                  ink: _ink,
                  mul: mul,
                  bold: true,
                ),
                _thinRule(mul),
                _MacroRow(
                  label: 'Total Carbohydrate',
                  grams: n.carbsG,
                  color: AppColors.macroCarbs,
                  ink: _ink,
                  mul: mul,
                  bold: true,
                ),
                if (showFiber) ...[
                  _thinRule(mul),
                  _MacroRow(
                    label: 'Dietary Fiber',
                    grams: fiber,
                    color: AppColors.green,
                    ink: _ink,
                    mul: mul,
                    bold: false,
                    indent: true,
                  ),
                ],
                _thinRule(mul),
                _MacroRow(
                  label: 'Protein',
                  grams: n.proteinG,
                  color: AppColors.macroProtein,
                  ink: _ink,
                  mul: mul,
                  bold: true,
                ),
                SizedBox(height: 5 * mul),
                _rule(8 * mul),
                SizedBox(height: 9 * mul),
                // ─── Itemized ingredients ────────────────────────────────
                if (visible.isNotEmpty) ...[
                  Text(
                    'INGREDIENTS',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 11 * mul,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 6 * mul),
                  for (final f in visible) _ingredientLine(f, mul),
                  if (overflow > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 3 * mul),
                      child: Text(
                        '+ $overflow more item${overflow == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.6),
                          fontSize: 12 * mul,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  SizedBox(height: 9 * mul),
                ],
                _rule(3.2 * mul),
                SizedBox(height: 10 * mul),
                // ─── Footer — watermark + date stamp ─────────────────────
                Row(
                  children: [
                    if (showWatermark)
                      AppWatermark(
                        textColor: _ink,
                        iconSize: 22 * mul,
                        fontSize: 13 * mul,
                      ),
                    const Spacer(),
                    Text(
                      _stamp(),
                      style: TextStyle(
                        color: _ink.withValues(alpha: 0.65),
                        fontSize: 12 * mul,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The eyebrow line — meal label + dish name, e.g. "LUNCH — Chicken bowl".
  String _eyebrow() {
    final meal = data.mealLabel?.trim();
    final title = data.title.trim();
    if (meal != null && meal.isNotEmpty && title.isNotEmpty) {
      return '${meal.toUpperCase()} · $title';
    }
    if (title.isNotEmpty) return title;
    if (meal != null && meal.isNotEmpty) return meal.toUpperCase();
    return 'Logged meal';
  }

  // Footer date stamp — falls back to a neutral label if no date.
  String _stamp() {
    final p = data.periodLabel.trim();
    final user = data.userDisplayName?.trim();
    if (p.isNotEmpty && user != null && user.isNotEmpty) return '$p · @$user';
    if (p.isNotEmpty) return p;
    if (user != null && user.isNotEmpty) return '@$user';
    return 'Logged with Zealova';
  }

  // "Serving size" line driven by the real item count.
  String _servingLabel(int itemCount) {
    if (itemCount <= 0) return 'Serving size  1 meal';
    return 'Serving size  1 meal ($itemCount item${itemCount == 1 ? '' : 's'})';
  }

  Widget _rule(double thickness) => Container(height: thickness, color: _ink);

  Widget _thinRule(double mul) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * mul),
        child: Container(
          height: 1,
          color: _ink.withValues(alpha: 0.5),
        ),
      );

  // One itemized ingredient line: "Grilled chicken … 320 kcal".
  Widget _ingredientLine(ShareableFood f, double mul) {
    final amount = f.amount?.trim();
    final name = amount != null && amount.isNotEmpty
        ? '${f.name} ($amount)'
        : f.name;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.5 * mul),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              color: _ink,
              fontSize: 13 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          if (f.calories > 0) ...[
            SizedBox(width: 8 * mul),
            Text(
              '${f.calories} kcal',
              style: TextStyle(
                color: _ink.withValues(alpha: 0.78),
                fontSize: 12.5 * mul,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One "Total Fat … 12g" macro row with a colored macro dot, mirroring the
/// FDA panel's bold nutrient lines.
class _MacroRow extends StatelessWidget {
  final String label;
  // Nullable: a genuinely-unknown macro (null) renders "—", never "0g". The
  // fiber row passes a non-null value (only shown when > 0).
  final double? grams;
  final Color color;
  final Color ink;
  final double mul;
  final bool bold;
  final bool indent;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.color,
    required this.ink,
    required this.mul,
    required this.bold,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 16 * mul : 0),
      child: Row(
        children: [
          Container(
            width: 9 * mul,
            height: 9 * mul,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 8 * mul),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 16 * mul,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            shareableMacroGrams(grams),
            style: TextStyle(
              color: ink,
              fontSize: 16 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
