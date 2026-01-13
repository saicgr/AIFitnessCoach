import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/main_shell.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get userId from authStateProvider (consistent with rest of app)
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    final isAdmin = ref.watch(isAdminProvider);

    // If no userId, show error
    if (userId == null) {
      return SocialEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Not Logged In',
        description: 'Please log in to see your activity feed',
        actionLabel: null,
        onAction: null,
      );
    }

    // Use the activityFeedProvider to load feed data
    final activityFeedAsync = ref.watch(activityFeedProvider(userId));

    return Stack(
      children: [
        activityFeedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            debugPrint('Error loading feed: $error');
            return SocialEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Failed to Load Feed',
              description: 'Could not load your activity feed.\nPlease try again later.',
              actionLabel: 'Retry',
              onAction: () {
                ref.invalidate(activityFeedProvider(userId));
              },
            );
          },
          data: (feedData) {
            // Backend returns 'items' key for activity list
            final activities = (feedData['items'] as List?) ?? [];
            final hasActivities = activities.isNotEmpty;

            if (!hasActivities) {
              return SocialEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Activity Yet',
                description: 'Complete workouts to see them shared here!\nFollow friends to see their workouts too.',
                actionLabel: 'Create Post',
                onAction: () => _showCreatePostSheet(userId),
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Activity Feed List
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = activities[index] as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ActivityCard(
                            activityId: activity['id'] as String? ?? '',
                            currentUserId: userId,
                            userName: activity['user_name'] as String? ?? 'User',
                            userAvatar: activity['user_avatar'] as String?,
                            activityType: activity['activity_type'] as String? ?? 'workout_completed',
                            activityData: activity['activity_data'] as Map<String, dynamic>? ?? {},
                            timestamp: _parseTimestamp(activity['created_at']),
                            reactionCount: activity['reaction_count'] as int? ?? 0,
                            commentCount: activity['comment_count'] as int? ?? 0,
                            hasUserReacted: activity['user_has_reacted'] as bool? ?? false,
                            userReactionType: activity['user_reaction_type'] as String?,
                            onReact: (reactionType) => _handleReaction(activity['id'] as String, reactionType, userId),
                            onComment: () => _handleComment(activity['id'] as String),
                            isPinned: activity['is_pinned'] as bool? ?? false,
                            isCurrentUserAdmin: isAdmin,
                            onPin: isAdmin ? () => _handlePinToggle(activity['id'] as String, activity['is_pinned'] as bool? ?? false, userId) : null,
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
            onPressed: () => _showCreatePostSheet(userId),
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  void _showCreatePostSheet(String userId) {
    HapticFeedback.mediumImpact();
    // Hide the floating nav bar when sheet opens
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
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
      // Show the floating nav bar again when sheet closes
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      // If post was created, refresh the feed
      if (result == true) {
        ref.invalidate(activityFeedProvider(userId));
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
        debugPrint('Failed to parse timestamp: $timestamp');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Future<void> _handleReaction(String activityId, String reactionType, String userId) async {
    HapticFeedback.lightImpact();

    try {
      final socialService = ref.read(socialServiceProvider);

      // Toggle reaction: if already reacted with this type, remove it; otherwise add/update
      final activity = ref.read(activityFeedProvider(userId)).value?['items']
          ?.firstWhere((a) => a['id'] == activityId, orElse: () => null);

      if (activity != null &&
          activity['user_has_reacted'] == true &&
          activity['user_reaction_type'] == reactionType) {
        // Remove reaction
        await socialService.removeReaction(
          userId: userId,
          activityId: activityId,
        );
        debugPrint('Removed reaction: $reactionType');
      } else {
        // Add or update reaction
        await socialService.addReaction(
          userId: userId,
          activityId: activityId,
          reactionType: reactionType,
        );
        debugPrint('Added reaction: $reactionType');
      }

      // Refresh the feed to show updated reaction counts
      ref.invalidate(activityFeedProvider(userId));
    } catch (e) {
      debugPrint('Error handling reaction: $e');
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
    debugPrint('Comment on activity: $activityId');

    // Placeholder: Show coming soon message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comments feature coming soon!')),
      );
    }
  }

  Future<void> _handlePinToggle(String activityId, bool currentlyPinned, String userId) async {
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);

      if (currentlyPinned) {
        await socialService.unpinPost(userId: userId, activityId: activityId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post unpinned'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await socialService.pinPost(userId: userId, activityId: activityId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post pinned to top of feed'),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Refresh the feed to show updated pin status
      ref.invalidate(activityFeedProvider(userId));
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${currentlyPinned ? 'unpin' : 'pin'} post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
