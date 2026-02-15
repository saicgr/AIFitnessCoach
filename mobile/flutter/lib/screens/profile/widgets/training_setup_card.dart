import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/edit_gym_profile_sheet.dart';

/// Unified card displaying equipment and workout preferences with edit capability.
/// Equipment and Environment are pulled from the active gym profile.
class TrainingSetupCard extends ConsumerWidget {
  final User? user;
  final VoidCallback? onCustomEquipment;

  const TrainingSetupCard({
    super.key,
    required this.user,
    this.onCustomEquipment,
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

  /// Get simplified equipment display text
  String _getEquipmentDisplay(List<String> equipment) {
    if (equipment.isEmpty) return 'Not set';

    // If user has full_gym, just show that
    if (equipment.contains('full_gym')) {
      return 'Full Gym Access';
    }

    // If user has home_gym, show that
    if (equipment.contains('home_gym')) {
      return 'Home Gym';
    }

    // Otherwise show count or list
    if (equipment.length <= 3) {
      return equipment.map(_formatEquipmentName).join(', ');
    }
    return '${equipment.length} items';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    // Get the active gym profile for equipment and environment
    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final equipment = activeGymProfile?.equipment ?? user?.equipmentList ?? [];
    final environment = activeGymProfile?.environmentDisplayName ?? user?.workoutEnvironmentDisplay ?? 'Not set';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with edit icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (activeGymProfile != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showGlassSheet(
                      context: context,
                      builder: (context) => EditGymProfileSheet(
                        profile: activeGymProfile,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Equipment row
          _SetupRow(
            icon: Icons.fitness_center,
            label: 'Equipment',
            value: _getEquipmentDisplay(equipment),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),

          // Environment row (from gym profile)
          _SetupRow(
            icon: Icons.location_on_outlined,
            label: 'Environment',
            value: environment,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),

          // Experience row
          _SetupRow(
            icon: Icons.timeline,
            label: 'Experience',
            value: user?.trainingExperienceDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),

          // Focus Areas row
          _SetupRow(
            icon: Icons.center_focus_strong,
            label: 'Focus Areas',
            value: user?.focusAreasDisplay ?? 'Full body',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),

          // Motivation row
          _SetupRow(
            icon: Icons.favorite_outline,
            label: 'Motivation',
            value: user?.motivationDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),

          // Workout Days row
          _SetupRow(
            icon: Icons.calendar_today_outlined,
            label: 'Workout Days',
            value: user?.workoutDaysFormatted ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Custom Equipment link
          if (onCustomEquipment != null) ...[
            const SizedBox(height: 16),
            Divider(
              color: textSecondary.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: 12),
            _TappableRow(
              icon: Icons.build_outlined,
              label: 'My Custom Equipment',
              subtitle: 'Add equipment not in the standard list',
              iconColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: onCustomEquipment!,
            ),
          ],
        ],
      ),
    );
  }
}

/// A single row in the setup card.
class _SetupRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _SetupRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A tappable row with icon, label, subtitle, and chevron.
class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: textSecondary,
          ),
        ],
      ),
    );
  }
}
