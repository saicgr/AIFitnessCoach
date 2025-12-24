import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/senior/senior_card.dart';
import '../../../widgets/senior/senior_button.dart';

/// Senior Mode Social Screen - Simplified, easy-to-use social features
/// Focuses on family connections and encouragement over competition
class SeniorSocialScreen extends ConsumerStatefulWidget {
  const SeniorSocialScreen({super.key});

  @override
  ConsumerState<SeniorSocialScreen> createState() => _SeniorSocialScreenState();
}

class _SeniorSocialScreenState extends ConsumerState<SeniorSocialScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: Load social summary from API
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: backgroundColor,
              floating: true,
              title: const Text(
                'Friends & Family',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encouragement Summary
                    _buildEncouragementSummary(context, isDark),

                    const SizedBox(height: 24),

                    // Recent Activities Section
                    _buildSectionHeader(context, 'Recent Activity'),
                    const SizedBox(height: 16),
                    _buildRecentActivities(context, isDark),

                    const SizedBox(height: 32),

                    // Your Challenges Section
                    _buildSectionHeader(context, 'Your Challenges'),
                    const SizedBox(height: 16),
                    _buildYourChallenges(context, isDark),

                    const SizedBox(height: 32),

                    // Family Members Section
                    _buildSectionHeader(context, 'Family'),
                    const SizedBox(height: 16),
                    _buildFamilyMembers(context, isDark),

                    // Bottom spacing for floating nav bar
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEncouragementSummary(BuildContext context, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return SeniorCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.3),
                    AppColors.purple.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 40,
                color: AppColors.pink,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '15 Cheers Received',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your friends are proud of you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, bool isDark) {
    // TODO: Replace with actual data
    final hasActivities = false;

    if (!hasActivities) {
      return _buildEmptyCard(
        context,
        isDark,
        icon: Icons.people_outline_rounded,
        message: 'No recent activity from friends.\nAdd family members to see their workouts!',
      );
    }

    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildActivityCard(
            context,
            isDark,
            userName: 'John',
            activityText: 'completed Morning Walk',
            timestamp: '2 hours ago',
            hasCheered: index == 0,
          ),
        );
      }),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    bool isDark, {
    required String userName,
    required String activityText,
    required String timestamp,
    required bool hasCheered,
  }) {
    return SeniorCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User and activity
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activityText,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timestamp
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 16),

            // Cheer button
            SeniorButton(
              onPressed: () => _handleCheer(),
              icon: hasCheered ? Icons.favorite : Icons.favorite_border,
              label: hasCheered ? 'Cheered!' : 'Send Cheer',
              variant: hasCheered ? 'secondary' : 'primary',
              color: AppColors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourChallenges(BuildContext context, bool isDark) {
    // TODO: Replace with actual data
    final hasChallenges = false;

    if (!hasChallenges) {
      return _buildEmptyCard(
        context,
        isDark,
        icon: Icons.emoji_events_outlined,
        message: 'You are not in any challenges yet.\nChallenges help you stay motivated!',
      );
    }

    return Column(
      children: [
        _buildChallengeCard(
          context,
          isDark,
          title: 'Walk Every Day',
          progress: '15 out of 30 days',
          progressPercentage: 0.5,
          daysLeft: 15,
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String progress,
    required double progressPercentage,
    required int daysLeft,
  }) {
    return SeniorCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.pink],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 16),

            // Days remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$daysLeft days remaining',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembers(BuildContext context, bool isDark) {
    // TODO: Replace with actual data
    final hasFamily = false;

    if (!hasFamily) {
      return _buildEmptyCard(
        context,
        isDark,
        icon: Icons.family_restroom_rounded,
        message: 'No family members added yet.\nInvite family to share your fitness journey!',
        actionLabel: 'Invite Family',
        onAction: () => _handleInviteFamily(),
      );
    }

    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFamilyCard(
            context,
            isDark,
            name: index == 0 ? 'Sarah' : 'Mike',
            workoutStreak: index == 0 ? 12 : 7,
          ),
        );
      }),
    );
  }

  Widget _buildFamilyCard(
    BuildContext context,
    bool isDark, {
    required String name,
    required int workoutStreak,
  }) {
    return SeniorCard(
      onTap: () => _handleFamilyProfile(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.purple.withValues(alpha: 0.2),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$workoutStreak day streak',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SeniorCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              icon,
              size: 60,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SeniorButton(
                onPressed: onAction,
                label: actionLabel,
                icon: Icons.person_add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCheer() {
    HapticFeedback.mediumImpact();
    // TODO: Send cheer reaction to API
  }

  void _handleInviteFamily() {
    HapticFeedback.lightImpact();
    // TODO: Show invite family dialog
  }

  void _handleFamilyProfile() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to family member profile
  }
}
