import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/activity_card.dart';
import '../widgets/empty_state.dart';

/// Activity Feed Tab - Shows recent workouts, achievements, and PRs from friends
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load activity feed from API
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // TODO: Replace with actual data from provider
    final hasActivities = false; // Placeholder

    if (!hasActivities && !_isLoading) {
      return SocialEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Activity Yet',
        description: 'Follow friends to see their workouts\nand achievements here!',
        actionLabel: 'Find Friends',
        onAction: () {
          // TODO: Navigate to friends tab or search
          HapticFeedback.lightImpact();
        },
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Quick Stats Summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildQuickStats(context, isDark),
          ),
        ),

        // Activity Feed List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // TODO: Replace with actual activity data
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ActivityCard(
                    userName: 'John Doe',
                    userAvatar: null,
                    activityType: 'workout_completed',
                    activityData: {
                      'workout_name': 'Upper Body Strength',
                      'duration_minutes': 45,
                      'exercises_count': 8,
                    },
                    timestamp: DateTime.now().subtract(Duration(hours: index + 1)),
                    reactionCount: 12,
                    commentCount: 3,
                    hasUserReacted: index == 0,
                    userReactionType: index == 0 ? 'fire' : null, // Example: first item has fire reaction
                    onReact: (reactionType) => _handleReaction(reactionType),
                    onComment: () => _handleComment(),
                  ),
                );
              },
              childCount: 5, // TODO: Replace with actual count
            ),
          ),
        ),

        // Bottom spacing for floating nav bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.people_rounded,
            label: 'Friends',
            value: '24',
            color: AppColors.cyan,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.emoji_events_rounded,
            label: 'Challenges',
            value: '3',
            color: AppColors.orange,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.favorite_rounded,
            label: 'Reactions',
            value: '89',
            color: AppColors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
          .withValues(alpha: 0.3),
    );
  }

  void _handleReaction(String reactionType) {
    HapticFeedback.lightImpact();
    // TODO: Send reaction to API
    debugPrint('Reaction: $reactionType');
  }

  void _handleComment() {
    HapticFeedback.lightImpact();
    // TODO: Show comment bottom sheet
  }
}
