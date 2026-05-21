import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroNumbersCard — bold, typographic. The calorie figure is the hero;
/// `MacroViz.numbers` carries the giant number + the P/C/F row. Photo-less.
class MacroNumbersCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroNumbersCardTemplate({
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
        ? 1.34
        : aspect == ShareableAspect.portrait
            ? 1.18
            : 1.05;
    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'ON THE PLATE';

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0A0B10), accent, 0.18) ??
            const Color(0xFF0A0B10),
        const Color(0xFF050608),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 76, 40, 46),
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
                letterSpacing: 3.4,
              ),
            ),
            SizedBox(height: 8 * mul),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32 * mul,
                fontWeight: FontWeight.w900,
                height: 1.06,
                letterSpacing: -0.6,
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
                  style: MacroVizStyle.numbers,
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
