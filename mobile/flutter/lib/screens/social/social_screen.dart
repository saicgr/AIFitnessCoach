import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Social screen placeholder - Coming Soon
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.pureBlack,
              floating: true,
              title: Text(
                'Social',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              centerTitle: false,
            ),

            // Coming Soon Content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.purple.withValues(alpha: 0.2),
                            AppColors.cyan.withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        size: 60,
                        color: AppColors.cyan,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Social Features',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // Coming Soon Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Connect with friends, share your workouts,\nand compete in challenges together!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                    ),

                    const SizedBox(height: 40),

                    // Feature List
                    _buildFeatureItem(
                      icon: Icons.group_add_outlined,
                      title: 'Add Friends',
                      description: 'Find and connect with workout buddies',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Challenges',
                      description: 'Compete in weekly fitness challenges',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.leaderboard_outlined,
                      title: 'Leaderboards',
                      description: 'See how you rank among friends',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.share_outlined,
                      title: 'Share Workouts',
                      description: 'Share your achievements with the community',
                    ),

                    // Extra space for floating nav bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.cyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
