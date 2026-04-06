part of 'exercise_navigation_mixin.dart';

/// Extension providing UI methods for exercise navigation mixin
extension ExerciseNavigationMixinUI on ExerciseNavigationMixin {

  // ── Helpers to access State<T> members through the mixin ──
  BuildContext get _ctx => (this as dynamic).context as BuildContext;
  bool get _mounted => (this as dynamic).mounted as bool;
  void _setState(VoidCallback fn) => (this as dynamic).setState(fn);

  /// Remove exercise from workout
  void removeExerciseFromWorkout(int index) {
    if (exercises.length <= 1) {
      ScaffoldMessenger.of(_ctx).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last exercise'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final removedExercise = exercises[index];

    _setState(() {
      exercises.removeAt(index);
      precomputeSupersetIndicesImpl();

      completedSets.remove(index);
      totalSetsPerExercise.remove(index);
      previousSets.remove(index);
      repProgressionPerExercise.remove(index);

      final newCompletedSets = <int, List<SetLog>>{};
      final newTotalSets = <int, int>{};
      final newPreviousSets = <int, List<Map<String, dynamic>>>{};
      final newRepProgressions = <int, RepProgressionType>{};

      completedSets.forEach((key, value) {
        if (key > index) {
          newCompletedSets[key - 1] = value;
        } else {
          newCompletedSets[key] = value;
        }
      });

      totalSetsPerExercise.forEach((key, value) {
        if (key > index) {
          newTotalSets[key - 1] = value;
        } else {
          newTotalSets[key] = value;
        }
      });

      previousSets.forEach((key, value) {
        if (key > index) {
          newPreviousSets[key - 1] = value;
        } else {
          newPreviousSets[key] = value;
        }
      });

      repProgressionPerExercise.forEach((key, value) {
        if (key > index) {
          newRepProgressions[key - 1] = value;
        } else {
          newRepProgressions[key] = value;
        }
      });

      completedSets
        ..clear()
        ..addAll(newCompletedSets);
      totalSetsPerExercise
        ..clear()
        ..addAll(newTotalSets);
      previousSets
        ..clear()
        ..addAll(newPreviousSets);
      repProgressionPerExercise
        ..clear()
        ..addAll(newRepProgressions);

      if (currentExerciseIndex >= exercises.length) {
        currentExerciseIndex = exercises.length - 1;
      }
      if (viewingExerciseIndex >= exercises.length) {
        viewingExerciseIndex = exercises.length - 1;
      }
    });

    ScaffoldMessenger.of(_ctx).showSnackBar(
      SnackBar(
        content: Text('${removedExercise.name} removed'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _setState(() {
              exercises.insert(index, removedExercise);
              precomputeSupersetIndicesImpl();
            });
          },
        ),
      ),
    );
  }


  /// Show the 3-dot "More" popup menu
  void showMoreMenu(WorkoutExercise exercise) {
    final isDark = Theme.of(_ctx).brightness == Brightness.dark;
    showMenu<String>(
      context: _ctx,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(_ctx).size.width - 200,
        kToolbarHeight + MediaQuery.of(_ctx).padding.top + 100,
        16,
        0,
      ),
      color: isDark ? WorkoutDesign.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
        ),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'swap',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 20, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              Text('Swap Exercise', style: TextStyle(
                color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'equipment',
          child: Row(
            children: [
              Icon(Icons.warehouse_outlined, size: 20, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text('My Gym', style: TextStyle(
                color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.purple.shade400),
              const SizedBox(width: 12),
              Text('History', style: TextStyle(
                color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'bar_type',
          enabled: isBarbell(exercise.equipment, exerciseName: exercise.name),
          child: Row(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: isBarbell(exercise.equipment, exerciseName: exercise.name)
                    ? Colors.teal.shade500
                    : (isDark ? WorkoutDesign.textSecondary.withValues(alpha: 0.3) : Colors.grey.shade400),
              ),
              const SizedBox(width: 12),
              Text('Bar Type', style: TextStyle(
                color: isBarbell(exercise.equipment, exerciseName: exercise.name)
                    ? (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900)
                    : (isDark ? WorkoutDesign.textSecondary.withValues(alpha: 0.3) : Colors.grey.shade400),
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'end_workout',
          child: Row(
            children: [
              Icon(Icons.stop_circle_outlined, size: 20, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text('End Workout', style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'swap') {
        showSwapSheetForIndex(viewingExerciseIndex);
      } else if (value == 'equipment') {
        showEquipmentProfileSheetImpl();
      } else if (value == 'history') {
        showHistorySheet(exercise);
      } else if (value == 'bar_type') {
        showBarTypeSelectorImpl(exercise);
      } else if (value == 'end_workout') {
        showQuitDialogImpl();
      }
    });
  }


  /// Handle superset creation from drag-and-drop on thumbnail strip
  void onSupersetFromDrag(int draggedIndex, int targetIndex) {
    HapticFeedback.mediumImpact();

    final draggedExercise = exercises[draggedIndex];
    final targetExercise = exercises[targetIndex];

    final existingGroupId = targetExercise.supersetGroup;
    final draggedGroupId = draggedExercise.supersetGroup;

    int groupId;
    String snackbarMessage;

    if (existingGroupId != null) {
      groupId = existingGroupId;

      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) {
            maxOrder = ex.supersetOrder!;
          }
        }
      }

      final groupCount = exercises.where((ex) => ex.supersetGroup == groupId).length + 1;
      snackbarMessage = 'Added ${draggedExercise.name} to superset ($groupCount exercises)';

      _setState(() {
        if (draggedGroupId != null && draggedGroupId != groupId) {
          final oldGroupMembers = exercises.where((ex) => ex.supersetGroup == draggedGroupId).toList();
          if (oldGroupMembers.length == 2) {
            for (int i = 0; i < exercises.length; i++) {
              if (exercises[i].supersetGroup == draggedGroupId && i != draggedIndex) {
                exercises[i] = exercises[i].copyWith(clearSuperset: true);
              }
            }
          }
        }

        exercises[draggedIndex] = exercises[draggedIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: maxOrder + 1,
        );

        moveExerciseToSuperset(draggedIndex, targetIndex);
      });
    } else if (draggedGroupId != null) {
      groupId = draggedGroupId;

      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) {
            maxOrder = ex.supersetOrder!;
          }
        }
      }

      final groupCount = exercises.where((ex) => ex.supersetGroup == groupId).length + 1;
      snackbarMessage = 'Added ${targetExercise.name} to superset ($groupCount exercises)';

      _setState(() {
        exercises[targetIndex] = exercises[targetIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: maxOrder + 1,
        );

        moveExerciseToSuperset(targetIndex, draggedIndex);
      });
    } else {
      int maxGroup = 0;
      for (final ex in exercises) {
        if (ex.supersetGroup != null && ex.supersetGroup! > maxGroup) {
          maxGroup = ex.supersetGroup!;
        }
      }
      groupId = maxGroup + 1;
      snackbarMessage = 'Superset: ${draggedExercise.name} + ${targetExercise.name}';

      _setState(() {
        exercises[draggedIndex] = exercises[draggedIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: 1,
        );
        exercises[targetIndex] = exercises[targetIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: 2,
        );

        moveExerciseToSuperset(draggedIndex, targetIndex);
      });
    }

    if (_mounted) {
      ScaffoldMessenger.of(_ctx).clearSnackBars();
      ScaffoldMessenger.of(_ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(snackbarMessage, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
          closeIconColor: Colors.white70,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => breakSuperset(groupId),
          ),
        ),
      );
    }
  }

}
