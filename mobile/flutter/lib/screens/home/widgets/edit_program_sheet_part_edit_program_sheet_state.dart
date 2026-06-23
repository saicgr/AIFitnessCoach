part of 'edit_program_sheet.dart';


class _EditProgramSheetState extends ConsumerState<_EditProgramSheet> {
  // Wizard step (0-5). The editor is now a unified, multi-section flow:
  //   0 Schedule     (days + difficulty + duration)
  //   1 Split        (AI Decides + AI-Powered presets)
  //   2 Per-day      (per training-day focus / duration / intensity / gym)
  //   3 Workout Type (Strength / Cardio / Mixed)
  //   4 Equipment    (equipment + focus areas)
  //   5 Health       (injuries + summary)
  int _currentStep = 0;
  static const int _totalSteps = 6;

  bool _isUpdating = false;
  bool _isLoading = false;
  String _updateStatus = '';

  // Streaming progress state
  int _generatingWorkout = 0;
  int _totalWorkoutsToGenerate = 0;
  String? _generatingDetail;

  // Step 0: Schedule
  final Set<int> _selectedDays = {0, 2, 4}; // Default: Mon, Wed, Fri
  String _selectedDifficulty = 'medium';
  double _selectedDurationMin = 45;
  double _selectedDurationMax = 60;
  // Program weeks removed - using automatic 2-week generation with auto-regeneration

  // Step 1: Training Split / Program
  // null or 'ai_decide' → let the coach choose the split.
  String? _selectedProgramId;
  String _customProgramDescription = ''; // For custom training program

  // Step 2: Per-day overrides (weekday int 0=Mon..6=Sun → override).
  late Map<int, WorkoutDayOverride> _dayOverrides;
  // The training day currently being edited in the per-day step.
  int? _editingDay;

  // Step 3: Workout Type (strength / cardio / mixed).
  String _selectedWorkoutType = 'mixed';

  // Step 4: Equipment + Focus
  final Set<String> _selectedFocusAreas = {'Full Body'};
  final Set<String> _selectedEquipment = {};

  // Step 5: Health (optional)
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

  // ── Change tracking for the "ask me each time" save flow ──────────────
  // Snapshot of program-affecting fields taken right after load. On save we
  // diff against this to decide whether to offer "Apply now".
  Set<int> _initialDays = {};
  String? _initialProgramId;
  String _initialWorkoutType = 'mixed';
  String _initialDifficulty = 'medium';
  int _initialDurationMin = 45;
  int _initialDurationMax = 60;
  Map<int, WorkoutDayOverride> _initialOverrides = {};
  Set<String> _initialEquipment = {};
  Set<String> _initialFocusAreas = {};
  Set<String> _initialInjuries = {};

  @override
  void initState() {
    super.initState();
    _dayOverrides = {};
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _focusAreaController.dispose();
    _injuryController.dispose();
    super.dispose();
  }

  /// Active gym profile (if any). Drives the gym-aware workout-days source so
  /// the home editor and Settings share ONE source of truth.
  GymProfile? get _activeProfile => ref.read(activeGymProfileProvider);

  Future<void> _loadPreferences() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final userId = user?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _selectedDays.addAll([0, 2, 4]);
        _selectedFocusAreas.add('Full Body');
        _snapshotInitialState();
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
            // Prefer the active gym profile's days so home + Settings agree.
            final profileDays = _activeProfile?.workoutDays;
            if (profileDays != null && profileDays.isNotEmpty) {
              _selectedDays.addAll(profileDays);
            } else if (prefs.workoutDays.isNotEmpty) {
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
            }
            if (_selectedDays.isEmpty) {
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

          // Per-day overrides live on the user record (preferences JSONB),
          // not in ProgramPreferences — load them directly from auth state.
          _dayOverrides = Map<int, WorkoutDayOverride>.from(
            user?.workoutDayOverrides ?? const <int, WorkoutDayOverride>{},
          );

          // Workout Type (Strength / Cardio / Mixed) is the user's
          // `workout_type_preference`, surfaced by the trainingPreferences
          // notifier — NOT ProgramPreferences.workoutType (that's the split).
          _selectedWorkoutType =
              ref.read(trainingPreferencesProvider).workoutType.value;

          _isLoading = false;
          _snapshotInitialState();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedDays.addAll([0, 2, 4]);
          _selectedFocusAreas.add('Full Body');
          _snapshotInitialState();
        });
      }
    }
  }

  /// Capture the post-load values so we can diff on save (change detection for
  /// the "Apply now?" confirm).
  void _snapshotInitialState() {
    _initialDays = Set<int>.from(_selectedDays);
    _initialProgramId = _selectedProgramId;
    _initialWorkoutType = _selectedWorkoutType;
    _initialDifficulty = _selectedDifficulty;
    _initialDurationMin = _selectedDurationMin.round();
    _initialDurationMax = _selectedDurationMax.round();
    _initialOverrides = Map<int, WorkoutDayOverride>.from(_dayOverrides);
    _initialEquipment = Set<String>.from(_selectedEquipment);
    _initialFocusAreas = Set<String>.from(_selectedFocusAreas);
    _initialInjuries = Set<String>.from(_selectedInjuries);
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  bool _overridesEqual(
      Map<int, WorkoutDayOverride> a, Map<int, WorkoutDayOverride> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// True when any program-affecting field changed since load.
  bool get _hasProgramChanges {
    return !_setEquals(_selectedDays, _initialDays) ||
        _selectedProgramId != _initialProgramId ||
        _selectedWorkoutType != _initialWorkoutType ||
        _selectedDifficulty != _initialDifficulty ||
        _selectedDurationMin.round() != _initialDurationMin ||
        _selectedDurationMax.round() != _initialDurationMax ||
        !_overridesEqual(_dayOverrides, _initialOverrides) ||
        !_setEquals(_selectedEquipment, _initialEquipment) ||
        !_setEquals(_selectedFocusAreas, _initialFocusAreas) ||
        !_setEquals(_selectedInjuries, _initialInjuries);
  }

  /// Persist gym-aware workout days. When an active gym profile exists, the
  /// days belong to THAT profile (mirrors settings_card `_saveWorkoutDays`),
  /// so home + Settings can't drift. Otherwise fall back to the global user
  /// preferences via the canonical update-program write below.
  Future<void> _persistWorkoutDaysToProfile(List<int> sortedDays) async {
    final activeProfile = _activeProfile;
    if (activeProfile == null) return; // global path handled by update-program
    await ref.read(gymProfilesProvider.notifier).updateProfile(
          activeProfile.id,
          GymProfileUpdate(workoutDays: sortedDays),
        );
  }

  /// Unified save: persist EVERYTHING with regenerate=false (pure write), then
  /// — if anything program-affecting changed — ask the user whether to apply
  /// now (delete today/upcoming so they regenerate under the new prefs).
  Future<void> _updateProgram() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProgramSheetPleaseSelectAtLeast),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateStatus = AppLocalizations.of(context)!.editProgramSheetSavingPreferences;
      _generatingWorkout = 0;
      _totalWorkoutsToGenerate = 0;
      _generatingDetail = null;
    });

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final userId = user?.id;

    if (userId == null) {
      setState(() {
        _isUpdating = false;
        _updateStatus = '';
      });
      return;
    }

    final didChange = _hasProgramChanges;

    try {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final sortedDays = _selectedDays.toList()..sort();
      final selectedDayNames = sortedDays.map((i) => dayNames[i]).toList();

      final repo = ref.read(workoutRepositoryProvider);

      // 1. Gym-aware days: write to the active profile when one exists (single
      //    source of truth shared with Settings).
      await _persistWorkoutDaysToProfile(sortedDays);

      // 2. Persist program preferences — pure write, NO regenerate. (The
      //    update-program endpoint also writes days to global prefs, which is
      //    the fallback when there's no active gym profile.)
      await repo.updateProgram(
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutesMin: _selectedDurationMin.round(),
        durationMinutesMax: _selectedDurationMax.round(),
        focusAreas: _selectedFocusAreas.toList(),
        injuries: _selectedInjuries.toList(),
        equipment:
            _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
        workoutType: _selectedProgramId == 'custom'
            ? 'custom'
            : (_selectedProgramId ?? 'ai_decide'),
        workoutDays: selectedDayNames,
        dumbbellCount:
            _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null,
        kettlebellCount:
            _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null,
        customProgramDescription: _selectedProgramId == 'custom'
            ? _customProgramDescription
            : null,
        regenerate: false,
      );

      // 3. Persist per-day overrides into the user preferences JSONB.
      await _persistDayOverrides(user, userId);

      // 4. Persist Workout Type (Strength / Cardio / Mixed). This lives on the
      //    user record via `workout_type_preference`, NOT update-program, so it
      //    routes through the trainingPreferences notifier (no-ops if unchanged).
      if (_selectedWorkoutType != _initialWorkoutType) {
        await ref
            .read(trainingPreferencesProvider.notifier)
            .setWorkoutType(WorkoutType.fromString(_selectedWorkoutType));
      }

      if (!mounted) return;

      // 5. "Ask me each time": only when something program-affecting changed.
      if (didChange) {
        final applyNow = await AppDialog.confirm(
          context,
          title: 'Apply now?',
          message:
              'Apply these changes to your upcoming workouts now? This regenerates today (if not started) and upcoming sessions.',
          confirmText: 'Apply now',
          cancelText: 'Later',
          icon: Icons.auto_awesome_rounded,
        );

        if (applyNow && mounted) {
          setState(() {
            _updateStatus = 'Applying changes…';
          });
          await repo.regenerateUpcoming(userId);
          // Refresh local state + home surfaces so the new sessions show.
          await ref.read(authStateProvider.notifier).refreshUser();
          TodayWorkoutNotifier.resetGenerationState();
          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
          ref.read(workoutsProvider.notifier).silentRefresh();
        }
      }

      // Close sheet. Returning `true` lets callers run their own refresh too.
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

        String errorMessage = AppLocalizations.of(context)!.editProgramSheetFailedToUpdateProgram;
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

  // ── Per-day override mutation helpers (used by _buildPerDayStep) ────────

  /// Set a single day's focus from the shared [PerDayControls].
  void _setOverrideFocus(int day, String focus) {
    setState(() {
      final existing = _dayOverrides[day];
      _dayOverrides[day] = existing == null
          ? WorkoutDayOverride(focus: focus)
          : existing.copyWith(focus: focus);
    });
  }

  /// "AI decide" for a day = remove its override entirely.
  void _clearOverride(int day) {
    setState(() => _dayOverrides.remove(day));
  }

  void _setOverrideDuration(int day, int? duration) {
    setState(() {
      final existing = _dayOverrides[day];
      if (existing == null) {
        if (duration == null) return;
        _dayOverrides[day] =
            WorkoutDayOverride(focus: 'full_body', durationMin: duration);
      } else {
        _dayOverrides[day] = duration == null
            ? existing.copyWith(clearDurationMin: true)
            : existing.copyWith(durationMin: duration);
      }
    });
  }

  void _setOverrideIntensity(int day, String? intensity) {
    setState(() {
      final existing = _dayOverrides[day];
      if (existing == null) {
        if (intensity == null) return;
        _dayOverrides[day] =
            WorkoutDayOverride(focus: 'full_body', intensity: intensity);
      } else {
        _dayOverrides[day] = intensity == null
            ? existing.copyWith(clearIntensity: true)
            : existing.copyWith(intensity: intensity);
      }
    });
  }

  void _setOverrideGym(int day, String? gymProfileId) {
    setState(() {
      final existing = _dayOverrides[day];
      if (existing == null) {
        if (gymProfileId == null) return;
        _dayOverrides[day] =
            WorkoutDayOverride(focus: 'full_body', gymProfileId: gymProfileId);
      } else {
        _dayOverrides[day] = gymProfileId == null
            ? existing.copyWith(clearGymProfileId: true)
            : existing.copyWith(gymProfileId: gymProfileId);
      }
    });
  }

  /// Merge the per-day overrides map into the user preferences JSONB and fire
  /// the optimistic auth-notifier update (same path the per-day sheet uses).
  Future<void> _persistDayOverrides(User? user, String userId) async {
    final payload = <String, dynamic>{};
    _dayOverrides.forEach((day, override) {
      payload[day.toString()] = override.toJson();
    });

    Map<String, dynamic> currentPrefs = {};
    if (user?.preferences != null && user!.preferences!.isNotEmpty) {
      try {
        final decoded = jsonDecode(user.preferences!);
        if (decoded is Map) {
          currentPrefs = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    final mergedPrefs = Map<String, dynamic>.from(currentPrefs);
    mergedPrefs['workout_day_overrides'] = payload;

    await ref.read(authStateProvider.notifier).updateUserProfile({
      'preferences': mergedPrefs,
    });
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProgramSheetPleaseSelectAtLeast),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.editProgramSheetPleaseLogInTo)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.editProgramSheetNoProgramHistoryFound)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.editProgramSheetFailedToLoadHistory(e.toString()))),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.editProgramSheetProgramRestoredRegenerateW),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.editProgramSheetFailedToRestore(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = [
      l10n.editProgramSheetSchedule,
      l10n.editProgramSheetTrainingProgram,
      'Per-day',
      'Workout Type',
      l10n.editProgramSheetEquipment,
      l10n.editProgramSheetHealth,
    ];
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
                      l10n.editProgramSheetCustomizeProgram,
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
                    l10n.editProgramSheetChangeYourWeeklySchedule,
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
        return _buildPerDayStep(colors);
      case 3:
        return _buildWorkoutTypeStep(colors);
      case 4:
        return _buildEquipmentStep(colors);
      case 5:
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
                      // Keep the per-day editor pointed at a valid day.
                      if (_editingDay != null &&
                          !_selectedDays.contains(_editingDay)) {
                        _editingDay = _selectedDays.isNotEmpty
                            ? (_selectedDays.toList()..sort()).first
                            : null;
                      }
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
                        Text(AppLocalizations.of(context)!.editProgramSheetBack, style: TextStyle(color: colors.textSecondary)),
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
                                        : AppLocalizations.of(context)!.editProgramSheetUpdating),
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
                              ? AppLocalizations.of(context)!.editProgramSheetContinue
                              : 'Save program',
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
