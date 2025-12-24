import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';

/// Typing indicator with animated bouncing dots.
class TypingIndicator extends StatelessWidget {
  final AnimationController animationController;

  const TypingIndicator({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: colors.cyanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colors.glassSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(controller: animationController, delay: 0.0),
                const SizedBox(width: 6),
                _AnimatedDot(controller: animationController, delay: 0.2),
                const SizedBox(width: 6),
                _AnimatedDot(controller: animationController, delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _AnimatedDot({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = (controller.value + delay) % 1.0;
        final bounce = progress < 0.5 ? progress * 2 : 2 - progress * 2;

        return Transform.translate(
          offset: Offset(0, -6 * bounce),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colors.cyan.withOpacity(0.5 + 0.5 * bounce),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.cyan.withOpacity(0.3 * bounce),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
