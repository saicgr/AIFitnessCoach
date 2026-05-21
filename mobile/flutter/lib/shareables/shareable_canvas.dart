import 'package:flutter/material.dart';

import 'shareable_data.dart';

/// Inherited carrier for the share sheet's selected [ShareBackground].
///
/// Placed above each rendered template (preview pane + every gallery tile)
/// so [ShareableCanvas] — which lives *inside* each template — can pick the
/// surface treatment without all 58 templates having to thread a parameter.
class ShareSurface extends InheritedWidget {
  final ShareBackground background;

  const ShareSurface({
    super.key,
    required this.background,
    required super.child,
  });

  static ShareBackground of(BuildContext context) {
    final surface =
        context.dependOnInheritedWidgetOfExactType<ShareSurface>();
    return surface?.background ?? ShareBackground.themed;
  }

  @override
  bool updateShouldNotify(ShareSurface oldWidget) =>
      oldWidget.background != background;
}

/// Aspect-aware capture wrapper. Templates receive the laid-out canvas size
/// + the selected aspect; they can switch root layout based on aspect.
///
/// The surface treatment is driven by the [ShareSurface] ancestor:
///  - [ShareBackground.themed] — the template's own gradient, edge-to-edge.
///  - [ShareBackground.dark]   — a flat near-black surface, edge-to-edge.
///  - [ShareBackground.light]  — a light mat with the template inset as a
///    rounded card (the card keeps the themed fill so light-on-dark content
///    stays legible — no per-template recoloring needed).
///  - [ShareBackground.transparent] — no surface; the template is the same
///    rounded card floating on alpha, so the captured PNG is a drop-on-any-
///    photo sticker.
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

  /// Flat near-black surface for [ShareBackground.dark].
  static const List<Color> _flatDark = [
    Color(0xFF111114),
    Color(0xFF050506),
  ];

  /// Light mat behind the inset card for [ShareBackground.light].
  static const List<Color> _lightMat = [
    Color(0xFFF6F7F9),
    Color(0xFFE6E9EF),
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
    final mode = ShareSurface.of(context);
    // The template's signature palette — used edge-to-edge in themed mode,
    // and as the inset-card fill in light/transparent mode.
    final themed = backgroundOverride ??
        (accentColor != null ? _accentTinted(accentColor!) : neutralCharcoal);

    final Widget surface;
    switch (mode) {
      case ShareBackground.themed:
        surface = _fill(themed, child);
        break;
      case ShareBackground.dark:
        surface = _fill(_flatDark, child);
        break;
      case ShareBackground.light:
        surface = _fill(_lightMat, _insetCard(themed));
        break;
      case ShareBackground.transparent:
      case ShareBackground.video:
        // No surface — just the floating card on alpha. The card's soft
        // shadow is captured into the PNG so the sticker pops on any photo.
        // In [video] mode the user's clip is composited behind this sticker
        // by Instagram; the captured PNG is the same alpha sticker.
        surface = _insetCard(themed);
        break;
    }

    return AspectRatio(aspectRatio: aspect.ratio, child: surface);
  }

  Widget _fill(List<Color> colors, Widget content) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: content,
    );
  }

  /// The template content inset as a rounded card. Used by light +
  /// transparent modes. Margins/radius are in the template's ~1080-wide
  /// design space (templates are always laid out at [ShareableAspect.size]
  /// before capture), so fixed pixel values are correct here.
  Widget _insetCard(List<Color> cardColors) {
    const radius = 60.0;
    return Padding(
      padding: const EdgeInsets.all(36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: cardColors,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 44,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
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
