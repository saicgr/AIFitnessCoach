import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Activity Card - Displays a single activity feed item
class ActivityCard extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String activityType;
  final Map<String, dynamic> activityData;
  final DateTime timestamp;
  final int reactionCount;
  final int commentCount;
  final bool hasUserReacted;
  final VoidCallback onReact;
  final VoidCallback onComment;

  const ActivityCard({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.activityType,
    required this.activityData,
    required this.timestamp,
    required this.reactionCount,
    required this.commentCount,
    required this.hasUserReacted,
    required this.onReact,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (User info + timestamp)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                  backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                  child: userAvatar == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () {
                    // TODO: Show options menu
                  },
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Activity content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActivityContent(context),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            color: cardBorder.withValues(alpha: 0.3),
          ),

          // Actions (Reactions & Comments)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // React button
                Expanded(
                  child: InkWell(
                    onTap: onReact,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasUserReacted ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: hasUserReacted ? AppColors.pink : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reactionCount > 0 ? '$reactionCount' : 'Cheer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: hasUserReacted ? AppColors.pink : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: cardBorder.withValues(alpha: 0.3),
                ),

                // Comment button
                Expanded(
                  child: InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            commentCount > 0 ? '$commentCount' : 'Comment',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContent(BuildContext context) {
    switch (activityType) {
      case 'workout_completed':
        return _buildWorkoutContent(context);
      case 'achievement_earned':
        return _buildAchievementContent(context);
      case 'personal_record':
        return _buildPRContent(context);
      case 'weight_milestone':
        return _buildWeightMilestoneContent(context);
      case 'streak_milestone':
        return _buildStreakContent(context);
      default:
        return _buildGenericContent(context);
    }
  }

  Widget _buildWorkoutContent(BuildContext context) {
    final workoutName = activityData['workout_name'] ?? 'a workout';
    final duration = activityData['duration_minutes'] ?? 0;
    final exercises = activityData['exercises_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'completed '),
              TextSpan(
                text: workoutName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _buildStat(Icons.timer_outlined, '$duration min'),
            _buildStat(Icons.fitness_center_outlined, '$exercises exercises'),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementContent(BuildContext context) {
    final achievementName = activityData['achievement_name'] ?? 'an achievement';
    final achievementIcon = activityData['achievement_icon'] ?? '🏆';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.3),
                AppColors.pink.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              achievementIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'earned an achievement',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                achievementName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPRContent(BuildContext context) {
    final exercise = activityData['exercise_name'] ?? 'an exercise';
    final value = activityData['record_value'] ?? 0;
    final unit = activityData['record_unit'] ?? '';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          const TextSpan(text: 'set a new PR in '),
          TextSpan(
            text: exercise,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ': '),
          TextSpan(
            text: '$value $unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightMilestoneContent(BuildContext context) {
    final weightChange = activityData['weight_change'] ?? 0;
    final direction = weightChange < 0 ? 'lost' : 'gained';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: '$direction '),
          TextSpan(
            text: '${weightChange.abs()} lbs',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakContent(BuildContext context) {
    final days = activityData['streak_days'] ?? 0;

    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          color: AppColors.orange,
          size: 24,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'reached a '),
              TextSpan(
                text: '$days-day streak',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              const TextSpan(text: '!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericContent(BuildContext context) {
    return const Text('was active');
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
