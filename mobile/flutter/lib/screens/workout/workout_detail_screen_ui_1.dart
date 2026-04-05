part of 'workout_detail_screen.dart';

/// Methods extracted from _WorkoutDetailScreenState
extension __WorkoutDetailScreenStateExt1 on _WorkoutDetailScreenState {

  /// Toggle between kg and lbs units locally
  void _toggleUnit() {
    setState(() {
      final bool currentUseKg = _useKgOverride ?? ref.read(useKgForWorkoutProvider);
      _useKgOverride = !currentUseKg;
    });
  }


  Future<void> _toggleFavorite() async {
    if (_workout == null) return;

    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    HapticService.selection();

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final newState = await repo.toggleWorkoutFavorite(_workout!.id!);
      if (mounted) {
        setState(() => _isFavorite = newState);
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() => _isFavorite = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }


  /// Start loading secondary data (summary, training split, generation params).
  /// Guarded by _secondaryLoadsStarted to prevent duplicate calls.
  void _startSecondaryLoads() {
    if (_secondaryLoadsStarted || _workout == null) return;
    _secondaryLoadsStarted = true;
    _loadWorkoutSummary();
    _loadTrainingSplit();
    _loadGenerationParams();
    if (_workout!.isCompleted == true) {
      _loadSaunaLog();
    }
  }


  /// Schedule auto-save with debounce (2 seconds)
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSaveExercises);
  }


  /// Flush any pending auto-save before add/swap/remove to prevent race conditions
  Future<void> _flushPendingAutoSave() async {
    if (_autoSaveTimer?.isActive == true) {
      _autoSaveTimer!.cancel();
      await _autoSaveExercises();
    }
  }


  /// Auto-save exercise modifications to backend
  Future<void> _autoSaveExercises() async {
    if (_workout?.id == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final exercises = _workout!.exercises.map((e) => e.toJson()).toList();
      final result = await ref.read(workoutRepositoryProvider).updateWorkoutExercises(
        workoutId: _workout!.id!,
        exercises: exercises,
      );
      if (result != null && mounted) {
        debugPrint('✅ [WorkoutDetail] Auto-saved exercise modifications');
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Auto-save failed: $e');
      // Silently fail - changes are still in local state
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  Future<void> _loadWorkout() async {
    if (widget.workoutId.isEmpty) {
      setState(() {
        _error = 'Invalid workout ID';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      // Only show loading spinner if we don't already have workout data
      if (_workout == null) _isLoading = true;
      _error = null;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.getWorkout(widget.workoutId);
      if (workout == null) {
        setState(() {
          _error = 'Workout not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _workout = workout;
        _isFavorite = workout.isFavorite ?? false;
        _isLoading = false;
      });

      // Track workout detail viewed
      ref.read(posthogServiceProvider).capture(
        eventName: 'workout_detail_viewed',
        properties: {
          'workout_id': widget.workoutId,
          'workout_name': workout.name ?? '',
        },
      );

      // Start secondary loads if not already started (e.g. from initialWorkout path)
      _startSecondaryLoads();
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load workout ${widget.workoutId}: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  Future<void> _loadTrainingSplit() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final prefs = await workoutRepo.getProgramPreferences(userId);
      if (mounted && prefs?.trainingSplit != null) {
        // Resolve 'dont_know' to actual split based on workout days
        final resolvedSplit = _resolveTrainingSplit(
          prefs!.trainingSplit!,
          prefs.workoutDays.length,
        );
        setState(() {
          _trainingSplit = resolvedSplit;
        });
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load training split: $e');
    }
  }


  /// Resolve 'dont_know' or 'ai_decide' to actual training split based on workout days count
  String _resolveTrainingSplit(String split, int numDays) {
    final lower = split.toLowerCase();
    if (lower != 'dont_know' && lower != 'ai_decide') {
      return split;  // Already a specific split
    }

    // Auto-pick based on days per week (matches backend logic)
    if (numDays <= 3) {
      return 'full_body';
    } else if (numDays == 4) {
      return 'upper_lower';
    } else if (numDays <= 6) {
      return 'push_pull_legs';
    } else {
      return 'full_body';
    }
  }


  Future<void> _loadWorkoutSummary() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load summary - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Starting to load workout summary for: ${widget.workoutId}');
    setState(() => _isLoadingSummary = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final summary = await workoutRepo.getWorkoutSummary(widget.workoutId);
      debugPrint('🔍 [WorkoutDetail] Got summary response: ${summary != null ? "yes (${summary.length} chars)" : "null"}');
      if (mounted) {
        setState(() {
          _workoutSummary = summary;
          _isLoadingSummary = false;
        });
        debugPrint('✅ [WorkoutDetail] Summary state updated - summary: ${_workoutSummary != null}, loading: $_isLoadingSummary');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WorkoutDetail] Failed to load workout summary: $e');
      debugPrint('❌ [WorkoutDetail] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }


  /// Load warmup and stretch exercises from API
  Future<void> _loadWarmupAndStretches() async {
    if (_workout?.id == null) return;
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final data = await workoutRepo.generateWarmupAndStretches(_workout!.id!);
      if (mounted) {
        setState(() {
          _warmupData = data['warmup'] ?? [];
          _stretchData = data['stretches'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load warmup/stretches: $e');
    }
  }


  /// Load generation parameters and AI reasoning for the workout
  Future<void> _loadGenerationParams() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load generation params - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Loading generation params for: ${widget.workoutId}');
    setState(() => _isLoadingParams = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final params = await workoutRepo.getWorkoutGenerationParams(widget.workoutId);
      if (mounted) {
        setState(() {
          _generationParams = params;
          _isLoadingParams = false;
        });
        debugPrint('✅ [WorkoutDetail] Generation params loaded - ${params?.exerciseReasoning.length ?? 0} exercise reasons');
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load generation params: $e');
      if (mounted) {
        setState(() => _isLoadingParams = false);
      }
    }
  }


  // ─────────────────────────────────────────────────────────────────
  // SAUNA POST-WORKOUT LOGGING
  // ─────────────────────────────────────────────────────────────────

  Future<void> _loadSaunaLog() async {
    if (_workout?.id == null) return;
    setState(() => _isLoadingSauna = true);
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;
      final repo = ref.read(saunaRepositoryProvider);
      final logs = await repo.getLogs(userId, workoutId: _workout!.id!);
      if (mounted) {
        setState(() {
          _saunaLog = logs.isNotEmpty ? logs.first : null;
          _isLoadingSauna = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Error loading sauna log: $e');
      if (mounted) setState(() => _isLoadingSauna = false);
    }
  }


  Future<void> _addSaunaToWorkout() async {
    final result = await showSaunaDialog(context: context);
    if (result != null && mounted) {
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.user?.id;
        if (userId == null) return;
        final repo = ref.read(saunaRepositoryProvider);
        final log = await repo.logSauna(
          userId: userId,
          durationMinutes: result.durationMinutes,
          workoutId: _workout?.id,
        );
        if (mounted) {
          setState(() => _saunaLog = log);
        }
      } catch (e) {
        debugPrint('❌ [WorkoutDetail] Error logging sauna: $e');
      }
    }
  }


  Future<void> _deleteSaunaLog() async {
    if (_saunaLog == null) return;
    try {
      final repo = ref.read(saunaRepositoryProvider);
      await repo.deleteLog(_saunaLog!.id);
      if (mounted) {
        setState(() => _saunaLog = null);
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Error deleting sauna log: $e');
    }
  }


  // ─────────────────────────────────────────────────────────────────
  // EQUIPMENT EDITING
  // ─────────────────────────────────────────────────────────────────

  /// Show sheet to edit equipment for this workout session
  void _showEditEquipmentSheet(Workout workout) {
    // Convert equipment strings to EquipmentItem objects
    final currentEquipmentDetails = workout.equipmentNeeded.map((name) {
      return EquipmentItem.fromName(name.toLowerCase().replaceAll(' ', '_'));
    }).toList();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: EditWorkoutEquipmentSheet(
          currentEquipment: workout.equipmentNeeded,
          equipmentDetails: currentEquipmentDetails,
          onApply: (selectedEquipment) => _applyEquipmentChanges(workout, selectedEquipment),
        ),
      ),
    );
  }


  /// Apply equipment changes and update workout
  Future<void> _applyEquipmentChanges(
    Workout workout,
    List<EquipmentItem> selectedEquipment,
  ) async {
    final analysis = _analyzeEquipmentChanges(workout, selectedEquipment);
    debugPrint('🔧 [Equipment] Analysis: ${analysis.weightAdjustments.length} weight adjustments, ${analysis.exercisesToReplace.length} to replace');

    if (analysis.exercisesToReplace.isEmpty && analysis.weightAdjustments.isEmpty) {
      // No changes needed
      _showSnackBar('No changes needed');
      return;
    }

    // Store snapshot BEFORE first modification (for revert functionality)
    if (_originalExercises == null) {
      _originalExercises = List<WorkoutExercise>.from(workout.exercises);
      debugPrint('🔧 [Equipment] Stored original exercises snapshot (${_originalExercises!.length} exercises)');
    }

    if (analysis.exercisesToReplace.isNotEmpty) {
      // Quick replace exercises one by one (faster than full regeneration)
      await _quickReplaceExercises(workout, analysis.exercisesToReplace, selectedEquipment);
    } else {
      // Only weight adjustments - apply locally
      _applyWeightAdjustments(workout, analysis.weightAdjustments);
    }

    // Mark as modified (enables revert button)
    setState(() => _hasEquipmentModifications = true);

    // Ask if user wants to save to profile
    if (mounted) {
      _showSaveToProfileDialog(selectedEquipment);
    }
  }


  /// Analyze what changes are needed based on equipment selection
  EquipmentChangeAnalysis _analyzeEquipmentChanges(
    Workout workout,
    List<EquipmentItem> selectedEquipment,
  ) {
    final selectedNames = selectedEquipment.map((e) => e.name.toLowerCase()).toSet();
    final equipmentWeights = {
      for (final e in selectedEquipment) e.name.toLowerCase(): e.weights,
    };

    final weightAdjustments = <ExerciseWeightAdjustment>[];
    final exercisesToReplace = <WorkoutExercise>[];

    for (final exercise in workout.exercises) {
      final eqNeeded = (exercise.equipment ?? 'bodyweight').toLowerCase().replaceAll(' ', '_');

      // Bodyweight exercises are always fine
      if (eqNeeded == 'bodyweight' || eqNeeded == 'body_weight' || eqNeeded.isEmpty) {
        continue;
      }

      // Check if equipment is still selected
      if (!selectedNames.contains(eqNeeded)) {
        exercisesToReplace.add(exercise);
        continue;
      }

      // Equipment available - check if weight adjustment needed
      final availableWeights = equipmentWeights[eqNeeded];
      if (availableWeights != null && availableWeights.isNotEmpty) {
        final currentWeight = exercise.weight ?? 0;
        if (currentWeight > 0) {
          final nearestWeight = _findNearestWeight(currentWeight, availableWeights);
          if ((nearestWeight - currentWeight).abs() > 0.1) {
            weightAdjustments.add(ExerciseWeightAdjustment(
              exercise: exercise,
              oldWeight: currentWeight,
              newWeight: nearestWeight,
            ));
          }
        }
      }
    }

    return EquipmentChangeAnalysis(
      weightAdjustments: weightAdjustments,
      exercisesToReplace: exercisesToReplace,
    );
  }


  /// Find nearest available weight
  double _findNearestWeight(double target, List<double> available) {
    if (available.isEmpty) return target;
    return available.reduce((a, b) =>
      (a - target).abs() < (b - target).abs() ? a : b
    );
  }


  /// Apply weight adjustments locally
  void _applyWeightAdjustments(
    Workout workout,
    List<ExerciseWeightAdjustment> adjustments,
  ) {
    final updatedExercises = List<WorkoutExercise>.from(workout.exercises);

    for (final adj in adjustments) {
      final index = updatedExercises.indexWhere((e) => e.id == adj.exercise.id);
      if (index != -1) {
        final exercise = updatedExercises[index];
        // Update weight and set targets
        List<SetTarget>? updatedTargets;
        if (exercise.setTargets != null && exercise.setTargets!.isNotEmpty) {
          updatedTargets = exercise.setTargets!.map((target) {
            return SetTarget(
              setNumber: target.setNumber,
              setType: target.setType,
              targetReps: target.targetReps,
              targetWeightKg: adj.newWeight,
              targetRpe: target.targetRpe,
              targetRir: target.targetRir,
            );
          }).toList();
        }

        updatedExercises[index] = exercise.copyWith(
          weight: adj.newWeight,
          setTargets: updatedTargets,
        );
      }
    }

    // Convert to JSON and update workout locally
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();
    setState(() {
      _workout = workout.copyWith(exercisesJson: exercisesJson);
    });

    _showSnackBar('Weights updated to match available equipment');
  }


  /// Quick replace exercises that need different equipment (faster than full regeneration)
  Future<void> _quickReplaceExercises(
    Workout workout,
    List<WorkoutExercise> exercisesToReplace,
    List<EquipmentItem> selectedEquipment,
  ) async {
    if (workout.id == null) {
      _showSnackBar('Cannot update - workout ID missing', isError: true);
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => QuickReplaceProgressDialog(
          total: exercisesToReplace.length,
        ),
      );
    }

    final workoutRepo = ref.read(workoutRepositoryProvider);
    int replaced = 0;
    int failed = 0;

    for (final exercise in exercisesToReplace) {
      try {
        debugPrint('🔄 [Equipment] Replacing: ${exercise.name}');
        final result = await workoutRepo.replaceExerciseSafe(
          workoutId: workout.id!,
          exerciseName: exercise.name,
          exerciseId: exercise.id,
          reason: 'equipment_unavailable',
        );

        if (result?.replaced == true) {
          replaced++;
          debugPrint('✅ [Equipment] Replaced ${exercise.name} with ${result!.replacement}');
        } else {
          failed++;
          debugPrint('⚠️ [Equipment] Could not replace ${exercise.name}');
        }
      } catch (e) {
        failed++;
        debugPrint('❌ [Equipment] Error replacing ${exercise.name}: $e');
      }
    }

    if (mounted) Navigator.of(context).pop(); // Close progress dialog

    // Reload the workout with new data
    await _loadWorkout();

    if (mounted) {
      if (failed == 0) {
        _showSnackBar('Replaced $replaced exercise${replaced > 1 ? 's' : ''} for available equipment');
      } else {
        _showSnackBar('Replaced $replaced, $failed could not be replaced');
      }
    }
  }


  /// Show dialog asking if user wants to save equipment to profile
  void _showSaveToProfileDialog(List<EquipmentItem> equipment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Save to Profile?',
          style: TextStyle(color: textPrimary, fontSize: 18),
        ),
        content: Text(
          'Would you like to save this equipment configuration to your profile for future workouts?',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No Thanks',
              style: TextStyle(color: textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveEquipmentToProfile(equipment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Save'),
          ),
        ],
      ),
    );
  }


  /// Save equipment configuration to user profile (Supabase)
  Future<void> _saveEquipmentToProfile(List<EquipmentItem> equipment) async {
    debugPrint('💾 [Equipment] Saving ${equipment.length} items to profile');

    try {
      // Convert EquipmentItem list to the format expected by the provider
      final equipmentDetails = equipment.map((item) => item.toJson()).toList();

      // Save to Supabase via the environment equipment provider
      await ref.read(environmentEquipmentProvider.notifier).setEquipmentDetails(equipmentDetails);

      if (mounted) {
        _showSnackBar('Equipment saved to profile');
      }
      debugPrint('✅ [Equipment] Successfully saved ${equipment.length} items to Supabase');
    } catch (e) {
      debugPrint('❌ [Equipment] Failed to save to profile: $e');
      if (mounted) {
        _showSnackBar('Failed to save equipment to profile', isError: true);
      }
    }
  }


  /// Revert workout to original exercises (before equipment changes)
  Future<void> _revertToOriginalExercises() async {
    if (_originalExercises == null || _workout == null) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Revert to Original?',
      message: 'This will restore all exercises to their original state before equipment changes were applied.',
      confirmText: 'Revert',
      icon: Icons.restore_rounded,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);

      debugPrint('🔄 [Equipment] Reverting to original ${_originalExercises!.length} exercises');

      // Restore original exercises via API
      await workoutRepo.updateWorkoutExercises(
        workoutId: _workout!.id!,
        exercises: _originalExercises!.map((e) => e.toJson()).toList(),
      );

      // Reload workout and clear snapshot
      await _loadWorkout();
      _originalExercises = null;
      _hasEquipmentModifications = false;

      if (mounted) {
        _showSnackBar('Workout restored to original');
      }
      debugPrint('✅ [Equipment] Successfully reverted to original exercises');
    } catch (e) {
      debugPrint('❌ [Equipment] Failed to revert: $e');
      if (mounted) {
        _showSnackBar('Failed to revert: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  /// Convert training split ID to display name
  /// Returns the program name if found, or null for special cases like 'nothing_structured'
  String? _getTrainingProgramName(String splitId) {
    // Handle special cases that are valid but don't have a display badge
    if (splitId == 'nothing_structured' || splitId == 'dont_know' || splitId == 'ai_decide') {
      // User chose "let AI decide" - no specific program badge to show
      return null;
    }

    // Look up the program in our known list
    final program = defaultTrainingPrograms.where((p) => p.id == splitId).firstOrNull;
    if (program == null) {
      // Unknown split ID - log it but don't crash
      debugPrint('⚠️ [WorkoutDetail] Unknown training split: $splitId');
      return null;
    }
    return program.name;
  }


  // ─────────────────────────────────────────────────────────────────
  // SUPERSET HANDLERS
  // ─────────────────────────────────────────────────────────────────

  /// Create superset from two exercise indices (via drag-drop or menu)
  void _createSuperset(int firstIndex, int secondIndex) {
    final exercise1 = _workout!.exercises[firstIndex];
    final exercise2 = _workout!.exercises[secondIndex];

    debugPrint('🔗 [Superset] _createSuperset called: firstIndex=$firstIndex, secondIndex=$secondIndex');
    debugPrint('🔗 [Superset] exercise1: ${exercise1.name}, isInSuperset=${exercise1.isInSuperset}, group=${exercise1.supersetGroup}');
    debugPrint('🔗 [Superset] exercise2: ${exercise2.name}, isInSuperset=${exercise2.isInSuperset}, group=${exercise2.supersetGroup}');

    // Case 1: Both exercises are already in different supersets - cannot merge
    if (exercise1.isInSuperset && exercise2.isInSuperset) {
      if (exercise1.supersetGroup != exercise2.supersetGroup) {
        debugPrint('🔗 [Superset] Case 1: Cannot merge different supersets');
        HapticService.error();
        _showCannotMergeSupersetDialog(exercise1, exercise2);
        return;
      }
      // Same superset - do nothing
      debugPrint('🔗 [Superset] Case 1b: Same superset, doing nothing');
      return;
    }

    // Case 2: One exercise is in a superset - offer to add the other to it
    if (exercise1.isInSuperset || exercise2.isInSuperset) {
      debugPrint('🔗 [Superset] Case 2: One in superset, showing add dialog');
      final existingSuperset = exercise1.isInSuperset ? exercise1 : exercise2;
      final newExercise = exercise1.isInSuperset ? exercise2 : exercise1;
      final newExerciseIndex = exercise1.isInSuperset ? secondIndex : firstIndex;
      _showAddToSupersetDialog(existingSuperset, newExercise, newExerciseIndex);
      return;
    }

    // Case 3: Neither is in a superset - create new superset
    debugPrint('🔗 [Superset] Case 3: Neither in superset, creating new');
    _performCreateSuperset(firstIndex, secondIndex);
  }


  /// Show dialog when both exercises are already in different supersets (cannot merge)
  Future<void> _showCannotMergeSupersetDialog(
    WorkoutExercise exercise1,
    WorkoutExercise exercise2,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cannot Merge Supersets',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '"${exercise1.name}" and "${exercise2.name}" are already in different supersets.\n\nBreak the existing supersets first to create a new pairing.',
          style: TextStyle(color: textPrimary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Clear pending state
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _pendingSupersetIndex = null);
  }


  /// Show dialog offering to add an exercise to an existing superset
  Future<void> _showAddToSupersetDialog(
    WorkoutExercise existingSuperset,
    WorkoutExercise newExercise,
    int newExerciseIndex,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentColor = isDark ? AppColors.purple : AppColorsLight.purple;

    // Count exercises in the existing superset
    final existingCount = _workout!.exercises
        .where((e) => e.supersetGroup == existingSuperset.supersetGroup)
        .length;

    final newSetType = switch (existingCount + 1) {
      3 => 'tri-set',
      _ => 'giant set',
    };

    // Capitalize first letter helper
    String capitalize(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_link, color: accentColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Create ${capitalize(newSetType)}?',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Add "${newExercise.name}" to create a $newSetType?',
          style: TextStyle(color: textPrimary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Create ${capitalize(newSetType)}'),
          ),
        ],
      ),
    );

    if (result == true) {
      _addToExistingSuperset(newExerciseIndex, existingSuperset.supersetGroup!);
    }

    // Clear pending state
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _pendingSupersetIndex = null);
  }


  /// Add an exercise to an existing superset
  void _addToExistingSuperset(int exerciseIndex, int targetGroup) {
    HapticService.medium();

    // Find the maximum order in the target group
    final maxOrder = _workout!.exercises
        .where((e) => e.supersetGroup == targetGroup)
        .map((e) => e.supersetOrder ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    final updatedExercises = _workout!.exercises.asMap().map((i, e) {
      if (i == exerciseIndex) {
        return MapEntry(i, e.copyWith(
          supersetGroup: targetGroup,
          supersetOrder: maxOrder + 1,
        ));
      }
      return MapEntry(i, e);
    }).values.toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();

    // Get count for snackbar message
    final newCount = _workout!.exercises
        .where((e) => e.supersetGroup == targetGroup)
        .length + 1;
    final setType = switch (newCount) {
      3 => 'Tri-set',
      _ => 'Giant set',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$setType created!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  /// Actually create the superset (called after validation passes)
  void _performCreateSuperset(int firstIndex, int secondIndex) {
    HapticService.medium();

    // Find next available group number
    final existingGroups = _workout!.exercises
        .where((e) => e.supersetGroup != null)
        .map((e) => e.supersetGroup!)
        .toSet();
    int newGroup = 1;
    while (existingGroups.contains(newGroup)) {
      newGroup++;
    }

    final updatedExercises = _workout!.exercises.asMap().map((i, e) {
      if (i == firstIndex) {
        return MapEntry(i, e.copyWith(supersetGroup: newGroup, supersetOrder: 1));
      }
      if (i == secondIndex) {
        return MapEntry(i, e.copyWith(supersetGroup: newGroup, supersetOrder: 2));
      }
      return MapEntry(i, e);
    }).values.toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() {
      _workout = _workout!.copyWith(exercisesJson: exercisesJson);
      _pendingSupersetIndex = null;
    });
    _scheduleAutoSave();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Superset created!'),
          duration: Duration(seconds: 2),
        ),
      );
  }


  /// Start pairing from 3-dot menu - stores pending index
  void _startSupersetPairing(int index) {
    setState(() => _pendingSupersetIndex = index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tap another exercise to link as superset'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {
            setState(() => _pendingSupersetIndex = null);
          },
        ),
      ),
    );
  }

}
