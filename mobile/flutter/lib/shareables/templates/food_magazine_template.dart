import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';

/// FoodMagazine — the meal styled as a food-magazine cover. The photo runs
/// full-bleed; a bold serif masthead sits at the top; two to three "cover
/// line" callouts (built from `foodItems` names + their key macros) run down
/// the right side; a [MacroViz] pills strip anchors the lower area; a circular
/// health-score "flag" pins to a top corner when `healthScore` is known.
///
/// Distinct from FoodPhotoMacros (clean photo + floating coin) — this one is
/// loud editorial styling. Renders across all 3 aspects; cover-line count and
/// masthead size step down on the shorter portrait / square canvases.
class FoodMagazineTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const FoodMagazineTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  /// Up to [limit] cover lines from the itemized food list. Each pairs the
  /// food name with its single most interesting macro fact (calories first,
  /// else the largest macro) so the callouts never read as filler.
  List<_CoverLine> _coverLines(int limit) {
    final items = data.foodItems ?? const <ShareableFood>[];
    final out = <_CoverLine>[];
    for (final f in items) {
      final name = f.name.trim();
      if (name.isEmpty) continue;
      out.add(_CoverLine(name, _macroFact(f)));
      if (out.length >= limit) break;
    }
    return out;
  }

  /// The headline macro fact for one food item.
  String _macroFact(ShareableFood f) {
    if (f.calories > 0) return '${f.calories} kcal';
    final p = f.proteinG;
    final c = f.carbsG;
    final fat = f.fatG;
    if (p >= c && p >= fat && p > 0) return '${p.round()}g protein';
    if (c >= fat && c > 0) return '${c.round()}g carbs';
    if (fat > 0) return '${fat.round()}g fat';
    return f.amount?.trim().isNotEmpty == true ? f.amount!.trim() : 'logged';
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    final photoUrl = data.foodImageUrls?.isNotEmpty == true
        ? data.foodImageUrls!.first
        : null;

    final isStory = data.aspect == ShareableAspect.story;
    final isSquare = data.aspect == ShareableAspect.square;

    // Tall story fits 3 cover lines; the shorter canvases get 2 so the right
    // rail never crowds the masthead or the macro strip.
    final coverLines = _coverLines(isStory ? 3 : 2);
    final score = data.healthScore;
    final user = data.userDisplayName?.trim();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Full-bleed dish photo ─────────────────────────────────────
          FoodImage(
            url: photoUrl,
            fit: BoxFit.cover,
            fallbackBuilder: () => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, Colors.black, 0.30)!,
                    Color.lerp(accent, Colors.black, 0.80)!,
                  ],
                ),
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 96)),
              ),
            ),
          ),
          // Editorial scrims — top for the masthead, bottom for the strip.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x33000000),
                  Color(0x4D000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.26, 0.6, 1.0],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(34, isStory ? 66 : 48, 34, 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Masthead ───────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FUEL',
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              color: Colors.white,
                              fontSize: isStory
                                  ? 86
                                  : isSquare
                                      ? 60
                                      : 70,
                              fontWeight: FontWeight.w900,
                              height: 0.82,
                              letterSpacing: -3.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                (data.mealLabel?.trim().isNotEmpty == true
                                        ? data.mealLabel!.trim()
                                        : 'THE FOOD ISSUE')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11 * mul,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: Colors.white
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ─── Health-score "flag" ──────────────────────────────
                    if (score != null) ...[
                      const SizedBox(width: 14),
                      _ScoreFlag(score: score, accent: accent, mul: mul),
                    ],
                  ],
                ),
                const Spacer(),
                // ─── Cover lines down the right rail ────────────────────
                if (coverLines.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < coverLines.length; i++) ...[
                            if (i > 0) SizedBox(height: 9 * mul),
                            _CoverChip(
                              line: coverLines[i],
                              accent: accent,
                              mul: mul,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 18 * mul),
                // ─── Cover title (the dish) ─────────────────────────────
                Text(
                  data.title.toUpperCase(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                    fontSize: isStory ? 50 : 40,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                    letterSpacing: -1.4,
                    shadows: const [
                      Shadow(blurRadius: 16, color: Colors.black87),
                    ],
                  ),
                ),
                SizedBox(height: 14 * mul),
                // ─── Macro pills strip ──────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: MacroViz(
                    nutrition: nutrition,
                    style: MacroVizStyle.pills,
                    accentColor: accent,
                    scale: isStory ? 0.92 : 0.82,
                  ),
                ),
                SizedBox(height: 16 * mul),
                // ─── Footer line ────────────────────────────────────────
                Row(
                  children: [
                    if (showWatermark)
                      AppWatermark(
                        textColor: Colors.white,
                        iconSize: 24,
                        fontSize: 13 * mul,
                      ),
                    const Spacer(),
                    if (user != null && user.isNotEmpty)
                      Flexible(
                        child: Text(
                          '@$user',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12 * mul,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One cover-line callout: a food name + its headline macro fact.
@immutable
class _CoverLine {
  final String name;
  final String fact;

  const _CoverLine(this.name, this.fact);
}

/// A right-rail cover chip — accent kicker bar + name + fact, on a dark plate.
class _CoverChip extends StatelessWidget {
  final _CoverLine line;
  final Color accent;
  final double mul;

  const _CoverChip({
    required this.line,
    required this.accent,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 30 * mul,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * mul,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  line.fact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular "health score" cover flag — a wax-seal-style badge.
class _ScoreFlag extends StatelessWidget {
  final int score;
  final Color accent;
  final double mul;

  const _ScoreFlag({
    required this.score,
    required this.accent,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    final size = 78.0 * mul;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.18)!,
            accent,
          ],
        ),
        border: Border.all(color: Colors.white, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // The score + HEALTH label sit inside a fixed-diameter circle. The
      // share sheet's font-size slider (up to 150%) scales all Text via
      // MediaQuery.textScaler, which pushed the two lines past the circle.
      // A scale-down FittedBox keeps the badge content inside the disc no
      // matter the text-scale factor.
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    color: _onAccent(accent),
                    fontSize: 30 * mul,
                    fontWeight: FontWeight.w900,
                    height: 0.92,
                  ),
                ),
                Text(
                  'HEALTH',
                  style: TextStyle(
                    color: _onAccent(accent).withValues(alpha: 0.85),
                    fontSize: 8 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Black or white text for an [accent]-filled badge, by perceived luminance.
  static Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}
