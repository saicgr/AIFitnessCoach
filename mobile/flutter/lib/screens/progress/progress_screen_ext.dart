part of 'progress_screen.dart';

/// Methods extracted from _ProgressScreenState
extension __ProgressScreenStateExt on _ProgressScreenState {

  void _showMuscleDetail(String muscleGroup) {
    final colorScheme = Theme.of(context).colorScheme;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _formatMuscleGroupName(muscleGroup),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final scoresState = ref.watch(scoresProvider);
                      final muscleData =
                          scoresState.strengthScores?.muscleScores[muscleGroup];

                      if (muscleData == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No data for this muscle group yet',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete workouts targeting this muscle\nto see your strength progress.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Color(muscleData.levelColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(muscleData.levelColor)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(muscleData.levelColor),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${muscleData.strengthScore}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        muscleData.levelDisplayName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(muscleData.levelColor),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: muscleData.progressToNextLevel,
                                          backgroundColor: colorScheme.outline
                                              .withOpacity(0.2),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(muscleData.levelColor),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Progress to next level',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Training status badge
                          Builder(builder: (context) {
                            final readiness = scoresState.todayReadiness ??
                                scoresState.overview?.todayReadiness;
                            final status = determineMuscleStatus(
                              muscleData: muscleData,
                              readiness: readiness,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: status.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: status.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(status.icon,
                                      size: 18, color: status.color),
                                  const SizedBox(width: 8),
                                  Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: status.color,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${muscleData.weeklySets} sets/wk',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),

                          // Stats
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Best Exercise',
                            muscleData.bestExerciseName ?? 'N/A',
                            Icons.star,
                          ),
                          if (muscleData.bestEstimated1rmKg != null)
                            _buildDetailRow(
                              'Estimated 1RM',
                              '${muscleData.bestEstimated1rmKg!.toStringAsFixed(1)} kg',
                              Icons.fitness_center,
                            ),
                          if (muscleData.bodyweightRatio != null)
                            _buildDetailRow(
                              'Bodyweight Ratio',
                              '${muscleData.bodyweightRatio!.toStringAsFixed(2)}x',
                              Icons.monitor_weight,
                            ),
                          _buildDetailRow(
                            'Weekly Sets',
                            '${muscleData.weeklySets}',
                            Icons.repeat,
                          ),
                          _buildDetailRow(
                            'Weekly Volume',
                            '${muscleData.weeklyVolumeKg.toStringAsFixed(0)} kg',
                            Icons.trending_up,
                          ),
                          _buildDetailRow(
                            'Trend',
                            muscleData.trend[0].toUpperCase() +
                                muscleData.trend.substring(1),
                            _getTrendIcon(muscleData.trendDirection),
                            valueColor:
                                _getTrendColor(muscleData.trendDirection),
                          ),
                        ],
                      );
                    },
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
