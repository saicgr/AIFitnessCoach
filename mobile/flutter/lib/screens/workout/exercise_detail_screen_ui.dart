part of 'exercise_detail_screen.dart';

/// UI builder methods extracted from _ExerciseDetailScreenState
extension _ExerciseDetailScreenStateUI on _ExerciseDetailScreenState {

  Widget _buildStatsTabContent(Color textMuted) {
    final exerciseName = widget.exercise.name;
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseName));
    final prsAsync = ref.watch(exercisePRsProvider(exerciseName));
    final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
    final chartType = ref.watch(exerciseChartTypeProvider);

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Error loading stats: $error')),
      ),
      data: (history) {
        if (!history.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined, size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No stats for this exercise yet',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a workout to start tracking',
                    style: TextStyle(color: textMuted.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseTimeRangeSelector(
              selected: timeRange,
              onChanged: (value) {
                ref.read(exerciseHistoryTimeRangeProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),

            if (history.summary != null)
              ExerciseSummaryCard(summary: history.summary!),
            const SizedBox(height: 16),

            ExerciseChartTypeSelector(
              selected: chartType,
              onChanged: (value) {
                ref.read(exerciseChartTypeProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 12),

            ExerciseProgressionChart(
              history: history,
              chartType: chartType,
            ),
            const SizedBox(height: 24),

            prsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (prs) {
                if (prs.isEmpty) return const SizedBox.shrink();
                return ExercisePersonalRecordsSection(records: prs);
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildActionRow(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textMuted, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favState = ref.watch(favoritesProvider);
    final stapleState = ref.watch(staplesProvider);
    final queueState = ref.watch(exerciseQueueProvider);
    final avoidState = ref.watch(avoidedProvider);

    final name = exercise.name;
    final isFav = favState.isFavorite(name);
    final isStaple = stapleState.isStaple(name);
    final isQueued = queueState.isQueued(name);
    final isAvoided = avoidState.isAvoided(name);

    final red = isDark ? AppColors.error : AppColorsLight.error;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    Widget actionButton({
      required IconData icon,
      required IconData activeIcon,
      required String label,
      required bool active,
      required Color activeColor,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  color: active ? activeColor : textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? activeColor : textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          actionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: 'Favorite',
            active: isFav,
            activeColor: red,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoritesProvider.notifier).toggleFavorite(name, exerciseId: exercise.exerciseId);
            },
          ),
          actionButton(
            icon: Icons.push_pin_outlined,
            activeIcon: Icons.push_pin,
            label: 'Staple',
            active: isStaple,
            activeColor: cyan,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(staplesProvider.notifier).toggleStaple(
                name,
                libraryId: exercise.libraryId,
                muscleGroup: exercise.muscleGroup ?? exercise.primaryMuscle,
              );
            },
          ),
          actionButton(
            icon: Icons.queue_outlined,
            activeIcon: Icons.queue,
            label: 'Queue',
            active: isQueued,
            activeColor: orange,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(exerciseQueueProvider.notifier).toggleQueue(
                name,
                exerciseId: exercise.exerciseId,
                targetMuscleGroup: exercise.muscleGroup ?? exercise.primaryMuscle,
              );
            },
          ),
          actionButton(
            icon: Icons.block_outlined,
            activeIcon: Icons.block,
            label: 'Avoid',
            active: isAvoided,
            activeColor: textMuted,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(avoidedProvider.notifier).toggleAvoided(name, exerciseId: exercise.exerciseId);
            },
          ),
        ],
      ),
    );
  }


  Widget _buildCoachingCuesSection(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary, Color textMuted, Color accentColor) {
    final cues = <_CueItem>[];

    if (exercise.formCue != null && exercise.formCue!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.sports_gymnastics, label: 'Form', text: exercise.formCue!));
    }
    if (exercise.breathingCue != null && exercise.breathingCue!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.air, label: 'Breathing', text: exercise.breathingCue!));
    }
    if (exercise.setup != null && exercise.setup!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.tune, label: 'Setup', text: exercise.setup!));
    }
    if (exercise.tempo != null && exercise.tempo!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.speed, label: 'Tempo', text: exercise.tempo!));
    }

    if (cues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COACHING CUES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < cues.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(cues[i].icon, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cues[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cues[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < cues.length - 1)
                  Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildExerciseInfoSection(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary, Color textMuted, Color accentColor) {
    final items = <_CueItem>[];

    if (exercise.difficulty != null && exercise.difficulty!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.signal_cellular_alt, label: 'Difficulty', text: exercise.difficulty!));
    }

    // Secondary muscles
    final secondaryMuscles = exercise.secondaryMuscles;
    String? musclesText;
    if (secondaryMuscles is List && secondaryMuscles.isNotEmpty) {
      musclesText = secondaryMuscles.map((m) => m.toString()).join(', ');
    } else if (secondaryMuscles is String && secondaryMuscles.isNotEmpty) {
      musclesText = secondaryMuscles;
    }
    if (musclesText != null) {
      items.add(_CueItem(icon: Icons.accessibility_new, label: 'Secondary Muscles', text: musclesText));
    }

    if (exercise.substitution != null && exercise.substitution!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.swap_horiz, label: 'Alternative', text: exercise.substitution!));
    }
    if (exercise.notes != null && exercise.notes!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.sticky_note_2_outlined, label: 'Notes', text: exercise.notes!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXERCISE INFO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(items[i].icon, color: textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildTableRow({
    required String setLabel,
    required bool isWarmup,
    PreviousSetData? previousData,
    required bool hasPrevious,
    double? targetWeight,
    int? targetReps,
    int? targetRir,
    required bool isLast,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
  }) {
    final previousDisplay = _formatPreviousSet(previousData);

    // Format target display
    String targetDisplay = '-';
    if (targetWeight != null && targetReps != null) {
      targetDisplay = '${targetWeight.toInt()} × $targetReps';
    } else if (targetReps != null) {
      targetDisplay = '× $targetReps';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withValues(alpha: 0.2),
                ),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null,
      ),
      child: Row(
        children: [
          // Set badge
          SizedBox(
            width: 36,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isWarmup
                    ? textMuted.withValues(alpha: 0.15)
                    : textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  setLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isWarmup ? textMuted : textPrimary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Previous column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight x Reps
                Text(
                  previousDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: previousDisplay == '-' ? textMuted : textSecondary,
                    fontWeight: previousDisplay != '-' ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                // RIR pill (if available)
                if (previousData?.rir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(previousData!.rir!).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR ${previousData.rir}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(previousData.rir!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Target column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target weight x reps
                Text(
                  targetDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: targetDisplay == '-' ? textMuted : textPrimary,
                    fontWeight: targetDisplay != '-' ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // Target RIR pill
                if (targetRir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(targetRir).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR $targetRir',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(targetRir),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}
