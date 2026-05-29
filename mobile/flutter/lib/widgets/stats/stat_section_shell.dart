import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';

/// Section header shared by the Workout "TRAINING STATS" and Nutrition
/// "NUTRITION STATS" blocks — an uppercase tracking label with an optional
/// trailing "See all" affordance, so both tabs read as one design.
class StatSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  /// Optional trailing action (e.g. "See all" → /stats).
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  const StatSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.onSeeAll,
    this.seeAllLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: textSecondary,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: () {
                HapticService.light();
                onSeeAll!();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllLabel ?? 'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: textMuted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Consistent card container for a stat card body (elevated bg + border +
/// radius 16). Keeps every card on both tabs visually identical.
class StatCardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const StatCardShell({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: child,
    );
  }
}
