part of 'hero_workout_card.dart';

/// Methods extracted from _HeroWorkoutCardState
extension __HeroWorkoutCardStateExt on _HeroWorkoutCardState {

  Future<void> _markAsDone() async {
    final dateLabel = _getScheduledDateLabel(widget.workout.scheduledDate);
    final isToday = dateLabel == 'TODAY';
    final dialogMessage = isToday
        ? 'This will mark the workout as completed without tracking sets.'
        : 'Mark workout for $dateLabel as done? This will mark it as completed without tracking sets.';

    final confirm = await AppDialog.confirm(
      context,
      title: 'Mark as Done?',
      message: dialogMessage,
      confirmText: 'Mark Done',
      confirmColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );

    if (!confirm) return;

    setState(() => _isMarkingDone = true);

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.markWorkoutAsDone(widget.workout.id!);

      if (result != null && mounted) {
        ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
        ref.read(workoutsProvider.notifier).silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout marked as done!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark workout as done'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isMarkingDone = false);
    }
  }


  void _showOptionsMenu() {
    HapticService.light();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Glance Workout
              ListTile(
                leading: Icon(
                  Icons.remove_red_eye_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Glance Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showGlanceWorkout();
                },
              ),
              // View Workout
              ListTile(
                leading: Icon(
                  Icons.visibility_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'View Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/workout/${widget.workout.id}', extra: widget.workout);
                },
              ),
              // Add Exercises
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Add Exercises',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addExercises();
                },
              ),
              // Ask Coach
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Ask Coach',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final workoutName = widget.workout.name ?? 'your workout';
                  final exerciseCount = widget.workout.exerciseCount;
                  final duration = widget.workout.formattedDurationShort;
                  context.push(
                    '/chat',
                    extra: {
                      'initialMessage':
                          'I have questions about my upcoming workout "$workoutName" ($exerciseCount exercises, $duration). Can you help me prepare for it?',
                    },
                  );
                },
              ),
              // Regenerate Workout
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Regenerate Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _regenerateWorkout();
                },
              ),
              // Share to Social
              ListTile(
                leading: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Share to Social',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareToSocial();
                },
              ),
              // Mark as Done
              ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: isDark ? AppColors.success : AppColors.success,
                ),
                title: Text(
                  'Mark as Done',
                  style: TextStyle(
                    color: isDark ? AppColors.success : AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _markAsDone();
                },
              ),
              // Divider before destructive action
              const Divider(height: 1),
              // Skip Workout
              ListTile(
                leading: const Icon(
                  Icons.skip_next_outlined,
                  color: AppColors.textMuted,
                ),
                title: const Text(
                  'Skip Workout',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _skipWorkout();
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }


  void _showGlanceWorkout() {
    final workout = widget.workout;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stats
              Text(
                '${workout.formattedDurationShort} • ${workout.exerciseCount} exercises',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              // Exercise list
              ...workout.exercises.take(5).map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.sets ?? 0} sets',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (workout.exercises.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${workout.exercises.length - 5} more exercises',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
