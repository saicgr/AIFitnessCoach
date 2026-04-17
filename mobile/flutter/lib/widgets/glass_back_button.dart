import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/services/haptic_service.dart';

/// Glassmorphic back button used consistently across all full screens.
///
/// Uses BackdropFilter for a frosted glass effect that adapts
/// to both dark and light themes.
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const GlassBackButton({
    super.key,
    this.onTap,
    this.icon = Icons.arrow_back_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        if (onTap != null) {
          onTap!();
        } else if (context.canPop()) {
          context.pop();
        }
      },
      // Use a semi-opaque DARK scrim regardless of theme so the button
      // stays legible on any underlying content — including white
      // hero videos (exercise detail screen) that previously hid the
      // white-tinted button entirely. Matches iOS/Android camera/photo
      // viewer convention: dark capsule + white icon.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              // Always-white icon on the dark scrim reads well on any bg.
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
