/// Glow Button Widget
///
/// Large, futuristic button with animated glow effects
/// and haptic feedback for gym-friendly interactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// Large glowing button with press animation
class GlowButton extends StatefulWidget {
  /// Button text or child widget
  final Widget child;

  /// Button tap callback
  final VoidCallback? onTap;

  /// Primary color for the button
  final Color color;

  /// Secondary color for gradient
  final Color? secondaryColor;

  /// Button width (null for auto)
  final double? width;

  /// Button height
  final double height;

  /// Border radius
  final double borderRadius;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is disabled
  final bool isDisabled;

  /// Icon to show before text
  final IconData? icon;

  /// Size of the icon
  final double iconSize;

  const GlowButton({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.glowCyan,
    this.secondaryColor,
    this.width,
    this.height = 56,
    this.borderRadius = 14,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconSize = 24,
  });

  /// Factory for complete set button
  factory GlowButton.complete({
    Key? key,
    required VoidCallback? onTap,
    required int setNumber,
    double? width,
    bool isLoading = false,
  }) {
    return GlowButton(
      key: key,
      onTap: onTap,
      color: AppColors.glowGreen,
      secondaryColor: const Color(0xFF00C853),
      width: width,
      height: 52,
      icon: Icons.check_rounded,
      isLoading: isLoading,
      child: Text(
        'COMPLETE SET $setNumber',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Factory for increment button (+ or -)
  factory GlowButton.increment({
    Key? key,
    required VoidCallback? onTap,
    required bool isAdd,
    Color color = AppColors.glowCyan,
    double size = 48,
  }) {
    return GlowButton(
      key: key,
      onTap: onTap,
      color: color,
      width: size,
      height: size,
      borderRadius: size / 2,
      child: Icon(
        isAdd ? Icons.add_rounded : Icons.remove_rounded,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading) return;
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = widget.secondaryColor ??
        HSLColor.fromColor(widget.color).withLightness(0.3).toColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.isDisabled
                    ? null
                    : LinearGradient(
                        colors: [widget.color, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: widget.isDisabled ? Colors.grey.shade700 : null,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: widget.color.withOpacity(_glowAnimation.value),
                          blurRadius: _isPressed ? 24 : 16,
                          spreadRadius: _isPressed ? 2 : 0,
                        ),
                        if (_isPressed)
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: widget.iconSize,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                            ],
                            DefaultTextStyle(
                              style: TextStyle(
                                color: widget.isDisabled
                                    ? Colors.grey.shade400
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              child: widget.child,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circular increment/decrement button with glow
class GlowIncrementButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isAdd;
  final double size;
  final Color color;
  final bool isDisabled;

  const GlowIncrementButton({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.isAdd,
    this.size = 48,
    this.color = AppColors.glowCyan,
    this.isDisabled = false,
  });

  @override
  State<GlowIncrementButton> createState() => _GlowIncrementButtonState();
}

class _GlowIncrementButtonState extends State<GlowIncrementButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.isDisabled ? null : widget.onTap,
          onLongPress: widget.isDisabled ? null : widget.onLongPress,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isDisabled
                    ? null
                    : LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.3),
                          widget.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: widget.isDisabled
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                    : null,
                border: Border.all(
                  color: widget.isDisabled
                      ? Colors.grey.shade600
                      : widget.color.withOpacity(_isPressed ? 0.8 : 0.5),
                  width: 2,
                ),
                boxShadow: widget.isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: widget.color.withOpacity(_isPressed ? 0.5 : 0.2),
                          blurRadius: _isPressed ? 16 : 8,
                          spreadRadius: _isPressed ? 2 : 0,
                        ),
                      ],
              ),
              child: Icon(
                widget.isAdd ? Icons.add_rounded : Icons.remove_rounded,
                size: widget.size * 0.5,
                color: widget.isDisabled
                    ? Colors.grey.shade500
                    : widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
