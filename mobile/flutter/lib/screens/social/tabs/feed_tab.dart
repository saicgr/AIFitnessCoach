import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/services/api_client.dart';
import '../widgets/activity_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/create_post_sheet.dart';

/// Activity Feed Tab - Shows recent workouts, achievements, and PRs from friends
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() {
        _userId = userId;
        _isLoadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading while fetching userId
    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no userId, show error
    if (_userId == null) {
      return SocialEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Not Logged In',
        description: 'Please log in to see your activity feed',
        actionLabel: null,
        onAction: null,
      );
    }

    // Use the activityFeedProvider to load feed data
    final activityFeedAsync = ref.watch(activityFeedProvider(_userId!));

    return Stack(
      children: [
        activityFeedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            debugPrint('❌ [FeedTab] Error loading feed: $error');
            return SocialEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Failed to Load Feed',
              description: 'Could not load your activity feed.\nPlease try again later.',
              actionLabel: 'Retry',
              onAction: () {
                ref.invalidate(activityFeedProvider(_userId!));
              },
            );
          },
          data: (feedData) {
            final activities = (feedData['activities'] as List?) ?? [];
            final hasActivities = activities.isNotEmpty;

            if (!hasActivities) {
              return SocialEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Activity Yet',
                description: 'Complete workouts to see them shared here!\nFollow friends to see their workouts too.',
                actionLabel: 'Create Post',
                onAction: _showCreatePostSheet,
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Quick Stats Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildQuickStats(context, isDark, feedData),
                  ),
                ),

                // Activity Feed List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = activities[index] as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ActivityCard(
                            activityId: activity['id'] as String? ?? '',
                            currentUserId: _userId ?? '',
                            userName: activity['user_name'] as String? ?? 'User',
                            userAvatar: activity['user_avatar'] as String?,
                            activityType: activity['activity_type'] as String? ?? 'workout_completed',
                            activityData: activity['activity_data'] as Map<String, dynamic>? ?? {},
                            timestamp: _parseTimestamp(activity['created_at']),
                            reactionCount: activity['reaction_count'] as int? ?? 0,
                            commentCount: activity['comment_count'] as int? ?? 0,
                            hasUserReacted: activity['user_has_reacted'] as bool? ?? false,
                            userReactionType: activity['user_reaction_type'] as String?,
                            onReact: (reactionType) => _handleReaction(activity['id'] as String, reactionType),
                            onComment: () => _handleComment(activity['id'] as String),
                          ),
                        );
                      },
                      childCount: activities.length,
                    ),
                  ),
                ),

                // Bottom spacing for floating nav bar and FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            );
          },
        ),

        // Floating Action Button for creating posts
        Positioned(
          bottom: 80, // Above the bottom nav bar
          right: 16,
          child: FloatingActionButton(
            onPressed: _showCreatePostSheet,
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  void _showCreatePostSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const CreatePostSheet(),
      ),
    ).then((result) {
      // If post was created, refresh the feed
      if (result == true && _userId != null) {
        ref.invalidate(activityFeedProvider(_userId!));
      }
    });
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        debugPrint('⚠️ [FeedTab] Failed to parse timestamp: $timestamp');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Widget _buildQuickStats(BuildContext context, bool isDark, Map<String, dynamic> feedData) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Extract stats from feedData
    final friendsCount = feedData['friends_count'] as int? ?? 0;
    final challengesCount = feedData['challenges_count'] as int? ?? 0;
    final reactionsCount = feedData['reactions_received_count'] as int? ?? 0;

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
            value: friendsCount.toString(),
            color: AppColors.cyan,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.emoji_events_rounded,
            label: 'Challenges',
            value: challengesCount.toString(),
            color: AppColors.orange,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.favorite_rounded,
            label: 'Reactions',
            value: reactionsCount.toString(),
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

  Future<void> _handleReaction(String activityId, String reactionType) async {
    HapticFeedback.lightImpact();

    if (_userId == null) return;

    try {
      final socialService = ref.read(socialServiceProvider);

      // Toggle reaction: if already reacted with this type, remove it; otherwise add/update
      final activity = ref.read(activityFeedProvider(_userId!)).value?['activities']
          ?.firstWhere((a) => a['id'] == activityId, orElse: () => null);

      if (activity != null &&
          activity['user_has_reacted'] == true &&
          activity['user_reaction_type'] == reactionType) {
        // Remove reaction
        await socialService.removeReaction(
          userId: _userId!,
          activityId: activityId,
        );
        debugPrint('🔄 [FeedTab] Removed reaction: $reactionType');
      } else {
        // Add or update reaction
        await socialService.addReaction(
          userId: _userId!,
          activityId: activityId,
          reactionType: reactionType,
        );
        debugPrint('🔄 [FeedTab] Added reaction: $reactionType');
      }

      // Refresh the feed to show updated reaction counts
      ref.invalidate(activityFeedProvider(_userId!));
    } catch (e) {
      debugPrint('❌ [FeedTab] Error handling reaction: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update reaction. Please try again.')),
        );
      }
    }
  }

  void _handleComment(String activityId) {
    HapticFeedback.lightImpact();
    // TODO: Show comment bottom sheet
    debugPrint('💬 [FeedTab] Comment on activity: $activityId');

    // Placeholder: Show coming soon message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comments feature coming soon!')),
      );
    }
  }
}
