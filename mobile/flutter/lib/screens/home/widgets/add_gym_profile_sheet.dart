import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';
import 'gym_equipment_sheet.dart';
import 'import_equipment_sheet.dart';

part 'add_gym_profile_sheet_part_equipment_follow_up.dart';

part 'add_gym_profile_sheet_ui.dart';

part 'add_gym_profile_sheet_ext.dart';


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
  bool _usingCustomColor = false;
  bool _usingAppTheme = false;
  bool _showCustomPicker = false;
  String _selectedEnvironment = 'commercial_gym';
  List<String> _selectedEquipment = List<String>.from(
    _environmentPresets['commercial_gym']!['defaultEquipment'] as List,
  );
  List<Map<String, dynamic>> _equipmentDetails = []; // Equipment with weights

  // Schedule (step 3): which weekdays this profile trains and which split.
  // Mon=0..Sun=6 to match backend storage and existing day pickers.
  List<int> _selectedWorkoutDays = [];
  String? _selectedTrainingSplit; // null = let AI decide

  // Day-of-week labels in Mon=0..Sun=6 order to match the backend index.
  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Training split options — must match backend `gym_profiles.training_split`
  // enum and the EditGymProfileSheet picker so editing later doesn't churn.
  static const List<Map<String, dynamic>> _trainingSplitOptions = [
    {'id': 'nothing_structured', 'label': 'Let AI Decide', 'icon': Icons.auto_awesome_rounded, 'desc': 'Flexible'},
    {'id': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new_rounded, 'desc': '3 days'},
    {'id': 'upper_lower', 'label': 'Upper/Lower', 'icon': Icons.swap_vert_rounded, 'desc': '4 days'},
    {'id': 'push_pull_legs', 'label': 'Push/Pull/Legs', 'icon': Icons.splitscreen_rounded, 'desc': '6 days'},
    {'id': 'phul', 'label': 'PHUL', 'icon': Icons.flash_on_rounded, 'desc': '4 days'},
    {'id': 'body_part', 'label': 'Body Part', 'icon': Icons.view_week_rounded, 'desc': '5-6 days'},
  ];

  // Track follow-up dialogs already shown this session
  final _shownFollowUps = <String>{};

  // Follow-up suggestions: selecting a primary equipment suggests a secondary
  static const _equipmentFollowUps = {
    'dumbbells': _EquipmentFollowUp(
      suggest: 'bench',
      title: 'Do you have a weight bench?',
      subtitle: 'Unlocks: Bench Press, Incline Press, Pullover, Chest-Supported Rows',
    ),
    'kettlebell': _EquipmentFollowUp(
      suggest: 'bench',
      title: 'Do you have a weight bench?',
      subtitle: 'Unlocks: Chest-Supported KB Row, KB Floor Press alternatives',
    ),
    'barbell': _EquipmentFollowUp(
      suggest: 'squat_rack',
      title: 'Do you have a squat rack?',
      subtitle: 'Required for: Barbell Squat, Overhead Press, Barbell Bench Press',
    ),
  };

  // Per-preset tint so each environment row has its own accent instead of
  // every icon rendering grey. Mapped from the preset key.
  Color _presetTint(String key) {
    switch (key) {
      case 'commercial_gym':
        return const Color(0xFFB366FF); // violet — matches existing accent
      case 'home_gym':
        return const Color(0xFF22C55E); // green
      case 'home':
        return const Color(0xFF0EA5E9); // sky blue
      case 'hotel':
        return const Color(0xFFF59E0B); // amber
      case 'outdoors':
        return const Color(0xFF10B981); // emerald
      default:
        return const Color(0xFF64748B); // slate fallback
    }
  }

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
      'description': 'Bodyweight exercises only',
      'defaultIcon': 'home',
      'defaultEquipment': [
        'bodyweight',
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
    {'id': 'sports_mma', 'icon': Icons.sports_mma_rounded},
    {'id': 'pool', 'icon': Icons.pool_rounded},
    {'id': 'directions_bike', 'icon': Icons.directions_bike_rounded},
    {'id': 'hiking', 'icon': Icons.hiking_rounded},
    {'id': 'local_fire_department', 'icon': Icons.local_fire_department_rounded},
    {'id': 'emoji_events', 'icon': Icons.emoji_events_rounded},
    {'id': 'monitor_heart', 'icon': Icons.monitor_heart_rounded},
    {'id': 'apartment', 'icon': Icons.apartment_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate _shownFollowUps for follow-ups already satisfied by initial equipment
    _initShownFollowUps();
    // Pre-select app theme color as default + seed schedule from current profile
    // (or user's account-level workout_days as fallback). This is just a sane
    // default — the user can flip to "Custom" or another preset on step 3.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gymColor = ref.read(gymAccentColorProvider);
      final accentColor = gymColor ?? ref.read(accentColorProvider).getColor(true);
      final hex = '#${accentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      final activeProfile = ref.read(activeGymProfileProvider);
      List<int> seedDays = activeProfile?.workoutDays ?? [];
      String? seedSplit = activeProfile?.trainingSplit;
      if (seedDays.isEmpty) {
        // Fall back to account-level workout_days (User model)
        final user = ref.read(currentUserProvider).valueOrNull;
        seedDays = user?.workoutDays ?? [];
      }
      setState(() {
        _selectedColor = hex;
        _usingAppTheme = true;
        _usingCustomColor = false;
        _selectedWorkoutDays = List<int>.from(seedDays);
        _selectedTrainingSplit = seedSplit;
      });
    });
  }

  void _initShownFollowUps() {
    for (final entry in _equipmentFollowUps.entries) {
      if (_selectedEquipment.contains(entry.value.suggest)) {
        _shownFollowUps.add(entry.key);
      }
    }
  }

  void _nextStep() {
    // Validate the Schedule step (index 2): require at least one workout day
    // before letting the user advance to the Style step. Without this guard,
    // the new profile would be persisted with workout_days=[] which disables
    // both day-dot indicators and the 14-day pre-generation.
    if (_currentStep == 2 && _selectedWorkoutDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one workout day for this gym.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticService.light();
      return;
    }
    if (_currentStep < 3) {
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
      // Re-init follow-ups based on new equipment
      _shownFollowUps.clear();
      _initShownFollowUps();
    });
    HapticService.medium();
  }

  /// Open the AI import flow from inside the Add flow.
  ///
  /// Edge case: during the initial Add flow the profile doesn't exist yet
  /// so we don't have an id to attach results to. We create the profile
  /// now (with whatever the user has entered so far) and push the import
  /// sheet against the newly created id. After save, the user is returned
  /// to the equipment step with the imported gear already applied.
  Future<void> _openImportSheet() async {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name for your gym first (step 1).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isLoading = true);

    String? newProfileId;
    try {
      final created = await ref
          .read(gymProfilesProvider.notifier)
          .createProfile(GymProfileCreate(
            name: _name,
            icon: _selectedIcon,
            color: _selectedColor,
            workoutEnvironment: _selectedEnvironment,
            equipment: _selectedEquipment,
            equipmentDetails: _equipmentDetails,
          ));
      newProfileId = created?.id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save profile before import: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted || newProfileId == null) return;

    // Close the Add sheet first so the import + result sheets can pop
    // cleanly back to the Home screen with the provider already updated.
    Navigator.of(context).pop();

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: ImportEquipmentSheet(
          gymProfileId: newProfileId!,
          existingEquipment: _selectedEquipment,
          existingEquipmentDetails: _equipmentDetails,
          currentEnvironment: _selectedEnvironment,
        ),
      ),
    );
  }

  void _openEquipmentSheet() {
    // Convert equipment details to EquipmentItem list
    final equipmentItems = _equipmentDetails.map((e) => EquipmentItem.fromJson(e)).toList();
    final previousEquipment = Set<String>.from(_selectedEquipment);

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: GymEquipmentSheet(
          selectedEquipment: _selectedEquipment,
          equipmentDetails: equipmentItems,
          title: 'Equipment',
          onSave: (equipment, details) {
            setState(() {
              _selectedEquipment = equipment;
              _equipmentDetails = details;
            });
            debugPrint('\u2705 [AddGymProfile] Equipment updated: ${equipment.length} items');
            // Check follow-ups for newly added equipment
            _checkEquipmentFollowUps(previousEquipment, equipment);
          },
        ),
      ),
    );
  }

  void _checkEquipmentFollowUps(Set<String> previous, List<String> current) {
    final currentSet = current.toSet();
    for (final entry in _equipmentFollowUps.entries) {
      final itemId = entry.key;
      final followUp = entry.value;
      // Only trigger if newly added
      if (!previous.contains(itemId) && currentSet.contains(itemId)) {
        if (currentSet.contains(followUp.suggest)) continue;
        if (_shownFollowUps.contains(itemId)) continue;
        _shownFollowUps.add(itemId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFollowUpDialog(followUp);
        });
        break; // Show one at a time
      }
    }
  }

  void _showFollowUpDialog(_EquipmentFollowUp followUp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          followUp.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textPrimary,
          ),
        ),
        content: Text(
          followUp.subtitle,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Skip',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (!_selectedEquipment.contains(followUp.suggest)) {
                  _selectedEquipment.add(followUp.suggest);
                }
              });
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Add It'),
          ),
        ],
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
        workoutDays: List<int>.from(_selectedWorkoutDays),
        trainingSplit: _selectedTrainingSplit,
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

    return GlassSheet(
      showHandle: false,
      child: DraggableScrollableSheet(
        // Step 1 (environment picker) has ~5 rows of content — an 85% sheet
        // leaves a big gap above the Next button. Start shorter; users can
        // drag up to 95% when step 2/3 has more content.
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            GlassSheetHandle(isDark: isDark),

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
                          'Step ${_currentStep + 1} of 4',
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
                children: List.generate(4, (index) {
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
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
                              _currentStep == 3 ? 'Create Gym' : 'Next',
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

  Widget _buildNameAndEnvironmentStep(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field - compact
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
        const SizedBox(height: 20),

        // Environment section
        Text(
          'Workout Environment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This helps us suggest the right equipment',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._environmentPresets.entries.map((entry) {
          final isSelected = _selectedEnvironment == entry.key;
          final preset = entry.value;
          return GestureDetector(
            onTap: () => _selectEnvironment(entry.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accentColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      // Per-preset tint so unselected rows aren't all grey.
                      color: _presetTint(entry.key).withValues(
                        alpha: isSelected ? 0.22 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      preset['icon'] as IconData,
                      color: _presetTint(entry.key),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + description stack vertically so a long name
                  // like "Commercial Gym" or "Hotel / Travel" stays on one
                  // line regardless of description length.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FittedBox.scaleDown keeps the name on one line on
                        // every screen size — shrinks if the row is narrow,
                        // never grows past the base 14 sp.
                        SizedBox(
                          height: 18,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                preset['name'] as String,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? accentColor : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset['description'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
