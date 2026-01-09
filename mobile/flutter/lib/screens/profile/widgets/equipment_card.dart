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

  /// Format equipment name for display
  String _formatEquipmentName(String equipment) {
    const displayNames = {
      'full_gym': 'Full Gym Access',
      'home_gym': 'Home Gym',
      'bodyweight': 'Bodyweight',
      'dumbbells': 'Dumbbells',
      'barbell': 'Barbell',
      'kettlebell': 'Kettlebell',
      'resistance_bands': 'Resistance Bands',
      'pull_up_bar': 'Pull-up Bar',
      'cable_machine': 'Cable Machine',
      'smith_machine': 'Smith Machine',
      'leg_press': 'Leg Press',
      'bench': 'Bench',
      'squat_rack': 'Squat Rack',
    };
    return displayNames[equipment] ?? equipment.replaceAll('_', ' ');
  }

  /// Get simplified equipment list for display
  List<String> _getDisplayEquipment(List<String> equipment) {
    // If user has full_gym, just show that - they have access to everything
    if (equipment.contains('full_gym')) {
      return ['full_gym'];
    }

    // If user has home_gym, show that plus any unique items
    if (equipment.contains('home_gym')) {
      final uniqueItems = equipment.where((e) =>
        e != 'home_gym' &&
        e != 'dumbbells' &&
        e != 'barbell' &&
        e != 'bench'
      ).toList();
      return ['home_gym', ...uniqueItems];
    }

    // Otherwise show all equipment
    return equipment;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    final rawEquipment = user?.equipmentList ?? ['bodyweight'];
    final equipment = _getDisplayEquipment(rawEquipment);

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
            label: _formatEquipmentName(eq),
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
