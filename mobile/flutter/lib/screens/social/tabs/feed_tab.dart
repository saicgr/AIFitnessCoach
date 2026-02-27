import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import '../widgets/activity_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/activity_share_sheet.dart';

/// Activity Feed Tab - Shows recent workouts, achievements, and PRs from friends
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showMyPostsOnly = false;

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
          loading: () => AppLoading.fullScreen(),
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
            final allActivities = (feedData['items'] as List?) ?? [];

            // Apply My Posts filter
            final activities = _showMyPostsOnly
                ? allActivities.where((a) => (a as Map<String, dynamic>)['user_id'] == userId).toList()
                : allActivities;
            final hasActivities = activities.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(activityFeedProvider(userId));
                // Wait for the provider to complete
                await ref.read(activityFeedProvider(userId).future);
              },
              color: ref.colors(context).accent,
              child: !hasActivities && allActivities.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: SocialEmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No Activity Yet',
                            description: 'Complete workouts to see them shared here!\nFollow friends to see their workouts too.',
                            actionLabel: 'Create Post',
                            onAction: () => _showCreatePostSheet(userId),
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // My Posts / All toggle
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('All'),
                                  icon: Icon(Icons.public_rounded, size: 18),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('My Posts'),
                                  icon: Icon(Icons.person_rounded, size: 18),
                                ),
                              ],
                              selected: {_showMyPostsOnly},
                              onSelectionChanged: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _showMyPostsOnly = value.first);
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ),

                        // Empty state for filtered view
                        if (!hasActivities && _showMyPostsOnly)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.post_add_rounded,
                                    size: 48,
                                    color: AppColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create your first post!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Activity Feed List
                        if (hasActivities)
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final activity = activities[index] as Map<String, dynamic>;
                                  final activityId = activity['id'] as String? ?? '';
                                  final postUserId = activity['user_id'] as String? ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: ActivityCard(
                                      activityId: activityId,
                                      currentUserId: userId,
                                      postUserId: postUserId,
                                      userName: activity['user_name'] as String? ?? 'User',
                                      userAvatar: activity['user_avatar'] as String?,
                                      activityType: activity['activity_type'] as String? ?? 'workout_completed',
                                      activityData: activity['activity_data'] as Map<String, dynamic>? ?? {},
                                      timestamp: _parseTimestamp(activity['created_at']),
                                      reactionCount: activity['reaction_count'] as int? ?? 0,
                                      commentCount: activity['comment_count'] as int? ?? 0,
                                      hasUserReacted: activity['user_has_reacted'] as bool? ?? false,
                                      userReactionType: activity['user_reaction_type'] as String?,
                                      onReact: (reactionType) => _handleReaction(activityId, reactionType, userId),
                                      onComment: () => _handleComment(activityId),
                                      onDelete: postUserId == userId ? () => _handleDelete(activityId, userId) : null,
                                      onEdit: postUserId == userId ? () => _handleEdit(activity, userId) : null,
                                      onShare: () => _handleShare(activity),
                                      isPinned: activity['is_pinned'] as bool? ?? false,
                                      isCurrentUserAdmin: isAdmin,
                                      onPin: isAdmin ? () => _handlePinToggle(activityId, activity['is_pinned'] as bool? ?? false, userId) : null,
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
                    ),
            );
          },
        ),

        // Floating Action Button for creating posts
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 72,
          right: 16,
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final accentColor = ref.colors(context).accent;
              return FloatingActionButton(
                onPressed: () => _showCreatePostSheet(userId),
                backgroundColor: accentColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 4,
                child: const Icon(Icons.add_rounded, size: 28),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreatePostSheet(String userId) {
    HapticFeedback.mediumImpact();
    // Hide the floating nav bar when sheet opens
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const CreatePostSheet(),
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

      // 'remove' is a special signal from the UI to remove the reaction
      if (reactionType == 'remove') {
        await socialService.removeReaction(
          userId: userId,
          activityId: activityId,
        );
        debugPrint('Removed reaction');
      } else {
        // Toggle: if already reacted with same type, remove; otherwise add/update
        final activity = ref.read(activityFeedProvider(userId)).value?['items']
            ?.firstWhere((a) => a['id'] == activityId, orElse: () => null);

        if (activity != null &&
            activity['user_has_reacted'] == true &&
            activity['user_reaction_type'] == reactionType) {
          await socialService.removeReaction(
            userId: userId,
            activityId: activityId,
          );
          debugPrint('Toggled off reaction: $reactionType');
        } else {
          await socialService.addReaction(
            userId: userId,
            activityId: activityId,
            reactionType: reactionType,
          );
          debugPrint('Added reaction: $reactionType');
        }
      }

      // Refresh the feed to show updated reaction counts
      ref.invalidate(activityFeedProvider(userId));
    } catch (e) {
      debugPrint('Error handling reaction: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to update reaction. Please try again.');
      }
    }
  }

  void _handleComment(String activityId) {
    HapticFeedback.lightImpact();
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => CommentsSheet(activityId: activityId),
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  Future<void> _handleDelete(String activityId, String userId) async {
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.deleteActivity(userId: userId, activityId: activityId);

      if (mounted) {
        AppSnackBar.success(context, 'Post deleted');
      }

      ref.invalidate(activityFeedProvider(userId));
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to delete post');
      }
    }
  }

  void _handleEdit(Map<String, dynamic> activity, String userId) {
    HapticFeedback.lightImpact();
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => CreatePostSheet(existingActivity: activity),
    ).then((result) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      if (result == true) {
        ref.invalidate(activityFeedProvider(userId));
      }
    });
  }

  void _handleShare(Map<String, dynamic> activity) {
    HapticFeedback.lightImpact();
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => ActivityShareSheet(
        userName: activity['user_name'] as String? ?? 'Someone',
        activityType: activity['activity_type'] as String? ?? 'manual_post',
        activityData: activity['activity_data'] as Map<String, dynamic>? ?? {},
        timestamp: _parseTimestamp(activity['created_at']),
      ),
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  Future<void> _handlePinToggle(String activityId, bool currentlyPinned, String userId) async {
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);

      if (currentlyPinned) {
        await socialService.unpinPost(userId: userId, activityId: activityId);
        if (mounted) {
          AppSnackBar.info(context, 'Post unpinned');
        }
      } else {
        await socialService.pinPost(userId: userId, activityId: activityId);
        if (mounted) {
          AppSnackBar.success(context, 'Post pinned to top of feed');
        }
      }

      // Refresh the feed to show updated pin status
      ref.invalidate(activityFeedProvider(userId));
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to ${currentlyPinned ? 'unpin' : 'pin'} post. Please try again.');
      }
    }
  }
}
