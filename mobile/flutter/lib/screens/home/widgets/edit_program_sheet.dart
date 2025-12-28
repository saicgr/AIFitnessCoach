import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import 'components/components.dart';
// import 'program_history_screen.dart';

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
    useRootNavigator: true,
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
  // Wizard step (0-3)
  int _currentStep = 0;
  static const int _totalSteps = 4;

  bool _isUpdating = false;
  bool _isLoading = false;
  String _updateStatus = '';

  // Step 1: Schedule
  final Set<int> _selectedDays = {0, 2, 4}; // Default: Mon, Wed, Fri
  String _selectedDifficulty = 'medium';
  double _selectedDuration = 45;
  // Program weeks removed - using automatic 2-week generation with auto-regeneration

  // Step 2: Training Program & Equipment
  String? _selectedProgramId;
  String _customProgramDescription = ''; // For custom training program
  final Set<String> _selectedFocusAreas = {'Full Body'};
  final Set<String> _selectedEquipment = {};

  // Step 3: Health (optional)
  final Set<String> _selectedInjuries = {};

  // Custom inputs
  String _customFocusArea = '';
  String _customInjury = '';
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;

  // Equipment quantities
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _focusAreaController.dispose();
    _injuryController.dispose();
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
            if (prefs.difficulty != null) {
              _selectedDifficulty = prefs.difficulty!.toLowerCase();
            }
            if (prefs.durationMinutes != null) {
              _selectedDuration =
                  prefs.durationMinutes!.toDouble().clamp(15, 90);
            }

            // Load training split as program ID
            if (prefs.trainingSplit != null && prefs.trainingSplit!.isNotEmpty) {
              _selectedProgramId = prefs.trainingSplit;
            }

            _selectedDays.clear();
            if (prefs.workoutDays.isNotEmpty) {
              final dayMap = {
                'Mon': 0,
                'Tue': 1,
                'Wed': 2,
                'Thu': 3,
                'Fri': 4,
                'Sat': 5,
                'Sun': 6
              };
              for (final day in prefs.workoutDays) {
                final index = dayMap[day];
                if (index != null) _selectedDays.add(index);
              }
            } else {
              _selectedDays.addAll([0, 2, 4]);
            }

            _selectedEquipment.clear();
            for (final equip in prefs.equipment) {
              if (defaultEquipmentOptions.contains(equip)) {
                _selectedEquipment.add(equip);
              }
            }

            _selectedFocusAreas.clear();
            for (final area in prefs.focusAreas) {
              if (defaultFocusAreas.contains(area)) {
                _selectedFocusAreas.add(area);
              }
            }
            if (_selectedFocusAreas.isEmpty) {
              _selectedFocusAreas.add('Full Body');
            }

            _selectedInjuries.clear();
            for (final injury in prefs.injuries) {
              if (defaultInjuries.contains(injury)) {
                _selectedInjuries.add(injury);
              }
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
        const SnackBar(
          content: Text('Please select at least one workout day'),
          backgroundColor: AppColors.error,
        ),
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
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final selectedDayNames = _selectedDays.map((i) => dayNames[i]).toList();

      final repo = ref.read(workoutRepositoryProvider);

      // Step 1: Update preferences and delete old workouts
      await repo.updateProgramAndRegenerate(
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutes: _selectedDuration.round(),
        focusAreas: _selectedFocusAreas.toList(),
        injuries: _selectedInjuries.toList(),
        equipment:
            _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
        workoutType: _selectedProgramId, // Send training program ID
        workoutDays: selectedDayNames,
        dumbbellCount:
            _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null,
        kettlebellCount:
            _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null,
        customProgramDescription: _selectedProgramId == 'custom'
            ? _customProgramDescription
            : null,
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
        weeks: 1,
        monthStartDate: today,
      );

      // Step 3: Schedule background generation for second week
      // Auto-regeneration system will handle ongoing workout creation beyond 2 weeks
      await repo.scheduleRemainingWorkouts(
        userId: userId,
        selectedDays: _selectedDays.toList(),
        durationMinutes: _selectedDuration.round(),
        totalWeeks: 2, // Always generate 2 weeks initially
        weeksGenerated: 1,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _updateStatus = '';
        });

        String errorMessage = 'Failed to update program';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
          errorMessage =
              'Request timed out. The server may be busy. Please try again.';
        } else if (errorStr.contains('connection') ||
            errorStr.contains('network')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one workout day'),
          backgroundColor: AppColors.error,
        ),
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

  void _showProgramHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program history coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
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
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colors),
                Divider(height: 1, color: colors.cardBorder),
                _buildProgressIndicator(colors),
                Flexible(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: colors.cyan))
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

  Widget _buildHeader(SheetColors colors) {
    final stepTitles = ['Schedule', 'Training Program', 'Equipment', 'Health'];
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isUpdating ? null : _showProgramHistory,
            icon: Icon(Icons.history, color: colors.cyan),
            tooltip: 'Program History',
          ),
          IconButton(
            onPressed: _isUpdating ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
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

  Widget _buildCurrentStep(SheetColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildScheduleStep(colors);
      case 1:
        return _buildTrainingProgramStep(colors);
      case 2:
        return _buildEquipmentStep(colors);
      case 3:
        return _buildHealthStep(colors);
      default:
        return const SizedBox();
    }
  }

  Widget _buildScheduleStep(SheetColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WorkoutDaysSelector(
                    selectedDays: _selectedDays,
                    onSelectionChanged: (days) => setState(() {
                      _selectedDays.clear();
                      _selectedDays.addAll(days);
                    }),
                    disabled: _isUpdating,
                  ),
                  const SizedBox(height: 16),
                  DifficultySelector(
                    selectedDifficulty: _selectedDifficulty,
                    onSelectionChanged: (d) =>
                        setState(() => _selectedDifficulty = d),
                    disabled: _isUpdating,
                    fitnessLevel: ref.read(authStateProvider).user?.fitnessLevel,
                  ),
                  const SizedBox(height: 16),
                  DurationSlider(
                    duration: _selectedDuration,
                    onChanged: (d) => setState(() => _selectedDuration = d),
                    disabled: _isUpdating,
                    accentColor: colors.success,
                  ),
                  // Program duration selector removed - using automatic 2-week generation
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainingProgramStep(SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info text
          Text(
            'Choose a training split that fits your schedule and goals',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Training Programs Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: defaultTrainingPrograms.length,
            itemBuilder: (context, index) {
              final program = defaultTrainingPrograms[index];
              final isSelected = _selectedProgramId == program.id;
              final isCustom = program.id == 'custom';
              final hasCustomDescription = _customProgramDescription.isNotEmpty;

              // For custom, show the description if set
              String displayDescription = program.description;
              if (isCustom && hasCustomDescription) {
                displayDescription = _customProgramDescription;
              }

              return GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () {
                        if (isCustom) {
                          _showCustomProgramSheet(colors);
                        } else {
                          setState(() => _selectedProgramId =
                              isSelected ? null : program.id);
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.purple.withOpacity(0.15)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colors.purple
                          : colors.cardBorder.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            program.icon,
                            size: 20,
                            color: isSelected
                                ? colors.purple
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              program.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.purple
                                    : colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          displayDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: isCustom && hasCustomDescription && isSelected
                                ? colors.purple.withOpacity(0.8)
                                : colors.textMuted,
                            height: 1.3,
                            fontStyle: isCustom && hasCustomDescription
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        program.daysPerWeek,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? colors.purple
                              : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCustomProgramSheet(SheetColors colors) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomProgramInputSheet(
        initialDescription: _customProgramDescription,
        onSave: (description) {
          setState(() {
            _customProgramDescription = description;
            _selectedProgramId = 'custom';
          });
        },
        colors: colors,
      ),
    );
  }

  Widget _buildEquipmentStep(SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EquipmentSelector(
            selectedEquipment: _selectedEquipment,
            onSelectionChanged: (eq) {
              setState(() {
                _selectedEquipment
                  ..clear()
                  ..addAll(eq);

                // When Full Gym is selected, set both counts to 2
                if (eq.contains('Full Gym')) {
                  _dumbbellCount = 2;
                  _kettlebellCount = 2;
                }
              });
            },
            customEquipment: '',
            showCustomInput: false,
            onToggleCustomInput: () {},
            onCustomEquipmentSaved: (_) {},
            dumbbellCount: _dumbbellCount,
            kettlebellCount: _kettlebellCount,
            onDumbbellCountChanged: (c) =>
                setState(() => _dumbbellCount = c),
            onKettlebellCountChanged: (c) =>
                setState(() => _kettlebellCount = c),
            disabled: _isUpdating,
          ),
          const SizedBox(height: 32),
          FocusAreasSelector(
            selectedAreas: _selectedFocusAreas,
            onSelectionChanged: (areas) =>
                setState(() => _selectedFocusAreas
                  ..clear()
                  ..addAll(areas)),
            customFocusArea: _customFocusArea,
            showCustomInput: _showFocusAreaInput,
            onToggleCustomInput: () =>
                setState(() => _showFocusAreaInput = !_showFocusAreaInput),
            onCustomFocusAreaSaved: (value) {
              setState(() {
                _customFocusArea = value;
                if (value.isNotEmpty) {
                  _selectedFocusAreas.add(value);
                }
                _showFocusAreaInput = false;
              });
            },
            customInputController: _focusAreaController,
            disabled: _isUpdating,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStep(SheetColors colors) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          InjuriesSelector(
            selectedInjuries: _selectedInjuries,
            onSelectionChanged: (injuries) =>
                setState(() => _selectedInjuries
                  ..clear()
                  ..addAll(injuries)),
            customInjury: _customInjury,
            showCustomInput: _showInjuryInput,
            onToggleCustomInput: () =>
                setState(() => _showInjuryInput = !_showInjuryInput),
            onCustomInjurySaved: (value) {
              setState(() {
                _customInjury = value;
                if (value.isNotEmpty) {
                  _selectedInjuries.add(value);
                }
                _showInjuryInput = false;
              });
            },
            customInputController: _injuryController,
            disabled: _isUpdating,
          ),
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
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  colors,
                  'Days',
                  _selectedDays.map((i) => dayNames[i]).join(', '),
                ),
                _buildSummaryRow(
                  colors,
                  'Difficulty',
                  _selectedDifficulty[0].toUpperCase() +
                      _selectedDifficulty.substring(1),
                ),
                _buildSummaryRow(
                  colors,
                  'Duration',
                  '${_selectedDuration.round()} minutes',
                ),
                // Program duration removed from summary - using automatic regeneration
                if (_selectedProgramId != null)
                  _buildSummaryRow(
                    colors,
                    'Program',
                    _selectedProgramId == 'custom' && _customProgramDescription.isNotEmpty
                        ? 'Custom: $_customProgramDescription'
                        : defaultTrainingPrograms
                            .firstWhere(
                              (p) => p.id == _selectedProgramId,
                              orElse: () => defaultTrainingPrograms.first,
                            )
                            .name,
                  ),
                if (_selectedEquipment.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Equipment',
                    _selectedEquipment.join(', '),
                  ),
                if (_selectedFocusAreas.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Focus',
                    _selectedFocusAreas.join(', '),
                  ),
                if (_selectedInjuries.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Injuries',
                    _selectedInjuries.join(', '),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(SheetColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    Text('Back', style: TextStyle(color: colors.textSecondary)),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _updateStatus.isNotEmpty
                                ? _updateStatus
                                : 'Updating...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _currentStep < _totalSteps - 1
                          ? 'Continue'
                          : 'Update & Regenerate',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Program Input Sheet - shown when user taps "Custom" training program
class _CustomProgramInputSheet extends StatefulWidget {
  final String? initialDescription;
  final ValueChanged<String> onSave;
  final SheetColors colors;

  const _CustomProgramInputSheet({
    this.initialDescription,
    required this.onSave,
    required this.colors,
  });

  @override
  State<_CustomProgramInputSheet> createState() =>
      _CustomProgramInputSheetState();
}

class _CustomProgramInputSheetState extends State<_CustomProgramInputSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  static const List<String> _examples = [
    'Train for HYROX competition',
    'Improve my box jump height',
    'Build explosive power for basketball',
    'Train for a marathon',
    'Get better at pull-ups',
    'Prepare for obstacle course racing',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Icon(Icons.tune, color: colors.purple, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Custom Program',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Describe what you want to train for and AI will create a personalized program.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Text input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g., "Train for HYROX competition"',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.glassSurface,
                  counterStyle: TextStyle(color: colors.textMuted),
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
                    borderSide: BorderSide(color: colors.purple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (_) => _saveAndClose(),
              ),
              const SizedBox(height: 16),

              // Examples
              Text(
                'Examples',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples.map((example) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = example;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: example.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasText ? _saveAndClose : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.purple.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Custom Program',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
