part of 'quick_workout_sheet.dart';

/// Methods extracted from _QuickWorkoutSheetState
extension __QuickWorkoutSheetStateExt1 on _QuickWorkoutSheetState {

  /// Primary equipment shown as chips directly.
  static const List<String> _primaryEquipment = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine',
    'Kettlebell',
  ];

  /// Full list of all equipment options (shown in "More" dialog).
  static const List<String> _allEquipmentOptions = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine', 'Kettlebell',
    'Smith Machine', 'EZ Bar', 'Resistance Bands', 'Pull-up Bar',
    'Machines', 'Suspension Trainer', 'Exercise Ball', 'Sandbag',
    'Battle Ropes', 'Yoga Mat', 'Dip Station',
  ];

  /// Equipment types that get auto-selected when "Full Gym" is tapped.
  static const Set<String> _fullGymEquipment = {
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine', 'Machines',
    'Smith Machine', 'Kettlebell', 'EZ Bar', 'Pull-up Bar',
  };


  static const List<String> _injuryOptions = [
    'Shoulder', 'Lower Back', 'Knee', 'Ankle', 'Hip', 'Neck', 'Elbow', 'Wrist',
  ];

  void _extInitState() {
    _initFromUserProfile();
    _loadDupSuggestion();
    _loadMesocycleStatus();
    _loadHrvModifiers();
    _loadPresets();
  }


  Future<void> _loadHrvModifiers() async {
    try {
      final modifiers = await HrvRecoveryService.getModifiers();
      if (mounted && modifiers.hasData) {
        setState(() => _hrvModifiers = modifiers);
      }
    } catch (_) {
      // Non-critical: continue without HRV data
    }
  }


  Future<void> _loadMesocycleStatus() async {
    try {
      final plan = await MesocyclePlanner.getActivePlan();
      final context = await MesocyclePlanner.getCurrentContext();
      if (mounted) {
        setState(() {
          _activeMesocycle = plan;
          _mesocycleContext = context;
        });
      }
    } catch (_) {
      // Silently fail -- mesocycle display is non-critical
    }
  }


  Future<void> _loadDupSuggestion() async {
    try {
      final recoveryScores = await MuscleRecoveryTracker.getAllRecoveryScores();
      final avgRecovery = recoveryScores.isEmpty
          ? null
          : recoveryScores.values.reduce((a, b) => a + b) / recoveryScores.length;
      final suggestion = await DupRotation.getNextGoal(avgRecoveryPercent: avgRecovery);
      if (mounted) {
        setState(() => _dupSuggestion = suggestion);
      }
    } catch (_) {
      // Silently fail -- DUP suggestion is non-critical
    }
  }


  Future<void> _loadPresets() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user == null) return;

      final userId = user.id;
      final presets = await QuickWorkoutPresetService.loadPresets(db, userId, user);
      final discover = QuickWorkoutPresetService.generateDiscoverPool(user);

      if (mounted) {
        setState(() {
          _presets = presets;
          _discoverPool = discover;
          _presetsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('[QuickPresets] Failed to load presets: $e');
      if (mounted) setState(() => _presetsLoaded = true);
    }
  }


  void _initFromUserProfile() {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    // Read weight unit preference
    _weightUnit = user.preferredWeightUnit;

    // Pre-fill difficulty from fitness level
    final level = user.fitnessLevel?.toLowerCase();
    if (level != null && DifficultyUtils.internalValues.contains(level)) {
      _selectedDifficulty = level;
    }

    // Pre-fill equipment from profile (always include Bodyweight)
    final profileEquipment = user.equipmentList;
    if (profileEquipment.isNotEmpty) {
      _selectedEquipment = profileEquipment
          .where((e) => _allEquipmentOptions.any((o) => o.toLowerCase() == e.toLowerCase()))
          .map((e) => _allEquipmentOptions.firstWhere((o) => o.toLowerCase() == e.toLowerCase()))
          .toSet();
      _selectedEquipment.add('Bodyweight');
    }

    // Pre-fill injuries from profile
    final profileInjuries = user.injuriesList;
    if (profileInjuries.isNotEmpty) {
      _selectedInjuries = profileInjuries
          .where((e) => _injuryOptions.any((o) => o.toLowerCase() == e.toLowerCase()))
          .map((e) => _injuryOptions.firstWhere((o) => o.toLowerCase() == e.toLowerCase()))
          .toSet();
    }
  }


  /// Whether this equipment type supports inline weight detail picker.
  bool _supportsWeightDetail(String equip) {
    final lower = equip.toLowerCase();
    return lower == 'dumbbells' ||
        lower == 'kettlebell' ||
        lower == 'barbell' ||
        lower == 'ez bar';
  }


  /// Build inline weight picker for the given equipment type.
  Widget _buildWeightPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final lower = equip.toLowerCase();
    final existing = _equipmentDetails[equip];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  'Available weights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                // Inline kg / lbs toggle
                Container(
                  decoration: BoxDecoration(
                    color: chipBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final unit in ['kg', 'lbs'])
                        GestureDetector(
                          onTap: () {
                            if (_weightUnit == unit) return;
                            HapticService.light();
                            setState(() {
                              _weightUnit = unit;
                              // Clear stale weight selections since values differ per unit
                              _equipmentDetails.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _weightUnit == unit ? accentColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _weightUnit == unit
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                                    : textMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                if (existing != null && existing.weightInventory.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() => _equipmentDetails.remove(equip));
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 12, color: accentColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (lower == 'dumbbells' || lower == 'kettlebell')
              _buildDumbbellKettlebellPicker(
                equip,
                accentColor: accentColor,
                cardBackground: cardBackground,
                chipBorder: chipBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              )
            else if (lower == 'barbell')
              _buildBarbellPicker(
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
      ),
    );
  }


  /// Weight chips for dumbbells/kettlebells.
  /// Tap cycles: 0 -> 1 -> 2 -> 0. Shows "1x" or "2x" badge.
  Widget _buildDumbbellKettlebellPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final weights = _weightUnit == 'lbs'
        ? [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0]
        : [5.0, 8.0, 10.0, 12.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
    final existing = _equipmentDetails[equip];
    final currentInventory =
        existing?.weightInventory ?? <double, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap to add (tap again for pairs)',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: weights.map((w) {
            final qty = currentInventory[w] ?? 0;
            final isActive = qty > 0;
            return GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() {
                  final newQty = (qty + 1) % 3; // 0 -> 1 -> 2 -> 0
                  final newInventory =
                      Map<double, int>.from(currentInventory);
                  if (newQty == 0) {
                    newInventory.remove(w);
                  } else {
                    newInventory[w] = newQty;
                  }
                  _equipmentDetails[equip] = EquipmentItem(
                    name: equip.toLowerCase() == 'dumbbells'
                        ? 'dumbbells'
                        : 'kettlebells',
                    displayName: equip,
                    quantity: newInventory.values.isEmpty
                        ? 1
                        : newInventory.values.reduce((a, b) => a > b ? a : b),
                    weightInventory: newInventory,
                    weightUnit: _weightUnit,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? accentColor.withOpacity(0.15)
                      : cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? accentColor : chipBorder,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${w.toInt()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? accentColor : textMuted,
                      ),
                    ),
                    if (qty > 0)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _weightUnit,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }


  /// Barbell picker: "Bar only (20kg)" toggle vs "With plates".
  Widget _buildBarbellPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isLbs = _weightUnit == 'lbs';
    final barWeight = isLbs ? 45.0 : 20.0;
    final barLabel = isLbs ? 'Bar only (45 lbs)' : 'Bar only (20kg)';
    final barTempoLabel = isLbs ? 'High-rep tempo work at 45 lbs' : 'High-rep tempo work at 20kg';
    final plateInventory = isLbs
        ? {45.0: 1, 95.0: 1, 135.0: 1, 185.0: 1, 225.0: 1}
        : {20.0: 1, 40.0: 1, 60.0: 1, 80.0: 1, 100.0: 1};

    final existing = _equipmentDetails[equip];
    final isBarOnly = existing != null &&
        existing.weightInventory.length == 1 &&
        existing.weightInventory.containsKey(barWeight);
    final hasPlates = existing != null &&
        existing.weightInventory.isNotEmpty &&
        !isBarOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _equipmentDetails[equip] = EquipmentItem(
                      name: 'barbell',
                      displayName: 'Barbell',
                      quantity: 1,
                      weightInventory: {barWeight: 1},
                      weightUnit: _weightUnit,
                      notes: 'bar only',
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBarOnly
                        ? accentColor.withOpacity(0.15)
                        : cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBarOnly ? accentColor : chipBorder,
                      width: isBarOnly ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      barLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBarOnly ? accentColor : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _equipmentDetails[equip] = EquipmentItem(
                      name: 'barbell',
                      displayName: 'Barbell',
                      quantity: 1,
                      weightInventory: plateInventory,
                      weightUnit: _weightUnit,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPlates
                        ? accentColor.withOpacity(0.15)
                        : cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPlates ? accentColor : chipBorder,
                      width: hasPlates ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'With plates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasPlates ? accentColor : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isBarOnly)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              barTempoLabel,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ),
      ],
    );
  }


  Color _getReadinessColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.low:
        return Colors.red;
      case ReadinessLevel.moderate:
        return Colors.orange;
      case ReadinessLevel.high:
        return Colors.green;
      case ReadinessLevel.peak:
        return Colors.blue;
    }
  }


  IconData _getReadinessIcon(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.low:
        return Icons.battery_1_bar;
      case ReadinessLevel.moderate:
        return Icons.battery_3_bar;
      case ReadinessLevel.high:
        return Icons.battery_full;
      case ReadinessLevel.peak:
        return Icons.bolt;
    }
  }


  void _showMoreFocusDialog({
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Workout Focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _focusOptions.map((option) {
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
                      Navigator.pop(ctx);
                    },
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  );
                }).toList(),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }


  void _showMoreEquipmentDialog({
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    // Copy current selection so dialog can preview changes
    var tempSelection = Set<String>.from(_selectedEquipment);

    showGlassSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (ctx, scrollController) => GlassSheet(
              showHandle: true,
              child: Column(
                children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'All Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedEquipment = tempSelection);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _allEquipmentOptions.length,
                    itemBuilder: (ctx, index) {
                      final equip = _allEquipmentOptions[index];
                      final isSelected = tempSelection.contains(equip);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _getEquipmentIcon(equip),
                          color: isSelected ? accentColor : textMuted,
                          size: 22,
                        ),
                        title: Text(
                          equip,
                          style: TextStyle(
                            color: isSelected ? accentColor : textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accentColor, size: 22)
                            : Icon(Icons.circle_outlined, color: chipBorder, size: 22),
                        onTap: () {
                          HapticService.light();
                          setModalState(() {
                            if (isSelected) {
                              tempSelection.remove(equip);
                            } else {
                              tempSelection.add(equip);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }


  IconData _getEquipmentIcon(String equip) {
    switch (equip) {
      case 'Bodyweight':
        return Icons.accessibility_new;
      case 'Dumbbells':
        return Icons.fitness_center;
      case 'Barbell':
        return Icons.sports_gymnastics;
      case 'Cable Machine':
        return Icons.cable;
      case 'Kettlebell':
        return Icons.sports_mma;
      case 'Smith Machine':
        return Icons.view_column_outlined;
      case 'EZ Bar':
        return Icons.straighten;
      case 'Resistance Bands':
        return Icons.waves;
      case 'Pull-up Bar':
        return Icons.horizontal_rule;
      case 'Machines':
        return Icons.precision_manufacturing;
      case 'Suspension Trainer':
        return Icons.link;
      case 'Exercise Ball':
        return Icons.sports_baseball;
      case 'Sandbag':
        return Icons.inventory_2_outlined;
      case 'Battle Ropes':
        return Icons.gesture;
      case 'Yoga Mat':
        return Icons.self_improvement;
      case 'Dip Station':
        return Icons.expand;
      default:
        return Icons.fitness_center;
    }
  }


  Widget _buildPresetCard({
    required QuickWorkoutPreset preset,
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final presetColor = preset.color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _generateFromPreset(preset),
        onLongPress: () => _showPresetOptions(preset),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: presetColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: presetColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(preset.icon, size: 16, color: presetColor),
                  const SizedBox(width: 4),
                  Text(
                    '${preset.duration}m',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: presetColor,
                    ),
                  ),
                  const Spacer(),
                  if (preset.isFavorite)
                    Icon(Icons.favorite, size: 12, color: Colors.red.shade300),
                  if (preset.isAiGenerated && !preset.isFavorite)
                    Icon(Icons.auto_awesome, size: 12, color: presetColor.withOpacity(0.7)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _focusLabel(preset.focus),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                preset.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDiscoverCard({
    required Color accentColor,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _showDiscoverSheet,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 24, color: accentColor),
              const SizedBox(height: 8),
              Text(
                'Discover',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _focusLabel(String? focus) {
    switch (focus) {
      case 'cardio': return 'Cardio';
      case 'strength': return 'Strength';
      case 'stretch': return 'Stretch';
      case 'full_body': return 'Full Body';
      case 'upper_body': return 'Upper Body';
      case 'lower_body': return 'Lower Body';
      case 'core': return 'Core';
      case 'emom': return 'EMOM';
      case 'amrap': return 'AMRAP';
      default: return 'Quick';
    }
  }


  void _generateFromPreset(QuickWorkoutPreset preset) {
    // Apply preset values to the sheet state, then generate
    setState(() {
      _selectedDuration = preset.duration;
      _selectedFocus = preset.focus;
      _selectedDifficulty = preset.difficulty;
      _selectedGoal = preset.goal;
      _selectedMood = preset.mood;
      _useSupersets = preset.useSupersets;
      _selectedEquipment = preset.equipment.toSet();
      _selectedInjuries = preset.injuries.toSet();
      _equipmentDetails.clear();
      if (preset.equipmentDetails != null) {
        _equipmentDetails.addAll(preset.equipmentDetails!);
      }
    });
    _generateQuickWorkout();
  }


  void _showPresetOptions(QuickWorkoutPreset preset) {
    HapticService.medium();
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                preset.label,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  preset.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: preset.isFavorite ? Colors.red : null,
                ),
                title: Text(preset.isFavorite ? 'Unfavorite' : 'Favorite'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(appDatabaseProvider);
                  await QuickWorkoutPresetService.toggleFavorite(db, preset.id);
                  await _loadPresets();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(appDatabaseProvider);
                  await QuickWorkoutPresetService.deletePreset(db, preset.id);
                  await _loadPresets();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

}
