import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/personal_goals_service.dart';
import '../../../data/services/goal_social_service.dart';
import 'friend_avatars_row.dart';

/// A card displaying a personal weekly goal with progress
class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onTap;
  final VoidCallback? onRecordAttempt;
  final VoidCallback? onAddVolume;
  final List<FriendGoalProgress>? friends;
  final int friendsCount;
  final VoidCallback? onFriendsTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onRecordAttempt,
    this.onAddVolume,
    this.friends,
    this.friendsCount = 0,
    this.onFriendsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final exerciseName = goal['exercise_name'] ?? 'Exercise';
    final goalType = PersonalGoalType.fromString(goal['goal_type'] ?? 'single_max');
    final status = PersonalGoalStatus.fromString(goal['status'] ?? 'active');
    final targetValue = goal['target_value'] ?? 0;
    final currentValue = goal['current_value'] ?? 0;
    final personalBest = goal['personal_best'];
    final isPrBeaten = goal['is_pr_beaten'] ?? false;
    final progressPercentage = goal['progress_percentage'] ?? 0.0;
    final daysRemaining = goal['days_remaining'] ?? 0;

    final isActive = status == PersonalGoalStatus.active;
    final isCompleted = status == PersonalGoalStatus.completed;

    // Colors based on status
    Color statusColor;
    if (isCompleted) {
      statusColor = AppColors.success;
    } else if (isPrBeaten) {
      statusColor = AppColors.orange;
    } else {
      statusColor = AppColors.cyan;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrBeaten || isCompleted ? statusColor.withValues(alpha: 0.5) : cardBorder,
            width: isPrBeaten || isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Exercise icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getExerciseIcon(exerciseName),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goalType == PersonalGoalType.singleMax
                            ? 'Max Reps Challenge'
                            : 'Weekly Volume Goal',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isPrBeaten)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: AppColors.orange),
                        SizedBox(width: 4),
                        Text(
                          'NEW PR!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress section
            Row(
              children: [
                // Current value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalType == PersonalGoalType.singleMax ? 'Best Attempt' : 'Total',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$currentValue',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            TextSpan(
                              text: ' / $targetValue reps',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Personal best
                if (personalBest != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Personal Best',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$personalBest reps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progressPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 12),

            // Friends row (if any)
            if (friendsCount > 0) ...[
              FriendAvatarsRow(
                friends: friends ?? [],
                totalCount: friendsCount,
                onTap: onFriendsTap,
              ),
              const SizedBox(height: 12),
            ],

            // Footer row
            Row(
              children: [
                // Days remaining
                if (isActive) ...[
                  Icon(Icons.schedule, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    daysRemaining == 1
                        ? '1 day left'
                        : '$daysRemaining days left',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
                const Spacer(),
                // Action button
                if (isActive)
                  TextButton.icon(
                    onPressed: goalType == PersonalGoalType.singleMax
                        ? onRecordAttempt
                        : onAddVolume,
                    icon: Icon(
                      goalType == PersonalGoalType.singleMax
                          ? Icons.add_circle_outline
                          : Icons.fitness_center,
                      size: 18,
                    ),
                    label: Text(
                      goalType == PersonalGoalType.singleMax
                          ? 'Record Attempt'
                          : 'Add Reps',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('push') || name.contains('press') || name.contains('bench')) {
      return Icons.fitness_center;
    } else if (name.contains('squat') || name.contains('leg')) {
      return Icons.airline_seat_legroom_extra;
    } else if (name.contains('pull') || name.contains('row')) {
      return Icons.sports_gymnastics;
    } else if (name.contains('plank') || name.contains('core') || name.contains('ab')) {
      return Icons.accessibility_new;
    } else if (name.contains('run') || name.contains('cardio')) {
      return Icons.directions_run;
    } else {
      return Icons.sports_martial_arts;
    }
  }
}
