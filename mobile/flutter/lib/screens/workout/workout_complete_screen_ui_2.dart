part of 'workout_complete_screen.dart';

/// UI builder methods extracted from _WorkoutCompleteScreenState
extension _WorkoutCompleteScreenStateUI2 on _WorkoutCompleteScreenState {

  Widget _buildExerciseComparisonRow(
    ExerciseComparisonInfo exComp,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Determine status icon and color
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (exComp.status) {
      case 'improved':
        statusIcon = Icons.trending_up;
        statusColor = AppColors.success;
        statusText = exComp.formattedPercentDiff;
        break;
      case 'declined':
        statusIcon = Icons.trending_down;
        statusColor = AppColors.error;
        statusText = exComp.formattedPercentDiff;
        break;
      case 'maintained':
        statusIcon = Icons.remove;
        statusColor = AppColors.cyan;
        statusText = 'Same';
        break;
      default: // first_time
        statusIcon = Icons.fiber_new;
        statusColor = AppColors.purple;
        statusText = 'New';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 14, color: statusColor),
          ),
          const SizedBox(width: 12),

          // Exercise name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exComp.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (exComp.hasPrevious) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.currentMaxWeightKg != null
                        ? '${exComp.currentMaxWeightKg!.toStringAsFixed(1)} kg x ${exComp.currentReps} reps'
                        : '${exComp.currentSets} sets, ${exComp.currentReps} reps',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Difference display
          if (exComp.hasPrevious)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (exComp.weightDiffKg != null && exComp.weightDiffKg != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.formattedWeightDiff,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                ],
                if (exComp.timeDiffSeconds != null && exComp.timeDiffSeconds != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.formattedTimeDiff,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildWorkoutTotalComparison(
    WorkoutComparisonInfo workoutComp,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL WORKOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Volume comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Volume',
                  current: '${workoutComp.currentTotalVolumeKg.toStringAsFixed(0)} kg',
                  diff: workoutComp.formattedVolumeDiff,
                  diffPercent: workoutComp.volumeDiffPercent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Duration comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Duration',
                  current: _formatDuration(workoutComp.currentDurationSeconds ~/ 60),
                  diff: workoutComp.formattedDurationDiff,
                  diffPercent: workoutComp.durationDiffPercent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Reps comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Total Reps',
                  current: '${workoutComp.currentTotalReps}',
                  diff: workoutComp.previousTotalReps != null
                      ? '${workoutComp.currentTotalReps - workoutComp.previousTotalReps! >= 0 ? '+' : ''}${workoutComp.currentTotalReps - workoutComp.previousTotalReps!}'
                      : null,
                  diffPercent: null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildComparisonStat({
    required String label,
    required String current,
    String? diff,
    double? diffPercent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color? diffColor;
    if (diffPercent != null) {
      if (diffPercent > 1) {
        diffColor = AppColors.success;
      } else if (diffPercent < -1) {
        diffColor = AppColors.error;
      } else {
        diffColor = AppColors.cyan;
      }
    } else if (diff != null && diff.isNotEmpty) {
      if (diff.startsWith('+')) {
        diffColor = AppColors.success;
      } else if (diff.startsWith('-')) {
        diffColor = AppColors.error;
      } else {
        diffColor = AppColors.cyan;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          current,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        if (diff != null && diff.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            diff,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: diffColor,
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildSimpleProgressChart(List<Map<String, dynamic>> history, double maxWeight) {
    final sortedHistory = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    return Builder(
      builder: (context) {
        final isDarkChart = Theme.of(context).brightness == Brightness.dark;
        final textMutedChart = isDarkChart ? AppColors.textMuted : AppColorsLight.textMuted;

        if (sortedHistory.isEmpty) {
          return Center(child: Text('No data', style: TextStyle(color: textMutedChart)));
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: sortedHistory.take(7).map((item) {
            final weight = (item['weight_kg'] ?? 0.0).toDouble();
            final heightPercent = maxWeight > 0 ? (weight / maxWeight) : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${weight.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 9, color: textMutedChart),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (60 * heightPercent).toDouble(),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

}
