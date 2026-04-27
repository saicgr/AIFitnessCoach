import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Minimal — typographic hero stat at center. Replaces the old "two empty
/// white bars" rendering by using `ShareableHeroNumber` (which handles
/// nullable values cleanly) and showing the title + period header.
class MinimalTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MinimalTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.periodLabel.toUpperCase(),
              style: TextStyle(
                color: data.accentColor,
                fontSize: 12 * mul,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * mul,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            ShareableHeroNumber(
              data: data,
              size: _heroSize,
              unitSize: 22 * mul,
              stacked: false,
              color: Colors.white,
              unitColor: data.accentColor,
            ),
            const SizedBox(height: 28),
            ...data.highlights.take(3).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h.label.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11 * mul,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        Text(
                          h.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * mul,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const Spacer(),
            if (showWatermark)
              AppWatermark(textColor: Colors.white.withValues(alpha: 0.85)),
          ],
        ),
      ),
    );
  }

  double get _heroSize {
    switch (data.aspect) {
      case ShareableAspect.square:
        return 96;
      case ShareableAspect.portrait:
        return 120;
      case ShareableAspect.story:
        return 168;
    }
  }
}
