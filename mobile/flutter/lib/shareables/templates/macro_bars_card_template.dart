import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroBarsCard — macros as linear progress bars (goal-relative when the
/// payload carries goals, absolute grams otherwise). Photo-less; the
/// cleanest, most "dashboard" of the macro cards.
class MacroBarsCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroBarsCardTemplate({
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

    final vizScale = aspect == ShareableAspect.story
        ? 1.20
        : aspect == ShareableAspect.portrait
            ? 1.10
            : 1.0;
    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'MACROS';

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0C0E13), accent, 0.15) ??
            const Color(0xFF0C0E13),
        const Color(0xFF06070A),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 72, 40, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 8 * mul),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 31 * mul,
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
            Expanded(
              child: Center(
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.progressBars,
                  accentColor: accent,
                  scale: vizScale,
                ),
              ),
            ),
            SizedBox(height: 16 * mul),
            if (showWatermark)
              AppWatermark(textColor: Colors.white, fontSize: 13 * mul),
          ],
        ),
      ),
    );
  }
}
