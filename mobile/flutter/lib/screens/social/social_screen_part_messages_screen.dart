part of 'social_screen.dart';


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
      appBar: PillAppBar(
        title: 'Messages',
        actions: [
          PillAppBarAction(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
            onTap: () {
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
          PillAppBarAction(
            icon: Icons.group_add_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => const _GroupCreateSheet(),
                ),
              );
            },
          ),
          PillAppBarAction(icon: Icons.edit_square, onTap: _handleNewMessage),
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
      appBar: const PillAppBar(title: 'New Message'),
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
      appBar: PillAppBar(
        title: 'New Group',
        actions: [
          PillAppBarAction(
            icon: Icons.check_rounded,
            visible: !_isCreating,
            onTap: _createGroup,
          ),
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

