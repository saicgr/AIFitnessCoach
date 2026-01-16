import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class ScheduleStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const ScheduleStep({
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
            'Your Schedule',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When would you like to work out?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Workout Days
          _buildLabel('Workout Days', isRequired: true),
          const SizedBox(height: 4),
          Text(
            '${data.workoutDays.length} days selected',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          DaySelector(
            selectedDays: data.workoutDays,
            onChanged: (days) {
              data.workoutDays = days;
              onDataChanged();
            },
          ),
          const SizedBox(height: 32),

          // Preferred Time
          _buildLabel('Preferred Time', isRequired: true),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Morning',
                value: 'morning',
                description: '6 AM - 12 PM',
                icon: Icons.wb_sunny,
              ),
              SelectionOption(
                label: 'Afternoon',
                value: 'afternoon',
                description: '12 PM - 5 PM',
                icon: Icons.wb_twilight,
              ),
              SelectionOption(
                label: 'Evening',
                value: 'evening',
                description: '5 PM - 10 PM',
                icon: Icons.nightlight_round,
              ),
            ],
            selectedValue: data.preferredTime,
            onChanged: (value) {
              data.preferredTime = value;
              onDataChanged();
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 32),

          // Workout Duration
          _buildLabel('Workout Duration'),
          const SizedBox(height: 12),
          _DurationSelector(
            value: data.workoutDuration,
            onChanged: (value) {
              data.workoutDuration = value;
              onDataChanged();
            },
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

class _DurationSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.value,
    required this.onChanged,
  });

  static const _durations = [30, 45, 60, 75, 90];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _durations.map((duration) {
        final isSelected = value == duration;
        return GestureDetector(
          onTap: () => onChanged(duration),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withOpacity(0.15)
                  : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              '$duration min',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
