import 'package:flutter/material.dart';

import 'shareable_data.dart';

/// Aspect-aware capture wrapper. Templates receive the laid-out canvas size
/// + the selected aspect; they can switch root layout based on aspect.
///
/// Background is a single neutral charcoal — per-template visual identity
/// comes from the template content (Wrapped's accent gradient, Retro80s'
/// purple grid, etc.) rather than the wrapper. Templates that want a custom
/// background paint it inside themselves.
class ShareableCanvas extends StatelessWidget {
  final ShareableAspect aspect;
  final Widget child;
  final List<Color>? backgroundOverride;

  /// Optional accent used to tint the default background gradient when no
  /// [backgroundOverride] is provided. Templates pass `data.accentColor`
  /// here so each share asset has its own visual identity instead of
  /// every neutral-canvas template looking like the same charcoal void.
  final Color? accentColor;

  const ShareableCanvas({
    super.key,
    required this.aspect,
    required this.child,
    this.backgroundOverride,
    this.accentColor,
  });

  static const List<Color> neutralCharcoal = [
    Color(0xFF0D1117),
    Color(0xFF161B22),
    Color(0xFF21262D),
  ];

  /// Build an accent-tinted background by mixing the accent into the
  /// neutral charcoal stops. Keeps templates legible (mostly dark) while
  /// giving each share asset a distinct hue so users can tell variants
  /// apart at a glance in the gallery.
  static List<Color> _accentTinted(Color accent) {
    return <Color>[
      Color.lerp(neutralCharcoal[0], accent, 0.18) ?? neutralCharcoal[0],
      Color.lerp(neutralCharcoal[1], accent, 0.10) ?? neutralCharcoal[1],
      Color.lerp(neutralCharcoal[2], accent, 0.04) ?? neutralCharcoal[2],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = backgroundOverride ??
        (accentColor != null ? _accentTinted(accentColor!) : neutralCharcoal);
    return AspectRatio(
      aspectRatio: aspect.ratio,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Aspect-aware body-font multiplier. Templates hardcode font sizes tuned for
/// the 9:16 story canvas; the same sizes feel anemic on the wider/shorter
/// 4:5 portrait and especially the 1:1 square canvas, where the same
/// pixel value covers a smaller share of the viewport. Multiplying body
/// fontSize values by this brings every aspect to consistent visual weight.
/// Hero numbers keep their existing per-aspect branches (they already scale).
extension ShareableAspectFontScale on ShareableAspect {
  double get bodyFontMultiplier {
    switch (this) {
      case ShareableAspect.story:
        return 1.0;
      case ShareableAspect.portrait:
        return 1.15;
      case ShareableAspect.square:
        return 1.35;
    }
  }
}
