import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/segmented_tab_bar.dart';
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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _challengeTabController = TabController(length: 2, vsync: this);

    // Get userId from authStateProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (mounted && userId != null) {
        setState(() => _userId = userId);
      }
    });
  }

  @override
  void dispose() {
    _challengeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Sub-tabs for Active vs Discover
        SegmentedTabBar(
          controller: _challengeTabController,
          showIcons: false,
          tabs: const [
            SegmentedTabItem(label: 'My Challenges', icon: Icons.emoji_events_rounded),
            SegmentedTabItem(label: 'Discover', icon: Icons.explore_rounded),
          ],
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
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeChallengesAsync = ref.watch(userActiveChallengesProvider(_userId!));

    return activeChallengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading active challenges: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Challenges',
          description: 'Could not load your challenges.\nPlease try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(userActiveChallengesProvider(_userId!));
          },
        );
      },
      data: (challenges) {
        if (challenges.isEmpty) {
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
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final participation = challenge['user_participation'] as Map<String, dynamic>?;
            final endDate = DateTime.tryParse(challenge['end_date'] as String? ?? '');
            final daysRemaining = endDate != null
                ? endDate.difference(DateTime.now()).inDays
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ChallengeCard(
                title: challenge['title'] as String? ?? 'Challenge',
                description: challenge['description'] as String? ?? '',
                challengeType: challenge['challenge_type'] as String? ?? 'workout_count',
                goalValue: (challenge['goal_value'] as num?)?.toDouble() ?? 0,
                goalUnit: challenge['goal_unit'] as String? ?? '',
                currentValue: (participation?['current_value'] as num?)?.toDouble() ?? 0,
                progressPercentage: (participation?['progress_percentage'] as num?)?.toDouble() ?? 0,
                participantCount: challenge['participant_count'] as int? ?? 0,
                daysRemaining: daysRemaining,
                isActive: true,
                onTap: () => _handleChallengeDetails(challenge['id'] as String?),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscoverChallenges(BuildContext context, bool isDark) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final challengesAsync = ref.watch(challengesListProvider(_userId!));

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading challenges: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Challenges',
          description: 'Could not load challenges.\nPlease try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(challengesListProvider(_userId!));
          },
        );
      },
      data: (challenges) {
        // Filter out challenges user is already participating in
        final availableChallenges = challenges
            .where((c) => c['user_participation'] == null)
            .toList();

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

            if (availableChallenges.isEmpty)
              SocialEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No Challenges Found',
                description: 'Be the first to create a challenge!',
                actionLabel: null,
                onAction: null,
              )
            else
              ...availableChallenges.map((challenge) {
                final endDate = DateTime.tryParse(challenge['end_date'] as String? ?? '');
                final daysRemaining = endDate != null
                    ? endDate.difference(DateTime.now()).inDays
                    : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(
                    title: challenge['title'] as String? ?? 'Challenge',
                    description: challenge['description'] as String? ?? '',
                    challengeType: challenge['challenge_type'] as String? ?? 'workout_count',
                    goalValue: (challenge['goal_value'] as num?)?.toDouble() ?? 0,
                    goalUnit: challenge['goal_unit'] as String? ?? '',
                    currentValue: 0,
                    progressPercentage: 0,
                    participantCount: challenge['participant_count'] as int? ?? 0,
                    daysRemaining: daysRemaining,
                    isActive: false,
                    onTap: () => _handleJoinChallenge(challenge['id'] as String?),
                  ),
                );
              }),

            // Bottom spacing
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildCreateChallengeButton(BuildContext context, bool isDark) {
    final colors = ref.colors(context);
    final accentColor = colors.accent;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleCreateChallenge(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: colors.accentContrast,
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
                            color: textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChallengeDetails(String? challengeId) {
    if (challengeId == null) return;
    HapticFeedback.lightImpact();
    // TODO: Navigate to challenge details screen
    debugPrint('Navigate to challenge details: $challengeId');
  }

  Future<void> _handleJoinChallenge(String? challengeId) async {
    if (challengeId == null || _userId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.joinChallenge(
        userId: _userId!,
        challengeId: challengeId,
      );
      _showSnackBar('Joined challenge!');
      // Refresh both lists
      ref.invalidate(challengesListProvider(_userId!));
      ref.invalidate(userActiveChallengesProvider(_userId!));
      // Switch to My Challenges tab
      _challengeTabController.animateTo(0);
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      _showSnackBar('Failed to join challenge');
    }
  }

  void _handleCreateChallenge() {
    HapticFeedback.mediumImpact();
    // TODO: Navigate to create challenge screen
    _showSnackBar('Create challenge feature coming soon!');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
