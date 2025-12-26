import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/services/api_client.dart';
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
    _initUser();
  }

  Future<void> _initUser() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
      if (userId != null) {
        _loadPendingRequests();
      }
    }
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
        Container(
          color: backgroundColor,
          child: TabBar(
            controller: _friendsTabController,
            indicatorColor: AppColors.cyan,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: AppColors.textMuted,
            isScrollable: false,
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
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
              const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Friend Requests',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
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
    // TODO: Replace with actual data from provider
    final hasFriends = false;

    if (!hasFriends) {
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
      itemCount: 10, // TODO: Replace with actual count
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FriendCard(
            name: 'John Doe',
            avatarUrl: null,
            bio: 'Fitness enthusiast',
            currentStreak: 15,
            totalWorkouts: 150,
            totalAchievements: 24,
            isFriend: true,
            isFollowing: true,
            onTap: () => _handleUserProfile(),
            onFollow: () => _handleFollow(),
          ),
        );
      },
    );
  }

  Widget _buildFollowersList(BuildContext context, bool isDark) {
    // TODO: Replace with actual data
    final hasFollowers = false;

    if (!hasFollowers) {
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
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FriendCard(
            name: 'Jane Smith',
            avatarUrl: null,
            bio: 'Beginner',
            currentStreak: 7,
            totalWorkouts: 20,
            totalAchievements: 5,
            isFriend: false,
            isFollowing: false,
            onTap: () => _handleUserProfile(),
            onFollow: () => _handleFollow(),
          ),
        );
      },
    );
  }

  Widget _buildFollowingList(BuildContext context, bool isDark) {
    // TODO: Replace with actual data
    final hasFollowing = false;

    if (!hasFollowing) {
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
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FriendCard(
            name: 'Alex Johnson',
            avatarUrl: null,
            bio: 'Powerlifter',
            currentStreak: 45,
            totalWorkouts: 300,
            totalAchievements: 50,
            isFriend: index.isEven,
            isFollowing: true,
            onTap: () => _handleUserProfile(),
            onFollow: () => _handleUnfollow(),
          ),
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

  void _handleUserProfile() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to user profile screen
  }

  void _handleFollow() {
    HapticFeedback.mediumImpact();
    // TODO: Send follow request to API
  }

  void _handleUnfollow() {
    HapticFeedback.mediumImpact();
    // TODO: Unfollow user via API
  }
}
