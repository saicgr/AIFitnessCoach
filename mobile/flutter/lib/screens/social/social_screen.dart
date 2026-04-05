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
import '../../widgets/app_loading.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/main_shell.dart';
import '../../core/services/posthog_service.dart';
import 'friend_search_screen.dart';
import 'conversation_screen.dart';

part 'social_screen_part_messages_screen.dart';


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
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'social_feed_viewed');
    });
  }

  void _onTabChanged() {
    // When leaving the Feed tab, disable auto-scroll to stop background timers
    if (_tabController.index != 0 && !_tabController.indexIsChanging) {
      final feedOn = ref.read(feedAutoScrollProvider);
      final storiesOn = ref.read(storiesAutoScrollProvider);
      if (feedOn) ref.read(feedAutoScrollProvider.notifier).state = false;
      if (storiesOn) ref.read(storiesAutoScrollProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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

    // Get auth state for user chip
    final authState = ref.watch(authStateProvider);

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
              ref.read(posthogServiceProvider).capture(
                eventName: 'social_find_friends_tapped',
                properties: <String, Object>{},
              );
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
          // Feed options button (visible only on Feed tab) — rightmost
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              if (_tabController.index != 0) return const SizedBox.shrink();
              return _buildFeedFilterButton(context, isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab pills (always visible)
          _buildPillTabs(context, isDark),
          // Subtle divider between nav pills and content
          Divider(
            height: 1,
            thickness: 0.5,
            color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                .withValues(alpha: 0.5),
          ),
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

  // Distinct pill colors per tab
  static const _pillColors = [
    Color(0xFF5B8DEF), // Feed — blue
    Color(0xFFFFB020), // Challenges — amber
    Color(0xFF34D399), // Ranks — emerald
    Color(0xFFE879F9), // Friends — fuchsia
  ];

  Widget _buildPillTabs(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final animationValue = _tabController.animation?.value ?? 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildPill(context, index: 0, label: 'Feed', animationValue: animationValue, isDark: isDark),
              const SizedBox(width: 8),
              _buildPill(context, index: 1, label: 'Challenges', animationValue: animationValue, isDark: isDark),
              const SizedBox(width: 8),
              _buildPill(context, index: 2, label: 'Ranks', animationValue: animationValue, isDark: isDark),
              const SizedBox(width: 8),
              _buildPill(context, index: 3, label: 'Friends', animationValue: animationValue, isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required int index,
    required String label,
    required double animationValue,
    required bool isDark,
  }) {
    final pillColor = _pillColors[index];
    final selectionProgress = (1.0 - (animationValue - index).abs()).clamp(0.0, 1.0);

    // Unselected: subtle tinted bg; Selected: full pill color
    final unselectedBg = pillColor.withValues(alpha: isDark ? 0.12 : 0.10);
    final bgColor = Color.lerp(unselectedBg, pillColor, selectionProgress)!;

    // Text: pill color when unselected, white/black contrast when selected
    final contrastFg = ThemeData.estimateBrightnessForColor(pillColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final fgColor = Color.lerp(
      isDark ? pillColor.withValues(alpha: 0.9) : pillColor.withValues(alpha: 0.8),
      contrastFg,
      selectionProgress,
    )!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selectionProgress > 0.5 ? FontWeight.w600 : FontWeight.w500,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedFilterButton(BuildContext context, bool isDark) {
    final colors = ref.colors(context);
    final sortBy = ref.watch(feedSortProvider);
    final myPostsOnly = ref.watch(feedMyPostsOnlyProvider);
    final feedAutoScroll = ref.watch(feedAutoScrollProvider);
    final storiesAutoScroll = ref.watch(storiesAutoScrollProvider);
    final anyAutoScroll = feedAutoScroll || storiesAutoScroll;

    const sortOptions = [
      ('recent', 'Recent'),
      ('top', 'Top'),
      ('trending', 'Trending'),
    ];

    return PopupMenuButton<String>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white : AppColors.pureBlack,
            size: 22,
          ),
          // Accent dot when any auto-scroll is active
          if (anyAutoScroll)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Feed Options',
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'my_posts_toggle') {
          ref.read(feedMyPostsOnlyProvider.notifier).state = !myPostsOnly;
        } else if (value == 'auto_scroll_feed_toggle') {
          ref.read(feedAutoScrollProvider.notifier).state = !feedAutoScroll;
        } else if (value == 'auto_scroll_stories_toggle') {
          ref.read(storiesAutoScrollProvider.notifier).state = !storiesAutoScroll;
        } else {
          ref.read(feedSortProvider.notifier).state = value;
        }
      },
      itemBuilder: (context) => [
        // Show section
        PopupMenuItem<String>(
          value: 'my_posts_toggle',
          child: Row(
            children: [
              Icon(
                myPostsOnly ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: myPostsOnly ? colors.accent : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              ),
              const SizedBox(width: 10),
              const Text('My Posts Only'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Sort section header
        const PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text(
            'Sort by',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        ...sortOptions.map((o) => PopupMenuItem<String>(
              value: o.$1,
              child: Row(
                children: [
                  if (sortBy == o.$1)
                    Icon(Icons.check_rounded, size: 18, color: colors.accent)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 10),
                  Text(o.$2),
                ],
              ),
            )),
        const PopupMenuDivider(),
        // Auto-scroll section
        PopupMenuItem<String>(
          value: 'auto_scroll_feed_toggle',
          child: Row(
            children: [
              Icon(
                feedAutoScroll ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: feedAutoScroll ? colors.accent : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              ),
              const SizedBox(width: 10),
              const Text('Auto-scroll Feed'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'auto_scroll_stories_toggle',
          child: Row(
            children: [
              Icon(
                storiesAutoScroll ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: storiesAutoScroll ? colors.accent : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              ),
              const SizedBox(width: 10),
              const Text('Auto-scroll Stories'),
            ],
          ),
        ),
      ],
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
