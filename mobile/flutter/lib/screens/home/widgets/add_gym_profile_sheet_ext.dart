part of 'add_gym_profile_sheet.dart';

/// Methods extracted from _AddGymProfileSheetState
extension __AddGymProfileSheetStateExt on _AddGymProfileSheetState {


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
        const SizedBox(height: 16),

        // AI import entry — saves profile immediately then hands off to the
        // import flow. See _openImportSheet() in add_gym_profile_sheet.dart
        // for the "create-then-import" sequence.
        FilledButton.tonalIcon(
          onPressed: _isLoading ? null : _openImportSheet,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Import from PDF, photo, or URL'),
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        const SizedBox(height: 16),

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
          Row(
            children: [
              Text(
                'Selected Equipment (${_selectedEquipment.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEquipment.clear();
                    _equipmentDetails.clear();
                  });
                  HapticService.light();
                },
                child: Text(
                  'Reset All',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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


  /// Step 3 — Schedule. User picks the weekdays they'll train at this gym
  /// and (optionally) the training split. The values are persisted to
  /// `gym_profiles.workout_days` + `gym_profiles.training_split` and drive
  /// the home carousel dot indicators + 14-day pre-generation on activate.
  ///
  /// Quick-fill buttons let the user copy from the active profile or their
  /// account-level workout_days, then tweak. Conflict markers warn when a
  /// day is also claimed by another profile (whichever is active that day
  /// wins at runtime — the warning is informational, not blocking).
  Widget _buildScheduleStep(bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
    final activeProfile = ref.read(activeGymProfileProvider);
    final user = ref.read(currentUserProvider).valueOrNull;
    final allProfiles = ref.read(gymProfilesProvider).valueOrNull ?? const <GymProfile>[];

    // Pre-compute per-day conflict map: which OTHER profiles already claim
    // each weekday. Empty unless the user has 2+ profiles. Skip the active
    // profile in conflict lookups since editing it isn't a "conflict."
    final Map<int, List<String>> conflictsByDay = {};
    for (final p in allProfiles) {
      if (p.id == activeProfile?.id) continue;
      for (final d in p.workoutDays) {
        conflictsByDay.putIfAbsent(d, () => []).add(p.name);
      }
    }

    void applyPreset(List<int> days) {
      setState(() => _selectedWorkoutDays = List<int>.from(days)..sort());
      HapticService.light();
    }

    final activeDays = activeProfile?.workoutDays ?? const <int>[];
    final accountDays = user?.workoutDays ?? const <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the days you\'ll train at this gym. We\'ll pre-generate 14 days '
          'of workouts for these days the moment you switch to this profile.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),

        // Quick-fill row: copy from current profile / account default / clear
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (activeDays.isNotEmpty)
              _scheduleQuickFillChip(
                label: 'Same as ${activeProfile?.name ?? 'current'}',
                icon: Icons.copy_rounded,
                accent: accentColor,
                isDark: isDark,
                textPrimary: textPrimary,
                onTap: () => applyPreset(activeDays),
              ),
            if (accountDays.isNotEmpty && !_listEquals(accountDays, activeDays))
              _scheduleQuickFillChip(
                label: 'Account default',
                icon: Icons.person_rounded,
                accent: accentColor,
                isDark: isDark,
                textPrimary: textPrimary,
                onTap: () => applyPreset(accountDays),
              ),
            _scheduleQuickFillChip(
              label: 'Clear',
              icon: Icons.refresh_rounded,
              accent: accentColor,
              isDark: isDark,
              textPrimary: textPrimary,
              onTap: () => applyPreset(const []),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Day-of-week picker. Mon=0..Sun=6 to match the backend index and
        // existing edit-sheet picker. Using LayoutBuilder so it scales on
        // narrow phones (iPhone SE, ~320px) without overflowing.
        LayoutBuilder(builder: (context, constraints) {
          final spacing = 6.0;
          final rawWidth = (constraints.maxWidth - spacing * 6) / 7;
          // Clamp tile width so very small screens still fit and very large
          // screens don't blow up the tiles.
          final tileWidth = rawWidth.clamp(36.0, 56.0);
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(7, (i) {
              final isSelected = _selectedWorkoutDays.contains(i);
              final hasConflict = (conflictsByDay[i] ?? const []).isNotEmpty;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWorkoutDays.remove(i);
                    } else {
                      _selectedWorkoutDays
                        ..add(i)
                        ..sort();
                    }
                  });
                  HapticService.light();
                },
                child: SizedBox(
                  width: tileWidth,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _AddGymProfileSheetState._dayNames[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? accentColor : textPrimary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                        // Tiny conflict marker — the user can hover/tap for details.
                        if (hasConflict)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Tooltip(
                              message: 'Also at: ${(conflictsByDay[i] ?? const []).join(", ")}',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: Colors.orange.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),

        // Render any conflict warnings as readable text below the picker —
        // a tooltip on a 12px icon isn't reliable on touch devices.
        if (_selectedWorkoutDays.any((d) => (conflictsByDay[d] ?? const []).isNotEmpty)) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildConflictMessage(conflictsByDay),
                    style: TextStyle(fontSize: 12, color: textPrimary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Training split picker (optional). Mirrors the EditGymProfileSheet
        // selector so toggling between create + edit is familiar.
        Text('Training Split', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 4),
        Text(
          'Optional — leave on "Let AI Decide" if unsure.',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _AddGymProfileSheetState._trainingSplitOptions.map((split) {
            // null + 'nothing_structured' both mean "AI decide"; treat them
            // as one selection so the visual state matches what's stored.
            final isAi = split['id'] == 'nothing_structured';
            final isSelected = isAi
                ? (_selectedTrainingSplit == null || _selectedTrainingSplit == 'nothing_structured')
                : _selectedTrainingSplit == split['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTrainingSplit = isAi ? null : split['id'] as String;
                });
                HapticService.light();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      split['icon'] as IconData,
                      size: 18,
                      color: isSelected ? accentColor : textSecondary,
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
                            color: isSelected ? accentColor : textPrimary,
                          ),
                        ),
                        Text(
                          split['desc'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.8)
                                : textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _scheduleQuickFillChip({
    required String label,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = List<int>.from(a)..sort();
    final sb = List<int>.from(b)..sort();
    for (int i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  String _buildConflictMessage(Map<int, List<String>> conflictsByDay) {
    final parts = <String>[];
    for (final d in _selectedWorkoutDays) {
      final names = conflictsByDay[d];
      if (names != null && names.isNotEmpty) {
        parts.add('${_AddGymProfileSheetState._dayNames[d]} also at "${names.join('", "')}"');
      }
    }
    return 'Schedule overlap: ${parts.join(' · ')}. Whichever profile is active that day will own the workout.';
  }

  Widget _buildStyleStep(bool isDark, Color textPrimary, Color textSecondary) {
    final selectedColorObj = GymProfileColors.fromHex(_selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline preview at top
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectedColorObj.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedColorObj.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _AddGymProfileSheetState._iconOptions.firstWhere(
                    (o) => o['id'] == _selectedIcon,
                    orElse: () => _AddGymProfileSheetState._iconOptions.first,
                  )['icon'] as IconData,
                  color: selectedColorObj,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _name.isEmpty ? 'Gym Name' : _name,
                  // Accent flows through the icon tile + border below, not
                  // the headline text. Painting the name in
                  // `selectedColorObj` made it invisible whenever the
                  // chosen accent matched the surface beneath the sheet
                  // (e.g. purple-on-purple when "Match app theme" was on).
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _name.isEmpty ? textSecondary : textPrimary,
                  ),
                ),
              ),
              Text(
                '${_selectedEquipment.length} equipment',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Icon selection
        Text(
          'Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _AddGymProfileSheetState._iconOptions.map((iconOption) {
            final isSelected = _selectedIcon == iconOption['id'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedIcon = iconOption['id'] as String);
                HapticService.light();
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColorObj.withOpacity(0.2)
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? selectedColorObj : Colors.transparent,
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

        const SizedBox(height: 20),

        // Color selection
        Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        // Match app theme option
        Builder(builder: (context) {
          final gymColor = ref.read(gymAccentColorProvider);
          final accent = ref.read(accentColorProvider);
          final appThemeColor = gymColor ?? accent.getColor(isDark);
          final onAppThemeColor = appThemeColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
          return GestureDetector(
            onTap: () {
              final hex = '#${appThemeColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              setState(() {
                _selectedColor = hex;
                _usingCustomColor = false;
                _usingAppTheme = true;
                _showCustomPicker = false;
              });
              HapticService.light();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _usingAppTheme
                    ? appThemeColor.withOpacity(0.15)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _usingAppTheme ? appThemeColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: appThemeColor,
                      shape: BoxShape.circle,
                    ),
                    child: _usingAppTheme
                        ? Icon(Icons.check_rounded, size: 14, color: onAppThemeColor)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Match app theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _usingAppTheme ? FontWeight.w600 : FontWeight.w400,
                      color: _usingAppTheme ? appThemeColor : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Palette swatches
            ...GymProfileColors.palette.map((colorHex) {
              final isSelected = _selectedColor == colorHex && !_usingCustomColor;
              final color = GymProfileColors.fromHex(colorHex);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = colorHex;
                    _usingCustomColor = false;
                    _usingAppTheme = false;
                    _showCustomPicker = false;
                  });
                  HapticService.light();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                        : null,
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                ),
              );
            }),

            // Custom color swatch — rainbow circle, becomes selected color when picked
            GestureDetector(
              onTap: () {
                setState(() => _showCustomPicker = !_showCustomPicker);
                HapticService.light();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _usingCustomColor
                      ? null
                      : const SweepGradient(colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ]),
                  color: _usingCustomColor ? GymProfileColors.fromHex(_selectedColor) : null,
                  border: Border.all(
                    color: _usingCustomColor || _showCustomPicker ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: _usingCustomColor
                      ? [BoxShadow(color: GymProfileColors.fromHex(_selectedColor).withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                      : null,
                ),
                child: _usingCustomColor
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Icon(Icons.add_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
              ),
            ),
          ],
        ),

        // Inline custom picker — only shown when the rainbow swatch is tapped
        if (_showCustomPicker) ...[
          const SizedBox(height: 14),
          _ColorScalePicker(
            selectedColor: _usingCustomColor ? GymProfileColors.fromHex(_selectedColor) : null,
            isDark: isDark,
            onColorSelected: (color) {
              final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              setState(() {
                _selectedColor = hex;
                _usingCustomColor = true;
                _usingAppTheme = false;
              });
              HapticService.light();
            },
          ),
        ],
      ],
    );
  }

}
