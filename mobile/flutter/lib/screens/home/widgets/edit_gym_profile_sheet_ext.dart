part of 'edit_gym_profile_sheet.dart';

/// Methods extracted from _EditGymProfileSheetState
extension __EditGymProfileSheetStateExt on _EditGymProfileSheetState {
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
  // User-level training preferences
  String? _selectedExperience;
  List<String> _selectedFocusAreas = [];
  int _selectedVarietyPct = 50; // 25 = Low, 50 = Medium, 75 = High
  bool _isLoading = false;
  bool _hasChanges = false;

  // Training split options
  static const List<Map<String, dynamic>> _trainingSplitOptions = [
    {'id': 'nothing_structured', 'label': 'Let AI Decide', 'icon': Icons.auto_awesome_rounded, 'desc': 'Flexible'},


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


  void _openEquipmentSheet() {
    // Convert equipment details to EquipmentItem list
    final equipmentItems = _equipmentDetails
        .map((e) => EquipmentItem.fromJson(e))
        .toList();

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
            _markChanged();
            debugPrint('✅ [EditGymProfile] Equipment updated: ${equipment.length} items');
          },
        ),
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

      // Sync training split to user preferences so it's consistent across screens
      if (_selectedTrainingSplit != null) {
        ref.read(trainingPreferencesProvider.notifier)
           .setTrainingSplit(_selectedTrainingSplit!);
      }

      // Save user-level training preferences (experience, focus areas, variety)
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post(
          '${ApiConstants.users}/${user.id}/preferences',
          data: {
            if (_selectedExperience != null) 'training_experience': _selectedExperience,
            if (_selectedFocusAreas.isNotEmpty) 'focus_areas': _selectedFocusAreas,
          },
        );
        // Refresh user so UI reflects new experience/focus areas immediately
        await ref.read(authStateProvider.notifier).refreshUser();
      }
      // Save weekly variety
      ref.read(variationProvider.notifier).setVariation(_selectedVarietyPct);

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

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
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


  Widget _buildExperienceSelector({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _experienceOptions.map((opt) {
        final id = opt['id'] as String;
        final label = opt['label'] as String;
        final isSelected = _selectedExperience == id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedExperience = id);
            _markChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColorObj.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? selectedColorObj
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColorObj : textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildFocusAreasSelector({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _focusAreaOptions.map((opt) {
        final id = opt['id'] as String;
        final label = opt['label'] as String;
        final isSelected = _selectedFocusAreas.contains(id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (id == 'full_body') {
                // Full Body clears specific areas
                _selectedFocusAreas = isSelected ? [] : ['full_body'];
              } else {
                if (isSelected) {
                  _selectedFocusAreas.remove(id);
                } else {
                  _selectedFocusAreas
                    ..remove('full_body')
                    ..add(id);
                }
              }
            });
            _markChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColorObj.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? selectedColorObj
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColorObj : textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildVarietySelector({
    required bool isDark,
    required Color textPrimary,
    required Color selectedColorObj,
  }) {
    const options = [
      {'pct': 25, 'label': 'Low', 'sub': 'Same exercises weekly'},
      {'pct': 50, 'label': 'Medium', 'sub': 'Some rotation'},
      {'pct': 75, 'label': 'High', 'sub': 'Always fresh'},
    ];
    return Row(
      children: options.map((opt) {
        final pct = (opt['pct'] as num).toInt();
        final label = opt['label'] as String;
        final sub = opt['sub'] as String;
        final isSelected = _selectedVarietyPct == pct;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedVarietyPct = pct);
              _markChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: pct != 75 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColorObj.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? selectedColorObj
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? selectedColorObj : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? selectedColorObj.withValues(alpha: 0.8)
                          : (isDark
                              ? Colors.white38
                              : Colors.black38),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

}
