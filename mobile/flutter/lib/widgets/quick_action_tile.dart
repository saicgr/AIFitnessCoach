import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Shared tile chrome used by every quick-action surface — the home grid,
/// the action sheet's grid, and the More overflow. A fixed-size rounded
/// chip wraps the icon so glyphs with very different visual weights
/// (a thin bolt vs. a fat document-scanner) read as the same "size":
/// the chip + tinted background is the visual frame, not the icon's own
/// bounds.
///
/// `muteChip` swaps the icon-chip background to a neutral tint — used by
/// the More button and other "system" affordances so they don't compete
/// with the colored shortcuts.
class QuickActionTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final Widget? iconChild;
  final String label;
  final Color iconColor;
  final bool muteChip;
  final bool isPinned;

  const QuickActionTile({
    super.key,
    required this.isDark,
    required this.onTap,
    required this.label,
    required this.iconColor,
    this.onLongPress,
    this.icon,
    this.iconChild,
    this.muteChip = false,
    this.isPinned = false,
  }) : assert(icon != null || iconChild != null, 'icon or iconChild required');

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isPinned
        ? iconColor.withValues(alpha: isDark ? 0.55 : 0.45)
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08));

    final chipColor = muteChip
        ? (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06))
        : iconColor.withValues(alpha: isDark ? 0.18 : 0.14);
    final iconRender = iconChild ??
        Icon(
          icon,
          size: 18,
          color: muteChip ? textColor.withValues(alpha: 0.7) : iconColor,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Tightened from v=10 / chip 32 / label 26 (~84pt total) to
          // v=7 / chip 28 / label 22 (~70pt total) — the previous tile was
          // visibly taller than necessary inside the unified parent box,
          // so trim about one row's worth of vertical air.
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isPinned ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: iconRender,
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 22,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
