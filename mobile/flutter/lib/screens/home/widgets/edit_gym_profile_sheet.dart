import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_slot_utils.dart';
import '../../../data/models/gym_location.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/sheet_header.dart';
import '../../gym_profile/gym_location_picker_screen.dart';
import 'gym_equipment_sheet.dart';

/// Bottom sheet for editing an existing gym profile
class EditGymProfileSheet extends ConsumerStatefulWidget {
  final GymProfile profile;

  /// Optional callback for back button - if null, no back button shown
  final VoidCallback? onBack;

  const EditGymProfileSheet({
    super.key,
    required this.profile,
    this.onBack,
  });

  @override
  ConsumerState<EditGymProfileSheet> createState() =>
      _EditGymProfileSheetState();
}

class _EditGymProfileSheetState extends ConsumerState<EditGymProfileSheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  late String _selectedEnvironment;
  late List<String> _selectedEquipment;
  late List<Map<String, dynamic>> _equipmentDetails;
  // Location state
  GymLocation? _selectedLocation;
  bool _autoSwitchEnabled = true;
  int _locationRadiusMeters = 100;
  // Time preference state
  String? _selectedTimeSlot;
  bool _timeAutoSwitchEnabled = true;
  // Training preferences state
  String? _selectedTrainingSplit;
  late List<int> _selectedWorkoutDays;
  late int _selectedDuration;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Training split options
  static const List<Map<String, dynamic>> _trainingSplitOptions = [
    {'id': 'nothing_structured', 'label': 'Let AI Decide', 'icon': Icons.auto_awesome_rounded, 'desc': 'Flexible'},
    {'id': 'push_pull_legs', 'label': 'Push/Pull/Legs', 'icon': Icons.splitscreen_rounded, 'desc': '6 days'},
    {'id': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new_rounded, 'desc': '3 days'},
    {'id': 'upper_lower', 'label': 'Upper/Lower', 'icon': Icons.swap_vert_rounded, 'desc': '4 days'},
    {'id': 'phul', 'label': 'PHUL', 'icon': Icons.flash_on_rounded, 'desc': '4 days'},
    {'id': 'body_part', 'label': 'Body Part', 'icon': Icons.view_week_rounded, 'desc': '5-6 days'},
  ];

  // Day names for workout days picker
  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Predefined environment presets
  static const Map<String, Map<String, dynamic>> _environmentPresets = {
    'commercial_gym': {
      'name': 'Commercial Gym',
      'icon': Icons.business_rounded,
    },
    'home_gym': {
      'name': 'Home Gym',
      'icon': Icons.home_work_rounded,
    },
    'home': {
      'name': 'Home (Minimal)',
      'icon': Icons.home_rounded,
    },
    'hotel': {
      'name': 'Hotel / Travel',
      'icon': Icons.hotel_rounded,
    },
    'outdoors': {
      'name': 'Outdoors',
      'icon': Icons.park_rounded,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedIcon = widget.profile.icon;
    _selectedColor = widget.profile.color;
    _selectedEnvironment = widget.profile.workoutEnvironment;
    _selectedEquipment = List.from(widget.profile.equipment);
    _equipmentDetails = List.from(widget.profile.equipmentDetails ?? []);
    // Initialize location from existing profile
    if (widget.profile.hasLocation) {
      _selectedLocation = GymLocation(
        placeId: widget.profile.placeId,
        name: widget.profile.name,
        address: widget.profile.address ?? '',
        city: widget.profile.city,
        latitude: widget.profile.latitude!,
        longitude: widget.profile.longitude!,
      );
    }
    _autoSwitchEnabled = widget.profile.autoSwitchEnabled;
    _locationRadiusMeters = widget.profile.locationRadiusMeters;
    // Initialize time preference from existing profile
    _selectedTimeSlot = widget.profile.preferredTimeSlot;
    _timeAutoSwitchEnabled = widget.profile.timeAutoSwitchEnabled;
    // Initialize training preferences from existing profile
    _selectedTrainingSplit = widget.profile.trainingSplit;
    _selectedWorkoutDays = List.from(widget.profile.workoutDays);
    _selectedDuration = widget.profile.durationMinutes;
  }

  void _openEquipmentSheet() {
    // Convert equipment details to EquipmentItem list
    final equipmentItems = _equipmentDetails
        .map((e) => EquipmentItem.fromJson(e))
        .toList();

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
          _markChanged();
          debugPrint('✅ [EditGymProfile] Equipment updated: ${equipment.length} items');
        },
      ),
    );
  }

  Future<void> _duplicateProfile() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(gymProfilesProvider.notifier).duplicateProfile(widget.profile.id);
      HapticService.success();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created copy of "${widget.profile.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final update = GymProfileUpdate(
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
        workoutEnvironment: _selectedEnvironment,
        equipment: _selectedEquipment,
        equipmentDetails: _equipmentDetails,
        // Location fields
        address: _selectedLocation?.address,
        city: _selectedLocation?.city,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        placeId: _selectedLocation?.placeId,
        locationRadiusMeters: _locationRadiusMeters,
        autoSwitchEnabled: _autoSwitchEnabled,
        // Time preference fields
        preferredTimeSlot: _selectedTimeSlot,
        timeAutoSwitchEnabled: _timeAutoSwitchEnabled,
        // Training preferences
        trainingSplit: _selectedTrainingSplit,
        workoutDays: _selectedWorkoutDays,
        durationMinutes: _selectedDuration,
      );

      await ref
          .read(gymProfilesProvider.notifier)
          .updateProfile(widget.profile.id, update);

      HapticService.success();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated "${_nameController.text}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
    final selectedColorObj = GymProfileColors.fromHex(_selectedColor);

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
              child: Column(
                children: [
                  Row(
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
                          color: selectedColorObj.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(_selectedIcon),
                          color: selectedColorObj,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nameController.text.isEmpty
                              ? widget.profile.name
                              : _nameController.text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildActionChip(
                          icon: Icons.home_rounded,
                          label: 'Edit Icon',
                          onTap: _showIconPicker,
                          isDark: isDark,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: Icons.edit_rounded,
                          label: 'Rename Gym',
                          onTap: _showRenameDialog,
                          isDark: isDark,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: Icons.copy_rounded,
                          label: 'Duplicate',
                          onTap: _duplicateProfile,
                          isDark: isDark,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => _markChanged(),
                      style: TextStyle(color: textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Enter gym name',
                        hintStyle:
                            TextStyle(color: textSecondary.withOpacity(0.5)),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: selectedColorObj, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Environment
                    Text(
                      'Environment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _environmentPresets.entries.map((entry) {
                        final isSelected = _selectedEnvironment == entry.key;
                        final preset = entry.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEnvironment = entry.key);
                            _markChanged();
                            HapticService.light();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColorObj.withOpacity(0.15)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColorObj
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  preset['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? selectedColorObj
                                      : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? selectedColorObj
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _iconOptions.map((iconOption) {
                        final isSelected = _selectedIcon == iconOption['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(
                                () => _selectedIcon = iconOption['id'] as String);
                            _markChanged();
                            HapticService.light();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColorObj.withOpacity(0.2)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColorObj
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              iconOption['icon'] as IconData,
                              color: isSelected ? selectedColorObj : textSecondary,
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Color selection
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: GymProfileColors.palette.map((colorHex) {
                        final isSelected = _selectedColor == colorHex;
                        final color = GymProfileColors.fromHex(colorHex);
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = colorHex);
                            _markChanged();
                            HapticService.light();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Equipment - tap to open advanced equipment sheet
                    Text(
                      'Equipment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openEquipmentSheet,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedColorObj.withOpacity(0.3),
                          ),
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
                                Icons.fitness_center_rounded,
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
                                    '${_selectedEquipment.length} Equipment Items',
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
                                      color: selectedColorObj,
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

                    // Training preferences section
                    Text(
                      'Training Preferences (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize workouts for this gym',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Training Split selector
                    _buildTrainingSplitSelector(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedColorObj: selectedColorObj,
                    ),

                    const SizedBox(height: 16),

                    // Workout Days picker
                    Text(
                      'Workout Days',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildWorkoutDaysPicker(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedColorObj: selectedColorObj,
                    ),

                    const SizedBox(height: 16),

                    // Duration selector
                    _buildDurationSelector(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedColorObj: selectedColorObj,
                    ),

                    const SizedBox(height: 24),

                    // Location section
                    Text(
                      'Location (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set a location to auto-switch profiles',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedLocation != null
                                ? selectedColorObj.withOpacity(0.5)
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedLocation != null
                                    ? selectedColorObj.withOpacity(0.15)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _selectedLocation != null
                                    ? Icons.place_rounded
                                    : Icons.add_location_alt_rounded,
                                color: _selectedLocation != null
                                    ? selectedColorObj
                                    : textSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedLocation != null
                                        ? _selectedLocation!.name
                                        : 'Add Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedLocation != null
                                        ? _selectedLocation!.shortAddress
                                        : 'Tap to set gym location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _selectedLocation != null
                                          ? selectedColorObj
                                          : textSecondary.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedLocation != null)
                              IconButton(
                                onPressed: _removeLocation,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                color: textSecondary,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Auto-switch toggle (only show if location is set)
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: selectedColorObj,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-switch when I arrive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Requires location permission',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _autoSwitchEnabled,
                              onChanged: (value) {
                                setState(() => _autoSwitchEnabled = value);
                                _markChanged();
                                HapticService.light();
                              },
                              activeColor: selectedColorObj,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Time preference section
                    Text(
                      'Workout Time (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When do you usually workout here?',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlotPicker(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      selectedColorObj: selectedColorObj,
                    ),

                    // Time auto-switch toggle (only show if time slot is set)
                    if (_selectedTimeSlot != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: selectedColorObj,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-switch at this time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Suggest this profile during ${TimeSlotUtils.fromValue(_selectedTimeSlot)?.label ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _timeAutoSwitchEnabled,
                              onChanged: (value) {
                                setState(() => _timeAutoSwitchEnabled = value);
                                _markChanged();
                                HapticService.light();
                              },
                              activeColor: selectedColorObj,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
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
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _hasChanges && !_isLoading
                          ? _saveChanges
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedColorObj,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: selectedColorObj.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconId) {
    final iconMap = {
      for (final option in _iconOptions) option['id'] as String: option['icon'] as IconData
    };
    return iconMap[iconId] ?? Icons.fitness_center_rounded;
  }

  void _showIconPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final selectedColorObj = GymProfileColors.fromHex(_selectedColor);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : Colors.white,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _iconOptions.map((iconOption) {
                final isSelected = _selectedIcon == iconOption['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = iconOption['id'] as String);
                    _markChanged();
                    HapticService.light();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
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
                      color: isSelected ? selectedColorObj : textPrimary,
                      size: 26,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final selectedColorObj = GymProfileColors.fromHex(_selectedColor);
    final tempController = TextEditingController(text: _nameController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Gym',
          style: TextStyle(color: textPrimary),
        ),
        content: TextField(
          controller: tempController,
          autofocus: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: textPrimary.withOpacity(0.5)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: selectedColorObj),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (tempController.text.isNotEmpty) {
                setState(() => _nameController.text = tempController.text);
                _markChanged();
                Navigator.pop(context);
              }
            },
            child: Text(
              'Rename',
              style: TextStyle(color: selectedColorObj),
            ),
          ),
        ],
      ),
    );
  }

  void _openLocationPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GymLocationPickerScreen(
          initialLocation: _selectedLocation,
          onLocationSelected: (location) {
            setState(() => _selectedLocation = location);
            _markChanged();
            debugPrint('✅ [EditGymProfile] Location selected: ${location.name}');
          },
        ),
      ),
    );
  }

  void _removeLocation() {
    setState(() => _selectedLocation = null);
    _markChanged();
    HapticService.light();
  }

  Widget _buildTimeSlotPicker({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Time slot options
        ...TimeSlot.values.map((slot) {
          final isSelected = _selectedTimeSlot == slot.value;
          return GestureDetector(
            onTap: () {
              setState(() {
                // Toggle off if already selected
                if (_selectedTimeSlot == slot.value) {
                  _selectedTimeSlot = null;
                } else {
                  _selectedTimeSlot = slot.value;
                }
              });
              _markChanged();
              HapticService.light();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColorObj.withOpacity(0.15)
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? selectedColorObj
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    slot.icon,
                    size: 24,
                    color: isSelected
                        ? selectedColorObj
                        : textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.shortLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? selectedColorObj
                          : textPrimary,
                    ),
                  ),
                  Text(
                    slot.timeRange,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? selectedColorObj.withOpacity(0.8)
                          : textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Clear option (only show if a time is selected)
        if (_selectedTimeSlot != null)
          GestureDetector(
            onTap: () {
              setState(() => _selectedTimeSlot = null);
              _markChanged();
              HapticService.light();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.clear_rounded,
                    size: 24,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    'No pref',
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrainingSplitSelector({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _trainingSplitOptions.map((split) {
        final isSelected = _selectedTrainingSplit == split['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              // Toggle off if already selected
              if (_selectedTrainingSplit == split['id']) {
                _selectedTrainingSplit = null;
              } else {
                _selectedTrainingSplit = split['id'] as String;
              }
            });
            _markChanged();
            HapticService.light();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColorObj.withOpacity(0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? selectedColorObj : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  split['icon'] as IconData,
                  size: 18,
                  color: isSelected ? selectedColorObj : textSecondary,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      split['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? selectedColorObj : textPrimary,
                      ),
                    ),
                    Text(
                      split['desc'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? selectedColorObj.withOpacity(0.8)
                            : textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutDaysPicker({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = _selectedWorkoutDays.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWorkoutDays.remove(index);
              } else {
                _selectedWorkoutDays.add(index);
                _selectedWorkoutDays.sort();
              }
            });
            _markChanged();
            HapticService.light();
          },
          child: Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColorObj.withOpacity(0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? selectedColorObj : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _dayNames[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? selectedColorObj : textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selectedColorObj,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDurationSelector({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: selectedColorObj,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Duration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '$_selectedDuration minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedColorObj,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDurationButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_selectedDuration > 15) {
                    setState(() => _selectedDuration -= 15);
                    _markChanged();
                    HapticService.light();
                  }
                },
                isEnabled: _selectedDuration > 15,
                isDark: isDark,
                textSecondary: textSecondary,
                selectedColorObj: selectedColorObj,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_selectedDuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              _buildDurationButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_selectedDuration < 180) {
                    setState(() => _selectedDuration += 15);
                    _markChanged();
                    HapticService.light();
                  }
                },
                isEnabled: _selectedDuration < 180,
                isDark: isDark,
                textSecondary: textSecondary,
                selectedColorObj: selectedColorObj,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required bool isDark,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? selectedColorObj.withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isEnabled ? selectedColorObj : textSecondary.withOpacity(0.3),
          size: 20,
        ),
      ),
    );
  }
}
