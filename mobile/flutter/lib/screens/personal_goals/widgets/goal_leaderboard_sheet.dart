import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/services/goal_social_service.dart';
import '../../../data/services/personal_goals_service.dart';
import '../../../data/providers/goal_suggestions_provider.dart';

/// Mini-leaderboard modal showing friends' progress on a goal
class GoalLeaderboardSheet extends ConsumerWidget {
  final String userId;
  final String goalId;
  final String exerciseName;
  final PersonalGoalType goalType;

  const GoalLeaderboardSheet({
    super.key,
    required this.userId,
    required this.goalId,
    required this.exerciseName,
    required this.goalType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final friendsAsync = ref.watch(
      goalFriendsProvider(GoalFriendsParams(userId: userId, goalId: goalId)),
    );

    return GlassSheet(
      maxHeightFraction: 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.leaderboard,
                    color: AppColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Friends Leaderboard',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textSecondary),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: friendsAsync.when(
              data: (response) => _buildLeaderboard(context, response),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorState(context, textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, GoalFriendsResponse response) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (!response.hasFriends) {
      return _buildEmptyState(context, textSecondary);
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: response.friendEntries.length + 1, // +1 for user's position
      itemBuilder: (context, index) {
        // Show user's position at the end
        if (index == response.friendEntries.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: _buildUserPosition(context, response),
          );
        }

        final friend = response.friendEntries[index];
        return _buildLeaderboardEntry(context, friend, index + 1);
      },
    );
  }

  Widget _buildLeaderboardEntry(BuildContext context, FriendGoalProgress friend, int rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Rank colors
    Color rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: rankColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 20)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          _buildAvatar(friend, 40),
          const SizedBox(width: 12),
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      friend.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (friend.isPrBeaten) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, size: 10, color: AppColors.orange),
                            SizedBox(width: 2),
                            Text(
                              'PR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: friend.progressPercentage / 100,
                    backgroundColor: textSecondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      friend.progressPercentage >= 100 ? AppColors.green : AppColors.purple,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${friend.currentValue}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: friend.progressPercentage >= 100 ? AppColors.green : textPrimary,
                ),
              ),
              Text(
                '/ ${friend.targetValue}',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserPosition(BuildContext context, GoalFriendsResponse response) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${response.userRank}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppColors.cyan, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: response.userProgressPercentage / 100,
                    backgroundColor: textSecondary.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${response.userProgressPercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends on this goal yet',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite friends to compete!',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load leaderboard',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
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

/// Show the leaderboard as a modal bottom sheet
void showGoalLeaderboardSheet(
  BuildContext context, {
  required String userId,
  required String goalId,
  required String exerciseName,
  required PersonalGoalType goalType,
}) {
  showGlassSheet(
    context: context,
    builder: (context) => GoalLeaderboardSheet(
      userId: userId,
      goalId: goalId,
      exerciseName: exerciseName,
      goalType: goalType,
    ),
  );
}
