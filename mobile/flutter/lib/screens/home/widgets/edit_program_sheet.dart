import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// Shows a bottom sheet for editing program preferences
Future<bool?> showEditProgramSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  // Capture the parent theme to ensure proper inheritance in the modal
  final parentTheme = Theme.of(context);

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: const _EditProgramSheet(),
    ),
  );
}

class _EditProgramSheet extends ConsumerStatefulWidget {
  const _EditProgramSheet();

  @override
  ConsumerState<_EditProgramSheet> createState() => _EditProgramSheetState();
}

class _EditProgramSheetState extends ConsumerState<_EditProgramSheet> {
  bool _isUpdating = false;
  bool _isLoading = true;
  String _selectedDifficulty = 'medium';
  double _selectedDuration = 45;
  String? _selectedWorkoutType;
  final Set<String> _selectedFocusAreas = {};
  final Set<String> _selectedInjuries = {};
  final Set<String> _selectedEquipment = {};
  final Set<int> _selectedDays = {}; // 0 = Monday, 6 = Sunday

  // Custom "Other" inputs
  String _customFocusArea = '';
  String _customInjury = '';
  String _customEquipment = '';
  String _customWorkoutType = '';
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;
  bool _showEquipmentInput = false;
  bool _showWorkoutTypeInput = false;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _workoutTypeController = TextEditingController();

  final List<String> _difficulties = ['easy', 'medium', 'hard'];
  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _workoutTypes = [
    'Strength',
    'HIIT',
    'Cardio',
    'Flexibility',
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Core',
  ];
  final List<String> _focusAreas = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Legs',
    'Glutes',
    'Full Body',
  ];
  final List<String> _injuries = [
    'Shoulder',
    'Lower Back',
    'Knee',
    'Elbow',
    'Wrist',
    'Ankle',
    'Hip',
    'Neck',
  ];
  final List<String> _equipmentOptions = [
    'Dumbbells',
    'Barbell',
    'Kettlebell',
    'Resistance Bands',
    'Pull-up Bar',
    'Bench',
    'Cable Machine',
    'Bodyweight Only',
  ];

  @override
  void initState() {
    super.initState();
    // Load preferences after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        // Set defaults if no user
        _selectedDays.addAll([0, 2, 4]);
        _selectedFocusAreas.add('Full Body');
      });
      return;
    }

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final prefs = await repo.getProgramPreferences(userId);

      if (mounted) {
        setState(() {
          if (prefs != null) {
            // Set difficulty
            if (prefs.difficulty != null) {
              _selectedDifficulty = prefs.difficulty!.toLowerCase();
            }

            // Set duration
            if (prefs.durationMinutes != null) {
              _selectedDuration = prefs.durationMinutes!.toDouble().clamp(15, 90);
            }

            // Set workout type
            if (prefs.workoutType != null && prefs.workoutType!.isNotEmpty) {
              // Check if it's a standard workout type
              final normalizedType = _workoutTypes.firstWhere(
                (t) => t.toLowerCase() == prefs.workoutType!.toLowerCase(),
                orElse: () => '',
              );
              if (normalizedType.isNotEmpty) {
                _selectedWorkoutType = normalizedType;
              } else {
                _customWorkoutType = prefs.workoutType!;
              }
            }

            // Set workout days (convert day names to indices)
            _selectedDays.clear();
            if (prefs.workoutDays.isNotEmpty) {
              final dayMap = {'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5, 'Sun': 6};
              for (final day in prefs.workoutDays) {
                final index = dayMap[day];
                if (index != null) {
                  _selectedDays.add(index);
                }
              }
            } else {
              // Default to Mon, Wed, Fri
              _selectedDays.addAll([0, 2, 4]);
            }

            // Set equipment
            _selectedEquipment.clear();
            for (final equip in prefs.equipment) {
              if (_equipmentOptions.contains(equip)) {
                _selectedEquipment.add(equip);
              } else if (_customEquipment.isEmpty) {
                _customEquipment = equip;
              }
            }

            // Set focus areas
            _selectedFocusAreas.clear();
            for (final area in prefs.focusAreas) {
              if (_focusAreas.contains(area)) {
                _selectedFocusAreas.add(area);
              } else if (_customFocusArea.isEmpty) {
                _customFocusArea = area;
              }
            }
            if (_selectedFocusAreas.isEmpty && _customFocusArea.isEmpty) {
              _selectedFocusAreas.add('Full Body');
            }

            // Set injuries
            _selectedInjuries.clear();
            for (final injury in prefs.injuries) {
              if (_injuries.contains(injury)) {
                _selectedInjuries.add(injury);
              } else if (_customInjury.isEmpty) {
                _customInjury = injury;
              }
            }
          } else {
            // No preferences found, set defaults
            _selectedDays.addAll([0, 2, 4]);
            _selectedFocusAreas.add('Full Body');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set defaults on error
          _selectedDays.addAll([0, 2, 4]);
          _selectedFocusAreas.add('Full Body');
        });
      }
    }
  }

  @override
  void dispose() {
    _focusAreaController.dispose();
    _injuryController.dispose();
    _equipmentController.dispose();
    _workoutTypeController.dispose();
    super.dispose();
  }

  Future<void> _updateProgram() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one workout day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isUpdating = false);
      return;
    }

    try {
      // Combine selected focus areas with custom one
      final allFocusAreas = _selectedFocusAreas.toList();
      if (_customFocusArea.isNotEmpty) {
        allFocusAreas.add(_customFocusArea);
      }

      // Combine selected injuries with custom one
      final allInjuries = _selectedInjuries.toList();
      if (_customInjury.isNotEmpty) {
        allInjuries.add(_customInjury);
      }

      // Combine selected equipment with custom one
      final allEquipment = _selectedEquipment.toList();
      if (_customEquipment.isNotEmpty) {
        allEquipment.add(_customEquipment);
      }

      // Use custom workout type if entered, otherwise selected
      final workoutType = _customWorkoutType.isNotEmpty
          ? _customWorkoutType
          : _selectedWorkoutType;

      // Convert day indices to day names for the API
      final selectedDayNames = _selectedDays.map((i) => _dayNames[i]).toList();

      final repo = ref.read(workoutRepositoryProvider);
      await repo.updateProgramAndRegenerate(
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutes: _selectedDuration.round(),
        focusAreas: allFocusAreas,
        injuries: allInjuries,
        equipment: allEquipment.isNotEmpty ? allEquipment : null,
        workoutType: workoutType,
        workoutDays: selectedDayNames,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update program: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Riverpod theme provider for consistent theme detection
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final _SheetColors colors = isDark ? _DarkColors() : _LightColors();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: colors.cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Program',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adjust settings and regenerate future workouts',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isUpdating ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: colors.textSecondary),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.cardBorder),

            // Scrollable content or loading indicator
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: colors.cyan),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your preferences...',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Days Selection
                    _buildWorkoutDaysSection(colors),

                    // Workout Type Selection
                    _buildWorkoutTypeSection(colors),

                    // Difficulty Selection
                    _buildDifficultySection(colors),

                    // Duration Selection (Slider)
                    _buildDurationSection(colors),

                    const SizedBox(height: 20),

                    // Equipment Selection
                    _buildEquipmentSection(colors),

                    const SizedBox(height: 20),

                    // Focus Areas Selection
                    _buildFocusAreasSection(colors),

                    const SizedBox(height: 20),

                    // Injuries Section (Optional)
                    _buildInjuriesSection(colors),

                    const SizedBox(height: 24),

                    // Update Button
                    _buildUpdateButton(colors),

                    // Extra padding
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDaysSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 20, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Workout Days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              Text(
                '${_selectedDays.length} days/week',
                style: TextStyle(color: colors.cyan, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select which days you want to work out',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(index);
                          } else {
                            _selectedDays.add(index);
                          }
                        });
                      },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.cyan.withOpacity(0.2)
                        : colors.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.cyan : colors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _dayNames[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.cyan : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTypeSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, size: 20, color: colors.purple),
              const SizedBox(width: 8),
              Text(
                'Workout Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Leave unselected for variety',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._workoutTypes.map((type) {
                final isSelected = _selectedWorkoutType?.toLowerCase() == type.toLowerCase() &&
                    _customWorkoutType.isEmpty;
                return GestureDetector(
                  onTap: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            _selectedWorkoutType = isSelected ? null : type;
                            _customWorkoutType = '';
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.purple.withOpacity(0.2)
                          : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colors.purple
                            : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? colors.purple : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () => setState(() => _showWorkoutTypeInput = !_showWorkoutTypeInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customWorkoutType.isNotEmpty
                        ? colors.purple.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customWorkoutType.isNotEmpty
                          ? colors.purple
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customWorkoutType.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showWorkoutTypeInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customWorkoutType.isNotEmpty ? colors.purple : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customWorkoutType.isNotEmpty ? _customWorkoutType : 'Other',
                        style: TextStyle(
                          color: _customWorkoutType.isNotEmpty ? colors.purple : colors.textSecondary,
                          fontWeight: _customWorkoutType.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showWorkoutTypeInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _workoutTypeController,
              decoration: InputDecoration(
                hintText: 'Enter custom workout type',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.purple),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.purple),
                  onPressed: () {
                    setState(() {
                      _customWorkoutType = _workoutTypeController.text.trim();
                      _selectedWorkoutType = null;
                      _showWorkoutTypeInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customWorkoutType = value.trim();
                  _selectedWorkoutType = null;
                  _showWorkoutTypeInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultySection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.speed, size: 20, color: colors.orange),
              const SizedBox(width: 8),
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _difficulties.map((difficulty) {
              final isSelected = _selectedDifficulty == difficulty;
              final color = _getDifficultyColor(difficulty);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty != _difficulties.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: _isUpdating
                        ? null
                        : () => setState(() => _selectedDifficulty = difficulty),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : colors.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : colors.cardBorder.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          difficulty[0].toUpperCase() + difficulty.substring(1),
                          style: TextStyle(
                            color: isSelected ? color : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: colors.success),
              const SizedBox(width: 8),
              Text(
                'Workout Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDuration.round()} min',
                  style: TextStyle(
                    color: colors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.success,
              inactiveTrackColor: colors.glassSurface,
              thumbColor: colors.success,
              overlayColor: colors.success.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _selectedDuration,
              min: 15,
              max: 90,
              divisions: 15,
              onChanged: _isUpdating
                  ? null
                  : (value) => setState(() => _selectedDuration = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15 min', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                Text('90 min', style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Equipment Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedEquipment.isNotEmpty || _customEquipment.isNotEmpty)
                Text(
                  '${_selectedEquipment.length + (_customEquipment.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.cyan, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only generate exercises with selected equipment',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._equipmentOptions.map((equipment) {
                final isSelected = _selectedEquipment.contains(equipment);
                return GestureDetector(
                  onTap: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedEquipment.remove(equipment);
                            } else {
                              _selectedEquipment.add(equipment);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.cyan.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.cyan : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.cyan),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          equipment,
                          style: TextStyle(
                            color: isSelected ? colors.cyan : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () => setState(() => _showEquipmentInput = !_showEquipmentInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customEquipment.isNotEmpty
                        ? colors.cyan.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customEquipment.isNotEmpty
                          ? colors.cyan
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customEquipment.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showEquipmentInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customEquipment.isNotEmpty ? colors.cyan : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customEquipment.isNotEmpty ? _customEquipment : 'Other',
                        style: TextStyle(
                          color: _customEquipment.isNotEmpty ? colors.cyan : colors.textSecondary,
                          fontWeight: _customEquipment.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showEquipmentInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _equipmentController,
              decoration: InputDecoration(
                hintText: 'Enter custom equipment',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cyan),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.cyan),
                  onPressed: () {
                    setState(() {
                      _customEquipment = _equipmentController.text.trim();
                      _showEquipmentInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customEquipment = value.trim();
                  _showEquipmentInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFocusAreasSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, size: 20, color: colors.purple),
              const SizedBox(width: 8),
              Text(
                'Focus Areas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedFocusAreas.isNotEmpty || _customFocusArea.isNotEmpty)
                Text(
                  '${_selectedFocusAreas.length + (_customFocusArea.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.purple, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._focusAreas.map((area) {
                final isSelected = _selectedFocusAreas.contains(area);
                return GestureDetector(
                  onTap: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedFocusAreas.remove(area);
                            } else {
                              _selectedFocusAreas.add(area);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.purple.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.purple : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.purple),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          area,
                          style: TextStyle(
                            color: isSelected ? colors.purple : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () => setState(() => _showFocusAreaInput = !_showFocusAreaInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customFocusArea.isNotEmpty
                        ? colors.purple.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customFocusArea.isNotEmpty
                          ? colors.purple
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customFocusArea.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFocusAreaInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customFocusArea.isNotEmpty ? colors.purple : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customFocusArea.isNotEmpty ? _customFocusArea : 'Other',
                        style: TextStyle(
                          color: _customFocusArea.isNotEmpty ? colors.purple : colors.textSecondary,
                          fontWeight: _customFocusArea.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showFocusAreaInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _focusAreaController,
              decoration: InputDecoration(
                hintText: 'Enter custom focus area',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.purple),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.purple),
                  onPressed: () {
                    setState(() {
                      _customFocusArea = _focusAreaController.text.trim();
                      _showFocusAreaInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customFocusArea = value.trim();
                  _showFocusAreaInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInjuriesSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 20, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Injuries to Consider',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedInjuries.isNotEmpty || _customInjury.isNotEmpty)
                Text(
                  '${_selectedInjuries.length + (_customInjury.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI will avoid exercises that may aggravate these areas',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._injuries.map((injury) {
                final isSelected = _selectedInjuries.contains(injury);
                return GestureDetector(
                  onTap: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedInjuries.remove(injury);
                            } else {
                              _selectedInjuries.add(injury);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.error.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.error : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.error),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          injury,
                          style: TextStyle(
                            color: isSelected ? colors.error : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () => setState(() => _showInjuryInput = !_showInjuryInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customInjury.isNotEmpty
                        ? colors.error.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customInjury.isNotEmpty
                          ? colors.error
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customInjury.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showInjuryInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customInjury.isNotEmpty ? colors.error : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customInjury.isNotEmpty ? _customInjury : 'Other',
                        style: TextStyle(
                          color: _customInjury.isNotEmpty ? colors.error : colors.textSecondary,
                          fontWeight: _customInjury.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showInjuryInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _injuryController,
              decoration: InputDecoration(
                hintText: 'Enter custom injury',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.error),
                  onPressed: () {
                    setState(() {
                      _customInjury = _injuryController.text.trim();
                      _showInjuryInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customInjury = value.trim();
                  _showInjuryInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdateButton(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _updateProgram,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.cyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isUpdating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Updating Program...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Update & Regenerate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.orange;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.cyan;
    }
  }
}

/// Theme colors interface for the sheet
abstract class _SheetColors {
  Color get elevated;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get cardBorder;
  Color get glassSurface;
  Color get cyan;
  Color get purple;
  Color get orange;
  Color get success;
  Color get error;
}

/// Dark theme colors for the sheet
class _DarkColors implements _SheetColors {
  @override Color get elevated => AppColors.elevated;
  @override Color get textPrimary => AppColors.textPrimary;
  @override Color get textSecondary => AppColors.textSecondary;
  @override Color get textMuted => AppColors.textMuted;
  @override Color get cardBorder => AppColors.cardBorder;
  @override Color get glassSurface => AppColors.glassSurface;
  @override Color get cyan => AppColors.cyan;
  @override Color get purple => AppColors.purple;
  @override Color get orange => AppColors.orange;
  @override Color get success => AppColors.success;
  @override Color get error => AppColors.error;
}

/// Light theme colors for the sheet
class _LightColors implements _SheetColors {
  @override Color get elevated => AppColorsLight.elevated;
  @override Color get textPrimary => AppColorsLight.textPrimary;
  @override Color get textSecondary => AppColorsLight.textSecondary;
  @override Color get textMuted => AppColorsLight.textMuted;
  @override Color get cardBorder => AppColorsLight.cardBorder;
  @override Color get glassSurface => AppColorsLight.glassSurface;
  @override Color get cyan => AppColorsLight.cyan;
  @override Color get purple => AppColors.purple;
  @override Color get orange => AppColors.orange;
  @override Color get success => AppColorsLight.success;
  @override Color get error => AppColorsLight.error;
}
