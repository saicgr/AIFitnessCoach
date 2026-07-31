import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/accent_color_provider.dart';
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
                color: context.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: context.accentColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              AppLocalizations.of(context).leaderboardLockedStateGlobalLeaderboardLocked,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              unlockStatus?['unlock_message'] ?? AppLocalizations.of(context).leaderboardLockedStateCompleteMoreWorkoutsTo,
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
                      AppLocalizations.of(context).navProgress,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      AppLocalizations.of(context)!.leaderboardLockedStateWorkouts(workoutsCompleted),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.accentColor,
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
                    valueColor: AlwaysStoppedAnimation<Color>(context.accentColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Friends Leaderboard Button
            OutlinedButton.icon(
              onPressed: onViewFriendsLeaderboard,
              icon: const Icon(Icons.people),
              label: Text(AppLocalizations.of(context).leaderboardLockedStateViewFriendsLeaderboard),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accentColor,
                side: BorderSide(color: context.accentColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
