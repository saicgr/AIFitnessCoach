import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/sheet_header.dart';
import 'gym_equipment_sheet.dart';

/// Bottom sheet for adding a new gym profile
///
/// Provides two options:
/// 1. Quick Setup - 5 steps with environment presets
/// 2. Full Setup - Complete onboarding flow (future)
class AddGymProfileSheet extends ConsumerStatefulWidget {
  /// Optional callback for back button - if null, no back button shown
  final VoidCallback? onBack;

  const AddGymProfileSheet({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<AddGymProfileSheet> createState() => _AddGymProfileSheetState();
}

class _AddGymProfileSheetState extends ConsumerState<AddGymProfileSheet> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form values
  String _name = '';
  String _selectedIcon = 'fitness_center';
  String _selectedColor = GymProfileColors.palette[0];
  String _selectedEnvironment = 'commercial_gym';
  List<String> _selectedEquipment = [];
  List<Map<String, dynamic>> _equipmentDetails = []; // Equipment with weights

  // Predefined environment presets
  static const Map<String, Map<String, dynamic>> _environmentPresets = {
    'commercial_gym': {
      'name': 'Commercial Gym',
      'icon': Icons.business_rounded,
      'description': 'Full access to all machines and equipment',
      'defaultIcon': 'fitness_center',
      'defaultEquipment': [
        'barbell',
        'dumbbells',
        'cable_machine',
        'machines',
        'bench',
        'squat_rack',
        'pull_up_bar',
        'leg_press',
      ],
    },
    'home_gym': {
      'name': 'Home Gym',
      'icon': Icons.home_work_rounded,
      'description': 'Dedicated workout space with your equipment',
      'defaultIcon': 'home',
      'defaultEquipment': [
        'dumbbells',
        'barbell',
        'bench',
        'pull_up_bar',
        'resistance_bands',
      ],
    },
    'home': {
      'name': 'Home (Minimal)',
      'icon': Icons.home_rounded,
      'description': 'Bodyweight and basic equipment only',
      'defaultIcon': 'home',
      'defaultEquipment': [
        'bodyweight',
        'resistance_bands',
      ],
    },
    'hotel': {
      'name': 'Hotel / Travel',
      'icon': Icons.hotel_rounded,
      'description': 'Limited space and equipment while traveling',
      'defaultIcon': 'hotel',
      'defaultEquipment': [
        'bodyweight',
        'resistance_bands',
      ],
    },
    'outdoors': {
      'name': 'Outdoors',
      'icon': Icons.park_rounded,
      'description': 'Parks, outdoor gyms, and open spaces',
      'defaultIcon': 'park',
      'defaultEquipment': [
        'bodyweight',
        'pull_up_bar',
      ],
    },
  };

  // Available icons
  static const List<Map<String, dynamic>> _iconOptions = [
    {'id': 'fitness_center', 'icon': Icons.fitness_center_rounded},
    {'id': 'home', 'icon': Icons.home_rounded},
    {'id': 'business', 'icon': Icons.business_rounded},
    {'id': 'hotel', 'icon': Icons.hotel_rounded},
    {'id': 'park', 'icon': Icons.park_rounded},
    {'id': 'sports_gymnastics', 'icon': Icons.sports_gymnastics_rounded},
    {'id': 'self_improvement', 'icon': Icons.self_improvement_rounded},
    {'id': 'directions_run', 'icon': Icons.directions_run_rounded},
  ];

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      HapticService.light();
    } else {
      _createProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      HapticService.light();
    }
  }

  void _selectEnvironment(String environment) {
    setState(() {
      _selectedEnvironment = environment;
      final preset = _environmentPresets[environment]!;
      _selectedIcon = preset['defaultIcon'] as String;
      _selectedEquipment = List<String>.from(preset['defaultEquipment'] as List);
      // Reset equipment details when changing environment
      _equipmentDetails = [];
    });
    HapticService.medium();
  }

  void _openEquipmentSheet() {
    // Convert equipment details to EquipmentItem list
    final equipmentItems = _equipmentDetails.map((e) => EquipmentItem.fromJson(e)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GymEquipmentSheet(
        selectedEquipment: _selectedEquipment,
        equipmentDetails: equipmentItems,
        title: 'Equipment',
        onSave: (equipment, details) {
          setState(() {
            _selectedEquipment = equipment;
            _equipmentDetails = details;
          });
          debugPrint('✅ [AddGymProfile] Equipment updated: ${equipment.length} items');
        },
      ),
    );
  }

  Future<void> _createProfile() async {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a name for your gym'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = GymProfileCreate(
        name: _name,
        icon: _selectedIcon,
        color: _selectedColor,
        workoutEnvironment: _selectedEnvironment,
        equipment: _selectedEquipment,
        equipmentDetails: _equipmentDetails,
      );

      await ref.read(gymProfilesProvider.notifier).createProfile(profile);

      HapticService.success();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Created "$_name" gym profile'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  // Back button (if provided)
                  if (widget.onBack != null) ...[
                    SheetBackButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.onBack?.call();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Gym',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of 3',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (index) {
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? accentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStepContent(isDark, textPrimary, textSecondary, accentColor),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: Text(
                          'Back',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 2 ? 'Create Gym' : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    switch (_currentStep) {
      case 0:
        return _buildNameAndEnvironmentStep(isDark, textPrimary, textSecondary, accentColor);
      case 1:
        return _buildEquipmentStep(isDark, textPrimary, textSecondary, accentColor);
      case 2:
        return _buildStyleStep(isDark, textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameAndEnvironmentStep(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name Your Gym',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Give this gym setup a memorable name',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          autofocus: true,
          onChanged: (value) => setState(() => _name = value),
          style: TextStyle(color: textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g., Home Gym, Planet Fitness, Hotel',
            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            prefixIcon: Icon(Icons.edit_rounded, color: textSecondary),
          ),
        ),
        const SizedBox(height: 28),

        // Environment section
        Text(
          'Workout Environment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us suggest the right equipment',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ..._environmentPresets.entries.map((entry) {
          final isSelected = _selectedEnvironment == entry.key;
          final preset = entry.value;
          return GestureDetector(
            onTap: () => _selectEnvironment(entry.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accentColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      preset['icon'] as IconData,
                      color: isSelected ? accentColor : textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? accentColor : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }


  Widget _buildEquipmentStep(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    // Format equipment name for display
    String formatName(String name) {
      return name
          .split('_')
          .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
          .join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Equipment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize the equipment available at this gym, including weight ranges',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Edit Equipment button
        GestureDetector(
          onTap: _openEquipmentSheet,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedEquipment.length} Equipment Selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add, remove, or edit weights',
                        style: TextStyle(
                          fontSize: 13,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Show selected equipment list with weight details
        if (_selectedEquipment.isNotEmpty) ...[
          Text(
            'Selected Equipment (${_selectedEquipment.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Show equipment as list items with weight info
          ..._selectedEquipment.map((equipment) {
            // Find weight info if available
            final details = _equipmentDetails.cast<Map<String, dynamic>?>().firstWhere(
              (e) => e?['name'] == equipment,
              orElse: () => null,
            );
            final weights = details?['weights'] as List?;
            final weightUnit = details?['weight_unit'] as String? ?? 'kg';
            final hasWeights = weights != null && weights.isNotEmpty;

            // Count occurrences of each weight and format display
            String weightDisplay = '';
            int totalCount = 0;
            if (hasWeights) {
              // Count occurrences of each weight
              final weightCounts = <num, int>{};
              for (final w in weights) {
                final weight = w as num;
                weightCounts[weight] = (weightCounts[weight] ?? 0) + 1;
              }
              totalCount = weights.length;

              // Sort weights and format with counts
              final sortedWeights = weightCounts.keys.toList()..sort();
              final weightStrings = sortedWeights.map((w) {
                final count = weightCounts[w]!;
                final weightStr = w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
                if (count > 1) {
                  return '$weightStr $weightUnit ×$count';
                }
                return '$weightStr $weightUnit';
              }).toList();
              weightDisplay = weightStrings.join(', ');
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              formatName(equipment),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            if (hasWeights) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$totalCount items',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasWeights) ...[
                          const SizedBox(height: 4),
                          Text(
                            weightDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasWeights)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.scale_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStyleStep(bool isDark, Color textPrimary, Color textSecondary) {
    final selectedColorObj = GymProfileColors.fromHex(_selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose an icon and color for your gym',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Icon selection
        Text(
          'Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _iconOptions.map((iconOption) {
            final isSelected = _selectedIcon == iconOption['id'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedIcon = iconOption['id'] as String);
                HapticService.light();
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColorObj.withOpacity(0.2)
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? selectedColorObj : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  iconOption['icon'] as IconData,
                  color: isSelected ? selectedColorObj : textSecondary,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Color selection
        Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: GymProfileColors.palette.map((colorHex) {
            final isSelected = _selectedColor == colorHex;
            final color = GymProfileColors.fromHex(colorHex);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = colorHex);
                HapticService.light();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Preview
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedColorObj,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: selectedColorObj.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selectedColorObj.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconOptions.firstWhere(
                    (o) => o['id'] == _selectedIcon,
                    orElse: () => _iconOptions.first,
                  )['icon'] as IconData,
                  color: selectedColorObj,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.isEmpty ? 'Gym Name' : _name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selectedColorObj,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedEquipment.length} equipment • ${_environmentPresets[_selectedEnvironment]!['name']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: selectedColorObj,
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
