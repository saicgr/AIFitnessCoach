part of 'workout_detail_screen.dart';

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
  }) {
    // When in superset pairing mode, intercept taps for pairing instead of navigation
    final bool inPairingMode = supersetPairingIndex != null;
    final bool isSelf = supersetPairingIndex == index;

    return ExpandedExerciseCard(
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


  Future<void> _showWorkoutActions(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await showWorkoutActionsSheet(
      context,
      ref,
      workout,
      onRefresh: () {
        _loadWorkout();
      },
    );
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
    final raw = workout.generationMetadata?['studio_params'];
    if (raw is Map) {
      try {
        return WorkoutBuildParams.fromJson(Map<String, dynamic>.from(raw));
      } catch (e) {
        debugPrint('⚠️ [WorkoutDetail] Bad studio_params, using defaults: $e');
      }
    }
    return const WorkoutBuildParams();
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

  // ── OVERFLOW MENU (Mark as done + Shuffle), shown from the app-bar … button.
  // Wraps the existing actions sheet so we keep prior behaviour and add the
  // two new parity items above it.
  Future<void> _showParityOverflowMenu(Workout workout) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentColor = ref.colors(context).accent;
    final alreadyDone = workout.isCompleted == true || _markedDoneLocal;

    HapticService.selection();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
            const SizedBox(height: 8),
            if (!alreadyDone)
              ListTile(
                leading: Icon(Icons.check_circle_outline_rounded,
                    color: accentColor),
                title: Text('Mark as done',
                    style: TextStyle(color: textPrimary)),
                subtitle: const Text('Log as completed, no PRs'),
                onTap: () {
                  Navigator.pop(ctx);
                  _markAsDone(workout);
                },
              ),
            ListTile(
              leading: Icon(Icons.shuffle_rounded, color: accentColor),
              title:
                  Text('Shuffle exercises', style: TextStyle(color: textPrimary)),
              subtitle: const Text('Re-roll with fresh picks'),
              onTap: () {
                Navigator.pop(ctx);
                _shuffleWorkout(workout);
              },
            ),
            ListTile(
              leading: Icon(Icons.tune_rounded, color: textPrimary),
              title: Text('More actions', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showWorkoutActions(context, ref, workout);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
