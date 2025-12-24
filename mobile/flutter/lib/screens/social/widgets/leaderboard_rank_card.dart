import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/leaderboard_service.dart';

/// User's rank card - displayed at the top of leaderboard
class LeaderboardRankCard extends StatelessWidget {
  final Map<String, dynamic> userRank;
  final LeaderboardType selectedType;
  final bool isDark;

  const LeaderboardRankCard({
    super.key,
    required this.userRank,
    required this.selectedType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rank = userRank['rank'] as int;
    final totalUsers = userRank['total_users'] as int;
    final percentile = userRank['percentile'] as num;
    final userStats = userRank['user_stats'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.2),
            AppColors.cyan.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR RANK',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '#$rank',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'of $totalUsers',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Top ${percentile.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Stats Row
          if (userStats != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildUserStatsRow(context, userStats),
          ],
        ],
      ),
    );
  }

  Widget _buildUserStatsRow(BuildContext context, Map<String, dynamic> stats) {
    final List<Widget> statWidgets = [];

    if (selectedType == LeaderboardType.challengeMasters) {
      final wins = stats['first_wins'] ?? 0;
      final winRate = stats['win_rate'] ?? 0.0;
      statWidgets.addAll([
        _buildStatColumn(context, '🏆 Wins', '$wins'),
        _buildStatColumn(context, '📊 Win Rate', '${winRate.toStringAsFixed(1)}%'),
        _buildStatColumn(context, '💪 Completed', '${stats['total_completed'] ?? 0}'),
      ]);
    } else if (selectedType == LeaderboardType.volumeKings) {
      final volume = stats['total_volume_lbs'] ?? 0.0;
      statWidgets.addAll([
        _buildStatColumn(context, '🏋️ Total Volume', '${(volume / 1000).toStringAsFixed(1)}K lbs'),
        _buildStatColumn(context, '💪 Workouts', '${stats['total_workouts'] ?? 0}'),
        _buildStatColumn(context, '📊 Avg Volume', '${stats['avg_volume_per_workout']?.toStringAsFixed(0) ?? 0} lbs'),
      ]);
    } else if (selectedType == LeaderboardType.streaks) {
      statWidgets.addAll([
        _buildStatColumn(context, '🔥 Current', '${stats['current_streak'] ?? 0} days'),
        _buildStatColumn(context, '⭐ Best', '${stats['best_streak'] ?? 0} days'),
      ]);
    } else if (selectedType == LeaderboardType.weeklyChallenges) {
      final weeklyRate = stats['weekly_win_rate'] ?? 0.0;
      statWidgets.addAll([
        _buildStatColumn(context, '⚡ Wins', '${stats['weekly_wins'] ?? 0}'),
        _buildStatColumn(context, '💪 Completed', '${stats['weekly_completed'] ?? 0}'),
        _buildStatColumn(context, '📊 Win Rate', '${weeklyRate.toStringAsFixed(1)}%'),
      ]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: statWidgets,
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }
}
