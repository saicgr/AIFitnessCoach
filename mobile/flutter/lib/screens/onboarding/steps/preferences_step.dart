import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/selection_chip.dart';

class PreferencesStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const PreferencesStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<PreferencesStep> {
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
            selectedValue: widget.data.trainingSplit,
            onChanged: (value) {
              widget.data.trainingSplit = value;
              widget.onDataChanged();
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
            selectedValue: widget.data.intensityLevel,
            onChanged: (value) {
              widget.data.intensityLevel = value;
              widget.onDataChanged();
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
          _buildEquipmentSection(),
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
            selectedValue: widget.data.workoutVariety,
            onChanged: (value) {
              widget.data.workoutVariety = value;
              widget.onDataChanged();
            },
            showDescriptions: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final equipmentOptions = EquipmentOptions.all;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: equipmentOptions.map((e) {
        final value = e['value']!;
        final label = e['label']!;
        final isSelected = widget.data.equipment.contains(value);
        final showQuantity = (value == 'dumbbells' || value == 'kettlebell') && isSelected;

        return _buildEquipmentChip(
          label: label,
          value: value,
          isSelected: isSelected,
          showQuantity: showQuantity,
          quantity: value == 'dumbbells' ? widget.data.dumbbellCount : widget.data.kettlebellCount,
          onQuantityChanged: (newQty) {
            setState(() {
              if (value == 'dumbbells') {
                widget.data.dumbbellCount = newQty;
              } else {
                widget.data.kettlebellCount = newQty;
              }
            });
            widget.onDataChanged();
          },
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentChip({
    required String label,
    required String value,
    required bool isSelected,
    required bool showQuantity,
    int quantity = 1,
    Function(int)? onQuantityChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _handleEquipmentTap(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: showQuantity ? 10 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.cyan : AppColors.textPrimary,
              ),
            ),
            if (showQuantity) ...[
              const SizedBox(width: 8),
              _buildQuantitySelector(quantity, onQuantityChanged!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(int currentValue, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentValue <= 1 ? null : () => onChanged(currentValue - 1),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.remove,
                size: 14,
                color: currentValue <= 1 ? AppColors.textMuted : AppColors.cyan,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentValue',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          ),
          GestureDetector(
            onTap: currentValue >= 2 ? null : () => onChanged(currentValue + 1),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.add,
                size: 14,
                color: currentValue >= 2 ? AppColors.textMuted : AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEquipmentTap(String value) {
    setState(() {
      List<String> newValues = List.from(widget.data.equipment);

      // Handle Full Gym auto-select
      if (value == 'full_gym') {
        if (newValues.contains('full_gym')) {
          newValues.remove('full_gym');
        } else {
          // Auto-select all gym equipment
          newValues = ['full_gym', 'dumbbells', 'barbell', 'kettlebell', 'resistance_bands', 'pull_up_bar', 'cable_machine'];
        }
      } else {
        if (newValues.contains(value)) {
          newValues.remove(value);
          // Remove full_gym if any item is deselected
          newValues.remove('full_gym');
        } else {
          newValues.add(value);
        }
      }

      widget.data.equipment = newValues;
    });
    widget.onDataChanged();
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
