import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/accessibility/accessibility_provider.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'tabs/feed_tab.dart';
import 'tabs/challenges_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/friends_tab.dart';
import 'senior/senior_social_screen.dart';
import 'friend_search_screen.dart';

/// Social screen - Shows activity feed, challenges, and friends
/// Adapts UI based on accessibility mode (Normal vs Senior)
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilitySettings = ref.watch(accessibilityProvider);

    // Show senior mode layout if in senior mode
    if (accessibilitySettings.isSeniorMode) {
      return const SeniorSocialScreen();
    }

    // Normal mode layout
    return _buildNormalLayout(context);
  }

  Widget _buildNormalLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Get userId from authStateProvider (consistent with rest of app)
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    // Watch activity feed for stats
    final feedDataAsync = userId != null
        ? ref.watch(activityFeedProvider(userId))
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar
              SliverAppBar(
                backgroundColor: backgroundColor,
                floating: true,
                pinned: true,
                title: Text(
                  'Social',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                centerTitle: false,
                actions: [
                  // Search button
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendSearchScreen(),
                        ),
                      );
                    },
                  ),
                  // Add friend button
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendSearchScreen(),
                        ),
                      );
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Column(
                    children: [
                      // Stats chips row
                      _buildStatsChips(context, isDark, feedDataAsync),
                      const SizedBox(height: 4),
                      // Compact tab bar - icons only for space
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.cyan,
                        labelColor: isDark ? Colors.white : Colors.black,
                        unselectedLabelColor: AppColors.textMuted,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(icon: Icon(Icons.dynamic_feed_rounded, size: 22)),
                          Tab(icon: Icon(Icons.emoji_events_rounded, size: 22)),
                          Tab(icon: Icon(Icons.leaderboard_rounded, size: 22)),
                          Tab(icon: Icon(Icons.people_rounded, size: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: const [
              FeedTab(),
              ChallengesTab(),
              LeaderboardTab(),
              FriendsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsChips(
    BuildContext context,
    bool isDark,
    AsyncValue<Map<String, dynamic>>? feedDataAsync,
  ) {
    // Extract stats from feed data if available
    int friendsCount = 0;
    int challengesCount = 0;
    int reactionsCount = 0;

    if (feedDataAsync != null) {
      feedDataAsync.whenData((feedData) {
        friendsCount = feedData['friends_count'] as int? ?? 0;
        challengesCount = feedData['challenges_count'] as int? ?? 0;
        reactionsCount = feedData['reactions_received_count'] as int? ?? 0;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              context,
              isDark: isDark,
              icon: Icons.people_rounded,
              value: friendsCount,
              color: AppColors.cyan,
              onTap: () {
                HapticFeedback.lightImpact();
                _tabController.animateTo(3); // Friends tab
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              context,
              isDark: isDark,
              icon: Icons.emoji_events_rounded,
              value: challengesCount,
              color: AppColors.orange,
              onTap: () {
                HapticFeedback.lightImpact();
                _tabController.animateTo(1); // Challenges tab
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              context,
              isDark: isDark,
              icon: Icons.favorite_rounded,
              value: reactionsCount,
              color: AppColors.pink,
              onTap: () {
                HapticFeedback.lightImpact();
                _tabController.animateTo(0); // Feed tab (where reactions are)
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final chipBackground = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.1);
    final borderColor = color.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
