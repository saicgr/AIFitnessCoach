part of 'regenerate_workout_sheet.dart';


class _RegenerateWorkoutSheetState
    extends ConsumerState<_RegenerateWorkoutSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRegenerating = false;
  String _selectedDifficulty = 'medium';
  double _selectedDurationMin = 45;
  double _selectedDurationMax = 60;
  String? _selectedWorkoutType;
  final Set<String> _selectedFocusAreas = {};
  final Set<String> _selectedInjuries = {};
  final Set<String> _selectedEquipment = {};

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 4;
  String _progressMessage = '';
  String? _progressDetail;

  // Elapsed time tracking
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Rotating substatus hints so the UI never looks frozen during the long
  // Gemini call (step 3 can run 15–25s with no backend events).
  Timer? _hintRotationTimer;
  int _hintIndex = 0;

  // Hints appropriate for the phase the backend is currently in. Step 3
  // (AI generation) is the only truly slow phase, so it gets the richest set.
  static const Map<int, List<String>> _stepHints = {
    0: ['Warming up'],
    1: ['Reading your profile', 'Checking preferences', 'Loading injuries and goals'],
    2: [
      'Scanning the exercise library',
      'Filtering by your equipment',
      'Matching your fitness level',
      'Considering focus areas',
    ],
    3: [
      'Balancing muscle groups',
      'Dialing in sets and reps',
      'Sequencing compound lifts first',
      'Matching intensity to your difficulty',
      'Pairing push and pull work',
      'Respecting your injury list',
      'Tuning rest periods',
      'Adding variety to prevent plateaus',
    ],
    4: ['Saving to your plan', 'Updating your schedule'],
  };

  // Rough expected total generation time — used only for the "~Ns remaining"
  // hint so the user has a sense of pace.
  static const Duration _estimatedTotal = Duration(seconds: 22);

  // Custom inputs
  String _customFocusArea = '';
  String _customInjury = '';
  String _customEquipment = '';
  String _customWorkoutType = '';
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;
  bool _showEquipmentInput = false;
  bool _showWorkoutTypeInput = false;

  // Equipment quantities
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _workoutTypeController = TextEditingController();

  // AI Suggestions
  final TextEditingController _aiPromptController = TextEditingController();
  final FocusNode _aiPromptFocusNode = FocusNode();
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _isLoadingSuggestions = false;
  int? _selectedSuggestionIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFromWorkout();
    _tabController.addListener(() {
      if (_tabController.index == 1 &&
          _aiSuggestions.isEmpty &&
          !_isLoadingSuggestions) {
        _loadAISuggestions();
      }
    });
  }

  void _initializeFromWorkout() {
    _selectedDifficulty = widget.workout.difficulty?.toLowerCase() ?? 'medium';
    final workoutDuration = (widget.workout.durationMinutes ?? 45).toDouble();
    _selectedDurationMin = workoutDuration;
    _selectedDurationMax = (workoutDuration + 15).clamp(15, 90);
    _selectedWorkoutType = widget.workout.type;

    final type = widget.workout.type?.toLowerCase() ?? '';
    if (type.contains('upper')) {
      _selectedFocusAreas.addAll(['Chest', 'Back', 'Shoulders', 'Arms']);
    } else if (type.contains('lower')) {
      _selectedFocusAreas.addAll(['Legs', 'Glutes']);
    } else if (type.contains('core')) {
      _selectedFocusAreas.add('Core');
    } else {
      _selectedFocusAreas.add('Full Body');
    }

    for (final eq in widget.workout.equipmentNeeded) {
      if (defaultEquipmentOptions.contains(eq)) {
        _selectedEquipment.add(eq);
      }
    }

    // Override with user's saved profile preferences
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final prefs = await repo.getProgramPreferences(userId);

      if (!mounted || prefs == null) return;

      setState(() {
        if (prefs.difficulty != null) {
          _selectedDifficulty = prefs.difficulty!.toLowerCase();
        }
        if (prefs.durationMinutes != null) {
          final duration = prefs.durationMinutes!.toDouble().clamp(15.0, 90.0);
          _selectedDurationMin = duration;
          _selectedDurationMax = (duration + 15).clamp(15.0, 90.0);
        }

        if (prefs.equipment.isNotEmpty) {
          _selectedEquipment.clear();
          for (final equip in prefs.equipment) {
            if (defaultEquipmentOptions.contains(equip)) {
              _selectedEquipment.add(equip);
            }
          }
        }

        if (prefs.focusAreas.isNotEmpty) {
          _selectedFocusAreas.clear();
          for (final area in prefs.focusAreas) {
            if (defaultFocusAreas.contains(area)) {
              _selectedFocusAreas.add(area);
            }
          }
          if (_selectedFocusAreas.isEmpty) {
            _selectedFocusAreas.add('Full Body');
          }
        }

        _selectedInjuries.clear();
        for (final injury in prefs.injuries) {
          if (defaultInjuries.contains(injury)) {
            _selectedInjuries.add(injury);
          }
        }

        if (prefs.dumbbellCount != null) {
          _dumbbellCount = prefs.dumbbellCount!;
        }
        if (prefs.kettlebellCount != null) {
          _kettlebellCount = prefs.kettlebellCount!;
        }
      });
    } catch (e) {
      // Silently fall back to workout-based defaults already set
      debugPrint('Failed to load user preferences for regenerate sheet: $e');
    }
  }

  void _startElapsedTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _elapsed = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = _stopwatch.elapsed);
      }
    });
    _startHintRotation();
  }

  void _stopElapsedTimer() {
    _stopwatch.stop();
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _stopHintRotation();
  }

  void _startHintRotation() {
    _hintRotationTimer?.cancel();
    _hintIndex = 0;
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex++);
    });
  }

  void _stopHintRotation() {
    _hintRotationTimer?.cancel();
    _hintRotationTimer = null;
  }

  /// Returns the substatus shown under the main progress message. Prefers the
  /// backend-provided detail, and falls back to a rotating hint for the
  /// current step so the UI keeps moving even when nothing is being emitted.
  String? _displayDetail() {
    if (_progressDetail != null && _progressDetail!.isNotEmpty) {
      return _progressDetail;
    }
    final hints = _stepHints[_currentStep];
    if (hints == null || hints.isEmpty) return null;
    return hints[_hintIndex % hints.length];
  }

  /// Rough remaining-time hint ("~Ns remaining" or "Almost there..."). Returns
  /// null before the first real progress event so we don't promise a time
  /// we haven't started measuring against.
  String? _estimatedRemainingHint() {
    if (!_isRegenerating) return null;
    final remaining = _estimatedTotal - _elapsed;
    if (remaining.inSeconds <= 2) {
      return 'Almost there…';
    }
    return '~${remaining.inSeconds}s remaining';
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    _stopHintRotation();
    _tabController.dispose();
    _focusAreaController.dispose();
    _injuryController.dispose();
    _equipmentController.dispose();
    _workoutTypeController.dispose();
    _aiPromptController.dispose();
    _aiPromptFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAISuggestions() async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) {
        setState(() => _isLoadingSuggestions = false);
        return;
      }

      final repo = ref.read(workoutRepositoryProvider);
      final suggestions = await repo.getWorkoutSuggestions(
        workoutId: widget.workout.id!,
        userId: userId,
        currentWorkoutType: widget.workout.type,
        prompt: _aiPromptController.text.trim().isEmpty
            ? null
            : _aiPromptController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;

    return GlassSheet(
      maxHeightFraction: 0.85,
      showHandle: false,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            _buildTabBar(colors),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.cardBorder),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCustomizeTab(colors),
                  _buildAISuggestionsTab(colors),
                ],
              ),
            ),
            // Pinned regenerate button at bottom
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: _buildRegenerateButton(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regenerate Current Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize or let AI suggest',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _isRegenerating ? null : () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(SheetColors colors) {
    return SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      tabs: const [
        SegmentedTabItem(label: 'Customize'),
        SegmentedTabItem(label: 'AI Suggestions'),
      ],
    );
  }

  Widget _buildCustomizeTab(SheetColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkoutTypeSelector(
            selectedType: _selectedWorkoutType,
            onSelectionChanged: (type) {
              setState(() {
                _selectedWorkoutType = type;
                _customWorkoutType = '';
              });
            },
            customWorkoutType: _customWorkoutType,
            showCustomInput: _showWorkoutTypeInput,
            onToggleCustomInput: () =>
                setState(() => _showWorkoutTypeInput = !_showWorkoutTypeInput),
            onCustomTypeSaved: (value) {
              setState(() {
                _customWorkoutType = value;
                _selectedWorkoutType = null;
                _showWorkoutTypeInput = false;
              });
            },
            customInputController: _workoutTypeController,
            disabled: _isRegenerating,
          ),
          DifficultySelector(
            selectedDifficulty: _selectedDifficulty,
            onSelectionChanged: (d) =>
                setState(() => _selectedDifficulty = d),
            disabled: _isRegenerating,
            showIcons: false,
          ),
          DurationRangeSlider(
            durationMin: _selectedDurationMin,
            durationMax: _selectedDurationMax,
            onChanged: (range) => setState(() {
              _selectedDurationMin = range.start;
              _selectedDurationMax = range.end;
            }),
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          EquipmentSelector(
            selectedEquipment: _selectedEquipment,
            onSelectionChanged: (eq) =>
                setState(() {
                  _selectedEquipment.clear();
                  _selectedEquipment.addAll(eq);
                }),
            customEquipment: _customEquipment,
            showCustomInput: _showEquipmentInput,
            onToggleCustomInput: () =>
                setState(() => _showEquipmentInput = !_showEquipmentInput),
            onCustomEquipmentSaved: (value) {
              setState(() {
                _customEquipment = value;
                _showEquipmentInput = false;
              });
            },
            dumbbellCount: _dumbbellCount,
            kettlebellCount: _kettlebellCount,
            onDumbbellCountChanged: (c) =>
                setState(() => _dumbbellCount = c),
            onKettlebellCountChanged: (c) =>
                setState(() => _kettlebellCount = c),
            customInputController: _equipmentController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          FocusAreasSelector(
            selectedAreas: _selectedFocusAreas,
            onSelectionChanged: (areas) =>
                setState(() {
                  _selectedFocusAreas.clear();
                  _selectedFocusAreas.addAll(areas);
                }),
            customFocusArea: _customFocusArea,
            showCustomInput: _showFocusAreaInput,
            onToggleCustomInput: () =>
                setState(() => _showFocusAreaInput = !_showFocusAreaInput),
            onCustomFocusAreaSaved: (value) {
              setState(() {
                _customFocusArea = value;
                _showFocusAreaInput = false;
              });
            },
            customInputController: _focusAreaController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          InjuriesSelector(
            selectedInjuries: _selectedInjuries,
            onSelectionChanged: (injuries) =>
                setState(() {
                  _selectedInjuries.clear();
                  _selectedInjuries.addAll(injuries);
                }),
            customInjury: _customInjury,
            showCustomInput: _showInjuryInput,
            onToggleCustomInput: () =>
                setState(() => _showInjuryInput = !_showInjuryInput),
            onCustomInjurySaved: (value) {
              setState(() {
                _customInjury = value;
                _showInjuryInput = false;
              });
            },
            customInputController: _injuryController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsTab(SheetColors colors) {
    return Column(
      children: [
        _buildAIPromptInput(colors),
        Divider(height: 1, color: colors.cardBorder),
        Expanded(
          child: _isLoadingSuggestions
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        'Generating suggestions...',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ],
                  ),
                )
              : _aiSuggestions.isEmpty
                  ? _buildEmptySuggestionsState(colors)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _aiSuggestions.length,
                      itemBuilder: (context, index) {
                        return AISuggestionCard(
                          suggestion: _aiSuggestions[index],
                          index: index,
                          isSelected: _selectedSuggestionIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedSuggestionIndex =
                                  _selectedSuggestionIndex == index
                                      ? null
                                      : index;
                            });
                          },
                        );
                      },
                    ),
        ),
        if (_selectedSuggestionIndex != null) _buildApplyButton(colors),
      ],
    );
  }

  Widget _buildAIPromptInput(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Describe your ideal workout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiPromptController,
            focusNode: _aiPromptFocusNode,
            maxLines: 2,
            enabled: !_isRegenerating,
            autofocus: false,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'e.g., "A quick upper body workout with no equipment"',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
              filled: true,
              fillColor: colors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colors.cardBorder.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.cyan, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _aiPromptController.text.isEmpty
                      ? colors.textMuted
                      : colors.cyan,
                ),
                onPressed: _isLoadingSuggestions ? null : _loadAISuggestions,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _loadAISuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySuggestionsState(SheetColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: colors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a prompt above or tap refresh to get AI-powered workout suggestions',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isLoadingSuggestions ? null : _loadAISuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Get Suggestions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.cyan,
                side: BorderSide(color: colors.cyan),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_isRegenerating)
            _buildProgressSection(colors, colors.purple),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRegenerating ? null : _regenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: colors.purple.withOpacity(0.6),
              ),
              child: _isRegenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generating... ${_formatElapsed(_elapsed)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Regenerate Workout',
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns true for "Replace", false for "Add", null if cancelled.
  Future<bool?> _showReplaceOrAddDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'What would you like to do?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You already have a workout scheduled for today.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Add Workout',
              style: TextStyle(color: colors.cyan),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(SheetColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRegenerating)
            _buildProgressSection(colors, colors.cyan),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRegenerating ? null : _applyAISuggestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: colors.cyan.withOpacity(0.6),
              ),
              child: _isRegenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generating... ${_formatElapsed(_elapsed)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Apply This Workout',
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

