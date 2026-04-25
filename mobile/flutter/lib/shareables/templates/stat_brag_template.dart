import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// StatBrag — single OBSCENELY large stat with a PR/+%∆ pill below, period
/// chip above, watermark. The "I just hit X" format. Maxes out the canvas
/// with the number — designed for the Lockscreen-screenshot share format.
class StatBragTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const StatBragTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  double _heroSize(ShareableAspect a) {
    switch (a) {
      case ShareableAspect.story:
        return 320;
      case ShareableAspect.portrait:
        return 260;
      case ShareableAspect.square:
        return 220;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);
    final pr = data.highlights.firstWhere(
      (h) => h.label.toUpperCase().contains('PR') ||
          h.label.toUpperCase().contains('STREAK'),
      orElse: () => data.highlights.isNotEmpty
          ? data.highlights.first
          : const ShareableMetric(label: '', value: ''),
    );

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF000000),
        Color.lerp(accent, Colors.black, 0.78)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                data.periodLabel.toUpperCase(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12 * mul,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hero,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _heroSize(data.aspect),
                  fontWeight: FontWeight.w900,
                  height: 0.85,
                  letterSpacing: -10,
                  shadows: [
                    Shadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  unit.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 24 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              data.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * mul,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            if (pr.value.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: accent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: accent, size: 16 * mul),
                    const SizedBox(width: 8),
                    Text(
                      '${pr.label}: ${pr.value}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * mul,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (showWatermark)
              FitWizWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }
}
