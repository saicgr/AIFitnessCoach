import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/macro_viz.dart';

/// WhatIAteCard — for text / voice / chat logs that have no photo. Renders
/// the user's own words (`logText`) as a large pull-quote, the parsed food
/// items as chips, and a `MacroViz.pills` strip. This is the default food
/// card a text log lands on.
class WhatIAteCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WhatIAteCardTemplate({
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

    final quote = (data.logText?.trim().isNotEmpty ?? false)
        ? data.logText!.trim()
        : data.title;
    final eyebrow = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? '${data.mealLabel!.trim().toUpperCase()} · LOGGED'
        : 'WHAT I ATE';
    final items = (data.foodItems ?? const <ShareableFood>[])
        .map((f) => f.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    // Long quotes need a smaller face so they never clip.
    final quoteSize = (quote.length > 90 ? 30.0 : quote.length > 48 ? 38.0 : 46.0) * mul;

    return ShareableCanvas(
      aspect: aspect,
      accentColor: accent,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0B0D13), accent, 0.20) ??
            const Color(0xFF0B0D13),
        const Color(0xFF06070A),
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
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 18 * mul),
            Text(
              '“',
              style: TextStyle(
                color: accent.withValues(alpha: 0.55),
                fontSize: 72 * mul,
                fontWeight: FontWeight.w900,
                height: 0.6,
              ),
            ),
            SizedBox(height: 6 * mul),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  quote,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: quoteSize,
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            if (items.isNotEmpty) ...[
              Wrap(
                spacing: 8 * mul,
                runSpacing: 8 * mul,
                children: [
                  for (final name in items.take(6))
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12 * mul, vertical: 6 * mul),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13 * mul,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 18 * mul),
            ],
            MacroViz(
              nutrition: nutrition,
              style: MacroVizStyle.pills,
              accentColor: accent,
              scale: mul,
            ),
            SizedBox(height: 16 * mul),
            Row(
              children: [
                if (showWatermark)
                  AppWatermark(textColor: Colors.white, fontSize: 13 * mul),
                const Spacer(),
                if (data.periodLabel.trim().isNotEmpty)
                  Text(
                    data.periodLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12 * mul,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
