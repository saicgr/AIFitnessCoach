import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// Reusable sheet header with optional back button, title, and close button.
///
/// Standard header for all bottom sheets in the app.
///
/// Features:
/// - Handle bar at top
/// - Optional back button (floating, top-left)
/// - Icon with colored background
/// - Title and optional subtitle
/// - Close button
///
/// Usage:
/// ```dart
/// SheetHeader(
///   icon: Icons.fitness_center_rounded,
///   iconColor: AppColors.cyan,
///   title: 'Switch Gym',
///   onBack: () => Navigator.pop(context), // Optional
///   onClose: () => Navigator.pop(context),
/// )
/// ```
class SheetHeader extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Color for the icon and its background
  final Color iconColor;

  /// Title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Callback when back button is pressed (if null, no back button shown)
  final VoidCallback? onBack;

  /// Callback when close button is pressed
  final VoidCallback onClose;

  /// Whether to show the handle bar
  final bool showHandle;

  const SheetHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onBack,
    required this.onClose,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        if (showHandle)
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              // Back button (if provided)
              if (onBack != null) ...[
                _BackButton(
                  onTap: onBack!,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
              ],

              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Close button
              IconButton(
                onPressed: () {
                  HapticService.light();
                  onClose();
                },
                icon: Icon(Icons.close_rounded, color: textSecondary),
              ),
            ],
          ),
        ),

        // Divider
        Divider(height: 1, color: cardBorder),
      ],
    );
  }
}

/// Floating back button for sheet navigation
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _BackButton({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: glassSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

/// Standalone floating back button that can be positioned anywhere
///
/// Use this when you need a back button outside of [SheetHeader],
/// for example in a Stack positioned at the top-left.
class SheetBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const SheetBackButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
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
          Icons.arrow_back_rounded,
          color: textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
