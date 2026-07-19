part of 'workout_detail_screen.dart';

/// Section label ("Warm Up" / "Main Circuit" / "Cool Down") to render ABOVE the
/// exercise at [index], or null. Only AI-authored workouts carry a per-exercise
/// `section`; a workout with no sections (all null) or only one section shows no
/// headers — keeping library/legacy workouts a flat list (back-compat).
/// Top-level + pure so it is directly unit-testable.
String? sectionHeaderForIndex(List<WorkoutExercise> exercises, int index) {
  if (index < 0 || index >= exercises.length) return null;
  final sec = exercises[index].section?.toLowerCase().trim();
  if (sec == null || sec.isEmpty) return null;
  final distinct = exercises
      .map((e) => e.section?.toLowerCase().trim())
      .where((s) => s != null && s.isNotEmpty)
      .toSet();
  if (distinct.length < 2) return null; // not a real multi-section workout
  // Only label the FIRST exercise of each section.
  for (int i = 0; i < index; i++) {
    if (exercises[i].section?.toLowerCase().trim() == sec) return null;
  }
  const labels = {
    'warmup': 'Warm Up',
    'warm_up': 'Warm Up',
    'main': 'Main Circuit',
    'cooldown': 'Cool Down',
    'cool_down': 'Cool Down',
  };
  return labels[sec] ?? (sec[0].toUpperCase() + sec.substring(1));
}

/// Methods extracted from _WorkoutDetailScreenState
extension __WorkoutDetailScreenStateExt2 on _WorkoutDetailScreenState {

  /// Break superset (long-press on header)
  Future<void> _breakSuperset(int groupNumber) async {
    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutDetailScreenBreakSuperset,
      message: AppLocalizations.of(context).workoutDetailScreenThisWillUnlinkThese,
      confirmText: 'Break',
      icon: Icons.link_off_rounded,
    );

    if (confirm == true) {
      final updatedExercises = _workout!.exercises.map((e) {
        if (e.supersetGroup == groupNumber) {
          return e.copyWith(clearSuperset: true);
        }
        return e;
      }).toList();

      // Convert exercises back to JSON for storage
      final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

      setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
      _scheduleAutoSave();
      HapticService.light();
    }
  }


  /// Swap the order of exercises within a superset (1 becomes 2, 2 becomes 1)
  void _swapSupersetOrder(int groupNumber) {
    HapticService.light();

    final updatedExercises = _workout!.exercises.map((e) {
      if (e.supersetGroup == groupNumber) {
        // Swap order: 1 becomes 2, 2 becomes 1
        final newOrder = e.supersetOrder == 1 ? 2 : 1;
        return e.copyWith(supersetOrder: newOrder);
      }
      return e;
    }).toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();
  }


  /// Show edit sheet for tri-sets and giant sets (3+ exercises) - reorder & remove
  Future<void> _showReorderSheet(int groupNumber, List<int> exerciseIndices) async {
    // Get the exercises in this superset, sorted by current order
    final supersetExercises = exerciseIndices
        .map((idx) => _workout!.exercises[idx])
        .toList()
      ..sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

    final result = await showSupersetEditSheet(
      context,
      exercises: supersetExercises,
      groupNumber: groupNumber,
    );

    if (result != null) {
      // Apply both removals and reorder in one atomic update
      _applyEditSheetResult(groupNumber, result);
    }
  }


  /// Apply the edit sheet result - handles both removals and reordering atomically
  void _applyEditSheetResult(int groupNumber, SupersetEditResult result) {
    HapticService.medium();

    // Create set of keys for removed exercises
    final removeKeys = result.removedExercises.map((e) => e.id ?? e.name).toSet();

    // Create a map of exercise ID/name to new order for remaining exercises
    final orderMap = <String, int>{};
    for (int i = 0; i < result.exercises.length; i++) {
      final key = result.exercises[i].id ?? result.exercises[i].name;
      orderMap[key] = i + 1; // supersetOrder is 1-indexed
    }

    // Apply both changes in one pass
    final updatedExercises = _workout!.exercises.map((e) {
      final key = e.id ?? e.name;

      // Check if this exercise was removed from the superset
      if (removeKeys.contains(key)) {
        return e.copyWith(
          supersetGroup: null,
          supersetOrder: null,
        );
      }

      // Check if this exercise is in the superset and needs reordering
      if (e.supersetGroup == groupNumber) {
        final newOrderValue = orderMap[key];
        if (newOrderValue != null) {
          return e.copyWith(supersetOrder: newOrderValue);
        }
      }

      return e;
    }).toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();

    // Show appropriate feedback
    final hasRemovals = result.removedExercises.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasRemovals
            ? '${result.removedExercises.length} exercise${result.removedExercises.length > 1 ? 's' : ''} removed from superset'
            : 'Exercise order updated!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  /// Reorder exercises (and supersets as single units) in the list
  void _reorderExercises(int oldIndex, int newIndex) {
    HapticService.medium();

    // Adjust for Flutter's ReorderableListView behavior
    if (newIndex > oldIndex) newIndex -= 1;

    final displayItems = groupExercisesForDisplay(_workout!.exercises);
    final exercises = List<WorkoutExercise>.from(_workout!.exercises);

    if (oldIndex >= displayItems.length || newIndex >= displayItems.length) return;

    final movedItem = displayItems[oldIndex];

    if (movedItem.isSuperset) {
      // Move all exercises in the superset together (supports 2+ exercises)
      final supersetIndices = movedItem.supersetIndices!;

      // Get exercises sorted by their superset order
      final supersetExercises = supersetIndices
          .map((idx) => exercises[idx])
          .toList()
        ..sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

      // Remove all exercises in the superset (remove from highest index to lowest to preserve indices)
      final sortedIndices = List<int>.from(supersetIndices)..sort((a, b) => b.compareTo(a));
      for (final idx in sortedIndices) {
        exercises.removeAt(idx);
      }

      // Calculate new insert position
      int insertPos = _calculateInsertPosition(displayItems, newIndex, exercises);

      // Insert all exercises at new position (maintain their relative order)
      for (int i = 0; i < supersetExercises.length; i++) {
        exercises.insert(insertPos + i, supersetExercises[i]);
      }
    } else {
      // Single exercise - simple move
      final ex = exercises.removeAt(movedItem.singleIndex!);
      int insertPos = _calculateInsertPosition(displayItems, newIndex, exercises);
      exercises.insert(insertPos.clamp(0, exercises.length), ex);
    }

    // Convert exercises back to JSON for storage
    final exercisesJson = exercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();
  }


  /// Calculate the actual exercise list position for a display index
  int _calculateInsertPosition(
    List<ExerciseDisplayItem> displayItems,
    int targetDisplayIndex,
    List<WorkoutExercise> currentExercises,
  ) {
    if (targetDisplayIndex >= displayItems.length) {
      return currentExercises.length;
    }
    if (targetDisplayIndex <= 0) {
      return 0;
    }

    // Find the actual exercise index for the target display position
    int exerciseIndex = 0;
    for (int i = 0; i < targetDisplayIndex && i < displayItems.length; i++) {
      final item = displayItems[i];
      if (item.isSuperset) {
        exerciseIndex += item.exerciseCount; // Supersets can contain 2+ exercises
      } else {
        exerciseIndex += 1;
      }
    }
    return exerciseIndex.clamp(0, currentExercises.length);
  }


  /// Build exercise card widget (used for both single and superset exercises)
  /// [reorderIndex] is the index within the SliverReorderableList for drag handle reordering
  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    Color accentColor, {
    int? reorderIndex,
    bool isPendingPair = false,
    void Function(int draggedIndex)? onSupersetDrop,
    int? supersetPairingIndex,
    String? sectionHeader,
  }) {
    // When in superset pairing mode, intercept taps for pairing instead of navigation
    final bool inPairingMode = supersetPairingIndex != null;
    final bool isSelf = supersetPairingIndex == index;

    final Widget card = ExpandedExerciseCard(
      key: ValueKey(exercise.id ?? index),
      exercise: exercise,
      index: index,
      workoutId: widget.workoutId,
      initiallyExpanded: false,
      reorderIndex: reorderIndex,
      isPendingPair: isPendingPair,
      onSupersetDrop: onSupersetDrop,  // Allow drop even if in superset (to add to tri-set/giant set)
      onTap: inPairingMode
          ? () {
              debugPrint('🔗 [WorkoutDetail] PAIRING TAP: index=$index, source=$supersetPairingIndex, isSelf=$isSelf');
              if (!isSelf) {
                _createSuperset(supersetPairingIndex, index);
              }
            }
          : () {
              debugPrint('🎯 [WorkoutDetail] Exercise tapped: ${exercise.name} (pairingMode=$inPairingMode, pendingIdx=$supersetPairingIndex)');
              context.push('/exercise-detail', extra: exercise);
            },
      onSwap: () async {
        await _flushPendingAutoSave();
        if (!mounted) return;
        final updatedWorkout = await showExerciseSwapSheet(
          context,
          ref,
          workoutId: widget.workoutId,
          exercise: exercise,
        );
        if (updatedWorkout != null && mounted) {
          setState(() => _workout = updatedWorkout);
          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
          ref.read(workoutsProvider.notifier).silentRefresh();
        }
      },
      onLinkSuperset: exercise.isInSuperset
          ? null  // Already in a superset
          : () => _startSupersetPairing(index),
      onViewHistory: () {
        // Open the exercise-detail screen with the History tab pre-selected.
        // Replaces the old standalone per-exercise history screen — users
        // get the full exercise context (video, stats, history) in one place.
        context.push(
          '/exercise-detail',
          extra: <String, dynamic>{
            'exercise': exercise,
            'initialTab': 2,
          },
        );
      },
      onRemove: () => _removeExerciseFromWorkout(exercise, index),
      onNeverRecommend: () => _neverRecommendExercise(exercise),
    );

    if (sectionHeader == null || sectionHeader.isEmpty) return card;
    // Render a section label above the first exercise of each section (the
    // header rides with its card as one reorderable unit, so reorder math is
    // unaffected).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sectionHeader.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        card,
      ],
    );
  }


  /// Remove an exercise from the current workout
  Future<void> _removeExerciseFromWorkout(WorkoutExercise exercise, int index) async {
    if (_workout == null) return;
    await _flushPendingAutoSave();
    if (!mounted) return;

    // Don't allow removing the last exercise
    if (_workout!.exercises.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workoutDetailScreenCannotRemoveTheLast),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutDetailScreenRemoveExercise,
      message: 'Remove "${exercise.name}" from this workout?',
      confirmText: 'Remove',
      icon: Icons.remove_circle_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    try {
      // Create updated exercises list without the removed exercise
      final updatedExercises = List<WorkoutExercise>.from(_workout!.exercises)
        ..removeAt(index);

      // Convert to JSON format for API
      final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await workoutRepo.updateWorkoutExercises(
        workoutId: widget.workoutId,
        exercises: exercisesJson,
      );

      if (mounted) {
        if (updatedWorkout != null) {
          setState(() => _workout = updatedWorkout);
          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
          ref.read(workoutsProvider.notifier).silentRefresh();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${exercise.name} removed from workout'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).workoutDetailScreenFailedToRemoveExercise),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove exercise: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  /// Add exercise to never recommend list
  Future<void> _neverRecommendExercise(WorkoutExercise exercise) async {
    // Show confirmation dialog
    final confirmed = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutDetailScreenNeverRecommend,
      message: 'Block "${exercise.name}" from all future AI recommendations?\n\n'
          'You can undo this in Settings > Exercise Preferences.',
      confirmText: 'Block',
      icon: Icons.block_rounded,
    );

    if (confirmed != true || !mounted) return;

    // Initialize avoided provider if needed
    await ref.read(avoidedProvider.notifier).ensureInitialized();

    final success = await ref.read(avoidedProvider.notifier).addAvoided(
      exercise.name,
      exerciseId: exercise.exerciseId,
      reason: 'user_blocked',
      isTemporary: false,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${exercise.name} will no longer be recommended'),
              ],
            ),
            backgroundColor: AppColors.purple,
          ),
        );

        // Reload workout to remove the blocked exercise if needed
        _loadWorkout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).workoutDetailScreenFailedToBlockExercise),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '$mins min $secs sec' : '$mins min';
    }
    return '$seconds sec';
  }

}

/// Google-Health-parity actions for the workout detail screen:
/// Adjust (+ Undo), Save to library, Mark as done, thumbs up/down, Shuffle.
///
/// All methods are surgical additions — they reuse the existing
/// [_loadWorkout] reload path and never disturb the "Let's Go" start flow.
extension _WorkoutDetailScreenStateParityActions on _WorkoutDetailScreenState {

  /// Build the studio params for this workout. Prefer the params the workout
  /// was originally generated with (stored in generationMetadata) so the
  /// studio opens pre-seeded with the user's real preferences; fall back to
  /// defaults when the workout predates studio metadata.
  WorkoutBuildParams _studioParamsFromWorkout(Workout workout) {
    // Seed the equipment override from the workout's CURRENT exercises so the
    // "Equipment for this workout" picker opens pre-selected (Smith/Cable/Lat…)
    // instead of "0 selected". Empty => keep null so the override falls back to
    // the user's profile equipment rather than forcing an empty selection.
    final seededEquipment = _seedEquipmentFromWorkout(workout);

    final raw = workout.generationMetadata?['studio_params'];
    if (raw is Map) {
      try {
        var stored = WorkoutBuildParams.fromJson(Map<String, dynamic>.from(raw));
        // Reconcile duration: the stored studio_params.duration_minutes can be
        // stale (an old 20 or 45 from a prior generation) while the workout's
        // actual duration has since changed. Prefer the workout's CURRENT
        // duration so the slider opens at what the user currently sees, not a
        // stale seed that makes "Apply changes" look like it rebuilds shorter.
        final actualDuration =
            workout.durationMinutes ?? workout.estimatedDurationMinutes;
        if (actualDuration != null &&
            actualDuration > 0 &&
            actualDuration != stored.durationMinutes) {
          stored = stored.copyWith(durationMinutes: actualDuration);
        }
        // Prefer the stored params, but seed equipment from the live workout
        // when the stored params didn't carry an explicit override.
        if ((stored.equipment == null || stored.equipment!.isEmpty) &&
            seededEquipment.isNotEmpty) {
          return stored.copyWith(equipment: seededEquipment);
        }
        return stored;
      } catch (e) {
        debugPrint('⚠️ [WorkoutDetail] Bad studio_params, using defaults: $e');
      }
    }
    // No studio metadata (older / regenerated workouts). Derive the focus from
    // the workout's actual type/muscles so the Adjust sheet pre-selects the
    // real focus instead of defaulting Target muscles to "Full body".
    // ALSO seed duration + intensity from the real workout — otherwise these
    // fall to WorkoutBuildParams defaults (20 min / moderate), which made the
    // "Your current workout" card show "20 min" for a 60-min workout and made
    // "Apply changes" rebuild toward 20 min (looked like it did nothing).
    final realDuration =
        workout.durationMinutes ?? workout.estimatedDurationMinutes;
    return WorkoutBuildParams(
      focusAreas: _deriveFocusAreas(workout),
      equipment: seededEquipment.isEmpty ? null : seededEquipment,
      durationMinutes: realDuration ?? const WorkoutBuildParams().durationMinutes,
      intensity: _intensityFromDifficulty(workout.difficulty),
    );
  }

  /// Map a workout's `difficulty` onto the studio's intensity vocabulary
  /// (light | moderate | intense). Unknown/absent → moderate.
  String _intensityFromDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase().trim()) {
      case 'beginner':
      case 'easy':
      case 'light':
        return 'light';
      case 'advanced':
      case 'expert':
      case 'hard':
      case 'intense':
        return 'intense';
      case 'intermediate':
      case 'medium':
      case 'moderate':
      default:
        return 'moderate';
    }
  }

  /// Map the workout's current equipment (`workout.equipmentNeeded`, which are
  /// display-ish names like "Cable Machine"/"Lat Pulldown") onto the canonical
  /// snake_case tokens the equipment picker stores (`commonEquipmentOptions`).
  /// Names that don't normalize onto a known token are dropped so we never seed
  /// a token the picker can't render. De-duped, order-preserving.
  List<String> _seedEquipmentFromWorkout(Workout workout) {
    final tokens = <String>[];
    final seen = <String>{};
    for (final name in workout.equipmentNeeded) {
      final token = name.toLowerCase().trim().replaceAll(' ', '_');
      if (token.isEmpty) continue;
      if (!commonEquipmentOptions.contains(token)) continue;
      if (seen.add(token)) tokens.add(token);
    }
    return tokens;
  }

  /// Map a workout's `type` (and, failing that, its `primaryMuscles`) onto the
  /// customization-studio focus-chip tokens (see `_muscleGroups` in
  /// customization_studio_sheet.dart: full_body / upper / lower / push / pull /
  /// chest / back / legs / core / glutes / arms / shoulders). Falls back to
  /// ['full_body'] only when nothing maps.
  List<String> _deriveFocusAreas(Workout workout) {
    // 1) Workout type — the strongest signal for a split day.
    final type = (workout.type ?? '').toLowerCase().trim();
    const typeToFocus = <String, String>{
      'lower': 'lower',
      'lower_body': 'lower',
      'upper': 'upper',
      'upper_body': 'upper',
      'push': 'push',
      'pull': 'pull',
      'legs': 'legs',
      'leg': 'legs',
      'core': 'core',
      'abs': 'core',
      'chest': 'chest',
      'back': 'back',
      'shoulders': 'shoulders',
      'arms': 'arms',
      'glutes': 'glutes',
      'full_body': 'full_body',
      'fullbody': 'full_body',
      'total_body': 'full_body',
    };
    final fromType = typeToFocus[type];
    if (fromType != null) return [fromType];

    // 2) Otherwise derive from the muscle groups actually trained. Map each
    //    primary muscle to a focus token and keep the distinct set (max 3 so
    //    the chip pre-selection stays readable).
    final tokens = <String>{};
    for (final muscle in workout.primaryMuscles) {
      final token = _muscleToFocusToken(muscle);
      if (token != null) tokens.add(token);
    }
    if (tokens.isNotEmpty) {
      return tokens.take(3).toList(growable: false);
    }

    // 3) Nothing usable — keep the safe default.
    return const ['full_body'];
  }

  /// Resolve a raw muscle name onto a focus-chip token. Returns null when the
  /// muscle doesn't cleanly map to a chip (so it's simply skipped).
  String? _muscleToFocusToken(String muscle) {
    final m = muscle.toLowerCase().trim();
    if (m.isEmpty) return null;
    if (m.contains('chest') || m.contains('pec')) return 'chest';
    if (m.contains('back') ||
        m.contains('lat') ||
        m.contains('trap') ||
        m.contains('rhomboid')) {
      return 'back';
    }
    if (m.contains('shoulder') || m.contains('delt')) return 'shoulders';
    if (m.contains('bicep') ||
        m.contains('tricep') ||
        m.contains('forearm') ||
        m.contains('arm')) {
      return 'arms';
    }
    if (m.contains('glute')) return 'glutes';
    if (m.contains('quad') ||
        m.contains('hamstring') ||
        m.contains('calf') ||
        m.contains('calves') ||
        m.contains('leg') ||
        m.contains('adductor') ||
        m.contains('abductor')) {
      return 'legs';
    }
    if (m.contains('core') ||
        m.contains('ab') ||
        m.contains('oblique')) {
      return 'core';
    }
    return null;
  }

  /// Snapshot the workout's current state into a [BuiltWorkout] so an Undo
  /// can restore it verbatim via adapt(prebuilt: ...). Captures the exact
  /// exercise maps currently shown (post-edits), not the server's copy.
  BuiltWorkout _snapshotBuiltWorkout(Workout workout) {
    return BuiltWorkout(
      name: workout.name ?? 'Workout',
      type: workout.type ?? 'full_body',
      difficulty: workout.difficulty ?? 'moderate',
      durationMinutes: workout.durationMinutes ?? 45,
      targetMuscles: List<String>.from(workout.primaryMuscles),
      exercises: workout.exercises.map((e) => e.toJson()).toList(),
    );
  }

  /// Reload the detail screen after a studio mutation. Prefer the in-place
  /// re-fetch (keeps scroll/screen state); the route-replacement fallback is
  /// only used if the workout id is somehow missing.
  Future<void> _reloadAfterMutation() async {
    final wid = _workout?.id;
    if (wid == null || wid.isEmpty) {
      if (mounted) context.pushReplacement('/workout/${widget.workoutId}');
      return;
    }
    await _loadWorkout();
    if (!mounted) return;
    // Keep home / list views in sync with the freshly-adapted plan.
    try {
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      ref.read(workoutsProvider.notifier).silentRefresh();
    } catch (_) {/* best effort */}
  }

  // ── SAVE TO LIBRARY ──────────────────────────────────────────────────────

  Future<void> _saveToLibrary(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) {
      _showSnackBar('Cannot save — workout not ready yet', isError: true);
      return;
    }
    HapticService.selection();
    try {
      final saved = await showSaveToLibrarySheet(
        context,
        workoutId: wid,
        defaultName: 'Copy of ${workout.name ?? 'Workout'}',
      );
      if (!mounted) return;
      if (saved) _showSnackBar('Saved to your library');
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Save to library failed: $e');
      if (mounted) _showSnackBar('Could not save: $e', isError: true);
    }
  }

  // ── ADJUST WORKOUT (+ UNDO) ──────────────────────────────────────────────

  Future<void> _adjustWorkout(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) {
      _showSnackBar('Cannot adjust — workout not ready yet', isError: true);
      return;
    }
    if (_actionInFlight) return;
    HapticService.selection();

    // Snapshot BEFORE opening the studio so Undo restores the pre-adjust plan.
    final snapshot = _snapshotBuiltWorkout(workout);

    try {
      final result = await showCustomizationStudio(
        context,
        workoutId: wid,
        initialParams: _studioParamsFromWorkout(workout),
        replaceInPlace: true,
      );
      if (!mounted || result == null) return;

      await _reloadAfterMutation();
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Workout adjusted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoAdjust(wid, snapshot),
            ),
          ),
        );
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Adjust workout failed: $e');
      if (mounted) _showSnackBar('Could not adjust: $e', isError: true);
    }
  }

  /// Restore the pre-adjust snapshot by re-adapting in place with the exact
  /// previewed payload (WYSIWYG), then reload.
  Future<void> _undoAdjust(String workoutId, BuiltWorkout snapshot) async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    HapticService.selection();
    try {
      await ref.read(workoutStudioServiceProvider).adapt(
            workoutId,
            replaceInPlace: true,
            prebuilt: snapshot,
          );
      await _reloadAfterMutation();
      if (mounted) _showSnackBar('Reverted to the previous workout');
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Undo adjust failed: $e');
      if (mounted) _showSnackBar('Could not undo: $e', isError: true);
    } finally {
      _actionInFlight = false;
    }
  }

  // ── MARK AS DONE ─────────────────────────────────────────────────────────

  Future<void> _markAsDone(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    if (workout.isCompleted == true || _markedDoneLocal) return;
    if (_actionInFlight) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Mark as done?',
      message:
          'Log this workout as completed without running the timer. '
          'No personal records will be created.',
      confirmText: 'Mark as done',
      icon: Icons.check_circle_outline_rounded,
    );
    if (confirmed != true || !mounted) return;

    _actionInFlight = true;
    HapticService.selection();
    try {
      await ref.read(apiClientProvider).post(
        '${ApiConstants.workouts}/$wid/complete',
        queryParameters: {'completion_method': 'marked_done'},
      );
      if (!mounted) return;
      setState(() => _markedDoneLocal = true);
      _showSnackBar('Logged as done');
      // Pull the canonical completed row + refresh dependent views.
      await _reloadAfterMutation();
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Mark as done failed: $e');
      if (mounted) _showSnackBar('Could not log workout: $e', isError: true);
    } finally {
      _actionInFlight = false;
    }
  }

  // ── THUMBS ───────────────────────────────────────────────────────────────

  Future<void> _onThumbs(Workout workout, int direction) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    HapticService.selection();

    // Toggle: tapping an already-active thumb clears it (sends 0).
    final next = (_thumbs == direction) ? 0 : direction;
    setState(() => _thumbs = next);

    try {
      await ref.read(workoutStudioServiceProvider).sendThumbs(wid, next);
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] sendThumbs failed: $e');
      // Roll back the local toggle so the UI never lies about a failed write.
      if (mounted) {
        setState(() => _thumbs = (next == direction) ? 0 : direction);
        _showSnackBar('Could not save feedback', isError: true);
      }
      return;
    }

    // Thumbs-down opens the studio so the user can express what they'd change.
    if (next == -1 && mounted) {
      try {
        final result = await showCustomizationStudio(
          context,
          workoutId: wid,
          initialParams: _studioParamsFromWorkout(workout),
          replaceInPlace: true,
        );
        if (mounted && result != null) {
          await _reloadAfterMutation();
          if (mounted) _showSnackBar('Workout updated');
        }
      } catch (e) {
        debugPrint('❌ [WorkoutDetail] Thumbs-down adjust failed: $e');
        if (mounted) _showSnackBar('Could not open editor: $e', isError: true);
      }
    }
  }

  // ── SHUFFLE ──────────────────────────────────────────────────────────────

  Future<void> _shuffleWorkout(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    if (_actionInFlight) return;
    _actionInFlight = true;
    HapticService.selection();
    try {
      await ref.read(workoutStudioServiceProvider).shuffle(wid);
      await _reloadAfterMutation();
      if (mounted) _showSnackBar('Shuffled in fresh exercises');
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Shuffle failed: $e');
      if (mounted) _showSnackBar('Could not shuffle: $e', isError: true);
    } finally {
      _actionInFlight = false;
    }
  }

  // ── OVERFLOW MENU — fully flattened. The old "More actions" row opened a
  // SEPARATE actions sheet (an extra tap); now every action is inlined into one
  // sectioned sheet: a "Quick" group (Mark done, Shuffle) + an "Options" group
  // (Reschedule, Regenerate, Version history, Generate warm-up, Generate
  // stretches, Share when completed) + Delete visually separated at the bottom.
  // `showWorkoutActionsSheet` is intentionally left intact for other callers.
  Future<void> _showParityOverflowMenu(Workout workout) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;
    final alreadyDone = workout.isCompleted == true || _markedDoneLocal;
    final isCompleted = workout.isCompleted == true;

    Widget groupLabel(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text.toUpperCase(),
              style: ZType.lbl(11, color: textMuted, letterSpacing: 1.6),
            ),
          ),
        );

    Widget actionTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool destructive = false,
    }) {
      final color = destructive ? AppColors.error : accentColor;
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: ZType.sans(15.5,
              color: destructive ? AppColors.error : textPrimary,
              weight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle,
              style: ZType.sans(12.5,
                  color: textMuted, weight: FontWeight.w400, height: 1.25)),
        ),
        onTap: onTap,
      );
    }

    HapticService.selection();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Quick group ──
              groupLabel('Quick'),
              if (!alreadyDone)
                actionTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Mark as done',
                  subtitle: 'Log as completed, no PRs',
                  onTap: () {
                    Navigator.pop(ctx);
                    _markAsDone(workout);
                  },
                ),
              actionTile(
                icon: Icons.shuffle_rounded,
                title: 'Shuffle exercises',
                subtitle: 'Re-roll with fresh picks',
                onTap: () {
                  Navigator.pop(ctx);
                  _shuffleWorkout(workout);
                },
              ),

              // ── Options group (was behind "More actions") ──
              groupLabel('Options'),
              actionTile(
                icon: Icons.calendar_month_rounded,
                title: 'Reschedule',
                subtitle: 'Change the workout date',
                onTap: () {
                  Navigator.pop(ctx);
                  _menuReschedule(workout);
                },
              ),
              actionTile(
                icon: Icons.refresh_rounded,
                title: 'Regenerate',
                subtitle: 'Create a new workout for this day',
                onTap: () {
                  Navigator.pop(ctx);
                  _menuRegenerate(workout);
                },
              ),
              actionTile(
                icon: Icons.history_rounded,
                title: 'Version history',
                subtitle: 'View and restore previous versions',
                onTap: () {
                  Navigator.pop(ctx);
                  _menuVersionHistory(workout);
                },
              ),
              actionTile(
                icon: Icons.directions_run_rounded,
                title: 'Generate warm-up',
                subtitle: 'Create warm-up exercises',
                onTap: () {
                  Navigator.pop(ctx);
                  _menuGenerateTimed(workout, isWarmup: true);
                },
              ),
              actionTile(
                icon: Icons.self_improvement_rounded,
                title: 'Generate stretches',
                subtitle: 'Create cool-down stretches',
                onTap: () {
                  Navigator.pop(ctx);
                  _menuGenerateTimed(workout, isWarmup: false);
                },
              ),
              if (isCompleted)
                actionTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Share workout',
                  subtitle: 'Get a ${Branding.marketingDomain} link for friends',
                  onTap: () {
                    Navigator.pop(ctx);
                    _menuShare(workout);
                  },
                ),

              // ── Delete, visually separated ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Divider(
                    height: 1, color: cardBorder.withValues(alpha: 0.5)),
              ),
              actionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete workout',
                subtitle: 'Remove this workout',
                destructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _menuDelete(workout);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Inlined overflow-menu action handlers ────────────────────────────────
  // These replicate the minimal repo/provider calls the standalone
  // workout_actions_sheet uses (its handlers are private to that widget), so
  // the flattened menu acts directly without a nested sheet.

  /// Reschedule: pick a date, persist via the repo, refresh dependent views.
  Future<void> _menuReschedule(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(workout.scheduledDate ?? '') ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final ok = await repo.rescheduleWorkout(
        wid,
        picked.toIso8601String().split('T')[0],
      );
      if (!mounted) return;
      if (ok) {
        await _reloadAfterMutation();
        if (mounted) _showSnackBar('Workout rescheduled');
      } else {
        _showSnackBar('Failed to reschedule workout', isError: true);
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Reschedule failed: $e');
      if (mounted) _showSnackBar('Failed to reschedule: $e', isError: true);
    }
  }

  /// Regenerate: confirm, then consume the streaming regenerate while showing a
  /// progress dialog (mirrors workout_actions_sheet behaviour 1:1).
  Future<void> _menuRegenerate(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    final confirm = await AppDialog.confirm(
      context,
      title: 'Regenerate workout?',
      message:
          'This creates a brand-new workout for this day, replacing the current one.',
      confirmText: 'Regenerate',
      icon: Icons.refresh_rounded,
    );
    if (confirm != true || !mounted) return;

    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;

    // Lightweight progress dialog driven by the SSE step messages.
    final progress = ValueNotifier<String>('Starting regeneration…');
    BuildContext? dialogContext;
    // ignore: unawaited_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dctx) {
        dialogContext = dctx;
        final accent = ref.colors(dctx).accent;
        return AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: progress,
                  builder: (_, msg, __) =>
                      Text(msg, style: ZType.sans(14, weight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        );
      },
    );

    Workout? generated;
    String? error;
    try {
      final repo = ref.read(workoutRepositoryProvider);
      await for (final p in repo.regenerateWorkoutStreaming(
        workoutId: wid,
        userId: userId,
      )) {
        if (!mounted) break;
        if (p.hasError) {
          error = p.message;
          break;
        }
        if (p.message.isNotEmpty) {
          progress.value = '${p.message} (${p.step}/${p.totalSteps})';
        }
        if (p.isCompleted && p.workout != null) {
          generated = p.workout;
          break;
        }
      }
    } catch (e) {
      error = e.toString();
    }

    // Close the progress dialog via its own context.
    final dctx = dialogContext;
    if (dctx != null && dctx.mounted && Navigator.canPop(dctx)) {
      Navigator.of(dctx).pop();
    }
    progress.dispose();

    if (!mounted) return;
    if (generated != null) {
      await _reloadAfterMutation();
      if (mounted) _showSnackBar('Workout regenerated');
    } else {
      _showSnackBar(
          error != null ? 'Regenerate failed: $error' : 'Could not regenerate',
          isError: true);
    }
  }

  /// Version history: fetch versions and show a compact restore list.
  Future<void> _menuVersionHistory(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    List<Map<String, dynamic>> versions;
    try {
      versions = await ref.read(workoutRepositoryProvider).getWorkoutVersions(wid);
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Version history failed: $e');
      if (mounted) _showSnackBar('Could not load history: $e', isError: true);
      return;
    }
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = ref.colors(context).accent;

    await showGlassSheet(
      context: context,
      builder: (sheetCtx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Text('Version history',
                      style: ZType.sans(17,
                          color: textPrimary, weight: FontWeight.w800)),
                ],
              ),
            ),
            if (versions.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Text('No previous versions yet.',
                    style: ZType.sans(14, color: textMuted)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: versions.length,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (lc, i) {
                    final v = versions[i];
                    final versionNum = v['version'] ?? (i + 1);
                    final name = v['name']?.toString() ?? 'Version $versionNum';
                    final isCurrent = i == 0;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isCurrent
                            ? accent.withValues(alpha: 0.2)
                            : (isDark
                                ? AppColors.elevated
                                : AppColorsLight.elevated),
                        child: Text('v$versionNum',
                            style: ZType.data(11,
                                color: isCurrent ? accent : textMuted,
                                weight: FontWeight.w700)),
                      ),
                      title: Text(name,
                          style: ZType.sans(14,
                              color: textPrimary, weight: FontWeight.w600)),
                      trailing: isCurrent
                          ? Text('CURRENT',
                              style: ZType.lbl(10, color: AppColors.success))
                          : TextButton(
                              onPressed: () async {
                                final ok = await AppDialog.confirm(
                                  context,
                                  title: 'Revert to this version?',
                                  message: 'Restore "$name"?',
                                  confirmText: 'Revert',
                                  icon: Icons.restore_rounded,
                                );
                                if (ok != true) return;
                                try {
                                  await ref
                                      .read(workoutRepositoryProvider)
                                      .revertWorkout(wid, versionNum as int);
                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  await _reloadAfterMutation();
                                  if (mounted) _showSnackBar('Reverted to $name');
                                } catch (e) {
                                  if (mounted) {
                                    _showSnackBar('Revert failed: $e',
                                        isError: true);
                                  }
                                }
                              },
                              child: Text('Revert',
                                  style: ZType.lbl(12, color: accent)),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Generate warm-up or stretches, then show the generated list in a compact
  /// sheet. After generating we also clear the cached section so the in-screen
  /// Warm Up / Cool Down section re-fetches the fresh data.
  Future<void> _menuGenerateTimed(Workout workout,
      {required bool isWarmup}) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    final label = isWarmup ? 'warm-up' : 'stretches';
    _showSnackBar('Generating $label…');
    List<Map<String, dynamic>> items;
    try {
      final repo = ref.read(workoutRepositoryProvider);
      items = isWarmup
          ? await repo.generateWarmup(wid)
          : await repo.generateStretches(wid);
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Generate $label failed: $e');
      if (mounted) _showSnackBar('Failed to generate $label: $e', isError: true);
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      _showSnackBar('Could not generate $label', isError: true);
      return;
    }
    // Refresh the in-screen section so the new data appears there too.
    setState(() {
      if (isWarmup) {
        _warmupData = null;
      } else {
        _stretchData = null;
      }
    });
    unawaited(_loadWarmupAndStretches());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final color = isWarmup ? AppColors.orange : AppColors.purple;

    await showGlassSheet(
      context: context,
      builder: (sheetCtx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(
                      isWarmup
                          ? Icons.directions_run_rounded
                          : Icons.self_improvement_rounded,
                      color: color,
                      size: 20),
                  const SizedBox(width: 10),
                  Text(isWarmup ? 'Warm-up' : 'Cool-down stretches',
                      style: ZType.sans(17,
                          color: textPrimary, weight: FontWeight.w800)),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                itemBuilder: (lc, i) {
                  final ex = items[i];
                  final name = ex['name']?.toString() ?? 'Exercise ${i + 1}';
                  final duration =
                      ex['duration_seconds'] ?? ex['duration'] ?? 30;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.glassSurface
                          : AppColorsLight.glassSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              style: ZType.sans(14,
                                  color: textPrimary, weight: FontWeight.w600)),
                        ),
                        Text('${duration}s',
                            style: ZType.data(12, color: color)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Added to this workout. Find them in the ${isWarmup ? 'Warm Up' : 'Cool Down'} section.',
                style: ZType.sans(12, color: textMuted, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Share: create a public link (completed workouts only) and open the OS
  /// share sheet, copying to the clipboard first as a guaranteed fallback.
  Future<void> _menuShare(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/workouts/$wid/share-link');
      final data = res.data;
      final url = (data is Map && data['url'] is String)
          ? data['url'] as String
          : null;
      if (!mounted) return;
      if (url == null) {
        _showSnackBar('Could not create share link', isError: true);
        return;
      }
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) _showSnackBar('Link copied to clipboard');
      await Share.share(
        '${workout.name ?? 'My workout'} — ${Branding.appName}\n$url',
        subject: '${Branding.appName} workout',
      );
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Share failed: $e');
      if (mounted) _showSnackBar('Share failed: $e', isError: true);
    }
  }

  /// Delete: confirm, delete via the repo, and pop back to the list.
  Future<void> _menuDelete(Workout workout) async {
    final wid = workout.id;
    if (wid == null || wid.isEmpty) return;
    final confirm = await AppDialog.destructive(
      context,
      title: 'Delete workout?',
      message: 'This action cannot be undone.',
      icon: Icons.delete_rounded,
    );
    if (confirm != true || !mounted) return;
    try {
      final ok = await ref.read(workoutRepositoryProvider).deleteWorkout(wid);
      if (!mounted) return;
      if (ok) {
        try {
          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
          ref.read(workoutsProvider.notifier).silentRefresh();
        } catch (_) {/* best effort */}
        _showSnackBar('Workout deleted');
        if (context.canPop()) context.pop();
      } else {
        _showSnackBar('Failed to delete workout', isError: true);
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Delete failed: $e');
      if (mounted) _showSnackBar('Failed to delete: $e', isError: true);
    }
  }
}
