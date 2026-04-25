import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// MagazineCover — full-canvas accent gradient with a single huge bold word
/// or number. Tiny rotated subscript on the right edge, watermark
/// bottom-left. Spotify-Wrapped × Vogue cover energy.
class MagazineCoverTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MagazineCoverTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String _bigWord(Shareable d) {
    final hero = shareableHeroString(d);
    if (hero != '—' && hero.isNotEmpty) return hero;
    return d.title.split(' ').first.toUpperCase();
  }

  double _coverSize(ShareableAspect a) {
    switch (a) {
      case ShareableAspect.story:
        return 240;
      case ShareableAspect.portrait:
        return 200;
      case ShareableAspect.square:
        return 160;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final word = _bigWord(data);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        accent,
        Color.lerp(accent, Colors.black, 0.55)!,
        const Color(0xFF000000),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top masthead.
          Positioned(
            top: 64,
            left: 36,
            right: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FITWIZ',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                    fontSize: data.aspect == ShareableAspect.story ? 64 : 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.periodLabel.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11 * mul,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    Text(
                      'VOL. 01',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11 * mul,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Big word — center.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _coverSize(data.aspect),
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    letterSpacing: -8,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right-edge rotated subscript.
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Transform.rotate(
                angle: 3.14159 / 2,
                child: Text(
                  shareableHeroUnit(data).isNotEmpty
                      ? shareableHeroUnit(data).toUpperCase()
                      : data.title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
          // Bottom strip — title + subtitle.
          Positioned(
            left: 36,
            right: 36,
            bottom: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 2,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      if (data.userDisplayName != null &&
                          data.userDisplayName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'BY ${data.userDisplayName!.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11 * mul,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showWatermark)
                  FitWizWatermark(
                    textColor: Colors.white,
                    fontSize: 12 * mul,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
