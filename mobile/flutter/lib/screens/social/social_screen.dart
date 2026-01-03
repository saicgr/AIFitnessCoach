import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/accessibility/accessibility_provider.dart';
import '../../data/providers/multi_screen_tour_provider.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/multi_screen_tour_helper.dart';
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

  // Tour key for Challenges section
  final GlobalKey _challengesSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should show tour step when this screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTourStep();
    });
  }

  /// Check and show the tour step for social screen
  void _checkAndShowTourStep() {
    final tourState = ref.read(multiScreenTourProvider);

    if (!tourState.isActive || tourState.isLoading) return;

    final currentStep = tourState.currentStep;
    if (currentStep == null) return;

    // Social screen handles step 5 (challenges_section)
    if (currentStep.screenRoute != '/social') return;

    if (currentStep.targetKeyId == 'challenges_section') {
      // Switch to challenges tab first
      _tabController.animateTo(1);
      // Small delay to let tab animation complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final helper = MultiScreenTourHelper(context: context, ref: ref);
          helper.checkAndShowTour('/social', _challengesSectionKey);
        }
      });
    }
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
                  preferredSize: const Size.fromHeight(140),
                  child: Column(
                    children: [
                      // Username chip (tap to copy)
                      _buildUserIdChip(context, isDark, authState.user),
                      const SizedBox(height: 8),
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
            children: [
              const FeedTab(),
              Container(
                key: _challengesSectionKey,
                child: const ChallengesTab(),
              ),
              const LeaderboardTab(),
              const FriendsTab(),
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

  Widget _buildUserIdChip(
    BuildContext context,
    bool isDark,
    dynamic user,
  ) {
    final username = user?.username as String?;
    final userId = user?.id as String?;

    // Show username if available, otherwise show truncated user ID
    final displayText = username != null
        ? '@$username'
        : (userId != null ? 'ID: ${userId.substring(0, 8)}...' : 'No ID');

    // Copy the full username or user ID
    final copyText = username ?? userId ?? '';

    final chipBackground = isDark
        ? AppColors.cyan.withValues(alpha: 0.15)
        : AppColors.cyan.withValues(alpha: 0.1);
    final borderColor = AppColors.cyan.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.cyan,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
