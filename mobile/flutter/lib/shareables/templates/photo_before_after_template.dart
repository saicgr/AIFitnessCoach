import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/photo_backdrop.dart';

/// PhotoBeforeAfter — two photos split side-by-side (square/portrait) or
/// stacked (story), labeled BEFORE/AFTER, with a delta-stat pill anchored
/// in the center between them. The transformation reel format.
class PhotoBeforeAfterTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoBeforeAfterTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;
    final mul = data.aspect.bodyFontMultiplier;
    final stack = data.aspect == ShareableAspect.story;
    final fallback = [
      Color.lerp(accent, Colors.black, 0.35)!,
      Color.lerp(accent, Colors.black, 0.65)!,
    ];

    final beforePane = _Pane(
      path: data.customPhotoPath,
      label: 'BEFORE',
      sublabel: _firstHighlightOr(data, idx: 1, fallback: 'Day 1'),
      accent: accent,
      mul: mul,
      fallback: fallback,
      bottomScrim: 0.40,
    );
    final afterPane = _Pane(
      path: data.customPhotoPathSecondary,
      label: 'AFTER',
      sublabel: _firstHighlightOr(data, idx: 0, fallback: data.periodLabel),
      accent: accent,
      mul: mul,
      fallback: fallback,
      bottomScrim: 0.40,
    );

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (stack)
            Column(
              children: [
                Expanded(child: beforePane),
                Expanded(child: afterPane),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: beforePane),
                Expanded(child: afterPane),
              ],
            ),
          // Center delta pill — straddles the divide between the two photos.
          Center(child: _deltaPill(accent, mul)),
          // Watermark anchored to the bottom edge.
          if (showWatermark)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: AppWatermark(
                  textColor: Colors.white,
                  fontSize: 12 * mul,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _firstHighlightOr(Shareable d,
      {required int idx, required String fallback}) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (hl.length > idx) return hl[idx].value;
    return fallback;
  }

  Widget _deltaPill(Color accent, double mul) {
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);
    final value = (hero == '—' || hero.isEmpty)
        ? data.title
        : (unit.isEmpty ? hero : '$hero $unit');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded,
              color: Colors.black, size: 22 * mul),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 22 * mul,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final String? path;
  final String label;
  final String sublabel;
  final Color accent;
  final double mul;
  final List<Color> fallback;
  final double bottomScrim;

  const _Pane({
    required this.path,
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.mul,
    required this.fallback,
    required this.bottomScrim,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PhotoBackdrop(
          path: path,
          fallbackGradient: fallback,
          topScrim: 0.20,
          bottomScrim: bottomScrim,
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                sublabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * mul,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(blurRadius: 6, color: Colors.black87),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
