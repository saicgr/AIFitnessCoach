import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Locked state widget shown when global leaderboard is not unlocked
class LeaderboardLockedState extends StatelessWidget {
  final Map<String, dynamic>? unlockStatus;
  final bool isDark;
  final VoidCallback onViewFriendsLeaderboard;

  const LeaderboardLockedState({
    super.key,
    required this.unlockStatus,
    required this.isDark,
    required this.onViewFriendsLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final workoutsCompleted = unlockStatus?['workouts_completed'] ?? 0;
    final workoutsNeeded = unlockStatus?['workouts_needed'] ?? 10;
    final progress = unlockStatus?['progress_percentage'] ?? 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: AppColors.orange,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Global Leaderboard Locked',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              unlockStatus?['unlock_message'] ?? 'Complete more workouts to unlock!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$workoutsCompleted / 10 workouts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Friends Leaderboard Button
            OutlinedButton.icon(
              onPressed: onViewFriendsLeaderboard,
              icon: const Icon(Icons.people),
              label: const Text('View Friends Leaderboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
