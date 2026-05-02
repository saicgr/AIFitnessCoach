import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/services/haptic_service.dart';

/// Glassmorphic back button used consistently across all full screens.
///
/// Theme-aware by default: dark capsule + white icon in dark mode,
/// light glass capsule + dark icon in light mode. Pass
/// `forceDarkScrim: true` for screens with media/hero backgrounds
/// (exercise detail video, photo viewers) where the button must read
/// against arbitrary content regardless of app theme.
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final bool forceDarkScrim;

  const GlassBackButton({
    super.key,
    this.onTap,
    this.icon = Icons.arrow_back_rounded,
    this.forceDarkScrim = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use a dark scrim either when explicitly requested (media screens)
    // or when the app theme is dark. In light mode without media we use
    // a light glass capsule so the chrome matches the surrounding UI.
    final useDarkScrim = forceDarkScrim || isDark;

    final scrimColor = useDarkScrim
        ? Colors.black.withValues(alpha: forceDarkScrim ? 0.32 : 0.45)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = useDarkScrim
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);
    final iconColor = useDarkScrim ? Colors.white : Colors.black87;
    final shadowColor =
        useDarkScrim ? Colors.black.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        if (onTap != null) {
          onTap!();
        } else if (context.canPop()) {
          context.pop();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scrimColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}
