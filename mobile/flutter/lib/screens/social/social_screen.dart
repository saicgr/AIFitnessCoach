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
                  // Username chip (compact, tap to copy)
                  _buildCompactUserChip(context, isDark, authState.user),
                  // Find friends button
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded),
                    tooltip: 'Find Friends',
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
                  preferredSize: const Size.fromHeight(116),
                  child: Column(
                    children: [
                      // Stats chips row
                      _buildStatsChips(context, isDark, feedDataAsync),
                      const SizedBox(height: 4),
                      // Modern segmented tab bar
                      _buildSegmentedTabs(context, isDark),
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

  Widget _buildSegmentedTabs(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Row(
              children: [
                _buildTabItem(
                  context,
                  index: 0,
                  icon: Icons.dynamic_feed_rounded,
                  label: 'Feed',
                  isDark: isDark,
                ),
                _buildTabItem(
                  context,
                  index: 1,
                  icon: Icons.emoji_events_rounded,
                  label: 'Challenges',
                  isDark: isDark,
                ),
                _buildTabItem(
                  context,
                  index: 2,
                  icon: Icons.leaderboard_rounded,
                  label: 'Ranks',
                  isDark: isDark,
                ),
                _buildTabItem(
                  context,
                  index: 3,
                  icon: Icons.people_rounded,
                  label: 'Friends',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _tabController.index == index;
    final animationValue = _tabController.animation?.value ?? 0.0;

    // Calculate selection progress for smooth animation
    final selectionProgress = (1.0 - (animationValue - index).abs()).clamp(0.0, 1.0);

    // Colors
    final selectedBg = AppColors.cyan;
    final unselectedBg = Colors.transparent;
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedFg = AppColors.textMuted;

    // Interpolate colors based on selection progress
    final bgColor = Color.lerp(unselectedBg, selectedBg, selectionProgress)!;
    final fgColor = Color.lerp(unselectedFg, selectedFg, selectionProgress)!;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: fgColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
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

  Widget _buildCompactUserChip(
    BuildContext context,
    bool isDark,
    dynamic user,
  ) {
    final username = user?.username as String?;
    final userId = user?.id as String?;

    // Show username if available, otherwise show truncated user ID
    final displayText = username ?? (userId?.substring(0, 6) ?? '---');
    final copyText = username ?? userId ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (copyText.isNotEmpty) {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: copyText));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  username != null
                      ? 'Username copied: @$username'
                      : 'User ID copied',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cyan.withValues(alpha: 0.15)
                : AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@$displayText',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.copy_rounded,
                color: AppColors.cyan.withValues(alpha: 0.7),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
