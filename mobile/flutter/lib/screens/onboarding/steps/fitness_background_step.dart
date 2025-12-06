import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class FitnessBackgroundStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const FitnessBackgroundStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Your Fitness Journey',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help us understand where you are and where you want to go',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Fitness Level
          _buildLabel('Fitness Level', isRequired: true),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Beginner',
                value: 'beginner',
                description: 'New to exercise or returning after a long break',
                icon: Icons.eco,
              ),
              SelectionOption(
                label: 'Intermediate',
                value: 'intermediate',
                description: 'Regular exercise for 6+ months',
                icon: Icons.fitness_center,
              ),
              SelectionOption(
                label: 'Advanced',
                value: 'advanced',
                description: 'Consistent training for 2+ years',
                icon: Icons.whatshot,
              ),
            ],
            selectedValue: data.fitnessLevel,
            onChanged: (value) {
              data.fitnessLevel = value;
              onDataChanged();
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 32),

          // Goals
          _buildLabel('Your Goals', isRequired: true),
          const Text(
            'Select all that apply',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MultiSelectGroup(
            options: GoalOptions.all
                .map((g) => SelectionOption(
                      label: g['label']!,
                      value: g['value']!,
                    ))
                .toList(),
            selectedValues: data.goals,
            onChanged: (values) {
              data.goals = values;
              onDataChanged();
            },
            crossAxisCount: 2,
          ),
          const SizedBox(height: 32),

          // Previous Experience
          _buildLabel('Previous Experience'),
          const Text(
            'Select all that you have tried',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MultiSelectGroup(
            options: ExperienceOptions.all
                .map((e) => SelectionOption(
                      label: e['label']!,
                      value: e['value']!,
                    ))
                .toList(),
            selectedValues: data.previousExperience,
            onChanged: (values) {
              data.previousExperience = values;
              onDataChanged();
            },
            exclusiveValue: 'none',
            crossAxisCount: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
