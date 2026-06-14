import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

/// Hairline Barlow chip — filter/tag/action chips.
class ZealovaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;
  const ZealovaChip({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = selected ? tc.accent : tc.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? tc.accent : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
            ] else if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
            ],
            Text(label.toUpperCase(),
                style: ZType.lbl(10, color: fg, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Signature text-tab bar — Barlow uppercase tabs with an accent underline on
/// the active item (replaces the per-screen pill tab bars).
class ZealovaTextTabs extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int>? onChanged;
  const ZealovaTextTabs({
    super.key,
    required this.tabs,
    required this.activeIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          GestureDetector(
            onTap: () => onChanged?.call(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tabs[i].toUpperCase(),
                  style: ZType.lbl(
                    12.5,
                    color: i == activeIndex ? tc.textPrimary : tc.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 18,
                  color: i == activeIndex ? tc.accent : Colors.transparent,
                ),
              ],
            ),
          ),
          if (i != tabs.length - 1) const SizedBox(width: 18),
        ],
      ],
    );
  }
}
