import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../widgets/friend_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/pending_request_card.dart';
import '../friend_search_screen.dart';

/// Friends Tab - Shows pending requests, friends, followers, and following
class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab>
    with SingleTickerProviderStateMixin {
  late TabController _friendsTabController;

  String? _userId;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoadingPending = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _friendsTabController = TabController(length: 3, vsync: this);

    // Get userId from authStateProvider (consistent with rest of app)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (mounted && userId != null) {
        setState(() => _userId = userId);
        _loadPendingRequests();
      }
    });
  }

  @override
  void dispose() {
    _friendsTabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    if (_userId == null) return;

    setState(() => _isLoadingPending = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      final requests = await socialService.getReceivedFriendRequests(
        userId: _userId!,
        status: 'pending',
      );
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _pendingCount = requests.length;
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load pending requests: $e');
      if (mounted) {
        setState(() => _isLoadingPending = false);
      }
    }
  }

  Future<void> _handleAcceptRequest(String requestId) async {
    if (_userId == null) return;

    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.acceptFriendRequest(
        userId: _userId!,
        requestId: requestId,
      );
      _showSnackBar('Friend request accepted!');
      await _loadPendingRequests();
    } catch (e) {
      _showSnackBar('Failed to accept request');
    }
  }

  Future<void> _handleDeclineRequest(String requestId) async {
    if (_userId == null) return;

    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.declineFriendRequest(
        userId: _userId!,
        requestId: requestId,
      );
      _showSnackBar('Friend request declined');
      await _loadPendingRequests();
    } catch (e) {
      _showSnackBar('Failed to decline request');
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Column(
      children: [
        // Pending Requests Section (if any)
        if (_pendingCount > 0) _buildPendingRequestsSection(isDark),

        // Sub-tabs for Friends, Followers, Following
        SegmentedTabBar(
          controller: _friendsTabController,
          showIcons: false,
          tabs: const [
            SegmentedTabItem(label: 'Friends', icon: Icons.people_rounded),
            SegmentedTabItem(label: 'Followers', icon: Icons.person_add_rounded),
            SegmentedTabItem(label: 'Following', icon: Icons.person_rounded),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _friendsTabController,
            children: [
              _buildFriendsList(context, isDark),
              _buildFollowersList(context, isDark),
              _buildFollowingList(context, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestsSection(bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: ref.colors(context).accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Friend Requests',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ref.colors(context).accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ref.colors(context).accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal scroll of pending requests
          SizedBox(
            height: 140,
            child: _isLoadingPending
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _pendingRequests.length - 1 ? 12 : 0,
                        ),
                        child: PendingRequestCard(
                          request: request,
                          onAccept: () => _handleAcceptRequest(request['id']),
                          onDecline: () => _handleDeclineRequest(request['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, bool isDark) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final friendsAsync = ref.watch(friendsListProvider(_userId!));

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading friends: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Friends',
          description: 'Could not load your friends list.\nPlease try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(friendsListProvider(_userId!));
          },
        );
      },
      data: (friends) {
        if (friends.isEmpty) {
          return SocialEmptyState(
            icon: Icons.people_rounded,
            title: 'No Friends Yet',
            description: 'Add friends to see their workouts\nand compete in challenges together!',
            actionLabel: 'Find Friends',
            onAction: () => _handleFindFriends(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FriendCard(
                name: friend['name'] as String? ?? 'Unknown',
                avatarUrl: friend['avatar_url'] as String?,
                bio: friend['bio'] as String?,
                currentStreak: friend['current_streak'] as int? ?? 0,
                totalWorkouts: friend['total_workouts'] as int? ?? 0,
                totalAchievements: friend['total_achievements'] as int? ?? 0,
                isFriend: true,
                isFollowing: true,
                isSupportUser: friend['is_support_user'] as bool? ?? false,
                onTap: () => _handleUserProfile(friend['id'] as String?),
                onFollow: () {}, // Already friends
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowersList(BuildContext context, bool isDark) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final followersAsync = ref.watch(followersListProvider(_userId!));

    return followersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading followers: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Followers',
          description: 'Could not load your followers list.\nPlease try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(followersListProvider(_userId!));
          },
        );
      },
      data: (followers) {
        if (followers.isEmpty) {
          return SocialEmptyState(
            icon: Icons.person_add_outlined,
            title: 'No Followers Yet',
            description: 'Keep crushing your workouts!\nFriends will want to follow your progress.',
            actionLabel: null,
            onAction: null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final follower = followers[index];
            final userProfile = follower['user_profile'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FriendCard(
                name: userProfile?['name'] as String? ?? 'Unknown',
                avatarUrl: userProfile?['avatar_url'] as String?,
                bio: follower['bio'] as String?,
                currentStreak: follower['current_streak'] as int? ?? 0,
                totalWorkouts: follower['total_workouts'] as int? ?? 0,
                totalAchievements: follower['total_achievements'] as int? ?? 0,
                isFriend: false,
                isFollowing: false,
                isSupportUser: userProfile?['is_support_user'] as bool? ?? false,
                onTap: () => _handleUserProfile(userProfile?['id'] as String?),
                onFollow: () => _handleFollow(userProfile?['id'] as String?),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList(BuildContext context, bool isDark) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final followingAsync = ref.watch(followingListProvider(_userId!));

    return followingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading following: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Following',
          description: 'Could not load users you follow.\nPlease try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(followingListProvider(_userId!));
          },
        );
      },
      data: (following) {
        if (following.isEmpty) {
          return SocialEmptyState(
            icon: Icons.person_search_outlined,
            title: 'Not Following Anyone',
            description: 'Follow friends to see their workouts\nand stay motivated together!',
            actionLabel: 'Find Friends',
            onAction: () => _handleFindFriends(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: following.length,
          itemBuilder: (context, index) {
            final follow = following[index];
            final userProfile = follow['user_profile'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FriendCard(
                name: userProfile?['name'] as String? ?? 'Unknown',
                avatarUrl: userProfile?['avatar_url'] as String?,
                bio: follow['bio'] as String?,
                currentStreak: follow['current_streak'] as int? ?? 0,
                totalWorkouts: follow['total_workouts'] as int? ?? 0,
                totalAchievements: follow['total_achievements'] as int? ?? 0,
                isFriend: false,
                isFollowing: true,
                isSupportUser: userProfile?['is_support_user'] as bool? ?? false,
                onTap: () => _handleUserProfile(userProfile?['id'] as String?),
                onFollow: () => _handleUnfollow(userProfile?['id'] as String?),
              ),
            );
          },
        );
      },
    );
  }

  void _handleFindFriends() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FriendSearchScreen()),
    );
  }

  void _handleUserProfile(String? targetUserId) {
    if (targetUserId == null) return;
    HapticFeedback.lightImpact();
    // TODO: Navigate to user profile screen
    debugPrint('Navigate to user profile: $targetUserId');
  }

  Future<void> _handleFollow(String? targetUserId) async {
    if (targetUserId == null || _userId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.followUser(
        userId: _userId!,
        followingId: targetUserId,
      );
      _showSnackBar('Now following user');
      // Refresh the lists
      ref.invalidate(followersListProvider(_userId!));
      ref.invalidate(followingListProvider(_userId!));
      ref.invalidate(friendsListProvider(_userId!));
    } catch (e) {
      debugPrint('Error following user: $e');
      _showSnackBar('Failed to follow user');
    }
  }

  Future<void> _handleUnfollow(String? targetUserId) async {
    if (targetUserId == null || _userId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.unfollowUser(
        userId: _userId!,
        followingId: targetUserId,
      );
      _showSnackBar('Unfollowed user');
      // Refresh the lists
      ref.invalidate(followersListProvider(_userId!));
      ref.invalidate(followingListProvider(_userId!));
      ref.invalidate(friendsListProvider(_userId!));
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      _showSnackBar('Failed to unfollow user');
    }
  }
}
