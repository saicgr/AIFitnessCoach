part of 'workout_detail_screen.dart';

/// Methods extracted from _WorkoutDetailScreenState
extension __WorkoutDetailScreenStateExt2 on _WorkoutDetailScreenState {

  /// Break superset (long-press on header)
  Future<void> _breakSuperset(int groupNumber) async {
    final confirm = await AppDialog.destructive(
      context,
      title: 'Break Superset?',
      message: 'This will unlink these exercises so they are performed separately.',
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
          ref.invalidate(todayWorkoutProvider);
          ref.invalidate(workoutsProvider);
        }
      },
      onLinkSuperset: exercise.isInSuperset
          ? null  // Already in a superset
          : () => _startSupersetPairing(index),
      onViewHistory: () {
        // Navigate to exercise history screen with exercise name
        final encodedName = Uri.encodeComponent(exercise.name);
        context.push('/stats/exercise-history/$encodedName');
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
        const SnackBar(
          content: Text('Cannot remove the last exercise'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Remove Exercise',
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
          ref.invalidate(todayWorkoutProvider);
          ref.invalidate(workoutsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${exercise.name} removed from workout'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove exercise'),
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
      title: 'Never Recommend',
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
            content: const Text('Failed to block exercise'),
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
