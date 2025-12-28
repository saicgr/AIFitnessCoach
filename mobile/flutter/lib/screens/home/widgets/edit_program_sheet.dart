import 'dart:ui';
import 'package:flutter/material.dart';
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
  // Wizard step (0-2)
  int _currentStep = 0;
  static const int _totalSteps = 3;

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
    final stepTitles = ['Schedule', 'Training Program', 'Health'];
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
        return _buildWorkoutTypeStep(colors);
      case 2:
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

  Widget _buildWorkoutTypeStep(SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Training Program Selector (horizontal scrolling cards)
          TrainingProgramSelector(
            selectedProgramId: _selectedProgramId,
            onSelectionChanged: (programId) =>
                setState(() => _selectedProgramId = programId),
            disabled: _isUpdating,
          ),
          const SizedBox(height: 32),
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
                    defaultTrainingPrograms
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
