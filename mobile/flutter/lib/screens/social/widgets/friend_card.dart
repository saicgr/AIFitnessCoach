import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Friend Card - Displays a user profile card
class FriendCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? bio;
  final int currentStreak;
  final int totalWorkouts;
  final int totalAchievements;
  final bool isFriend;
  final bool isFollowing;
  final bool isSupportUser; // Support users cannot be unfriended
  final VoidCallback onTap;
  final VoidCallback onFollow;

  const FriendCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.bio,
    required this.currentStreak,
    required this.totalWorkouts,
    required this.totalAchievements,
    required this.isFriend,
    required this.isFollowing,
    this.isSupportUser = false,
    required this.onTap,
    required this.onFollow,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 24,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isFriend)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'FRIEND',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cyan,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (bio != null && bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            bio!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.local_fire_department,
                      label: '$currentStreak day streak',
                      color: AppColors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.fitness_center_rounded,
                      label: '$totalWorkouts workouts',
                      color: AppColors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.emoji_events_rounded,
                      label: '$totalAchievements badges',
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Follow button (hidden for support users who cannot be unfriended)
              if (isSupportUser)
                // Support user badge - cannot be unfriended
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FitWiz Support',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onFollow,
                    icon: Icon(
                      isFollowing ? Icons.person_remove : Icons.person_add,
                      size: 18,
                    ),
                    label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowing ? AppColors.textMuted : AppColors.cyan,
                      side: BorderSide(
                        color: isFollowing
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : AppColors.cyan.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
