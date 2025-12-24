import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/friend_card.dart';
import '../widgets/empty_state.dart';

/// Friends Tab - Shows friends, followers, and following
class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab>
    with SingleTickerProviderStateMixin {
  late TabController _friendsTabController;

  @override
  void initState() {
    super.initState();
    _friendsTabController = TabController(length: 3, vsync: this);
    // TODO: Load friends data from API
  }

  @override
  void dispose() {
    _friendsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Column(
      children: [
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
            bio: 'Fitness enthusiast • 🏋️ 150 workouts',
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
            bio: 'Beginner • Started 2 months ago',
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
            bio: 'Powerlifter • 💪 300 workouts',
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
    // TODO: Navigate to friend search screen
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
