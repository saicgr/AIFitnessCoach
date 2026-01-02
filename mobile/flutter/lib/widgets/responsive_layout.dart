import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/window_mode_provider.dart';

/// A responsive layout widget that provides different layouts based on window size.
///
/// This widget automatically selects between compact, medium, and expanded layouts
/// based on the current window width, making it ideal for split-screen and
/// multi-window support.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   compact: (context, windowState) => CompactView(),
///   medium: (context, windowState) => MediumView(),
///   expanded: (context, windowState) => ExpandedView(),
/// )
/// ```
class ResponsiveLayout extends ConsumerWidget {
  /// Builder for compact layout (width < 600dp)
  /// Used for phones and narrow split-screen windows
  final Widget Function(BuildContext context, WindowModeState windowState) compact;

  /// Builder for medium layout (600dp <= width < 840dp)
  /// Used for tablets in portrait, large phones in landscape, and split-screen
  final Widget Function(BuildContext context, WindowModeState windowState)? medium;

  /// Builder for expanded layout (width >= 840dp)
  /// Used for tablets in landscape and desktop
  final Widget Function(BuildContext context, WindowModeState windowState)? expanded;

  /// Optional builder for when in split-screen mode specifically
  /// If provided, this overrides the size-based layout when in split screen
  final Widget Function(BuildContext context, WindowModeState windowState)? splitScreen;

  /// Whether to animate transitions between layouts
  final bool animateTransitions;

  /// Duration of transition animation
  final Duration transitionDuration;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.splitScreen,
    this.animateTransitions = true,
    this.transitionDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowModeProvider);

    // Select the appropriate layout builder
    Widget Function(BuildContext, WindowModeState) layoutBuilder;

    // Check for split-screen override first
    if (splitScreen != null && windowState.isInSplitScreen) {
      layoutBuilder = splitScreen!;
    } else {
      // Select based on window size class
      switch (windowState.sizeClass) {
        case WindowSizeClass.compact:
          layoutBuilder = compact;
          break;
        case WindowSizeClass.medium:
          layoutBuilder = medium ?? compact;
          break;
        case WindowSizeClass.expanded:
          layoutBuilder = expanded ?? medium ?? compact;
          break;
      }
    }

    final child = layoutBuilder(context, windowState);

    if (animateTransitions) {
      return AnimatedSwitcher(
        duration: transitionDuration,
        child: KeyedSubtree(
          key: ValueKey('${windowState.sizeClass}_${windowState.isInSplitScreen}'),
          child: child,
        ),
      );
    }

    return child;
  }
}

/// A convenience widget for building layouts with responsive spacing and padding
class ResponsiveContainer extends ConsumerWidget {
  final Widget child;

  /// Padding multiplier for compact mode (default 1.0)
  final double compactPaddingMultiplier;

  /// Padding multiplier for medium mode (default 1.5)
  final double mediumPaddingMultiplier;

  /// Padding multiplier for expanded mode (default 2.0)
  final double expandedPaddingMultiplier;

  /// Base horizontal padding
  final double baseHorizontalPadding;

  /// Base vertical padding
  final double baseVerticalPadding;

  /// Whether to use reduced spacing in split-screen mode
  final bool reduceSplitScreenSpacing;

  /// Maximum content width (for centering content on large screens)
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.compactPaddingMultiplier = 1.0,
    this.mediumPaddingMultiplier = 1.5,
    this.expandedPaddingMultiplier = 2.0,
    this.baseHorizontalPadding = 16.0,
    this.baseVerticalPadding = 12.0,
    this.reduceSplitScreenSpacing = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowModeProvider);

    // Calculate padding based on window state
    double multiplier;
    switch (windowState.sizeClass) {
      case WindowSizeClass.compact:
        multiplier = compactPaddingMultiplier;
        break;
      case WindowSizeClass.medium:
        multiplier = mediumPaddingMultiplier;
        break;
      case WindowSizeClass.expanded:
        multiplier = expandedPaddingMultiplier;
        break;
    }

    // Reduce spacing in split screen mode
    if (reduceSplitScreenSpacing && windowState.isInSplitScreen) {
      multiplier *= 0.6;
    }

    // Further reduce for very narrow layouts
    if (windowState.isNarrowLayout) {
      multiplier *= 0.5;
    }

    final horizontalPadding = baseHorizontalPadding * multiplier;
    final verticalPadding = baseVerticalPadding * multiplier;

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: child,
    );

    // Apply max width constraint if specified
    if (maxWidth != null && windowState.windowWidth > maxWidth!) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A responsive grid that adjusts columns based on window size
class ResponsiveGrid extends ConsumerWidget {
  final List<Widget> children;

  /// Minimum item width for calculating column count
  final double minItemWidth;

  /// Cross axis spacing between items
  final double crossAxisSpacing;

  /// Main axis spacing between items
  final double mainAxisSpacing;

  /// Padding around the grid
  final EdgeInsets? padding;

  /// Child aspect ratio (width / height)
  final double childAspectRatio;

  /// Maximum number of columns
  final int maxColumns;

  /// Whether to shrink wrap the grid
  final bool shrinkWrap;

  /// Scroll physics
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 150,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
    this.childAspectRatio = 1.0,
    this.maxColumns = 6,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowModeProvider);

    // Calculate column count based on window width and min item width
    int columns = (windowState.windowWidth / minItemWidth).floor();
    columns = columns.clamp(1, maxColumns);

    // Reduce columns in split screen for better visibility
    if (windowState.isInSplitScreen && columns > 1) {
      columns = (columns * 0.7).ceil().clamp(1, maxColumns);
    }

    // Reduce spacing in narrow layouts
    final spacing = windowState.isNarrowLayout
        ? (crossAxisSpacing * 0.5)
        : crossAxisSpacing;
    final mainSpacing = windowState.isNarrowLayout
        ? (mainAxisSpacing * 0.5)
        : mainAxisSpacing;

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      padding: padding ?? windowState.suggestedPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive row that wraps to column in narrow layouts
class ResponsiveRowOrColumn extends ConsumerWidget {
  final List<Widget> children;

  /// Width threshold below which to switch to column layout
  final double columnThreshold;

  /// Spacing between children
  final double spacing;

  /// Main axis alignment for row layout
  final MainAxisAlignment rowMainAxisAlignment;

  /// Cross axis alignment for row layout
  final CrossAxisAlignment rowCrossAxisAlignment;

  /// Main axis alignment for column layout
  final MainAxisAlignment columnMainAxisAlignment;

  /// Cross axis alignment for column layout
  final CrossAxisAlignment columnCrossAxisAlignment;

  /// Whether to force column layout in split screen
  final bool forceColumnInSplitScreen;

  const ResponsiveRowOrColumn({
    super.key,
    required this.children,
    this.columnThreshold = 400,
    this.spacing = 12,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.forceColumnInSplitScreen = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowModeProvider);

    final useColumn = windowState.windowWidth < columnThreshold ||
        (forceColumnInSplitScreen && windowState.isInSplitScreen && windowState.windowWidth < 500);

    // Reduce spacing in narrow layouts
    final effectiveSpacing = windowState.isNarrowLayout ? spacing * 0.5 : spacing;

    if (useColumn) {
      return Column(
        mainAxisAlignment: columnMainAxisAlignment,
        crossAxisAlignment: columnCrossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: _addSpacing(children, effectiveSpacing, Axis.vertical),
      );
    }

    return Row(
      mainAxisAlignment: rowMainAxisAlignment,
      crossAxisAlignment: rowCrossAxisAlignment,
      children: _addSpacing(children, effectiveSpacing, Axis.horizontal),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing, Axis axis) {
    if (widgets.isEmpty) return widgets;

    final spacer = axis == Axis.horizontal
        ? SizedBox(width: spacing)
        : SizedBox(height: spacing);

    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(spacer);
      }
    }
    return result;
  }
}

/// A widget that shows different content based on whether the app is in split screen
class SplitScreenAware extends ConsumerWidget {
  /// Widget to show in full-screen mode
  final Widget fullScreen;

  /// Widget to show in split-screen mode
  final Widget splitScreen;

  /// Whether to animate the transition
  final bool animate;

  const SplitScreenAware({
    super.key,
    required this.fullScreen,
    required this.splitScreen,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInSplitScreen = ref.watch(windowModeProvider).isInSplitScreen;

    final child = isInSplitScreen ? splitScreen : fullScreen;

    if (animate) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(isInSplitScreen),
          child: child,
        ),
      );
    }

    return child;
  }
}

/// Extension methods for responsive values
extension ResponsiveValues on BuildContext {
  /// Get a value based on window size class
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final windowWidth = MediaQuery.of(this).size.width;

    if (windowWidth >= 840) {
      return expanded ?? medium ?? compact;
    } else if (windowWidth >= 600) {
      return medium ?? compact;
    }
    return compact;
  }

  /// Get spacing value scaled for current window size
  double responsiveSpacing(double base) {
    final windowWidth = MediaQuery.of(this).size.width;

    if (windowWidth < 400) {
      return base * 0.5;
    } else if (windowWidth < 600) {
      return base * 0.75;
    } else if (windowWidth < 840) {
      return base;
    }
    return base * 1.25;
  }

  /// Get font size scaled for current window size
  double responsiveFontSize(double base) {
    final windowWidth = MediaQuery.of(this).size.width;

    if (windowWidth < 400) {
      return base * 0.9;
    } else if (windowWidth < 600) {
      return base;
    } else if (windowWidth < 840) {
      return base * 1.05;
    }
    return base * 1.1;
  }
}

/// A mixin that provides responsive helpers for ConsumerStatefulWidgets
mixin ResponsiveMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Get current window mode state
  WindowModeState get windowState => ref.watch(windowModeProvider);

  /// Check if in split screen mode
  bool get isInSplitScreen => windowState.isInSplitScreen;

  /// Check if in compact mode
  bool get isCompactMode => windowState.isCompactMode;

  /// Check if in narrow layout (very small width)
  bool get isNarrowLayout => windowState.isNarrowLayout;

  /// Get current window width
  double get windowWidth => windowState.windowWidth;

  /// Get current window height
  double get windowHeight => windowState.windowHeight;

  /// Get suggested padding for current window size
  EdgeInsets get suggestedPadding => windowState.suggestedPadding;

  /// Get a responsive value based on window state
  R responsiveValue<R>({
    required R compact,
    R? medium,
    R? expanded,
    R? splitScreen,
  }) {
    // Check for split screen override
    if (splitScreen != null && isInSplitScreen) {
      return splitScreen;
    }

    switch (windowState.sizeClass) {
      case WindowSizeClass.compact:
        return compact;
      case WindowSizeClass.medium:
        return medium ?? compact;
      case WindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  /// Get responsive horizontal padding
  double get responsiveHorizontalPadding {
    if (isNarrowLayout) return 8;
    if (isCompactMode) return 12;
    if (isInSplitScreen) return 10;
    return 16;
  }

  /// Get responsive vertical padding
  double get responsiveVerticalPadding {
    if (isNarrowLayout) return 4;
    if (isCompactMode) return 8;
    if (isInSplitScreen) return 6;
    return 12;
  }
}
