part of 'quick_workout_sheet.dart';


class _QuickWorkoutSheetState extends ConsumerState<_QuickWorkoutSheet> {
  int _selectedDuration = 15;
  String? _selectedFocus;
  String? _selectedDifficulty;
  String? _selectedMood;
  String? _selectedGoal;
  String? _dupSuggestion;
  MesocyclePlan? _activeMesocycle;
  MesocycleContext? _mesocycleContext;
  HrvRecoveryModifiers? _hrvModifiers;
  bool _useSupersets = true;
  bool _showAdvanced = false;
  String _weightUnit = 'kg';
  Set<String> _selectedEquipment = {'Bodyweight'};
  Set<String> _selectedInjuries = {};
  final Map<String, EquipmentItem> _equipmentDetails = {};
  String? _expandedEquipment; // which equipment's weight picker is open

  // Preset state
  List<QuickWorkoutPreset> _presets = [];
  List<QuickWorkoutPreset> _discoverPool = [];
  bool _presetsLoaded = false;

  final List<Map<String, dynamic>> _focusOptions = [
    {'value': 'cardio', 'label': 'Cardio / HIIT', 'icon': Icons.local_fire_department, 'color': AppColors.cardio},
    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.strength},
    {'value': 'stretch', 'label': 'Stretch', 'icon': Icons.self_improvement, 'color': AppColors.flexibility},
    {'value': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': null},
    {'value': 'upper_body', 'label': 'Upper Body', 'icon': Icons.sports_martial_arts, 'color': null},
    {'value': 'lower_body', 'label': 'Lower Body', 'icon': Icons.directions_walk, 'color': null},
    {'value': 'core', 'label': 'Core', 'icon': Icons.circle_outlined, 'color': null},
    {'value': 'emom', 'label': 'EMOM', 'icon': Icons.timer, 'color': Colors.purple},
    {'value': 'amrap', 'label': 'AMRAP', 'icon': Icons.repeat, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _moodOptions = [
    {'value': 'energized', 'label': 'Energized', 'icon': Icons.bolt, 'color': Colors.orange},
    {'value': 'tired', 'label': 'Tired', 'icon': Icons.bedtime_outlined, 'color': Colors.indigo},
    {'value': 'stressed', 'label': 'Stressed', 'icon': Icons.psychology_outlined, 'color': Colors.red},
    {'value': 'chill', 'label': 'Chill', 'icon': Icons.spa_outlined, 'color': Colors.teal},
    {'value': 'motivated', 'label': 'Fired Up', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'value': 'low_energy', 'label': 'Low Energy', 'icon': Icons.battery_2_bar, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickWorkoutProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Theme-aware accent color (AppColors.cyan is light gray for dark theme — invisible in light mode)
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final chipBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perfect for busy days',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textMuted),
              ),
            ],
          ),
        ),

        // ── Preset row ──
        if (_presetsLoaded && _presets.isNotEmpty)
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length + 1, // +1 for Discover card
              itemBuilder: (context, index) {
                if (index == _presets.length) {
                  return _buildDiscoverCard(
                    accentColor: accentColor,
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  );
                }
                final preset = _presets[index];
                return _buildPresetCard(
                  preset: preset,
                  accentColor: accentColor,
                  cardBackground: cardBackground,
                  chipBorder: chipBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration slider
                Row(
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_selectedDuration min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: chipBorder,
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _selectedDuration.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (v) {
                      HapticService.light();
                      setState(() => _selectedDuration = v.round());
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Focus selector
                Text(
                  'Focus (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Show first 5 options (2 rows)
                    ..._focusOptions.take(5).map((option) {
                      final isSelected = _selectedFocus == option['value'];
                      final chipColor = (option['color'] as Color?) ?? accentColor;
                      return _FocusChip(
                        label: option['label'] as String,
                        icon: option['icon'] as IconData,
                        color: chipColor,
                        isSelected: isSelected,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            _selectedFocus = isSelected ? null : option['value'] as String;
                          });
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }),
                    // Show selected option from hidden set (if any)
                    ..._focusOptions.skip(5).where((option) =>
                        _selectedFocus == option['value']).map((option) {
                      final chipColor = (option['color'] as Color?) ?? accentColor;
                      return _FocusChip(
                        label: option['label'] as String,
                        icon: option['icon'] as IconData,
                        color: chipColor,
                        isSelected: true,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedFocus = null);
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }),
                    // "More" chip
                    GestureDetector(
                      onTap: () => _showMoreFocusDialog(
                        accentColor: accentColor,
                        cardBackground: cardBackground,
                        chipBorder: chipBorder,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: chipBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.more_horiz, size: 18, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'More',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // "Customize more" toggle between Focus and advanced content
                TextButton.icon(
                  onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                  icon: Icon(_showAdvanced ? Icons.expand_less : Icons.tune, size: 18),
                  label: Text(_showAdvanced ? 'Show less' : 'Customize more'),
                  style: TextButton.styleFrom(foregroundColor: textSecondary),
                ),

                // ── Advanced section (collapsed by default) ──
                if (_showAdvanced) ...[
                  const SizedBox(height: 8),

                  // Equipment selector (chips only — weight pickers further below)
                  Row(
                    children: [
                      Text(
                        'Equipment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            final isFullGym = _fullGymEquipment.every(
                              (e) => _selectedEquipment.contains(e),
                            );
                            if (isFullGym) {
                              _selectedEquipment = {'Bodyweight'};
                              _equipmentDetails.clear();
                              _expandedEquipment = null;
                            } else {
                              _selectedEquipment = Set.from(_fullGymEquipment);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _fullGymEquipment.every(
                              (e) => _selectedEquipment.contains(e),
                            )
                                ? accentColor.withValues(alpha: 0.15)
                                : cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _fullGymEquipment.every(
                                (e) => _selectedEquipment.contains(e),
                              )
                                  ? accentColor
                                  : chipBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 14,
                                color: _fullGymEquipment.every(
                                  (e) => _selectedEquipment.contains(e),
                                )
                                    ? accentColor
                                    : textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Full Gym',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _fullGymEquipment.every(
                                    (e) => _selectedEquipment.contains(e),
                                  )
                                      ? accentColor
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._primaryEquipment.map((equip) {
                        final isSelected = _selectedEquipment.contains(equip);
                        final hasDetails = _equipmentDetails.containsKey(equip);
                        final supportsDetail = _supportsWeightDetail(equip);
                        return _EquipmentChip(
                          label: equip,
                          isSelected: isSelected,
                          hasDetails: hasDetails,
                          showTuneIcon: isSelected && supportsDetail,
                          color: accentColor,
                          chipBorder: chipBorder,
                          onTap: () {
                            HapticService.light();
                            setState(() {
                              if (isSelected) {
                                _selectedEquipment.remove(equip);
                                _equipmentDetails.remove(equip);
                                if (_expandedEquipment == equip) {
                                  _expandedEquipment = null;
                                }
                              } else {
                                _selectedEquipment.add(equip);
                              }
                            });
                          },
                          onTuneTap: supportsDetail
                              ? () {
                                  HapticService.light();
                                  setState(() {
                                    _expandedEquipment =
                                        _expandedEquipment == equip ? null : equip;
                                  });
                                }
                              : null,
                          cardBackground: cardBackground,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        );
                      }),
                      if (!_fullGymEquipment.every((e) => _selectedEquipment.contains(e)))
                      ..._selectedEquipment
                          .where((e) => !_primaryEquipment.contains(e))
                          .map((equip) {
                        final hasDetails = _equipmentDetails.containsKey(equip);
                        final supportsDetail = _supportsWeightDetail(equip);
                        return _EquipmentChip(
                          label: equip,
                          isSelected: true,
                          hasDetails: hasDetails,
                          showTuneIcon: supportsDetail,
                          color: accentColor,
                          chipBorder: chipBorder,
                          onTap: () {
                            HapticService.light();
                            setState(() {
                              _selectedEquipment.remove(equip);
                              _equipmentDetails.remove(equip);
                              if (_expandedEquipment == equip) {
                                _expandedEquipment = null;
                              }
                            });
                          },
                          onTuneTap: supportsDetail
                              ? () {
                                  HapticService.light();
                                  setState(() {
                                    _expandedEquipment =
                                        _expandedEquipment == equip ? null : equip;
                                  });
                                }
                              : null,
                          cardBackground: cardBackground,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        );
                      }),
                      GestureDetector(
                        onTap: () => _showMoreEquipmentDialog(
                          accentColor: accentColor,
                          cardBackground: cardBackground,
                          chipBorder: chipBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: chipBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'More',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Injuries selector
                  Text(
                    'Injuries (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _injuryOptions.map((injury) {
                      final isSelected = _selectedInjuries.contains(injury);
                      return _ToggleChip(
                        label: injury,
                        isSelected: isSelected,
                        color: AppColors.error,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            if (isSelected) {
                              _selectedInjuries.remove(injury);
                            } else {
                              _selectedInjuries.add(injury);
                            }
                          });
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Difficulty selector
                  Text(
                    'Difficulty',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: DifficultyUtils.internalValues.map((diff) {
                      final isSelected = _selectedDifficulty == diff;
                      final color = DifficultyUtils.getColor(diff);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: diff != DifficultyUtils.internalValues.last ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() {
                                _selectedDifficulty = isSelected ? null : diff;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withValues(alpha: 0.15) : cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? color : chipBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (diff == 'hell') Icon(Icons.local_fire_department, size: 14, color: isSelected ? color : textPrimary),
                                    if (diff == 'hell') const SizedBox(width: 4),
                                    Text(
                                      DifficultyUtils.getDisplayName(diff),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? color : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Goal selector
                  Text(
                    'Goal (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': Colors.red},
                      {'value': 'hypertrophy', 'label': 'Hypertrophy', 'icon': Icons.accessibility_new, 'color': Colors.blue},
                      {'value': 'endurance', 'label': 'Endurance', 'icon': Icons.directions_run, 'color': Colors.green},
                      {'value': 'power', 'label': 'Power', 'icon': Icons.bolt, 'color': Colors.orange},
                    ].asMap().entries.map((entry) {
                      final option = entry.value;
                      final isSelected = _selectedGoal == option['value'];
                      final chipColor = option['color'] as Color;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: entry.key < 3 ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() {
                                _selectedGoal = isSelected ? null : option['value'] as String;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? chipColor.withValues(alpha: 0.15) : cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? chipColor : chipBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    size: 18,
                                    color: isSelected ? chipColor : textMuted,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? chipColor : textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // DUP suggestion
                  if (_dupSuggestion != null && _selectedGoal == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Suggested: ${_dupSuggestion![0].toUpperCase()}${_dupSuggestion!.substring(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Mood selector
                  Text(
                    'Mood (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moodOptions.map((option) {
                      final isSelected = _selectedMood == option['value'];
                      final chipColor = option['color'] as Color;
                      return _FocusChip(
                        label: option['label'] as String,
                        icon: option['icon'] as IconData,
                        color: chipColor,
                        isSelected: isSelected,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            _selectedMood = isSelected ? null : option['value'] as String;
                          });
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Format section
                  Text('Format', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: chipBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, color: accentColor, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Supersets', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
                              Text('Pair opposing muscles to save time', style: TextStyle(color: textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _useSupersets,
                          activeColor: accentColor,
                          onChanged: (_selectedFocus == 'cardio' || _selectedFocus == 'stretch')
                              ? null
                              : (v) => setState(() => _useSupersets = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Equipment Details (weight pickers — only for selected equipment)
                  if (_selectedEquipment.any(_supportsWeightDetail)) ...[
                    Text(
                      'Equipment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedEquipment.where(_supportsWeightDetail).map((equip) {
                      final isExpanded = _expandedEquipment == equip;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticService.light();
                                setState(() {
                                  _expandedEquipment = isExpanded ? null : equip;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Icon(Icons.tune, size: 16, color: accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    equip,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (_equipmentDetails.containsKey(equip)) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_circle, size: 14, color: accentColor),
                                  ],
                                  const Spacer(),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.expand_more, size: 20, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isExpanded)
                              _buildWeightPicker(
                                equip,
                                accentColor: accentColor,
                                cardBackground: cardBackground,
                                chipBorder: chipBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textMuted: textMuted,
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  // Mesocycle status chip
                  if (_mesocycleContext != null && _activeMesocycle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _mesocycleContext!.isDeload
                              ? Colors.green.withOpacity(0.1)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _mesocycleContext!.isDeload
                                ? Colors.green.withOpacity(0.3)
                                : accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _mesocycleContext!.isDeload
                                  ? Icons.spa_outlined
                                  : Icons.trending_up,
                              size: 18,
                              color: _mesocycleContext!.isDeload
                                  ? Colors.green
                                  : accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mesocycle: ${_mesocycleContext!.phaseDisplayName}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Week ${_mesocycleContext!.weekNumber}/${_mesocycleContext!.totalWeeks}'
                                    '${_mesocycleContext!.isDeload ? " - Recovery week" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // HRV readiness indicator
                  if (_hrvModifiers != null && _hrvModifiers!.hasData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _getReadinessColor(_hrvModifiers!.readinessLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getReadinessColor(_hrvModifiers!.readinessLevel).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getReadinessIcon(_hrvModifiers!.readinessLevel),
                              size: 18,
                              color: _getReadinessColor(_hrvModifiers!.readinessLevel),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recovery: ${_hrvModifiers!.readinessDisplayName}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (_hrvModifiers!.explanation != null)
                                    Text(
                                      _hrvModifiers!.explanation!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Instant generation powered by exercise science research.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ], // end _showAdvanced
              ],
            ),
          ),
        ),

        // Generate button
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isGenerating
                  ? null
                  : () => _generateQuickWorkout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor: accentColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: state.isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          state.statusMessage ?? 'Generating...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Generate $_selectedDuration-min Workout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // Error message
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Stored conflict workout ID for the "Replace" action
  String? _conflictWorkoutId;
}

