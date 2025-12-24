import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/challenge_card.dart';
import '../widgets/empty_state.dart';

/// Challenges Tab - Shows active and available fitness challenges
class ChallengesTab extends ConsumerStatefulWidget {
  const ChallengesTab({super.key});

  @override
  ConsumerState<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<ChallengesTab>
    with SingleTickerProviderStateMixin {
  late TabController _challengeTabController;

  @override
  void initState() {
    super.initState();
    _challengeTabController = TabController(length: 2, vsync: this);
    // TODO: Load challenges from API
  }

  @override
  void dispose() {
    _challengeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Column(
      children: [
        // Sub-tabs for Active vs Discover
        Container(
          color: backgroundColor,
          child: TabBar(
            controller: _challengeTabController,
            indicatorColor: AppColors.orange,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'My Challenges'),
              Tab(text: 'Discover'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _challengeTabController,
            children: [
              _buildMyChallenges(context, isDark),
              _buildDiscoverChallenges(context, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyChallenges(BuildContext context, bool isDark) {
    // TODO: Replace with actual data from provider
    final hasActiveChallenges = false;

    if (!hasActiveChallenges) {
      return SocialEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Active Challenges',
        description: 'Join a challenge to compete with\nfriends and reach your fitness goals!',
        actionLabel: 'Browse Challenges',
        onAction: () {
          _challengeTabController.animateTo(1);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // TODO: Replace with actual count
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ChallengeCard(
            title: '30-Day Workout Streak',
            description: 'Complete at least one workout every day for 30 days',
            challengeType: 'workout_streak',
            goalValue: 30,
            goalUnit: 'days',
            currentValue: 15,
            progressPercentage: 50,
            participantCount: 24,
            daysRemaining: 15,
            isActive: true,
            onTap: () => _handleChallengeDetails(),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverChallenges(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Create Challenge Button
        _buildCreateChallengeButton(context, isDark),

        const SizedBox(height: 16),

        // Section: Popular Challenges
        Text(
          'Popular Challenges',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // TODO: Replace with actual data
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ChallengeCard(
              title: index.isEven ? 'Push-Up Challenge' : 'Weekly Cardio Goal',
              description: index.isEven
                  ? 'Reach 500 total push-ups this month'
                  : 'Complete 150 minutes of cardio per week',
              challengeType: index.isEven ? 'total_volume' : 'workout_count',
              goalValue: index.isEven ? 500 : 150,
              goalUnit: index.isEven ? 'reps' : 'minutes',
              currentValue: 0,
              progressPercentage: 0,
              participantCount: index * 10 + 50,
              daysRemaining: 30,
              isActive: false,
              onTap: () => _handleJoinChallenge(),
            ),
          );
        }),

        // Bottom spacing
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCreateChallengeButton(BuildContext context, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleCreateChallenge(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.15),
                AppColors.pink.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
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
                  Icons.add_rounded,
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
                      'Create Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start your own challenge and invite friends',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChallengeDetails() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to challenge details screen
  }

  void _handleJoinChallenge() {
    HapticFeedback.mediumImpact();
    // TODO: Show join challenge dialog
  }

  void _handleCreateChallenge() {
    HapticFeedback.mediumImpact();
    // TODO: Navigate to create challenge screen
  }
}
