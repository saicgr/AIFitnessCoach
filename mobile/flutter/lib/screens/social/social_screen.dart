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
