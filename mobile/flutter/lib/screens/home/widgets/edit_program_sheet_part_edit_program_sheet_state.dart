part of 'edit_program_sheet.dart';


class _EditProgramSheetState extends ConsumerState<_EditProgramSheet>
    with SingleTickerProviderStateMixin {
  // The editor is now a TABBED layout (replacing the old 6-step wizard).
  //   0 Schedule  — days + difficulty + duration + split ("Vibe") + workout type
  //   1 Per-day   — per training-day focus / duration / intensity / gym
  //   2 Equipment — equipment inventory (global Target Areas removed)
  //   3 Health    — injuries + summary
  // A beginner can finish entirely on the Schedule tab and tap Save.
  static const List<String> _tabLabels = [
    'Schedule',
    'Per-day',
    'Equipment',
    'Health',
  ];
  late final TabController _tabController;

  bool _isLoading = false;

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

  // Custom inputs ( focus-area custom input removed with the global Target
  // Areas selector — per-day Focus is the only focus control now).
  String _customInjury = '';
  bool _showInjuryInput = false;

  // Equipment quantities
  int _dumbbellCount = 2;
  int _kettlebellCount = 2;

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
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      // Repaint the sticky summary line / Save label as tabs change.
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  /// Instant-close + background save.
  ///
  /// Tapping Save closes the sheet IMMEDIATELY and persists in the background.
  /// Because the user explicitly tapped Save, that IS the "apply now" decision —
  /// if any program-affecting field changed we always regenerate upcoming in the
  /// background (no separate confirm dialog). If nothing program-affecting
  /// changed, we still persist the writes but skip the (expensive) regenerate.
  ///
  /// Dispose-proofing: all background work runs against the ROOT
  /// [appProviderContainer] (captured before pop), never the sheet's `ref` —
  /// the sheet's Element is disposed the moment we pop, so reading `ref` after
  /// that would throw. Snapshots of the user-edited values are captured into
  /// locals before pop too.
  Future<void> _updateProgram() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProgramSheetPleaseSelectAtLeast),
          backgroundColor: AppColors.error,
        ),
      );
      // Send the user to the Schedule tab where days live.
      _tabController.animateTo(0);
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final userId = user?.id;
    if (userId == null) return;

    // ── Capture everything the background save needs BEFORE we pop ──────────
    // After pop the sheet's Element is gone, so `ref` is invalid. The root
    // container survives the whole app session.
    final container = appProviderContainer;
    final didChange = _hasProgramChanges;
    final activeProfile = _activeProfile;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = _selectedDays.toList()..sort();
    final selectedDayNames = sortedDays.map((i) => dayNames[i]).toList();

    final difficulty = _selectedDifficulty;
    final durationMin = _selectedDurationMin.round();
    final durationMax = _selectedDurationMax.round();
    final injuries = _selectedInjuries.toList();
    final equipment =
        _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null;
    final workoutTypeSplit =
        _selectedProgramId == 'custom' ? 'custom' : (_selectedProgramId ?? 'ai_decide');
    final dumbbellCount =
        _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null;
    final kettlebellCount =
        _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null;
    final customProgramDescription =
        _selectedProgramId == 'custom' ? _customProgramDescription : null;
    final overridesPayload = <String, dynamic>{};
    _dayOverrides.forEach((day, override) {
      overridesPayload[day.toString()] = override.toJson();
    });
    final mergedPrefs = _mergedPreferences(user, overridesPayload);
    final workoutTypeChanged = _selectedWorkoutType != _initialWorkoutType;
    final newWorkoutType = WorkoutType.fromString(_selectedWorkoutType);

    // ── Instant close ───────────────────────────────────────────────────────
    if (mounted) {
      Navigator.pop(context, true);
    }
    // Toast via the ROOT messenger so it survives the sheet being popped.
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Program updated')),
    );

    if (container == null) {
      debugPrint('⚠️ [EditProgram] no root container — save skipped');
      return;
    }

    // ── Background persistence (dispose-proof, runs against root container) ──
    unawaited(() async {
      try {
        final repo = container.read(workoutRepositoryProvider);

        // Independent writes run in parallel:
        //   1. Gym-aware days → active profile (single source of truth shared
        //      with Settings) when a profile exists.
        //   2. Program preferences (pure write, NO regenerate). The
        //      update-program endpoint also writes days to global prefs (the
        //      fallback when there's no active gym profile). Global focusAreas
        //      are intentionally NOT sent — per-day Focus is the only focus
        //      control now, so days on "AI decide" fall back to split/AI.
        //   3. Per-day overrides → user preferences JSONB (awaited dict update).
        await Future.wait([
          if (activeProfile != null)
            container.read(gymProfilesProvider.notifier).updateProfile(
                  activeProfile.id,
                  GymProfileUpdate(workoutDays: sortedDays),
                ),
          repo.updateProgram(
            userId: userId,
            difficulty: difficulty,
            durationMinutesMin: durationMin,
            durationMinutesMax: durationMax,
            focusAreas: const [],
            injuries: injuries,
            equipment: equipment,
            workoutType: workoutTypeSplit,
            workoutDays: selectedDayNames,
            dumbbellCount: dumbbellCount,
            kettlebellCount: kettlebellCount,
            customProgramDescription: customProgramDescription,
            regenerate: false,
          ),
          container.read(authStateProvider.notifier).updateUserProfile({
            'preferences': mergedPrefs,
          }),
          // Workout Type (Strength / Cardio / Mixed) lives on the user record
          // via `workout_type_preference`; routes through trainingPreferences.
          if (workoutTypeChanged)
            container
                .read(trainingPreferencesProvider.notifier)
                .setWorkoutType(newWorkoutType),
        ]);

        // Save IS the apply: regenerate upcoming when anything program-affecting
        // changed; skip the expensive regen otherwise.
        if (didChange) {
          await repo.regenerateUpcoming(userId);
          await container.read(authStateProvider.notifier).refreshUser();
          TodayWorkoutNotifier.resetGenerationState();
          await refreshAfterWorkoutMutation(source: 'edit_program_save');
        }
      } catch (e) {
        debugPrint('⚠️ [EditProgram] background save failed: $e');
        final messenger = rootScaffoldMessengerKey.currentState;
        String msg = 'Couldn\'t update your program. Please try again.';
        final s = e.toString().toLowerCase();
        if (s.contains('timeout') || s.contains('timed out')) {
          msg = 'Request timed out. The server may be busy. Please try again.';
        } else if (s.contains('connection') || s.contains('network')) {
          msg = 'Network error. Please check your connection and try again.';
        }
        messenger?.showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }());
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

  /// Merge the per-day overrides [payload] into the user's existing preferences
  /// JSONB (so we don't clobber unrelated keys). Pure function — no side effects
  /// — so it's safe to call before pop and hand the result to the background
  /// save running on the root container.
  Map<String, dynamic> _mergedPreferences(
    User? user,
    Map<String, dynamic> payload,
  ) {
    Map<String, dynamic> currentPrefs = {};
    if (user?.preferences != null && user!.preferences!.isNotEmpty) {
      try {
        final decoded = jsonDecode(user.preferences!);
        if (decoded is Map) {
          currentPrefs = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    final merged = Map<String, dynamic>.from(currentPrefs);
    merged['workout_day_overrides'] = payload;
    return merged;
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
    setState(() => _isLoading = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      await workoutRepo.restoreProgram(userId, programId);

      // Reload preferences to update the UI ( _loadPreferences clears _isLoading)
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
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
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
            _buildTabBar(colors),
            Flexible(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.cyan))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildScheduleTab(colors),
                        _buildPerDayStep(colors),
                        _buildEquipmentStep(colors),
                        _buildHealthStep(colors),
                      ],
                    ),
            ),
            _buildSaveBar(colors),
          ],
        ),
      ),
    );
  }

  /// Horizontally-scrollable tab strip replacing the old per-step progress bar.
  Widget _buildTabBar(SheetColors colors) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: colors.cyan,
      unselectedLabelColor: colors.textMuted,
      indicatorColor: colors.cyan,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tabs: [for (final label in _tabLabels) Tab(text: label)],
    );
  }

  Widget _buildHeader(SheetColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
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
                const SizedBox(height: 2),
                Text(
                  'Tweak any tab — defaults are AI-chosen. Save when ready.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showProgramHistory,
            icon: Icon(Icons.history, color: colors.cyan),
            tooltip: 'Program History',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Schedule tab = weekly schedule + difficulty + duration, with the Split
  /// ("Vibe") and Workout-Type selectors folded in so a beginner can finish
  /// the whole setup here and tap Save.
  Widget _buildScheduleTab(SheetColors colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildScheduleStep(colors),
        const SizedBox(height: 24),
        _sectionTitle(colors, 'Vibe'),
        const SizedBox(height: 8),
        _buildTrainingProgramStep(colors),
        const SizedBox(height: 24),
        _sectionTitle(colors, 'Workout type'),
        const SizedBox(height: 8),
        _buildWorkoutTypeStep(colors),
      ],
    );
  }

  Widget _sectionTitle(SheetColors colors, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Schedule section content (non-scrolling — the Schedule tab's ListView owns
  /// scrolling). Days + difficulty + duration.
  Widget _buildScheduleStep(SheetColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkoutDaysSelector(
          selectedDays: _selectedDays,
          onSelectionChanged: (days) => setState(() {
            _selectedDays.clear();
            _selectedDays.addAll(days);
            // Keep the per-day editor pointed at a valid day.
            if (_editingDay != null && !_selectedDays.contains(_editingDay)) {
              _editingDay = _selectedDays.isNotEmpty
                  ? (_selectedDays.toList()..sort()).first
                  : null;
            }
          }),
        ),
        const SizedBox(height: 16),
        DifficultySelector(
          selectedDifficulty: _selectedDifficulty,
          onSelectionChanged: (d) => setState(() => _selectedDifficulty = d),
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
          accentColor: colors.success,
        ),
        // Program duration selector removed - using automatic 2-week generation
      ],
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
          ),
          // The global "Target Areas" selector was removed — per-day Focus
          // (Per-day tab) is now the only focus control. Days left on "AI
          // decide" fall back to the split / AI.
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

  Widget _buildSaveBar(SheetColors colors) {
    final summary = _condensedSummary();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky condensed summary line so the user always sees the gist
          // of the program no matter which tab they're on.
          if (summary.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 14, color: colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateProgram,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save program',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One-line gist of the current program for the sticky summary above Save.
  String _condensedSummary() {
    if (_selectedDays.isEmpty) return '';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = (_selectedDays.toList()..sort()).map((i) => dayNames[i]);
    final parts = <String>['${_selectedDays.length}× / wk'];
    final dur = _selectedDurationMin.round() == _selectedDurationMax.round()
        ? '${_selectedDurationMin.round()}m'
        : '${_selectedDurationMin.round()}–${_selectedDurationMax.round()}m';
    parts.add(dur);
    parts.add(days.join(' '));
    return parts.join(' · ');
  }
}
