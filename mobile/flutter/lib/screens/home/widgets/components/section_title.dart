import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';

/// A section title widget with icon and optional badge
/// Used across customization sheets to label sections
class SectionTitle extends StatelessWidget {
  /// Icon to display before the title
  final IconData icon;

  /// Section title text
  final String title;

  /// Optional badge/count text displayed on the right
  final String? badge;

  /// Color for the icon (defaults to cyan from theme)
  final Color? iconColor;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.badge,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? colors.cyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Text(
            badge!,
            style: TextStyle(color: colors.cyan, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// A full section header with title, optional subtitle, and optional action
/// Used on the home screen for section separators
class SectionHeader extends StatelessWidget {
  /// Section title text
  final String title;

  /// Optional subtitle shown after the title
  final String? subtitle;

  /// Optional action text (e.g., "View All")
  final String? actionText;

  /// Callback when action is tapped
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colors.cyan,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
