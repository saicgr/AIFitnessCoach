import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Elite — cosmetic-gated chrome version of Activity Overview with gold
/// accents. Visible only when `cosmetics.ownsCosmetic('stats_card_elite')`
/// is true (handled at catalog availability check).
class EliteTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const EliteTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF181208),
        Color(0xFF3A2A0F),
        Color(0xFF0E0905),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELITE',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontSize: 14 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * mul,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Center(
              child: ShareableHeroNumber(
                data: data,
                size: 144,
                unitSize: 16,
                stacked: true,
                color: Colors.amber.shade100,
                unitColor: Colors.amber.shade200,
              ),
            ),
            const Spacer(),
            ...data.highlights.take(4).map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.amber.shade300, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            h.label.toUpperCase(),
                            style: TextStyle(
                              color: Colors.amber.shade100
                                  .withValues(alpha: 0.85),
                              fontSize: 12 * mul,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        Text(
                          h.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * mul,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            if (showWatermark)
              Align(
                alignment: Alignment.centerRight,
                child:
                    AppWatermark(textColor: Colors.amber.shade100),
              ),
          ],
        ),
      ),
    );
  }
}
