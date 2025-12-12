import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';

/// A card with parallax scrolling effect for the background image.
/// Based on Flutter cookbook's parallax implementation.
class ParallaxCard extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final double height;
  final BorderRadius? borderRadius;
  final Gradient? overlayGradient;
  final Color? backgroundColor;

  ParallaxCard({
    super.key,
    this.imageUrl,
    required this.child,
    this.height = 200,
    this.borderRadius,
    this.overlayGradient,
    this.backgroundColor,
  });

  final GlobalKey _backgroundImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.elevated,
        ),
        child: Stack(
          children: [
            // Parallax background
            if (imageUrl != null && imageUrl!.isNotEmpty)
              _buildParallaxBackground(context),

            // Gradient overlay
            if (overlayGradient != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: overlayGradient),
                ),
              ),

            // Content
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxBackground(BuildContext context) {
    return Flow(
      delegate: ParallaxFlowDelegate(
        scrollable: Scrollable.of(context),
        listItemContext: context,
        backgroundImageKey: _backgroundImageKey,
      ),
      children: [
        CachedNetworkImage(
          key: _backgroundImageKey,
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, __) => Container(color: AppColors.glassSurface),
          errorWidget: (_, __, ___) => Container(color: AppColors.glassSurface),
        ),
      ],
    );
  }
}

/// FlowDelegate that creates the parallax scrolling effect.
class ParallaxFlowDelegate extends FlowDelegate {
  ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(width: constraints.maxWidth);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this list item within the viewport.
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox?;
    final listItemBox = listItemContext.findRenderObject() as RenderBox?;

    if (scrollableBox == null || listItemBox == null) {
      context.paintChild(0);
      return;
    }

    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    // Determine the percent position of this list item within the scrollable area.
    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction = (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

    // Calculate the vertical alignment of the background based on scroll percent.
    final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);

    // Convert the background alignment into a pixel offset for painting purposes.
    final backgroundRenderBox =
        backgroundImageKey.currentContext?.findRenderObject() as RenderBox?;

    if (backgroundRenderBox == null) {
      context.paintChild(0);
      return;
    }

    final backgroundSize = backgroundRenderBox.size;
    final listItemSize = context.size;
    final childRect = verticalAlignment.inscribe(
      backgroundSize,
      Offset.zero & listItemSize,
    );

    // Paint the background with translation transform.
    context.paintChild(
      0,
      transform: Transform.translate(offset: Offset(0.0, childRect.top)).transform,
    );
  }

  @override
  bool shouldRepaint(ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey;
  }
}

/// A simple parallax container for any scrollable content.
class ParallaxContainer extends StatefulWidget {
  final Widget child;
  final double parallaxFactor;

  const ParallaxContainer({
    super.key,
    required this.child,
    this.parallaxFactor = 0.3,
  });

  @override
  State<ParallaxContainer> createState() => _ParallaxContainerState();
}

class _ParallaxContainerState extends State<ParallaxContainer> {
  double _offset = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _offset = notification.metrics.pixels * widget.parallaxFactor;
          });
        }
        return false;
      },
      child: Transform.translate(
        offset: Offset(0, _offset),
        child: widget.child,
      ),
    );
  }
}
