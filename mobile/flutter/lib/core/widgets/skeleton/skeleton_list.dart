/// Part 1 of the instant-load standard — list / card skeleton helpers.
///
/// Builds on [SkeletonBox] / [SkeletonText] / [SkeletonCircle] to produce the
/// two most common loading layouts: a vertical list of placeholder rows and a
/// single placeholder card. Use these for the `skeletonBuilder` of a
/// `CacheFirstView` on any list- or card-shaped screen.
library;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'skeleton_box.dart';

/// A single placeholder "card": a rounded, theme-surface container holding an
/// optional leading circle (avatar/icon) and a short stack of text lines.
///
/// Sized to roughly match a typical content card so the skeleton → content
/// swap is reflow-free; pass [height] to pin it exactly to your real card.
class SkeletonCard extends StatelessWidget {
  /// Show a leading [SkeletonCircle] (e.g. for avatar/icon rows).
  final bool showLeading;

  /// Diameter of the leading circle when [showLeading] is true.
  final double leadingSize;

  /// Number of text lines inside the card.
  final int lines;

  /// Fixed card height. Null → the card sizes to its content.
  final double? height;

  /// Inner padding.
  final EdgeInsets padding;

  /// Card corner radius.
  final double radius;

  const SkeletonCard({
    super.key,
    this.showLeading = true,
    this.leadingSize = 44,
    this.lines = 2,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLeading) ...[
            SkeletonCircle(size: leadingSize),
            const SizedBox(width: 12),
          ],
          Expanded(child: SkeletonText(lines: lines)),
        ],
      ),
    );
  }
}

/// A vertical list of [SkeletonCard]s — the standard placeholder for any
/// scrollable list screen (workout history, food log, leaderboard, etc).
///
/// Renders [itemCount] cards separated by [spacing]. By default it is a plain,
/// non-scrolling [Column] (`shrinkWrap`-style) so it can be dropped into any
/// parent; set [scrollable] to wrap it in its own `ListView` when it is the
/// whole screen body.
class SkeletonList extends StatelessWidget {
  /// How many placeholder rows to render.
  final int itemCount;

  /// Vertical gap between rows.
  final double spacing;

  /// Outer padding around the list.
  final EdgeInsets padding;

  /// Whether to wrap the rows in a scrollable [ListView]. Leave false when the
  /// list is embedded inside an already-scrolling parent.
  final bool scrollable;

  /// Builder for each placeholder row. Defaults to a [SkeletonCard]. Override
  /// to layout-match a bespoke row.
  final Widget Function(BuildContext context, int index)? itemBuilder;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.spacing = 12,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
    this.itemBuilder,
  });

  Widget _item(BuildContext context, int index) =>
      itemBuilder?.call(context, index) ?? const SkeletonCard();

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: _item,
      );
    }
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            _item(context, i),
          ],
        ],
      ),
    );
  }
}

/// A placeholder grid — [itemCount] [SkeletonBox] tiles in a fixed-column grid.
///
/// Standard placeholder for grid screens (gym profiles, trophy wall, recipe
/// gallery). Non-scrolling by default for embedding; set [scrollable] when it
/// is the whole screen body.
class SkeletonGrid extends StatelessWidget {
  /// Total tiles to render.
  final int itemCount;

  /// Columns in the grid.
  final int crossAxisCount;

  /// Width / height ratio of each tile.
  final double childAspectRatio;

  /// Gap between tiles on both axes.
  final double spacing;

  /// Corner radius of each tile.
  final double tileRadius;

  /// Outer padding.
  final EdgeInsets padding;

  /// Whether to wrap in a scrollable [GridView].
  final bool scrollable;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.spacing = 12,
    this.tileRadius = 16,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
    Widget tile(BuildContext _, int __) => SkeletonBox(radius: tileRadius);

    if (scrollable) {
      return GridView.builder(
        padding: padding,
        gridDelegate: delegate,
        itemCount: itemCount,
        itemBuilder: tile,
      );
    }
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: delegate,
        itemCount: itemCount,
        itemBuilder: tile,
      ),
    );
  }
}
