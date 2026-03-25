import 'package:flutter/material.dart';
import '../core/animations/app_animations.dart';
import '../core/services/haptic_service.dart';

/// A morphing pill indicator that stretches/squashes as it slides
/// between tab positions, creating a fluid "liquid" tab transition.
///
/// The indicator stretches horizontally (squash effect) mid-animation,
/// then compresses back to pill size at the destination. The active icon
/// does a subtle bounce on arrival.
///
/// Usage: Wrap the nav bar's Row of items in a Stack, placing this behind.
/// ```dart
/// MorphingTabIndicator(
///   selectedIndex: _currentIndex,
///   itemCount: 4,
///   itemWidth: 80,
///   color: accentColor.withOpacity(0.15),
/// )
/// ```
class MorphingTabIndicator extends StatefulWidget {
  final int selectedIndex;
  final int itemCount;

  /// Total width of the row containing all items.
  final double totalWidth;

  /// Height of the indicator pill.
  final double height;

  /// Border radius of the indicator pill.
  final double borderRadius;

  /// Color of the indicator pill.
  final Color color;

  /// Horizontal padding inset from the edges.
  final double horizontalPadding;

  /// Duration of the morph animation.
  final Duration duration;

  /// How much the indicator stretches at the midpoint (1.0 = no stretch).
  final double stretchFactor;

  const MorphingTabIndicator({
    super.key,
    required this.selectedIndex,
    required this.itemCount,
    required this.totalWidth,
    this.height = 36,
    this.borderRadius = 20,
    required this.color,
    this.horizontalPadding = 6,
    this.duration = const Duration(milliseconds: 300),
    this.stretchFactor = 1.4,
  });

  @override
  State<MorphingTabIndicator> createState() => _MorphingTabIndicatorState();
}

class _MorphingTabIndicatorState extends State<MorphingTabIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _widthAnimation;

  int _previousIndex = 0;
  double _baseItemWidth = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _baseItemWidth = _calculateItemWidth();
    _positionAnimation = AlwaysStoppedAnimation(_getTargetPosition(widget.selectedIndex));
    _widthAnimation = const AlwaysStoppedAnimation(1.0);
  }

  double _calculateItemWidth() {
    final usableWidth = widget.totalWidth - widget.horizontalPadding * 2;
    return usableWidth / widget.itemCount;
  }

  double _getTargetPosition(int index) {
    return widget.horizontalPadding + index * _baseItemWidth;
  }

  @override
  void didUpdateWidget(covariant MorphingTabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _baseItemWidth = _calculateItemWidth();

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _animateToIndex(widget.selectedIndex);
    }
  }

  void _animateToIndex(int newIndex) {
    final startPos = _getTargetPosition(_previousIndex);
    final endPos = _getTargetPosition(newIndex);

    _positionAnimation = Tween<double>(
      begin: startPos,
      end: endPos,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.decelerate,
    ));

    // Stretch in the middle of the animation, return to normal at ends
    _widthAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.stretchFactor)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.stretchFactor, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.reset();
    _controller.forward();

    HapticService.instance.tap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentWidth = _baseItemWidth * _widthAnimation.value;
        // Center the stretched width around the moving position
        final widthDelta = currentWidth - _baseItemWidth;
        final left = _positionAnimation.value - widthDelta / 2;

        return Positioned(
          left: left,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: currentWidth,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Wraps a nav bar icon with a bounce animation when it becomes selected.
class BounceOnSelect extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Duration duration;

  const BounceOnSelect({
    super.key,
    required this.child,
    required this.isSelected,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<BounceOnSelect> createState() => _BounceOnSelectState();
}

class _BounceOnSelectState extends State<BounceOnSelect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: AppAnimations.bouncy)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant BounceOnSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
