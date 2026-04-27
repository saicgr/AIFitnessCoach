import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Level Up — RPG-style XP ring + tier badge. Used for milestones &
/// achievements.
class LevelUpTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const LevelUpTemplate({
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
        Color(0xFF1E1B4B),
        Color(0xFF6D28D9),
        Color(0xFF0F0F1F),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'LEVEL UP',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
                  Color(0xFFFCD34D),
                  Color(0xFFFB923C),
                  Color(0xFFFCD34D),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 40,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E1B4B),
                ),
                alignment: Alignment.center,
                child: ShareableHeroNumber(
                  data: data,
                  size: 64,
                  unitSize: 14,
                  stacked: true,
                  color: Colors.white,
                  unitColor: Colors.amber.shade200,
                ),
              ),
            ),
            const Spacer(),
            ...data.highlights.take(3).map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h.label.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11 * mul,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        Text(
                          h.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * mul,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            if (showWatermark) AppWatermark(textColor: Colors.white),
          ],
        ),
      ),
    );
  }
}
