import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/leaderboard_service.dart';

/// Individual leaderboard entry card
class LeaderboardEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final LeaderboardType selectedType;
  final LeaderboardService leaderboardService;
  final bool isDark;
  final VoidCallback onChallengeTap;

  const LeaderboardEntryCard({
    super.key,
    required this.entry,
    required this.selectedType,
    required this.leaderboardService,
    required this.isDark,
    required this.onChallengeTap,
  });

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int;
    final userName = entry['user_name'] as String? ?? 'User';
    final avatarUrl = entry['avatar_url'] as String?;
    final countryCode = entry['country_code'] as String?;
    final isFriend = entry['is_friend'] as bool? ?? false;
    final isCurrentUser = entry['is_current_user'] as bool? ?? false;

    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final highlightColor = isCurrentUser
        ? AppColors.cyan.withValues(alpha: 0.1)
        : (isFriend ? AppColors.green.withValues(alpha: 0.05) : cardColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlightColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank/Medal
          SizedBox(
            width: 50,
            child: Text(
              rank <= 3 ? leaderboardService.getMedalEmoji(rank) : '#$rank',
              style: TextStyle(
                fontSize: rank <= 3 ? 28 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person) : null,
          ),

          const SizedBox(width: 12),

          // Name and Country
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (countryCode != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        leaderboardService.getCountryFlag(countryCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    if (isFriend && !isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '✓ Friend',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _buildStatsRow(context),
              ],
            ),
          ),

          // Challenge Button
          if (!isCurrentUser)
            IconButton(
              onPressed: onChallengeTap,
              icon: Icon(
                isFriend ? Icons.emoji_events : Icons.flash_on,
                color: isFriend ? AppColors.orange : AppColors.cyan,
              ),
              tooltip: isFriend ? 'Challenge Friend' : 'Beat Their Best',
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final List<Widget> stats = [];

    // Challenge Masters stats
    if (selectedType == LeaderboardType.challengeMasters) {
      final wins = entry['first_wins'] ?? 0;
      final winRate = entry['win_rate'] ?? 0.0;
      stats.addAll([
        _buildStatItem('🏆', '$wins wins'),
        _buildStatItem('📊', '${winRate.toStringAsFixed(1)}%'),
      ]);
    }
    // Volume Kings stats
    else if (selectedType == LeaderboardType.volumeKings) {
      final volume = entry['total_volume_lbs'] ?? 0.0;
      final workouts = entry['total_workouts'] ?? 0;
      stats.addAll([
        _buildStatItem('🏋️', '${(volume / 1000).toStringAsFixed(1)}K lbs'),
        _buildStatItem('💪', '$workouts workouts'),
      ]);
    }
    // Streaks stats
    else if (selectedType == LeaderboardType.streaks) {
      final currentStreak = entry['current_streak'] ?? 0;
      final bestStreak = entry['best_streak'] ?? 0;
      stats.addAll([
        _buildStatItem('🔥', '$currentStreak days'),
        _buildStatItem('⭐', 'Best: $bestStreak'),
      ]);
    }
    // Weekly stats
    else if (selectedType == LeaderboardType.weeklyChallenges) {
      final weeklyWins = entry['weekly_wins'] ?? 0;
      final weeklyRate = entry['weekly_win_rate'] ?? 0.0;
      stats.addAll([
        _buildStatItem('⚡', '$weeklyWins wins'),
        _buildStatItem('📊', '${weeklyRate.toStringAsFixed(1)}%'),
      ]);
    }

    return Row(
      children: stats.expand((w) => [w, const SizedBox(width: 12)]).take(stats.length * 2 - 1).toList(),
    );
  }

  Widget _buildStatItem(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
