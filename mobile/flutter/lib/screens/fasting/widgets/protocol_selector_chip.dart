import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';

/// Tappable chip showing the currently selected fasting protocol
class ProtocolSelectorChip extends StatelessWidget {
  final FastingProtocol selectedProtocol;
  final VoidCallback onTap;
  final bool isDark;

  const ProtocolSelectorChip({
    super.key,
    required this.selectedProtocol,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedProtocol.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${selectedProtocol.fastingHours}h fast',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
