import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';

/// FoodPhotoMacros — the headline food-share card. The logged meal photo runs
/// full-bleed; a bottom-up dark scrim keeps the type legible; the meal label
/// eyebrow + dish title sit over the scrim; a frosted [MacroViz] coin floats
/// in the lower third with the macro totals + (optional) health score.
///
/// This is the format users screenshot most for a food log — the photo IS the
/// hook, the macros are the proof. Renders identically across all 3 aspects;
/// the macro coin scale + scrim height adapt so nothing overflows.
///
/// Phase B will make the macro overlay draggable — for now it sits at a fixed,
/// composition-tested position anchored to the card's lower third.
class FoodPhotoMacrosTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const FoodPhotoMacrosTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    // First usable photo — FoodImage itself degrades a null/failed url to a
    // neutral gradient, so an empty list still captures cleanly.
    final photoUrl = data.foodImageUrls?.isNotEmpty == true
        ? data.foodImageUrls!.first
        : null;

    final isStory = data.aspect == ShareableAspect.story;
    final isSquare = data.aspect == ShareableAspect.square;

    // Macro coin footprint — smaller on the square canvas so the title +
    // photo still breathe; largest on the tall story canvas.
    final coinScale = isStory
        ? 1.0
        : isSquare
            ? 0.78
            : 0.9;

    final mealLabel = data.mealLabel?.trim();
    final user = data.userDisplayName?.trim();

    return ShareableCanvas(
      aspect: data.aspect,
      // Pure black base so any photo letterboxing reads as intentional.
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Full-bleed meal photo ─────────────────────────────────────
          FoodImage(
            url: photoUrl,
            fit: BoxFit.cover,
            fallbackBuilder: () => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, Colors.black, 0.35)!,
                    Color.lerp(accent, Colors.black, 0.78)!,
                  ],
                ),
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 88)),
              ),
            ),
          ),
          // ─── Bottom-up legibility scrim ────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x33000000),
                  Color(0xCC000000),
                  Color(0xF2000000),
                ],
                stops: [0.0, 0.40, 0.74, 1.0],
              ),
            ),
          ),
          // A soft top scrim so a watermark on a bright photo still reads.
          const Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          // ─── Content ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(34, isStory ? 70 : 52, 34, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showWatermark)
                  const AppWatermark(
                    textColor: Colors.white,
                    iconSize: 26,
                    fontSize: 15,
                  ),
                const Spacer(),
                // The floating frosted macro coin, lower third, right-aligned
                // so it never collides with the title block beneath it.
                Align(
                  alignment: Alignment.centerRight,
                  child: MacroViz(
                    nutrition: nutrition,
                    style: MacroVizStyle.coin,
                    accentColor: accent,
                    glass: true,
                    scale: coinScale,
                    healthScore: data.healthScore,
                  ),
                ),
                SizedBox(height: 22 * mul),
                // Meal eyebrow.
                if (mealLabel != null && mealLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        mealLabel.toUpperCase(),
                        style: TextStyle(
                          color: _onAccent(accent),
                          fontSize: 11 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                // Dish title.
                Text(
                  data.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isStory ? 44 : 38,
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                    letterSpacing: -0.8,
                    shadows: const [
                      Shadow(blurRadius: 14, color: Colors.black87),
                    ],
                  ),
                ),
                if (data.periodLabel.trim().isNotEmpty ||
                    (user != null && user.isNotEmpty)) ...[
                  SizedBox(height: 8 * mul),
                  Row(
                    children: [
                      if (data.periodLabel.trim().isNotEmpty)
                        Flexible(
                          child: Text(
                            data.periodLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13 * mul,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (data.periodLabel.trim().isNotEmpty &&
                          user != null &&
                          user.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13 * mul,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (user != null && user.isNotEmpty)
                        Flexible(
                          child: Text(
                            '@$user',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13 * mul,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Black or white text for a chip filled with [accent], chosen by the
  /// accent's perceived luminance so the eyebrow stays readable on any theme.
  static Color _onAccent(Color accent) {
    return accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
  }
}
