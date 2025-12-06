import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class PersonalInfoStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const PersonalInfoStep({
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
            "Let's get to know you",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us personalize your experience',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Name Field
          _buildLabel('Your Name', isRequired: true),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: TextEditingController(text: data.name)
                ..selection = TextSelection.collapsed(offset: data.name?.length ?? 0),
              onChanged: (value) {
                data.name = value.isEmpty ? null : value;
                onDataChanged();
              },
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Gender Selection
          _buildLabel('Gender', isRequired: true),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Male',
                value: 'male',
                icon: Icons.male,
              ),
              SelectionOption(
                label: 'Female',
                value: 'female',
                icon: Icons.female,
              ),
            ],
            selectedValue: data.gender,
            onChanged: (value) {
              data.gender = value;
              onDataChanged();
            },
            crossAxisCount: 2,
          ),
          const SizedBox(height: 24),

          // Age Field
          _buildLabel('Age'),
          const SizedBox(height: 8),
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: TextEditingController(text: data.age?.toString() ?? '')
                ..selection = TextSelection.collapsed(offset: data.age?.toString().length ?? 0),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                data.age = int.tryParse(value);
                onDataChanged();
              },
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Years',
                hintStyle: TextStyle(color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
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
