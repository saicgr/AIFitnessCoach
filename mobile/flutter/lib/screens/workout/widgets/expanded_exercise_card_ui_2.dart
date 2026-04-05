part of 'expanded_exercise_card.dart';

/// UI builder methods extracted from _ExpandedExerciseCardState
extension _ExpandedExerciseCardStateUI2 on _ExpandedExerciseCardState {

  Widget _buildAlternatingHandsChip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = isDark ? 0.1 : 0.15;
    final displayColor = isDark ? AppColors.orange : _darkenColor(AppColors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? null : Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_alt, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            'Alternating Hands',
            style: TextStyle(
              fontSize: 11,
              color: displayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  /// Build preference indicator chips (Staple, Favorite, Queued)
  List<Widget> _buildPreferenceChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exerciseName = widget.exercise.name;
    final chips = <Widget>[];

    final isStaple = ref.watch(staplesProvider).isStaple(exerciseName);
    final isFavorite = ref.watch(favoritesProvider).isFavorite(exerciseName);
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(exerciseName);

    if (isStaple) {
      final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.purple.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: purple.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin, size: 12, color: purple),
            const SizedBox(width: 4),
            Text('Staple', style: TextStyle(fontSize: 11, color: purple, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    if (isFavorite) {
      final red = isDark ? AppColors.error : _darkenColor(AppColors.error);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: red.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 12, color: red),
            const SizedBox(width: 4),
            Text('Favorite', style: TextStyle(fontSize: 11, color: red, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    if (isQueued) {
      final cyan = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: cyan.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_check, size: 12, color: cyan),
            const SizedBox(width: 4),
            Text('Queued', style: TextStyle(fontSize: 11, color: cyan, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    return chips;
  }


  Widget _buildBreathingStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildSetRow({
    required String setLabel,
    required bool isWarmup,
    String setType = 'working',
    double? weightKg,
    int? targetReps,
    int? targetRir,
    required bool useKg,
    required Color cardBorder,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
    required Color accentColor,
  }) {
    final setColor = _getSetTypeColor(setType, accentColor);

    // Convert weight to user's preferred unit (matching active workout screen)
    // All weights are stored in kg internally
    double? displayWeight;
    if (weightKg != null && weightKg > 0) {
      displayWeight = useKg ? weightKg : weightKg * 2.20462;
    }

    // Build target display string: weight unit × reps (matching active workout screen)
    // Include unit label so user knows if weight is in kg or lbs
    final unit = useKg ? 'kg' : 'lbs';
    String targetDisplay = '—';
    if (displayWeight != null && displayWeight > 0 && targetReps != null && targetReps > 0) {
      // Check if this is a failure/amrap set
      if (setType.toLowerCase() == 'failure' || setType.toLowerCase() == 'amrap') {
        targetDisplay = '${displayWeight.toStringAsFixed(0)} $unit × AMRAP';
      } else {
        targetDisplay = '${displayWeight.toStringAsFixed(0)} $unit × $targetReps';
      }
    } else if (targetReps != null && targetReps > 0) {
      // Bodyweight exercise - just show reps (no weight/unit needed)
      if (setType.toLowerCase() == 'failure' || setType.toLowerCase() == 'amrap') {
        targetDisplay = 'AMRAP';
      } else {
        targetDisplay = '$targetReps reps';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cardBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top so text baselines match
        children: [
          // SET column - Set number with type color badge
          // Add top padding to align badge center with text baseline
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 50,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: setColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    setLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: setColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LAST column - previous session data (shows "—" for preview)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                height: 34, // Match SET badge height (32) + top padding (2)
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // TARGET column - AI recommended weight × reps with RIR badge
          Expanded(
            flex: 3,
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    targetDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: targetDisplay != '—' ? accentColor : textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // RIR pill (matching active workout screen)
                  if (targetRir != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: WorkoutDesign.getRirColor(targetRir),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          WorkoutDesign.getRirLabel(targetRir),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: WorkoutDesign.getRirTextColor(targetRir),
                          ),
                        ),
                      ),
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
