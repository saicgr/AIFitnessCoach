import 'dart:ui';
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
  // Wizard step (0-2)
  int _currentStep = 0;
  static const int _totalSteps = 3;

  bool _isUpdating = false;
  bool _isLoading = true;
  String _updateStatus = ''; // Status message during update

  // Step 1: Schedule
  final Set<int> _selectedDays = {};
  String _selectedDifficulty = 'medium';
  double _selectedDuration = 45;
  int _programWeeks = 4; // Program duration in weeks (1, 2, 4, 8, 12)

  // Step 2: Workout Type & Focus
  String? _selectedWorkoutType;
  final Set<String> _selectedFocusAreas = {};
  final Set<String> _selectedEquipment = {};

  // Step 3: Health (optional)
  final Set<String> _selectedInjuries = {};
  final TextEditingController _customInjuryController = TextEditingController();
  bool _showCustomInjuryField = false;

  // Custom "Other" inputs
  String _customWorkoutType = '';
  String _customFocusArea = '';
  bool _showWorkoutTypeInput = false;
  bool _showFocusAreaInput = false;
  final TextEditingController _workoutTypeController = TextEditingController();
  final TextEditingController _focusAreaController = TextEditingController();

  // Equipment quantity selectors
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];
  final List<String> _workoutTypes = ['Strength', 'HIIT', 'Cardio', 'Flexibility', 'Full Body', 'Upper Body', 'Lower Body', 'Core'];
  final List<String> _focusAreas = ['Chest', 'Back', 'Shoulders', 'Arms', 'Core', 'Legs', 'Glutes', 'Full Body'];
  final List<String> _equipmentOptions = ['Full Gym', 'Dumbbells', 'Barbell', 'Kettlebell', 'Resistance Bands', 'Pull-up Bar', 'Bench', 'Cable Machine', 'Bodyweight Only'];
  final List<String> _injuries = ['Shoulder', 'Lower Back', 'Knee', 'Elbow', 'Wrist', 'Ankle', 'Hip', 'Neck'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _customInjuryController.dispose();
    _workoutTypeController.dispose();
    _focusAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
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
            if (prefs.difficulty != null) _selectedDifficulty = prefs.difficulty!.toLowerCase();
            if (prefs.durationMinutes != null) _selectedDuration = prefs.durationMinutes!.toDouble().clamp(15, 90);

            if (prefs.workoutType != null && prefs.workoutType!.isNotEmpty) {
              final normalizedType = _workoutTypes.firstWhere(
                (t) => t.toLowerCase() == prefs.workoutType!.toLowerCase(),
                orElse: () => '',
              );
              if (normalizedType.isNotEmpty) _selectedWorkoutType = normalizedType;
            }

            _selectedDays.clear();
            if (prefs.workoutDays.isNotEmpty) {
              final dayMap = {'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5, 'Sun': 6};
              for (final day in prefs.workoutDays) {
                final index = dayMap[day];
                if (index != null) _selectedDays.add(index);
              }
            } else {
              _selectedDays.addAll([0, 2, 4]);
            }

            _selectedEquipment.clear();
            for (final equip in prefs.equipment) {
              if (_equipmentOptions.contains(equip)) _selectedEquipment.add(equip);
            }

            _selectedFocusAreas.clear();
            for (final area in prefs.focusAreas) {
              if (_focusAreas.contains(area)) _selectedFocusAreas.add(area);
            }
            if (_selectedFocusAreas.isEmpty) _selectedFocusAreas.add('Full Body');

            _selectedInjuries.clear();
            for (final injury in prefs.injuries) {
              if (_injuries.contains(injury)) _selectedInjuries.add(injury);
            }
          } else {
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
          _selectedDays.addAll([0, 2, 4]);
          _selectedFocusAreas.add('Full Body');
        });
      }
    }
  }

  Future<void> _updateProgram() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one workout day'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateStatus = 'Saving preferences...';
    });

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _isUpdating = false;
        _updateStatus = '';
      });
      return;
    }

    try {
      final selectedDayNames = _selectedDays.map((i) => _dayNames[i]).toList();

      final repo = ref.read(workoutRepositoryProvider);

      // Step 1: Update preferences and delete old workouts
      await repo.updateProgramAndRegenerate(
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutes: _selectedDuration.round(),
        focusAreas: _selectedFocusAreas.toList(),
        injuries: _selectedInjuries.toList(),
        equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
        workoutType: _selectedWorkoutType,
        workoutDays: selectedDayNames,
        dumbbellCount: _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null,
        kettlebellCount: _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null,
      );

      if (mounted) {
        setState(() => _updateStatus = 'Generating first week...');
      }

      // Step 2: Generate just 1 week immediately for fast response
      final today = DateTime.now().toIso8601String().split('T')[0];
      await repo.generateMonthlyWorkouts(
        userId: userId,
        selectedDays: _selectedDays.toList(),
        durationMinutes: _selectedDuration.round(),
        weeks: 1, // Only generate 1 week initially
        monthStartDate: today,
      );

      // Step 3: If user wants more than 1 week, schedule background generation
      if (_programWeeks > 1) {
        // Store remaining weeks to generate in user preferences for background job
        await repo.scheduleRemainingWorkouts(
          userId: userId,
          selectedDays: _selectedDays.toList(),
          durationMinutes: _selectedDuration.round(),
          totalWeeks: _programWeeks,
          weeksGenerated: 1,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _updateStatus = '';
        });

        // Provide user-friendly error messages
        String errorMessage = 'Failed to update program';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
          errorMessage = 'Request timed out. The server may be busy. Please try again.';
        } else if (errorStr.contains('connection') || errorStr.contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one workout day'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _updateProgram();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? _DarkColors() : _LightColors();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: isDark
                ? colors.elevated.withOpacity(0.85)
                : colors.elevated.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            Divider(height: 1, color: colors.cardBorder),
            _buildProgressIndicator(colors),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colors.cyan))
                  : _buildCurrentStep(colors),
            ),
            _buildNavigationButtons(colors),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildHeader(_SheetColors colors) {
    final stepTitles = ['Schedule', 'Workout Type', 'Health'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune, color: colors.cyan, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Program',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps: ${stepTitles[_currentStep]}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isUpdating ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? colors.cyan : colors.glassSurface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(_SheetColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildScheduleStep(colors);
      case 1:
        return _buildWorkoutTypeStep(colors);
      case 2:
        return _buildHealthStep(colors);
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Schedule
  Widget _buildScheduleStep(_SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Days
          _buildSectionTitle(colors, Icons.calendar_month, 'Workout Days', '${_selectedDays.length} days/week'),
          const SizedBox(height: 8),
          Text('Select which days you want to work out', style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedDays.remove(index);
                  } else {
                    _selectedDays.add(index);
                  }
                }),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.cyan.withOpacity(0.2) : colors.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? colors.cyan : colors.cardBorder, width: isSelected ? 2 : 1),
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

          const SizedBox(height: 32),

          // Difficulty
          _buildSectionTitle(colors, Icons.speed, 'Difficulty', null),
          const SizedBox(height: 12),
          Row(
            children: _difficulties.map((difficulty) {
              final isSelected = _selectedDifficulty == difficulty;
              final color = _getDifficultyColor(difficulty);
              final icon = _getDifficultyIcon(difficulty);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: difficulty != _difficulties.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDifficulty = difficulty),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : colors.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? color : colors.cardBorder.withOpacity(0.3), width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 16, color: isSelected ? color : colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            difficulty[0].toUpperCase() + difficulty.substring(1),
                            style: TextStyle(color: isSelected ? color : colors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Duration
          _buildSectionTitle(colors, Icons.timer_outlined, 'Duration', '${_selectedDuration.round()} min'),
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
              onChanged: (value) => setState(() => _selectedDuration = value),
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

          const SizedBox(height: 32),

          // Program Duration
          _buildSectionTitle(colors, Icons.date_range, 'Program Duration', _getProgramDurationLabel()),
          const SizedBox(height: 8),
          Text('How far ahead to schedule workouts', style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationOption(colors, 1, '1 Week'),
              _buildDurationOption(colors, 2, '2 Weeks'),
              _buildDurationOption(colors, 4, '1 Month'),
              _buildDurationOption(colors, 8, '2 Months'),
              _buildDurationOption(colors, 12, '3 Months'),
            ],
          ),
        ],
      ),
    );
  }

  String _getProgramDurationLabel() {
    if (_programWeeks <= 1) return '1 week';
    if (_programWeeks <= 4) return '$_programWeeks weeks';
    return '${(_programWeeks / 4).round()} months';
  }

  Widget _buildDurationOption(_SheetColors colors, int weeks, String label) {
    final isSelected = _programWeeks == weeks;
    return GestureDetector(
      onTap: () => setState(() => _programWeeks = weeks),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.purple.withOpacity(0.2) : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.purple : colors.cardBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.purple : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // STEP 2: Workout Type & Focus
  Widget _buildWorkoutTypeStep(_SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Type (Optional)
          _buildSectionTitle(colors, Icons.category, 'Workout Type', 'Optional'),
          const SizedBox(height: 8),
          Text('Leave unselected for variety', style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._workoutTypes.map((type) {
                final isSelected = _selectedWorkoutType == type;
                return _buildChip(colors, type, isSelected, colors.purple, () {
                  setState(() => _selectedWorkoutType = isSelected ? null : type);
                });
              }),
              // "Other" chip for workout type
              GestureDetector(
                onTap: () => setState(() => _showWorkoutTypeInput = !_showWorkoutTypeInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customWorkoutType.isNotEmpty ? colors.purple.withOpacity(0.2) : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customWorkoutType.isNotEmpty ? colors.purple : colors.cardBorder.withOpacity(0.3),
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
          // Custom workout type input field
          if (_showWorkoutTypeInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _workoutTypeController,
              decoration: InputDecoration(
                hintText: 'Enter custom workout type (e.g., "Boxing")',
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
                      _selectedWorkoutType = _customWorkoutType.isNotEmpty ? _customWorkoutType : null;
                      _showWorkoutTypeInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customWorkoutType = value.trim();
                  _selectedWorkoutType = _customWorkoutType.isNotEmpty ? _customWorkoutType : null;
                  _showWorkoutTypeInput = false;
                });
              },
            ),
          ],

          const SizedBox(height: 32),

          // Equipment
          _buildSectionTitle(colors, Icons.fitness_center, 'Equipment', _selectedEquipment.isNotEmpty ? '${_selectedEquipment.length} selected' : null),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentOptions.map((equip) {
              final isSelected = _selectedEquipment.contains(equip);
              final bool hasQuantitySelector = equip == 'Dumbbells' || equip == 'Kettlebell';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (equip == 'Full Gym') {
                      // Full Gym selects all equipment except Bodyweight Only
                      if (isSelected) {
                        _selectedEquipment.remove('Full Gym');
                      } else {
                        _selectedEquipment.add('Full Gym');
                        _selectedEquipment.addAll(_equipmentOptions.where((e) =>
                          e != 'Bodyweight Only' && e != 'Full Gym'));
                      }
                    } else if (isSelected) {
                      _selectedEquipment.remove(equip);
                      // Also remove Full Gym if any equipment is deselected
                      _selectedEquipment.remove('Full Gym');
                    } else {
                      _selectedEquipment.add(equip);
                      // Check if all equipment selected (except Bodyweight Only and Full Gym)
                      final allEquipment = _equipmentOptions.where((e) =>
                        e != 'Bodyweight Only' && e != 'Full Gym');
                      if (allEquipment.every((e) => _selectedEquipment.contains(e))) {
                        _selectedEquipment.add('Full Gym');
                      }
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
                        equip,
                        style: TextStyle(
                          color: isSelected ? colors.cyan : colors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      // Quantity selector for Dumbbells and Kettlebell
                      if (hasQuantitySelector && isSelected) ...[
                        const SizedBox(width: 8),
                        _buildQuantitySelector(
                          equip == 'Dumbbells' ? _dumbbellCount : _kettlebellCount,
                          (newValue) {
                            setState(() {
                              if (equip == 'Dumbbells') {
                                _dumbbellCount = newValue;
                              } else {
                                _kettlebellCount = newValue;
                              }
                            });
                          },
                          colors,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Focus Areas
          _buildSectionTitle(colors, Icons.track_changes, 'Focus Areas', _selectedFocusAreas.isNotEmpty ? '${_selectedFocusAreas.length} selected' : null),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._focusAreas.map((area) {
                final isSelected = _selectedFocusAreas.contains(area);
                return _buildChip(colors, area, isSelected, colors.purple, () {
                  setState(() {
                    if (isSelected) {
                      _selectedFocusAreas.remove(area);
                    } else {
                      _selectedFocusAreas.add(area);
                    }
                  });
                });
              }),
              // "Other" chip for focus areas
              GestureDetector(
                onTap: () => setState(() => _showFocusAreaInput = !_showFocusAreaInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customFocusArea.isNotEmpty ? colors.purple.withOpacity(0.2) : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customFocusArea.isNotEmpty ? colors.purple : colors.cardBorder.withOpacity(0.3),
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
          // Custom focus area input field
          if (_showFocusAreaInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _focusAreaController,
              decoration: InputDecoration(
                hintText: 'Enter custom focus area (e.g., "Rotator cuff")',
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
                      if (_customFocusArea.isNotEmpty) {
                        _selectedFocusAreas.add(_customFocusArea);
                      }
                      _showFocusAreaInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customFocusArea = value.trim();
                  if (_customFocusArea.isNotEmpty) {
                    _selectedFocusAreas.add(_customFocusArea);
                  }
                  _showFocusAreaInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(int currentValue, Function(int) onChanged, _SheetColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentValue <= 1 ? null : () => onChanged(currentValue - 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 14,
                color: currentValue <= 1 ? colors.textMuted : colors.cyan,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentValue',
              style: TextStyle(
                color: colors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: currentValue >= 2 ? null : () => onChanged(currentValue + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 14,
                color: currentValue >= 2 ? colors.textMuted : colors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Health (Optional)
  Widget _buildHealthStep(_SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This step is optional. You can skip it if you have no injuries to report.',
                    style: TextStyle(fontSize: 13, color: colors.success),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(colors, Icons.healing, 'Injuries to Consider', _selectedInjuries.isNotEmpty ? '${_selectedInjuries.length} selected' : 'None'),
          const SizedBox(height: 8),
          Text('AI will avoid exercises that may aggravate these areas', style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._injuries.map((injury) {
                final isSelected = _selectedInjuries.contains(injury);
                return _buildChip(colors, injury, isSelected, colors.error, () {
                  setState(() {
                    if (isSelected) {
                      _selectedInjuries.remove(injury);
                    } else {
                      _selectedInjuries.add(injury);
                    }
                  });
                });
              }),
              // Other chip
              _buildChip(colors, '+ Other', _showCustomInjuryField, colors.orange, () {
                setState(() => _showCustomInjuryField = !_showCustomInjuryField);
              }),
            ],
          ),

          // Custom injury input field
          if (_showCustomInjuryField) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customInjuryController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter injury/condition',
                      hintStyle: TextStyle(color: colors.textMuted),
                      filled: true,
                      fillColor: colors.glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (value) => _addCustomInjury(colors),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addCustomInjury(colors),
                  icon: Icon(Icons.add_circle, color: colors.cyan),
                  tooltip: 'Add',
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.glassSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 12),
                _buildSummaryRow(colors, 'Days', _selectedDays.map((i) => _dayNames[i]).join(', ')),
                _buildSummaryRow(colors, 'Difficulty', _selectedDifficulty[0].toUpperCase() + _selectedDifficulty.substring(1)),
                _buildSummaryRow(colors, 'Duration', '${_selectedDuration.round()} minutes'),
                if (_selectedWorkoutType != null) _buildSummaryRow(colors, 'Type', _selectedWorkoutType!),
                if (_selectedEquipment.isNotEmpty) _buildSummaryRow(colors, 'Equipment', _selectedEquipment.join(', ')),
                if (_selectedFocusAreas.isNotEmpty) _buildSummaryRow(colors, 'Focus', _selectedFocusAreas.join(', ')),
                if (_selectedInjuries.isNotEmpty) _buildSummaryRow(colors, 'Injuries', _selectedInjuries.join(', ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomInjury(_SheetColors colors) {
    final value = _customInjuryController.text.trim();
    if (value.isNotEmpty && !_selectedInjuries.contains(value)) {
      setState(() {
        _selectedInjuries.add(value);
        _customInjuryController.clear();
      });
    }
  }

  Widget _buildSummaryRow(_SheetColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 13, color: colors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(_SheetColors colors) {
    // Account for floating nav bar (56px) + its bottom margin (16px) + extra spacing (16px)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 88;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUpdating ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back', style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _updateStatus.isNotEmpty ? _updateStatus : 'Updating...',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _currentStep < _totalSteps - 1 ? 'Continue' : 'Update & Regenerate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionTitle(_SheetColors colors, IconData icon, String title, String? badge) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.cyan),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: colors.textPrimary)),
        if (badge != null) ...[
          const Spacer(),
          Text(badge, style: TextStyle(color: colors.cyan, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildChip(_SheetColors colors, String label, bool isSelected, Color accentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? accentColor : colors.cardBorder.withOpacity(0.3), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: accentColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
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

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.check_circle_outline;
      case 'medium':
        return Icons.change_history;
      case 'hard':
        return Icons.star_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

/// Theme colors interface
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
