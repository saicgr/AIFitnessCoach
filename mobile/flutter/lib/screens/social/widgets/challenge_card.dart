import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Challenge Card - Displays a fitness challenge
class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final String challengeType;
  final double goalValue;
  final String? goalUnit;
  final double currentValue;
  final double progressPercentage;
  final int participantCount;
  final int daysRemaining;
  final bool isActive;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.goalValue,
    this.goalUnit,
    required this.currentValue,
    required this.progressPercentage,
    required this.participantCount,
    required this.daysRemaining,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.orange.withValues(alpha: 0.5)
                  : cardBorder.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange,
                            AppColors.pink,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getChallengeIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Progress (if active)
              if (isActive) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentValue / $goalValue ${goalUnit ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${progressPercentage.toInt()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.orange,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Divider
              Divider(
                height: 1,
                color: cardBorder.withValues(alpha: 0.3),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Participants
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount participating',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    // Days remaining
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$daysRemaining days left',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getChallengeIcon() {
    switch (challengeType) {
      case 'workout_count':
        return Icons.fitness_center_rounded;
      case 'workout_streak':
        return Icons.local_fire_department;
      case 'total_volume':
        return Icons.trending_up_rounded;
      case 'weight_loss':
        return Icons.monitor_weight_outlined;
      case 'step_count':
        return Icons.directions_walk_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
