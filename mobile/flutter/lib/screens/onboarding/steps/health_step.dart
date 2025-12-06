import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class HealthStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const HealthStep({
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
            'Health & Limitations',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help us create safe workouts for you',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Injuries/Pain
          _buildLabel('Injuries or Pain Areas'),
          const Text(
            'Select any areas of concern',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MultiSelectGroup(
            options: InjuryOptions.all
                .map((i) => SelectionOption(
                      label: i['label']!,
                      value: i['value']!,
                    ))
                .toList(),
            selectedValues: data.injuries,
            onChanged: (values) {
              data.injuries = values;
              onDataChanged();
            },
            exclusiveValue: 'none',
            crossAxisCount: 2,
          ),
          const SizedBox(height: 32),

          // Health Conditions
          _buildLabel('Health Conditions'),
          const Text(
            'Select any that apply',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MultiSelectGroup(
            options: HealthConditionOptions.all
                .map((h) => SelectionOption(
                      label: h['label']!,
                      value: h['value']!,
                    ))
                .toList(),
            selectedValues: data.healthConditions,
            onChanged: (values) {
              data.healthConditions = values;
              onDataChanged();
            },
            exclusiveValue: 'none',
            crossAxisCount: 2,
          ),
          const SizedBox(height: 32),

          // Activity Level
          _buildLabel('Daily Activity Level', isRequired: true),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Sedentary',
                value: 'sedentary',
                description: 'Mostly sitting, minimal movement',
                icon: Icons.weekend,
              ),
              SelectionOption(
                label: 'Lightly Active',
                value: 'lightly_active',
                description: 'Light walking, some standing',
                icon: Icons.directions_walk,
              ),
              SelectionOption(
                label: 'Moderately Active',
                value: 'moderately_active',
                description: 'Regular walking, light physical work',
                icon: Icons.directions_run,
              ),
              SelectionOption(
                label: 'Very Active',
                value: 'very_active',
                description: 'Physically demanding job or lifestyle',
                icon: Icons.fitness_center,
              ),
            ],
            selectedValue: data.activityLevel,
            onChanged: (value) {
              data.activityLevel = value;
              onDataChanged();
            },
            showDescriptions: true,
          ),

          // Safety note
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Always consult a healthcare provider before starting any exercise program if you have health conditions or concerns.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
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
