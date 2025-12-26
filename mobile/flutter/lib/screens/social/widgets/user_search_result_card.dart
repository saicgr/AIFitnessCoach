import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// User Search Result Card - Displays a user in search results or suggestions
class UserSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onAction;
  final bool showSuggestionReason;

  const UserSearchResultCard({
    super.key,
    required this.user,
    required this.onAction,
    this.showSuggestionReason = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final name = user['name'] as String? ?? 'Unknown';
    final avatarUrl = user['avatar_url'] as String?;
    final bio = user['bio'] as String?;
    final totalWorkouts = user['total_workouts'] as int? ?? 0;
    final currentStreak = user['current_streak'] as int? ?? 0;
    final isFollowing = user['is_following'] as bool? ?? false;
    final isFollower = user['is_follower'] as bool? ?? false;
    final isFriend = user['is_friend'] as bool? ?? false;
    final hasPendingRequest = user['has_pending_request'] as bool? ?? false;
    final requiresApproval = user['requires_approval'] as bool? ?? false;
    final suggestionReason = user['suggestion_reason'] as String?;
    final mutualFriendsCount = user['mutual_friends_count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and badges
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFriend)
                      _buildBadge('FRIEND', AppColors.cyan),
                    if (isFollower && !isFriend)
                      _buildBadge('FOLLOWS YOU', AppColors.purple),
                    if (requiresApproval && !isFriend && !hasPendingRequest)
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Bio or stats
                if (bio != null && bio.isNotEmpty) ...[
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalWorkouts workouts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (currentStreak > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_fire_department,
                          size: 12,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak day streak',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Suggestion reason
                if (showSuggestionReason && suggestionReason != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        mutualFriendsCount > 0
                            ? Icons.people_outline_rounded
                            : Icons.star_outline_rounded,
                        size: 12,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestionReason,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action button
          _buildActionButton(
            isFollowing: isFollowing,
            isFriend: isFriend,
            hasPendingRequest: hasPendingRequest,
            requiresApproval: requiresApproval,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required bool isFollowing,
    required bool isFriend,
    required bool hasPendingRequest,
    required bool requiresApproval,
  }) {
    String label;
    IconData icon;
    Color color;
    bool isOutlined;

    if (isFriend) {
      label = 'Friends';
      icon = Icons.check_circle_rounded;
      color = AppColors.cyan;
      isOutlined = true;
    } else if (hasPendingRequest) {
      label = 'Requested';
      icon = Icons.schedule_rounded;
      color = AppColors.orange;
      isOutlined = true;
    } else if (isFollowing) {
      label = 'Following';
      icon = Icons.check_rounded;
      color = AppColors.textMuted;
      isOutlined = true;
    } else if (requiresApproval) {
      label = 'Request';
      icon = Icons.person_add_rounded;
      color = AppColors.cyan;
      isOutlined = false;
    } else {
      label = 'Follow';
      icon = Icons.person_add_rounded;
      color = AppColors.cyan;
      isOutlined = false;
    }

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isFriend ? null : onAction,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onAction,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
