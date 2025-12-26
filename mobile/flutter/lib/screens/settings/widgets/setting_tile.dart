import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A data class representing a single setting item.
class SettingItemData {
  /// The icon to display for this setting.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional subtitle text shown below the title.
  final String? subtitle;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Optional custom trailing widget.
  final Widget? trailing;

  /// Whether this item controls the theme toggle.
  final bool isThemeToggle;

  /// Whether this item controls the follow system theme toggle.
  final bool isFollowSystemToggle;

  /// Whether this item is the theme selector (System/Light/Dark).
  final bool isThemeSelector;

  /// Whether this item is the timezone selector.
  final bool isTimezoneSelector;

  const SettingItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isThemeToggle = false,
    this.isFollowSystemToggle = false,
    this.isThemeSelector = false,
    this.isTimezoneSelector = false,
  });
}

/// A single setting tile widget with icon, title, subtitle, and optional trailing widget.
///
/// Used for individual settings items that may have navigation or custom actions.
class SettingTile extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Optional custom trailing widget (overrides default chevron).
  final Widget? trailing;

  /// Whether to show a chevron indicator for navigation.
  final bool showChevron;

  /// Custom icon color (defaults to textSecondary).
  final Color? iconColor;

  /// The border radius for ink splash.
  final BorderRadius? borderRadius;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.iconColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null && showChevron)
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
