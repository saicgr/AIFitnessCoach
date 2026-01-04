/// Glass Card Widget
///
/// A reusable glassmorphic container with backdrop blur,
/// subtle borders, and optional glow effects for futuristic UI.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Glassmorphic card container with blur effect
class GlassCard extends StatelessWidget {
  /// Child widget to display inside the card
  final Widget child;

  /// Padding inside the card
  final EdgeInsetsGeometry padding;

  /// Margin around the card
  final EdgeInsetsGeometry margin;

  /// Border radius of the card
  final double borderRadius;

  /// Blur intensity (sigma)
  final double blurSigma;

  /// Optional glow color for active state
  final Color? glowColor;

  /// Glow intensity (0.0 - 1.0)
  final double glowIntensity;

  /// Background opacity (0.0 - 1.0)
  final double backgroundOpacity;

  /// Border opacity (0.0 - 1.0)
  final double borderOpacity;

  /// Whether the card is in active/highlighted state
  final bool isActive;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16,
    this.blurSigma = 10,
    this.glowColor,
    this.glowIntensity = 0.3,
    this.backgroundOpacity = 0.15,
    this.borderOpacity = 0.2,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = glowColor ?? AppColors.glowCyan;

    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: padding,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(backgroundOpacity)
                    : Colors.white.withOpacity(backgroundOpacity * 2),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isActive
                      ? effectiveGlowColor.withOpacity(0.5)
                      : (isDark
                          ? Colors.white.withOpacity(borderOpacity)
                          : Colors.black.withOpacity(borderOpacity * 0.5)),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: effectiveGlowColor.withOpacity(glowIntensity),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: effectiveGlowColor.withOpacity(glowIntensity * 0.5),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass card with animated glow pulse effect
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color glowColor;
  final bool animate;
  final VoidCallback? onTap;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16,
    this.glowColor = AppColors.glowCyan,
    this.animate = true,
    this.onTap,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
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
      animation: _glowAnimation,
      builder: (context, child) {
        return GlassCard(
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          glowColor: widget.glowColor,
          glowIntensity: widget.animate ? _glowAnimation.value : 0.3,
          isActive: true,
          onTap: widget.onTap,
          child: widget.child,
        );
      },
    );
  }
}

/// Simple glass surface without backdrop blur (for performance)
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;
  final bool isActive;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    this.glowColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = glowColor ?? AppColors.glowCyan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.glassSurface.withOpacity(0.8)
            : AppColorsLight.glassSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isActive
              ? effectiveGlowColor.withOpacity(0.5)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: effectiveGlowColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
