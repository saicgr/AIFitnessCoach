import 'package:flutter/material.dart';

/// A horizontally scrolling row of chips that *tells you it scrolls*.
///
/// E2E register row 148: five separate surfaces sliced their rightmost chip
/// mid-word with no fade, peek or arrow — "Quick lo…", "Nutritio…",
/// "DIFFICULTY: MODERATE" cut by the screen edge. A sliced word reads as a
/// layout bug, not as "scroll me", so the actions parked off-screen were
/// simply never found.
///
/// The treatment here is lifted verbatim from `chat_quick_pills.dart`, which
/// arrived at it the hard way (row 108). Two properties matter and are easy to
/// get wrong:
///
///  * **The fade is a fixed 12 logical px, not a fraction of the viewport.**
///    A fractional mask (stops 0.82 → 1.0) dissolves ~18% of the strip —
///    roughly 70px on a phone — and eats whichever chip parks there. 12px is
///    gutter, not text.
///  * **A trailing spacer** lets the last chip scroll clear of the fade
///    instead of dying under it.
///
/// Use this instead of a bare `SingleChildScrollView(scrollDirection:
/// Axis.horizontal)` for any chip/pill strip. `lib/core/theme/` is untouched by
/// this widget — it paints no colour of its own, so it is accent-neutral.
class FadingChipRow extends StatelessWidget {
  const FadingChipRow({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.spacing = 8,
    this.trailingGutter = 24,
    this.fadeWidth = 12,
    this.controller,
    this.physics,
  });

  /// The chips, in order. Spacing between them is applied here — callers
  /// should NOT wrap each child in its own trailing padding.
  final List<Widget> children;

  /// Inset applied inside the scroll view. Note a `EdgeInsets.zero` horizontal
  /// padding is what butted the 5th Sort chip against the screen edge in
  /// `menu_analysis_sheet.dart`; give it a real leading inset.
  final EdgeInsetsGeometry padding;

  /// Gap between adjacent chips.
  final double spacing;

  /// Extra width after the final chip so it can scroll past the fade.
  final double trailingGutter;

  /// Width of the right-hand fade, in logical pixels. Keep this narrow —
  /// see the class docstring.
  final double fadeWidth;

  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      row.add(children[i]);
      if (i != children.length - 1) {
        row.add(SizedBox(width: spacing));
      }
    }
    row.add(SizedBox(width: trailingGutter));

    return ShaderMask(
      shaderCallback: (rect) {
        final solidStop =
            rect.width <= fadeWidth ? 0.0 : (rect.width - fadeWidth) / rect.width;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, solidStop, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: controller,
        physics: physics,
        padding: padding,
        child: Row(mainAxisSize: MainAxisSize.min, children: row),
      ),
    );
  }
}
