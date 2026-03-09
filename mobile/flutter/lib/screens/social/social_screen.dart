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
import '../../widgets/glass_back_button.dart';
import '../../widgets/main_shell.dart';
import 'friend_search_screen.dart';
import 'conversation_screen.dart';

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

/// Standalone Messages screen with proper AppBar for navigation
class _MessagesScreen extends ConsumerStatefulWidget {
  const _MessagesScreen();

  @override
  ConsumerState<_MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<_MessagesScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    Future.microtask(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
    super.dispose();
  }

  void _handleNewMessage() {
    HapticFeedback.lightImpact();
    // Open friend picker to start a new conversation
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => _NewMessagePickerScreen(),
      ),
    );
  }

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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              )
            : Text(
                'Messages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: isDark ? Colors.white : AppColors.pureBlack,
            ),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.group_add_rounded,
              color: isDark ? Colors.white : AppColors.pureBlack,
            ),
            tooltip: 'New Group',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => const _GroupCreateSheet(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.edit_square,
              color: isDark ? Colors.white : AppColors.pureBlack,
            ),
            tooltip: 'New Message',
            onPressed: _handleNewMessage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _searchQuery.isNotEmpty
          ? _FilteredMessagesTab(searchQuery: _searchQuery)
          : const MessagesTab(),
    );
  }
}

/// Filtered messages tab that filters conversations by search query
class _FilteredMessagesTab extends ConsumerWidget {
  final String searchQuery;

  const _FilteredMessagesTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) return const SizedBox.shrink();

    final conversationsAsync = ref.watch(conversationsProvider(userId));

    return conversationsAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (_, __) => const Center(child: Text('Failed to load')),
      data: (conversations) {
        final filtered = conversations.where((c) {
          final name = (c['other_user_name'] as String? ?? '').toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No conversations found',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final conversation = filtered[index];
            return _buildConversationCard(context, ref, conversation, userId, isDark);
          },
        );
      },
    );
  }

  Widget _buildConversationCard(BuildContext context, WidgetRef ref,
      Map<String, dynamic> conversation, String userId, bool isDark) {
    final otherUserName = conversation['other_user_name'] as String? ?? 'User';
    final otherUserAvatar = conversation['other_user_avatar'] as String?;
    final otherUserId = conversation['other_user_id'] as String? ?? '';
    final lastMessage = conversation['last_message'] as String? ?? '';
    final conversationId = conversation['id'] as String? ?? '';
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => ConversationScreen(
                  conversationId: conversationId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserAvatar: otherUserAvatar,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cyan,
                  backgroundImage: otherUserAvatar != null
                      ? NetworkImage(otherUserAvatar)
                      : null,
                  child: otherUserAvatar == null
                      ? Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Friend picker screen for starting a new conversation
class _NewMessagePickerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'New Message',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
      ),
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : _buildFriendsList(context, ref, userId, isDark),
    );
  }

  Widget _buildFriendsList(BuildContext context, WidgetRef ref, String userId, bool isDark) {
    final friendsAsync = ref.watch(friendsListProvider(userId));

    return friendsAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (_, __) => const Center(child: Text('Failed to load friends')),
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Text(
              'No friends to message',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final name = friend['name'] as String? ?? 'Unknown';
            final avatarUrl = friend['avatar_url'] as String?;
            final friendId = friend['id'] as String? ?? '';
            final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
            final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
            final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
            final colors = ref.colors(context);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    try {
                      final socialService = ref.read(socialServiceProvider);
                      final conversation = await socialService.getOrCreateConversation(
                        userId: userId,
                        otherUserId: friendId,
                      );

                      if (context.mounted) {
                        // Pop the picker, then push the conversation
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => ConversationScreen(
                              conversationId: conversation['id'] as String? ?? '',
                              otherUserId: friendId,
                              otherUserName: name,
                              otherUserAvatar: avatarUrl,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Failed to create conversation: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to start conversation')),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.accent.withValues(alpha: 0.2),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.accent,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: colors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Group create screen for creating a new group conversation (F12)
class _GroupCreateSheet extends ConsumerStatefulWidget {
  const _GroupCreateSheet();

  @override
  ConsumerState<_GroupCreateSheet> createState() => _GroupCreateSheetState();
}

class _GroupCreateSheetState extends ConsumerState<_GroupCreateSheet> {
  final _nameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedMemberIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a group name and select at least 2 members'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.createGroupConversation(
        name: name,
        memberIds: _selectedMemberIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$name" created')),
        );
      }
    } catch (e) {
      debugPrint('Failed to create group: $e');
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'New Group',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Group name field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                prefixIcon: Icon(Icons.group_rounded, color: colors.accent),
                filled: true,
                fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Selected count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Select members (${_selectedMemberIds.length} selected)',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Friends list for selection
          Expanded(
            child: userId == null
                ? const Center(child: Text('Not logged in'))
                : _buildFriendsSelector(context, userId, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSelector(BuildContext context, String userId, bool isDark) {
    final friendsAsync = ref.watch(friendsListProvider(userId));
    final colors = ref.colors(context);

    return friendsAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (_, __) => const Center(child: Text('Failed to load friends')),
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Text(
              'No friends to add',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final friendId = friend['id'] as String? ?? '';
            final name = friend['name'] as String? ?? 'Unknown';
            final avatarUrl = friend['avatar_url'] as String?;
            final isSelected = _selectedMemberIds.contains(friendId);
            final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
            final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? colors.accent.withValues(alpha: 0.1)
                    : cardBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isSelected) {
                        _selectedMemberIds.remove(friendId);
                      } else {
                        _selectedMemberIds.add(friendId);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.accent.withValues(alpha: 0.2),
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.accent,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? colors.accent
                              : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
