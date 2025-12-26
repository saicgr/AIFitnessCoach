import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/goal_social_service.dart';

/// Row of overlapping friend avatars with count badge
/// Shows up to 3 avatars + remaining count
class FriendAvatarsRow extends StatelessWidget {
  final List<FriendGoalProgress> friends;
  final int totalCount;
  final double avatarSize;
  final VoidCallback? onTap;

  const FriendAvatarsRow({
    super.key,
    required this.friends,
    required this.totalCount,
    this.avatarSize = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final displayFriends = friends.take(3).toList();
    final remaining = totalCount - displayFriends.length;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked avatars
          SizedBox(
            width: avatarSize + (displayFriends.length - 1) * (avatarSize * 0.6),
            height: avatarSize,
            child: Stack(
              children: List.generate(displayFriends.length, (index) {
                final friend = displayFriends[index];
                return Positioned(
                  left: index * (avatarSize * 0.6),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: elevated,
                        width: 2,
                      ),
                    ),
                    child: _buildAvatar(friend, avatarSize - 4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          // Friends label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining > 0
                    ? '+$remaining more'
                    : '$totalCount friend${totalCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'on this goal',
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(FriendGoalProgress friend, double size) {
    if (friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(friend.avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: friend.avatarUrl == null
            ? Text(
                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: size * 0.4),
              )
            : null,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.purple.withValues(alpha: 0.2),
      child: Text(
        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.4,
          color: AppColors.purple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Compact friend count badge
class FriendCountBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const FriendCountBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people,
              size: 14,
              color: AppColors.purple,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
