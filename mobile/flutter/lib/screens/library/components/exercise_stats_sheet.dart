import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../widgets/stat_badge.dart';

/// Bottom sheet showing detailed exercise statistics
class ExerciseStatsSheet extends StatelessWidget {
  final String exerciseName;
  final ExerciseHistoryItem item;

  const ExerciseStatsSheet({
    super.key,
    required this.exerciseName,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.surface : AppColorsLight.surface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final error = isDark ? AppColors.error : AppColorsLight.error;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark
                        ? null
                        : Border.all(color: AppColorsLight.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              title: 'Total Sets',
                              value: '${item.totalSets}',
                              icon: Icons.fitness_center,
                              color: cyan,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              title: 'Max Weight',
                              value: item.maxWeight != null
                                  ? '${item.maxWeight!.toStringAsFixed(1)} kg'
                                  : '-',
                              icon: Icons.monitor_weight_outlined,
                              color: cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              title: 'Est. 1RM',
                              value: item.estimated1rm != null
                                  ? '${item.estimated1rm!.toStringAsFixed(1)} kg'
                                  : '-',
                              icon: Icons.emoji_events_outlined,
                              color: success,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              title: 'Max Reps',
                              value:
                                  item.maxReps != null ? '${item.maxReps}' : '-',
                              icon: Icons.repeat,
                              color: cyan,
                            ),
                          ),
                        ],
                      ),
                      if (item.avgRpe != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                title: 'Avg RPE',
                                value: item.avgRpe!.toStringAsFixed(1),
                                icon: Icons.speed,
                                color: cyan,
                              ),
                            ),
                            Expanded(
                              child: StatTile(
                                title: 'Volume',
                                value: item.totalVolume != null
                                    ? '${(item.totalVolume! / 1000).toStringAsFixed(1)}k kg'
                                    : '-',
                                icon: Icons.bar_chart,
                                color: cyan,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Progression info
                if (item.progression != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.progression!.isIncreasing
                          ? success.withOpacity(0.1)
                          : item.progression!.isDecreasing
                              ? error.withOpacity(0.1)
                              : elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.progression!.isIncreasing
                            ? success.withOpacity(0.3)
                            : item.progression!.isDecreasing
                                ? error.withOpacity(0.3)
                                : elevated,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.progression!.isIncreasing
                              ? Icons.trending_up
                              : item.progression!.isDecreasing
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          color: item.progression!.isIncreasing
                              ? success
                              : item.progression!.isDecreasing
                                  ? error
                                  : cyan,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progression',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                item.progression!.message,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
