import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/glass_sheet.dart';
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
import '../widgets/stories_ring.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Feed filter: show only my posts
final feedMyPostsOnlyProvider = StateProvider<bool>((ref) => false);

/// Auto-scroll: vertical feed cards
final feedAutoScrollProvider = StateProvider<bool>((ref) => false);

/// Auto-scroll: horizontal stories ring
final storiesAutoScrollProvider = StateProvider<bool>((ref) => false);

/// Activity Feed Tab - Shows recent workouts, achievements, and PRs from friends
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _disposed = false;

  /// True until the feed has been opened once on this install. Drives whether
  /// the cold-load placeholder is a skeleton (first ever) — the cache-first
  /// provider means returning users never hit a skeleton again.
  bool _isFirstEver = true;

  /// Latches once the "seen" flag has been persisted this session.
  bool _markedSeen = false;

  @override
  void initState() {
    super.initState();
    // Resolve the first-ever flag off the UI thread; never blocks the build.
    CacheFirstView.hasBeenSeen('social_feed').then((seen) {
      if (mounted && seen) setState(() => _isFirstEver = false);
    });
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || !_scrollController.hasClients) return;
      final current = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;
      if (current >= max) {
        // Reached bottom — auto-disable
        ref.read(feedAutoScrollProvider.notifier).state = false;
        return;
      }
      final target = (current + 280).clamp(0.0, max);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopAutoScroll();
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
        title: AppLocalizations.of(context).messagesNotLoggedIn,
        description: AppLocalizations.of(context).feedPleaseLogInTo,
        actionLabel: null,
        onAction: null,
      );
    }

    // Auto-scroll: start/stop timer when provider changes
    ref.listen<bool>(feedAutoScrollProvider, (prev, next) {
      if (next) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    });

    // Use the activityFeedProvider to load feed data
    final activityFeedAsync = ref.watch(activityFeedProvider(userId));

    return Stack(
      children: [
        CacheFirstView<Map<String, dynamic>>(
          value: activityFeedAsync,
          isFirstEver: _isFirstEver,
          traceLabel: 'social_feed',
          // Layout-matched placeholder: a stories-ring strip + a list of
          // post-card skeletons, mirroring the real feed shape.
          skeletonBuilder: (context) => const _FeedSkeleton(),
          errorBuilder: (context, error, st) {
            debugPrint('Error loading feed: $error');
            return SocialEmptyState(
              icon: Icons.cloud_off_rounded,
              title: AppLocalizations.of(context).feedFailedToLoadFeed,
              description: AppLocalizations.of(context).feedCouldNotLoadYour,
              actionLabel: 'Retry',
              onAction: () {
                ref.invalidate(activityFeedProvider(userId));
              },
            );
          },
          contentBuilder: (context, feedData) {
            // First successful content — persist the "seen" flag once so
            // future cold opens skip the skeleton. Guard prevents repeated
            // SharedPreferences writes on every rebuild this session.
            if (!_markedSeen) {
              _markedSeen = true;
              CacheFirstView.markSeen('social_feed');
            }
            // Backend returns 'items' key for activity list
            final allActivities = (feedData['items'] as List?) ?? [];

            // Apply My Posts filter
            final showMyPostsOnly = ref.watch(feedMyPostsOnlyProvider);
            final activities = showMyPostsOnly
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
                        const StoriesRing(),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: SocialEmptyState(
                            icon: Icons.people_outline_rounded,
                            title: AppLocalizations.of(context).feedNoActivityYet,
                            description: AppLocalizations.of(context).feedCompleteWorkoutsToSee,
                            actionLabel: 'Create Post',
                            onAction: () => _showCreatePostSheet(userId),
                          ),
                        ),
                      ],
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        // User-initiated drag → disable auto-scroll
                        if (notification is UserScrollNotification &&
                            notification.direction != ScrollDirection.idle) {
                          if (ref.read(feedAutoScrollProvider)) {
                            ref.read(feedAutoScrollProvider.notifier).state = false;
                          }
                        }
                        return false;
                      },
                      child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Stories ring (scrolls with feed)
                        SliverToBoxAdapter(
                          child: const StoriesRing(),
                        ),

                        // Empty state for filtered view
                        if (!hasActivities && showMyPostsOnly)
                          SliverFillRemaining(
                            hasScrollBody: false,
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
                                    AppLocalizations.of(context).feedNoPostsYet,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).feedCreateYourFirstPost,
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
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: ActivityShareSheet(
          userName: activity['user_name'] as String? ?? 'Someone',
          activityType: activity['activity_type'] as String? ?? 'manual_post',
          activityData: activity['activity_data'] as Map<String, dynamic>? ?? {},
          timestamp: _parseTimestamp(activity['created_at']),
        ),
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

/// Layout-matched skeleton for the activity feed shown ONLY on a true
/// first-ever open (no cache has ever existed). It mirrors the real feed: a
/// horizontal stories-ring strip on top, then a column of post-card
/// placeholders, so the skeleton → content cross-fade does not reflow.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    // Non-interactive: the real feed is a CustomScrollView, but the skeleton
    // just needs to fill the viewport with placeholder shapes.
    return ListView(
      // Match the real feed: the list itself scrolls, padded like ActivityCard.
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Stories-ring strip placeholder (circle avatars in a row).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonCircle(size: 60),
            ),
          ),
        ),
        // Post-card placeholders — taller than a default SkeletonCard so they
        // read as feed posts (avatar + text + media block).
        Padding(
          padding: const EdgeInsets.all(16),
          child: SkeletonList(
            itemCount: 4,
            spacing: 16,
            itemBuilder: (context, index) => const SkeletonCard(
              height: 180,
              lines: 3,
              leadingSize: 40,
            ),
          ),
        ),
      ],
    );
  }
}
