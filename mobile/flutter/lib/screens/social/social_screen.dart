import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/accessibility/accessibility_provider.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'tabs/feed_tab.dart';
import 'tabs/challenges_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/friends_tab.dart';
import 'tabs/messages_tab.dart';
import '../../widgets/glass_back_button.dart';
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

    // Senior social screen hidden until data providers are connected.
    // All users see the normal social layout for now.
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
            icon: Icon(
              Icons.person_add_rounded,
              color: isDark ? Colors.white : AppColors.pureBlack,
            ),
            tooltip: 'Find Friends',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (context) => const FriendSearchScreen(),
                ),
              );
            },
          ),
          // Messages button
          IconButton(
            icon: Icon(
              Icons.chat_bubble_rounded,
              color: isDark ? Colors.white : AppColors.pureBlack,
            ),
            tooltip: 'Messages',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (context) => const _MessagesScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Modern segmented tab bar
          _buildSegmentedTabs(context, isDark),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FeedTab(),
                ChallengesTab(),
                LeaderboardTab(),
                FriendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
    final colors = ref.colors(context);
    final textMuted = colors.textMuted;
    // Use user's accent color
    final accentColor = colors.accent;

    // Calculate selection progress for smooth animation
    final selectionProgress = (1.0 - (animationValue - index).abs()).clamp(0.0, 1.0);

    // Colors - accent-based style
    final selectedBg = accentColor;
    final unselectedBg = Colors.transparent;
    // Contrast text based on accent color
    final selectedFg = colors.accentContrast;
    final unselectedFg = textMuted;

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
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 10,
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

    final colors = ref.colors(context);
    final cardBg = colors.elevated;
    final cardBorder = colors.cardBorder;
    // Use accent color for stats
    final accentColor = colors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatChip(
                context,
                isDark: isDark,
                icon: Icons.people_rounded,
                value: friendsCount,
                label: 'Friends',
                color: accentColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _tabController.animateTo(3); // Friends tab
                },
              ),
            ),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: cardBorder,
            ),
            Expanded(
              child: _buildStatChip(
                context,
                isDark: isDark,
                icon: Icons.emoji_events_rounded,
                value: challengesCount,
                label: 'Challenges',
                color: accentColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _tabController.animateTo(1); // Challenges tab
                },
              ),
            ),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: cardBorder,
            ),
            Expanded(
              child: _buildStatChip(
                context,
                isDark: isDark,
                icon: Icons.favorite_rounded,
                value: reactionsCount,
                label: 'Likes',
                color: accentColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _tabController.animateTo(0); // Feed tab (where reactions are)
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required int value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
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
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Monochrome text color
    final textColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Show username if available, otherwise show truncated user ID
    String displayText;
    if (username != null && username.isNotEmpty) {
      // Truncate long usernames
      displayText = username.length > 10 ? '${username.substring(0, 10)}...' : username;
    } else if (userId != null && userId.length >= 6) {
      displayText = userId.substring(0, 6);
    } else {
      displayText = '---';
    }
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '@$displayText',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.copy_rounded,
                color: textColor.withValues(alpha: 0.7),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone Messages screen with proper AppBar for navigation
class _MessagesScreen extends StatelessWidget {
  const _MessagesScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
      ),
      body: const MessagesTab(),
    );
  }
}
