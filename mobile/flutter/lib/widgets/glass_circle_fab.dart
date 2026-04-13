import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// Circular glassmorphic FAB used across the measurements flow. Matches
/// [GlassBackButton]'s translucent-blur styling so the "+ add" button and the
/// "< back" button read as the same family of floating controls.
///
/// Prefer this over [FloatingActionButton] / [FloatingActionButton.extended]
/// when the surrounding screen already uses the glass back button — a solid
/// accent pill breaks the visual consistency.
class GlassCircleFab extends StatelessWidget {
  final VoidCallback onPressed;

  /// Icon rendered inside the pill. Defaults to [Icons.add_rounded].
  final IconData icon;

  /// Visual size of the button (it stays a perfect circle).
  final double size;

  /// Screen-reader / long-press label. Since there's no visible caption
  /// (the old FAB extended read "Log Weight"), this keeps affordance for
  /// accessibility tools.
  final String? tooltip;

  const GlassCircleFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.size = 56,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = size / 2;

    final button = GestureDetector(
      onTap: () {
        HapticService.light();
        onPressed();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColorsLight.textPrimary,
              size: size * 0.46,
            ),
          ),
        ),
      ),
    );

    // Tooltip wraps only when provided — Tooltip adds a MouseRegion /
    // semantics layer we don't want bleeding into pixel-perfect layouts.
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
