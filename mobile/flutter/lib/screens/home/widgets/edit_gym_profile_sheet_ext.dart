part of 'edit_gym_profile_sheet.dart';

/// Methods extracted from _EditGymProfileSheetState
extension __EditGymProfileSheetStateExt on _EditGymProfileSheetState {

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
          title: AppLocalizations.of(context).trainingSetupCardEquipment,
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
    // Double-tap guard: a save is already in flight — ignore re-entry so we
    // never fire duplicate writes or stack timeouts.
    if (_isLoading) return;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).editGymProfilePleaseEnterAName)),
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
        // Per-day focus pins for the "Let AI Decide" split. Other splits
        // ignore this server-side, but we still send the value so the
        // user's pins survive a split change-back to AI Decide later
        // (see `apply_day_focus_overrides` in schedule_utils.py). Only
        // include when populated to keep the JSON payload tight.
        dayFocusOverride: _dayFocusOverride.isEmpty
            ? null
            : {
                for (final entry in _dayFocusOverride.entries)
                  if (entry.value != null) entry.key.toString(): entry.value!,
              },
      );

      // Timeout-cap every network await so a stalled request can never wedge
      // the spinner forever (issue 14). On timeout the TimeoutException
      // propagates to the catch below → "Failed to save" snackbar, and the
      // finally block re-enables the button while KEEPING the user's input
      // (we don't pop the sheet on error).
      const saveTimeout = Duration(seconds: 20);

      await ref
          .read(gymProfilesProvider.notifier)
          .updateProfile(widget.profile.id, update)
          .timeout(saveTimeout);

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
        ).timeout(saveTimeout);
        // Refresh user so UI reflects new experience/focus areas immediately
        await ref
            .read(authStateProvider.notifier)
            .refreshUser()
            .timeout(saveTimeout);
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
      for (final option in _EditGymProfileSheetState._iconOptions) option['id'] as String: option['icon'] as IconData
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
              AppLocalizations.of(context).habitsScreenUiChooseIcon,
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
              children: _EditGymProfileSheetState._iconOptions.map((iconOption) {
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
          AppLocalizations.of(context).editGymProfileRenameGym,
          style: TextStyle(color: textPrimary),
        ),
        content: TextField(
          controller: tempController,
          autofocus: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).editGymProfileEnterNewName,
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
              AppLocalizations.of(context).buttonCancel,
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
              AppLocalizations.of(context).editGymProfileRename,
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
    // Even 2-per-row grid (same treatment as the training-split selector):
    // each tile is exactly half the available width minus the column gap, so
    // the 5 time slots + optional Clear tile lay out cleanly with no overflow
    // on any device (feedback_no_overflow_adaptive_screens).
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            // Time slot options
            ...TimeSlot.values.map((slot) {
              final isSelected = _selectedTimeSlot == slot.value;
              return SizedBox(
                width: tileWidth,
                child: GestureDetector(
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
                        color: isSelected ? selectedColorObj : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          slot.icon,
                          size: 22,
                          color: isSelected ? selectedColorObj : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slot.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color:
                                      isSelected ? selectedColorObj : textPrimary,
                                ),
                              ),
                              Text(
                                slot.timeRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Clear option (only show if a time is selected)
            if (_selectedTimeSlot != null)
              SizedBox(
                width: tileWidth,
                child: GestureDetector(
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.clear_rounded,
                          size: 22,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context).vacationModeClear,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).editGymProfileNoPref,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Widget _buildTrainingSplitSelector({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    // Even 2-per-row grid. We size each tile to exactly half the available
    // width (minus the inter-column gap) inside a Wrap, so tiles stay uniform
    // and wrap cleanly from iPhone SE → iPad with NO overflow
    // (feedback_no_overflow_adaptive_screens). LayoutBuilder gives us the
    // real constraint width rather than guessing.
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _EditGymProfileSheetState._trainingSplitOptions.map((split) {
            final isSelected = _selectedTrainingSplit == split['id'];
            return SizedBox(
              width: tileWidth,
              child: GestureDetector(
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
                      color: isSelected ? selectedColorObj : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        split['icon'] as IconData,
                        size: 18,
                        color: isSelected ? selectedColorObj : textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              split['label'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? selectedColorObj : textPrimary,
                              ),
                            ),
                            Text(
                              split['desc'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
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
                  _EditGymProfileSheetState._dayNames[index],
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


  /// Per-day focus picker shown under Workout Days when the user chose
  /// "Let AI Decide". Renders one chip per SELECTED workout day; tapping
  /// opens a bottom sheet of focus options. Pinned days display the focus
  /// label (e.g. "Tue · Upper"); unpinned show "Auto".
  Widget _buildPerDayFocusPicker({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color selectedColorObj,
  }) {
    final sortedDays = [..._selectedWorkoutDays]..sort();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedDays.map((dayIdx) {
        final pinnedToken = _dayFocusOverride[dayIdx];
        final pinned = pinnedToken != null;
        final label = pinned
            ? _EditGymProfileSheetState._focusOptions
                .firstWhere(
                  (o) => o['id'] == pinnedToken,
                  orElse: () => {'id': pinnedToken, 'label': pinnedToken},
                )['label']!
            : 'Auto';
        return InkWell(
          onTap: () => _showFocusPicker(dayIdx),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pinned
                  ? selectedColorObj.withValues(alpha: 0.18)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: pinned
                    ? selectedColorObj.withValues(alpha: 0.6)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _EditGymProfileSheetState._dayNames[dayIdx],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pinned ? selectedColorObj : textPrimary,
                  ),
                ),
                Text(
                  '  ·  ',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pinned ? selectedColorObj : textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: pinned ? selectedColorObj : textSecondary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showFocusPicker(int dayIdx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final dayName = _EditGymProfileSheetState._dayNames[dayIdx];
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pin focus for $dayName',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _focusPickerOption(
                ctx,
                id: null,
                label: AppLocalizations.of(context).editGymProfileAutoAiDecides,
                isDark: isDark,
                dayIdx: dayIdx,
              ),
              ..._EditGymProfileSheetState._focusOptions.map(
                (opt) => _focusPickerOption(
                  ctx,
                  id: opt['id'],
                  label: opt['label']!,
                  isDark: isDark,
                  dayIdx: dayIdx,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusPickerOption(
    BuildContext sheetCtx, {
    required String? id,
    required String label,
    required bool isDark,
    required int dayIdx,
  }) {
    final selected = _dayFocusOverride[dayIdx] == id;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return InkWell(
      onTap: () {
        HapticService.light();
        setState(() {
          if (id == null) {
            _dayFocusOverride.remove(dayIdx);
          } else {
            _dayFocusOverride[dayIdx] = id;
          }
          _hasChanges = true;
        });
        Navigator.of(sheetCtx).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.orange : textPrimary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
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
                  AppLocalizations.of(context).editableFitnessCardWorkoutDuration,
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
                    color: textSecondary,
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
      children: _EditGymProfileSheetState._experienceOptions.map((opt) {
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
      children: _EditGymProfileSheetState._focusAreaOptions.map((opt) {
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
