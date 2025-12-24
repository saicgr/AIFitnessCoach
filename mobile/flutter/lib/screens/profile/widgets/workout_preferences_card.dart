import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';

/// Displays workout preferences from onboarding data.
class WorkoutPreferencesCard extends StatelessWidget {
  final User? user;

  const WorkoutPreferencesCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
          _PreferenceRow(
            icon: Icons.timeline,
            label: 'Experience',
            value: user?.trainingExperienceDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _PreferenceRow(
            icon: Icons.location_on_outlined,
            label: 'Environment',
            value: user?.workoutEnvironmentDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _PreferenceRow(
            icon: Icons.center_focus_strong,
            label: 'Focus Areas',
            value: user?.focusAreasDisplay ?? 'Full body',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _PreferenceRow(
            icon: Icons.favorite_outline,
            label: 'Motivation',
            value: user?.motivationDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          _PreferenceRow(
            icon: Icons.calendar_today_outlined,
            label: 'Workout Days',
            value: user?.workoutDaysFormatted ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

/// A single row in the preferences card.
class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _PreferenceRow({
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
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
