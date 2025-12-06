import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class PreferencesStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const PreferencesStep({
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
            'Training Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customize how you want to train',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Training Split
          _buildLabel('Training Split', isRequired: true),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Full Body',
                value: 'full_body',
                description: 'Train all muscle groups each session',
                icon: Icons.accessibility_new,
              ),
              SelectionOption(
                label: 'Upper/Lower',
                value: 'upper_lower',
                description: 'Alternate between upper and lower body',
                icon: Icons.swap_vert,
              ),
              SelectionOption(
                label: 'Push/Pull/Legs',
                value: 'push_pull_legs',
                description: 'Classic 3-day split for muscle building',
                icon: Icons.splitscreen,
              ),
              SelectionOption(
                label: 'Body Part',
                value: 'body_part',
                description: 'Focus on one muscle group per session',
                icon: Icons.filter_frames,
              ),
            ],
            selectedValue: data.trainingSplit,
            onChanged: (value) {
              data.trainingSplit = value;
              onDataChanged();
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 32),

          // Intensity Level
          _buildLabel('Intensity Level'),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Light',
                value: 'light',
                description: 'Lower intensity, good for beginners',
                icon: Icons.brightness_low,
              ),
              SelectionOption(
                label: 'Moderate',
                value: 'moderate',
                description: 'Balanced effort and recovery',
                icon: Icons.brightness_medium,
              ),
              SelectionOption(
                label: 'Intense',
                value: 'intense',
                description: 'High intensity for maximum gains',
                icon: Icons.brightness_high,
              ),
            ],
            selectedValue: data.intensityLevel,
            onChanged: (value) {
              data.intensityLevel = value;
              onDataChanged();
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 32),

          // Equipment
          _buildLabel('Equipment Available', isRequired: true),
          const Text(
            'Select all equipment you have access to',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MultiSelectGroup(
            options: EquipmentOptions.all
                .map((e) => SelectionOption(
                      label: e['label']!,
                      value: e['value']!,
                    ))
                .toList(),
            selectedValues: data.equipment,
            onChanged: (values) {
              data.equipment = values;
              onDataChanged();
            },
            crossAxisCount: 2,
          ),
          const SizedBox(height: 32),

          // Workout Variety
          _buildLabel('Workout Variety'),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Consistent',
                value: 'consistent',
                description: 'Same exercises to track progress',
                icon: Icons.repeat,
              ),
              SelectionOption(
                label: 'Varied',
                value: 'varied',
                description: 'Different exercises for variety',
                icon: Icons.shuffle,
              ),
            ],
            selectedValue: data.workoutVariety,
            onChanged: (value) {
              data.workoutVariety = value;
              onDataChanged();
            },
            showDescriptions: true,
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
