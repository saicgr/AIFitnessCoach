import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Inline theme selector with 3 buttons: System, Light, Dark
/// Provides immediate feedback without requiring a bottom sheet
class InlineThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const InlineThemeSelector({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.pureBlack.withValues(alpha: 0.5)
        : AppColorsLight.cardBorder.withValues(alpha: 0.5);
    final selectedColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemeButton(
            icon: Icons.smartphone_outlined,
            label: 'Auto',
            isSelected: currentMode == ThemeMode.system,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.system),
          ),
          ThemeButton(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isSelected: currentMode == ThemeMode.light,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.light),
          ),
          ThemeButton(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Individual theme button for the inline selector
class ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color textMuted;
  final VoidCallback onTap;

  const ThemeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isSelected
        ? (isDark ? AppColors.elevated : Colors.white)
        : Colors.transparent;
    final iconColor = isSelected ? selectedColor : textMuted;
    final textColor = isSelected
        ? (isDark ? Colors.white : AppColorsLight.textPrimary)
        : textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
