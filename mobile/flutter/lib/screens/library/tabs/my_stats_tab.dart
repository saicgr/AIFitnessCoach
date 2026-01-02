import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../providers/library_providers.dart';
import '../widgets/stat_badge.dart';
import '../components/exercise_stats_sheet.dart';

/// My Stats tab showing exercise history and performance
class MyStatsTab extends ConsumerWidget {
  const MyStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'Failed to load stats',
              style: TextStyle(color: textMuted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(exerciseHistoryProvider),
              child: Text('Retry', style: TextStyle(color: cyan)),
            ),
          ],
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_outlined,
                    size: 64, color: textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No exercise history yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete workouts to see your stats',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textMuted.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exerciseHistoryProvider);
          },
          color: cyan,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Summary header
                final totalSets =
                    history.fold<int>(0, (sum, item) => sum + item.totalSets);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${history.length} exercises tracked  •  $totalSets total sets',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textMuted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: elevated),
                    const SizedBox(height: 8),
                  ],
                );
              }

              final item = history[index - 1];
              return _ExerciseHistoryCard(item: item)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: (index - 1) * 30));
            },
          ),
        );
      },
    );
  }
}

/// Card showing exercise history item with stats
class _ExerciseHistoryCard extends StatelessWidget {
  final ExerciseHistoryItem item;

  const _ExerciseHistoryCard({required this.item});

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final error = isDark ? AppColors.error : AppColorsLight.error;

    // Get progression icon and color
    IconData progressIcon = Icons.remove;
    Color progressColor = textMuted;
    String progressText = 'No trend data';

    if (item.progression != null) {
      if (item.progression!.isIncreasing) {
        progressIcon = Icons.trending_up;
        progressColor = success;
        progressText =
            '+${item.progression!.changePercent?.toStringAsFixed(1) ?? ''}%';
      } else if (item.progression!.isDecreasing) {
        progressIcon = Icons.trending_down;
        progressColor = error;
        progressText =
            '${item.progression!.changePercent?.toStringAsFixed(1) ?? ''}%';
      } else if (item.progression!.isStable) {
        progressIcon = Icons.trending_flat;
        progressColor = cyan;
        progressText = 'Stable';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide.none
            : BorderSide(color: AppColorsLight.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show detailed stats sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ExerciseStatsSheet(
                exerciseName: item.exerciseName, item: item),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name and progress indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.exerciseName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(progressIcon, size: 16, color: progressColor),
                        const SizedBox(width: 4),
                        Text(
                          progressText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  StatBadge(
                    icon: Icons.fitness_center,
                    value: '${item.totalSets}',
                    label: 'sets',
                    color: cyan,
                  ),
                  const SizedBox(width: 16),
                  if (item.maxWeight != null && item.maxWeight! > 0)
                    StatBadge(
                      icon: Icons.monitor_weight_outlined,
                      value: item.maxWeight!.toStringAsFixed(1),
                      label: 'kg max',
                      color: cyan,
                    ),
                  if (item.maxWeight != null && item.maxWeight! > 0)
                    const SizedBox(width: 16),
                  if (item.estimated1rm != null && item.estimated1rm! > 0)
                    StatBadge(
                      icon: Icons.emoji_events_outlined,
                      value: item.estimated1rm!.toStringAsFixed(1),
                      label: '1RM',
                      color: success,
                    ),
                ],
              ),

              if (item.lastWorkoutDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last performed: ${_formatDate(item.lastWorkoutDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
