import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// Back button used consistently across all full screens (AppBar.leading).
///
/// Matches [SheetBackButton] style exactly so all back buttons in the app
/// look the same regardless of whether they appear in a sheet or a screen.
///
/// Usage in AppBar:
/// ```dart
/// appBar: AppBar(
///   automaticallyImplyLeading: false,
///   leading: const GlassBackButton(),
///   ...
/// )
/// ```
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
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
        onTap: () {
          HapticService.light();
          if (onTap != null) {
            onTap!();
          } else if (context.canPop()) {
            context.pop();
          }
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: textSecondary,
            size: 22,
          ),
        ),
    );
  }
}
