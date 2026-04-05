part of 'exercise_detail_sheet.dart';


class _ExerciseActionButtonsState extends ConsumerState<_ExerciseActionButtons> {
  bool _showStaplePills = false;
  bool _isProcessing = false;
  bool _currentWorkout = true; // true = current workout, false = upcoming

  Future<void> _handleStaple(String section) async {
    if (_isProcessing) return;

    // Show choice sheet to collect params (sets, reps, weight, cardio, target days)
    final choice = await showStapleChoiceSheet(
      context,
      exerciseName: widget.exerciseName,
      equipmentValue: widget.equipmentValue,
      category: widget.category,
      initialSection: section,
    );
    if (choice == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(staplesProvider.notifier).addStaple(
        widget.exerciseName,
        muscleGroup: widget.muscleGroup,
        section: choice.section,
        addToCurrentWorkout: choice.addToday,
        gymProfileId: choice.gymProfileId,
        swapExerciseId: choice.swapExerciseId,
        cardioParams: choice.cardioParams,
        userSets: choice.userSets,
        userReps: choice.userReps,
        userRestSeconds: choice.userRestSeconds,
        userWeightLbs: choice.userWeightLbs,
        targetDays: choice.targetDays,
      );
      if (mounted) {
        setState(() { _showStaplePills = false; _isProcessing = false; });
        if (success) {
          final timing = choice.addToday ? 'current workout' : 'upcoming workouts';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.push_pin, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Stapled "${widget.exerciseName}" to ${choice.section} ($timing)')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to staple: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleUnstaple() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await ref.read(staplesProvider.notifier).toggleStaple(
      widget.exerciseName,
      muscleGroup: widget.muscleGroup,
    );
    if (mounted) {
      setState(() { _showStaplePills = false; _isProcessing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.push_pin_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('"${widget.exerciseName}" unstapled'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleReplaceExercise() async {
    final todayResponse = ref.read(todayWorkoutProvider).valueOrNull;
    final workout = todayResponse?.todayWorkout ?? todayResponse?.nextWorkout;
    final exercises = workout?.exercises ?? [];

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No exercises in current workout to replace'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Replace which exercise?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (ctx, index) {
              final ex = exercises[index];
              return ListTile(
                leading: Icon(Icons.fitness_center, size: 18, color: textMuted),
                title: Text(
                  ex.name,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
                subtitle: ex.muscleGroup != null
                    ? Text(ex.muscleGroup!, style: TextStyle(fontSize: 12, color: textMuted))
                    : null,
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => Navigator.pop(ctx, ex.name),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => _isProcessing = true);
      final success = await ref.read(staplesProvider.notifier).addStaple(
        widget.exerciseName,
        muscleGroup: widget.muscleGroup,
        section: 'main',
        addToCurrentWorkout: _currentWorkout,
        swapExerciseId: selected,
      );
      if (mounted) {
        setState(() { _showStaplePills = false; _isProcessing = false; });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Replaced "$selected" with "${widget.exerciseName}"')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildStaplePillsSection(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final isAlreadyStaple = ref.watch(staplesProvider).isStaple(widget.exerciseName);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timing toggle row
          Row(
            children: [
              Expanded(
                child: _buildTimingChip(
                  'Current Workout',
                  isSelected: _currentWorkout,
                  onTap: () => setState(() => _currentWorkout = true),
                  isDark: isDark,
                  cyan: cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimingChip(
                  'Upcoming Workouts',
                  isSelected: !_currentWorkout,
                  onTap: () => setState(() => _currentWorkout = false),
                  isDark: isDark,
                  cyan: cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 1: section pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isAlreadyStaple)
                _buildPill(
                  'Unstaple',
                  Icons.push_pin_outlined,
                  onTap: _handleUnstaple,
                  color: AppColors.error,
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
              _buildPill(
                'Add to Warmup',
                Icons.whatshot_outlined,
                onTap: () => _handleStaple('warmup'),
                color: AppColors.orange,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              _buildPill(
                'Add to Stretch',
                Icons.self_improvement,
                onTap: () => _handleStaple('stretches'),
                color: purple,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: action pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(
                'Add as Exercise',
                Icons.add,
                onTap: () => _handleStaple('main'),
                color: cyan,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              _buildPill(
                'Replace Exercise',
                Icons.swap_horiz,
                onTap: _handleReplaceExercise,
                color: AppColors.orange,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color cyan,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cyan : textMuted.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? cyan : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Watch providers for state
    final isFavorite = ref.watch(favoritesProvider).isFavorite(widget.exerciseName);
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(widget.exerciseName);
    final isAvoided = ref.watch(avoidedProvider).isAvoided(widget.exerciseName);
    final isStaple = ref.watch(staplesProvider).isStaple(widget.exerciseName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated pills section (only when staple is tapped)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _showStaplePills
              ? _buildStaplePillsSection(isDark)
              : const SizedBox.shrink(),
        ),
        // Processing indicator
        if (_isProcessing)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: purple,
              ),
            ),
          ),
        // 4 floating action icons
        Container(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.97),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFloatingIcon(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: 'Favorite',
                  isActive: isFavorite,
                  activeColor: AppColors.error,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(favoritesProvider.notifier).toggleFavorite(widget.exerciseName);
                  },
                ),
                _buildFloatingIcon(
                  icon: isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                  label: 'Queue',
                  isActive: isQueued,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(exerciseQueueProvider.notifier).toggleQueue(
                      widget.exerciseName,
                      targetMuscleGroup: widget.muscleGroup,
                    );
                  },
                ),
                _buildFloatingIcon(
                  icon: isAvoided ? Icons.block : Icons.block_outlined,
                  label: 'Avoid',
                  isActive: isAvoided,
                  activeColor: AppColors.orange,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(avoidedProvider.notifier).toggleAvoided(widget.exerciseName);
                  },
                ),
                _buildFloatingIcon(
                  icon: isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                  label: 'Staple',
                  isActive: isStaple || _showStaplePills,
                  activeColor: purple,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    setState(() => _showStaplePills = !_showStaplePills);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

