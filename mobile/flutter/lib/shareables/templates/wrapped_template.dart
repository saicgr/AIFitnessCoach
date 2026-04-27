import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Wrapped — accent gradient canvas, large WRAPPED title, numbered highlight
/// list, hero anchored low. Fixes the old "giant green void" by filling the
/// vertical space with content rather than `Spacer()` to push everything down.
class WrappedTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WrappedTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final highlights = data.highlights.take(4).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        accent,
        Color.lerp(accent, Colors.black, 0.45)!,
        const Color(0xFF05050A),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative diagonal slashes (the Wrapped signature).
          Positioned(
            top: 110,
            left: -60,
            right: -60,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                height: 36,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 220,
            left: -60,
            right: -60,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                height: 22,
                color: Colors.black.withValues(alpha: 0.22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WRAPPED',
                  style: TextStyle(
                    fontSize: data.aspect == ShareableAspect.story ? 80 : 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.95,
                    letterSpacing: -2.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16 * mul,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(height: 24),
                if (highlights.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(highlights.length, (i) {
                        final h = highlights[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                (i + 1).toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 14 * mul,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  h.label.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12 * mul,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                              Text(
                                h.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17 * mul,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                const Spacer(),
                Text(
                  'YOUR NUMBER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.6,
                  ),
                ),
                const SizedBox(height: 6),
                ShareableHeroNumber(
                  data: data,
                  size: data.aspect == ShareableAspect.story ? 160 : 110,
                  unitSize: 18,
                  stacked: false,
                  color: Colors.white,
                  unitColor: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                if (data.userDisplayName != null &&
                    data.userDisplayName!.trim().isNotEmpty)
                  Text(
                    data.userDisplayName!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                const SizedBox(height: 16),
                if (showWatermark)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppWatermark(textColor: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
