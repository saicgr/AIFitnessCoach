import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Widget — iOS-widget aesthetic. Charcoal canvas background with a
/// centered rounded-rect card (28pt corners, soft shadow), period header,
/// title, hero number, subtitle, Zealova icon row at the bottom of the
/// card. Gives the share asset that "screenshot of my home screen widget"
/// energy users actually post.
class WidgetTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WidgetTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: accent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(72),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1F2C),
                    Color.lerp(accent, const Color(0xFF1A1F2C), 0.7)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.periodLabel.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.4,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: accent,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * mul,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: ShareableHeroNumber(
                      data: data,
                      size: 96,
                      unitSize: 14 * mul,
                      stacked: true,
                      color: Colors.white,
                      unitColor: accent,
                    ),
                  ),
                  const Spacer(),
                  if (showWatermark)
                    Row(
                      children: [
                        AppWatermark(
                          textColor: Colors.white,
                          fontSize: 11 * mul,
                          iconSize: 16,
                        ),
                        const Spacer(),
                        Text(
                          'NOW',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 9 * mul,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
