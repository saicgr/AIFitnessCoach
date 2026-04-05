part of 'edit_program_sheet.dart';


class _EditProgramSheetState extends ConsumerState<_EditProgramSheet> {
  // Wizard step (0-3)
  int _currentStep = 0;
  static const int _totalSteps = 4;

  bool _isUpdating = false;
  bool _isLoading = false;
  String _updateStatus = '';

  // Streaming progress state
  int _generatingWorkout = 0;
  int _totalWorkoutsToGenerate = 0;
  String? _generatingDetail;

  // Step 1: Schedule
  final Set<int> _selectedDays = {0, 2, 4}; // Default: Mon, Wed, Fri
  String _selectedDifficulty = 'medium';
  double _selectedDurationMin = 45;
  double _selectedDurationMax = 60;
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
  int _kettlebellCount = 2;

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
              final duration = prefs.durationMinutes!.toDouble().clamp(15.0, 90.0);
              _selectedDurationMin = duration;
              _selectedDurationMax = (duration + 15).clamp(15.0, 90.0);
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

            // Load equipment quantities
            if (prefs.dumbbellCount != null) {
              _dumbbellCount = prefs.dumbbellCount!;
            }
            if (prefs.kettlebellCount != null) {
              _kettlebellCount = prefs.kettlebellCount!;
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
      _generatingWorkout = 0;
      _totalWorkoutsToGenerate = 0;
      _generatingDetail = null;
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

      // Update preferences and delete old workouts
      await repo.updateProgramAndRegenerate(
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutesMin: _selectedDurationMin.round(),
        durationMinutesMax: _selectedDurationMax.round(),
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

      // Close sheet immediately - workouts will be generated on-demand when user visits home
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _updateStatus = '';
          _generatingWorkout = 0;
          _totalWorkoutsToGenerate = 0;
          _generatingDetail = null;
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

  Future<void> _showProgramHistory() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view program history')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final history = await workoutRepo.getProgramHistory(userId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (history.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No program history found')),
        );
        return;
      }

      // Show history dialog
      await showGlassSheet(
        context: context,
        builder: (ctx) => GlassSheet(
          child: _ProgramHistorySheet(
            history: history,
            onRestore: (programId) async {
              Navigator.pop(ctx); // Close history sheet
              await _restoreProgram(userId, programId);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  Future<void> _restoreProgram(String userId, String programId) async {
    setState(() {
      _isUpdating = true;
      _updateStatus = 'Restoring program...';
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      await workoutRepo.restoreProgram(userId, programId);

      // Reload preferences to update the UI
      await _loadPreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program restored! Regenerate workouts to apply changes.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _updateStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;

    return GlassSheet(
      maxHeightFraction: 0.95,
      showHandle: false,
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
    );
  }

  Widget _buildHeader(SheetColors colors) {
    final stepTitles = ['Schedule', 'Training Program', 'Equipment', 'Health'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: colors.purple, size: 24),
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
          const SizedBox(height: 12),
          // Info tooltip explaining what this sheet does
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.cyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Change your weekly schedule, equipment, or difficulty. Your workouts will be regenerated based on your new settings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.cyan,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
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
                  DurationRangeSlider(
                    durationMin: _selectedDurationMin,
                    durationMax: _selectedDurationMax,
                    onChanged: (range) => setState(() {
                      _selectedDurationMin = range.start;
                      _selectedDurationMax = range.end;
                    }),
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

  void _showCustomProgramSheet(SheetColors colors) {
    HapticFeedback.mediumImpact();
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: _CustomProgramInputSheet(
          initialDescription: _customProgramDescription,
          onSave: (description) {
            setState(() {
              _customProgramDescription = description;
              _selectedProgramId = 'custom';
            });
          },
          colors: colors,
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar when generating workouts
          if (_isUpdating && _totalWorkoutsToGenerate > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _generatingWorkout / _totalWorkoutsToGenerate,
                backgroundColor: colors.glassSurface,
                valueColor: AlwaysStoppedAnimation<Color>(colors.cyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _generatingDetail ?? _updateStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '$_generatingWorkout of $_totalWorkoutsToGenerate',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
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
                                _totalWorkoutsToGenerate > 0
                                    ? _updateStatus
                                    : (_updateStatus.isNotEmpty
                                        ? _updateStatus
                                        : 'Updating...'),
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
        ],
      ),
    );
  }
}

