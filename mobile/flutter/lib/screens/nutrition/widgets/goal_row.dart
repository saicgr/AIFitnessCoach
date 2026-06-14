import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class GoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const GoalRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cardBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: ZType.lbl(12, color: textPrimary, letterSpacing: 1.5),
            ),
          ),
          Text(
            value,
            style: ZType.disp(20, color: color, letterSpacing: 0.5),
          ),
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              unit.toUpperCase(),
              style: ZType.lbl(10, color: color.withValues(alpha: 0.7), letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
