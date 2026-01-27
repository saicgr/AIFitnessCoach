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
  late TextEditingController _gymNameController;

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController(text: widget.data.gymName ?? '');
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    super.dispose();
  }

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
          const SizedBox(height: 4),
          Text(
            'Choose how you want to structure your workouts',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              // === BEGINNER ===
              SelectionOption(
                label: 'Full Body',
                value: 'full_body',
                description: '3 days/week - Best for beginners',
                icon: Icons.accessibility_new,
              ),
              SelectionOption(
                label: 'Upper / Lower',
                value: 'upper_lower',
                description: '4 days/week - Great balance',
                icon: Icons.swap_vert,
              ),

              // === INTERMEDIATE ===
              SelectionOption(
                label: 'Push / Pull / Legs',
                value: 'push_pull_legs',
                description: '3-6 days/week - Most popular',
                icon: Icons.splitscreen,
              ),
              SelectionOption(
                label: 'PHUL',
                value: 'phul',
                description: '4 days/week - Strength + Size',
                icon: Icons.fitness_center,
              ),
              SelectionOption(
                label: 'PPLUL Hybrid',
                value: 'pplul',
                description: '5 days/week - Optimal for gains',
                icon: Icons.auto_graph,
              ),

              // === ADVANCED ===
              SelectionOption(
                label: 'Arnold Split',
                value: 'arnold_split',
                description: '6 days/week - Classic bodybuilding',
                icon: Icons.star,
              ),
              SelectionOption(
                label: 'Bro Split',
                value: 'body_part',
                description: '5 days/week - One muscle per day',
                icon: Icons.filter_frames,
              ),

              // === AI MODE ===
              SelectionOption(
                label: 'Let AI Decide',
                value: 'ai_adaptive',
                description: 'AI picks optimal split for you',
                icon: Icons.auto_awesome,
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

          // === NEW: Gym Location Context ===
          _buildLabel('Workout Location', isRequired: true),
          const Text(
            'Where do you primarily work out?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Home',
                value: 'home_gym',
                description: 'I work out at home',
                icon: Icons.home_rounded,
              ),
              SelectionOption(
                label: 'Gym',
                value: 'commercial_gym',
                description: 'I have a gym membership',
                icon: Icons.business_rounded,
              ),
              SelectionOption(
                label: 'Both',
                value: 'both',
                description: 'Home and gym',
                icon: Icons.compare_arrows_rounded,
              ),
              SelectionOption(
                label: 'Other',
                value: 'other',
                description: 'Hotel, outdoors, etc.',
                icon: Icons.more_horiz_rounded,
              ),
            ],
            selectedValue: widget.data.workoutEnvironment,
            onChanged: (value) {
              widget.data.workoutEnvironment = value;
              // Auto-populate gym name suggestion
              if (value == 'home_gym') {
                _gymNameController.text = 'Home Gym';
                widget.data.gymName = 'Home Gym';
              } else if (value == 'both') {
                _gymNameController.text = 'Home Gym';
                widget.data.gymName = 'Home Gym';
              } else {
                _gymNameController.text = '';
                widget.data.gymName = null;
              }
              widget.onDataChanged();
              setState(() {}); // Rebuild to show/hide suggestions
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 24),

          // Gym Name Input
          _buildLabel('Location Name'),
          const Text(
            'What would you like to call this workout location?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gymNameController,
            onChanged: (value) {
              widget.data.gymName = value;
              widget.onDataChanged();
            },
            decoration: InputDecoration(
              hintText: _getGymNameHint(),
              filled: true,
              fillColor: AppColors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),

          // Smart Suggestions
          if (widget.data.workoutEnvironment == 'commercial_gym') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '24 Hour Fitness',
                'Planet Fitness',
                'LA Fitness',
                'Gold\'s Gym',
                'Anytime Fitness',
              ].map((name) => _buildSuggestionChip(name)).toList(),
            ),
          ],
          const SizedBox(height: 32),

          // Equipment
          _buildLabel(
            widget.data.gymName != null && widget.data.gymName!.isNotEmpty
                ? 'Equipment at ${widget.data.gymName}'
                : 'Equipment Available',
            isRequired: true,
          ),
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
          const SizedBox(height: 32),

          // Workout Type Preference
          _buildLabel('Workout Type'),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Strength',
                value: 'strength',
                description: 'Focus on weight training and muscle building',
                icon: Icons.fitness_center,
              ),
              SelectionOption(
                label: 'Cardio',
                value: 'cardio',
                description: 'Focus on heart health and endurance',
                icon: Icons.directions_run,
              ),
              SelectionOption(
                label: 'Mixed',
                value: 'mixed',
                description: 'Combine strength training with cardio',
                icon: Icons.sports_gymnastics,
              ),
            ],
            selectedValue: widget.data.workoutTypePreference,
            onChanged: (value) {
              widget.data.workoutTypePreference = value;
              widget.onDataChanged();
            },
            showDescriptions: true,
          ),
          const SizedBox(height: 32),

          // Progression Pace
          _buildLabel('Progression Pace'),
          const Text(
            'How fast should weights increase?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SingleSelectGroup(
            options: const [
              SelectionOption(
                label: 'Slow',
                value: 'slow',
                description: 'Same weight for 3-4 weeks before increasing',
                icon: Icons.slow_motion_video,
              ),
              SelectionOption(
                label: 'Medium',
                value: 'medium',
                description: 'Increase weight every 1-2 weeks',
                icon: Icons.speed,
              ),
              SelectionOption(
                label: 'Fast',
                value: 'fast',
                description: 'Increase weight every session when ready',
                icon: Icons.flash_on,
              ),
            ],
            selectedValue: widget.data.progressionPace,
            onChanged: (value) {
              widget.data.progressionPace = value;
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
              ? AppColors.accent.withOpacity(0.15)
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
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
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
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
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
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
                color: currentValue <= 1 ? AppColors.textMuted : AppColors.accent,
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
                color: AppColors.accent,
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
                color: currentValue >= 2 ? AppColors.textMuted : AppColors.accent,
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

  String _getGymNameHint() {
    switch (widget.data.workoutEnvironment) {
      case 'home_gym':
        return 'Home Gym';
      case 'commercial_gym':
        return '24 Hour Fitness, Planet Fitness, etc.';
      case 'both':
        return 'Home Gym';
      case 'other':
        return 'Hotel Gym, Outdoor Gym, etc.';
      default:
        return 'My Gym';
    }
  }

  Widget _buildSuggestionChip(String name) {
    return InkWell(
      onTap: () {
        _gymNameController.text = name;
        widget.data.gymName = name;
        widget.onDataChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
