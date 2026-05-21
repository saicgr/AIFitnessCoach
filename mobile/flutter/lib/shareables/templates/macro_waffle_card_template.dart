import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// MacroWaffleCard — the day/meal macro split as a 10×10 dot-grid
/// infographic. Photo-less; every datum comes from `data.nutrition`. The
/// waffle reads as a data-viz / infographic format, distinct from the rings
/// and bar cards.
class MacroWaffleCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MacroWaffleCardTemplate({
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
        ? 1.30
        : aspect == ShareableAspect.portrait
            ? 1.14
            : 1.0;
    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim().toUpperCase()
        : 'MACRO BREAKDOWN';

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0B0D12), accent, 0.14) ??
            const Color(0xFF0B0D12),
        const Color(0xFF06070A),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 70, 38, 44),
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
            Expanded(
              child: Center(
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.waffle,
                  accentColor: accent,
                  scale: vizScale,
                ),
              ),
            ),
            SizedBox(height: 10 * mul),
            Text(
              'Each square ≈ 1% of calories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12 * mul,
                fontWeight: FontWeight.w500,
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
