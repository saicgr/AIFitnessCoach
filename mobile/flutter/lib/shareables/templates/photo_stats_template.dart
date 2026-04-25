import 'dart:ui';

import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/photo_backdrop.dart';

/// PhotoStats — user's photo full-bleed, title top-left, frosted-glass
/// stat strip across the bottom showing 3 highlights.
class PhotoStatsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoStatsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final stats = data.highlights.where((h) => h.isPopulated).take(3).toList();
    final accent = data.accentColor;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF0D1117), Color(0xFF161B22)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoBackdrop(
            path: data.customPhotoPath,
            fallbackGradient: [
              Color.lerp(accent, Colors.black, 0.25)!,
              Color.lerp(accent, Colors.black, 0.55)!,
            ],
            topScrim: 0.20,
            bottomScrim: 0.55,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 56, 36, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 * mul,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Colors.black87),
                    ],
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            Expanded(child: _stat(stats[i], mul)),
                            if (i < stats.length - 1)
                              Container(
                                width: 1,
                                height: 36,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (showWatermark)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FitWizWatermark(
                      textColor: Colors.white,
                      fontSize: 13 * mul,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(ShareableMetric m, double mul) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * mul,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          m.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 10 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
