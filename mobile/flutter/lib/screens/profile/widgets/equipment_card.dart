import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';

/// Displays user's available equipment as chips.
class EquipmentCard extends StatelessWidget {
  final User? user;

  const EquipmentCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    final equipment = user?.equipmentList ?? ['Dumbbells', 'Bodyweight'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: equipment.map((eq) {
          return _EquipmentChip(
            label: eq,
            glassSurface: glassSurface,
            textPrimary: textPrimary,
            success: success,
          );
        }).toList(),
      ),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final String label;
  final Color glassSurface;
  final Color textPrimary;
  final Color success;

  const _EquipmentChip({
    required this.label,
    required this.glassSurface,
    required this.textPrimary,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: success,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
