/// Part 1 of the instant-load standard — the skeleton primitive kit.
///
/// One shared shimmer implementation, extracted from the Phase-A `_SkeletonBox`
/// in `unified_home_widgets.dart`, so every screen's loading placeholder looks
/// identical and is theme-aware (light + dark) for free.
///
/// Primitives in this file:
///  - [SkeletonBox]    — a single shimmering rounded rectangle.
///  - [SkeletonText]   — n stacked shimmering lines (paragraph placeholder).
///  - [SkeletonCircle] — a shimmering circle (avatars, icon slots).
///
/// All three render the SAME shimmer sweep (see [SkeletonShimmer]) so a screen
/// that mixes them never shows two different shimmer speeds / tones.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/theme_colors.dart';

/// The single, canonical shimmer wrapper for the whole app.
///
/// Wraps [child] in a `Shimmer.fromColors` whose base/highlight tones are
/// pulled from [ThemeColors] — `cardBorder` (the subtlest surface tone) as the
/// base and `glassSurface` as the sweep highlight, exactly the Phase-A Home
/// skeleton look. Because the colours resolve from `ThemeColors.of(context)`
/// the placeholder is correct on both light and dark themes with no caller
/// effort.
///
/// Prefer the higher-level [SkeletonBox] / [SkeletonText] / [SkeletonCircle]
/// for normal use; reach for [SkeletonShimmer] directly only when you need to
/// shimmer a bespoke shape.
class SkeletonShimmer extends StatelessWidget {
  /// The shape to shimmer. Its own colour shows through the sweep, so give it
  /// the base tone (the convenience widgets do this for you).
  final Widget child;

  /// Sweep period. Kept at the Phase-A 1200ms default for visual consistency.
  final Duration period;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: c.cardBorder,
      highlightColor: c.glassSurface,
      period: period,
      child: child,
    );
  }
}

/// A single shimmering rounded rectangle — the building block for every
/// layout-matched skeleton.
///
/// Give it the dimensions of the real content it stands in for so the skeleton
/// → content swap doesn't reflow the layout.
class SkeletonBox extends StatelessWidget {
  /// Fixed width. Null → expands to the parent's constraints (use inside a
  /// bounded parent, e.g. a `Row`/`Column` with `Expanded`, or a sized box).
  final double? width;

  /// Fixed height. Defaults to a single-line-ish 16pt.
  final double height;

  /// Corner radius. 8pt matches the Phase-A Home skeleton.
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return SkeletonShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.cardBorder,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A multi-line text placeholder — [lines] stacked [SkeletonBox]es.
///
/// The last line is rendered shorter (see [lastLineFraction]) so the block
/// reads as a paragraph rather than a solid rectangle, matching how real text
/// rarely fills its final line.
class SkeletonText extends StatelessWidget {
  /// Number of shimmering lines. Must be >= 1.
  final int lines;

  /// Height of each line.
  final double lineHeight;

  /// Vertical gap between lines.
  final double spacing;

  /// Corner radius of each line.
  final double radius;

  /// Width of the final line as a fraction of full width (0–1). Ignored when
  /// [lines] is 1 (a single line uses full width).
  final double lastLineFraction;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.lineHeight = 12,
    this.spacing = 8,
    this.radius = 6,
    this.lastLineFraction = 0.6,
  }) : assert(lines >= 1, 'SkeletonText needs at least one line');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (i) {
        final isLast = i == lines - 1;
        final line = SkeletonBox(height: lineHeight, radius: radius);
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          // Shorten the last line of a multi-line block via FractionallySized.
          child: (isLast && lines > 1)
              ? FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: lastLineFraction.clamp(0.1, 1.0),
                  child: line,
                )
              : line,
        );
      }),
    );
  }
}

/// A shimmering circle — avatar, profile photo, or round icon placeholder.
class SkeletonCircle extends StatelessWidget {
  /// Diameter of the circle.
  final double size;

  const SkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return SkeletonShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.cardBorder,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
