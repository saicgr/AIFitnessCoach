import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/animations/app_animations.dart';

/// A button widget with spring-based press animation and haptic feedback.
/// Provides tactile, Messenger-like press feedback with scale animation.
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final bool enableHaptics;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve pressCurve;
  final Curve releaseCurve;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.95,
    this.enableHaptics = true,
    this.pressDuration = const Duration(milliseconds: 100),
    this.releaseDuration = const Duration(milliseconds: 200),
    this.pressCurve = Curves.easeInOut,
    Curve? releaseCurve,
    this.splashColor,
    this.borderRadius,
  }) : releaseCurve = releaseCurve ?? AppAnimations.overshoot;

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.releaseDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.pressCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;

    setState(() => _isPressed = true);
    _controller.duration = widget.pressDuration;
    _controller.forward();

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _releaseButton();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _releaseButton();
  }

  void _releaseButton() {
    if (!_isPressed) return;

    setState(() => _isPressed = false);
    _controller.duration = widget.releaseDuration;

    // Use spring-like overshoot for release
    _scaleAnimation = Tween<double>(
      begin: widget.pressScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.releaseCurve,
    ));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0 + (1.0 - _scaleAnimation.value),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A convenience wrapper that adds press animation to elevated buttons
class AnimatedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enableHaptics;

  const AnimatedElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enableHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressButton(
      onTap: onPressed,
      enableHaptics: enableHaptics,
      child: ElevatedButton(
        onPressed: () {}, // Handled by AnimatedPressButton
        style: style,
        child: child,
      ),
    );
  }
}

/// A card with press animation, perfect for list items
class AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final Color? color;
  final BorderRadius? borderRadius;
  final double elevation;
  final double pressedElevation;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const AnimatedPressCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.98,
    this.color,
    this.borderRadius,
    this.elevation = 0,
    this.pressedElevation = 4,
    this.margin,
    this.padding,
  });

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    _releaseCard();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _releaseCard();
  }

  void _releaseCard() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.color ?? Theme.of(context).cardColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 + _elevationAnimation.value * 0.02),
                    blurRadius: 4 + _elevationAnimation.value * 2,
                    offset: Offset(0, 2 + _elevationAnimation.value),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Animated icon button with spring-based press feedback
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double pressScale;
  final EdgeInsets? padding;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.pressScale = 0.85,
    this.padding,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _release();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _release();
  }

  void _release() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * (1.0 - widget.pressScale));
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(8),
              decoration: widget.backgroundColor != null
                  ? BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            ),
          );
        },
      ),
    );
  }
}
